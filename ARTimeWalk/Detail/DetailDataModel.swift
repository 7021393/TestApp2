//
//  DetailDataModel.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/22.
//

import SwiftUI
import MapKit

final class DetailDataModel: ObservableObject {
    let detailMap = DetailMap()
    let originalURLSession = OriginalURLSession()
    
    var selectedDataSource: DataSource = .local
    var multiple: Bool = false
    var annotationIndex: Int = 0
    
    @Published var PresViewModal: Bool = false
    
    @Published var isAlert_publishReference: Bool = false
    @Published var isAlert_publishAllData: Bool = false
    @Published var isAlert_deletePhoto: Bool = false
    @Published var isAlert_deleteReference: Bool = false
    @Published var isAlert_changePhotoDate: Bool = false
    
    @Published var isAlert_invalidDateFormat: Bool = false
    @Published var isAlert_serverError: Bool = false
    
    @Published var isAlert_publishIsNotAvailable: Bool = false
    
    @Published var photoCount: Int = 0
    @Published var yourPhotoCount: Int = 0
    @Published var referenceCount: Int = 0
    @Published var yourReferenceCount: Int = 0
    
    @Published var photoDetailIndex: Int = 0
    @Published var referenceDetailIndex: Int = 0
    @Published var appearDetail_photo: Bool = false
    @Published var appearDetail_reference: Bool = false
    
    var publish_referenceID: Int?
    var publish_referenceJpegDataFileName: String?
    var publish_photoJpegDataFileNameArray: [String] = []
    
    @Published var duringPostData: Bool = false
    
    @Published var isPresentedBanner_copy_photo: Bool = false
    @Published var isPresentedBanner_copy_reference: Bool = false
    
    @Published var inputPhotoDate: String = ""
    
    @Published var photoArray_deleteReference: [LinkContainer_Photo] = []
    @Published var isCustomAlert_deleteReference: Bool = false
    
    /**
     MapViewからDetailViewへ遷移したときに行う一連の処理
     */
    func detailView_init_process(multiple: Bool, selectedDataSource: DataSource, dataTransfer: DataTransfer, annotationIndex: Int) {
        self.selectedDataSource = selectedDataSource
        self.multiple = multiple
        self.annotationIndex = annotationIndex
        
        resetDataTransfer(dataTransfer: dataTransfer)
        setReferenceData(dataTransfer: dataTransfer)
        setPhotoData(dataTransfer: dataTransfer)
    }
    
    /**
     データ受け渡し用変数の初期化
     */
    func resetDataTransfer(dataTransfer: DataTransfer) {
        dataTransfer.referenceContainerArray.removeAll()
        dataTransfer.linkContainerArray_photo.removeAll()
    }
    
    /**
     MapViewのAnnotationに格納されているReferenceデータ（各種変数、画像）を、
     データ受け渡し用変数（DetailViewとPresViewで使用）に格納
     */
    func setReferenceData(dataTransfer: DataTransfer) {
        // [Multiple]
        if multiple {
            for annotation in dataTransfer.annotationContainerArray {
                let reference = annotation.reference
                dataTransfer.referenceContainerArray.append(reference)
                setReferenceCount(dataTransfer: dataTransfer, reference: reference)
            }
        } else {
            let reference = dataTransfer.annotationContainerArray[annotationIndex].reference
            dataTransfer.referenceContainerArray.append(reference)
            setReferenceCount(dataTransfer: dataTransfer, reference: reference)
        }
    }
    
    /**
     DetailViewに表示するReferenceCount、YourReferenceCountに値を格納
     */
    func setReferenceCount(dataTransfer: DataTransfer, reference: ReferenceContainer) {
        referenceCount += 1
        if reference.userID == ARTimeWalkApp.isUserID || reference.userID == 0 {
            yourReferenceCount += 1
        }
    }
    
