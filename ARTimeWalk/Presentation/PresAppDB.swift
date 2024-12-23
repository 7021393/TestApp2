//
//  PresAppDB.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/17.
//

import RealityKit
import RealmSwift

extension PresAR {
    func reg_saveToAppDB(referenceID: Int) -> [AppDB_Photo] {
        var save_photoArray: [AppDB_Photo] = []
        
        resetVariable()
        setVariable()
        
        do {
            let realm = try Realm()
            
            // photo
            try reg_savePhotoJpegData()
            save_photoArray = reg_createPhotoData(realm: realm, referenceID: referenceID)
            
            try realm.write {
                realm.add(save_photoArray)
            }
            
            for index in tmp_reg_photoIndex {
                reg_photoArray[index].saved = true
            }
            
            return save_photoArray
        } catch {
            print("Error occurred: \(error.localizedDescription), PresAppDB.swift, reg_saveToAppDB()")
        }
        return []
    }
    
    private func reg_savePhotoJpegData() throws {
        for (index, reg_process_photo) in reg_process_photoArray.enumerated() {
            let jpegData: Data = reg_process_photo.reg_photo.jpegData
            
            let uuid = UUID().uuidString
            let fileName = "photo_" + uuid + ".jpg"
            // ドキュメントディレクトリへのパスを取得
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                // 保存するファイルのURLを生成
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                do {
                    // ファイルにデータを書き込む
                    try jpegData.write(to: fileURL)
                    // 保存が成功した場合の処理
                    reg_process_photoArray[index].jpegDataFileName = fileName
                } catch {
                    // 保存が失敗した場合の処理
                    throw error
                }
            } else {
                throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate documents directory"])
            }
        }
    }
    
    private func reg_createPhotoData(realm: Realm, referenceID: Int) -> [AppDB_Photo] {
        var appDB_photoArray: [AppDB_Photo] = []
        
        let lastID = (realm.objects(AppDB_Photo.self).max(ofProperty: "id") as Int? ?? 0)
        var id = lastID + 1
        
        for (index, reg_process_photo) in reg_process_photoArray.enumerated() {
            
            let appDB_photo = AppDB_Photo()
            
            let photo = reg_process_photo.reg_photo
            
            let referencePositionAndEuler = returnReferencePositionAndEuler()
            
            let calculation = SpatialCalculation()
            
            let photoAnchor = photo.anchor
            let photoPosition = OriginalPosition(x: photoAnchor.position.x, y: photoAnchor.position.y, z: photoAnchor.position.z)
            let photoPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: photo.euler)
            
            let avatar = photo.avatar
            let avatarAnchor = avatar.anchor
            let avatarPosition = OriginalPosition(x: avatarAnchor.position.x, y: avatarAnchor.position.y, z: avatarAnchor.position.z)
            let avatarPositionAndEuler = OriginalPositionAndEuler(position: avatarPosition, euler: avatar.euler)
            
            let calculatedPhoto = calculation.calculateRelativePositionAndOrientation(reference: referencePositionAndEuler!, target: photoPositionAndEuler)
            let calculatedAvatar = calculation.calculateRelativePositionAndOrientation(reference: referencePositionAndEuler!, target: avatarPositionAndEuler)
            
            appDB_photo.id = id
            appDB_photo.uuid = photo.uuid
            appDB_photo.serverID = 0
            appDB_photo.userID = 0
            appDB_photo.userName = ARTimeWalkApp.isUserName
            appDB_photo.referenceID = referenceID
            appDB_photo.jpegDataFileName = reg_process_photoArray[index].jpegDataFileName!
            
            appDB_photo.dataSizeKB = photo.dataSizeKB
            appDB_photo.imageAlbum = photo.imageAlbum
            appDB_photo.registrationDate = photo.registrationDate
            
            appDB_photo.photoPositionX = calculatedPhoto.position.x
            appDB_photo.photoPositionY = calculatedPhoto.position.y
            appDB_photo.photoPositionZ = calculatedPhoto.position.z
            
            appDB_photo.photoEulerX = calculatedPhoto.euler.x
            appDB_photo.photoEulerY = calculatedPhoto.euler.y
            appDB_photo.photoEulerZ = calculatedPhoto.euler.z
            
            appDB_photo.avatarPositionX = calculatedAvatar.position.x
            appDB_photo.avatarPositionY = calculatedAvatar.position.y
            appDB_photo.avatarPositionZ = calculatedAvatar.position.z
            
            appDB_photo.avatarEulerX = calculatedAvatar.euler.x
            appDB_photo.avatarEulerY = calculatedAvatar.euler.y
            appDB_photo.avatarEulerZ = calculatedAvatar.euler.z
            
            reg_process_photoArray[index].id = id
            tmp_sumImageDataSizeInAppDocumentsKB += photo.dataSizeKB
            
            appDB_photoArray.append(appDB_photo)
            
            id += 1
        }
        return appDB_photoArray
    }
}

