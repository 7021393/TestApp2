//
//  MapViewContainer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/10.
//

import SwiftUI
import MapKit

struct MapViewContainer: UIViewRepresentable {
    let model: MapDataModel
    let dataTransfer: DataTransfer
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = model.map.makeMapView()
        
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(self)
    }
}
