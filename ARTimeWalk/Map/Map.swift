//
//  Map.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/11.
//

import MapKit

class Map: NSObject, CLLocationManagerDelegate {
    let mapView: MKMapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    // Network Line
    var annotationLocationArray: [(Int, Double, Double)] = []
    var referenceLinkArray: [(Int, Int)] = []
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func makeMapView() -> MKMapView {
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.tintColor = UIColor.systemBlue // ユーザの位置の色
        
        updateGNSSTrackingMode()
        
        return mapView
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateGNSSTrackingMode()
    }
    
    // アプリ起動時の位置情報設定に対応
    // アプリ起動中の位置情報設定変更に対応
    func updateGNSSTrackingMode() {
        let guarded = locationManager.authorizationStatus.rawValue
        switch guarded {
        case 2:
            mapView.userTrackingMode = MKUserTrackingMode.none
        default:
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
            mapView.userTrackingMode = MKUserTrackingMode.follow
        }
    }
    
    // 画面に写る地図範囲における、画面中央から画面端までの実距離を取得
    func getMapRange() -> (Double, Double, Double) {
        // 現在の地図の表示範囲(region)を取得
        let visibleRegion = mapView.region
        
        // 表示範囲から中心座標を取得
        let centerCoordinate = visibleRegion.center
        
        // 中心座標から画面端までの距離を算出
        let centerPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let edgeCoordinatePoint = CGPoint(x: centerPoint.x, y: centerPoint.y + mapView.bounds.height / 2)
        let edgeCoordinate = mapView.convert(edgeCoordinatePoint, toCoordinateFrom: mapView)
        let edgeLocation = CLLocation(latitude: edgeCoordinate.latitude, longitude: edgeCoordinate.longitude)
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let range = centerLocation.distance(from: edgeLocation)
        
        return (centerLocation.coordinate.latitude, centerLocation.coordinate.longitude, range)
    }
    
    func annotationZoom(annotation: MKAnnotation) {
        mapView.deselectAnnotation(annotation, animated: false)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025)
        let center = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
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
    
    /**
     Reference同士がNetworkによって紐付けられている状態を可視化する線を描画
     
     ※ Referenceの削除が行われている特定のNetwork構造は可視化できていない。
     例："A --- B --- C" -> "A --- (B) --- C"
     Reference B が削除され、NetworkによってAとCが紐付けられている状態
     AとCを結ぶ線の描画も検討にあったが、AとCを直接紐付けるLinkと混同する可能性から保留にしている。
     */
    func drawLine() {
        for link in referenceLinkArray {
            guard let fromTuple = annotationLocationArray.first(where: { $0.0 == link.0 }),
                  let toTuple = annotationLocationArray.first(where: { $0.0 == link.1 }) else {
                continue
            }
            
            let fromLocation = CLLocationCoordinate2D(latitude: fromTuple.1, longitude: fromTuple.2)
            let toLocation = CLLocationCoordinate2D(latitude: toTuple.1, longitude: toTuple.2)
            
            let line = MKPolyline(coordinates: [fromLocation, toLocation], count: 2)
            self.mapView.addOverlay(line)
        }
    }
    
    func removeAllLines() {
        mapView.removeOverlays(mapView.overlays)
    }
    
    func resetLineVariables() {
        annotationLocationArray.removeAll()
        referenceLinkArray.removeAll()
    }
}
