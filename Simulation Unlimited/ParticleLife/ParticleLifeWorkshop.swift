//
//  ParticleLifeWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import SwiftUI

struct ParticleLifeWorkshop: View {
    @State var viewModel = ParticleLifeViewModel()
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 15) {
            VStack {
                Text("Speed: \(viewModel.config.speedMultiplier, specifier: "%.2f")")
                    .font(.title)
                Slider(value: $viewModel.config.speedMultiplier, in: 0...viewModel.maxMultiplier)
            }
            
            VStack {
                Text("Falloff: \(viewModel.config.falloff, specifier: "%.3f")")
                    .font(.title)
                Slider(value: $viewModel.config.falloff, in: 0...viewModel.maxFalloff)
            }
            
            VStack() {
                Text("Trail Size: \(Int(viewModel.config.trailRadius))").font(.title)
                Slider(value: $viewModel.config.trailRadius, in: 1...viewModel.maxRadius)
            }
            
        }
        
        ParticleLifeView(viewModel: viewModel)
        
        HStack {
            ForEach(viewModel.getSwiftUIColors(), id: \.self) { c in
                RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                    .foregroundColor(c)
                    .padding(2)
                    .frame(width: 50, height: 50)
            }
        }
        
    }
}

#Preview {
    ParticleLifeWorkshop()
}
