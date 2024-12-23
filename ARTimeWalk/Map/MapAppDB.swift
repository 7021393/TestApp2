//
//  MapAppDB.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/10.
//

import RealmSwift
import MapKit

extension MapDataModel {
    func getImageDataSizeInAppDocuments() {
        appDB_sumImageDataSizeInAppDocumentsKB = 0.0
        
        do {
            let realm = try Realm()
            appDB_sumImageDataSizeInAppDocumentsKB += realm.objects(AppDB_Reference.self).sum(ofProperty: "dataSizeKB")
            appDB_sumImageDataSizeInAppDocumentsKB += realm.objects(AppDB_Photo.self).sum(ofProperty: "dataSizeKB")
        } catch {
            print("Error occurred: \(error.localizedDescription), MapAppDB.swift, getImageDataSizeInAppDocuments()")
        }
    }
    
    func getNormalReferenceDataFromAppDB() {
        do {
            let realm = try Realm()
            let appDB_references = realm.objects(AppDB_Reference.self)
            
            for appDB_reference in appDB_references {
                // Referenceに関連付けられたPhotoの数を取得
                let photoCount = realm.objects(AppDB_Photo.self).filter("referenceID == \(appDB_reference.id)").count
                
                // 自分が登録したPhotoの数を取得
                let yourPhotoCount = realm.objects(AppDB_Photo.self).filter("referenceID == \(appDB_reference.id) AND (userID == \(ARTimeWalkApp.isUserID) OR userID == 0)").count
                
                let reference = ReferenceContainer(id: appDB_reference.id,
                                                   uuid: appDB_reference.uuid,
                                                   serverID: appDB_reference.serverID,
                                                   userID: appDB_reference.userID,
                                                   userName: appDB_reference.userName,
                                                   jpegDataFileName: appDB_reference.jpegDataFileName,
                                                   
                                                   jpegData: nil,
                                                   
                                                   dataSizeKB: appDB_reference.dataSizeKB,
                                                   latitude: appDB_reference.latitude,
                                                   longitude: appDB_reference.longitude,
                                                   magneticHeading: appDB_reference.magneticHeading,
                                                   physicalWidth: appDB_reference.physicalWidth,
                                                   registrationDate: appDB_reference.registrationDate,
                                                   
                                                   photoCount: photoCount,
                                                   yourPhotoCount: yourPhotoCount,
                                                   
                                                   detailButton: false)
                
                let annotation = OriginalAnnotation(reference: reference,
                                                    connectedReference: [appDB_reference.id],
                                                    network: [],
                                                    annotationType: .normal)
                
                let latitude = appDB_reference.latitude
                let longitude = appDB_reference.longitude
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.coordinate = center
                
                self.map.mapView.addAnnotation(annotation)
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), MapAppDB.swift, getNormalReferenceDataFromAppDB()")
        }
    }
    
    func getReferenceJpegDataFromAppDocuments(dataTransfer: DataTransfer, jpegDataFileName: String, index: Int) {
        // ドキュメントディレクトリへのパスを取得
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // 保存したファイルのURLを生成
            let fileURL = documentsDirectory.appendingPathComponent(jpegDataFileName)
            do {
                let jpegData = try Data(contentsOf: fileURL)
                dataTransfer.annotationContainerArray[index].reference.jpegData = jpegData
                
                photoCount[index] = dataTransfer.annotationContainerArray[index].reference.photoCount
                yourPhotoCount[index] = dataTransfer.annotationContainerArray[index].reference.yourPhotoCount
            } catch {
                print("Error occurred: \(error.localizedDescription), MapAppDB.swift, getReferenceJpegDataFromAppDocuments()")
            }
        }
    }
}
