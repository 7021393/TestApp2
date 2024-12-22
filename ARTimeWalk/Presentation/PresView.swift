//
//  PresView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2022/12/26.
//

import SwiftUI
import struct SwiftUI.Animation

struct PresView : View {
    @StateObject private var model = PresDataModel()
    @Environment(\.dismiss) var dismiss
    
    let selectedDataSource: DataSource
    
    let multiple: Bool
    
    let dataTransfer: DataTransfer
    let annotationIndex: Int
    
    //@State private var initialPhotoDistance: Float = 1.0
    //@State private var currentPhotoDistance: Float = 1.0
    @State private var initialPhotoDistance: Float = 0.0
    @State private var currentPhotoDistance: Float = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: AR View
                ARViewContainer(model: model, currentPhotoDistance: $currentPhotoDistance, loadInitialDistance: loadInitialDistance)
                    
                //スライダー（閲覧モード）
                if model.isARDisplayActive {
                    DistanceSliderContainer(currentPhotoDistance: $currentPhotoDistance, model: model, dataTransfer: dataTransfer)
                        .onAppear {
                            print("Distanceスライダーが表示されている")
                            print("Current Distance: \(currentPhotoDistance)")
                        }
                }
                
                // MARK: ArSpatialGuide View
                if model.presAr.ar_photoArray.allSatisfy({ $0.animationBool.avatar == true }) { // Avatarの場所にいるときは描画しない
                    ArSpatialGuideView(model: model, viewingPositions: model.viewingPositions)
                }
                
