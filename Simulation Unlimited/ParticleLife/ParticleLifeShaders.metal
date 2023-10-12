//
//  ParticleLifeShaders.metal
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

#include <metal_stdlib>
#import "../ShaderTypes.h"

using namespace metal;

struct LifeParticle {
    float2 position;
    float2 velocity;
    float2 acceleration;
    float species;
    float bytes;
};

struct ParticleLifeConfig {
    float r_min_distance;
    float r_max_distance;
    float turn_angle;
    float draw_radius;
    float trail_radius;
    float cutoff;
    float falloff;
    float speed_multiplier;
};

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

kernel void drawLifeParticles(texture2d<half, access::write> output [[texture(InputTextureIndexDrawable)]],
                           device LifeParticle *particles [[buffer(ParticleLifeInputIndexParticles)]],
                           device float4 *colors [[buffer(ParticleLifeInputIndexColours)]],
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
    uint span = (uint)config.draw_radius;
    
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
                            const device RenderLifeColours& colours [[buffer(InputIndexColours)]],
                            device LifeParticle *particles [[buffer(InputIndexParticles)]],
                            device float4 *colors [[buffer(ParticleLifeInputIndexColours)]],
                            const device float *weights [[buffer(ParticleLifeInputIndexWeights)]],
                            const device int& particle_count [[ buffer(InputIndexParticleCount)]],
                            const device ParticleLifeConfig& config [[ buffer(InputIndexConfig)]],
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
    
    // position
    position += (velocity * config.speed_multiplier);
    
    // bounds
    if (position.x < 0 || position.x > width) {
        velocity.x *= -1;
    }
    
    if (position.y < 0 || position.y > height) {
        velocity.y *= -1;
    }
    
    // velocity
    
    
    // update particle
    particle.velocity = velocity;
    particle.acceleration = acceleration;
    particle.position = position;
    
    // output
    particles[index] = particle;
    
    // leave trail
    uint2 pos = uint2(particle.position);
    uint span = (uint)config.trail_radius;
    
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
