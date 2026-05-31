//
//  ParticleLifeShaders.metal
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

#include <metal_stdlib>
#import "../ShaderTypes.h"

using namespace metal;

struct RenderLifeColours {
    float4 background;
    float4 trail;
    float4 particle;
};

// TODO: put in shared file
float2 rotate_vector2(float2 vector, float angle) {
    float2x2 rotation = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotation * vector;
}

// TODO: put in shared file
float2 limit_magnitude2(float2 vec, float max_mag) {
    float magnitude = length(vec);
    if (magnitude > max_mag) {
        return normalize(vec) * max_mag;
    }
    return vec;
}

int particle_life_wrapped_cell(int value, int max_value) {
    int wrapped = value % max_value;
    return wrapped < 0 ? wrapped + max_value : wrapped;
}

float2 particle_life_toroidal_delta(float2 from, float2 to, float width, float height) {
    float2 delta = to - from;
    float halfWidth = width * 0.5;
    float halfHeight = height * 0.5;
    
    if (delta.x > halfWidth) {
        delta.x -= width;
    } else if (delta.x < -halfWidth) {
        delta.x += width;
    }
    
    if (delta.y > halfHeight) {
        delta.y -= height;
    } else if (delta.y < -halfHeight) {
        delta.y += height;
    }
    
    return delta;
}

float particle_life_fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

uint particle_life_hash(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352d;
    x ^= x >> 15;
    x *= 0x846ca68b;
    x ^= x >> 16;
    return x;
}

float particle_life_lerp(float a, float b, float t) {
    return a + (b - a) * t;
}

float particle_life_gradient(uint hash, float3 position) {
    switch (hash & 15) {
        case 0: return  position.x + position.y;
        case 1: return -position.x + position.y;
        case 2: return  position.x - position.y;
        case 3: return -position.x - position.y;
        case 4: return  position.x + position.z;
        case 5: return -position.x + position.z;
        case 6: return  position.x - position.z;
        case 7: return -position.x - position.z;
        case 8: return  position.y + position.z;
        case 9: return -position.y + position.z;
        case 10: return  position.y - position.z;
        case 11: return -position.y - position.z;
        case 12: return  position.x + position.y;
        case 13: return -position.x + position.y;
        case 14: return -position.y + position.z;
        default: return -position.y - position.z;
    }
}

float particle_life_perlin(float3 position, uint seed) {
    int3 cell = int3(floor(position));
    float3 local = position - float3(cell);
    float3 fade = float3(
        particle_life_fade(local.x),
        particle_life_fade(local.y),
        particle_life_fade(local.z)
    );
    
    uint baseX = uint(cell.x) * 73856093u;
    uint baseY = uint(cell.y) * 19349663u;
    uint baseZ = uint(cell.z) * 83492791u;
    
    float c000 = particle_life_gradient(particle_life_hash(baseX ^ baseY ^ baseZ ^ seed), local);
    float c100 = particle_life_gradient(particle_life_hash((baseX + 73856093u) ^ baseY ^ baseZ ^ seed), local - float3(1, 0, 0));
    float c010 = particle_life_gradient(particle_life_hash(baseX ^ (baseY + 19349663u) ^ baseZ ^ seed), local - float3(0, 1, 0));
    float c110 = particle_life_gradient(particle_life_hash((baseX + 73856093u) ^ (baseY + 19349663u) ^ baseZ ^ seed), local - float3(1, 1, 0));
    float c001 = particle_life_gradient(particle_life_hash(baseX ^ baseY ^ (baseZ + 83492791u) ^ seed), local - float3(0, 0, 1));
    float c101 = particle_life_gradient(particle_life_hash((baseX + 73856093u) ^ baseY ^ (baseZ + 83492791u) ^ seed), local - float3(1, 0, 1));
    float c011 = particle_life_gradient(particle_life_hash(baseX ^ (baseY + 19349663u) ^ (baseZ + 83492791u) ^ seed), local - float3(0, 1, 1));
    float c111 = particle_life_gradient(particle_life_hash((baseX + 73856093u) ^ (baseY + 19349663u) ^ (baseZ + 83492791u) ^ seed), local - float3(1, 1, 1));
    
    float x00 = particle_life_lerp(c000, c100, fade.x);
    float x10 = particle_life_lerp(c010, c110, fade.x);
    float x01 = particle_life_lerp(c001, c101, fade.x);
    float x11 = particle_life_lerp(c011, c111, fade.x);
    float y0 = particle_life_lerp(x00, x10, fade.y);
    float y1 = particle_life_lerp(x01, x11, fade.y);
    
    return particle_life_lerp(y0, y1, fade.z);
}