    /**
     MapViewより選択されたReference（ひとつまたは複数）に紐付けられているPhoto（Networkで接続されたものも含む）を取得し格納
     */
    func setPhotoData(dataTransfer: DataTransfer) {
        switch selectedDataSource {
        case .local:
            getPhotoDataFromApp(dataTransfer: dataTransfer, annotationIndex: annotationIndex)
        case .global:
            Task {
                var id_array: [Int] = []
                // [Multiple]
                if multiple {
                    var connectedReferenceArray: [[Int]] = []
                    for annotation in dataTransfer.annotationContainerArray {
                        connectedReferenceArray.append(annotation.connectedReference)
                    }
                    // すべての配列を一つの配列にまとめる
                    let flattenedArray = connectedReferenceArray.flatMap { $0 }
                    // 重複を除去して一つの配列にする
                    id_array = Array(Set(flattenedArray))
                } else {
                    id_array = dataTransfer.annotationContainerArray[annotationIndex].connectedReference
                }
                
                await getPhotoDataFromServerDB(dataTransfer: dataTransfer, id_array: id_array)
                if dataTransfer.linkContainerArray_photo.isEmpty == false {
                    await getPhotoJpegDataFromServerDirectory(dataTransfer: dataTransfer)
                }
            }
        }
    }
    
    /**
     Photoの詳細データを表示
     */
    func pushedPhotoDetailButton(dataTransfer: DataTransfer, index: Int) {
        if dataTransfer.linkContainerArray_photo[index].detailButton == false {
            dataTransfer.linkContainerArray_photo[photoDetailIndex].detailButton = false
            dataTransfer.linkContainerArray_photo[index].detailButton = true
            photoDetailIndex = index
            appearDetail_photo = true
        } else {
            dataTransfer.linkContainerArray_photo[index].detailButton = false
            appearDetail_photo = false
        }
    }
    
    /**
     Referenceの詳細データを表示
     */
    func pushedReferenceDetailButton(dataTransfer: DataTransfer, index: Int) {
        if dataTransfer.referenceContainerArray[index].detailButton == false {
            dataTransfer.referenceContainerArray[referenceDetailIndex].detailButton = false
            dataTransfer.referenceContainerArray[index].detailButton = true
            referenceDetailIndex = index
            appearDetail_reference = true
            
            detailMap.removeAllAnnotations()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {_ in // DetailMapCoordinatorが機能するまで待機
                self.detailMap.setMap(reference: dataTransfer.referenceContainerArray[index])
            }
            
        } else {
            dataTransfer.referenceContainerArray[index].detailButton = false
            appearDetail_reference = false
        }
    }
    
    /**
     Local（アプリ内DB）に保存されているデータを外部Serverに送信、データを公開
     */
    func publishDataInApp(mapView: MKMapView, dataTransfer: DataTransfer) async {
        let annotation = dataTransfer.annotationContainerArray[annotationIndex]
        
        self.duringPostData = true
        
        await publishReferenceJpegData(annotation: annotation)
        await publishPhotoJpegData(dataTransfer: dataTransfer)
        await publishReferenceData(annotation: annotation)
        await publishPhotoData(dataTransfer: dataTransfer)
        
        deleteReferenceInApp(id: annotation.reference.id)
        for photo in dataTransfer.linkContainerArray_photo {
            deletePhotoInApp(id: photo.id)
        }
        
        DispatchQueue.main.async {
            dataTransfer.sumImageDataSizeInAppDocumentsMB -= annotation.reference.dataSizeKB / 1000.0
            for LinkContainer_Photo in dataTransfer.linkContainerArray_photo {
                dataTransfer.sumImageDataSizeInAppDocumentsMB -= LinkContainer_Photo.dataSizeKB / 1000.0
            }
            if dataTransfer.sumImageDataSizeInAppDocumentsMB <= 0.0 {
                dataTransfer.sumImageDataSizeInAppDocumentsMB = 0.0
            }
        }
        
        removeAnnotationInMapView(mapView: mapView, dataTransfer: dataTransfer, index: annotationIndex)
        duringPostData = false
    }
    
