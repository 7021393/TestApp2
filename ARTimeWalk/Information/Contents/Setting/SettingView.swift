//
//  SettingView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/10.
//

import SwiftUI

struct SettingView: View {
    @StateObject private var model = SettingDataModel()
    
    var body: some View {
        ZStack {
            List {
                // MARK: User UUID
                Section(header: Text("User UUID")) {
                    HStack {
                        // Left contens
                        Text(model.displayUserUUID)
                            .underline()
                        Spacer()
                        // Right contens
                        copyUserUUIDButton()
                    }
                }
                // MARK: Change User UUID
                Section(header: Text("Change User UUID"), footer: text_ChangeUUID()) {
                    HStack {
                        // Left contens
                        TextField("User UUID", text: $model.inputUserUUID)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                        Spacer()
                        // Right contens
                        changeUserUUIDButton()
                    }
                }
                // MARK: User Name
                Section(header: Text("User Name")) {
                    HStack {
                        // Left contens
                        Text(model.displayUserName)
                            .underline()
                        Spacer()
                    }
                }
                // MARK: Change User Name
                Section(header: Text("Change User Name"), footer: text_ChangeUserName()) {
                    HStack {
                        // Left contens
                        TextField("User Name", text: $model.inputUserName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                        Spacer()
                        // Right contens
                        changeUserNameButton()
                    }
                }
            }
            progressView()
        }
        .alert("❌", isPresented: $model.isAlert_serverError) {
            
        } message: {
            Text("Server Error")
        }
    }
    
    // MARK: Copy User UUID Button
    private func copyUserUUIDButton() -> some View {
        HStack {
            Text("Copied!")
                .font(.caption)
                .foregroundStyle(Color.white)
                .frame(width: 70, height: 20)
                .background(Color.digitalBlue_color)
                .cornerRadius(15)
                .opacity(model.isPresentedBanner_copy ? 1.0 : 0.0)
            Button(action: {
                // User UUIDをコピー
                UIPasteboard.general.string = ARTimeWalkApp.isUserUUID
                model.isPresentedBanner_copy = true
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                    self.model.isPresentedBanner_copy = false
                }
            }){
                Image(systemName: model.isPresentedBanner_copy ? "checkmark.circle" : "doc.on.doc")
                    .foregroundStyle(model.isPresentedBanner_copy ? .green : Color.digitalBlue_color)
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    // MARK: Change User UUID Button
    private func changeUserUUIDButton() -> some View {
        HStack {
            Text(model.isInvalid_changeUserUUID ? "Invalid!" : "Changed!")
                .font(.caption)
                .foregroundStyle(Color.white)
                .frame(width: 70, height: 20)
                .background(model.isInvalid_changeUserUUID ? .red : Color.digitalBlue_color)
                .cornerRadius(15)
                .opacity(model.isPresentedBanner_changeUserUUID ? 1.0 : 0.0)
            Button(action: {
                model.changeUserUUID()
            }){
                Image(systemName: model.isInvalid_changeUserUUID ? "xmark" : "arrow.triangle.2.circlepath")
                    .foregroundStyle(model.isInvalid_changeUserUUID ? .red : Color.digitalBlue_color)
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    private func text_ChangeUUID() -> some View {
        VStack {
            HStack {
                Text("Please enter in uppercase letters and numbers only, in the format 'AAAAAA-BBBB-CCC-DDDDDD-EEEEEEEEE'.")
                    .font(.caption2)
                    .foregroundStyle(model.isInvalid_changeUserUUID ? .red : Color.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
                .frame(height: 35)
            Divider()
            Spacer()
                .frame(height: 5)
        }
    }
    
    // MARK: Change User Name Button
    private func changeUserNameButton() -> some View {
        HStack {
            Text(model.isInvalid_changeUserName ? "Invalid!" : "Changed!")
                .font(.caption)
                .foregroundStyle(Color.white)
                .frame(width: 70, height: 20)
                .background(model.isInvalid_changeUserName ? .red : Color.digitalBlue_color)
                .cornerRadius(15)
                .opacity(model.isPresentedBanner_changeUserName ? 1.0 : 0.0)
            Button(action: {
                model.changeUserName()
            }){
                Image(systemName: model.isInvalid_changeUserName ? "xmark" : "arrow.triangle.2.circlepath")
                    .foregroundStyle(model.isInvalid_changeUserName ? .red : Color.digitalBlue_color)
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    private func text_ChangeUserName() -> some View {
        VStack {
            HStack {
                Text("Please enter no more than 36 characters.")
                    .font(.caption2)
                    .foregroundStyle(model.isInvalid_changeUserName ? .red : Color.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
        }
    }
    
    // MARK: Progress View
    private func progressView() -> some View {
        Group {
            if model.duringPostData {
                ZStack {
                    blackSheet()
                    ProgressView()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(Color.primary)
                        .background(.regularMaterial)
                        .cornerRadius(15)
                        .font(.system(size: 20))
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        }
    }
    
    // MARK: Black Sheet
    private func blackSheet() -> some View {
            Rectangle()
                .edgesIgnoringSafeArea(.all)
                .foregroundStyle(.black)
                .opacity(0.3)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
