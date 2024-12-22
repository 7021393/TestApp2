//
//  DetailGet.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/12.
//

import SwiftUI

extension DetailDataModel {
    private struct Encode_PhotoID: Codable {
        let id_array: [Int]
    }
    
    private struct Decode_Link_Photo: Codable {
        let id: String
        let uuid: String
        let userID: String
        let userName: String
        let referenceID: String
        let jpegDataFileName: String
        
        let dataSizeKB: String
        let imageAlbum: String
        let registrationDate: String
        
        let photoPositionX: String
        let photoPositionY: String
        let photoPositionZ: String
        
        let photoEulerX: String
        let photoEulerY: String
        let photoEulerZ: String
        
        let avatarPositionX: String
        let avatarPositionY: String
        let avatarPositionZ: String
        
        let avatarEulerX: String
        let avatarEulerY: String
        let avatarEulerZ: String
    }
    
    func getPhotoDataFromServerDB(dataTransfer: DataTransfer, id_array: [Int]) async {
        // struct
        let record = Encode_PhotoID(id_array: id_array)
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "select/selectPhotoData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode([Decode_Link_Photo].self, from: data)
                        
                        for data in decodeData {
                            let photoPosition = OriginalPosition(x: Float(data.photoPositionX)!, y: Float(data.photoPositionY)!, z: Float(data.photoPositionZ)!)
                            let photoEuler = OriginalEuler(x: Float(data.photoEulerX)!, y: Float(data.photoEulerY)!, z: Float(data.photoEulerZ)!)
                            
                            let avatarPosition = OriginalPosition(x: Float(data.avatarPositionX)!, y: Float(data.avatarPositionY)!, z: Float(data.avatarPositionZ)!)
                            let avatarEuler = OriginalEuler(x: Float(data.avatarEulerX)!, y: Float(data.avatarEulerY)!, z: Float(data.avatarEulerZ)!)
                            
                            let linkOriginalPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: photoEuler)
                            
                            
                            // PhotoDistanceExperiments
                            let photo = LinkContainer_Photo(id: Int(data.id)!,
                                                            uuid: data.uuid,
                                                            serverID: Int(data.id)!,
                                                            userID: Int(data.userID)!,
                                                            userName: data.userName,
                                                            referenceID: Int(data.referenceID)!,
                                                            jpegDataFileName: data.jpegDataFileName,
                                                            jpegData: nil,
                                                            dataSizeKB: Double(data.dataSizeKB)!,
                                                            imageAlbum: (data.imageAlbum == "1"),
                                                            registrationDate: data.registrationDate,
                                                            photo: OriginalPositionAndEuler(position: photoPosition, euler: photoEuler),
                                                            avatar: OriginalPositionAndEuler(position: avatarPosition, euler: avatarEuler),
                                                            detailButton: false,
                                                            photoDistance: 1.0,
                                                            originalPositionAndEuler: linkOriginalPositionAndEuler)
                            
                            dataTransfer.linkContainerArray_photo.append(photo)
                        }
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DetailGet.swift, getPhotoDataFromServerDB()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailGet.swift, getPhotoDataFromServerDB()")
            }
        }
    }
    
    func getPhotoJpegDataFromServerDirectory(dataTransfer: DataTransfer) async {
        for (index, LinkContainer_Photo) in dataTransfer.linkContainerArray_photo.enumerated() {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "Photo/" + LinkContainer_Photo.jpegDataFileName
                if let jpegData = try await originalURLSession.getAwait(stringURL: url) {
                    if jpegData.first == 0xFF && jpegData[1] == 0xD8 { // JPEG画像データであるかの判定
                        DispatchQueue.main.async {
                            /**
                             linkContainerArray_photoに画像データを格納するだけではUIが更新されず、画像が表示されないようです。
                             画像データ格納後、PhotoCount等のUIを明示的に変更することで、画像の表示を促しています。
                             
                             ※ SwiftUIでは変数単体の値の変化は監視していても、配列内の値の変化は監視していない可能性があります。
                             */
                            dataTransfer.linkContainerArray_photo[index].jpegData = jpegData
                            
                            self.photoCount += 1
                            if dataTransfer.linkContainerArray_photo[index].userID == ARTimeWalkApp.isUserID || dataTransfer.linkContainerArray_photo[index].userID == 0 {
                                self.yourPhotoCount += 1
                            }
                        }
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailGet.swift, getPhotoJpegDataFromServerDirectory()")
            }
        }
    }
    
    private struct Decode_ReferenceExisted: Codable {
        let bool: String
    }
    
    func checkReferenceExistedFromServerDB(dataTransfer: DataTransfer, id_array: [Int]) async -> Bool {
        // struct
        let record = Encode_PhotoID(id_array: id_array)
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "select/checkReferenceExisted.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_ReferenceExisted.self, from: data)
                        // Reference Existed
                        if decodeData.bool == "1" {
                            return true
                        }
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DetailGet.swift, checkReferenceExistedFromServerDB()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailGet.swift, checkReferenceExistedFromServerDB()")
            }
        }
        return false
    }
}