    /**
     Photoの削除
     */
    func deletePhoto(dataTransfer: DataTransfer) {
        appearDetail_photo = false
        let photoID = dataTransfer.linkContainerArray_photo[photoDetailIndex].id
        
        switch selectedDataSource {
        case .local:
            // アプリ内DBのPhotoデータを削除
            deletePhotoInApp(id: photoID)
            
            // データ容量を再計算（Localのみ）
            dataTransfer.sumImageDataSizeInAppDocumentsMB -= dataTransfer.linkContainerArray_photo[photoDetailIndex].dataSizeKB / 1000.0
            if dataTransfer.sumImageDataSizeInAppDocumentsMB <= 0.0 {
                dataTransfer.sumImageDataSizeInAppDocumentsMB = 0.0
            }
            
        case .global:
            Task {
                // 外部ServerDBのPhotoデータを削除
                await deletePhotoInServer(id: photoID)
            }
        }
        
        decreasePhotoCount(dataTransfer: dataTransfer, id: photoID)
        photoDetailIndex = 0
    }
    
    // test
    /**
     PhotoCount、YourPhotoCountの変更（+α 配列remove）
     コード量削減のため、Localおよび非Multipleに対しても、Multipleで行われる削除処理を適用している。
     
     ※ Multiple：複数のReference同時認識機能（Globalのみ）
     */
    private func decreasePhotoCount(dataTransfer: DataTransfer, id: Int) {
        DispatchQueue.main.async {
            // 配列の操作ではUIの更新が行われないため、"配列の操作 -> CountによるUIの更新"の順で処理を行う。
            if let photoIndex = dataTransfer.linkContainerArray_photo.firstIndex(where: { $0.id == id }) {
                // データ退避
                let photo = dataTransfer.linkContainerArray_photo[photoIndex]
                // データ受け渡し用配列からPhotoデータを削除、DetailViewの画像を消す
                dataTransfer.linkContainerArray_photo.remove(at: photoIndex)
                
                /*
                 DetailViewのCount表示を変更
                 */
                
                // 自分が設置したPhotoであるかを判断
                var myPhoto: Bool = false
                if photo.userID == ARTimeWalkApp.isUserID || photo.userID == 0 {
                    myPhoto = true
                }
                
                // PhotoCountを変更（DetailView）
                self.photoCount -= 1
                if myPhoto {
                    // YourPhotoCountを変更（DetailView）
                    self.yourPhotoCount -= 1
                }
                
                /*
                 MapViewのCount表示を変更（dataTransfer.annotationContainerArrayを変更）
                 */
                
                // 削除するPhotoが紐付けられているReferenceを検索
                if let mainAnnotation = dataTransfer.annotationContainerArray.first(where: { $0.reference.id == photo.referenceID }) {
                    // 検索されたReferenceとNetworkによって紐付けられている他のReference全てに対してCount変更処理
                    for referenceID in mainAnnotation.connectedReference {
                        if let annotationIndex = dataTransfer.annotationContainerArray.firstIndex(where: { $0.reference.id == referenceID }) {
                            // PhotoCountを変更（MapView）
                            dataTransfer.annotationContainerArray[annotationIndex].reference.photoCount -= 1
                            if myPhoto {
                                // YourPhotoCountを変更（MapView）
                                dataTransfer.annotationContainerArray[annotationIndex].reference.yourPhotoCount -= 1
                            }
                        }
                    }
                }
                dataTransfer.photoCountBool.toggle()
            }
        }
    }
    
