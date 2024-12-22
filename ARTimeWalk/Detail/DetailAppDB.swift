//
//  DetailAppDB.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/10.
//

import RealmSwift

extension DetailDataModel {
    func getPhotoDataFromApp(dataTransfer: DataTransfer, annotationIndex: Int) {
        do {
            let realm = try Realm()
            let appDB_photos = realm.objects(AppDB_Photo.self).filter("referenceID == \(dataTransfer.annotationContainerArray[annotationIndex].reference.id)")
            
            for appDB_photo in appDB_photos {
                guard let jpegData = getPhotoJpegDataFromAppDocuments(jpegDataFileName: appDB_photo.jpegDataFileName) else { return }
                
                let photoPosition = OriginalPosition(x: appDB_photo.photoPositionX, y: appDB_photo.photoPositionY, z: appDB_photo.photoPositionZ)
                let photoEuler = OriginalEuler(x: appDB_photo.photoEulerX, y: appDB_photo.photoEulerY, z: appDB_photo.photoEulerZ)
                
                let avatarPosition = OriginalPosition(x: appDB_photo.avatarPositionX, y: appDB_photo.avatarPositionY, z: appDB_photo.avatarPositionZ)
                let avatarEuler = OriginalEuler(x: appDB_photo.avatarEulerX, y: appDB_photo.avatarEulerY, z: appDB_photo.avatarEulerZ)
                
                let linkOriginalPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: photoEuler)
                
                
                // PhotoDistanceExperiments
                let photo = LinkContainer_Photo(id: appDB_photo.id,
                                                uuid: appDB_photo.uuid,
                                                serverID: appDB_photo.serverID,
                                                userID: appDB_photo.userID,
                                                userName: appDB_photo.userName,
                                                referenceID: appDB_photo.referenceID,
                                                jpegDataFileName: appDB_photo.jpegDataFileName,
                                                jpegData: jpegData,
                                                dataSizeKB: appDB_photo.dataSizeKB,
                                                imageAlbum: appDB_photo.imageAlbum,
                                                registrationDate: appDB_photo.registrationDate,
                                                photo: OriginalPositionAndEuler(position: photoPosition, euler: photoEuler),
                                                avatar: OriginalPositionAndEuler(position: avatarPosition, euler: avatarEuler),
                                                detailButton: false,
                                                photoDistance: appDB_photo.photoDistance,
                                                originalPositionAndEuler: linkOriginalPositionAndEuler)
                
                DispatchQueue.main.async {
                    dataTransfer.linkContainerArray_photo.append(photo)
                    
                    self.photoCount += 1
                    if appDB_photo.userID == ARTimeWalkApp.isUserID || appDB_photo.userID == 0 {
                        self.yourPhotoCount += 1
                    }
                }
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, getPhotoDataFromApp()")
        }
    }
    
    private func getPhotoJpegDataFromAppDocuments(jpegDataFileName: String) -> Data? {
        // ドキュメントディレクトリへのパスを取得
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // 保存したファイルのURLを生成
            let fileURL = documentsDirectory.appendingPathComponent(jpegDataFileName)
            do {
                let jpegData = try Data(contentsOf: fileURL)
                return jpegData
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, getPhotoJpegDataFromAppDocuments()")
            }
        }
        return nil
    }
    
    func deletePhotoInApp(id: Int) {
        do {
            let realm = try Realm()
            let appDB_photos = realm.objects(AppDB_Photo.self).filter("id == \(id)")
            
            for photo in appDB_photos {
                deleteJpegDataInAppDocuments(fileName: photo.jpegDataFileName)
            }
            
            try realm.write {
                realm.delete(appDB_photos)
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, deletePhotoInApp()")
        }
    }
    
    func deleteReferenceInApp(id: Int) {
        do {
            let realm = try Realm()
            let appDB_references = realm.objects(AppDB_Reference.self).filter("id == \(id)")
            
            for reference in appDB_references {
                deleteJpegDataInAppDocuments(fileName: reference.jpegDataFileName)
            }
            
            try realm.write {
                realm.delete(appDB_references)
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, deleteReferenceInApp()")
        }
    }
    
    private func deleteJpegDataInAppDocuments(fileName: String) {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // 削除するファイルのURLを生成
            let fileURL = documentsDirectory.appendingPathComponent(fileName)

            do {
                // ファイルが存在するか確認し、存在する場合は削除
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                } else {
                    print("Error occurred: File does not exist, DetailAppDB.swift, deleteJpegDataInAppDocuments()")
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, deleteJpegDataInAppDocuments()")
            }
        }
    }
    
    func changePhotoDateInApp(dataTransfer: DataTransfer) {
        do {
            let realm = try Realm()
            let appDB_photo = realm.objects(AppDB_Photo.self).filter("id == \(dataTransfer.linkContainerArray_photo[photoDetailIndex].id)").first
            
            try realm.write {
                appDB_photo?.registrationDate = inputPhotoDate
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), DetailAppDB.swift, changePhotoDateInApp()")
        }
    }
}
