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
    float sensor_angle;
    float sensor_distance;
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
                            const device float *random [[buffer(InputIndexRandom)]],
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
    
//    float sensor_angle = config.sensor_angle;
//    float turn_angle = config.turn_angle;
//    float sensor_distance = config.sensor_distance;
//    
//    float2 center_direction = normalize(-velocity) * sensor_distance;
//    float2 left_direction = rotate_vector2(center_direction, sensor_angle);
//    float2 right_direction = rotate_vector2(center_direction, -sensor_angle);
//    
//    ushort2 center_coord = (ushort2)floor(position - center_direction);
//    ushort2 left_coord = (ushort2)floor(position - left_direction);
//    ushort2 right_coord = (ushort2)floor(position - right_direction);
//    
//    half4 center_colour = output.read(center_coord);
//    half4 left_colour = output.read(left_coord);
//    half4 right_colour = output.read(right_coord);
    
//    int channel = species;
//    float tolerance = 0.1;
//    if (left_colour[channel] - center_colour[channel] > tolerance && left_colour[channel] - right_colour[channel] > tolerance) {
//        velocity = rotate_vector2(velocity, turn_angle);
//    } else if (right_colour[channel] - center_colour[channel] > tolerance && right_colour[channel] - left_colour[channel] > tolerance) {
//        velocity = rotate_vector2(velocity, -turn_angle);
//    } else if (abs(right_colour[channel] - left_colour[channel]) < tolerance) {
//        if (random[index % 1024] < 0.5) {
//            velocity = rotate_vector2(velocity, -turn_angle);
//        } else {
//            velocity = rotate_vector2(velocity, turn_angle);
//        }
//    }
    
    // update particle
    particle.velocity = velocity;
    particle.acceleration = acceleration;
    particle.position = position;
    
    // output
    particles[index] = particle;
    
    // leave trail
    
    uint2 pos = uint2(particle.position);
//    half4 trail_colour = half4(0,0,0,1);
//    trail_colour[species] = 0.25;
    
//    half4 deletion_colour = half4(0.1, 0.1, 0.1, 1);
//    deletion_colour[species] = 0;
    uint span = (uint)config.trail_radius;
    
    for (uint u = pos.x - span; u <= uint(pos.x) + span; u++) {
        for (uint v = pos.y - span; v <= uint(pos.y) + span; v++) {
            if (u < 0 || v < 0 || u >= width || v >= height) {
                continue;
            }
            
            if (length(float2(u, v) - particle.position) < span) {
                half4 current_color = output.read(uint2(u,v));
                half4 output_color = current_color += color;
//                output_color = current_color -= deletion_colour;
                output.write(clamp(output_color, half4(0), half4(1)), uint2(u, v));
            }
        }
    }
}