                // MARK: Reference View
                Group {
                    referenceView(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                }
                .opacity(model.pickerSelection == 0 ? 1.0 : 0.0)
                
                // MARK: Grid/Finder
                grid()
                finderView()
                
                // MARK: Top Left Contents
                VStack {
                    Spacer()
                        .frame(height: 30)
                    HStack {
                        Spacer()
                            .frame(width: 30)
                        returnButton()
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 15)
                    HStack {
                        Spacer()
                            .frame(width: 30)
                        statusView()
                        Spacer()
                    }
                    Spacer()
                }
                
                // MARK: Adjust Layout
                /*
                 画面の横幅によって、レイアウトを調整
                 （iPhone縦持ち or iPhone横持ち、iPad）
                 */
                if geometry.size.width < 600 {
                    HStack {
                        Spacer()
                            .frame(width: 30)
                        changeReferenceViewButton()
                        Spacer()
                            .frame(width: 30)
                    }
                    VStack {
                        Spacer()
                        ZStack {
                            modePickerView()
                            HStack {
                                imageAlbumButton()
                                reDetectReferenceButton()
                                Spacer()
                                    .frame(width: 210)
                            }
                        }
                        ZStack {
                            mainButtonView()
                            HStack {
                                Spacer()
                                    .frame(width: 220)
                                saveButtonView()
                            }
                        }
                        Spacer()
                            .frame(height: 30)
                    }
                } else {
                    let safeAreaBottom = geometry.safeAreaInsets.bottom
                    HStack {
                        Spacer()
                            .frame(width: 170)
                        changeReferenceViewButton()
                        Spacer()
                            .frame(width: 170)
                    }
                    HStack {
                        Spacer()
                        ZStack {
                            VStack {
                                modePickerView()
                                Spacer()
                                    .frame(height: 220 - safeAreaBottom)
                            }
                            VStack {
                                HStack {
                                    imageAlbumButton()
                                    reDetectReferenceButton()
                                    Spacer()
                                        .frame(width: 70)
                                }
                                Spacer()
                                    .frame(height: 140 - safeAreaBottom)
                            }
                            VStack {
                                Spacer()
                                    .frame(height: safeAreaBottom)
                                mainButtonView()
                            }
                            VStack {
                                Spacer()
                                    .frame(height: 200 + safeAreaBottom)
                                saveButtonView()
                            }
                        }
                        Spacer()
                            .frame(width: 30)
                    }
                }
                
                // MARK: Photo Date
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                            .frame(width: 30)
                        photoDateView()
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 30)
                }
                
                // MARK: Progress/CheckMark
                progressView()
                checkMark()
            }
            // MARK: onAppear
            .onAppear {
                model.initializeReferenceReading()
            }
            
            //閲覧反映
            .onAppear {
                model.presView_init_process(multiple: multiple, selectedDataSource: selectedDataSource, dataTransfer: dataTransfer, annotationIndex: annotationIndex)
            }
            // MARK: Image Album
            .sheet(isPresented: $model.showingImageAlbum) {
                ImageAlbum(image: $model.inputFromImageAlbum)
            }
            .onChange(of: model.inputFromImageAlbum) { _ in
                model.startPhotoManipulation()
            }
            .onChange(of: geometry.size.width) { _ in
                model.isReferenceViewAnimation = false
                Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {_ in
                    model.isReferenceViewAnimation = true
                }
            }
            // MARK: isPresented Custom Alert
            .overlay {
                if model.isCustomAlert_Reference {
                    customAlertView_Reference(alertSize: min(geometry.size.width, geometry.size.height) * 0.6)
                }
                if model.isCustomAlert_Photo {
                    customAlertView_Photo(alertSize: min(geometry.size.width, geometry.size.height) * 0.6)
                }
            }
            // MARK: isPresented Alert
            .alert("⚠️", isPresented: $model.isAlert_DetectionError) {
                
            } message: {
                Text("Not enough recognition (For example, the surroundings are dark, the camera is moving, etc.)")
            }
            .alert("⚠️", isPresented: $model.isAlert_referenceAnchorIsRequired) {
                
            } message: {
                Text("Reference is required")
            }
            .alert("⚠️", isPresented: $model.isAlert_photoIsRequired) {
                
            } message: {
                Text("Photo is required")
            }
            .alert("📎", isPresented: $model.isAlert_savePhoto) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    model.reg_saveDataProcess(dataTransfer: dataTransfer)
                }
            } message: {
                Text("Add photo?")
            }
            .alert("🚀", isPresented: $model.isAlert_postPhoto) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    model.reg_saveDataProcess(dataTransfer: dataTransfer)
                }
            } message: {
                Text("Add photo?")
            }
        }
    }
    private func loadInitialDistance() {
        print("Annotation Index: \(annotationIndex)")
        
        // linkContainerArray_photoの中身を確認
        print("Photo Array Count: \(dataTransfer.linkContainerArray_photo.count)")
        dataTransfer.linkContainerArray_photo.forEach { photo in
        print("Photo Distance: \(photo.photoDistance)")
        }
        
        let validIndex = min(max(annotationIndex, 0), dataTransfer.linkContainerArray_photo.count - 1)
        guard validIndex < dataTransfer.linkContainerArray_photo.count else {
            print("Invalid annotationIndex or no photo data available")
            return
        }

        let photo = dataTransfer.linkContainerArray_photo[annotationIndex]
        let initialDistance = photo.photoDistance
        initialPhotoDistance = initialDistance
        currentPhotoDistance = initialDistance
        print("Initial Distance Loaded: \(initialDistance)")
    }

    
    
    
    // MARK: Finder
    private func finderView() -> some View {
        Group {
            if model.currentMode == .detectReference && model.detectedReferenceImage == nil {
                // Top part of the finder
                VStack(spacing: 0){
                    Spacer()
                        .frame(height: 10)
                    finders(lineVertical: false)
                    finders(lineVertical: true)
                    Spacer()
                }
                // Bottom part of the finder
                VStack(spacing: 0){
                    Spacer()
                    finders(lineVertical: true)
                    finders(lineVertical: false)
                    Spacer()
                        .frame(height: 10)
                }
            }
        }
    }
    
    private func finders(lineVertical: Bool) -> some View {
        HStack {
            Spacer()
                .frame(width: 10)
            finder(lineVertical: lineVertical)
            Spacer()
            finder(lineVertical: lineVertical)
            Spacer()
                .frame(width: 10)
        }
    }
    
    private func finder(lineVertical: Bool) -> some View {
        Rectangle()
            .frame(width: lineVertical ? 1 : 20)
            .frame(height: lineVertical ? 20 : 1)
            .foregroundStyle(Color.white)
            .opacity(0.8)
    }
    
    // MARK: Grid
    private func grid() -> some View {
        Group {
            if model.currentMode == .takeAndRegistrationPhoto {
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.white)
                        .opacity(0.8)
                    Spacer()
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.white)
                        .opacity(0.8)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(width: 0.5)
                        .foregroundStyle(Color.white)
                        .opacity(0.8)
                    Spacer()
                    Rectangle()
                        .frame(width: 0.5)
                        .foregroundStyle(Color.white)
                        .opacity(0.8)
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: Return Button
    private func returnButton() -> some View {
        Button(action: {
            model.presAr.sessionPause()
            dismiss()
        }){
            Image(systemName: "arrow.uturn.backward")
                .foregroundStyle(Color.primary)
                .frame(width: 75, height: 45)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .font(.system(size: 20))
        }
        .disabled(model.isCustomAlert_Photo)
    }
    
    // MARK: Status View
    private func statusView() -> some View {
        Group {
            if model.currentMode == .takeAndRegistrationPhoto || model.currentMode == .registrationSelectedPhotoFromImageAlbum {
                Button(action: {
                    model.isCustomAlert_Reference = true
                }){
                    Grid(alignment: .leading) {
                        GridRow {
                            Image(systemName: model.detectedReferenceImage != nil ? "checkmark.circle" : "circle")
                                .foregroundStyle(model.detectedReferenceImage != nil ? .green : Color.secondary)
                            Text("Reference")
                        }
                        GridRow {
                            Image(systemName: 0 < model.reg_photoCount ? "checkmark.circle" : "circle")
                                .foregroundStyle(0 < model.reg_photoCount ? .green : Color.secondary)
                            Text("Photo : \(model.reg_photoCount)")
                        }
                    }
                    .frame(width: 155, height: 55)
                    .foregroundStyle(Color.primary)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .font(.headline)
                }
                .opacity(model.duringPhotoManipulation ? 0.5 : 1.0)
                .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
            }
        }
    }
    
    // MARK: Photo Date
    private func photoDateView() -> some View {
        Group {
            if model.lookingPhoto {
                Text(model.dateConversion_toLocal(utcDateString: model.photoDateText).prefix(16))
                    .frame(height: 10)
                    .foregroundStyle(Color.white)
                    .font(.headline)
            }
        }
    }
    
    // MARK: Reference View
    /**
     ReferenceViewに適応しているSwiftUIの.animation機能は、
     直前の処理（画像加工等）を完了させてから動作させないと不安定な挙動をします。
     Timer.scheduledTimerなどで適度に処理時間を設ける必要があります。
     */
    private func referenceView(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        Group {
            if model.showReferenceView {
                let uiImage: UIImage = UIImage(data: dataTransfer.referenceContainerArray[model.selectedReferenceIndex].jpegData!)!
                let referenceWidth = uiImage.size.width
                let referenceHeight = uiImage.size.height
                
                let adjustedWidthHeight = model.calculationReferenceViewSize(screenWidth: screenWidth,
                                                                                screenHeight: screenHeight,
                                                                                referenceWidth: referenceWidth,
                                                                                referenceHeight: referenceHeight)
                
                let adjustedWidth: CGFloat = adjustedWidthHeight.0
                let adjustedHeight: CGFloat = adjustedWidthHeight.1
                
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: adjustedWidth,
                           height: adjustedHeight
                    )
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .opacity(0.6)
            }
        }
        .scaleEffect(model.isReferenceViewAnimation ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.3).repeat(while: model.isReferenceViewAnimation), value: model.isReferenceViewAnimation)
    }
    
    // MARK: Change Reference View
    private func changeReferenceViewButton() -> some View {
        Group {
            if model.currentMode == .detectReference && model.showReferenceView && 1 < dataTransfer.referenceContainerArray.count {
                HStack {
                    Button(action: {
                        model.changeReferenceViewProcess(dataTransfer: dataTransfer, nextReference: false)
                    }){
                        Image(systemName: "chevron.left")
                            .frame(width: 40, height: 50)
                            .foregroundStyle(Color.primary)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .font(.system(size: 20))
                    }
                    .opacity(model.selectedReferenceIndex == 0 ? 0.0 : 1.0)
                    .disabled(model.selectedReferenceIndex == 0)
                    Spacer()
                    Button(action: {
                        model.changeReferenceViewProcess(dataTransfer: dataTransfer, nextReference: true)
                    }){
                        Image(systemName: "chevron.right")
                            .frame(width: 40, height: 50)
                            .foregroundStyle(Color.primary)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .font(.system(size: 20))
                    }
                    .opacity(model.selectedReferenceIndex == dataTransfer.referenceContainerArray.count - 1 ? 0.0 : 1.0)
                    .disabled(model.selectedReferenceIndex == dataTransfer.referenceContainerArray.count - 1)
                }
            }
        }
    }
    
    // MARK: Mode Picker
    /**
     - ArSpatialGuideViewによる画面再描画の影響で、
     RegViewと同様の.pickerStyle(.wheel)を設定すると、
     Pickerが動作しなくなる。
     
     - デフォルトの.pickerStyleは、
     Pickerに表示されるLabelやTextに対して.frame()や.lineLimit()が適用されず、
     大きさを調節できない（不要なはみ出し、改行）。
     */
    private func modePickerView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 130, height: 32) // Picker select frame size
                .foregroundStyle(Color.digitalBlue_color)
                .cornerRadius(5)
            Picker(selection: $model.pickerSelection, label: Text("")) {
                Text("ViewPhoto")
                    .tag(0)
                // [Publish Reference And Photo]
                if ARTimeWalkApp.publishReferenceAndPhoto || selectedDataSource == .local { // データ公開機能がOffの場合は.globalでPhotoの追加ができない。
                    Text("AddPhoto")
                        .tag(1)
                }
            }
