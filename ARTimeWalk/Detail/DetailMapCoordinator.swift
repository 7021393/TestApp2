//
//  DetailMapCoordinator.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/22.
//

import MapKit

class DetailMapCoordinator: NSObject, MKMapViewDelegate {
    let parent: DetailMapViewContainer
    
    init(_ parent: DetailMapViewContainer) {
        self.parent = parent
    }
    
    // Make Annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let annotationView =  MKMarkerAnnotationView()
        annotationView.markerTintColor = UIColor.digitalBlue_uiColor
        
        // Single Annotation
        if let addedAnnotation = annotation as? OriginalAnnotation {
            if addedAnnotation.reference.userID == 0 || addedAnnotation.reference.userID == ARTimeWalkApp.isUserID || 0 < addedAnnotation.reference.yourPhotoCount {
                annotationView.markerTintColor = UIColor.systemTeal
            }
        }
        
        annotationView.glyphImage = UIImage(systemName: "photo")
        return annotationView
    }
}
