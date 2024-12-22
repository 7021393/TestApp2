//
//  SettingDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/16.
//

import SwiftUI

final class SettingDataModel: ObservableObject {
    let originalURLSession = OriginalURLSession()
    
    @Published var selection: Int = 0
    
    @Published var displayUserUUID: String = ARTimeWalkApp.isUserUUID
    @Published var displayUserName: String = ARTimeWalkApp.isUserName
    
    @Published var inputUserUUID: String = ""
    @Published var inputUserName: String = ""
    
    @Published var isInvalid_changeUserUUID = false
    @Published var isInvalid_changeUserName = false
    @Published var isPresentedBanner_copy: Bool = false
    @Published var isPresentedBanner_changeUserUUID: Bool = false
    @Published var isPresentedBanner_changeUserName: Bool = false
    
    @Published var duringPostData: Bool = false
    
    @Published var isAlert_serverError: Bool = false
    
    func changeUserUUID() {
        // 入力を検査
        if validateInput_ChangeUUID(inputUserUUID) == false {
            inputUserUUID = ""
            
            isInvalid_changeUserUUID = true
            isPresentedBanner_changeUserUUID = true
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                self.isPresentedBanner_changeUserUUID = false
                self.isInvalid_changeUserUUID = false
            }
        } else {
            duringPostData = true
            
            Task {
                if let dataFromServerDB = await postUserUUID() {
                    duringPostData = false
                    
                    ARTimeWalkApp.isUserID = Int(dataFromServerDB.0)!
                    ARTimeWalkApp.isUserName = dataFromServerDB.1
                    ARTimeWalkApp.isUserUUID = inputUserUUID
                    
                    displayUserName = dataFromServerDB.1
                    displayUserUUID = inputUserUUID
                    inputUserUUID = ""
                    
                    DispatchQueue.main.async {
                        self.isPresentedBanner_changeUserUUID = true
                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                            self.isPresentedBanner_changeUserUUID = false
                        }
                    }
                } else {
                    duringPostData = false
                    inputUserUUID = ""
                    
                    isAlert_serverError.toggle()
                }
            }
        }
    }
    
    func changeUserName() {
        // 入力を検査
        if validateInput_ChangeUserName(inputUserName) == false {
            inputUserName = ""
            
            isInvalid_changeUserName = true
            isPresentedBanner_changeUserName = true
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                self.isPresentedBanner_changeUserName = false
                self.isInvalid_changeUserName = false
            }
        } else {
            duringPostData = true
            
            Task {
                if let userNameFromServerDB = await postUserName() {
                    duringPostData = false
                    
                    ARTimeWalkApp.isUserName = userNameFromServerDB
                    displayUserName = userNameFromServerDB
                    inputUserName = ""
                    
                    DispatchQueue.main.async {
                        self.isPresentedBanner_changeUserName = true
                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                            self.isPresentedBanner_changeUserName = false
                        }
                    }
                } else {
                    duringPostData = false
                    inputUserName = ""
                    
                    isAlert_serverError.toggle()
                }
            }
        }
    }
    
    // 大文字と数字のみ可、'AAAAAA-BBBB-CCC-DDDDDD-EEEEEEEEE'の形式（UUIDフォーマット）
    func validateInput_ChangeUUID(_ input: String) -> Bool {
        let pattern = "^[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: input)
    }
    
    // 空白や何も入力されていない場合は無効
    func validateInput_ChangeUserName(_ input: String) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedInput.isEmpty && trimmedInput.count <= 36
    }
}
