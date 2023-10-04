//
//  MainShaders.metal
//  BoidsUnlimited
//
//  Created by Robert Waltham on 2022-03-21.
//

#include <metal_stdlib>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "SlimeTypes.h"

using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float2 acceleration;
    float2 force;
};

struct Obstacle {
    float2 position;
};

struct BoidsConfig {
    float max_speed;
    float margin;
    float align_coefficient;
    float cohere_coefficient;
    float separate_coefficient;
    float radius;
};

float2 limit_magnitude(float2 vec, float max_mag) {
    float magnitude = length(vec);
    if (magnitude > max_mag) {
        return normalize(vec) * max_mag;
    }
    return vec;
}

kernel void firstPass(texture2d<half, access::write> output [[texture(0)]],
                      uint2 id [[thread_position_in_grid]]) {
    output.write(half4(0.), id);
}

kernel void secondPass(device Particle *particles [[buffer(BoidsInputIndexParticle)]],
                       const device int& particle_count [[ buffer(BoidsInputIndexParticleCount)]],
                       const device uint& width [[ buffer(BoidsInputIndexWidth)]],
                       const device uint& height [[ buffer(BoidsInputIndexHeight)]],
//                       const device float& max_speed [[ buffer(BoidsInputIndexMaxSpeed)]],
//                       const device float& margin [[ buffer(BoidsInputIndexMargin)]],
//                       const device float& align_coefficient [[ buffer(BoidsInputIndexAlign)]],
//                       const device float& cohere_coefficient [[ buffer(BoidsInputIndexCohere)]],
//                       const device float& separate_coefficient [[ buffer(BoidsInputIndexSeparate)]],
//                       const device float& radius [[ buffer(BoidsInputIndexRadius)]],
                       device Obstacle *obstacles [[buffer(BoidsInputIndexObstacle)]],
                       const device int& obstacle_count [[ buffer(BoidsInputIndexObstacleCount)]],
                       const device BoidsConfig& config [[ buffer(BoidsInputIndexConfig)]],
                       uint id [[ thread_position_in_grid ]],
                       uint tid [[ thread_index_in_threadgroup ]],
                       uint bid [[ threadgroup_position_in_grid ]],
                       uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    Particle particle = particles[index];

    float margin_force = 0.1;
    float max_force = 1;
    
    float2 position = particle.position;
    float2 velocity = particle.velocity;
    float2 acceleration = float2(0,0);

    // boids
    float2 align_target = float2(0,0);
    float2 cohere_center = float2(0,0);
    float2 separate_target = float2(0,0);
    float total = 0;
    float separate_total = 0;
    for (uint i = 0; i < uint(particle_count); i++) {

        if (i == index) {
            continue;
        }

        Particle other = particles[i];
        float dist = distance(position, other.position);
        if (dist > config.radius) {
            continue;
        }
        total++;

        align_target += other.velocity;
        cohere_center += other.position;

        float2 diff = position - other.position;
        if (diff.x != 0 && diff.y != 0 && dist < config.radius / 2) {
            diff = diff / pow(dist, 2.);
            separate_target += diff;
            separate_total++;
        }
    }
    
    float2 align_force = float2(0,0);
    float2 cohere_force = float2(0,0);
    float2 separate_force = float2(0,0);

    if (total > 0) {

        float align_target_len = length(align_target);
        if (align_target_len != 0) {
            align_target /= total;
            align_target *= config.max_speed / align_target_len;
            align_force = align_target - velocity;
            align_force = limit_magnitude(align_force, max_force);
            align_force *= config.align_coefficient;
            acceleration += align_force;
        }

        cohere_center /= total;
        float2 cohere_target = cohere_center - position;
        float cohere_target_len = length(cohere_target);
        if (cohere_target_len != 0) {
            cohere_target *= config.max_speed / cohere_target_len;
            cohere_force = cohere_target - velocity;
            cohere_force = limit_magnitude(cohere_force, max_force);
            cohere_force *= config.cohere_coefficient;
            acceleration += cohere_force;
        }
    }
    
    if (separate_total > 0) {
        separate_target /= separate_total;
        float separate_target_len = length(separate_target);
        if (separate_target_len != 0) {
            separate_target *= config.max_speed / separate_target_len;
            separate_force = separate_target - velocity;
            separate_force = limit_magnitude(separate_force, max_force);
            separate_force *= config.separate_coefficient;
            acceleration += separate_force;
        }
    }
    
    acceleration = limit_magnitude(acceleration, config.max_speed*2);

    
    // obstacles
    
    for (uint j = 0; j < uint(obstacle_count); j++) {
        Obstacle obst = obstacles[j];
        float obstacle_radius = 200;
        float obstacle_max_force = 2;
        float obstacle_distance = distance(position, obst.position);
        if (obstacle_distance < obstacle_radius) {
            float2 diff = position - obst.position;
            float2 obs_force = normalize(diff) * pow((obstacle_radius - obstacle_distance) / obstacle_radius, 1.5) * obstacle_max_force;
            acceleration += obs_force;
        }
    }
    
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
        position.x = 0;
    }
    
    // velocity
    velocity += acceleration;
    velocity = limit_magnitude(velocity, config.max_speed);
    float magnitude = length(velocity);
    if (magnitude < config.max_speed / 3) {
        velocity = normalize(velocity) * config.max_speed;
    }
    
    // margin
    if (position.x < config.margin || position.x > width - config.margin || position.y < config.margin || position.y > height - config.margin) {
        float2 center = float2(width / 2., height / 2.);
        float2 center_direction = normalize(center - position);
        float2 center_force = center_direction * margin_force;
        velocity += center_force;
    }
    
    
    
    // position
    position += velocity;

    // update particle
    particle.velocity = velocity;
    particle.acceleration = acceleration;
    particle.position = position;
    particle.force = align_force + cohere_force + separate_force;

    // output
    particles[index] = particle;
}

kernel void thirdPass(texture2d<half, access::write> output [[texture(0)]],
                      device Particle *particles [[buffer(ThirdPassInputTextureIndexParticle)]],
                      const device int& span [[ buffer(ThirdPassInputTextureIndexRadius)]],
                      uint id [[ thread_position_in_grid ]],
                      uint tid [[ thread_index_in_threadgroup ]],
                      uint bid [[ threadgroup_position_in_grid ]],
                      uint blockDim [[ threads_per_threadgroup ]]) {
    
    uint index = bid * blockDim + tid;
    
    uint width = output.get_width();
    uint height = output.get_height();

    Particle particle = particles[index];
    uint2 pos = uint2(particle.position);
    
    // display
    half4 color = half4(1.);
    
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
