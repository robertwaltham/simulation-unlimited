//
//  SimulationPicker.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-29.
//

import SwiftUI

struct SimulationPicker: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                simulationTile(content: {
                    BoidsWorkshop()
                        .edgesIgnoringSafeArea(.all)
                        .statusBar(hidden: true)
                }, sim: {
                    BoidsView(viewModel: BoidsViewModel(count: 1024))
                }, text: "Boids", icon: "bird.circle")
                
                simulationTile(content: {
                    SlimeLFOWorkshop()
                }, sim: {
                    SlimeView(viewModel: SlimeViewModel())
                }, text: "Slime", icon: "drop.circle")
                
                simulationTile(content: {
                    ParticleLifeWorkshop()        
                        .edgesIgnoringSafeArea(.all)
                        .statusBar(hidden: true)
                }, sim: {
                    ParticleLifeView(viewModel: ParticleLifeViewModel())
                }, text: "Particle Life", icon: "sun.dust.circle")
                
//                simulationTile(content: {
//                    HexagonWorkshop()
//                        .edgesIgnoringSafeArea(.all)
//                        .statusBar(hidden: true)
//                }, sim: {
//                    HexagonView(viewModel: HexagonViewModel(config: HexagonConfig(shiftX: 58, shiftY: 32)))
//                }, text: "Hexagons", icon: "hexagon")
                
                simulationTile(content: {
                    CircleWorkshop()
                        .edgesIgnoringSafeArea(.all)
                        .statusBar(hidden: true)
                }, sim: {
                    CircleView(viewModel: CircleViewModel())
                }, text: "Circles", icon: "circle")
                
                
            }.navigationTitle("Simulations")
        }
    }
}

extension SimulationPicker {
    
    @ViewBuilder
    func simulationTile<Content, Simulation>(content: @escaping () -> Content, sim: @escaping () -> Simulation, text: String, icon: String) -> some View where Content: View, Simulation: View {
        NavigationLink {
            content()
        } label: {
            sim()
                .frame(width: 500, height: 200)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
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
}

#Preview {
    SimulationPicker()
}
