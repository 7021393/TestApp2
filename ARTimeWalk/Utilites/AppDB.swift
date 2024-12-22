//
//  AppDB.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/10.
//

import RealmSwift

/*
 アプリ内DB
 ※ 変更後はアプリを再インストール
 */

class AppDB_Reference: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var uuid: String
    @Persisted var serverID: Int
    @Persisted var userID: Int
    @Persisted var userName: String
    @Persisted var jpegDataFileName: String
    
    @Persisted var dataSizeKB: Double
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    @Persisted var magneticHeading: Double
    @Persisted var physicalWidth: Double
    @Persisted var registrationDate: String
}

class AppDB_Photo: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var uuid: String
    @Persisted var serverID: Int
    @Persisted var userID: Int
    @Persisted var userName: String
    @Persisted var referenceID: Int
    @Persisted var jpegDataFileName: String
    
    @Persisted var dataSizeKB: Double
    @Persisted var imageAlbum: Bool
    @Persisted var registrationDate: String
    
    @Persisted var photoPositionX: Float
    @Persisted var photoPositionY: Float
    @Persisted var photoPositionZ: Float
    
    @Persisted var photoEulerX: Float
    @Persisted var photoEulerY: Float
    @Persisted var photoEulerZ: Float
    
    @Persisted var avatarPositionX: Float
    @Persisted var avatarPositionY: Float
    @Persisted var avatarPositionZ: Float
    
    @Persisted var avatarEulerX: Float
    @Persisted var avatarEulerY: Float
    @Persisted var avatarEulerZ: Float
    
    // PhotoDistanceExperiments
    @Persisted var photoDistance: Float
}
