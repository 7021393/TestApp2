//
//  PresDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/22.
//

import SwiftUI
import ARKit

final class PresDataModel: ObservableObject {
    let presAr = PresAR()
    @Published var isARDisplayActive: Bool = false
    
    
    func initializeReferenceReading() {
        startReadingProcess()
    }
    
    private func startReadingProcess() {
        print("読み取り開始")
    }
    
    func completeReferenceReading() {
        isARDisplayActive = true
        print("読み取り完了。trueに設定")
    }
    //var presAr: PresAR
    /*
    init() {
        self.presAr = PresAR()
        self.presAr.dataModel = self
    }
    
    func selectPhoto(_ photo: Pres_Photo) {
        selectedPhotoDistance = photo.photoDistance
    }
    */
    var selectedDataSource: DataSource = .local
    var multiple: Bool = false
    var annotationIndex: Int = 0
    
    @Published var isAlert_DetectionError: Bool = false
    @Published var isAlert_referenceAnchorIsRequired: Bool = false
    @Published var isAlert_photoIsRequired: Bool = false
    @Published var isAlert_savePhoto: Bool = false
    @Published var isAlert_postPhoto: Bool = false
    
    @Published var pickerSelection: Int = 0
    
    @Published var selectedReferenceIndex: Int = 0
    @Published var showReferenceView: Bool = true
    @Published var isReferenceViewAnimation: Bool = false
    
    enum mode {
        case detectReference
        case viewPhoto
        case takeAndRegistrationPhoto
        case registrationSelectedPhotoFromImageAlbum
    }
    
    @Published var currentMode: mode = .detectReference
    
    var arExperienceAnimationTrigger: Bool = false
    
    var failedDetect: Bool = false
    @Published var updateReferenceAnchorTrigger: Bool = false
    @Published var detectedReferenceImage: UIImage?
    
    var detectedAnnotationArray: [OriginalAnnotation] = []
    
    @Published var lookingPhoto: Bool = false
    @Published var photoDateText: String = ""
    
    // Add Photo
    @Published var isCustomAlert_Reference: Bool = false
    @Published var isCustomAlert_Photo: Bool = false
    
    @Published var reg_photoImage: UIImage?
    @Published var reg_photoCount: Int = 0
    
    @Published var showingImageAlbum: Bool = false
    @Published var inputFromImageAlbum: UIImage?
    
    @Published var duringPostData: Bool = false
    @Published var duringPhotoManipulation: Bool = false
    
    @Published var showingCheckMark: Bool = false
    
    // ArSpatialGuide
    @Published var viewingPositions: [ViewingPosition] = []
    
