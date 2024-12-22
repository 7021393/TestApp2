//
//  InfoView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/22.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var initialDataTransfer: InitialDataTransfer
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        NavigationLink {
                            // XcodeのSimulatorを起動するとエラーを吐きます。
                            // エラーの原因はEnvironmentObjectの記述ですが、対処法は不明です。
                            AboutAppView(initial: false)
                                .environmentObject(initialDataTransfer)
                        } label: {
                            Label("About App", systemImage: "questionmark.circle")
                                .foregroundStyle(Color.digitalBlue_color)
                        }
                        NavigationLink {
                            SettingView()
                        } label: {
                            Label("Setting", systemImage: "gearshape")
                                .foregroundStyle(Color.digitalBlue_color)
                        }
                    }
                    Section {
                        NavigationLink {
                            NotificationView()
                        } label: {
                            Label("Notification", systemImage: "bell")
                                .foregroundStyle(Color.digitalBlue_color)
                        }
                        NavigationLink {
                            ContactView()
                        } label: {
                            Label("Contact Us", systemImage: "paperplane")
                                .foregroundStyle(Color.digitalBlue_color)
                        }
                    }
                    
                    // DocumentView
                    DocumentView(initial: false).termsAndPrivacySection()
                    
                    // MARK: App
                    Section(header: Text("APP")) {
                        HStack {
                            if let image = UIImage(named: "icons_ARTimeWalk") {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(10)
                            } else {
                                // 画像が見つからなかった場合の代替処理
                                Text("App Icon Not Found")
                            }
                            Spacer()
                            Text("ARTimeWalk")
                        }
                        HStack {
                            Text("Version")
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text(ARTimeWalkApp.AppVersion)
                        }
                        HStack {
                            Text("License")
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text("2024 © Akita University. Japan.\n Graduate School of Engineering Science.\n Arikawa Laboratory.")
                                .font(.caption)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(nil)
                        }
                    }
                }
            }
        }
        .accentColor(Color.primary)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
