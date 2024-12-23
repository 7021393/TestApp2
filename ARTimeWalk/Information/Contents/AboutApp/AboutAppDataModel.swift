//
//  AboutAppDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/07/07.
//

import SwiftUI

final class AboutAppDataModel: ObservableObject {
    @Published var selection: Int = 0
    
    init() {
        let currenTintColor = UIColor.digitalBlue_uiColor
        UIPageControl.appearance().currentPageIndicatorTintColor = currenTintColor
        UIPageControl.appearance().pageIndicatorTintColor = currenTintColor!.withAlphaComponent(0.2)
    }
}
