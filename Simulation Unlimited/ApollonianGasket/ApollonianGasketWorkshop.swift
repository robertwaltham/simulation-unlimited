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
        
        var result = [Circle]()
        var queue = [(a: Circle, b: Circle, c: Circle)]()
        
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
        
        queue.append((a: result[0], b: result[1], c: result[2]))
        
        while !queue.isEmpty {
            let next = queue.popLast()!
            
            let descartes = ApollonianGasket.descartes(next.a, next.b, next.c)
            
            for circle in ApollonianGasket.complexDescartes(next.a, next.b, next.c, descartes) {
                if ApollonianGasket.validate(next.a, next.b, next.c, circle, result) {
                    result.append(circle)
                    
                    queue.append((a: next.a, b: next.b, c: circle))
                    queue.append((a: next.a, b: next.c, c: circle))
                    queue.append((a: next.b, b: next.c, c: circle))
                }
            }
        }

        circles = result
        return result
    }
}


#Preview {
    ApollonianGasketWorkshop()
}
