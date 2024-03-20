# simulation-unlimited
A playground for graphical simulations built using Metal compute shaders and other techniques:
- Hosting a MTKView within SwiftUI using an UIViewRepresentable
- Updating and drawing simulation using a MetalKit compute kernel shader
- Drawing shapes using Signed Distance Functions

## Slime

A particle simulation based on the behaviour of slime mold
- 3 particle flavours that use red/green/blue channel as their trail
- Each particle decides to turn left or right based on sampling the trail in front of them
- As it moves it lays down trail underneath it, and deletes the other flavour's trails
- Flavours can also follow trails from different texture, including a hexagon grid tiling 
![IMG_0044](https://github.com/robertwaltham/simulation-unlimited/assets/438673/39251722-ef12-407f-a599-df94acfd75e1)

I took inspiration from modular synthesizers and using a low frequency oscillator as "magic hands" to change the simulation parameters over time
- speed
- turn angle
- turn bias
- trail falloff
- path vs hexagon 
![IMG_0046](https://github.com/robertwaltham/simulation-unlimited/assets/438673/67c5c6ef-1a49-4d09-8c10-5af197b142df)


Inspiration for building this:
- https://www.youtube.com/watch?v=X-iSQQgOd1A

Paper that this algorithm comes from
- https://cargocollective.com/sagejenson/physarum

I based my implementation (in part) off of this code:
- https://github.com/fogleman/physarum
- https://www.shadertoy.com/view/WtySRc (hexagon SDF)

## Boids

A classic flocking simulation
![IMG_0043](https://github.com/robertwaltham/simulation-unlimited/assets/438673/9110b189-cd09-45bc-b432-20b56434729f)

Inspiriations for building this:
- https://www.youtube.com/watch?v=gpc7u3331oQ
- https://www.youtube.com/watch?v=bqtqltqcQhw

Original Boids papers and reference:
- http://www.red3d.com/cwr/boids/
- http://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/

I based my implementation off this code:
- https://github.com/womogenes/Boids

## Particle Life

A more generalized version of a flocking simulation, where each particle flavour has different attraction/repulsion to other flavours.

![IMG_0045](https://github.com/robertwaltham/simulation-unlimited/assets/438673/558c13d5-a2bc-4206-a172-c4ed40e24a7f)

Inspiration for building this:
- https://www.youtube.com/watch?v=p4YirERTVF0

I based my implementation (in part) off this code:
- https://github.com/tom-mohr/particle-life-app

## Other References

Extremely Helpful Articles and Examples:
- https://metalbyexample.com/modern-metal-1/
- https://metalkit.org/2017/11/30/working-with-particles-in-metal-part-3/
- https://eugenebokhan.io/introduction-to-metal-compute-part-two
- https://github.com/RedQueenCoder/Metal-Learning-Projects
- https://github.com/mateuszbuda/GPUExample/tree/master/GPUExample
- https://iquilezles.org/articles/distgradfunctions2d/




