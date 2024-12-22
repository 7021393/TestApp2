//
//  DetailPost.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/12.
//

import SwiftUI

extension DetailDataModel {
    private struct Decode_JpegDataURL: Codable {
        let jpegDataFileName: String
    }
    
    func publishReferenceJpegData(annotation: OriginalAnnotation) async {
        let jpegImage = annotation.reference.jpegData
        
        do {
            // URLSession
            let url = originalURLSession.mainURL + "put/putReferenceJpegData.php"
            if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jpegImage!) {
                do {
                    // Decode
                    let decoder = JSONDecoder()
                    let decodeData = try decoder.decode(Decode_JpegDataURL.self, from: data)
                    publish_referenceJpegDataFileName = decodeData.jpegDataFileName
                    
                } catch {
                    print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishReferenceJpegData()")
                }
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishReferenceJpegData()")
        }
    }
    
    func publishPhotoJpegData(dataTransfer: DataTransfer) async {
        publish_photoJpegDataFileNameArray.removeAll()
        
        for photo in dataTransfer.linkContainerArray_photo {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "put/putPhotoJpegData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: photo.jpegData!) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_JpegDataURL.self, from: data)
                        publish_photoJpegDataFileNameArray.append(decodeData.jpegDataFileName)
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishPhotoJpegData()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishPhotoJpegData()")
            }
        }
    }
    
    private struct Encode_Reference: Codable {
        let uuid: String
        let userID: Int
        let jpegDataFileName: String
        
        let dataSizeKB: Double
        let latitude: Double
        let longitude: Double
        let magneticHeading: Double
        let physicalWidth: Double
        let registrationDate: String
    }
    
    private struct Decode_ReferenceID: Codable {
        let id: String
    }
    
    func publishReferenceData(annotation: OriginalAnnotation) async {
        // struct
        let record = Encode_Reference(uuid: annotation.reference.uuid,
                                      userID: ARTimeWalkApp.isUserID,
                                      jpegDataFileName: publish_referenceJpegDataFileName!,
                                      dataSizeKB: annotation.reference.dataSizeKB,
                                      latitude: annotation.coordinate.latitude,
                                      longitude: annotation.coordinate.longitude,
                                      magneticHeading: annotation.reference.magneticHeading,
                                      physicalWidth: annotation.reference.physicalWidth,
                                      registrationDate: annotation.reference.registrationDate)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "insert/insertReferenceData.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_ReferenceID.self, from: data)
                        publish_referenceID = Int(decodeData.id)
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishReferenceData()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishReferenceData()")
            }
        }
    }
    
    private struct Encode_Photo: Codable {
        let uuid: String
        let userID: Int
        let referenceID: Int
        let jpegDataFileName: String
        
        let dataSizeKB: Double
        let imageAlbum: Bool
        let registrationDate: String
        
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
    }
    
    func publishPhotoData(dataTransfer: DataTransfer) async {
        if dataTransfer.linkContainerArray_photo.isEmpty == false {
            var record:[Encode_Photo] = []
            for (index, LinkContainer_Photo) in dataTransfer.linkContainerArray_photo.enumerated() {
                let data = Encode_Photo(uuid: LinkContainer_Photo.uuid,
                                        userID: ARTimeWalkApp.isUserID,
                                        referenceID: publish_referenceID!,
                                        jpegDataFileName: publish_photoJpegDataFileNameArray[index],
                                        dataSizeKB: LinkContainer_Photo.dataSizeKB,
                                        imageAlbum: LinkContainer_Photo.imageAlbum,
                                        registrationDate: LinkContainer_Photo.registrationDate,
                                        photoPositionX: LinkContainer_Photo.photo.position.x,
                                        photoPositionY: LinkContainer_Photo.photo.position.y,
                                        photoPositionZ: LinkContainer_Photo.photo.position.z,
                                        photoEulerX: LinkContainer_Photo.photo.euler.x,
                                        photoEulerY: LinkContainer_Photo.photo.euler.y,
                                        photoEulerZ: LinkContainer_Photo.photo.euler.z,
                                        avatarPositionX: LinkContainer_Photo.avatar.position.x,
                                        avatarPositionY: LinkContainer_Photo.avatar.position.y,
                                        avatarPositionZ: LinkContainer_Photo.avatar.position.z,
                                        avatarEulerX: LinkContainer_Photo.avatar.euler.x,
                                        avatarEulerY: LinkContainer_Photo.avatar.euler.y,
                                        avatarEulerZ: LinkContainer_Photo.avatar.euler.z)
                
                record.append(data)
            }
            
            // Encode
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let jsonData = try? encoder.encode(record) {
                do {
                    // URLSession
                    let url = originalURLSession.mainURL + "insert/insertPhotoData.php"
                    try await originalURLSession.postAwait(stringURL: url, data: jsonData)
                } catch {
                    print("Error occurred: \(error.localizedDescription), DetailPost.swift, publishPhotoData()")
                }
            }
        }
    }
    
    func deletePhotoInServer(id: Int) async {
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(id) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "delete/deletePhoto.php"
                try await originalURLSession.postAwait(stringURL: url, data: jsonData)
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, deletePhotoInServer()")
            }
        }
    }
    
    func deleteReferenceInServer(id: Int) async {
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(id) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "delete/deleteReference.php"
                try await originalURLSession.postAwait(stringURL: url, data: jsonData)
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, deleteReferenceInServer()")
            }
        }
    }
    
    private struct Encode_ReferenceID: Codable {
        let id_array: [Int]
    }
    
    func deleteReferenceLinkInServer(id_array: [Int]) async {
        // struct
        let record = Encode_ReferenceID(id_array: id_array)
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "delete/deleteReferenceLink.php"
                try await originalURLSession.postAwait(stringURL: url, data: jsonData)
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, deleteReferenceLinkInServer()")
            }
        }
    }
    
    private struct Encode_PhotoDate: Codable {
        let id: Int
        let photoDate: String
    }
    
    private struct Decode_PhotoID_ChangePhotoDate: Codable {
        let id: Int
    }
    
    func changePhotoDateInServer(dataTransfer: DataTransfer) async -> Int? {
        // struct
        let record = Encode_PhotoDate(id: dataTransfer.linkContainerArray_photo[photoDetailIndex].id, photoDate: inputPhotoDate)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "update/updatePhotoDate.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_PhotoID_ChangePhotoDate.self, from: data)
                        return decodeData.id
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DetailPost.swift, changePhotoDateInServer()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DetailPost.swift, changePhotoDateInServer()")
            }
        }
        return nil
    }
}
