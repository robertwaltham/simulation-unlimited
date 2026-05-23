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

kernel void drawParticlePath(texture2d<half, access::read_write> output [[texture(InputTextureIndexPathInput)]],
                            const device RenderLifeColours& colours [[buffer(ParticleLifeInputIndexRenderColours)]],
                            device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                            device float4 *colors [[buffer(ParticleLifeInputIndexSpeciesColours)]],
                            const device float *weights [[buffer(ParticleLifeInputIndexWeights)]],
                            const device int& particle_count [[ buffer(ParticleLifeInputIndexParticleCount)]],
                            const device ParticleLifeConfig& config [[ buffer(ParticleLifeInputIndexConfig)]],
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
    half4 color = (half4)colors[species];
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    // Accumulate neighbor influence into force, then integrate velocity.
    float2 force = float2(0,0);
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
    
    if (length(force) > 0.001) {
        velocity += force * config.forceMultiplier;
    }
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
    
    // leave trail
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
