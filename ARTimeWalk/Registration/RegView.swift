//
//  RegView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2022/12/26.
//

import SwiftUI
import MapKit

struct RegView : View {
    @StateObject private var model = RegDataModel()
    @Environment(\.dismiss) var dismiss
    
    let dataTransfer: DataTransfer
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: AR View
                RegARViewContainer(model: model)
                    .edgesIgnoringSafeArea(.all)
                
                // MARK: Grid/Reticle
                grid()
                reticle()
                
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
                    let safeAreaTop = geometry.safeAreaInsets.top
                    let safeAreaBottom = geometry.safeAreaInsets.bottom
                    
                    //AR画面上で被写体を確認するための表示領域
                    finderView(width: geometry.size.width, height: geometry.size.height + safeAreaTop + safeAreaBottom)
                    VStack {
                        Spacer()
                        sliderView(screenWidthShort: true)
                        ZStack {
                            modePickerView(width: geometry.size.width, height: geometry.size.height)
                            HStack {
                                imageAlbumButton()
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
                    let safeAreaLeading = geometry.safeAreaInsets.leading
                    let safeAreaTrailing = geometry.safeAreaInsets.trailing
                    let safeAreaBottom = geometry.safeAreaInsets.bottom
                    
                    finderView(width: geometry.size.width + safeAreaLeading + safeAreaTrailing,
                               height: geometry.size.height)
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                                .frame(height: safeAreaBottom)
                            sliderView(screenWidthShort: false)
                        }
                        ZStack {
                            VStack {
                                modePickerView(width: geometry.size.width, height: geometry.size.height)
                                Spacer()
                                    .frame(height: 220 - safeAreaBottom)
                            }
                            VStack {
                                HStack {
                                    imageAlbumButton()
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
                
                // MARK: Progress/CheckMark
                progressView()
                checkMark()
            }
            // MARK: onAppear
            .onAppear {
                model.setScreenWidth(width: geometry.size.width)
            }
            // MARK: Image Album
            .sheet(isPresented: $model.showingImageAlbum) {
                ImageAlbum(image: $model.inputFromImageAlbum)
            }
            .onChange(of: model.inputFromImageAlbum) { _ in
                // PhotoDistanceExperiments
                model.regAr.setPhotoDistanceAndSize(sliderVal_photoDistance: model.sliderVal_photoDistance)
                
                model.startPhotoManipulation()
            }
            // MARK: Exchange Slider Value
            .onChange(of: geometry.size.width) { _ in
                model.exchangeSliderVal()
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
            .alert("⚠️", isPresented: $model.isAlert_firstLocationError) {
                
            } message: {
                Text("Location information is required")
            }
            .alert("❌", isPresented: $model.isAlert_secondLocationError) {
                
            } message: {
                Text("Location information is required")
            }
            .alert("⚠️", isPresented: $model.isAlert_referenceAnchorIsRequired) {
                
            } message: {
                Text("Reference is required")
            }
            .alert("⚠️", isPresented: $model.isAlert_referenceImageError) {
                
            } message: {
                Text("Not enough recognition (For example, the surroundings are dark, the camera is moving, etc...)")
            }
            .alert("📎", isPresented: $model.isAlert_postReference) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    model.saveDataProcess()
                    DispatchQueue.main.async {
                        dataTransfer.sumImageDataSizeInAppDocumentsMB += model.regAr.tmp_sumImageDataSizeInAppDocumentsKB / 1000.0
                    }
                }
            } message: {
                Text("Save reference? (No photograph)")
            }
            .alert("📎", isPresented: $model.isAlert_postAllData) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    model.saveDataProcess()
                    DispatchQueue.main.async {
                        dataTransfer.sumImageDataSizeInAppDocumentsMB += model.regAr.tmp_sumImageDataSizeInAppDocumentsKB / 1000.0
                    }
                }
            } message: {
                Text("Save reference and photo?")
            }
            .alert("❌", isPresented: $model.isAlert_referenceStateError) {
                
            } message: {
                Text("Please register the reference anchor when location information is allowed")
            }
        }
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
    
