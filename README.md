# simulation-unlimited
A playground for graphical simulations built using Metal compute shaders and other techniques:
- Hosting a MTKView within SwiftUI using an UIViewRepresentable
- Updating and drawing simulation using a MetalKit compute kernel shader
- Drawing shapes using Signed Distance Functions

## Boids

A classic flocking simulation

Inspiriations for building this:
- https://www.youtube.com/watch?v=gpc7u3331oQ
- https://www.youtube.com/watch?v=bqtqltqcQhw

Original Boids papers and reference:
- http://www.red3d.com/cwr/boids/
- http://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/

I based my implementation off this code:
- https://github.com/womogenes/Boids

## Slime

A particle simulation based on the behaviour of slime mold
- 3 particle flavours that use red/green/blue channel as their trail
- Each particle decides to turn left or right based on sampling the trail in front of them
- As it moves it lays down trail underneath it, and deletes the other flavour's trails
- Flavours can also follow trails from different texture, including a hexagon grid tiling 

I took inspiration from modular synthesizers and using a low frequency oscillator as "magic hands" to change the simulation parameters over time
- speed
- turn angle
- turn bias
- trail falloff
- path vs hexagon 

Inspiration for building this:
- https://www.youtube.com/watch?v=X-iSQQgOd1A

Paper that this algorithm comes from
- https://cargocollective.com/sagejenson/physarum

I based my implementation (in part) off of this code:
- https://github.com/fogleman/physarum
- https://www.shadertoy.com/view/WtySRc (hexagon SDF)

## Particle Life

A more generalized version of a flocking simulation, where each particle flavour has different attraction/repulsion to other flavours.

Inspiration for building this:
- https://www.youtube.com/watch?v=p4YirERTVF0

I based my implementation (in part) off this code:
https://github.com/tom-mohr/particle-life-app

## Other References

Extremely Helpful Articles and Examples:
- https://metalbyexample.com/modern-metal-1/
- https://metalkit.org/2017/11/30/working-with-particles-in-metal-part-3/
- https://eugenebokhan.io/introduction-to-metal-compute-part-two
- https://github.com/RedQueenCoder/Metal-Learning-Projects
- https://github.com/mateuszbuda/GPUExample/tree/master/GPUExample
- https://iquilezles.org/articles/distgradfunctions2d/


![IMG_0036](https://github.com/robertwaltham/simulation-unlimited/assets/438673/abf0a992-c329-46f5-aff3-3d4c23d514e1)
![IMG_0037](https://github.com/robertwaltham/simulation-unlimited/assets/438673/2dd6d38b-1608-48e5-8be9-d6e4442698e0)

