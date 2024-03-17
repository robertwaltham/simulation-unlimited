//
//  HexagonShaders.metal
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-16.
//

#include <metal_stdlib>
using namespace metal;
#import "../ShaderTypes.h"

// The MIT License
// Copyright © 2020 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Signed distance and gradient to a hexagon. Probably
// faster than central differences or automatic
// differentiation/dual numbers.

// List of other 2D distances+gradients:
//
// https://iquilezles.org/articles/distgradfunctions2d
//
// and
//
// https://www.shadertoy.com/playlist/M3dSRf


// .x = f(p)
// .y = ∂f(p)/∂x
// .z = ∂f(p)/∂y
// .yz = ∇f(p) with ‖∇f(p)‖ = 1
float3 sdgHexagon(float2 p, float r) {
    float3 k = float3(-0.866025404,0.5,0.577350269);
    float2 s = sign(p);
    p = abs(p);
    float w = dot(k.xy,p);
    p -= 2.0*min(w,0.0)*k.xy;
    p -= float2(clamp(p.x, -k.z*r, k.z*r), r);
    float d = length(p)*sign(p.y);
    float2  g = (w<0.0) ? float2x2(-k.y,-k.x,-k.x,k.y)*p : p;
    return float3( d, s*g/d );
}

struct HexagonConfig {
    float offset_x;
    float offset_y;
    float shift_x;
    float shift_y;
    float size;
    float mod_x;
    float mod_y;
    float multiplier;
    float color_offset;
};


kernel void hexagonPass(texture2d<half, access::write> output [[texture(InputTextureIndexPathHexagon)]],
                           const device HexagonConfig& config [[ buffer(7)]],
                           uint2 id [[thread_position_in_grid]]) {
    float2 fragCoord = float2(id);
    float2 iResolution = float2(output.get_width(), output.get_height());
    
    half4 col = half4(0.0, 0.0, 0.0, 1.0);
    
    float denom = iResolution.x > iResolution.y ? iResolution.x : iResolution.y;
    
    for(int i = 0; i < 3; i++) {
        float colorOffset = i * config.color_offset;
        
        float2 p = (fragCoord +float2(0.0, colorOffset))/denom;
        float2 p1 = p * config.multiplier;
        p1.x = fmod(p1.x, config.mod_x) - config.offset_x;
        p1.y = fmod(p1.y, config.mod_y) - config.offset_y;
        
        float2 q = ((fragCoord+float2(config.shift_x, config.shift_y + colorOffset)))/denom;
        float2 p2 = q * config.multiplier;
        p2.x = fmod(p2.x, config.mod_x) - config.offset_x;
        p2.y = fmod(p2.y, config.mod_y) - config.offset_y;

        //size
        float si = config.size;

        // sdf(p) and gradient(sdf(p))
        float3 dg1 = sdgHexagon(p1,si);
        float3 dg2 = sdgHexagon(p2,si);
        
        float d = min(dg1.x, dg2.x);
        
        // coloring
        if (d > 0.0) {
            col[i] = 1.0;
        }
    }
    
    output.write(col, id);
}