float particle_life_octave_noise(float3 position, const device ParticleLifeGradientConfig& config) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0;
    int octaves = clamp(config.octaves, 1, 8);
    
    for (int i = 0; i < octaves; i++) {
        total += particle_life_perlin(position * frequency, config.seed + uint(i * 131u)) * amplitude;
        maxValue += amplitude;
        amplitude *= config.persistence;
        frequency *= config.lacunarity;
    }
    
    if (maxValue <= 0.0) {
        return 0.0;
    }
    
    return total / maxValue;
}

kernel void generateParticleLifeGradientNoise(texture2d<half, access::write> gradient [[texture(InputTextureIndexGradient)]],
                                              const device ParticleLifeGradientConfig& config [[buffer(ParticleLifeInputIndexGradientConfig)]],
                                              uint2 id [[thread_position_in_grid]]) {
    if (id.x >= gradient.get_width() || id.y >= gradient.get_height()) {
        return;
    }
    
    float2 uv = float2(id) / float2(max(gradient.get_width() - 1, 1u), max(gradient.get_height() - 1, 1u));
    float2 xy = uv * config.scale;
    float red = clamp((particle_life_octave_noise(float3(xy, config.zOffset + config.redZOffset), config) + 1.0) * 0.5, 0.0, 1.0);
    float green = clamp((particle_life_octave_noise(float3(xy, config.zOffset + config.greenZOffset), config) + 1.0) * 0.5, 0.0, 1.0);
    float blue = clamp((particle_life_octave_noise(float3(xy, config.zOffset + config.blueZOffset), config) + 1.0) * 0.5, 0.0, 1.0);
    gradient.write(half4(half(red), half(green), half(blue), 1), id);
}

kernel void drawParticleLifeBackground(texture2d<half, access::write> output [[texture(InputTextureIndexDrawable)]],
                                       texture2d<half, access::read> gradient [[texture(InputTextureIndexGradient)]],
                                       const device RenderLifeColours& colours [[buffer(ParticleLifeInputIndexRenderColours)]],
                                       const device ParticleLifeGradientConfig& gradient_config [[buffer(ParticleLifeInputIndexGradientConfig)]],
                                       uint2 id [[thread_position_in_grid]]) {
    if (id.x >= output.get_width() || id.y >= output.get_height()) {
        return;
    }
    
    half4 color = (half4)colours.background;
    if (gradient_config.isDisplayed == 1) {
        uint2 gradient_coord = uint2(
            (float(id.x) / float(output.get_width())) * float(gradient.get_width() - 1),
            (float(id.y) / float(output.get_height())) * float(gradient.get_height() - 1)
        );
        color = half4(gradient.read(gradient_coord).rgb / 2.0, 1);
    }
    
    output.write(color, id);
}

kernel void drawParticleLifePath(texture2d<half, access::read_write> output [[texture(InputTextureIndexDrawable)]],
                                 texture2d<half, access::read> input [[texture(InputTextureIndexPathOutput)]],
                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    
    half4 path_color = input.read(gid);
    if (all(path_color.rgb <= half3(0))) {
        return;
    }
    
    half4 background_color = output.read(gid);
    output.write(half4(max(background_color.rgb, path_color.rgb), 1), gid);
}