    // MARK: Reticle
    private func reticle() -> some View {
        Group {
            if model.currentMode == .detectReference {
                Rectangle()
                    .frame(width: 30, height: 1.0)
                    .foregroundStyle(Color.white)
                    .opacity(0.8)
                Rectangle()
                    .frame(width: 1.0, height: 30)
                    .foregroundStyle(Color.white)
                    .opacity(0.8)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: Return Button
    private func returnButton() -> some View {
        Button(action: {
            model.regAr.sessionPause()
            model.currentMode = .takeAndRegistrationPhoto // Clear finderBlackSheet
            dismiss()
        }){
            Image(systemName: "arrow.uturn.backward")
                .frame(width: 75, height: 45)
                .foregroundStyle(Color.primary)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .font(.system(size: 20))
        }
        .opacity(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation ? 0.5 : 1.0)
        .disabled(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
    }
    
    // MARK: Status View
    private func statusView() -> some View {
        Button(action: {
            model.isCustomAlert_Reference = true
        }){
            Grid(alignment: .leading) {
                GridRow {
                    Image(systemName: model.referenceImage != nil ? "checkmark.circle" : "circle")
                        .foregroundStyle(model.referenceImage != nil ? .green : Color.secondary)
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
        .opacity(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation ? 0.5 : 1.0)
        .disabled(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
    }
    
    // MARK: Finder
    private func finderView(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if model.currentMode == .detectReference {
                if 0.0 < model.sliderVal_cropLongSide {
                    VStack(spacing: 0) {
                        finderBlackSheet(vertical: true, topOrLeft: true, width: width, height: height)
                            finders(vertical: true, topOrLeft: true, lineVertical: false, width: width, height: height)
                            finders(vertical: true, topOrLeft: true, lineVertical: true, width: width, height: height)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Spacer()
                            finders(vertical: true, topOrLeft: false, lineVertical: true, width: width, height: height)
                            finders(vertical: true, topOrLeft: false, lineVertical: false, width: width, height: height)
                        finderBlackSheet(vertical: true, topOrLeft: false, width: width, height: height)
                    }
                }
                
                if 0.0 < model.sliderVal_cropShortSide {
                    HStack(spacing: 0) {
                        finderBlackSheet(vertical: false, topOrLeft: true, width: width, height: height)
                            finders(vertical: false, topOrLeft: true, lineVertical: true, width: width, height: height)
                            finders(vertical: false, topOrLeft: true, lineVertical: false, width: width, height: height)
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        Spacer()
                            finders(vertical: false, topOrLeft: false, lineVertical: false, width: width, height: height)
                            finders(vertical: false, topOrLeft: false, lineVertical: true, width: width, height: height)
                        finderBlackSheet(vertical: false, topOrLeft: false, width: width, height: height)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func finders(vertical: Bool, topOrLeft: Bool, lineVertical: Bool, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if vertical {
                HStack {
                    finder(vertical: vertical, topOrLeft: topOrLeft, lineVertical: lineVertical, width: width, height: height)
                    Spacer()
                    finder(vertical: vertical, topOrLeft: topOrLeft, lineVertical: lineVertical, width: width, height: height)
                }
            } else {
                VStack {
                    finder(vertical: vertical, topOrLeft: topOrLeft, lineVertical: lineVertical, width: width, height: height)
                    Spacer()
                    finder(vertical: vertical, topOrLeft: topOrLeft, lineVertical: lineVertical, width: width, height: height)
                }
            }
        }
    }
    
    private func finder(vertical: Bool, topOrLeft: Bool, lineVertical: Bool, width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .frame(width: lineVertical ? 1 : 20)
            .frame(height: lineVertical ? 20 : 1)
            .foregroundStyle(Color.white)
            .opacity(0.8)
            .offset(x: vertical ?
                    0
                    : topOrLeft ?
                    -(width / 2 - width / 2 * model.sliderVal_cropShortSide)
                    : width / 2 - width / 2 * model.sliderVal_cropShortSide,
                    y: vertical ?
                    topOrLeft ?
                    -(height / 2 - height / 2 * model.sliderVal_cropLongSide)
                    : height / 2 - height / 2 * model.sliderVal_cropLongSide
                    : 0)
    }
    
    private func finderBlackSheet(vertical: Bool, topOrLeft: Bool, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if vertical {
                Rectangle()
                    .frame(height: height / 2)
                    .foregroundStyle(Color.black)
                    .opacity(0.5)
                    .offset(x: 0,
                            y: topOrLeft ?
                            -(height / 2 - height / 2 * model.sliderVal_cropLongSide)
                            : height / 2 - height / 2 * model.sliderVal_cropLongSide)
            } else {
                Rectangle()
                    .frame(width: width / 2)
                    .foregroundStyle(Color.black)
                    .opacity(0.5)
                    .offset(x: topOrLeft ?
                            -(width / 2 - width / 2 * model.sliderVal_cropShortSide)
                            : width / 2 - width / 2 * model.sliderVal_cropShortSide,
                            y: 0)
            }
        }
    }
    
    // MARK: Slider
    private func sliderView(screenWidthShort: Bool) -> some View {
        Group {
            if model.currentMode == .detectReference {
                if screenWidthShort {
                    VStack {
                        slider_cropLongSide(screenWidthShort: true)
                        slider_cropShortSide(screenWidthShort: true)
                    }
                    .frame(width: 180)
                    .offset(y: 10)
                } else {
                    VStack {
                        slider_cropShortSide(screenWidthShort: false)
                        slider_cropLongSide(screenWidthShort: false)
                    }
                    .frame(width: 180)
                    .rotationEffect(.degrees(-90))
                    .offset(x: 60)
                }
            } else if model.currentMode == .takeAndRegistrationPhoto {
                // PhotoDistanceExperiments
                if screenWidthShort {
                    meterAndSlider()
                        .frame(width: 330)
                        .offset(y: 10)
                } else {
                    meterAndSlider()
                        .frame(width: 330)
                        .rotationEffect(.degrees(-90))
                        .offset(x: 60)
                }
            }
        }
    }
    
    private func slider_cropLongSide(screenWidthShort: Bool) -> some View {
        Slider(value: $model.sliderVal_cropLongSide,
               in: 0.00...model.maxCropLongSideRatio,
               onEditingChanged: { _ in
            model.sliderVal_cropShortSide = 0.00
        },
               minimumValueLabel: Image(systemName: "square"),
               maximumValueLabel: Image(systemName: screenWidthShort ? "square.split.1x2" : "square.split.2x1"),
               label: { EmptyView() }
        )
        .foregroundStyle(Color.white)
        .accentColor(Color.digitalBlue_color)
    }
    
    private func slider_cropShortSide(screenWidthShort: Bool) -> some View {
        Slider(value: $model.sliderVal_cropShortSide,
               in: 0.00...model.maxCropShortSideRatio,
               onEditingChanged: { _ in
            model.sliderVal_cropLongSide = 0.00
        },
               minimumValueLabel: Image(systemName: "square"),
               maximumValueLabel: Image(systemName: screenWidthShort ? "square.split.2x1" : "square.split.1x2"),
               label: { EmptyView() }
        )
        .foregroundStyle(Color.white)
        .accentColor(Color.digitalBlue_color)
    }
    
    // PhotoDistanceExperiments Parameters
    private func meterAndSlider() -> some View {
        Group {
            // 以下の変数は調整してください。
            let minDistance: Float = 1.0 // 写真のカメラからの最小距離[m]（デフォルト）
            let maxDistance: Float = 10.0 // 写真のカメラからの最大距離[m]
            let step: Float = 1.0 // 距離間隔[m]
            
            VStack {
                ZStack {
                    Text(String(model.sliderVal_photoDistance) + " m")
                        .font(.system(size: 20))
                        .frame(width: 80, height: 30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                }
                Slider(value: $model.sliderVal_photoDistance,
                       in: minDistance...maxDistance,
                       step: step,
                       minimumValueLabel: Image(systemName: "camera.macro"),
                       maximumValueLabel: Image(systemName: "mountain.2.fill"),
                       label: { EmptyView() }
                )
                .foregroundStyle(Color.white)
                .accentColor(Color.digitalBlue_color)
            }
        }
    }
    
    // MARK: Mode Picker
    private func modePickerView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 130, height: 32) // Picker select frame size
                .foregroundStyle(Color.digitalBlue_color)
                .cornerRadius(5)
            Picker(selection: $model.pickerSelection, label: Text("")) {
                Label("Reference", systemImage: "viewfinder")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .tag(0)
                Label("Camera", systemImage: "camera")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .tag(1)
            }
            .pickerStyle(.wheel)
            .frame(width: 150, height: 130)
            .onChange(of: model.pickerSelection) { _ in
                switch model.pickerSelection {
                case 0:
                    if model.cropFlag {
                        model.settingCropSize(width: width, height: height)
                        model.cropFlag = false
                    }
                    model.currentMode = .detectReference
                case 1:
                    model.currentMode = .takeAndRegistrationPhoto
                    model.sliderVal_cropLongSide = 0.0
                    model.sliderVal_cropShortSide = 0.0
                default:
                    break
                }
            }
        }
        .opacity(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation ? 0.5 : 1.0)
        .disabled(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
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
                .opacity(model.duringPhotoManipulation ? 0.5 : 1.0)
                .disabled(model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
            }
        }
    }
    
    // MARK: Main Button
    /**
     - Referenceのスキャン
     - 写真の撮影/設置
     - アルバムから選択された写真の設置
     */
    private func mainButtonView() -> some View {
        Group {
            ZStack {
                switch model.currentMode {
                case .detectReference:
                    Button(action: {
                        if model.releaseLongPress {
                            model.detectReferenceAnchor()
                            model.releaseLongPress = false
                        }
                    }) {
                        Image(systemName: "viewfinder.circle.fill")
                            .frame(width: 62, height: 62)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 62))
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            model.releaseLongPress = true
                            model.captureAndValidateReferenceImage()
                        }
                    )
                    VStack {
                        Spacer()
                            .frame(height: 90)
                        Text("Long Press")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    
                case .takeAndRegistrationPhoto:
                    Button(action: {
                        // PhotoDistanceExperiments
                        model.regAr.setPhotoDistanceAndSize(sliderVal_photoDistance: model.sliderVal_photoDistance)
                        
                        model.regAr.takeAndRegistrationPhoto()
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
        .disabled(model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
    }
    
    // MARK: Save Button
    private func saveButtonView() -> some View {
        Button(action: {
            model.secondStateCheck()
        }){
            Label("Save", systemImage: "person")
                .frame(width: 100, height: 40)
                .foregroundStyle(Color.primary)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .foregroundStyle(Color.primary)
                .font(.headline)
        }
        .opacity(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation ? 0.5 : 1.0)
        .disabled(model.updateReferenceAnchorTrigger || model.duringPhotoManipulation || model.duringPostData || model.isCustomAlert_Reference || model.isCustomAlert_Photo)
    }
    
    // MARK: Custom Alert (Reference)
    private func customAlertView_Reference(alertSize: CGFloat) -> some View {
        ZStack {
            blackSheet()
            VStack(spacing: 0) {
                Spacer()
                customAlertImage(uiImage: model.referenceImage, alertSize: alertSize)
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
                        model.regAr.removePhoto()
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
        ZStack {
            let imageMaxSize = alertSize * 0.6
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
                .foregroundStyle(Color.black)
                .opacity(0.3)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
    }
}

struct RegView_Previews: PreviewProvider {
    static var previews: some View {
        RegView(dataTransfer: DataTransfer())
    }
}

