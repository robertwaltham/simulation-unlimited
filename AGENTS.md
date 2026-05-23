# Project Instructions

## Project Overview

Simulation Unlimited is a SwiftUI iOS playground for graphical simulations backed by Metal and MetalKit. The app starts in `Simulation_UnlimitedApp.swift` and presents simulation entries from `SimulationPicker.swift`.

The main simulations live in separate folders:

- `Boids/`
- `Slime/`
- `ParticleLife/`
- `Sand/`
- `ApollonianGasket/`
- `Bestagons/`
- `LFO/`

Most simulation screens use a SwiftUI `UIViewRepresentable` wrapper around `MTKView`, a view model for tunable parameters, and one or more Metal shader files.

## Important Runtime Notes

- Many simulations require read-write Metal textures and are intended for physical iOS devices with A11-class GPUs or newer.
- Do not assume the simulations will render correctly in the iOS Simulator.
- The current active developer directory is full Xcode: `/Applications/Xcode.app/Contents/Developer`.
- In sandboxed agent sessions, `xcodebuild` may still fail while resolving Swift packages if it cannot write to user cache directories such as `~/.cache/clang/ModuleCache` or `~/Library/Caches/org.swift.swiftpm`.

## Code Style

- Follow the existing folder pattern: each simulation keeps its SwiftUI view, view model, workshop/control view, and Metal shader file together.
- Prefer small, local changes that preserve each simulation's current pipeline structure.
- Keep SwiftUI control surfaces in workshop files and rendering/Metal lifecycle code in view files.
- Avoid broad refactors unless the user asks for them or they are necessary to fix a bug.
- Use ASCII in new source and documentation unless the surrounding file already uses non-ASCII text.

## Metal And Swift Interop

- Shared CPU/GPU constants and buffer indices belong in `ShaderTypes.h`.
- Keep Swift buffer layouts aligned with Metal shader structs. When changing structs used by both Swift and Metal, verify size, padding, and field order carefully.
- Prefer typed enums and existing index constants over hard-coded buffer or texture slots.
- Be careful with `MTLTextureUsage.shaderRead`, `shaderWrite`, and `renderTarget`; several simulations depend on read-write textures.

## SwiftUI And MTKView Notes

- `UIViewRepresentable` types should update coordinator state in `updateUIView`.
- Keep Metal resource creation in the coordinator or helper methods near the coordinator.
- Avoid putting heavy GPU setup work directly in SwiftUI `body` builders.
- Preserve `MTKViewDelegate` draw lifecycle behavior unless changing the render loop is part of the task.

## Verification

When possible, verify changes with:

```sh
xcodebuild -project "Simulation Unlimited.xcodeproj" -scheme "Simulation Unlimited" -destination 'generic/platform=iOS' build
```

For UI or rendering changes, prefer testing on a physical device. Simulator results may be incomplete because of Metal feature requirements.

## Git Hygiene

- Do not revert unrelated local changes.
- Xcode user/workspace files may appear as untracked local files; leave them alone unless the user asks to manage them.
- Keep generated build output and DerivedData out of commits.
