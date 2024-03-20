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
                }.stroke(Color.black, lineWidth: 3)
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
    func updateTouch(_ touch: UITouch, location: CGPoint?) {
        if let location = location {
            touches[touch] = location
        } else {
            touches.removeValue(forKey: touch)
        }
    }
    
    func touchCircles(size: CGSize) -> [Circle] {
        var result = [Circle]()
        
        let center1 = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let radius1 = (min(size.width, size.height) - 10.0) / 2.0
        result.insert(Circle(center: center1, radius: -radius1), at: 0)
        
        var center2 = lastCenter
        if touches.count >= 1 {
            let points = touches.values.compactMap {$0}
            center2 = points[0]
            lastCenter = center2
        }
        
        let radius2 = radius1 - center2.distance(from: center1)
        let radius3 = radius1 - radius2

        let center3 = center2
        .applying(CGAffineTransform(translationX: -center1.x, y: -center1.y))
        .applying(CGAffineTransform(rotationAngle: CGFloat.pi))
        .normalize()
        .applying(CGAffineTransform(scaleX: radius1 - radius3, y: radius1 - radius3))
        .applying(CGAffineTransform(translationX: center1.x, y: center1.y))
        
        result.append(Circle(center: center2, radius: radius2))
        result.append(Circle(center: center3, radius: radius3))
        
        let descartes = ApollonianGasket.descartes(result[0], result[1], result[2])
        let gaskets = ApollonianGasket.complexDescartes(result[0], result[1], result[2], descartes)
        
        
        result.append(contentsOf: gaskets)
        
        for circle in result {
            print(circle)
        }
                
        return result
    }
}


#Preview {
    ApollonianGasketWorkshop()
}
