//
//  RegDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/22.
//

import SwiftUI
import RealityKit
import MapKit

final class RegDataModel: ObservableObject {
    let regAr = RegAR()
    
    @Published var pickerSelection: Int = 1
    
    @Published var referenceImage: UIImage?
    @Published var reg_photoImage: UIImage?
    @Published var reg_photoCount: Int = 0
    
    @Published var showingImageAlbum: Bool = false
    @Published var inputFromImageAlbum: UIImage?
    
    @Published var isAlert_firstLocationError: Bool = false
    @Published var isAlert_secondLocationError: Bool = false
    @Published var isAlert_referenceAnchorIsRequired: Bool = false
    @Published var isAlert_referenceImageError: Bool = false
    @Published var isAlert_postReference: Bool = false
    @Published var isAlert_postAllData: Bool = false
    @Published var isAlert_referenceStateError: Bool = false
    
    @Published var isCustomAlert_Reference: Bool = false
    @Published var isCustomAlert_Photo: Bool = false
    
    @Published var duringPostData: Bool = false
    @Published var duringPhotoManipulation: Bool = false
    @Published var updateReferenceAnchorTrigger: Bool = false
    
    @Published var showingCheckMark: Bool = false
    
    @Published var cropFlag: Bool = true
    @Published var maxCropLongSideRatio: CGFloat = 0.8
    @Published var maxCropShortSideRatio: CGFloat = 0.8
    
    @Published var sliderVal_cropLongSide: CGFloat = 0.0
    @Published var sliderVal_cropShortSide: CGFloat = 0.0
    
    // PhotoDistanceExperiments
    @Published var sliderVal_photoDistance: Float = 0.0
    
    @Published var releaseLongPress: Bool = false
    
    var failedDetect: Bool = false
    
    init() {
        firstStatusCheck()
    }
    
    enum mode {
        case detectReference
        case takeAndRegistrationPhoto
        case registrationSelectedPhotoFromImageAlbum
    }
    
    @Published var currentMode: mode = .takeAndRegistrationPhoto
    
    func captureAndValidateReferenceImage() {
        regAr.captureReferenceImage(verticalRatio: sliderVal_cropLongSide, horizontalRatio: sliderVal_cropShortSide) { validateResult in
            if validateResult { // 無効なReferenceImageをはじく
                self.failedDetect = true
                
                DispatchQueue.main.async {
                    self.isAlert_referenceImageError.toggle()
                }
            } else {
                self.updateReferenceAnchorTrigger = true
                self.failedDetect = true
            }
        }
    }
    
    func detectReferenceAnchor() {
        if failedDetect { // Referenceが認識できなかった場合にはじく
            updateReferenceAnchorTrigger = false
            
            DispatchQueue.main.async {
                // test
                // ReferenceImageErrorではなく、DetectionErrorとしてアラートを吹鳴すべき
                self.isAlert_referenceImageError.toggle()
            }
        } else {
            self.updateReferenceAnchorTrigger = false
            
            regAr.removeReferenceAnchor()
            currentMode = .takeAndRegistrationPhoto
            pickerSelection = 1
            
            referenceImage = UIImage(data: regAr.reg_reference!.jpegData)
        }
    }
    
    func startPhotoManipulation() {
        regAr.preProcessingPhotoManipulation(uiImage: inputFromImageAlbum!) {
            self.duringPhotoManipulation = true
            self.currentMode = .registrationSelectedPhotoFromImageAlbum
        }
    }
    
    func stopPhotoManipulation() {
        self.duringPhotoManipulation = false
        regAr.registrationSelectedPhotoFromImageAlbum(image: inputFromImageAlbum!) {
            self.reg_photoCount += 1
            self.currentMode = .takeAndRegistrationPhoto
        }
    }
    
    func tapProcessing(entityType: EntityType, entity: Entity) {
        switch entityType.kind {
        case .photo:
            if let index = regAr.reg_photoArray.firstIndex(where: {$0.photoPlaneEntity == entity}) {
                reg_photoImage = UIImage(data: regAr.reg_photoArray[index].jpegData)!
                
                regAr.willRemoveIndex = index
                isCustomAlert_Photo = true
            }
        case .avatar:
            if let index = regAr.reg_photoArray.firstIndex(where: {$0.avatar.entity == entity}) {
                reg_photoImage = UIImage(data: regAr.reg_photoArray[index].jpegData)!
                
                regAr.willRemoveIndex = index
                isCustomAlert_Photo = true
            }
        default:
            break
        }
    }
    
    func firstStatusCheck() {
        // 位置情報の許可をCheck
        let guarded = getAuthorizationStatus()
        if guarded == 2 {
            isAlert_firstLocationError.toggle()
        }
    }
    
    func secondStateCheck() {
        // 位置情報の許可をCheck
        let guarded = getAuthorizationStatus()
        if guarded == 2 {
            isAlert_secondLocationError.toggle()
        } else {
            // 参照点と写真の数をCheck
            if 0 < reg_photoCount && referenceImage != nil {
                if referenceStateCheck() {
                    isAlert_postAllData.toggle()
                } else {
                    isAlert_referenceStateError.toggle()
                }
            } else if referenceImage != nil {
                if referenceStateCheck() {
                    isAlert_postReference.toggle()
                } else {
                    isAlert_referenceStateError.toggle()
                }
            } else {
                isAlert_referenceAnchorIsRequired.toggle()
            }
        }
    }
    
    // 位置情報の許可状況を取得
    private func getAuthorizationStatus() -> Int32 {
        let manager = CLLocationManager()
        return manager.authorizationStatus.rawValue
    }
    
    // Referenceに緯度経度情報が設定されているかを確認
    private func referenceStateCheck() -> Bool {
        let reference = regAr.reg_reference!
        if reference.latitude == 0.0 && reference.longitude == 0.0 && reference.magneticHeading == 0.0 {
            return false
        } else {
            return true
        }
    }
    
    var screenWidth: Double = 0.0
    func setScreenWidth(width: Double) {
        screenWidth = width
    }
    
    func exchangeSliderVal() {
        let tmpCropLongSide = sliderVal_cropLongSide
        sliderVal_cropLongSide = sliderVal_cropShortSide
        sliderVal_cropShortSide = tmpCropLongSide
        
        let tmpMaxCropLongSideRatio = maxCropLongSideRatio
        maxCropLongSideRatio = maxCropShortSideRatio
        maxCropShortSideRatio = tmpMaxCropLongSideRatio
    }
    
    func settingCropSize(width: CGFloat, height: CGFloat) {
        guard let cropSize = regAr.returnCropSize() else { return }
        
        if width < height {
            maxCropLongSideRatio = cropSize.0
            maxCropShortSideRatio = cropSize.1
        } else {
            maxCropLongSideRatio = cropSize.1
            maxCropShortSideRatio = cropSize.0
        }
    }
    
    func saveDataProcess() {
        duringPostData = true
        
        regAr.saveToAppDB()
        
        duringPostData = false
        showingCheckMark = true
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
            self.showingCheckMark = false
        }
    }
}
