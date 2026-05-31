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
    float3 position = float3(uv * config.scale, config.zOffset);
    float value = clamp((particle_life_octave_noise(position, config) + 1.0) * 0.5, 0.0, 1.0);
    gradient.write(half4(value, value, value, 1), id);
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
        half value = gradient.read(gradient_coord).r / 2.0;
        color = half4(value, value, value, 1);
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
    if (path_color.r <= 0 && path_color.g <= 0 && path_color.b <= 0) {
        return;
    }
    
    half4 background_color = output.read(gid);
    output.write(half4(max(background_color.rgb, path_color.rgb), 1), gid);
}

kernel void drawLifeParticles(texture2d<half, access::write> output [[texture(InputTextureIndexDrawable)]],
                           device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                           device float4 *colors [[buffer(ParticleLifeInputIndexSpeciesColours)]],
                           const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                           uint id [[ thread_position_in_grid ]],
                           uint tid [[ thread_index_in_threadgroup ]],
                           uint bid [[ threadgroup_position_in_grid ]],
                           uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    LifeParticle particle = particles[index];
    uint2 pos = uint2(particle.position);
    uint span = (uint)config.drawRadius;
    
    // display
    half4 color = (half4)colors[(int)particle.species];
    
    if (span == 0) {
        output.write(color, pos);
    } else {
        for (uint u = pos.x - span; u <= uint(pos.x) + span; u++) {
            for (uint v = pos.y - span; v <= uint(pos.y) + span; v++) {
                if (u < 0 || v < 0 || u >= width || v >= height) {
                    continue;
                }
                
                if (length(float2(u, v) - particle.position) < span) {
                    output.write(color, uint2(u, v));
                }
            }
        }
    }
}

kernel void updateParticles(texture2d<half, access::read_write> output [[texture(InputTextureIndexPathInput)]],
                            texture2d<half, access::read> gradient [[texture(InputTextureIndexGradient)]],
                            device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                            const device float *weights [[buffer(ParticleLifeInputIndexWeights)]],
                            const device ParticleLifeTouch *touches [[buffer(ParticleLifeInputIndexTouches)]],
                            const device int& touch_count [[buffer(ParticleLifeInputIndexTouchCount)]],
                            const device int& particle_count [[ buffer(ParticleLifeInputIndexParticleCount)]],
                            const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                            const device ParticleLifeGradientConfig& gradient_config [[buffer(ParticleLifeInputIndexGradientConfig)]],
                            uint id [[ thread_position_in_grid ]],
                            uint tid [[ thread_index_in_threadgroup ]],
                            uint bid [[ threadgroup_position_in_grid ]],
                            uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    LifeParticle particle = particles[index];
    
    float2 position = particle.position;
    float2 velocity = particle.velocity;
    float2 acceleration = particle.acceleration;
    int species = (int)particle.species;
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    // Accumulate neighbor influence into force, then integrate velocity.
    float2 force = float2(0,0);
    float2 gradient_velocity_delta = float2(0,0);
    for (uint i = 0; i < uint(particle_count); i++) {
        
        if (i == index) {
            continue;
        }
        
        LifeParticle other = particles[i];
        float dist = distance(position, other.position);
        if (dist <= 0.0001 || dist > config.rMaxDistance) {
            continue;
        }
        
        int otherSpecies = (int)other.species;
        int forceIndex = (species * (int)config.flavourCount) + otherSpecies;
        float weight = -1.0 * weights[forceIndex];

        
        float2 direction = normalize(other.position - position);
        if (dist < config.rMinDistance) {
            force -= (1.0 - (dist / config.rMinDistance)) * direction * 0.5; // repel harder as particles get closer
        } else {
            float d = (dist - config.rMinDistance) / (config.rMaxDistance - config.rMinDistance);
            if (d < 0.5) {
                force += (d * 2.0 * weight) * direction; // force = 0 -> weight as distance goes from r_min -> r_max - r_min / 2
            } else {
                force += (0.5 - d) * 2.0 * weight * direction; // force = weight -> 0 as distance goes from r_max - r_min / 2 -> r_max
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
        
        float left = float(gradient.read(uint2(x0, uint(gy))).r);
        float right = float(gradient.read(uint2(x1, uint(gy))).r);
        float up = float(gradient.read(uint2(uint(gx), y0)).r);
        float down = float(gradient.read(uint2(uint(gx), y1)).r);
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
        position.x = width;
    }
    
    if (position.y < 0) {
        position.y = height;
    }
    
    if (position.x > width) {
        position.x = 0;
    }
    
    if (position.y > height) {
        position.y = 0;
    }
    
    
    // update particle
    particle.acceleration = acceleration;
    particle.velocity = velocity;
    particle.position = position;
    
    // output
    particles[index] = particle;
}

kernel void drawParticleTrail(texture2d<half, access::read_write> output [[texture(InputTextureIndexPathInput)]],
                              device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                              device float4 *colors [[buffer(ParticleLifeInputIndexSpeciesColours)]],
                              const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
                              uint id [[ thread_position_in_grid ]],
                              uint tid [[ thread_index_in_threadgroup ]],
                              uint bid [[ threadgroup_position_in_grid ]],
                              uint blockDim [[ threads_per_threadgroup ]]) {
    uint index = bid * blockDim + tid;
    LifeParticle particle = particles[index];
    half4 color = (half4)colors[(int)particle.species];
    
    uint width = output.get_width();
    uint height = output.get_height();
    uint2 pos = uint2(particle.position);
    uint span = (uint)config.trailRadius;
    
    for (uint u = pos.x - span; u <= uint(pos.x) + span; u++) {
        for (uint v = pos.y - span; v <= uint(pos.y) + span; v++) {
            if (u < 0 || v < 0 || u >= width || v >= height) {
                continue;
            }
            
            if (length(float2(u, v) - particle.position) < span) {
                half4 current_color = output.read(uint2(u,v));
                half4 output_color = current_color += color;
                output.write(clamp(output_color, half4(0), half4(1)), uint2(u, v));
                // TODO: desaturate existing color?
            }
        }
    }
}
