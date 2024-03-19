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
    static let epsilon = 0.1
    
    init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = abs(radius)
        
        self.bend = 1.0 / abs(radius);
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
}

extension Circle: Identifiable {
    var id: String {
        "\(center.debugDescription).\(radius.description)"
    }
}

// Adapted from https://editor.p5js.org/codingtrain/sketches/zrq8KHXnO
struct ApollonianGasket {
    static let epsilon = 0.1
    
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
        root = Complex.sqrt(root) * 0.5
        
        let center1 = (sum + root) * Float(1 / k4.0)
        let center2 = (sum - root) * Float(1 / k4.0)
        let center3 = (sum + root) * Float(1 / k4.1)
        let center4 = (sum - root) * Float(1 / k4.1)
        
        return [
            Circle(complexCenter: center1, bend: k4.0),
            Circle(complexCenter: center2, bend: k4.0),
            Circle(complexCenter: center3, bend: k4.1),
            Circle(complexCenter: center4, bend: k4.1)
        ];
    }
    
    static func validate(_ c1: Circle, _ c2: Circle, _ c3: Circle, _ newCircle: Circle, _ allCircles: [Circle]) -> Bool {
        
        guard newCircle.radius > 2 else {
            return false
        }
        
        for circle in allCircles {
            let d = newCircle.distance(other: circle)
            let r = abs(circle.radius - newCircle.radius)
            
            guard d > epsilon && r > epsilon else {
                return false
            }
        }
        
        guard c1.isTangent(other: newCircle),
              c2.isTangent(other: newCircle),
              c3.isTangent(other: newCircle) else {
            return false
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

