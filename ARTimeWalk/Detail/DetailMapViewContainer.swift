//
//  DetailMapViewContainer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/22.
//

import SwiftUI
import MapKit

struct DetailMapViewContainer: UIViewRepresentable {
    let model: DetailDataModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = model.detailMap.makeMapView()
        
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    func makeCoordinator() -> DetailMapCoordinator {
        DetailMapCoordinator(self)
    }
}