kernel void clearParticleLifeGrid(device atomic_uint *grid_counts [[buffer(ParticleLifeInputIndexGridCounts)]],
                                  const device ParticleLifeGridConfig& grid_config [[buffer(ParticleLifeInputIndexGridConfig)]],
                                  uint id [[thread_position_in_grid]]) {
    if (id >= uint(grid_config.cellCount)) {
        return;
    }
    
    atomic_store_explicit(&grid_counts[id], 0, memory_order_relaxed);
}

kernel void buildParticleLifeGrid(const device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                                  device atomic_uint *grid_counts [[buffer(ParticleLifeInputIndexGridCounts)]],
                                  device uint *grid_particle_indices [[buffer(ParticleLifeInputIndexGridParticleIndices)]],
                                  const device int& particle_count [[buffer(ParticleLifeInputIndexParticleCount)]],
                                  const device ParticleLifeGridConfig& grid_config [[buffer(ParticleLifeInputIndexGridConfig)]],
                                  uint id [[thread_position_in_grid]]) {
    if (id >= uint(particle_count)) {
        return;
    }
    
    LifeParticle particle = particles[id];
    int cellX = clamp(int(floor(particle.position.x / grid_config.cellSize)), 0, grid_config.gridWidth - 1);
    int cellY = clamp(int(floor(particle.position.y / grid_config.cellSize)), 0, grid_config.gridHeight - 1);
    uint cellIndex = uint(cellY * grid_config.gridWidth + cellX);
    uint slot = atomic_fetch_add_explicit(&grid_counts[cellIndex], 1, memory_order_relaxed);
    
    if (slot >= uint(grid_config.maxParticlesPerCell)) {
        return;
    }
    
    grid_particle_indices[(cellIndex * uint(grid_config.maxParticlesPerCell)) + slot] = id;
}

kernel void drawLifeParticles(texture2d<half, access::write> output [[texture(InputTextureIndexDrawable)]],
                           device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                           device float4 *colors [[buffer(ParticleLifeInputIndexSpeciesColours)]],
                           const device int& particle_count [[ buffer(ParticleLifeInputIndexParticleCount)]],
                           const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                           uint id [[ thread_position_in_grid ]],
                           uint tid [[ thread_index_in_threadgroup ]],
                           uint bid [[ threadgroup_position_in_grid ]],
                           uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    if (index >= uint(particle_count)) {
        return;
    }
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    LifeParticle particle = particles[index];
    uint2 pos = uint2(clamp(particle.position, float2(0), float2(float(width - 1), float(height - 1))));
    uint span = (uint)config.drawRadius;
    
    // display
    half4 color = (half4)colors[particle.species];
    
    if (span == 0) {
        output.write(color, pos);
    } else {
        int minX = max(int(pos.x) - int(span), 0);
        int maxX = min(int(pos.x) + int(span), int(width) - 1);
        int minY = max(int(pos.y) - int(span), 0);
        int maxY = min(int(pos.y) + int(span), int(height) - 1);
        for (int u = minX; u <= maxX; u++) {
            for (int v = minY; v <= maxY; v++) {
                if (length(float2(float(u), float(v)) - particle.position) < span) {
                    output.write(color, uint2(uint(u), uint(v)));
                }
            }
        }
    }
}

