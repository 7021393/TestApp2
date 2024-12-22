//
//  MapGet.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/12.
//

import MapKit

extension MapDataModel {
    // MARK: Minimum
    private struct Encode_Range: Codable {
        let latitude: Double
        let longitude: Double
        let range: Double
    }
    
    private struct Decode_MinimumReference: Codable {
        let id: String
        
        let latitude: String
        let longitude: String
    }
    
    // 広範囲のデータ取得に対応、データ取得先をReferenceDBに限定（PhotoCountの取得やNetworkの探索を行わない）
    func getMinimumReferenceDataFromServerDB(latitude: Double, longitude: Double, range: Double) async {
        // struct
        let record = Encode_Range(latitude: latitude,
                                  longitude: longitude,
                                  range: range)
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "select/selectMinimumReferenceData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode([Decode_MinimumReference].self, from: data)
                        
                        // データを順番に開封
                        for data in decodeData {
                            // Annotation生成
                            let reference = ReferenceContainer(id: Int(data.id)!,
                                                               uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                                                               serverID: 0,
                                                               userID: 0,
                                                               userName: "",
                                                               jpegDataFileName: "fileName",
                                                               
                                                               jpegData: nil,
                                                               
                                                               dataSizeKB: 0.0,
                                                               latitude: Double(data.latitude)!,
                                                               longitude: Double(data.longitude)!,
                                                               magneticHeading: 0.0,
                                                               physicalWidth: 0.3,
                                                               registrationDate: "0000-00-00 00:00:00",
                                                               
                                                               photoCount: 0,
                                                               yourPhotoCount: 0,
                                                               
                                                               detailButton: false)
                            
                            let annotation = OriginalAnnotation(reference: reference,
                                                                connectedReference: [],
                                                                network: [],
                                                                annotationType: .minimum)
                            
                            guard let latitude = Double(data.latitude) else { return }
                            guard let longitude = Double(data.longitude) else { return }
                            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            annotation.coordinate = center
                            
                            await self.map.mapView.addAnnotation(annotation)
                        }
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), MapGet.swift getMinimumReferenceDataFromServerDB()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), MapGet.swift getMinimumReferenceDataFromServerDB()")
            }
        }
    }
    
    // MARK: Network
    private struct Encode_IDandRange: Codable {
        let id: Int
        let latitude: Double
        let longitude: Double
        let range: Double
    }
    
    private struct Decode_NetworkReference: Codable {
        let reference: Decode_NormalReference
        let connectedReference: [String]
        let network: [Decode_Link_Reference]
    }
    
    private struct Decode_NormalReference: Codable {
        let id: String
        let uuid: String
        let userID: String
        let userName: String
        let jpegDataFileName: String
        
        let dataSizeKB: String
        let latitude: String
        let longitude: String
        let magneticHeading: String
        let physicalWidth: String
        let registrationDate: String
        
        let photoCount: String
        let yourPhotoCount: String
    }
    
    private struct Decode_Link_Reference: Codable {
        let id: String
        let uuid: String
        let fromReferenceID: String
        let toReferenceID: String
        
        let positionX: String
        let positionY: String
        let positionZ: String
        
        let eulerX: String
        let eulerY: String
        let eulerZ: String
        
        let registrationDate: String
        let lastUpdateDate: String
    }
    
    // Network機能のOnに対応、PhotoCountの取得、Networkの探索を行う
    func getNetworkReferenceDataFromServerDB(latitude: Double, longitude: Double, range: Double) async {
        // struct
        let record = Encode_IDandRange(id: ARTimeWalkApp.isUserID,
                                       latitude: latitude,
                                       longitude: longitude,
                                       range: range)
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "select/selectNetworkReferenceData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode([Decode_NetworkReference].self, from: data)
                        
                        // データを順番に開封
                        for data in decodeData {
                            // Annotation生成
                            let reference = ReferenceContainer(id: Int(data.reference.id)!,
                                                               uuid: "\(data.reference.uuid)",
                                                               serverID: Int(data.reference.id)!,
                                                               userID: Int(data.reference.userID)!,
                                                               userName: data.reference.userName,
                                                               jpegDataFileName: "\(data.reference.jpegDataFileName)",
                                                               
                                                               jpegData: nil,
                                                               
                                                               dataSizeKB: Double(data.reference.dataSizeKB)!,
                                                               latitude: Double(data.reference.latitude)!,
                                                               longitude: Double(data.reference.longitude)!,
                                                               magneticHeading: Double(data.reference.magneticHeading)!,
                                                               physicalWidth: Double(data.reference.physicalWidth)!,
                                                               registrationDate: "\(data.reference.registrationDate)",
                                                               
                                                               photoCount: Int(data.reference.photoCount)!,
                                                               yourPhotoCount: Int(data.reference.yourPhotoCount)!,
                                                               
                                                               detailButton: false)
                            
                            var networklSet: [LinkContainer_Reference] = []
                            
                            for i in data.network {
                                let position = OriginalPosition(x: Float(i.positionX)!, y: Float(i.positionY)!, z: Float(i.positionZ)!)
                                let euler = OriginalEuler(x: Float(i.eulerX)!, y: Float(i.eulerY)!, z: Float(i.eulerZ)!)
                                
                                let link = LinkContainer_Reference(id: Int(i.id)!,
                                                                   uuid: "\(i.uuid)",
                                                                   fromReferenceID: Int(i.fromReferenceID)!,
                                                                   toReferenceID: Int(i.toReferenceID)!,
                                                                   positionAndEuler: OriginalPositionAndEuler(position: position, euler: euler),
                                                                   registrationDate: "\(i.registrationDate)",
                                                                   lastUpdateDate: "\(i.lastUpdateDate)")
                                
                                networklSet.append(link)
                                
                                // Network Line
                                let from = Int(i.fromReferenceID)!
                                let to = Int(i.toReferenceID)!
                                // 格納されていないLineを格納する
                                if !map.referenceLinkArray.contains(where: { $0 == (from, to) || $0 == (to, from) }) {
                                    map.referenceLinkArray.append((from, to))
                                }
                            }
                            
                            let annotation = OriginalAnnotation(reference: reference,
                                                                connectedReference: data.connectedReference.map { Int($0)! },
                                                                network: networklSet,
                                                                annotationType: .network)
                            
                            guard let latitude = Double(data.reference.latitude) else { return }
                            guard let longitude = Double(data.reference.longitude) else { return }
                            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            annotation.coordinate = center
                            
                            await self.map.mapView.addAnnotation(annotation)
                            
                            // Network Line
                            // IDに紐付けた緯度経度情報を格納
                            let annotationLocation = (Int(data.reference.id)!, Double(data.reference.latitude)!, Double(data.reference.longitude)!)
                            map.annotationLocationArray.append(annotationLocation)
                        }
                        
                        // Network Line
                        DispatchQueue.main.async {
                            let mapRange = self.map.getMapRange()
                            // 地図範囲が狭い場合のみ処理を行う
                            if mapRange.2 <= self.linkRange {
                                // Lineを描画
                                self.map.drawLine()
                            }
                        }
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), MapGet.swift, getNetworkReferenceDataFromServerDB()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), MapGet.swift, getNetworkReferenceDataFromServerDB()")
            }
        }
    }
    
    func getReferenceJpegDataFromServerDirectory(dataTransfer: DataTransfer, jpegDataFileName: String, index: Int) async {
        do {
            // URLSession
            let url = originalURLSession.mainURL + "Reference/" + jpegDataFileName
            if let jpegData = try await originalURLSession.getAwait(stringURL: url) {
                if jpegData.first == 0xFF && jpegData[1] == 0xD8 { // JPEG画像データであるかの判定
                    DispatchQueue.main.async {
                        dataTransfer.annotationContainerArray[index].reference.jpegData = jpegData
                        
                        self.photoCount[index] = dataTransfer.annotationContainerArray[index].reference.photoCount
                        self.yourPhotoCount[index] = dataTransfer.annotationContainerArray[index].reference.yourPhotoCount
                    }
                }
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), MapGet.swift, getReferenceJpegDataFromServerDirectory()")
        }
    }
}
