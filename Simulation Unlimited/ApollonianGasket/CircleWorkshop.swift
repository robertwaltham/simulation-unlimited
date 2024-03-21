//
//  CircleWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-20.
//

import Foundation
import SwiftUI
import Observation

struct CircleWorkshop: View {
    @State var viewModel = CircleViewModel()
    
    var body: some View {
        ZStack {

            
            CircleView(viewModel: viewModel)
            TapView { touch, optLocation in
                viewModel.updateTouch(touch, location: optLocation)
            }
            VStack {
                Spacer()
                
                Slider(value: $viewModel.config.radius, in: 0.0...100.0)
                    .padding()
            }
            

        }
    }
}

#Preview {
    CircleWorkshop()
}
