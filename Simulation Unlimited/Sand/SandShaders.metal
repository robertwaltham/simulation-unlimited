//
//  SandShaders.metal
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-29.
//


#include <metal_stdlib>
#import "../ShaderTypes.h"

using namespace metal;


kernel void firstPassSand(texture2d<half, access::write> output [[texture(0)]],
                           uint2 id [[thread_position_in_grid]]) {
    output.write(half4(0.5, 0.5, 0.5, 1.0), id);
}
