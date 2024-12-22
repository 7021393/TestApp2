//
//  ARTimeWalkApp.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/08.
//

import SwiftUI

@main
struct ARTimeWalkApp: App {
    /*
     Information画面に表示されるアプリバージョン
     
     - プログラム変更時にバージョンを上げる。
     - .xcodeprojファイルのGeneralにある"Version"と"Build"のバージョンも同様に上げる（Apple Store Connectのバージョン管理に利用されます）。
     */
    
    // PhotoDistanceExperiments
    static let AppVersion: String = "PhotoPositioningExperiments" // [Server Program Beta 2.3]
    
    /*
     App Storeでの一般公開に向けた機能制限用Bool値
     
     - publishReferenceAndPhoto : ReferenceとPhotoの公開機能の制限（DetailのPublishボタン、Global選択時のPresentationのAddPhotoピッカー）
     - publishReferenceLink     : Reference間のLinkの送信機能の制限（PresentationのReference同時認識時の処理）
     */
    
    // PhotoDistanceExperiments
    static let publishReferenceAndPhoto: Bool = false // 実験用のアプリVerなので公開機能はfalseにしてください。
    static let publishReferenceLink: Bool = false // 実験用のアプリVerなので公開機能はfalseにしてください。
    
    /*
     アプリ内永続変数（UserDefaultsのSwiftUI版）
     ※ 変更後はアプリを再インストール
     
     - isUserID     : userUUIDがServerに登録された際にServer側で生成されるID、ServerDBの検索に用いる。
     - isUserUUID   : アプリ側で生成されるユーザー固有のID、表記のために使用される、変更可能。
     - isUserName   : 飾り
     */
    @AppStorage("is_userID") static var isUserID: Int = 0
    @AppStorage("is_userUUID") static var isUserUUID: String = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
    @AppStorage("is_userName") static var isUserName: String = "gest"
    
    var body: some Scene {
        WindowGroup {
            MapView(simulator: false)
        }
    }
}
