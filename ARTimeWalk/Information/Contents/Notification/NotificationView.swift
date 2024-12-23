//
//  NotificationView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/10.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var model = NotificationDataModel()
    
    var body: some View {
        List {
            Section(header: Text("NOTIFICATION")) {
                Text(model.infoMessage)
            }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
