//
//  ContactView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/07/06.
//

import SwiftUI

struct ContactView: View {
    var body: some View {
        List {
            // Goolge Form
            /**
             "ar-time-walk@si.akita-u.info"でGoogleアカウントの作成ができなかったので、
             "ryoo@lab.akita-u.info"（有川研での藤原のメールアドレス）でGoogle Formを作成しています。
             ※ 以前はgmail以外のアドレスでGoogleアカウントを作成できたのですが、現在はできないようです。
             */
            Section(header: Text("FORM"), footer: text_googleForm()) {
                Link(destination: URL(string: "https://forms.gle/HcvRQC6HUQnk7Cpp9")!) {
                    Label("Bug Report", systemImage: "ant")
                        .foregroundStyle(Color.digitalBlue_color)
                }
                Link(destination: URL(string: "https://forms.gle/1CBi7EakkamVsbWG6")!) {
                    Label("Feature Requests", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color.digitalBlue_color)
                }
            }
            // Mail
            Section(header: Text("MAIL"), footer: text_mail()) {
                Button(action: {
                    sendEmail(to: "ar-time-walk@si.akita-u.info")
                }) {
                    Label("Send Email", systemImage: "envelope")
                        .foregroundStyle(Color.digitalBlue_color)
                }
            }
        }
    }
    
    private func text_googleForm() -> some View {
        VStack {
            HStack {
                Text("Please select your inquiry. The Google Form will open in your browser.")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
    
    private func text_mail() -> some View {
        VStack {
            HStack {
                Text("For other questions or to contact us, please send us an email.")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
    
    private func sendEmail(to email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
    }
}
