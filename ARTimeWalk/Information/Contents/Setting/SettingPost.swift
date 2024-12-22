//
//  SettingPost.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/16.
//

import Foundation

extension SettingDataModel {
    private struct Decode_UserID: Codable {
        let id: String
        let userName: String
    }
    
    func postUserUUID() async -> (String, String)? {
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(inputUserUUID) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "select/selectUserID.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_UserID.self, from: data)
                        return (decodeData.id, decodeData.userName)
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), SettingPost.swift, postUserUUID()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), SettingPost.swift, postUserUUID()")
            }
        }
        return nil
    }
    
    private struct Encode_UserName: Codable {
        let id: Int
        let userName: String
    }
    
    private struct Decode_UserName_ChangeUserName: Codable {
        let userName: String
    }
    
    func postUserName() async -> String? {
        // struct
        let record = Encode_UserName(id: ARTimeWalkApp.isUserID, userName: inputUserName)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "update/updateUserName.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_UserName_ChangeUserName.self, from: data)
                        return decodeData.userName
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), SettingPost.swift, postUserName()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), SettingPost.swift, postUserName()")
            }
        }
        return nil
    }
}