    func presView_init_process(multiple: Bool, selectedDataSource: DataSource, dataTransfer: DataTransfer, annotationIndex: Int) {
        self.selectedDataSource = selectedDataSource
        self.multiple = multiple
        self.annotationIndex = annotationIndex
        
        presAr.setImageForReferenceDetection(reference: dataTransfer.referenceContainerArray[selectedReferenceIndex])
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
            self.isReferenceViewAnimation = true
            self.startDetectReference()
        }
    }
    
    func startDetectReference() {
        // Reference認識の検査を開始
        failedDetect = true
        // Reference認識に伴う処理（PresCoordinator.swiftより"Update Reference Anchor"）を開始
        updateReferenceAnchorTrigger = true
    }
    
    func checkDetectionStatus(dataTransfer: DataTransfer) {
        if failedDetect {
            DispatchQueue.main.async {
                // Reference認識Error、アラート吹鳴
                self.isAlert_DetectionError.toggle()
                print("認識失敗")
            }
        } else {
            updateReferenceAnchorTrigger = false
            presAr.removeReferenceAnchorFromARView()
            currentMode = .viewPhoto
            detectedReferenceImage = UIImage(data: dataTransfer.referenceContainerArray[selectedReferenceIndex].jpegData!)
            
            processingAfterDetection(dataTransfer: dataTransfer)
            
            completeReferenceReading()
        }
    }
    
    func processingAfterDetection(dataTransfer: DataTransfer) {
        var annotation: OriginalAnnotation
        
        // [Multiple]
        if multiple {
            annotation = dataTransfer.annotationContainerArray[selectedReferenceIndex]
        } else {
            annotation = dataTransfer.annotationContainerArray[annotationIndex]
        }
        
        if detectedAnnotationArray.isEmpty { // 初回認識
            presentationPhotoProcess(dataTransfer: dataTransfer, annotation: annotation)
        } else { // 2回目以降
            for detectedAnnotation in detectedAnnotationArray {
                if detectedAnnotation.connectedReference.contains(annotation.reference.id) {
                    // test
                    let photosToRemove = presAr.removePhoto(referenceIDArray: detectedAnnotation.connectedReference)
                    // ArSpatialGuide
                    viewingPositions.removeAll { viewingPosition in
                        return photosToRemove.contains { $0.id == viewingPosition.id }
                    }
                }
            }
            
            // [Publish Reference Link]
            if ARTimeWalkApp.publishReferenceLink {
                if presAr.tmp_reference!.id != presAr.ar_reference!.id {
                    let data = presAr.calculationReferenceLink()
                    Task {
                        let id0 = presAr.tmp_reference!.id
                        let id1 = presAr.ar_reference!.id
                        
                        if id0 != id1 {
                            await presAr.publishReferenceLinkData(id0: id0, id1: id1, PE: data.0)
                            await presAr.publishReferenceLinkData(id0: id1, id1: id0, PE: data.1)
                        }
                    }
                }
            }
            
            presentationPhotoProcess(dataTransfer: dataTransfer, annotation: annotation)
        }
    }
    

    //閲覧反映
    func presentationPhotoProcess(dataTransfer: DataTransfer, annotation: OriginalAnnotation) {
        setReferencePositionAndEuler(dataTransfer: dataTransfer, annotation: annotation)
        assignPhotoToReference(dataTransfer: dataTransfer)
        arExperienceAnimationTrigger = true
        
        detectedAnnotationArray.append(annotation)
        presAr.tmp_ReferenceAnchor()
    }
    
    /**
     認識したReferenceおよび、Networkによって接続されている他のReferenceの位置と向きを取得
     */
    func setReferencePositionAndEuler(dataTransfer: DataTransfer, annotation: OriginalAnnotation) {
        presAr.ar_referenceArray.removeAll()
        
        let detectedReference = referencePositionAndEulerContainer(id: annotation.reference.id,
                                                                   positionAndEuler: presAr.returnReferencePositionAndEuler()!)
        
        presAr.ar_referenceArray.append(detectedReference)
        
        for link in annotation.network {
            guard let fromReference = presAr.ar_referenceArray.first(where: { $0.id == link.fromReferenceID }) else { return }
            
            let toReferencePositionAndEuler = presAr.returnNextReferencePositionAndEuler(reference: fromReference.positionAndEuler,
                                                                                         relativePositionAndOrientation: link.positionAndEuler)
            
            let toReference = referencePositionAndEulerContainer(id: link.toReferenceID,
                                                                 positionAndEuler: toReferencePositionAndEuler)
            
            presAr.ar_referenceArray.append(toReference)
        }
    }
    
    //閲覧反映
    func assignPhotoToReference(dataTransfer: DataTransfer) {
        let presentationLinkContainerArray_photo = dataTransfer.linkContainerArray_photo.filter { container in
            presAr.ar_referenceArray.contains(where: { $0.id == container.referenceID })
        }
        
        let count = presentationLinkContainerArray_photo.count
        
        if 0 < count {
            // 一定間隔で写真とAvatarの位置、向きを算出（大量の処理を一度に行うことを防止）
            var index = 0
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                guard let reference = self.presAr.ar_referenceArray.first(where: { $0.id == presentationLinkContainerArray_photo[index].referenceID }) else { return }
                
                self.presAr.presentationPhoto(referencePositionAndEuler: reference.positionAndEuler, LinkContainer_Photo: presentationLinkContainerArray_photo[index])
                
                // ArSpatialGuide
                self.viewingPositions.append(ViewingPosition(id: presentationLinkContainerArray_photo[index].id))
                
                index += 1
                
                if index == count {
                    timer.invalidate()
                }
            }
        }
    }
    
    func calculationReferenceViewSize(screenWidth: CGFloat, screenHeight: CGFloat, referenceWidth: CGFloat, referenceHeight: CGFloat) -> (CGFloat, CGFloat) {
        let imageAspectRatio = referenceWidth / referenceHeight
        let screenAspectRatio = screenWidth / screenHeight
        
        var adjustedWidth: CGFloat
        var adjustedHeight: CGFloat
        
        if imageAspectRatio > screenAspectRatio { // 画像が縦長の場合
            adjustedHeight = screenHeight
            adjustedWidth = adjustedHeight * imageAspectRatio
            if adjustedWidth > screenWidth {
                adjustedWidth = screenWidth
                adjustedHeight = adjustedWidth / imageAspectRatio
            }
        } else { // 画像が横長の場合
            adjustedWidth = screenWidth
            adjustedHeight = adjustedWidth / imageAspectRatio
            if adjustedHeight > screenHeight {
                adjustedHeight = screenHeight
                adjustedWidth = adjustedHeight * imageAspectRatio
            }
        }
        return(adjustedWidth, adjustedHeight)
    }
    
    func changeReferenceViewProcess(dataTransfer: DataTransfer, nextReference: Bool) {
        // Referenceの認識を停止
        updateReferenceAnchorTrigger = false
        // ReferenceViewのアニメーションを停止
        isReferenceViewAnimation = false
        // ReferenceViewを非表示
        showReferenceView = false
        // ProgressViewを表示
        duringPostData = true
        
        if nextReference {
            selectedReferenceIndex += 1
        } else {
            selectedReferenceIndex -= 1
        }
        
        presAr.setImageForReferenceDetection(reference: dataTransfer.annotationContainerArray[selectedReferenceIndex].reference)
        
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {_ in
            // ProgressViewを非表示
            self.duringPostData = false
            // ReferenceViewを表示
            self.showReferenceView = true
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                // ReferenceViewのアニメーションを再開
                self.isReferenceViewAnimation = true
                // Referenceの認識を再開
                self.updateReferenceAnchorTrigger = true
            }
        }
    }
    
    // UTC（協定世界時）をデバイスのタイムゾーンに変換
    func dateConversion_toLocal(utcDateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        // 入力された日付文字列の形式を確認
        let components = utcDateString.components(separatedBy: " ")
        let dateComponents = components[0].components(separatedBy: "-")
        let timeComponents = components.count > 1 ? components[1].components(separatedBy: ":") : []
        
        var formatString: String = ""
        
        if dateComponents.count == 1 { // 年
            formatString = "yyyy"
        } else if dateComponents.count == 2 { // 年月
            formatString = "yyyy-MM"
        } else if dateComponents.count == 3 && timeComponents.count == 0 { // 年月日
            formatString = "yyyy-MM-dd"
        } else if dateComponents.count == 3 && timeComponents.count == 2 { // 年月日時分
            formatString = "yyyy-MM-dd HH:mm"
        } else if dateComponents.count == 3 && timeComponents.count == 3 { // 年月日時分秒
            formatString = "yyyy-MM-dd HH:mm:ss"
        } else { // それ以外の場合はエラー
            return "Error"
        }
        
        dateFormatter.dateFormat = formatString
        
        // UTCの日時文字列をDateオブジェクトに変換
        if let utcDate = dateFormatter.date(from: utcDateString) {
            // デバイスのタイムゾーンに変換
            dateFormatter.locale = Locale.autoupdatingCurrent
            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
            dateFormatter.dateFormat = formatString
            return dateFormatter.string(from: utcDate)
        } else {
            return "Error"
        }
    }
    
    // ArSpatialGuide
    func updateViewingPosition(frame: ARFrame) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let interfaceOrientation = windowScene.windows.first!.windowScene?.interfaceOrientation
        
        // Calculate FOV and Focal length
        let viewPortSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let projectionMat = frame.camera.projectionMatrix(for: interfaceOrientation!,
                                                          viewportSize: viewPortSize, zNear: 0.1, zFar: 0.9)
        let xScale = projectionMat[0, 0]
        let yScale = projectionMat[1, 1]
        
        let fovX = 2 * atan(1/xScale)
        let fovY = fovX * Float(viewPortSize.height / viewPortSize.width)
        let pixelFocalLenX = xScale * Float(viewPortSize.width) / 2
        let pixelFocalLenY = yScale * Float(viewPortSize.height) / 2
        
        for index in viewingPositions.indices {
            let value = presAr.spatialGuide(frame: frame, index: index, interfaceOrientation: interfaceOrientation!, viewPortSize: viewPortSize, pixelFocalLenX: pixelFocalLenX, pixelFocalLenY: pixelFocalLenY, fovX: fovX, fovY: fovY)
            
            viewingPositions[value.id].theta = value.theta
            viewingPositions[value.id].phi = value.phi
            viewingPositions[value.id].radius = value.radius
            viewingPositions[value.id].position = value.position
            viewingPositions[value.id].onFrame = value.onFrame
            viewingPositions[value.id].fixedDistanceFromCenter = value.fixedDistanceFromCenter
            viewingPositions[value.id].fixedGreatCircleDistanceToFrame = value.fixedGreatCircleDistanceToFrame
        }
    }
}
