//
//  NotificationGet.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/16.
//

import SwiftUI

extension NotificationDataModel {
    private struct Decode_Notification: Codable {
        let message: String
    }
    
    func getNotification() async {
        do {
            // URLSession
            let url = originalURLSession.mainURL + "informationMessage.json"
            if let data = try await originalURLSession.getAwait(stringURL: url) {
                do {
                    // Decode
                    let decoder = JSONDecoder()
                    let primaryData = try decoder.decode([Decode_Notification].self, from: data)
                    
                    DispatchQueue.main.async {
                        for data in primaryData {
                            self.infoMessage = data.message
                        }
                    }
                } catch {
                    print("Error occurred: \(error.localizedDescription), NotificationGet.swift, getNotification()")
                }
            }
        } catch {
            print("Error occurred: \(error.localizedDescription), NotificationGet.swift, getNotification()")
        }
    }
}

