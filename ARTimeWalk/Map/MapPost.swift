//
//  MapPost.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/16.
//

import Foundation

extension MapDataModel {
    private struct Encode_AccessData: Codable {
        let id: Int
        let lastAccessDate: String
    }
    
    func access() async {
        // Date生成
        // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
        let dt = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let lastAccessDate = dateFormatter.string(from: dt)
        
        // struct
        let record = Encode_AccessData(id: ARTimeWalkApp.isUserID, lastAccessDate: lastAccessDate)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "update/updateAccessDate.php"
                try await originalURLSession.postAwait(stringURL: url, data: jsonData)
            } catch {
                print("Error occurred: \(error.localizedDescription), MapPost.swift, access()")
            }
        }
    }
}
