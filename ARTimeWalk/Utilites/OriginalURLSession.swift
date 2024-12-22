//
//  OriginalURLSession.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/05.
//

import SwiftUI

class OriginalURLSession {
    var mainURL = "https://si.akita-u.info/artimewalk/ARTimeWalk02/"
    
    func getAwait(stringURL: String) async throws -> Data? {
        // URLに変換
        guard let url = URL(string: stringURL) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }
        
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        // データ取得
        do {
            let (data, _) = try await session.data(for: request)
            session.finishTasksAndInvalidate()
            return data
        } catch {
            print("Error occurred: \(error.localizedDescription), OriginalURLSession.swift, getAwait()")
            throw error
        }
    }
    
    func postAwait(stringURL: String, data: Data) async throws {
        // URLに変換
        guard let url = URL(string: stringURL) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        // データ送信
        do {
            let (_, _) = try await URLSession.shared.data(for: request, delegate: nil)
        } catch {
            print("Error occurred: \(error.localizedDescription), OriginalURLSession.swift, postAwait()")
            throw error
        }
    }
    
    func postAwait_Return(stringURL: String, data: Data) async throws -> Data? {
        // URLに変換
        guard let url = URL(string: stringURL) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        // データ送信
        do {
            let (returnData, _) = try await URLSession.shared.data(for: request, delegate: nil)
            // サーバーからの返信を返す
            return returnData
        } catch {
            print("Error occurred: \(error.localizedDescription), OriginalURLSession.swift, postAwait_Return()")
            throw error
        }
    }
}
