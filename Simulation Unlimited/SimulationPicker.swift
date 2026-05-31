//
//  SimulationPicker.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-29.
//

import SwiftUI

struct SimulationPicker: View {
    @State private var path: [SimulationRoute] = []
    @State private var renderPickerSimulations = true
    @State private var unplugPickerSimulationsWorkItem: DispatchWorkItem?
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                simulationTile(route: .boids, sim: {
                    BoidsView(viewModel: BoidsViewModel(count: 1024))
                }, text: "Boids", icon: "bird.circle")
                
                simulationTile(route: .slime, sim: {
                    SlimeView(viewModel: SlimeViewModel())
                }, text: "Slime", icon: "drop.circle")
                
                simulationTile(route: .particleLife, sim: {
                    ParticleLifeView(viewModel: ParticleLifeViewModel(count: 1024))
                }, text: "Particle Life", icon: "sun.dust.circle")
                
                simulationTile(route: .hexagons, sim: {
                    HexagonView(viewModel: HexagonViewModel(config: HexagonConfig(shiftX: 58, shiftY: 32)))
                }, text: "Hexagons", icon: "hexagon")
                
                simulationTile(route: .circles, sim: {
                    CircleView(viewModel: CircleViewModel())
                }, text: "Circles", icon: "circle")
                
                
                simulationTile(route: .sand, sim: {
                    SandView(viewModel: SandViewModel())
                }, text: "Sand", icon: "beach.umbrella.fill")
                
                
            }.navigationTitle("Simulations")
                .navigationDestination(for: SimulationRoute.self) { route in
                    destination(for: route)
                }
                .onChange(of: path) { _, newPath in
                    updatePickerSimulationRendering(for: newPath)
                }
        }
    }
}

extension SimulationPicker {
    
    @ViewBuilder
    private func destination(for route: SimulationRoute) -> some View {
        switch route {
        case .boids:
            BoidsWorkshop()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        case .slime:
            SlimeLFOWorkshop()
        case .particleLife:
            ParticleLifeWorkshop()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        case .hexagons:
            HexagonWorkshop()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        case .circles:
            CircleWorkshop()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        case .sand:
            SandWorkshop()
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        }
    }
    
    private func updatePickerSimulationRendering(for path: [SimulationRoute]) {
        unplugPickerSimulationsWorkItem?.cancel()
        
        guard !path.isEmpty else {
            renderPickerSimulations = true
            return
        }
        
        let workItem = DispatchWorkItem {
            renderPickerSimulations = false
        }
        unplugPickerSimulationsWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
    }
    
    @ViewBuilder
    private func simulationTile<Simulation>(route: SimulationRoute, sim: @escaping () -> Simulation, text: String, icon: String) -> some View where Simulation: View {
        NavigationLink(value: route) {
            pickerSimulationPreview(sim: sim)
                .overlay(
                    HStack {
                        Image(systemName: icon)
                            .foregroundStyle(.white, .white)
                            .font(.system(size: 64))
                            .padding()
                        
                        Text(text)
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 20))
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                    }.background(.gray.opacity(0.75), in: RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                )
        }
    }
    
    @ViewBuilder
    private func pickerSimulationPreview<Simulation>(sim: @escaping () -> Simulation) -> some View where Simulation: View {
        if renderPickerSimulations {
            sim()
                .frame(width: 500, height: 200)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
        } else {
            Rectangle()
                .fill(.black)
                .frame(width: 500, height: 200)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
        }
    }
}

private enum SimulationRoute: Hashable {
    case boids
    case slime
    case particleLife
    case hexagons
    case circles
    case sand
}

#Preview {
    SimulationPicker()
}
