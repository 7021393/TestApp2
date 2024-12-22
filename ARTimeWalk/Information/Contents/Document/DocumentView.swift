//
//  DocumentView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/08/12.
//

import SwiftUI

struct DocumentView: View {
    @EnvironmentObject var initialDataTransfer: InitialDataTransfer
    let originalURLSession = OriginalURLSession()
    
    let initial: Bool
    
    var body: some View {
        List {
            termsAndPrivacySection()
        }
    }
    
    func termsAndPrivacySection() -> some View {
        Section(header: headerText(), footer: checkedButton()) {
            Link(destination: URL(string: "https://artimewalk.github.io/site/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
                    .foregroundStyle(Color.digitalBlue_color)
            }
            Link(destination: URL(string: "https://artimewalk.github.io/site/privacy-policy")!) {
                Label("Privacy Policy", systemImage: "lock")
                    .foregroundStyle(Color.digitalBlue_color)
            }
        }
    }
    
    private func headerText() -> some View {
        Group {
            if initial {
                Text("Terms and Privacy")
            }
        }
    }
    
    private func checkedButton() -> some View {
        Group {
            if initial {
                VStack {
                    HStack {
                        Text("By pressing the button below, you agree to the Terms of Service and Privacy Policy.")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 40)
                    HStack {
                        Spacer()
                        Button(action: {
                            initialDataTransfer.isAboutAppViewPresented = false
                            initialDataTransfer.isDocumentViewPresented = false
                            
                            ARTimeWalkApp.isUserUUID = UUID().uuidString // UserUUID生成
                            Task {
                                await userRegistration()
                            }
                        }) {
                            Text("Checked")
                                .frame(width: 150, height: 40)
                                .foregroundColor(.white)
                                .background(Color.digitalBlue_color)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    private struct Encode_UserData: Codable {
        let uuid: String
        let userName: String
        let registrationDate: String
    }
    
    private struct Decode_UserID: Codable {
        let id: String
    }
    
    func userRegistration() async {
        // Date生成
        // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
        let dt = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let registrationDate = dateFormatter.string(from: dt)
        
        // struct
        let record = Encode_UserData(uuid: ARTimeWalkApp.isUserUUID, userName: ARTimeWalkApp.isUserName, registrationDate: registrationDate)
        
        // Encode
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(record) {
            do {
                // URLSession
                let url = originalURLSession.mainURL + "insert/insertUser.php"
                if let data = try await originalURLSession.postAwait_Return(stringURL: url, data: jsonData) {
                    do {
                        // Decode
                        let decoder = JSONDecoder()
                        let decodeData = try decoder.decode(Decode_UserID.self, from: data)
                        ARTimeWalkApp.isUserID = Int(decodeData.id)!
                        
                    } catch {
                        print("Error occurred: \(error.localizedDescription), DocumentView.swift, userRegistration()")
                    }
                }
            } catch {
                print("Error occurred: \(error.localizedDescription), DocumentView.swift, userRegistration()")
            }
        }
    }
}

struct DocumentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(initial: true)
            .environmentObject(InitialDataTransfer())
    }
}

