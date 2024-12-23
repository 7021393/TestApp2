//
//  MapView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2022/12/20.
//

import SwiftUI

struct MapView: View {
    @StateObject private var model = MapDataModel()
    @StateObject private var dataTransfer = DataTransfer()
    @StateObject private var initialDataTransfer = InitialDataTransfer()
    
    let simulator: Bool
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    // MARK: Map View
                    MapViewContainer(model: model, dataTransfer: dataTransfer)
                        .edgesIgnoringSafeArea(.all)
                    
                    // MARK: Top Contents
                    VStack {
                        Spacer()
                            .frame(height: 10)
                        reloadButton(width: geometry.size.width)
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                    .frame(height: 10)
                                informationButton()
                                Spacer()
                                    .frame(height: 20)
                                functionButton()
                                Spacer()
                            }
                            Spacer()
                                .frame(width: 35)
                        }
                        Spacer()
                    }
                    
                    // MARK: Bottom Contents
                    VStack {
                        Spacer()
                        multipleRecognitionButton(width: geometry.size.width)
                        ZStack {
                            VStack {
                                HStack {
                                    Spacer()
                                        .frame(width: 40)
                                    dataSizeView()
                                    Spacer()
                                }
                                Spacer()
                                    .frame(height: 110)
                            }
                            HStack {
                                Spacer()
                                    .frame(width: 40)
                                selectDataSource()
                                Spacer()
                                plusButton()
                                Spacer()
                                    .frame(width: 30)
                            }
                            scrollBar(width: geometry.size.width)
                        }
                    }
                }
            }
        }
        // MARK: onAppear
        .onAppear {
            // [Simulator]
            if simulator == false {
                model.mapView_init_process(dataTransfer: dataTransfer, initialDataTransfer: initialDataTransfer)
            }
        }
        .onChange(of: dataTransfer.photoCountBool) { _ in
            model.updatePhotoCount(dataTransfer: dataTransfer)
        }
        // MARK: isPresented RegView
        .fullScreenCover(isPresented: $model.RegViewModal, onDismiss: {
            // Dismiss後の処理
            model.map.removeAllAnnotations()
            model.getReferenceData(dataTransfer: dataTransfer)
        }) {
            RegView(dataTransfer: dataTransfer)
        }
        // MARK: isPresented AboutAppView
        .fullScreenCover(isPresented: $initialDataTransfer.isAboutAppViewPresented) {
            AboutAppView(initial: true)
                .environmentObject(initialDataTransfer)
        }
        .accentColor(Color.primary)
    }
    
    // MARK: Reload Button
    private func reloadButton(width: CGFloat) -> some View {
        Button(action: {
            model.map.removeAllAnnotations()
            model.getReferenceData(dataTransfer: dataTransfer)
        }){
            Label("Reload", systemImage: "arrow.counterclockwise")
                .frame(width: 150, height: 30)
                .foregroundStyle(Color.white)
                .background(Color.digitalBlue_color)
                .cornerRadius(10)
                .foregroundStyle(Color.primary)
                .font(.subheadline)
                .shadow(color: .black.opacity(0.5), radius: 5)
        }
    }
    
    // MARK: Information Button
    private func informationButton() -> some View {
        NavigationLink {
            InfoView()
                .environmentObject(initialDataTransfer)
        } label: {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Color.primary)
                .frame(width: 60, height: 35)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .font(.system(size: 20))
                .shadow(color: .black.opacity(0.5), radius: 5)
        }
    }
    
    // MARK: Function Area
    private func functionButton() -> some View {
        VStack {
            Spacer()
            locationButton()
            Spacer()
            Divider()
            Spacer()
            changeMapTypeButton()
            Spacer()
        }
        .frame(width: 60, height: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.5), radius: 5)
    }
    
    private func locationButton() -> some View {
        Button(action: {
            model.map.updateGNSSTrackingMode()
        }){
            Image(systemName: "location")
                .foregroundStyle(Color.primary)
                .frame(width: 60, height: 35)
                .font(.system(size: 20))
        }
    }
    
    private func changeMapTypeButton() -> some View {
        Button(action: {
            model.changeMapTypeIndex()
        }){
            Image(systemName: "map")
                .foregroundStyle(Color.primary)
                .frame(width: 60, height: 35)
                .font(.system(size: 20))
        }
    }
    
    // MARK: Multiple Recognition Button
    private func multipleRecognitionButton(width: CGFloat) -> some View {
        Group {
            if model.selectedDataSource == .global && 1 < dataTransfer.annotationContainerArray.count {
                NavigationLink {
                    DetailView(mapView: model.map.mapView, mapTypeIndex: model.mapTypeIndex, selectedDataSource: model.selectedDataSource, multiple: true, simulator: false, dataTransfer: dataTransfer, annotationIndex: 0)
                } label: {
                    multipleRecognitionButtonText()
                }
                .disabled(dataTransfer.annotationContainerArray.last!.reference.jpegData == nil)
                .offset(x: 0, y: model.scrollBarBool ? 0 : 180)
                .animation(.easeInOut(duration: 0.1), value: model.scrollBarBool ? 0 : 180)
            }
        }
    }
    
    // MARK: Multiple Recognition Button Text
    private func multipleRecognitionButtonText() -> some View {
        ZStack {
            HStack {
                Spacer()
                // Text
                Text("Multiple Recognition")
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                Spacer()
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 15))
                Spacer()
                    .frame(width: 10)
            }
        }
        .frame(width: 250, height: 30)
        .foregroundStyle(Color.primary)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.5), radius: 5)
    }
    
    // MARK: Scroll Bar
    private func scrollBar(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 20) {
                ForEach(0 ..< dataTransfer.annotationContainerArray.count, id: \.self) { index in
                    NavigationLink {
                        DetailView(mapView: model.map.mapView, mapTypeIndex: model.mapTypeIndex, selectedDataSource: model.selectedDataSource, multiple: false, simulator: false, dataTransfer: dataTransfer, annotationIndex: index)
                    } label: {
                        bar(width: width, index: index)
                    }
                    .disabled(dataTransfer.annotationContainerArray[index].reference.jpegData == nil)
                }
                // 横スクロールの余白調整
                ForEach(0 ..< 2) { _ in
                    Rectangle()
                        .frame(width: width < 600 ?
                               abs((width - width * 0.8) / 2 - 20)
                               : abs((width - 550) / 2 - 20),
                               height: 100)
                        .foregroundStyle(Color.clear)
                }
            }
            .frame(height: 120)
            .offset(x: width < 600 ?
                    abs((width - width * 0.8) / 2)
                    : abs((width - 550) / 2))
        }
        .offset(x: 0, y: model.scrollBarBool ? 0 : 180)
        .animation(.easeInOut(duration: 0.1), value: model.scrollBarBool ? 0 : 180)
    }
    
    // MARK: Bar
    private func bar(width: CGFloat, index: Int) -> some View {
        HStack {
            Spacer()
                .frame(width: 10)
            // Reference Image
            barReferenceImage(index: index)
            Spacer()
                .frame(width: 10)
            // Text
            barText(index: index)
            Spacer()
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 35))
            Spacer()
                .frame(width: 10)
        }
        .frame(width: width < 600 ?
               width * 0.8
               : 550, height: 100)
        .foregroundStyle(Color.primary)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.5), radius: 5)
    }
    
    // MARK: Bar Reference Image
    private func barReferenceImage(index: Int) -> some View {
        ZStack {
            Rectangle()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.clear)
            if dataTransfer.annotationContainerArray[index].reference.jpegData == nil {
                ProgressView()
            } else {
                let referenceWidth = UIImage(data: dataTransfer.annotationContainerArray[index].reference.jpegData!)!.size.width
                let referenceHeight = UIImage(data: dataTransfer.annotationContainerArray[index].reference.jpegData!)!.size.height
                Image(uiImage: UIImage(data: dataTransfer.annotationContainerArray[index].reference.jpegData!)!)
                    .resizable()
                    .frame(width: referenceHeight < referenceWidth ?
                           80
                           : 80 * referenceWidth / referenceHeight,
                           height: referenceHeight < referenceWidth ?
                           80 * referenceHeight / referenceWidth
                           : 80)
                    .cornerRadius(5)
                // Icon
                barReferenceImageIcon(index: index)
            }
        }
    }
    
    // MARK: Bar Reference Image Icon
    private func barReferenceImageIcon(index: Int) -> some View {
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
            .frame(width: 80)
        }
        .frame(height: 80)
        .opacity(dataTransfer.annotationContainerArray[index].reference.userID == ARTimeWalkApp.isUserID || dataTransfer.annotationContainerArray[index].reference.userID == 0 ? 1 : 0)
    }
    
    // MARK: Bar Text
    private func barText(index: Int) -> some View {
        VStack(alignment: .leading) {
            // 登録日（秒は表示しない）
            Text(model.dateConversion_toLocal(utcDateString: dataTransfer.annotationContainerArray[index].reference.registrationDate).prefix(16))
                .font(.caption)
            Spacer()
                .frame(height: 5)
            // UUID
            Text(dataTransfer.annotationContainerArray[index].reference.uuid)
                .lineLimit(1)
            Spacer()
                .frame(height: 5)
            HStack {
                // 紐づけられている写真の枚数
                Label(String(model.photoCount[index]), systemImage: "photo")
                    .font(.caption)
                Spacer()
                    .frame(width: 15)
                // 自分が登録した写真の枚数
                if 0 < model.yourPhotoCount[index] {
                    Text("(")
                        .font(.caption)
                    Label(String(model.yourPhotoCount[index]), systemImage: "person.crop.circle")
                        .font(.caption)
                        .foregroundStyle(Color.teal)
                    Text(")")
                        .font(.caption)
                }
                Spacer()
                    .frame(width: 15)
            }
        }
    }
    
    // MARK: Select Data Source Area
    private func selectDataSource() -> some View {
        HStack {
            Spacer()
            localButton()
            Spacer()
            Divider()
            Spacer()
            globalButton()
            Spacer()
        }
        .frame(width: 180, height: 60)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.5), radius: 5)
        .opacity(model.bottomContentsFade ? 0 : 1)
    }
    
    private func localButton() -> some View {
        VStack {
            Button(action: {
                model.selectedDataSource = .local
                model.map.removeAllLines() // Lineの削除
                model.map.resetLineVariables() // Line用変数のリセット
                model.selectDataSourceProcess(dataTransfer: dataTransfer)
            }){
                Image(systemName: "person")
                    .font(.system(size: 30))
            }
            Text("Local")
                .font(.caption)
        }
        .foregroundStyle(model.selectedDataSource == .local ? Color.teal : Color.gray)
        .disabled(model.selectedDataSource == .local)
    }
    
    private func globalButton() -> some View {
        VStack {
            Button(action: {
                model.selectedDataSource = .global
                model.selectDataSourceProcess(dataTransfer: dataTransfer)
            }){
                Image(systemName: "globe")
                    .font(.system(size: 30))
            }
            Text("Global")
                .font(.caption)
        }
        .foregroundStyle(model.selectedDataSource == .global ? Color.teal : Color.gray)
        .disabled(model.selectedDataSource == .global)
    }
    
    // MARK: Data Size View
    private func dataSizeView() -> some View {
        HStack {
            Spacer()
                .frame(width: 10)
            Text("Data:")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(String(format: "%.2f MB", dataTransfer.sumImageDataSizeInAppDocumentsMB))
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Spacer()
                .frame(width: 10)
        }
        .frame(width: 180, height: 30)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.5), radius: 5)
        .opacity(model.selectedDataSource == .local && model.bottomContentsFade == false ? 1 : 0)
    }
    
    // MARK: Plus Button
    private func plusButton() -> some View {
        Group {
            if model.selectedDataSource == .local {
                Button(action: {
                    model.RegViewModal.toggle()
                }){
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.digitalBlue_color)
                        .font(.system(size: 60))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                }
                .opacity(model.bottomContentsFade ? 0 : 1)
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(simulator: true)
    }
}
