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
    InputTextureIndexPathOutput = 2,
    InputTextureIndexPathHexagon = 3
} InputTextureIndex;

// Boids

typedef enum BoidsInputIndex {
    BoidsInputIndexParticle = 0,
    BoidsInputIndexParticleCount = 1,
    BoidsInputIndexWidth = 2,
    BoidsInputIndexHeight = 3,
    BoidsInputIndexObstacle = 4,
    BoidsInputIndexObstacleCount = 5,
    BoidsInputIndexConfig = 6
} BoidsInputIndex;

typedef enum ThirdPassInputIndex {
    ThirdPassInputTextureIndexParticle = 0,
    ThirdPassInputTextureIndexRadius = 1,
} ThirdPassInputTextureIndex;

// Particle Life

typedef enum ParticleLifeInputIndex {
    ParticleLifeInputIndexParticles = 1,
    ParticleLifeInputIndexParticleCount = 2,
    ParticleLifeInputIndexConfig = 3,
    ParticleLifeInputIndexRandom = 4,
    ParticleLifeInputIndexColours = 5,
    ParticleLifeInputIndexWeights = 6
} ParticleLifeInputIndex;

#endif /* ShaderTypes_h */