kernel void updateParticles(texture2d<half, access::read_write> output [[texture(InputTextureIndexPathInput)]],
                            texture2d<half, access::read> gradient [[texture(InputTextureIndexGradient)]],
                            const device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                            device LifeParticle *updated_particles [[buffer(ParticleLifeInputIndexParticleOutput)]],
                            const device atomic_uint *grid_counts [[buffer(ParticleLifeInputIndexGridCounts)]],
                            const device uint *grid_particle_indices [[buffer(ParticleLifeInputIndexGridParticleIndices)]],
                            const device float *weights [[buffer(ParticleLifeInputIndexWeights)]],
                            const device ParticleLifeTouch *touches [[buffer(ParticleLifeInputIndexTouches)]],
                            const device int& touch_count [[buffer(ParticleLifeInputIndexTouchCount)]],
                            const device int& particle_count [[ buffer(ParticleLifeInputIndexParticleCount)]],
                            const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                            const device ParticleLifeGradientConfig& gradient_config [[buffer(ParticleLifeInputIndexGradientConfig)]],
                            const device ParticleLifeGridConfig& grid_config [[buffer(ParticleLifeInputIndexGridConfig)]],
                            uint id [[ thread_position_in_grid ]],
                            uint tid [[ thread_index_in_threadgroup ]],
                            uint bid [[ threadgroup_position_in_grid ]],
                            uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    if (index >= uint(particle_count)) {
        return;
    }
    LifeParticle particle = particles[index];
    
    float2 position = particle.position;
    float2 velocity = particle.velocity;
    float2 acceleration = particle.acceleration;
    int species = particle.species;
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    // Accumulate neighbor influence into force, then integrate velocity.
    float2 force = float2(0,0);
    float2 gradient_velocity_delta = float2(0,0);
    int cellX = clamp(int(floor(position.x / grid_config.cellSize)), 0, grid_config.gridWidth - 1);
    int cellY = clamp(int(floor(position.y / grid_config.cellSize)), 0, grid_config.gridHeight - 1);
    
    for (int yOffset = -grid_config.cellRadius; yOffset <= grid_config.cellRadius; yOffset++) {
        int neighborCellY = particle_life_wrapped_cell(cellY + yOffset, grid_config.gridHeight);
        for (int xOffset = -grid_config.cellRadius; xOffset <= grid_config.cellRadius; xOffset++) {
            int neighborCellX = particle_life_wrapped_cell(cellX + xOffset, grid_config.gridWidth);
            uint cellIndex = uint(neighborCellY * grid_config.gridWidth + neighborCellX);
            uint cellParticleCount = min(atomic_load_explicit(&grid_counts[cellIndex], memory_order_relaxed), uint(grid_config.maxParticlesPerCell));
            
            for (uint slot = 0; slot < cellParticleCount; slot++) {
                uint otherIndex = grid_particle_indices[(cellIndex * uint(grid_config.maxParticlesPerCell)) + slot];
                if (otherIndex == index || otherIndex >= uint(particle_count)) {
                    continue;
                }
                
                LifeParticle other = particles[otherIndex];
                float2 delta = particle_life_toroidal_delta(position, other.position, float(width), float(height));
                float dist = length(delta);
                if (dist <= 0.0001 || dist > config.rMaxDistance) {
                    continue;
                }
                
                int otherSpecies = other.species;
                int forceIndex = (species * (int)config.flavourCount) + otherSpecies;
                float weight = -1.0 * weights[forceIndex];
                
                float2 direction = normalize(delta);
                if (dist < config.rMinDistance) {
                    float minDistance = max(config.rMinDistance, 0.0001);
                    force -= (1.0 - (dist / minDistance)) * direction * 0.5; // repel harder as particles get closer
                } else {
                    float interactionRange = max(config.rMaxDistance - config.rMinDistance, 0.0001);
                    float d = clamp((dist - config.rMinDistance) / interactionRange, 0.0, 1.0);
                    float influence = 1.0 - abs((d * 2.0) - 1.0);
                    force += (influence * weight) * direction; // force = 0 -> weight -> 0 across r_min -> r_max
                }
            }
        }
    }
    
    for (uint j = 0; j < uint(touch_count); j++) {
        ParticleLifeTouch touch = touches[j];
        float touchDistance = distance(position, touch.position);
        if (touchDistance <= 0.0001 || touchDistance > config.touchRadius) {
            continue;
        }
        
        float2 direction = normalize(position - touch.position);
        float strength = pow((config.touchRadius - touchDistance) / config.touchRadius, 1.5) * config.touchForce;
        force += direction * strength;
    }
    
    if (gradient_config.isEnabled == 1 && gradient.get_width() > 1 && gradient.get_height() > 1) {
        float gx = clamp(position.x / float(width), 0.0, 1.0) * float(gradient.get_width() - 1);
        float gy = clamp(position.y / float(height), 0.0, 1.0) * float(gradient.get_height() - 1);
        uint x0 = uint(max(gx - 1.0, 0.0));
        uint x1 = uint(min(gx + 1.0, float(gradient.get_width() - 1)));
        uint y0 = uint(max(gy - 1.0, 0.0));
        uint y1 = uint(min(gy + 1.0, float(gradient.get_height() - 1)));
        
        int gradientChannel = clamp(species, 0, 2);
        float left = float(gradient.read(uint2(x0, uint(gy)))[gradientChannel]);
        float right = float(gradient.read(uint2(x1, uint(gy)))[gradientChannel]);
        float up = float(gradient.read(uint2(uint(gx), y0))[gradientChannel]);
        float down = float(gradient.read(uint2(uint(gx), y1))[gradientChannel]);
        float2 gradient_force = -float2(right - left, down - up);
        gradient_velocity_delta = gradient_force * gradient_config.forceMultiplier;
    }
    
    if (length(force) > 0.001) {
        velocity += force * config.forceMultiplier;
    }
    velocity += gradient_velocity_delta;
    velocity *= config.damping;
    velocity = limit_magnitude2(velocity, config.maxSpeed);
    position += (velocity * config.speedMultiplier);
    
    // bounds
    if (position.x < 0) {
        position.x = float(width - 1);
    }
    
    if (position.y < 0) {
        position.y = float(height - 1);
    }
    
    if (position.x >= width) {
        position.x = 0;
    }
    
    if (position.y >= height) {
        position.y = 0;
    }
    
    
    // update particle
    particle.acceleration = acceleration;
    particle.velocity = velocity;
    particle.position = position;
    
    // output
    updated_particles[index] = particle;
}

