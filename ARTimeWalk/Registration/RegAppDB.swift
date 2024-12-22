//
//  RegAppDB.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/10.
//

import RealmSwift
import MapKit

extension RegAR {
    // MARK: Save to App DB
    /**
     認識したマーカーと設置した写真を保存
     
     一度保存されたデータは2回目以降の保存処理によって重複保存されることはありません。
     例外として、Referenceが更新された際はPhotoの保存状態がリセットされ、更新されたReferenceに紐付く形で再度保存されます。
     
     - reg_: マーカー、写真を生成したときに作成されるデータ、RegARでのデータ更新、削除、アニメーションで使用、savedパラメータで保存状況を管理
     - reg_process: 保存処理を行うデータ、2回目以降の保存処理に対応、reg_のsavedパラメータより保存されていないデータを判別、格納
     - save_: App DBへの最終保存処理用変数
 
     - Note: reg = registration
     
     - Warning: 画像データをディレクトリへ保存した後に参照データをDBへ保存しているため、DBへの保存が失敗した際に削除不可の画像データがストレージを圧迫する可能性がある。画像データ、参照データのどちらかの保存が失敗した際に状態を元に戻すトランザクション処理の実装などが必要
     */
    func saveToAppDB() {
        var save_reference: AppDB_Reference?
        var save_photoArray: [AppDB_Photo] = []
        
        resetVariable()
        setVariable()
        
        do {
            let realm = try Realm()
            
            // reference
            if reg_process_reference?.id == nil {
                try saveReferenceJpegData()
                save_reference = createReferenceData(realm: realm)
            }
            
            // photo
            try savePhotoJpegData()
            save_photoArray = createPhotoData(realm: realm)
            
            try realm.write {
                if let reference = save_reference {
                    realm.add(reference)
                }
                realm.add(save_photoArray)
            }
            
            reg_reference?.saved = true
            for index in tmp_reg_photoIndex {
                reg_photoArray[index].saved = true
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), RegAppDB.swift, saveToAppDB()")
        }
    }
    
    private func resetVariable() {
        reg_process_photoArray.removeAll()
        tmp_reg_photoIndex.removeAll()
        tmp_sumImageDataSizeInAppDocumentsKB = 0.0
    }
    
    // 保存されていないデータを抽出
    private func setVariable() {
        if reg_reference?.saved == false {
            reg_process_reference = Reg_Process_Reference(reg_reference: reg_reference!)
        }
        for (index, reg_photo) in reg_photoArray.enumerated() {
            if reg_photo.saved == false {
                reg_process_photoArray.append(Reg_Process_Photo(reg_photo: reg_photo))
                tmp_reg_photoIndex.append(index)
            }
        }
    }
    
    private func saveReferenceJpegData() throws {
        let jpegData: Data = reg_process_reference!.reg_reference.jpegData
        
        let uuid = UUID().uuidString
        let fileName = "reference_" + uuid + ".jpg"
        // ドキュメントディレクトリへのパスを取得
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // 保存するファイルのURLを生成
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            do {
                // ファイルにデータを書き込む
                try jpegData.write(to: fileURL)
                // 保存が成功した場合の処理
                reg_process_reference?.jpegDataFileName = fileName
            } catch {
                // 保存が失敗した場合の処理
                throw error
            }
        } else {
            throw NSError(domain: "SaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate documents directory"])
        }
    }
    
    private func createReferenceData(realm: Realm) -> AppDB_Reference {
        let lastID = (realm.objects(AppDB_Reference.self).max(ofProperty: "id") as Int? ?? 0)
        let id = lastID + 1
        
        let appDB_reference = AppDB_Reference()
        
        let reference = reg_process_reference!.reg_reference
        
        appDB_reference.id = id
        appDB_reference.uuid = reference.uuid
        appDB_reference.serverID = 0
        appDB_reference.userID = 0
        appDB_reference.userName = ARTimeWalkApp.isUserName
        appDB_reference.jpegDataFileName = reg_process_reference!.jpegDataFileName!
        
        appDB_reference.dataSizeKB = reference.dataSizeKB
        appDB_reference.latitude = reference.latitude
        appDB_reference.longitude = reference.longitude
        appDB_reference.magneticHeading = reference.magneticHeading
        appDB_reference.physicalWidth = reference.physicalWidth
        appDB_reference.registrationDate = reference.registrationDate
        
        reg_process_reference?.id = id
        tmp_sumImageDataSizeInAppDocumentsKB += reference.dataSizeKB
        
        return appDB_reference
    }
    
    private func savePhotoJpegData() throws {
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
    
    private func createPhotoData(realm: Realm) -> [AppDB_Photo] {
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
            appDB_photo.referenceID = reg_process_reference!.id!
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
            
            // PhotoDistanceExperiments
            appDB_photo.photoDistance = photo.photoDistance
            
            reg_process_photoArray[index].id = id
            tmp_sumImageDataSizeInAppDocumentsKB += photo.dataSizeKB
            
            appDB_photoArray.append(appDB_photo)
            
            id += 1
        }
        return appDB_photoArray
    }
    
    private func returnReferencePositionAndEuler() -> OriginalPositionAndEuler? {
        guard let anchor = reg_process_reference?.reg_reference.anchor else { return nil }
        guard let euler = reg_process_reference?.reg_reference.euler else { return nil }
        
        let referencePosition = OriginalPosition(x: anchor.position.x, y: anchor.position.y, z: anchor.position.z)
        let referencePositionAndEuler = OriginalPositionAndEuler(position: referencePosition, euler: euler)
        
        return referencePositionAndEuler
    }
}
