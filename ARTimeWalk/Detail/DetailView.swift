//
//  DetailView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/22.
//

import SwiftUI
import MapKit

struct DetailView: View {
    @StateObject private var model = DetailDataModel()
    @Environment(\.dismiss) var dismiss
    
    /*
     - mapView              : データ削除時のAnnotation削除処理（MapView）用変数
     - mapTypeIndex         : 地図の見た目引き継ぎ
     
     - selectedDataSource   : データ取得先（Local or Global）
     
     - multiple             : MultipleRecognition対応Bool値
     - simulator            : シミュレーター（Xcode）対応Bool値、サーバーとの通信スキップ、シミュレーター用データ読み込み
     
     - dataTransfer         : データ引き継ぎ用変数
     - annotationIndex      : MapViewで選択したAnnotationがClusterだった場合の該当データ番号（Clusterではない場合は0）
     */
    
    let mapView: MKMapView
    let mapTypeIndex: Int
    
    let selectedDataSource: DataSource
    
    let multiple: Bool
    let simulator: Bool
    
    let dataTransfer: DataTransfer
    let annotationIndex: Int
    
    // iPhone横持ち or iPadの画面分割比率
    let firstListRatio: Double = 2.3 / 5
    let secondListRatio: Double = 2.7 / 5
    // デバイスの画面に対するPhoto画像の最大サイズの比率
    let photoRatio_shingleList: Double = 0.28
    let photoRatio_doubleList: Double = 0.23
    // デバイスの画面に対するReference画像の最大サイズの比率
    let referenceRatio_shingleList: Double = 0.5
    let referenceRatio_doubleList: Double = 0.4
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                // MARK: Adjust Layout
                /*
                 画面の横幅によって、レイアウトを調整
                 （iPhone縦持ち or iPhone横持ち、iPad）
                 */
                if dataTransfer.annotationContainerArray.isEmpty == false {
                    if geometry.size.width < 600 {
                        List{
                            firstLlist(doubleList: false, width: geometry.size.width)
                            secondList(doubleList: false, width: geometry.size.width)
                        }
                    } else {
                        HStack {
                            List{
                                firstLlist(doubleList: true, width: geometry.size.width)
                            }
                            .frame(width: geometry.size.width * firstListRatio)
                            List{
                                secondList(doubleList: true, width: geometry.size.width)
                            }
                        }
                    }
                }
                progressView()
            }
            // MARK: onAppear
            .onAppear {
                model.detailMap.changeMapType(index: mapTypeIndex)
                
                // [Simulator]
                if simulator == false {
                    model.detailView_init_process(multiple: multiple, selectedDataSource: selectedDataSource, dataTransfer: dataTransfer, annotationIndex: annotationIndex)
                }
            }
            // MARK: isPresented PresView
            .fullScreenCover(isPresented: $model.PresViewModal, onDismiss: {
                // test
                // Dismiss後の処理（PresView -> DetailView）
                model.updatePhotoCount(dataTransfer: dataTransfer)
            }) {
                PresView(selectedDataSource: selectedDataSource, multiple: multiple, dataTransfer: dataTransfer, annotationIndex: annotationIndex)
            }
            // MARK: isPresented Custom Alert
            .overlay {
                if model.isCustomAlert_deleteReference {
                    customAlertView_deleteReference(alertSize: min(geometry.size.width, geometry.size.height) * 0.6)
                }
            }
            // MARK: isPresented Alert
            .alert("🚀", isPresented: $model.isAlert_publishReference) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    Task {
                        await model.publishDataInApp(mapView: mapView, dataTransfer: dataTransfer)
                        dismiss()
                    }
                }
            } message: {
                Text("Publish the reference? (No photo)")
            }
            .alert("🚀", isPresented: $model.isAlert_publishAllData) {
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    Task {
                        await model.publishDataInApp(mapView: mapView, dataTransfer: dataTransfer)
                        dismiss()
                    }
                }
            } message: {
                Text("Publish the reference and photo?")
            }
            .alert("⚠️", isPresented: $model.isAlert_deletePhoto) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    model.deletePhoto(dataTransfer: dataTransfer)
                }
            } message: {
                Text("Delete this photo?")
            }
            .alert("📆", isPresented: $model.isAlert_changePhotoDate) {
                TextField("Date", text: $model.inputPhotoDate)
                    .autocapitalization(.none)
                Button("Cancel", role: .cancel) {}
                Button("OK") {
                    model.changePhotoDate(dataTransfer: dataTransfer)
                }
            } message: {
                Text("Change the date?\n\nPlease enter in the format 'yyyy' or 'yyyy-mm' or 'yyyy-mm-dd' or 'yyyy-mm-dd hh:mm'")
            }
            .alert("⚠️", isPresented: $model.isAlert_invalidDateFormat) {
                
            } message: {
                Text("Invalid date format")
            }
            .alert("❌", isPresented: $model.isAlert_serverError) {
                
            } message: {
                Text("Server Error")
            }
            // test
            .alert("😅", isPresented: $model.isAlert_publishIsNotAvailable) {
                
            } message: {
                Text("The data publication function is not available. Stay tuned for future updates!")
            }
        }
    }
    
    // MARK: First List
    private func firstLlist(doubleList: Bool, width: CGFloat) -> some View {
        Group {
            let annotation = dataTransfer.annotationContainerArray[annotationIndex]
            // Start
            Section {
                startSection(doubleList: doubleList, width: width, annotation: annotation)
            }
            if selectedDataSource == .local {
                Section {
                    publishSection()
                }
            }
        }
    }
    
    // MARK: Second List
    private func secondList(doubleList: Bool, width: CGFloat) -> some View {
        Group {
            let annotation = dataTransfer.annotationContainerArray[annotationIndex]
            // Photo
            Section {
                // Photo Count
                photoCount(annotation: annotation)
                // Scroll Photo
                scrollPhoto(doubleList: doubleList, width: width, annotation: annotation)
                // Photo Detail
                photoDetail()
            }
            // Reference
            Section {
                // Reference Count
                referenceCount(annotation: annotation)
                // Scroll Reference
                scrollReference(doubleList: doubleList, width: width)
                // Reference Detail
                referenceDetail()
            }
        }
    }
    
    // need refactoring
    // MARK: Start
    private func startSection(doubleList: Bool, width: CGFloat, annotation: OriginalAnnotation) -> some View {
        Group {
            // Image and Text
            VStack {
                HStack {
                    Spacer()
                    if let image: UIImage = UIImage(named: "undraw_Landscape_mode_re_r964") {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: doubleList ? width * firstListRatio * referenceRatio_shingleList : width * 0.6,
                                   height: doubleList ? width * firstListRatio * referenceRatio_shingleList * image.size.height / image.size.width : width * 0.6 * image.size.height / image.size.width)
                            .cornerRadius(10)
                    } else {
                        // 画像が見つからなかった場合の代替処理
                        Text("Image Not Found")
                    }
                    Spacer()
                }
                Text("View The Photo")
                    .font(.headline)
                    .padding(.top, 10)
                Text("(Add The Photo)")
                    .font(.subheadline)
                Spacer()
                    .frame(height: 0)
                Text("Detect the reference and view the photo. The photo will appear when you move to the avatar's position and orientation.")
                    .multilineTextAlignment(.center)
                    .padding(.all)
            }
            // Start Button
            HStack {
                Spacer()
                Button(action: {
                    model.PresViewModal.toggle()
                }){
                    Text("Start")
                        .foregroundStyle(Color.digitalBlue_color)
                }
                .opacity(dataTransfer.annotationContainerArray.allSatisfy { $0.reference.photoCount > 0 } && (dataTransfer.linkContainerArray_photo.isEmpty || dataTransfer.linkContainerArray_photo.contains { $0.jpegData == nil }) ? 0.5 : 1.0)
                .disabled(dataTransfer.annotationContainerArray.allSatisfy { $0.reference.photoCount > 0 } && (dataTransfer.linkContainerArray_photo.isEmpty || dataTransfer.linkContainerArray_photo.contains { $0.jpegData == nil }))
                Spacer()
            }
        }
    }
    
    // MARK: Publish
    private func publishSection() -> some View {
        HStack {
            Spacer()
            Button(action: {
                // No processing in case of simulator
                if simulator == false {
                    // [Publish Reference And Photo]
                    if ARTimeWalkApp.publishReferenceAndPhoto {
                        if dataTransfer.linkContainerArray_photo.isEmpty {
                            model.isAlert_publishReference.toggle()
                        } else {
                            model.isAlert_publishAllData.toggle()
                        }
                    } else {
                        model.isAlert_publishIsNotAvailable.toggle()
                    }
                }
            }){
                Text("Publish")
                    .foregroundStyle(Color.digitalBlue_color)
            }
            Spacer()
        }
    }
    
    // MARK: Photo Count
    private func photoCount(annotation: OriginalAnnotation) -> some View {
        HStack {
            Label("Photo", systemImage: "photo")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(String(model.photoCount))
                .lineLimit(nil)
                .multilineTextAlignment(.trailing)
            if 0 < model.yourPhotoCount {
                Text("(")
                Label(String(model.yourPhotoCount), systemImage: "person.crop.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.teal)
                    .lineLimit(nil)
                    .multilineTextAlignment(.trailing)
                Text(")")
            }
        }
    }
    
    // MARK: Scroll Photo
    private func scrollPhoto(doubleList: Bool, width: CGFloat, annotation: OriginalAnnotation) -> some View {
        Group {
            let shingleListPhotoSize = width * photoRatio_shingleList
            let doubleListPhotoSize = width * secondListRatio * photoRatio_doubleList
            
            if dataTransfer.linkContainerArray_photo.isEmpty == false {
                HStack {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .center, spacing: 30) {
                            ForEach(0 ..< dataTransfer.linkContainerArray_photo.count, id: \.self) { index in
                                // Photo
                                photo(doubleList: doubleList, width: width, index: index)
                            }
                            // 横スクロールの余白調整
                            ForEach(0 ..< 2) { _ in
                                VStack {
                                    Rectangle()
                                        .frame(width: doubleList ? doubleListPhotoSize - 30 : shingleListPhotoSize - 30,
                                               height: doubleList ? doubleListPhotoSize : shingleListPhotoSize)
                                        .foregroundStyle(Color.clear)
                                    Spacer()
                                        .frame(height: 10)
                                    Image(systemName: "ellipsis.rectangle")
                                        .foregroundStyle(Color.clear)
                                        .font(.system(size: 25))
                                }
                            }
                        }
                        .offset(x: doubleList ? doubleListPhotoSize : shingleListPhotoSize) // 写真位置オフセット（写真を中央に配置）
                    }
                    .frame(width: doubleList ? doubleListPhotoSize * 3 : shingleListPhotoSize * 3) // スクロール範囲（横幅）
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(width: doubleList ? doubleListPhotoSize : shingleListPhotoSize,
                               height: doubleList ? doubleListPhotoSize : shingleListPhotoSize)
                        .foregroundStyle(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4, 4, 4]))
                        )
                    Spacer()
                }
            }
        }
    }
    
    // MARK: Photo
    private func photo(doubleList: Bool, width: CGFloat, index: Int) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .frame(width: doubleList ? width * secondListRatio * photoRatio_doubleList : width * photoRatio_shingleList,
                           height: doubleList ? width * secondListRatio * photoRatio_doubleList : width * photoRatio_shingleList)
                    .foregroundStyle(Color.clear)
                
                if dataTransfer.linkContainerArray_photo[index].jpegData == nil {
                    ProgressView()
                } else {
                    let uiImage = UIImage(data: dataTransfer.linkContainerArray_photo[index].jpegData!)!
                    let photoWidth = uiImage.size.width
                    let photoHeight = uiImage.size.height
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: photoWidth < photoHeight ?
                               doubleList ?
                               width * secondListRatio * photoRatio_doubleList * photoWidth / photoHeight
                               : width * photoRatio_shingleList * photoWidth / photoHeight
                               : doubleList ?
                               width * secondListRatio * photoRatio_doubleList
                               : width * photoRatio_shingleList,
                               height: photoWidth < photoHeight ?
                               doubleList ?
                               width * secondListRatio * photoRatio_doubleList
                               : width * photoRatio_shingleList
                               : doubleList ?
                               width * secondListRatio * photoRatio_doubleList * photoHeight / photoWidth
                               : width * photoRatio_shingleList * photoHeight / photoWidth)
                        .cornerRadius(10)
                    // Photo Icon
                    photoIcon(doubleList: doubleList, width: width, index: index)
                }
            }
            Spacer()
                .frame(height: 10)
            // Photo Button
            Button(action: {
                model.pushedPhotoDetailButton(dataTransfer: dataTransfer, index: index)
            }){
                Image(systemName: dataTransfer.linkContainerArray_photo[index].detailButton ? "ellipsis.rectangle.fill" : "ellipsis.rectangle")
                    .foregroundStyle(Color.digitalBlue_color)
                    .font(.system(size: 25))
            }
        }
    }
    
    // MARK: Photo Icon
    private func photoIcon(doubleList: Bool, width: CGFloat, index: Int) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(Color.teal)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .font(.system(size: 20))
            }
            .frame(width: doubleList ? width * secondListRatio * photoRatio_doubleList : width * photoRatio_shingleList)
        }
        .frame(height: doubleList ? width * secondListRatio * photoRatio_doubleList : width * photoRatio_shingleList)
        .opacity(dataTransfer.linkContainerArray_photo[index].userID == ARTimeWalkApp.isUserID || dataTransfer.linkContainerArray_photo[index].userID == 0 ? 1 : 0)
    }
    
    // MARK: Photo Detail
    private func photoDetail() -> some View {
        Group {
            if model.appearDetail_photo {
                // Date
                HStack {
                    Text("Date")
                        .foregroundStyle(Color.secondary)
                    // 日時変更機能（imageAlbumの写真のみ）
                    if (dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == ARTimeWalkApp.isUserID || dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == 0) && dataTransfer.linkContainerArray_photo[model.photoDetailIndex].imageAlbum {
                        Button(action: {
                            model.isAlert_changePhotoDate.toggle()
                        }){
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(Color.digitalBlue_color)
                                .font(.system(size: 20))
                        }
                    }
                    Spacer()
                    Text(model.dateConversion_toLocal(utcDateString:dataTransfer.linkContainerArray_photo[model.photoDetailIndex].registrationDate).prefix(16)) // 秒は表示しない
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.top, 10)
                // UUID
                HStack {
                    Text("UUID")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].uuid))
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                // User
                HStack {
                    Text("User")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    if dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == ARTimeWalkApp.isUserID || dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == 0 {
                        Text("You")
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userName))
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                    }
                }
                // Data Size
                HStack {
                    Text("DataSize")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(String(format: "%.2f KB", dataTransfer.linkContainerArray_photo[model.photoDetailIndex].dataSizeKB))
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                // Delete or Copy
                if dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == ARTimeWalkApp.isUserID || dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userID == 0 {
                    HStack{
                        Spacer()
                        Button(action: {
                            model.isAlert_deletePhoto.toggle()
                        }){
                            Text("Delete")
                                .foregroundStyle(Color.red)
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Dataをコピー
                            UIPasteboard.general.string = String(1) + ", " +  String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].registrationDate) + ", " + String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].uuid) + ", " + String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].userName) + ", " + String(dataTransfer.linkContainerArray_photo[model.photoDetailIndex].dataSizeKB)
                            
                            model.isPresentedBanner_copy_photo = true
                            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                                self.model.isPresentedBanner_copy_photo = false
                            }
                        }){
                            if model.isPresentedBanner_copy_photo {
                                Text("Copied!")
                                    .foregroundStyle(Color.green)
                            } else {
                                Text("Copy")
                                    .foregroundStyle(Color.digitalBlue_color)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: Reference Count
    private func referenceCount(annotation: OriginalAnnotation) -> some View {
        HStack {
            Label("Reference", systemImage: "viewfinder")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(String(model.referenceCount))
                .lineLimit(nil)
                .multilineTextAlignment(.trailing)
            if 0 < model.yourReferenceCount {
                Text("(")
                Label(String(model.yourReferenceCount), systemImage: "person.crop.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.teal)
                    .lineLimit(nil)
                    .multilineTextAlignment(.trailing)
                Text(")")
            }
        }
    }
    
    // MARK: Scroll Reference
    private func scrollReference(doubleList: Bool, width: CGFloat) -> some View {
        HStack {
            let shingleListReferenceSize = width * referenceRatio_shingleList
            let doubleListReferenceSize = width * secondListRatio * referenceRatio_doubleList
            
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 30) {
                    ForEach(0 ..< dataTransfer.referenceContainerArray.count, id: \.self) { index in // check
                        // Reference
                        reference(doubleList: doubleList, width: width, index: index)
                    }
                    // 横スクロールの余白調整
                    ForEach(0 ..< 2) { _ in
                        VStack {
                            Rectangle()
                                .frame(width: doubleList ? doubleListReferenceSize - 30 : shingleListReferenceSize - 30,
                                       height: doubleList ? doubleListReferenceSize : shingleListReferenceSize)
                                .foregroundStyle(Color.clear)
                            Spacer()
                                .frame(height: 10)
                            Image(systemName: "ellipsis.rectangle")
                                .foregroundStyle(Color.clear)
                                .font(.system(size: 25))
                        }
                    }
                }
                .offset(x: doubleList ? doubleListReferenceSize : shingleListReferenceSize)
            }
            .frame(width: doubleList ? doubleListReferenceSize * 3 : shingleListReferenceSize * 3)
            Spacer()
        }
    }
    
    // MARK: Reference
    private func reference(doubleList: Bool, width: CGFloat, index: Int) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .frame(width: doubleList ? width * secondListRatio * referenceRatio_doubleList : width * referenceRatio_shingleList,
                           height: doubleList ? width * secondListRatio * referenceRatio_doubleList : width * referenceRatio_shingleList)
                    .foregroundStyle(Color.clear)
                if dataTransfer.referenceContainerArray[index].jpegData == nil {
                    ProgressView()
                } else {
                    let uiImage = UIImage(data: dataTransfer.referenceContainerArray[index].jpegData!)!
                    let referenceWidth = uiImage.size.width
                    let referenceHeight = uiImage.size.height
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: referenceWidth < referenceHeight ?
                               doubleList ?
                               width * secondListRatio * referenceRatio_doubleList * referenceWidth / referenceHeight
                               : width * referenceRatio_shingleList * referenceWidth / referenceHeight
                               : doubleList ?
                               width * secondListRatio * referenceRatio_doubleList
                               : width * referenceRatio_shingleList,
                               height: referenceWidth < referenceHeight ?
                               doubleList ?
                               width * secondListRatio * referenceRatio_doubleList
                               : width * referenceRatio_shingleList
                               : doubleList ?
                               width * secondListRatio * referenceRatio_doubleList * referenceHeight / referenceWidth
                               : width * referenceRatio_shingleList * referenceHeight / referenceWidth)
                        .cornerRadius(10)
                    // Reference Icon
                    referenceIcon(doubleList: doubleList, width: width, index: index)
                }
            }
            Spacer()
                .frame(height: 10)
            Button(action: {
                model.pushedReferenceDetailButton(dataTransfer: dataTransfer, index: index)
            }){
                Image(systemName: dataTransfer.referenceContainerArray[index].detailButton ? "ellipsis.rectangle.fill" : "ellipsis.rectangle")
                    .foregroundStyle(Color.digitalBlue_color)
                    .font(.system(size: 25))
            }
        }
    }
    
    // MARK: Reference Icon
    private func referenceIcon(doubleList: Bool, width: CGFloat, index: Int) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(Color.teal)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .font(.system(size: 20))
            }
            .frame(width: doubleList ? width * secondListRatio * referenceRatio_doubleList : width * referenceRatio_shingleList)
        }
        .frame(height: doubleList ? width * secondListRatio * referenceRatio_doubleList : width * referenceRatio_shingleList)
        .opacity(dataTransfer.referenceContainerArray[index].userID == ARTimeWalkApp.isUserID || dataTransfer.referenceContainerArray[index].userID == 0 ? 1 : 0)
    }
    
    // MARK: Reference Detail
    private func referenceDetail() -> some View {
        Group {
            if model.appearDetail_reference {
                // Map View
                HStack {
                    DetailMapViewContainer(model: model)
                        .frame(height: 150)
                        .cornerRadius(10)
                }
                // Date
                HStack {
                    Text("Date")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(model.dateConversion_toLocal(utcDateString: dataTransfer.referenceContainerArray[model.referenceDetailIndex].registrationDate).prefix(16)) // 秒は表示しない
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.top, 10)
                // UUID
                HStack {
                    Text("UUID")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].uuid))
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                // User
                HStack {
                    Text("User")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    if dataTransfer.referenceContainerArray[model.referenceDetailIndex].userID == ARTimeWalkApp.isUserID || dataTransfer.referenceContainerArray[model.referenceDetailIndex].userID == 0 {
                        Text("You")
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].userName))
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                    }
                }
                // Data Size
                HStack {
                    Text("DataSize")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(String(format: "%.2f KB", dataTransfer.referenceContainerArray[model.referenceDetailIndex].dataSizeKB))
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                // Delete or Copy
                if dataTransfer.referenceContainerArray[model.referenceDetailIndex].userID == ARTimeWalkApp.isUserID || dataTransfer.referenceContainerArray[model.referenceDetailIndex].userID == 0 {
                    HStack {
                        Spacer()
                        Button(action: {
                            model.checkReferenceExisted(dataTransfer: dataTransfer)
                            model.isCustomAlert_deleteReference.toggle()
                        }){
                            Text("Delete")
                                .foregroundStyle(Color.red)
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Dataをコピー
                            UIPasteboard.general.string =  String(0) + ", " + String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].registrationDate) + ", " + String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].uuid) + ", " + String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].userName) + ", " + String(dataTransfer.referenceContainerArray[model.referenceDetailIndex].dataSizeKB)
                            
                            model.isPresentedBanner_copy_reference = true
                            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                                self.model.isPresentedBanner_copy_reference = false
                            }
                        }){
                            if model.isPresentedBanner_copy_reference {
                                Text("Copied!")
                                    .foregroundStyle(Color.green)
                            } else {
                                Text("Copy")
                                    .foregroundStyle(Color.digitalBlue_color)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: Custom Alert (Delete Reference)
    private func customAlertView_deleteReference(alertSize: CGFloat) -> some View {
        ZStack {
            blackSheet()
            VStack(spacing: 0) {
                Spacer()
                scrollPhoto_deleteReference(alertSize: alertSize)
                Spacer()
                Text("Delete this reference? (The displayed photo will also be deleted)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Divider()
                    .frame(height: 0.5)
                    .background(Color.gray.opacity(0.5))
                HStack(spacing: 0) {
                    Button(action: {
                        model.isCustomAlert_deleteReference = false
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
                        model.deleteReference(mapView: mapView, dataTransfer: dataTransfer)
                        model.isCustomAlert_deleteReference = false
                        dismiss()
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
    
    // MARK: Scroll Photo (Delete Reference)
    private func scrollPhoto_deleteReference(alertSize: CGFloat) -> some View {
        Group {
            let imageMaxSize = alertSize * 0.4
            
            if model.photoArray_deleteReference.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 30) {
                        ForEach(0 ..< model.photoArray_deleteReference.count, id: \.self) { index in
                            // Photo
                            photo_deleteReference(photo: model.photoArray_deleteReference[index], imageMaxSize: imageMaxSize)
                        }
                        // 横スクロールの余白調整
                        ForEach(0 ..< 2) { _ in
                            Rectangle()
                                .frame(width: imageMaxSize - 30, height: imageMaxSize - 30)
                                .foregroundStyle(Color.clear)
                        }
                    }
                    .offset(x: imageMaxSize)
                }
                .frame(width: imageMaxSize * 3)
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
    
    // MARK: Photo (Delete Reference)
    private func photo_deleteReference(photo: LinkContainer_Photo, imageMaxSize: CGFloat) -> some View {
        ZStack {
            let image = photo.jpegData
            let uiImage = UIImage(data: image!)!
            let imageWidth = uiImage.size.width
            let imageHeight = uiImage.size.height
            Rectangle()
                .frame(width: imageMaxSize, height: imageMaxSize)
                .foregroundStyle(Color.clear)
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: imageHeight < imageWidth ?
                       imageMaxSize
                       : imageMaxSize * imageWidth / imageHeight,
                       height: imageHeight < imageWidth ?
                       imageMaxSize * imageHeight / imageWidth
                       : imageMaxSize)
                .cornerRadius(5)
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

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(mapView: MKMapView(), mapTypeIndex: 0, selectedDataSource: .local, multiple: false, simulator: true, dataTransfer: DataTransfer.simulatorData(), annotationIndex: 0)
    }
}
