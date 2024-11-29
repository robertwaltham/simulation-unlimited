//
//  SandWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-29.
//

import SwiftUI

public struct SandWorkshop: View {
    @State var viewModel = SandViewModel()

    
    public var body: some View {
        ZStack {
            SandView(viewModel: viewModel)
            TapView { touch, optLocation in
                viewModel.updateTouch(touch, location: optLocation)
            }
        }
    }

}