kernel void drawParticleTrail(texture2d<half, access::read_write> output [[texture(InputTextureIndexPathInput)]],
                              device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                              device float4 *colors [[buffer(ParticleLifeInputIndexSpeciesColours)]],
                              const device int& particle_count [[ buffer(ParticleLifeInputIndexParticleCount)]],
                              const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                              uint id [[ thread_position_in_grid ]],
                              uint tid [[ thread_index_in_threadgroup ]],
                              uint bid [[ threadgroup_position_in_grid ]],
                              uint blockDim [[ threads_per_threadgroup ]]) {
    uint index = bid * blockDim + tid;
    if (index >= uint(particle_count)) {
        return;
    }
    LifeParticle particle = particles[index];
    half4 color = (half4)colors[particle.species];
    
    uint width = output.get_width();
    uint height = output.get_height();
    uint2 pos = uint2(clamp(particle.position, float2(0), float2(float(width - 1), float(height - 1))));
    uint span = (uint)config.trailRadius;
    
    int minX = max(int(pos.x) - int(span), 0);
    int maxX = min(int(pos.x) + int(span), int(width) - 1);
    int minY = max(int(pos.y) - int(span), 0);
    int maxY = min(int(pos.y) + int(span), int(height) - 1);
    for (int u = minX; u <= maxX; u++) {
        for (int v = minY; v <= maxY; v++) {
            if (length(float2(float(u), float(v)) - particle.position) < span) {
                uint2 pixel = uint2(uint(u), uint(v));
                half4 current_color = output.read(pixel);
                half4 output_color = current_color += color;
                output.write(clamp(output_color, half4(0), half4(1)), pixel);
                // TODO: desaturate existing color?
            }
        }
    }
}
