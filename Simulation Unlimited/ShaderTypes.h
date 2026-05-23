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
    InputTextureIndexPathHexagon = 3,
    InputTextureIndexGradient = 4
} InputTextureIndex;

// Boids

typedef enum BoidsInputIndex {
    BoidsInputIndexParticle = 0,
    BoidsInputIndexParticleCount = 1,
    BoidsInputIndexWidth = 2,
    BoidsInputIndexHeight = 3,
    BoidsInputIndexObstacle = 4,
    BoidsInputIndexObstacleCount = 5,
    BoidsInputIndexConfig = 6,
    BoidsInputIndexBlurConfig = 7

} BoidsInputIndex;

typedef enum ThirdPassInputIndex {
    ThirdPassInputTextureIndexParticle = 0,
    ThirdPassInputTextureIndexRadius = 1,
} ThirdPassInputTextureIndex;

// Particle Life

typedef enum ParticleLifeInputIndex {
    ParticleLifeInputIndexRenderColours = 0,
    ParticleLifeInputIndexParticles = 1,
    ParticleLifeInputIndexParticleCount = 2,
    ParticleLifeInputIndexConfig = 3,
    ParticleLifeInputIndexRandom = 4,
    ParticleLifeInputIndexSpeciesColours = 5,
    ParticleLifeInputIndexWeights = 6,
    ParticleLifeInputIndexTouches = 7,
    ParticleLifeInputIndexTouchCount = 8,
    ParticleLifeInputIndexGradientConfig = 9
} ParticleLifeInputIndex;

typedef struct LifeParticle {
    vector_float2 position;
    vector_float2 velocity;
    vector_float2 acceleration;
    float species;
    float bytes;
} LifeParticle;

typedef struct ParticleLifeTouch {
    vector_float2 position;
} ParticleLifeTouch;

typedef struct ParticleLifeConfig {
    float rMinDistance;
    float rMaxDistance;
    float maxSpeed;
    float drawRadius;
    float trailRadius;
    float cutoff;
    float falloff;
    float speedMultiplier;
    float flavourCount;
    float blurRadius;
    float padding;
    float damping;
    float forceMultiplier;
    float touchRadius;
    float touchForce;
} ParticleLifeConfig;

typedef struct ParticleLifeGradientConfig {
    int32_t isEnabled;
    int32_t isDisplayed;
    int32_t animateOverTime;
    int32_t octaves;
    float forceMultiplier;
    float scale;
    float zOffset;
    float animationSpeed;
    float persistence;
    float lacunarity;
    uint32_t seed;
} ParticleLifeGradientConfig;


struct Vertex {
    vector_float4 position;
    vector_float3 color;
};

#endif /* ShaderTypes_h */
