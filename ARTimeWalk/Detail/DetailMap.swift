//
//  DetailMap.swift
//  ARTimeWalk
//
//  Created by member on 2024/01/19.
//

import MapKit

class DetailMap: NSObject, CLLocationManagerDelegate {
    let mapView: MKMapView = MKMapView()
    
    func makeMapView() -> MKMapView {
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false
        
        return mapView
    }
    
    func setMap(reference: ReferenceContainer) {
        let region: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: reference.latitude + 0.0001, longitude: reference.longitude),
            latitudinalMeters: 50.0,
            longitudinalMeters: 50.0)
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        let center = CLLocationCoordinate2D(latitude: reference.latitude, longitude: reference.longitude)
        annotation.coordinate = center

        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: false)
    }
    
    func removeAllAnnotations() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func changeMapType(index: Int) {
        switch index {
        case 0:
            mapView.mapType = .standard
        default:
            mapView.mapType = .hybrid
        }
    }
}
