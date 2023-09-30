//
//  SlimeTypes.h
//  SlimeUnlimited
//
//  Created by Robert Waltham on 2022-07-23.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

// Slime

typedef enum InputIndex {
    InputIndexColours = 0,
    InputIndexParticles = 1,
    InputIndexParticleCount = 2,
    InputIndexConfig = 3,
    InputIndexRandom = 4
} InputIndex;

typedef enum InputTextureIndex {
    InputTextureIndexDrawable = 0,
    InputTextureIndexPathInput = 1,
    InputTextureIndexPathOutput = 2

} InputTextureIndex;

// Boids

typedef enum SecondPassInputIndex {
    SecondPassInputIndexParticle = 0,
    SecondPassInputIndexParticleCount = 1,
    SecondPassInputIndexMaxSpeed = 2,
    SecondPassInputIndexMargin = 3,
    SecondPassInputIndexAlign = 4,
    SecondPassInputIndexCohere = 5,
    SecondPassInputIndexSeparate = 6,
    SecondPassInputIndexRadius = 7,
    SecondPassInputIndexWidth = 8,
    SecondPassInputIndexHeight = 9,
    SecondPassInputIndexObstacle = 10,
    SecondPassInputIndexObstacleCount = 11

} SecondPassInputIndex;

typedef enum ThirdPassInputIndex {
    ThirdPassInputTextureIndexParticle = 0,
    ThirdPassInputTextureIndexRadius = 1,
} ThirdPassInputTextureIndex;


#endif /* ShaderTypes_h */
