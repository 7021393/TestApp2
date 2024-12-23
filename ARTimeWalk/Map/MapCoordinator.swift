//
//  MapCoordinator.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/10.
//

import MapKit

class MapCoordinator: NSObject, MKMapViewDelegate {
    let parent: MapViewContainer
    
    init(_ parent: MapViewContainer) {
        self.parent = parent
    }
    
    // MARK: Annotation
    
    // Make Annotation
    func mapView(_ mapView: MKMapView, viewFor mkAnnotation: MKAnnotation) -> MKAnnotationView? {
        if mkAnnotation is MKUserLocation { return nil }
        
        let annotationView =  MKMarkerAnnotationView()
        annotationView.markerTintColor = UIColor.digitalBlue_uiColor
        
        // Single Annotation
        if let addedAnnotation = mkAnnotation as? OriginalAnnotation {
            if addedAnnotation.annotationType != .minimum { // MinimumReferenceはTealにしない
                if addedAnnotation.reference.userID == 0 || addedAnnotation.reference.userID == ARTimeWalkApp.isUserID || 0 < addedAnnotation.reference.yourPhotoCount {
                    annotationView.markerTintColor = UIColor.systemTeal
                }
            }
        }
        
        // Cluster Annotation
        if let cluster = mkAnnotation as? MKClusterAnnotation {
            let annotations = cluster.memberAnnotations
            for annotation in annotations {
                if let addedAnnotation = annotation as? OriginalAnnotation {
                    if addedAnnotation.annotationType != .minimum { // MinimumReferenceはTealにしない
                        if addedAnnotation.reference.userID == 0 || addedAnnotation.reference.userID == ARTimeWalkApp.isUserID || 0 < addedAnnotation.reference.yourPhotoCount {
                            annotationView.markerTintColor = UIColor.systemTeal
                        }
                    }
                }
            }
        }
        
        annotationView.glyphImage = UIImage(systemName: "photo")
        annotationView.clusteringIdentifier = "cluster"
        return annotationView
    }
    
    // Annotation Select
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation { return }
        
        let mapRange = parent.model.map.getMapRange()
        // 地図の表示範囲によって処理を分岐
        if parent.model.dataRange < mapRange.2 { // 表示範囲が広い
            // Single Annotation
            if let singleAnnotation = view.annotation {
                parent.model.map.annotationZoom(annotation: singleAnnotation)
                changeAnnotation(annotation: singleAnnotation, range: parent.model.dataRange)
            }
            
            // Cluster Annotation
            if let cluster = view.annotation as? MKClusterAnnotation {
                let annotations = cluster.memberAnnotations
                if let firstAnnotation = annotations.first {
                    parent.model.map.annotationZoom(annotation: firstAnnotation)
                    changeAnnotation(annotation: firstAnnotation, range: parent.model.dataRange)
                }
            }
        } else { // 表示範囲が狭い
            // Single Annotation
            if let singleAnnotation = view.annotation as? OriginalAnnotation {
                if singleAnnotation.annotationType == .minimum {
                    let range = parent.model.map.getMapRange()
                    changeAnnotation(annotation: singleAnnotation, range: range.2)
                } else {
                    parent.model.setDataTransferAnnotationArray(dataTransfer: parent.dataTransfer, selectedAnnotation: singleAnnotation, index: 0)
                    // ScrollBarを表示
                    parent.model.appearScrollBar()
                }
            }
            
            // Cluster Annotation
            if let cluster = view.annotation as? MKClusterAnnotation {
                let annotations = cluster.memberAnnotations
                if let firstAnnotation = annotations.first as? OriginalAnnotation {
                    if firstAnnotation.annotationType == .minimum {
                        let range = parent.model.map.getMapRange()
                        changeAnnotation(annotation: firstAnnotation, range: range.2)
                    } else {
                        // Cluster Annotationを逐次処理
                        for (index, oneOfAnnotations) in annotations.enumerated() {
                            let annotation: OriginalAnnotation = oneOfAnnotations as! OriginalAnnotation
                            parent.model.setDataTransferAnnotationArray(dataTransfer: parent.dataTransfer, selectedAnnotation: annotation, index: index)
                        }
                        // ScrollBarを表示
                        parent.model.appearScrollBar()
                    }
                }
            }
        }
    }
    
    // NetworkAnnotationまたはNormalAnnotationを取得し交換
    func changeAnnotation(annotation: MKAnnotation, range: Double) {
        if parent.model.selectedDataSource == .global {
            parent.model.map.removeAllAnnotations()
            let latitude = annotation.coordinate.latitude
            let longitude = annotation.coordinate.longitude
            Task {
                await parent.model.getNetworkReferenceDataFromServerDB(latitude: latitude, longitude: longitude, range: range)
            }
        }
    }
    
    // Annotation Deselect
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.annotation is MKUserLocation { return }
        
        parent.model.resetDataTransferAnnotationArray(dataTransfer: parent.dataTransfer)
        parent.model.disappearScrollBar()
    }
    
    // MARK: Network Line
    
    // Make Network Line
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer: MKOverlayPathRenderer
        renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3
        renderer.strokeColor = UIColor.digitalBlue
        renderer.lineDashPattern = [5, 5]
        
        return renderer
    }
    
    var mapRangeIsSmall: Bool = false
    
    // Show/Hide Network Line
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if parent.model.selectedDataSource == .global {
            let mapRange = parent.model.map.getMapRange()
            
            if mapRangeIsSmall {
                // 前回の地図範囲が狭い場合
                // 地図範囲が広くなった場合のみ処理を行う
                if parent.model.linkRange < mapRange.2 {
                    // 描画されているLineを全て削除
                    parent.model.map.removeAllLines()
                    
                    mapRangeIsSmall = false
                }
            } else {
                // 前回の地図範囲が広い場合
                // 地図範囲が狭くなった場合のみ処理を行う
                if mapRange.2 <= parent.model.linkRange {
                    // Lineを描画
                    parent.model.map.drawLine()
                    
                    mapRangeIsSmall = true
                }
            }
        }
    }
}
