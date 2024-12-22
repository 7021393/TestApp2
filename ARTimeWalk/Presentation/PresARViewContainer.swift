//
//  PresARViewContainer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/08.
//

import SwiftUI
import RealityKit

struct PresARViewContainer: UIViewRepresentable {
    var model: PresDataModel
    @Binding var currentPhotoDistance: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = model.presAr.makeARView()
        
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> PresCoordinator {
        PresCoordinator(self)
    }
}
