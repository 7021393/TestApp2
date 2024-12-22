//
//  TermsOfUseView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/07/06.
//

import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        let termsText: String = """
          利用規約
          
          1. サービスの提供に関する条件
             - 本アプリは写真の撮影や位置情報の取得を行いますが、個人情報の収集は行いません。
             - 利用者は法律および規制を遵守しなければなりません。
          
          2. データの取り扱い
             - ログイン情報をサーバーに保存しますが、それ以外のデータは送信されません。
             - 不適切なデータがある場合は開発者に連絡してください。
          """
        
        List {
            Section(header: Text("TERMS OF USE")) {
                Text(termsText)
            }
        }
    }
}

struct TermsOfUseView_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfUseView()
    }
}
