//
//  ApollonianGasketWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-19.
//

import SwiftUI
import Observation

struct ApollonianGasketWorkshop: View {
    @State var viewModel = ViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            
            TapView { touch, optLocation in
                viewModel.updateTouch(touch, location: optLocation)
            }

            ForEach(viewModel.touchCircles(size: geometry.size)) { circle in
                Path { path in
                    path.addArc(center: circle.center, radius: circle.radius, startAngle: Angle.zero, endAngle: Angle.radians(Double.pi * 2.0), clockwise: true)
                }.stroke(Color.black, lineWidth: 1)
            }
        }
        .border(Color.black)
        .background(Color(white: 1.0))
    }
}

@Observable
class ViewModel {
    var touches: [UITouch: CGPoint] = [:]
    var lastCenter: CGPoint = CGPoint()
    var circles = [Circle]() // TODO: is this neccessary?
    
    func updateTouch(_ touch: UITouch, location: CGPoint?) {
        if let location = location {
            touches[touch] = location
            circles.removeAll()
        } else {
            touches.removeValue(forKey: touch)
        }
    }
    
    func touchCircles(size: CGSize) -> [Circle] {
        
        guard circles.isEmpty else {
            return circles
        }
        
        var center2 = lastCenter
        if touches.count >= 1 {
            let points = touches.values.compactMap {$0}
            center2 = points[0]
            lastCenter = center2
        }

        circles = Circle.circles(size: size, center: center2)
        return circles
    }
}


#Preview {
    ApollonianGasketWorkshop()
}
