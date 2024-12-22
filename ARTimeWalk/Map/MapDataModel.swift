//
//  MapDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/22.
//

import SwiftUI

final class MapDataModel: ObservableObject {
    let map = Map()
    let originalURLSession = OriginalURLSession()
    
    @Published var selectedDataSource: DataSource = .local
    @Published var mapTypeIndex: Int = 0
    
    @Published var scrollBarBool: Bool = false
    @Published var bottomContentsFade: Bool = false
    
    @Published var RegViewModal: Bool = false
    @Published var AboutAppViewModal: Bool = false
    
    @Published var photoCount: [Int] = []
    @Published var yourPhotoCount: [Int] = []
    
    var appDB_sumImageDataSizeInAppDocumentsKB: Double = 0.0
    
    let dataRange: Double = 250.0
    let linkRange: Double = 200.0
    
    func mapView_init_process(dataTransfer: DataTransfer, initialDataTransfer: InitialDataTransfer) {
        if ARTimeWalkApp.isUserID == 0 { //　サーバー上でユーザー登録ができていない場合は説明画面から表示する。
            initialDataTransfer.isAboutAppViewPresented.toggle() // 説明画面を表示
        } else {
            Task {
                await access()
            }
        }
        // Reference取得
        getReferenceData(dataTransfer: dataTransfer)
    }
    
    func changeMapTypeIndex() {
        mapTypeIndex = (mapTypeIndex + 1) % 2
        map.changeMapType(index: mapTypeIndex)
    }
    
    func selectDataSourceProcess(dataTransfer: DataTransfer) {
        map.removeAllAnnotations()
        getReferenceData(dataTransfer: dataTransfer)
    }
    
    /*
     地図上のAnnotationは、表示領域に応じてデータを取得している。
     この際、Server側のDB探索コストを考慮し、表示領域の広さに応じて取得するデータを変化させている。
     Annotationには以下の3種類がある。

     - Minimum  : 広範囲のデータ取得に適した、最小限の情報を含むAnnotation
     - Normal   : ネットワークの探索を行わず、Annotationが指すReferenceのデータのみを格納したAnnotation（.localのみ）
     - Network  : ネットワークによって紐づけられた全てのデータを探索し、格納したAnnotation（.globalのみ）
     */
    func getReferenceData(dataTransfer: DataTransfer) {
        switch selectedDataSource {
        case .local:
            getImageDataSizeInAppDocuments()
            getNormalReferenceDataFromAppDB()
            DispatchQueue.main.async {
                dataTransfer.sumImageDataSizeInAppDocumentsMB = self.appDB_sumImageDataSizeInAppDocumentsKB / 1000.0
            }
        case .global:
            // Line描画用変数をリセット
            map.resetLineVariables()
            // 描画されているLineを全て削除
            map.removeAllLines()
            
            let mapRange = map.getMapRange()
            
            // 地図の表示範囲によって処理を分岐
            if dataRange < mapRange.2 { // 表示範囲が広い
                Task {
                    await getMinimumReferenceDataFromServerDB(latitude: mapRange.0, longitude: mapRange.1, range: mapRange.2)
                }
            } else { // 表示範囲が狭い
                Task {
                    await getNetworkReferenceDataFromServerDB(latitude: mapRange.0, longitude: mapRange.1, range: mapRange.2)
                }
            }
        }
    }
    
    func setDataTransferAnnotationArray(dataTransfer: DataTransfer, selectedAnnotation: OriginalAnnotation, index: Int) {
        // 選択したAnnotationのデータを格納
        dataTransfer.annotationContainerArray.append(selectedAnnotation)
        photoCount.append(0)
        yourPhotoCount.append(0)
        getReferenceJpegData(dataTransfer: dataTransfer, jpegDataFileName: selectedAnnotation.reference.jpegDataFileName, index: index)
    }
    
    func resetDataTransferAnnotationArray(dataTransfer: DataTransfer) {
        dataTransfer.annotationContainerArray.removeAll()
        
        // test
        photoCount.removeAll()
        yourPhotoCount.removeAll()
    }
    
    func getReferenceJpegData(dataTransfer: DataTransfer, jpegDataFileName: String, index: Int) {
        switch selectedDataSource {
        case .local:
            getReferenceJpegDataFromAppDocuments(dataTransfer: dataTransfer, jpegDataFileName: jpegDataFileName, index: index)
        case .global:
            Task {
                await getReferenceJpegDataFromServerDirectory(dataTransfer: dataTransfer, jpegDataFileName: jpegDataFileName, index: index)
            }
        }
    }
    
    func appearScrollBar() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {_ in
            self.scrollBarBool = true
            self.bottomContentsFade = true
        }
    }
    
    func disappearScrollBar() {
        scrollBarBool = false
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {_ in
            if self.scrollBarBool == false {
                self.bottomContentsFade = false
            } else {
                self.bottomContentsFade = true
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
    
    /**
     PresViewで追加されたPhotoをDetailViewのPhotoCountに反映
     */
    func updatePhotoCount(dataTransfer: DataTransfer) {
        for index in dataTransfer.annotationContainerArray.indices {
            photoCount[index] = dataTransfer.annotationContainerArray[index].reference.photoCount
            yourPhotoCount[index] = dataTransfer.annotationContainerArray[index].reference.yourPhotoCount
        }
    }
}
