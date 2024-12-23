//
//  InitialDataTransfer.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/07/07.
//

import SwiftUI

final class InitialDataTransfer: ObservableObject {
    /*
     初回ログイン時にAboutAppView（アプリの紹介）とDocumentView（利用規約、プライバシーポリシー）を表示するための変数
     */
    @Published var isAboutAppViewPresented = false
    @Published var isDocumentViewPresented = false
}
