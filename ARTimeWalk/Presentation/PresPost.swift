//
//  PresPost.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/17.
//

import SwiftUI

extension PresAR {
    private struct Decode_JpegDataURL: Codable {
        let jpegDataFileName: String
    }
    
    func reg_publishPhotoJpegData() async {
        for (index, reg_process_photo) in reg_process_photoArray.enumerated() {
            let jpegData: Data = reg_process_photo.reg_photo.jpegData
            
            do {
                // URLSession
                let url = originalURLSession.mainURL + "put/putPhotoJpegData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jpegData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_JpegDataURL.self, from: data)
                        reg_process_photoArray[index].jpegDataFileName = decodeData.jpegDataFileName
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), PresPost.swift, reg_publishPhotoJpegData()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), PresPost.swift, reg_publishPhotoJpegData()")
            }
        }
    }
    
    struct Encode_Photo: Codable {
        let uuid: String
        let userID: Int
        let referenceID: Int
        let jpegDataFileName: String
        let dataSizeKB: Double
        let imageAlbum: Bool
        
        let photoPositionX: Float
        let photoPositionY: Float
        let photoPositionZ: Float
        
        let photoEulerX: Float
        let photoEulerY: Float
        let photoEulerZ: Float
        
        let avatarPositionX: Float
        let avatarPositionY: Float
        let avatarPositionZ: Float
        
        let avatarEulerX: Float
        let avatarEulerY: Float
        let avatarEulerZ: Float
        
        let registrationDate: String
    }
    
    private struct Decode_PhotoID: Codable {
        let id: String
    }
    
    func reg_publishPhotoData(referenceID: Int) async -> [Encode_Photo] {
        var publish_photoArray: [Encode_Photo] = []
        
        let calculation = SpatialCalculation()
        
        for (index, reg_process_photo) in reg_process_photoArray.enumerated() {
            let reg_photo = reg_process_photo.reg_photo
            
            let photoAnchor = reg_photo.anchor
            let photoPosition = await OriginalPosition(x: photoAnchor.position.x, y: photoAnchor.position.y, z: photoAnchor.position.z)
            let photoPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: reg_photo.euler)
            
            let avatar = reg_photo.avatar
            let avatarAnchor = avatar.anchor
            let avatarPosition = await OriginalPosition(x: avatarAnchor.position.x, y: avatarAnchor.position.y, z: avatarAnchor.position.z)
            let avatarPositionAndEuler = OriginalPositionAndEuler(position: avatarPosition, euler: avatar.euler)
            
            let referencePoaition = await OriginalPosition(x: ar_reference!.anchor.position.x, y: ar_reference!.anchor.position.y, z: ar_reference!.anchor.position.z)
            let referencePositionAndEuler = OriginalPositionAndEuler(position: referencePoaition, euler: ar_reference!.euler)
            
            let calculatedPhoto = calculation.calculateRelativePositionAndOrientation(reference: referencePositionAndEuler, target: photoPositionAndEuler)
            let calculatedAvatar = calculation.calculateRelativePositionAndOrientation(reference: referencePositionAndEuler, target: avatarPositionAndEuler)
            
            let data = Encode_Photo(uuid: reg_photo.uuid,
                                    userID: ARTimeWalkApp.isUserID,
                                    referenceID: referenceID,
                                    jpegDataFileName: reg_process_photoArray[index].jpegDataFileName!,
                                    dataSizeKB: reg_photo.dataSizeKB,
                                    imageAlbum: reg_photo.imageAlbum,
                                    photoPositionX: calculatedPhoto.position.x,
                                    photoPositionY: calculatedPhoto.position.y,
                                    photoPositionZ: calculatedPhoto.position.z,
                                    photoEulerX: calculatedPhoto.euler.x,
                                    photoEulerY: calculatedPhoto.euler.y,
                                    photoEulerZ: calculatedPhoto.euler.z,
                                    avatarPositionX: calculatedAvatar.position.x,
                                    avatarPositionY: calculatedAvatar.position.y,
                                    avatarPositionZ: calculatedAvatar.position.z,
                                    avatarEulerX: calculatedAvatar.euler.x,
                                    avatarEulerY: calculatedAvatar.euler.y,
                                    avatarEulerZ: calculatedAvatar.euler.z,
                                    registrationDate: reg_photo.registrationDate)
            
            publish_photoArray.append(data)
        }
        
        // Encode
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let jsonData = try? encoder.encode(publish_photoArray) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "insert/addPhotoData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode([Decode_PhotoID].self, from: data)
                        
                        for (index, data) in decodeData.enumerated() {
                            reg_process_photoArray[index].id = Int(data.id)
                        }
                        
                        for index in tmp_reg_photoIndex {
                            reg_photoArray[index].saved = true
                        }
                        
                        return publish_photoArray
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), PresPost.swift, reg_publishPhotoData()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), PresPost.swift, reg_publishPhotoData()")
            }
        }
        return []
    }
    
    struct Encode_Link_Reference: Codable {
        let uuid: String
        let fromReferenceID: Int
        let toReferenceID: Int
        
        let positionX: Float
        let positionY: Float
        let positionZ: Float
        
        let eulerX: Float
        let eulerY: Float
        let eulerZ: Float
        
        let registrationDate: String
    }
    
    func publishReferenceLinkData(id0: Int, id1: Int, PE: OriginalPositionAndEuler) async {
        let uuid = UUID().uuidString
        
        // Date生成
        // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
        let dt = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let registrationDate = dateFormatter.string(from: dt)
        
        let data = Encode_Link_Reference(uuid: uuid,
                                         fromReferenceID: id0,
                                         toReferenceID: id1,
                                         positionX: PE.position.x,
                                         positionY: PE.position.y,
                                         positionZ: PE.position.z,
                                         eulerX: PE.euler.x,
                                         eulerY: PE.euler.y,
                                         eulerZ: PE.euler.z,
                                         registrationDate: registrationDate)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(data) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "insert/insertLinkData.php"
                try await originalURLSession.postAwait(stringURL: url, data: jsonData)
            } catch {
                print("Error occurred: \(error.localizedDescription), PresPost.swift, publishReferenceLinkData()")
            }
        }
    }
}
