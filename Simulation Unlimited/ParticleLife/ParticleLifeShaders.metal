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
    
//    float2 position = particle.position;
//    float2 velocity = particle.velocity;
//    half4 sensor_color = half4(1, 0, 0, 1);
//    float sensor_angle = config.sensor_angle;
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
//    output.write(sensor_color, center_coord);
//    output.write(sensor_color, left_coord);
//    output.write(sensor_color, right_coord);
}
