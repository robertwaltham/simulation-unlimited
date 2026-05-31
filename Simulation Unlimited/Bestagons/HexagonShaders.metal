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

float sdHexagon(float2 p, float r) {
    float3 k = float3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    float w = dot(k.xy,p);
    p -= 2.0*min(w,0.0)*k.xy;
    p -= float2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

kernel void hexagonPass(texture2d<half, access::write> output [[texture(InputTextureIndexPathHexagon)]],
                           const device HexagonConfig& config [[ buffer(HexagonInputIndexConfig)]],
                           uint2 id [[thread_position_in_grid]]) {
    if (id.x >= output.get_width() || id.y >= output.get_height()) {
        return;
    }
    
    float2 fragCoord = float2(id);
    float2 iResolution = float2(output.get_width(), output.get_height());
    
    half4 col = half4(0.0, 0.0, 0.0, 1.0);
    
    float denom = iResolution.x > iResolution.y ? iResolution.x : iResolution.y;
    
    for(int i = 0; i < 3; i++) {
        float colorOffset = i * config.colorOffset;
        
        float2 p = (fragCoord +float2(0.0, colorOffset))/denom;
        float2 p1 = p * config.multiplier;
        p1.x = fmod(p1.x, config.modX) - config.offsetX;
        p1.y = fmod(p1.y, config.modY) - config.offsetY;
        
        float2 q = ((fragCoord+float2(config.shiftX, config.shiftY + colorOffset)))/denom; //TODO: calculate shift_x/y from size
        float2 p2 = q * config.multiplier;
        p2.x = fmod(p2.x, config.modX) - config.offsetX;
        p2.y = fmod(p2.y, config.modY) - config.offsetY;

        //size
        float si = config.size;

        float d = min(sdHexagon(p1,si), sdHexagon(p2,si));
        
        // coloring
        if (d > 0.0) {
            col[i] = 1.0;
        }
    }
    
    output.write(col, id);
}

