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
                    BoidsView().navigationTitle("Boids")
                }, sim: {
                    BoidsView()
                }, text: "Boids", icon: "bird.circle")
                
                simulationTile(content: {
                    SlimeLFOWorkshop().navigationTitle("Slime")
                }, sim: {
                    SlimeView(viewModel: SlimeViewModel())
                }, text: "Slime", icon: "drop.circle")
                
                simulationTile(content: {
                    ParticleLifeView(viewModel: ParticleLifeViewModel()).navigationTitle("Particle Life")
                }, sim: {
                    ParticleLifeView(viewModel: ParticleLifeViewModel())
                }, text: "Particle Life", icon: "sun.dust.circle")
                
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
