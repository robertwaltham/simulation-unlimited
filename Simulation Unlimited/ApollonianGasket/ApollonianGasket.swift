//
//  ApollonianGasket.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-19.
//

import Foundation
import Numerics

/*
 Adapted from https://thecodingtrain.com/challenges/182-apollonian-gasket
 */

struct Circle {
    let center: CGPoint
    let radius: CGFloat
    let bend: CGFloat
    let complexCenter: Complex<Float>
    static let epsilon = 0.01
    
    init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = abs(radius)
        
        self.bend = 1.0 / radius;
        self.complexCenter = Complex(Float(center.x), Float(center.y))
    }
    
    init(complexCenter: Complex<Float>, bend: CGFloat) {
        self.complexCenter = complexCenter
        self.bend = bend
        self.radius = abs(1 / bend)
        self.center = CGPoint(x: CGFloat(complexCenter.real), y: CGFloat(complexCenter.imaginary))
    }
    
    func distance(other: Circle) -> CGFloat {
        return self.center.distance(from: other.center)
    }
    
    func isTangent(other: Circle) -> Bool {
        let d = self.distance(other: other)
        let r1 = self.radius
        let r2 = other.radius
        // Tangency check based on distances and radii
        let a = abs(d - (r1 + r2)) < Circle.epsilon
        let b = abs(d - abs(r2 - r1)) < Circle.epsilon
        return a || b;
    }
    
    func toShader() -> ShaderCircle {
        return ShaderCircle(x: Float(center.x), y: Float(center.y), r: Float(radius))
    }
    
    static func circles(size: CGSize, center: CGPoint) -> [Circle] {
        var result = [Circle]()
        var queue = [(a: Circle, b: Circle, c: Circle)]()
        
        let center1 = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let radius1 = (min(size.width, size.height) - 10.0) / 2.0
        result.insert(Circle(center: center1, radius: -radius1), at: 0)
        
        let center2 = center
        
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
        
        return result
    }
}

struct ShaderCircle {
    let x: Float
    let y: Float
    let r: Float
}

extension Circle: Identifiable {
    var id: String {
        "\(center.debugDescription).\(radius.description)"
    }
}

// Adapted from https://editor.p5js.org/codingtrain/sketches/zrq8KHXnO
struct ApollonianGasket {
    static let epsilon = 0.01
    
    static func descartes(_ c1: Circle, _ c2: Circle, _ c3: Circle) -> (CGFloat, CGFloat) {
        let k1 = c1.bend
        let k2 = c2.bend
        let k3 = c3.bend
        // Sum and product of curvatures for Descartes' theorem
        let sum = k1 + k2 + k3
        let product = abs((k1 * k2) + (k2 * k3) + (k1 * k3))
        let root = 2 * sqrt(product)
        return (sum + root, sum - root)
    }
    
    static func complexDescartes(_ c1: Circle, _ c2: Circle, _ c3: Circle, _ k4: (CGFloat, CGFloat)) -> [Circle] {
        
        // Curvature and center calculations for new circles
        let k1 = Float(c1.bend)
        let k2 = Float(c2.bend)
        let k3 = Float(c3.bend)
        
        let z1 = c1.complexCenter
        let z2 = c2.complexCenter
        let z3 = c3.complexCenter
        
        let zk1 = z1 * k1
        let zk2 = z2 * k2
        let zk3 = z3 * k3
        let sum = zk1 + zk2 + zk3
        
        var root = (zk1 * zk2) + (zk2 * zk3) + (zk1 * zk3)
        root = Complex.sqrt(root) * 2.0
        
        let center1 = (sum + root) * Float(1 / k4.0)
        let center2 = (sum - root) * Float(1 / k4.0)
        let center3 = (sum + root) * Float(1 / k4.1)
        let center4 = (sum - root) * Float(1 / k4.1)
        
        return [
            Circle(complexCenter: center1, bend: k4.0),
            Circle(complexCenter: center2, bend: k4.0),
            Circle(complexCenter: center3, bend: k4.1),
            Circle(complexCenter: center4, bend: k4.1)
        ]
    }
    
    static func validate(_ c1: Circle, _ c2: Circle, _ c3: Circle, _ newCircle: Circle, _ allCircles: [Circle]) -> Bool {
        
        guard newCircle.radius > 5 else { // TODO: pass this value in
            return false
        }
        
        guard c1.isTangent(other: newCircle) &&
              c2.isTangent(other: newCircle) &&
              c3.isTangent(other: newCircle) else {
            return false
        }
        
        for circle in allCircles {
            let d = newCircle.distance(other: circle)
            let r = abs(circle.radius - newCircle.radius)
            
            guard d > epsilon || r > epsilon else {
                return false
            }
        }
        return true
    }
}

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
    
    func magnitude() -> CGFloat {
        return sqrt(pow(x, 2) + pow(y, 2))
    }
    
    func normalize() -> CGPoint {
        let m = magnitude()
        return CGPoint(x: x / m, y: y / m)
    }
}

extension Complex<Float> {
    static func * (lhs: Complex<Float>, rhs: Float) -> Self {
        return Complex(lhs.real * rhs, lhs.imaginary * rhs)
    }
}