    /**
     削除対象のReferenceに紐付けられている他のReferenceがServer上にデータとして残されているかを確認
     
     - Referenceを削除する際に共に削除されるPhotoをアラートに描画する。
     - Reference同士のNetworkによって、Referenceを削除してもPhotoを鑑賞できる場合がある。
     */
    func checkReferenceExisted(dataTransfer: DataTransfer) {
        photoArray_deleteReference.removeAll()
        
        let reference = dataTransfer.referenceContainerArray[referenceDetailIndex]
        
        if let index = dataTransfer.annotationContainerArray.firstIndex(where: { $0.reference.id == reference.id }) {
            var referenceIDArray = dataTransfer.annotationContainerArray[index].connectedReference
            let tmp_referenceIDArray = referenceIDArray
            
            switch selectedDataSource {
            case .local:
                /*
                 削除対象のReferenceに紐付けられているPhotoを描画用配列に格納
                 */
                setPhotoArray_deleteReference(dataTransfer: dataTransfer, id_array: referenceIDArray)
            case .global:
                /*
                 削除対象のReferenceに他のReferenceが紐付けられていない、または、紐付けられているがReference自体は全て削除されている場合、
                 紐付けられているPhotoを描画用配列に格納
                 
                 - 削除対象のReferenceに他のReferenceが紐付けられている限りPhotoは削除されず、他のReferenceを介して鑑賞が可能です。
                 - 削除対象のReferenceに他のReferenceが紐付けられておらず、Photoを鑑賞するためのReferenceが削除対象としているReferenceのみである場合は、
                 Referenceと共に、紐付けられている全てのPhotoが削除されます。
                 
                 ※ OriginalAnnotation.connectedReferenceは、ServerDBのNetwork、NetworkLogテーブルを参照して作成しているため、
                 削除されているReferenceのIDも含まれている。
                 */
                // 紐付けられている他のReferenceのID
                referenceIDArray.removeFirst()
                // 上書きされたdataTransfer.annotationContainerArrayを修正
                dataTransfer.annotationContainerArray[index].connectedReference = tmp_referenceIDArray
                
                if referenceIDArray.isEmpty {
                    // 他のReferenceが紐付けられていない
                    setPhotoArray_deleteReference(dataTransfer: dataTransfer, id_array: tmp_referenceIDArray)
                } else {
                    let id_array = referenceIDArray
                    Task {
                        let result = await checkReferenceExistedFromServerDB(dataTransfer: dataTransfer, id_array: id_array)
                        if result == false {
                            // 紐付けられているがReference自体は全て削除されている
                            setPhotoArray_deleteReference(dataTransfer: dataTransfer, id_array: tmp_referenceIDArray)
                        }
                    }
                }
            }
        }
    }
    
    // アラートに描画するPhotoを配列に格納
    func setPhotoArray_deleteReference(dataTransfer: DataTransfer, id_array: [Int]) {
        let photoArrayWithIndexes = dataTransfer.linkContainerArray_photo.enumerated().filter { id_array.contains($0.element.referenceID) }
        let photoArray = photoArrayWithIndexes.map { $0.element }
        
        DispatchQueue.main.async {
            self.photoArray_deleteReference = photoArray
        }
    }
    
    // test
    /**
     Referenceの削除
     */
    func deleteReference(mapView: MKMapView, dataTransfer: DataTransfer) {
        appearDetail_reference = false
        
        switch selectedDataSource {
        case .local:
            let annotation = dataTransfer.annotationContainerArray[annotationIndex]
            
            deleteReferenceInApp(id: annotation.reference.id)
            for photo in dataTransfer.linkContainerArray_photo {
                deletePhotoInApp(id: photo.id)
            }
            
            dataTransfer.sumImageDataSizeInAppDocumentsMB -= annotation.reference.dataSizeKB / 1000.0
            for LinkContainer_Photo in dataTransfer.linkContainerArray_photo {
                dataTransfer.sumImageDataSizeInAppDocumentsMB -= LinkContainer_Photo.dataSizeKB / 1000.0
            }
            if dataTransfer.sumImageDataSizeInAppDocumentsMB <= 0.0 {
                dataTransfer.sumImageDataSizeInAppDocumentsMB = 0.0
            }
            
            removeAnnotationInMapView(mapView: mapView, dataTransfer: dataTransfer, index: annotationIndex)
            
        case .global:
            let reference = dataTransfer.referenceContainerArray[referenceDetailIndex]
            
            Task {
                await deleteReferenceInServer(id: reference.id)
                for photo in photoArray_deleteReference {
                    await deletePhotoInServer(id: photo.id)
                }
            }
            
            if let index = dataTransfer.annotationContainerArray.firstIndex(where: { $0.reference.id == reference.id }) {
                removeAnnotationInMapView(mapView: mapView, dataTransfer: dataTransfer, index: index)
                
                if photoArray_deleteReference.isEmpty == false {
                    let id_array = dataTransfer.annotationContainerArray[annotationIndex].connectedReference
                    if 1 < id_array.count {
                        Task {
                            await deleteReferenceLinkInServer(id_array: id_array)
                        }
                    }
                }
            }
        }
    }
    
