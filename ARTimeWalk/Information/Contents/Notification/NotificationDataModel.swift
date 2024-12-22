//
//  NotificationDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/16.
//

import SwiftUI

final class NotificationDataModel: ObservableObject {
    let originalURLSession = OriginalURLSession()
    
    @Published var infoMessage: String = "Network Error"
    
    init() {
        Task {
            await getNotification()
        }
    }
}
