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
                
                NavigationLink {
                    Text("TODO")
                } label: {
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .stroke(lineWidth: 1.0)
                        .overlay(
                            HStack {
                                Image(systemName: "bird.circle")
                                      .foregroundStyle(.teal, .gray)
                                      .font(.system(size: 64))
                                      .padding()
                                
                                Text("Boids")
                                    .padding()
                                    .font(.largeTitle)
                                
                            })
                        .frame(width: 500, height: 200)
                }
                
                NavigationLink {
//                    SlimeView()
                    Text("TODO")
                } label: {
//                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
//                        .stroke(lineWidth: 1.0)
//                        .overlay(
//                            HStack {
//                                Image(systemName: "drop.circle")
//                                      .foregroundStyle(.teal, .gray)
//                                      .font(.system(size: 64))
//                                      .padding()
//                                
//                                Text("Slime")
//                                    .padding()
//                                    .font(.largeTitle)
//                                
//                            })
//                        .frame(width: 500, height: 200)
                    SlimeView()
                        .frame(width: 500, height: 200)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                        .overlay(
                            HStack {
                                Image(systemName: "drop.circle")
                                      .foregroundStyle(.white, .white)
                                      .font(.system(size: 64))
                                      .padding()
                                
                                Text("Slime")
                                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 20))
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    
                            }.background(.gray.opacity(0.75), in: RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                        )
                }
                
                NavigationLink {
                    Text("TODO")
                } label: {
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .stroke(lineWidth: 1.0)
                        .overlay(
                            HStack {
                                Image(systemName: "sun.dust.circle")
                                      .foregroundStyle(.teal, .gray)
                                      .font(.system(size: 64))
                                      .padding()
                                
                                Text("Particle Life")
                                    .padding()
                                    .font(.largeTitle)
                                
                            })
                        .frame(width: 500, height: 200)
                }

            }.navigationTitle("Simulations")
        }
    }
}

#Preview {
    SimulationPicker()
}
