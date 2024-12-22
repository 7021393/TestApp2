//
//  OriginalVariable.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/08.
//

import Foundation
import RealityKit
import MapKit

class OriginalAnnotation: MKPointAnnotation {
    var reference: ReferenceContainer // Annotationが示すReferenceのデータ
    var connectedReference: [Int] // 接続されたReferenceのIDを格納する配列（Annotationが示すReferenceを含む）
    var network: [LinkContainer_Reference] // connectedReferenceのReference同士を繋ぐリンクを格納する配列
    var annotationType: AnnotationType
    
    init(reference: ReferenceContainer, connectedReference: [Int], network: [LinkContainer_Reference], annotationType: AnnotationType) {
        self.reference = reference
        self.connectedReference = connectedReference
        self.network = network
        self.annotationType = annotationType
    }
}

// 取得データ用変数（Reference）
struct ReferenceContainer {
    var id: Int
    var uuid: String
    var serverID: Int
    var userID: Int
    var userName: String
    var jpegDataFileName: String
    
    var jpegData: Data?
    
    var dataSizeKB: Double
    var latitude: Double
    var longitude: Double
    var magneticHeading: Double
    var physicalWidth: Double
    var registrationDate: String
    
    var photoCount: Int
    var yourPhotoCount: Int
    
    var detailButton: Bool
}

// 取得データ用変数（Photo）
struct LinkContainer_Photo {
    var id: Int
    var uuid: String
    var serverID: Int
    var userID: Int
    var userName: String
    var referenceID: Int
    var jpegDataFileName: String
    
    var jpegData: Data?
    
    var dataSizeKB: Double
    var imageAlbum: Bool
    var registrationDate: String
    
    var photo: OriginalPositionAndEuler
    var avatar: OriginalPositionAndEuler
    
    var detailButton: Bool
    
    // PhotoDistanceExperiments
    var photoDistance: Float
    
    var originalPositionAndEuler: OriginalPositionAndEuler
}

// 取得データ用変数（ReferenceLink）
struct LinkContainer_Reference {
    var id: Int
    var uuid: String
    var fromReferenceID: Int
    var toReferenceID: Int
    
    var positionAndEuler: OriginalPositionAndEuler
    
    var registrationDate: String
    var lastUpdateDate: String
}

// 登録データ用変数（Reference）
struct Reg_Reference {
    var uuid: String
    
    var jpegData: Data
    
    var dataSizeKB: Double
    var latitude: Double
    var longitude: Double
    var magneticHeading: Double
    var physicalWidth: Double
    var registrationDate: String
    
    var anchor: AnchorEntity
    var euler: OriginalEuler
    
    var saved: Bool
}

// 登録データ用変数（Photo）
struct Reg_Photo {
    var uuid: String
    
    var jpegData: Data
    
    var dataSizeKB: Double
    var imageAlbum: Bool
    var registrationDate: String
    
    var photoPlaneEntity: Entity
    var whitePlaneEntity: Entity
    var anchor: AnchorEntity
    var euler: OriginalEuler
    
    var avatar: Avatar
    
    var animationBool: AnimationBool
    
    var saved: Bool
    
    // PhotoDistanceExperiments
    var photoDistance: Float
}

// 登録処理データ用変数（Reference）
struct Reg_Process_Reference {
    var id: Int?
    var jpegDataFileName: String?
    var reg_reference: Reg_Reference
}

// 登録処理データ用変数（Photo）
struct Reg_Process_Photo {
    var id: Int?
    var jpegDataFileName: String?
    var reg_photo: Reg_Photo
}

// 写真表示用変数（Reference）
struct Pres_Reference {
    var id: Int
    
    var anchor: AnchorEntity
    var euler: OriginalEuler
}

// 写真表示用変数（Photo）
struct Pres_Photo {
    var id: Int
    var referenceID: Int
    
    var registrationDate: String
    
    var anchor: AnchorEntity
    var euler: OriginalEuler
    
    var avatar: Avatar
    
    var animationBool: AnimationBool
    
    // PhotoDistanceExperiments
    var photoDistance: Float
    
    var originalPositionAndEuler: OriginalPositionAndEuler?
}


// 写真表示用変数（計算）
struct referencePositionAndEulerContainer {
    var id: Int
    var positionAndEuler: OriginalPositionAndEuler
}

struct Avatar {
    var entity: Entity
    var anchor: AnchorEntity
    var euler: OriginalEuler
}

struct OriginalPositionAndEuler {
    var position: OriginalPosition
    var euler: OriginalEuler
}

struct OriginalPosition {
    var x: Float
    var y: Float
    var z: Float
}

struct OriginalEuler {
    var x: Float
    var y: Float
    var z: Float
}

struct EntityType: Component {
    enum Kind {
        case photo
        case avatar
        case reference
    }
    var kind: Kind
}

struct AnimationTarget {
    enum Kind {
        case photo
        case avatar
        case photoAndAvatar
    }
    var kind: Kind
}

struct AnimationBool {
    var photo: Bool
    var avatar: Bool
    var interval: Bool
}

enum AnnotationType {
    case minimum
    case normal
    case network
}

enum DataSource {
    case local // アプリ内DB
    case global // 外部サーバーDB
}