//            .pickerStyle(.wheel)
            .frame(height: 130)
            .onChange(of: model.pickerSelection) { _ in
                switch model.pickerSelection {
                case 0:
                    model.arExperienceAnimationTrigger = false
                    
                    if model.showReferenceView {
                        model.currentMode = .detectReference
                    } else {
                        model.currentMode = .viewPhoto
                    }
                    
                    model.presAr.reg_changePhotoAndAvatar()
                    model.arExperienceAnimationTrigger = true
                case 1:
                    model.arExperienceAnimationTrigger = false
                    model.currentMode = .takeAndRegistrationPhoto
                    model.lookingPhoto = false
                    model.presAr.ar_changePhotoAndAvatar()
                    model.arExperienceAnimationTrigger = true
                default:
                    break
                }
            }
        }
        .opacity(model.duringPhotoManipulation || model.lookingPhoto ? 0.5 : 1.0)
        .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Photo)
    }
    
    // MARK: Image Album Button
    private func imageAlbumButton() -> some View {
        Group {
            if model.currentMode == .takeAndRegistrationPhoto || model.currentMode == .registrationSelectedPhotoFromImageAlbum {
                Button(action: {
                    model.showingImageAlbum = true
                }){
                    Image(systemName: "photo.on.rectangle")
                        .frame(width: 60, height: 32)
                        .foregroundStyle(Color.primary)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                        .font(.system(size: 20))
                }
                .opacity(model.duringPhotoManipulation || model.lookingPhoto ? 0.5 : 1.0)
                .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Photo)
            }
        }
    }
    
    // MARK: Re Detect Reference Button
    private func reDetectReferenceButton() -> some View {
        Group {
            if model.currentMode == .viewPhoto {
                Button(action: {
                    model.isReferenceViewAnimation = false
                    model.currentMode = .detectReference
                    model.showReferenceView = true
                    model.startDetectReference()
                    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {_ in
                        model.isReferenceViewAnimation = true
                    }
                }){
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 60, height: 32)
                        .foregroundStyle(Color.primary)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                        .font(.system(size: 20))
                }
                .opacity(model.duringPhotoManipulation || model.lookingPhoto ? 0.6 : 1.0) // .opacityが0.5以下だとボタンが機能しなくなります。
                .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Photo)
            }
        }
    }
    
    // MARK: Main Button
    /**
     - Referenceのスキャン、Photoの表示
     - 写真の撮影/設置
     - アルバムから選択された写真の設置
     */
    private func mainButtonView() -> some View {
        Group {
            ZStack {
                switch model.currentMode {
                case .detectReference:
                    Button(action: {
                        model.checkDetectionStatus(dataTransfer: dataTransfer)
                    }) {
                        Image(systemName: "viewfinder.circle.fill")
                            .frame(width: 62, height: 62)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 62))
                    }
                    VStack {
                        Spacer()
                            .frame(height: 90)
                        Text("Tap")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    
                case .viewPhoto:
                    Group {
                        Button(action: {
                            // スペースを確保するための透明なボタン
                        }){
                            Image(systemName: "viewfinder.circle.fill")
                                .frame(width: 62, height: 62)
                                .foregroundStyle(Color.white)
                                .font(.system(size: 62))
                        }
                        VStack {
                            Spacer()
                                .frame(height: 90)
                            Text(" ")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                        }
                    }
                    .opacity(0.0)
                    
                case .takeAndRegistrationPhoto:
                    Button(action: {
                        model.presAr.reg_takeAndRegistrationPhoto()
                        model.reg_photoCount += 1
                    }){
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 3)
                                .frame(width: 62, height: 62)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                        }
                    }
                    VStack {
                        Spacer()
                            .frame(height: 90)
                        Text(" ")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    
                case .registrationSelectedPhotoFromImageAlbum:
                    Button(action: {
                        model.stopPhotoManipulation()
                    }){
                        Image(systemName: "plus.circle.fill")
                            .frame(width: 62, height: 62)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 62))
                    }
                    VStack {
                        Spacer()
                            .frame(height: 90)
                        Text(" ")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
        .disabled(model.duringPostData || model.isCustomAlert_Photo)
    }
    
    // MARK: Save Button
    private func saveButtonView() -> some View {
        Group {
            if model.currentMode == .takeAndRegistrationPhoto || model.currentMode == .registrationSelectedPhotoFromImageAlbum {
                Button(action: {
                    model.stateCheck(selectedDataSource: selectedDataSource)
                }){
                    if selectedDataSource == .local {
                        Label("Save", systemImage: "person")
                            .frame(width: 100, height: 40)
                            .foregroundStyle(Color.primary)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .foregroundStyle(Color.primary)
                            .font(.headline)
                    } else {
                        Label("Publish", systemImage: "globe")
                            .frame(width: 100, height: 40)
                            .foregroundStyle(Color.primary)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .foregroundStyle(Color.primary)
                            .font(.headline)
                    }
                }
                .opacity( model.duringPhotoManipulation ? 0.5 : 1.0)
                .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Photo)
            }
        }
    }
    
    // MARK: Custom Alert (Reference)
    private func customAlertView_Reference(alertSize: CGFloat) -> some View {
        Group {
            ZStack {
                blackSheet()
                VStack(spacing: 0) {
                    Spacer()
                    customAlertImage(uiImage: model.detectedReferenceImage, alertSize: alertSize)
                    Spacer()
                    Text("Reference")
                        .font(.headline)
                    Spacer()
                    Divider()
                        .frame(height: 0.5)
                        .background(Color.gray.opacity(0.5))
                    Button(action: {
                        model.isCustomAlert_Reference = false
                    }){
                        Text("OK")
                            .frame(width: alertSize, height: 30)
                            .foregroundStyle(.blue)
                    }
                    .frame(height: 45)
                }
                .frame(width: alertSize,
                       height: alertSize)
                .foregroundStyle(Color.primary)
                .background(.regularMaterial)
                .cornerRadius(15)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
    
    // MARK: Custom Alert (Photo)
    private func customAlertView_Photo(alertSize: CGFloat) -> some View {
        ZStack {
            blackSheet()
            VStack(spacing: 0) {
                Spacer()
                customAlertImage(uiImage: model.reg_photoImage, alertSize: alertSize)
                Spacer()
                Text("Delete this photo?")
                    .font(.headline)
                Spacer()
                Divider()
                    .frame(height: 0.5)
                    .background(Color.gray.opacity(0.5))
                HStack(spacing: 0) {
                    Button(action: {
                        model.isCustomAlert_Photo = false
                    }){
                        Text("Cancel")
                            .font(.headline)
                            .frame(width: alertSize / 2)
                            .foregroundStyle(.blue)
                    }
                    Divider()
                        .frame(width: 0.5)
                        .background(Color.gray.opacity(0.5))
                    Button(action: {
                        model.presAr.reg_removePhoto()
                        model.reg_photoCount -= 1
                        model.isCustomAlert_Photo = false
                    }){
                        Text("Delete")
                            .foregroundStyle(.red)
                            .frame(width: alertSize / 2)
                    }
                }
                .frame(height: 45)
            }
            .frame(width: alertSize,
                   height: alertSize)
            .foregroundStyle(Color.primary)
            .background(.regularMaterial)
            .cornerRadius(15)
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
    
    private func customAlertImage(uiImage: UIImage?, alertSize: CGFloat) -> some View {
        let imageMaxSize = alertSize * 0.6
        
        return ZStack {
            if let image = uiImage {
                let imageWidth = image.size.width
                let imageHeight = image.size.height
                Rectangle()
                    .frame(width: imageMaxSize, height: imageMaxSize)
                    .foregroundStyle(Color.clear)
                Image(uiImage: image)
                    .resizable()
                    .frame(width: imageHeight < imageWidth ?
                           imageMaxSize
                           : imageMaxSize * imageWidth / imageHeight,
                           height: imageHeight < imageWidth ?
                           imageMaxSize * imageHeight / imageWidth
                           : imageMaxSize)
                    .cornerRadius(5)
            } else {
                Rectangle()
                    .frame(width: imageMaxSize, height: imageMaxSize)
                    .foregroundStyle(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4, 4, 4]))
                    )
            }
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
    
    // MARK: Check Mark
    private func checkMark() -> some View {
        Group {
            if model.showingCheckMark {
                Image(systemName: "checkmark.circle")
                    .frame(width: 75, height: 75)
                    .foregroundStyle(.green)
                    .background(.regularMaterial)
                    .cornerRadius(15)
                    .font(.system(size: 30))
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            return self.repeatForever(autoreverses: autoreverses)
        } else {
            return self
        }
    }
}

struct PresView_Previews: PreviewProvider {
    static var previews: some View {
        PresView(selectedDataSource: .local, multiple: false, dataTransfer: DataTransfer.simulatorData(), annotationIndex: 0)
    }
}

struct ARViewContainer: View {
    var model: PresDataModel
    @Binding var currentPhotoDistance: Float
    let loadInitialDistance: () -> Void
    
    var body: some View {
        PresARViewContainer(model: model, currentPhotoDistance: $currentPhotoDistance)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                print("call loadinitialdistance")
                loadInitialDistance()
            }
    }
}

struct DistanceSliderContainer: View {
    @Binding var currentPhotoDistance: Float
    @State private var initialDistanceLoaded = false
    var model: PresDataModel
    var dataTransfer: DataTransfer
    
    var body: some View {
        VStack {
            ZStack {
                Text("距離設定 \(currentPhotoDistance, specifier: "%.1f")m")
                    .font(.system(size: 15))
                    .frame(width: 150, height: 30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
            }
            Slider(value: $currentPhotoDistance,
                   in: 1.0...10.0,
                   step: 1.0,
                   minimumValueLabel: Image(systemName: "camera.macro"),
                   maximumValueLabel: Image(systemName: "mountain.2.fill"),
                   label: { EmptyView() }
            )
                .foregroundStyle(Color.white)
                .accentColor(Color.digitalBlue_color)
                .onAppear{
                    if !initialDistanceLoaded {
                        print("Initializing Slider to \(currentPhotoDistance)")
                        initialDistanceLoaded = true
                    }
                }
                .onChange(of: currentPhotoDistance) { newDistance in
                    print("Slider Value Changed: \(newDistance)")
                    model.presAr.updatePhotoDistance(Float(newDistance), dataTransfer: dataTransfer)
                    print("updatePhotoDIstance called")
                }
        }
    }
    
}

