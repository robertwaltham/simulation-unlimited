//
//  CircleShaders.metal
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-20.
//

#include <metal_stdlib>
using namespace metal;
#import "../ShaderTypes.h"

struct CircleConfig {
    float radius;
    float circle_count;
};

struct Circle {
    float x;
    float y;
    float radius;
};

float sdfCircle(float2 position, float radius) {
    return length(position) - radius;
}

kernel void circlePass(texture2d<half, access::write> output [[texture(InputTextureIndexPathHexagon)]],
                           const device CircleConfig& config [[ buffer(8)]],
                           device Circle *circles [[buffer(9)]],
                           uint2 id [[thread_position_in_grid]]) {
    float2 fragCoord = float2(id);

    float distance = 10000.0;
    
    for (int i = 0; i < config.circle_count; i++) {
        Circle circle = circles[i];
        float distance2 = sdfCircle(fragCoord - float2(circle.x, circle.y), circle.radius);
        distance = abs(distance2) < abs(distance) ? distance2 : distance;
    }
    
    float r = config.radius;
    half color = distance > -(r/2.0) && distance < (r/2.0) ? abs(distance) * 2.0 / r : 1.0;
    
    half4 col = half4(half3(color), 1.0);
    
    output.write(col, id);
}
