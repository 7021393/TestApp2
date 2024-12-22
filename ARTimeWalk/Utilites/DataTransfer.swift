//
//  DataTransfer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/12/02.
//

import SwiftUI
import CoreLocation

final class DataTransfer: ObservableObject {
    /*
     "Registration <-> Map <-> Detail <-> Presentation" 間のデータ受け渡し用変数
     
     - sumImageDataSizeInAppDocumentsMB : アプリ内に保存された画像ファイルのデータ容量（MB）、Local選択時のMapViewに表示される。
     - annotationContainerArray         : Network探索済みのReferenceデータを含んだAnnnotationを格納する配列。クラスターAnnotationに対応。
     - referenceContainerArray          : DetailViewで取得されるReferenceのデータを格納する配列、詳細ボタンの押下を判別するBool値も格納している。
     - linkContainerArray_photo         : DetailViewで取得されるPhotoのLinkデータを格納する配列、詳細ボタンの押下を判別するBool値も格納している。
     
     - photoCountBool                   : DetailView/PresViewで写真を削除/追加した際のPhotoCountデータをMapViewに伝えるためのBool値（test）
     */
    @Published var sumImageDataSizeInAppDocumentsMB: Double = 0.0
    @Published var annotationContainerArray: [OriginalAnnotation] = []
    @Published var referenceContainerArray: [ReferenceContainer] = []
    @Published var linkContainerArray_photo: [LinkContainer_Photo] = []
    
    // test
    @Published var photoCountBool: Bool = false
    
    // Xcode シミュレーター用データ
    static func simulatorData() -> DataTransfer {
        let image: UIImage = UIImage(named: "undraw_Polaroid_re_481f")!
        let jpegData: Data = image.jpegData(compressionQuality: 0.0)!
        
        let reference = ReferenceContainer(id: 0,
                                           uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                                           serverID: 0,
                                           userID: ARTimeWalkApp.isUserID,
                                           userName: ARTimeWalkApp.isUserName,
                                           jpegDataFileName: "fileName",
                                           
                                           jpegData: jpegData,
                                           
                                           dataSizeKB: 200,
                                           latitude: 37.33486612523069, // Apple Park
                                           longitude: -122.008954277723, // Apple Park
                                           magneticHeading: 0.0,
                                           physicalWidth: 0.3,
                                           registrationDate: "2020-04-14 12:36",
                                           
                                           photoCount: 3,
                                           yourPhotoCount: 2,
                                           
                                           detailButton: false)
        
        // Annotation生成
        let annotation = OriginalAnnotation(reference: reference,
                                            connectedReference: [reference.id],
                                            network: [],
                                            annotationType: .normal)
        
        let center = CLLocationCoordinate2D(latitude: 37.33486612523069, longitude: -122.008954277723) // Apple Park
        annotation.coordinate = center
        
        
        let linkOriginalPositionAndEuler = OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0), euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0))
        
        // Photo0生成
        let photo0 = LinkContainer_Photo(id: 0,
                                         uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                                         serverID: 0,
                                         userID: ARTimeWalkApp.isUserID,
                                         userName: ARTimeWalkApp.isUserName,
                                         referenceID: 0,
                                         jpegDataFileName: "fileName",
                                         
                                         jpegData: jpegData,
                                         
                                         dataSizeKB: 100,
                                         imageAlbum: true, // カメラロールから選択
                                         registrationDate: "2020-10-02 04:18",
                                         
                                         photo: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                         euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         avatar: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                          euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         detailButton: false,
                                         photoDistance: 1.0,
                                          // PhotoDistanceExperiments
                                         
                                         originalPositionAndEuler: linkOriginalPositionAndEuler)
                                         
        
        // Photo1生成
        let photo1 = LinkContainer_Photo(id: 1,
                                         uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                                         serverID: 0,
                                         userID: 1, // 他のユーザーが設置
                                         userName: ARTimeWalkApp.isUserName,
                                         referenceID: 0,
                                         jpegDataFileName: "fileName",
                                         
                                         jpegData: jpegData,
                                         
                                         dataSizeKB: 100,
                                         imageAlbum: false,
                                         registrationDate: "2021-3-25 01:54",
                                         
                                         photo: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                         euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         avatar: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                          euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         detailButton: false,
                                         photoDistance: 1.0, // PhotoDistanceExperiments
                                         originalPositionAndEuler: linkOriginalPositionAndEuler)
        
        // Photo2生成
        let photo2 = LinkContainer_Photo(id: 2,
                                         uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                                         serverID: 0,
                                         userID: ARTimeWalkApp.isUserID,
                                         userName: ARTimeWalkApp.isUserName,
                                         referenceID: 0,
                                         jpegDataFileName: "fileName",
                                         
                                         jpegData: jpegData,
                                         
                                         dataSizeKB: 100,
                                         imageAlbum: false,
                                         registrationDate: "2020-11-11 22:10",
                                         
                                         photo: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                         euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         avatar: OriginalPositionAndEuler(position: OriginalPosition(x: 0.0, y: 0.0, z: 0.0),
                                                                          euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0)),
                                         detailButton: false,
                                         photoDistance: 1.0, // PhotoDistanceExperiments
                                         originalPositionAndEuler: linkOriginalPositionAndEuler)
        
        let data: DataTransfer = DataTransfer()
        data.sumImageDataSizeInAppDocumentsMB = 500.0
        data.annotationContainerArray = [annotation]
        data.referenceContainerArray = [reference]
        data.linkContainerArray_photo = [photo0, photo1, photo2]
        
        return data
    }
}