    // MapViewからPinを削除
    func removeAnnotationInMapView(mapView: MKMapView, dataTransfer: DataTransfer, index: Int) {
        DispatchQueue.main.async {
            mapView.removeAnnotation(dataTransfer.annotationContainerArray[index])
        }
    }
    
    /**
     Photoの日付を変更（自分が設置したPhotoのみ）
     */
    func changePhotoDate(dataTransfer: DataTransfer) {
        // 入力を変換
        inputPhotoDate = dateConversion_toUTC(localDateString: inputPhotoDate)
        
        // 入力を検査
        if validateInput_ChangePhotoDate(inputPhotoDate) == false {
            inputPhotoDate = ""
            
            isAlert_invalidDateFormat.toggle()
            
        } else {
            duringPostData = true
            
            switch selectedDataSource {
            case .local:
                changePhotoDateInApp(dataTransfer: dataTransfer)
                duringPostData = false
                
                dataTransfer.linkContainerArray_photo[photoDetailIndex].registrationDate = inputPhotoDate
                inputPhotoDate = ""
                
            case .global:
                Task {
                    if (await changePhotoDateInServer(dataTransfer: dataTransfer)) != nil {
                        duringPostData = false
                        
                        dataTransfer.linkContainerArray_photo[photoDetailIndex].registrationDate = inputPhotoDate
                        inputPhotoDate = ""
                    } else {
                        duringPostData = false
                        inputPhotoDate = ""
                        
                        isAlert_serverError.toggle()
                    }
                }
            }
        }
    }
    
    // 入力された日付をUTC（協定世界時）に変換
    func dateConversion_toUTC(localDateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.autoupdatingCurrent
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent

        // 入力された日付文字列の形式を確認
        let components = localDateString.components(separatedBy: " ")
        let dateComponents = components[0].components(separatedBy: "-")
        let timeComponents = components.count > 1 ? components[1].components(separatedBy: ":") : []
        
        var formatString: String = ""
        if dateComponents.count == 1 { // 年のみ
            formatString = "yyyy"
        } else if dateComponents.count == 2 { // 年月
            formatString = "yyyy-MM"
        } else if dateComponents.count == 3 && timeComponents.count == 0 { // 年月日
            formatString = "yyyy-MM-dd"
        } else if dateComponents.count == 3 && timeComponents.count == 2 { // 年月日時分
            formatString = "yyyy-MM-dd HH:mm"
        } else { // それ以外の場合はエラー
            return "Error"
        }
        
        dateFormatter.dateFormat = formatString
        
        // 入力された日付文字列をDateオブジェクトに変換（UTCに変換される）
        if var localDate = dateFormatter.date(from: localDateString) {
            // 年月日時分以外の場合はローカル時間を使用する（タイムゾーンの差をUTCに加算）
            if formatString != "yyyy-MM-dd HH:mm" {
                localDate = localDate.addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT(for: localDate)))
            }
            
            // UTCに変換
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = formatString
            let utcDate = dateFormatter.string(from: localDate)
            
            // 未来の日付であるか確認
            let currentDate = dateFormatter.string(from: Date())
            if currentDate < utcDate {
                return "Error"
            } else {
                return utcDate
            }
        } else {
            return "Error"
        }
    }
    
    // test
    func validateInput_ChangePhotoDate(_ input: String) -> Bool {
        // 不正な日付（0000-00-00 00:00など）や未来の日時を弾く
        if input == "Error" {
            return false
        } else {
            return true
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
        // 写真の数を取得
        let photoCountInDataTransfer = dataTransfer.linkContainerArray_photo.count
        // 増えた写真の数を計算
        let newPhotoCount = photoCountInDataTransfer - photoCount
        // 写真が追加されていれば、PhotoCountとYourPhotoCountを増やす
        if newPhotoCount > 0 {
            photoCount += newPhotoCount
            yourPhotoCount += newPhotoCount
        }
    }
}
