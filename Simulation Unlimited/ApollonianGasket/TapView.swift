//
//  TapView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-19.
//

import Foundation
import UIKit
import SwiftUI

// adapted from https://stackoverflow.com/questions/61566929/swiftui-multitouch-gesture-multiple-gestures

class NFingerGestureRecognizer: UIGestureRecognizer {

    var tappedCallback: (UITouch, CGPoint?) -> Void

    var touchViews = [UITouch:CGPoint]()

    init(target: Any?, tappedCallback: @escaping (UITouch, CGPoint?) -> ()) {
        self.tappedCallback = tappedCallback
        super.init(target: target, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            let location = touch.location(in: touch.view)
            touchViews[touch] = location
            tappedCallback(touch, location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            let newLocation = touch.location(in: touch.view)
            touchViews[touch] = newLocation
            tappedCallback(touch, newLocation)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            touchViews.removeValue(forKey: touch)
            tappedCallback(touch, nil)
        }
    }
}

struct TapView: UIViewRepresentable {

    var tappedCallback: (UITouch, CGPoint?) -> Void

    func makeUIView(context: UIViewRepresentableContext<TapView>) -> TapView.UIViewType {
        let v = UIView(frame: .zero)
        let gesture = NFingerGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TapView>) {
        // empty
    }

}

