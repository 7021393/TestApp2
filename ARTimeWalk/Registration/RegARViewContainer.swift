//
//  RegARViewContainer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/07.
//

import SwiftUI
import RealityKit

struct RegARViewContainer: UIViewRepresentable {
    let model: RegDataModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = model.regAr.makeARView()
        
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> RegCoordinator {
        RegCoordinator(self)
    }
}
