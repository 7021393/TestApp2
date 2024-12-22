//
//  RegAR.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/13.
//

import SwiftUI
import RealityKit
import ARKit
import CoreLocation

class RegAR: NSObject, ARCoachingOverlayViewDelegate {
    let arView: ARView = ARView()
    
    private let animation = SpatialAnimation()
    let originalURLSession = OriginalURLSession()
    
    private var config = ARWorldTrackingConfiguration()
    
    // MARK: Make ARView
    func makeARView() -> ARView {
        // RealityKitの処理をできるだけ軽くするための努力
        arView.renderOptions = [
            .disableAREnvironmentLighting, // オブジェクトへの環境照明効果を無効化
            .disableCameraGrain, // オブジェクトへのノイズ効果を無効化
            .disableDepthOfField, // 被写体の深度によるぼかしを無効化
            .disableFaceMesh, // 顔検出を無効化
            .disableGroundingShadows, // 設置面への影を無効化
            .disableHDR, // HDRを無効化
            .disableMotionBlur, // オブジェクトへのモーションブラー効果を無効化
            .disablePersonOcclusion // 人物検出を無効化
        ]
        
        // HighResolutionFrameCapturingを可能な設定に変更（WWDC2022より）
//        hiResCapture(view: arView)
        
        arView.session.run(config)
        setupCoachingOverlay()
        
        return arView
    }
    
    private func setupCoachingOverlay() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.goal = .tracking
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = true
        coachingOverlay.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        arView.addSubview(coachingOverlay)
    }
    
//    private func hiResCapture(view: ARView) {
//        if let hiResCaptureVideoFormat = ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing {
//            // Assign the video format that supports hi-res capturing.
//            config.videoFormat = hiResCaptureVideoFormat
//            view.session.run(config)
//        }
//    }
    
    // MARK: Session Pause
    func sessionPause() {
        arView.session.pause()
    }
    
    var reg_reference: Reg_Reference?
    var reg_photoArray: [Reg_Photo] = []
    
    var calculationPhysicalWidth = 0.0
    
    private var savingTexture: TextureResource?
    
    private var randomInt = Int.random(in: 0...1)
    var willRemoveIndex: Int = 0
    
    var reg_process_reference: Reg_Process_Reference?
    var reg_process_photoArray: [Reg_Process_Photo] = []
    
    var tmp_reg_photoIndex: [Int] = []
    var tmp_sumImageDataSizeInAppDocumentsKB: Double = 0.0
    
    // PhotoDistanceExperiments
    var photoDistance: Float = 0.0
    var photoSize: Float = 0.0
    
    // PhotoDistanceExperiments Parameters
    func setPhotoDistanceAndSize(sliderVal_photoDistance: Float) {
        // スライダーの値を反映
        photoDistance = sliderVal_photoDistance // 写真のカメラからの距離[m]
        
        // 写真の距離に対してどの程度の写真サイズにするのかは調整してください。
        //　写真のカメラからの距離と同じ写真サイズになるように設定しています（距離が1mであれば写真サイズも1m）。
        photoSize = sliderVal_photoDistance// 写真サイズ[m]
    }
    
    // MARK: Crop Size
    func returnCropSize() -> (CGFloat, CGFloat)! {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        let screenWidth = windowScene.screen.bounds.width
        let screenHeight = windowScene.screen.bounds.height
        // ARFrame
        guard let arFrame = arView.session.currentFrame else { return nil }
        
        // cvPixelBuffer -> CIImage
        let ciImage = CIImage(cvPixelBuffer: arFrame.capturedImage)
        
        // カメラ画像と画面のサイズを取得（カメラ画像と画面の座標系は異なる）
        let imageLongSide = ciImage.extent.width
        let screenLongSide = max(screenWidth, screenHeight) // not use
        let screenShortSide = min(screenWidth, screenHeight) // not use
        let screenSizeImageShortSide = imageLongSide * screenShortSide / screenLongSide
        
        /*
         ARReferenceImageとして使用する画像には幾らかの制限がある。
         （従わない場合は、認識率の低下、および、システム側からの警告が出る場合がある）
         
         - 画像の縦横比は3：1より小さくする。
         - 画像のヒストグラムは広く、平らなものにする（輝度の差がある画像を使用する）。
         - 画像のコントラストは全体に高い局所コントラスト領域が分散しているものにする（カラフルな画像を使用する）。
         - 画像の解像度は幅と高さそれぞれが少なくとも480px以上であるようにする。
         
         2、3番目に関しては、ARKitの"detectImage.validate"機能にて多少の検査/制限が行われている。
         明示的には、本関数にて解像度のみ制限をかけている。
         */
        
        let minARReferenceImagePixel: CGFloat = 480.0
        
        let maxCropLongSideRatio: CGFloat = 1.0 - (minARReferenceImagePixel / imageLongSide)
        let maxCropShortSideRatio: CGFloat = 1.0 - (minARReferenceImagePixel / screenSizeImageShortSide)
        
        return (maxCropLongSideRatio, maxCropShortSideRatio)
    }
    
    // need refactoring
    // MARK: Capture Reference Image
    func captureReferenceImage(verticalRatio: CGFloat, horizontalRatio: CGFloat, completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return completion(true) }
        let screenWidth = windowScene.screen.bounds.width
        let screenHeight = windowScene.screen.bounds.height
        let interfaceOrientation = windowScene.windows.first!.windowScene?.interfaceOrientation
        
        // ARFrame
        guard let arFrame = arView.session.currentFrame else { return completion(true) }
        // Transform
        let viewportSize = CGSize(width: 0, height: 0)
        let transform = arFrame.displayTransform(for: interfaceOrientation!, viewportSize: viewportSize).inverted()
        
        // cvPixelBuffer -> CIImage
        let ciImage = CIImage(cvPixelBuffer: arFrame.capturedImage)
        
        // カメラ画像と画面のサイズを取得（カメラ画像と画面の座標系は異なる）
        let imageLongSide = ciImage.extent.width
        let imageShortSide = ciImage.extent.height
        let screenLongSide = max(screenWidth, screenHeight) // not use
        let screenShortSide = min(screenWidth, screenHeight) // not use
        let screenSizeImageShortSide = imageLongSide * screenShortSide / screenLongSide
        
        var cropStartPosition_x: CGFloat = 0.0
        var cropStartPosition_y: CGFloat = 0.0
        var cropSize_x: CGFloat = 0.0
        var cropSize_y: CGFloat = 0.0
        
        // 切り取り開始位置と切り取り範囲を算出
        switch interfaceOrientation?.rawValue {
        case 1:
            cropStartPosition_x = imageLongSide / 2 * verticalRatio
            cropStartPosition_y = (imageShortSide - screenSizeImageShortSide) / 2 + screenSizeImageShortSide / 2 * horizontalRatio
            cropSize_x = imageLongSide - imageLongSide * verticalRatio
            cropSize_y = screenSizeImageShortSide - screenSizeImageShortSide * horizontalRatio
            
            calculationPhysicalWidth = 0.3 * cropSize_y / screenSizeImageShortSide
        case 3, 4:
            cropStartPosition_x = imageLongSide / 2 * horizontalRatio
            cropStartPosition_y = (imageShortSide - screenSizeImageShortSide) / 2 + screenSizeImageShortSide / 2 * verticalRatio
            cropSize_x = imageLongSide - imageLongSide * horizontalRatio
            cropSize_y = screenSizeImageShortSide - screenSizeImageShortSide * verticalRatio
            
            calculationPhysicalWidth = 0.3 * cropSize_x / imageLongSide
        default:
            completion(true) // error
        }
        
        // CIImage (Cropped and Transformed)
        let cgRect = CGRect(x: cropStartPosition_x, y: cropStartPosition_y, width: cropSize_x, height: cropSize_y)
        let croppedAndTransformedCIImage = ciImage.cropped(to: cgRect).transformed(by: transform)
        // CIImage -> UIImage
        var uiImage = UIImage(ciImage: croppedAndTransformedCIImage) // なぜか真っ白な画像データ
        // UIImage -> JpegData
        let jpegData = uiImage.jpegData(compressionQuality: 0.5) // 圧縮率：高 0.0 ~ 1.0 低
        // JpegData -> UIImage
        uiImage = UIImage(data: jpegData!)! // 真っ白でなくなった画像データ
        // UIImage -> CGImage
        let cgImage = uiImage.cgImage
        
        // ARReferenceImageを作成
        let detectImage = ARReferenceImage(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: CGFloat(calculationPhysicalWidth))
        
        detectImage.validate { error in // ARReferenceImageのシステム側での検査
            if error != nil {
                completion(true) // error
                
            } else {
                DispatchQueue.main.async {
                    // Configuration Run
                    self.config.detectionImages = [detectImage]
                    self.arView.session.run(self.config)
                    
                    // Anchor/Entity Set
                    let anchor = AnchorEntity()
                    let plane = ModelEntity(mesh: .generatePlane(width: Float(self.calculationPhysicalWidth),
                                                                 depth: Float(self.calculationPhysicalWidth * uiImage.size.height / uiImage.size.width)))
                    let material = UnlitMaterial(color: .digitalBlue_uiColor!.withAlphaComponent(0.5))
                    plane.model?.materials = [material]
                    plane.components[EntityType.self] = EntityType(kind: .reference)
                    anchor.addChild(plane)
                    
                    var latitude: Double = 0.0
                    var longitude: Double = 0.0
                    var magneticHeading: Double = 0.0
                    
                    // 緯度経度、方位角取得
                    let manager = CLLocationManager()
                    let guarded = manager.authorizationStatus.rawValue
                    if guarded != 2 {
                        // 緯度経度
                        if let location = manager.location {
                            latitude = Double(location.coordinate.latitude)
                            longitude = Double(location.coordinate.longitude)
                        }
                        
                        // 方位角
                        manager.startUpdatingHeading()
                        while manager.heading == nil {} // 方位角の取得を待機
                        magneticHeading = Double(manager.heading!.magneticHeading)
                    }
                    
                    // 画像のデータサイズ取得
                    let dataSize = NSData(data: jpegData!).count
                    let dataSizeKB = Double(dataSize) / 1000.0
                    
                    let euler = OriginalEuler(x: 0.0, y: 0.0, z: 0.0)
                    
                    let uuid = UUID().uuidString
                    
                    // Date生成
                    // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
                    let dt = Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let registrationDate = dateFormatter.string(from: dt)
                    
                    let reference = Reg_Reference(uuid: uuid,
                                                  jpegData: jpegData!,
                                                  dataSizeKB: dataSizeKB,
                                                  latitude: latitude,
                                                  longitude: longitude,
                                                  magneticHeading: magneticHeading,
                                                  physicalWidth: self.calculationPhysicalWidth,
                                                  registrationDate: registrationDate,
                                                  anchor: anchor,
                                                  euler: euler,
                                                  saved: false)
                    
                    self.reg_reference = reference
                    
                    // referenceが更新されたときはphotoの保存状態をリセット
                    for index in self.reg_photoArray.indices {
                        self.reg_photoArray[index].saved = false
                    }
                    
                    completion(false)
                }
            }
        }
    }
    
    // MARK: Update Reference Anchor
    func updateReferenceAnchor(anchor: ARImageAnchor) {
        // ReferenceAnchorの位置を上書き
        reg_reference!.anchor.transform = Transform(matrix: anchor.transform)
        
        arView.scene.anchors.append(reg_reference!.anchor)
        
        // ReferenceAnchorの角度を取り出し、加工
        var acosEuler = acos(anchor.transform[0][0]) // .pi ~ 0 | 0 ~ .pi
        let asinEuler = asin(anchor.transform[0][2]) // -0 ~ -.pi/2 ~ -0 | 0 ~ .pi/2 ~ 0
        
        // left .pi ~ 0 | -0 ~ -.pi right
        if 0 < asinEuler {
            acosEuler = -acosEuler
        }
        
        // ReferenceAnchorの角度を上書き
        reg_reference!.euler.y = acosEuler
    }
    
    // MARK: Remove Reference Anchor
    func removeReferenceAnchor() {
        arView.scene.anchors.remove(reg_reference!.anchor)
    }
    
    // need refactoring
    // MARK: Take And Registration Photo
    func takeAndRegistrationPhoto() {
        // 写真生成
        guard let arFrame = arView.session.currentFrame else { return }
        let viewportSize = CGSize(width: 0, height: 0)
        
        //画像の縦向き・横向きを取得し、合わせる設定
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let interfaceOrientation = windowScene.windows.first!.windowScene?.interfaceOrientation
        
        let transform = arFrame.displayTransform(for: interfaceOrientation!, viewportSize: viewportSize).inverted()
        
        // cvPixelBuffer -> CIImage -> UIImage -> jpegData
        let ciImage = CIImage(cvPixelBuffer: arFrame.capturedImage).transformed(by: transform)
        var uiImage = UIImage(ciImage: ciImage)
        // Server保存用Jpegデータ
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.0) else { return }
        
        uiImage = UIImage(data: jpegData)!
        let cgImage = uiImage.cgImage
        
        do {
            let texture = try TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: nil, mipmapsMode: .none))
            
            var photoMaterial = UnlitMaterial()
            photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
            
            // PhotoDistanceExperiments
            let photoAnchor = AnchorEntity()
            //エンティティの作成
            let photoPlaneEntity = ModelEntity(mesh: .generatePlane(width: interfaceOrientation == .portrait ? 1.0 * photoSize : Float(uiImage.size.width / uiImage.size.height) * 1.0 * photoSize,
                                                                    depth: interfaceOrientation == .portrait ? Float(uiImage.size.height / uiImage.size.width) * 1.0 * photoSize : 1.0 * photoSize,
                                                                    cornerRadius: 0.0))
            photoPlaneEntity.name = "photoPlane"
            
            photoPlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            photoPlaneEntity.model?.materials = [photoMaterial]
            photoPlaneEntity.generateCollisionShapes(recursive: true)
            photoPlaneEntity.components[EntityType.self] = EntityType(kind: .photo)
            
            // PhotoDistanceExperiments
            //白い枠のエンティティの作成
            let whitePlaneEntity = ModelEntity(mesh: .generatePlane(width: interfaceOrientation == .portrait ? 1.05 * photoSize : Float(uiImage.size.width / uiImage.size.height) * 1.05 * photoSize,
                                                                    depth: interfaceOrientation == .portrait ? Float(uiImage.size.height / uiImage.size.width) * 1.05 * photoSize : 1.05 * photoSize,
                                                                    cornerRadius: 0.0))
            whitePlaneEntity.name = "whitePlane"
            
            let whiteMaterial = UnlitMaterial(color: .white)
            whitePlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            whitePlaneEntity.position = simd_make_float3(0.0, 0.0, -0.001)
            whitePlaneEntity.model?.materials = [whiteMaterial]
              
            
            // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
            let distanceToPhoto: Float = photoDistance // PhotoDistanceExperiments
            let cameraPosition_x = arFrame.camera.transform[3][0]
            let cameraPosition_y = arFrame.camera.transform[3][1]
            let cameraPosition_z = arFrame.camera.transform[3][2]
            let cameraEuler_x = arFrame.camera.eulerAngles.x // down -.pi/2 ~ -0 | 0 ~ .pi/2 up
            let cameraEuler_y = -arFrame.camera.eulerAngles.y // left -.pi ~ -0 | 0 ~ .pi right
            var cameraEuler_z = arFrame.camera.eulerAngles.z // tiltBottom .pi ~ 0 | -0 ~ -.pi tiltTop
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let interfaceOrientation = windowScene.windows.first!.windowScene?.interfaceOrientation
            
            // z軸の回転を矯正
            switch interfaceOrientation {
            case .portrait:
                cameraEuler_z += .pi/2
            case .landscapeLeft:
                cameraEuler_z += .pi
            default:
                break
            }
            
            // 写真の向き（TransformはPositionを上書きするので初めに処理）
            photoAnchor.transform = Transform(pitch: cameraEuler_x, yaw: -cameraEuler_y, roll: cameraEuler_z)
            
            // 写真の位置
            photoAnchor.position = simd_make_float3(cameraPosition_x + distanceToPhoto * cos(cameraEuler_x) * sin(cameraEuler_y),
                                                    cameraPosition_y + distanceToPhoto * sin(cameraEuler_x),
                                                    cameraPosition_z - distanceToPhoto * cos(cameraEuler_x) * cos(cameraEuler_y))
            
            photoAnchor.addChild(photoPlaneEntity)
            photoAnchor.addChild(whitePlaneEntity)
            arView.scene.anchors.append(photoAnchor)
            
            // 画像のデータサイズ取得
            let dataSize = NSData(data: jpegData).count
            let dataSizeKB = Double(dataSize) / 1000.0
            
            // Avatar生成
            let avatarAnchor = AnchorEntity()
            
            var sceneURL: URL? = nil
            switch randomInt {
            case 0:
                sceneURL = Bundle.main.url(forResource: "man", withExtension: "usdz", subdirectory: "art.scnassets")!
                randomInt += 1
            default:
                sceneURL = Bundle.main.url(forResource: "woman", withExtension: "usdz", subdirectory: "art.scnassets")!
                randomInt = 0
            }
            
            guard let avatarModel = try? Entity.loadModel(contentsOf: sceneURL!) else { return } // art.scnassets UI, Emission 230
            avatarModel.generateCollisionShapes(recursive: true)
            avatarModel.components[EntityType.self] = EntityType(kind: .avatar)
            avatarAnchor.addChild(avatarModel)
            
            // Avatarの位置は、カメラの位置から1.65m（日本人平均身長）下、0.3m後方（ユーザの位置）に配置
            let avatarDown: Float = -1.65
            let distanceToUser: Float = -0.3
            
            avatarAnchor.transform = Transform(pitch: 0, yaw: -cameraEuler_y, roll: 0)
            
            avatarAnchor.position = simd_make_float3(cameraPosition_x + distanceToUser * cos(cameraEuler_x) * sin(cameraEuler_y),
                                                     cameraPosition_y + distanceToUser * sin(cameraEuler_x) + avatarDown,
                                                     cameraPosition_z - distanceToUser * cos(cameraEuler_x) * cos(cameraEuler_y))
            
            avatarAnchor.scale = simd_make_float3(0.001, 0.001, 0.001)
            arView.scene.anchors.append(avatarAnchor)
            
            let uuid = UUID().uuidString
            
            // Date生成
            // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
            let dt = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let registrationDate = dateFormatter.string(from: dt)
            
            let avatar = Avatar(entity: avatarModel,
                                anchor: avatarAnchor,
                                euler: OriginalEuler(x: 0.0, y: -cameraEuler_y, z: 0.0))
            
            // PhotoDistanceExperiments
            let photo = Reg_Photo(uuid: uuid,
                                  jpegData: jpegData,
                                  dataSizeKB: dataSizeKB,
                                  imageAlbum: false,
                                  registrationDate: registrationDate,
                                  photoPlaneEntity: photoPlaneEntity,
                                  whitePlaneEntity: whitePlaneEntity,
                                  anchor: photoAnchor,
                                  euler: OriginalEuler(x: cameraEuler_x, y: -cameraEuler_y, z: cameraEuler_z),
                                  avatar: avatar,
                                  animationBool: AnimationBool(photo: true, avatar: false, interval: false),
                                  saved: false,
                                  photoDistance: photoDistance)
            
            reg_photoArray.append(photo)
        } catch {
            print("Error occurred: \(error.localizedDescription), RegAR.swift, takeAndRegistrationPhoto()")
        }
    }
    
    // need refactoring
    // MARK: Pre Processing Photo Manipulation
    func preProcessingPhotoManipulation(uiImage: UIImage, completion: @escaping () -> Void) {
        // Server保存用Jpegデータ
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.0) else { return }
        
        let cgImage = uiImage.cgImage
        
        do {
            let texture = try TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: nil, mipmapsMode: .none))
            savingTexture = texture
            
            var photoMaterial = UnlitMaterial(color: .white.withAlphaComponent(0.7))
            photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
            
            // PhotoDistanceExperiments
            let anchor = AnchorEntity()
            let photoPlaneEntity = ModelEntity(mesh: .generatePlane(width: 1.0 * photoSize,
                                                                    depth: Float(uiImage.size.height / uiImage.size.width) * 1.0 * photoSize,
                                                                    cornerRadius: 0.0))
            
            photoPlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            photoPlaneEntity.model?.materials = [photoMaterial]
            
            // PhotoDistanceExperiments
            let whitePlaneEntity = ModelEntity(mesh: .generatePlane(width: 1.05 * photoSize,
                                                                    depth: Float(uiImage.size.height / uiImage.size.width) * 1.05 * photoSize,
                                                                    cornerRadius: 0.0))
            
            let whiteMaterial = UnlitMaterial(color: .white.withAlphaComponent(0.3))
            whitePlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            whitePlaneEntity.position = simd_make_float3(0.0, 0.0, -0.001)
            whitePlaneEntity.model?.materials = [whiteMaterial]
            
            anchor.addChild(photoPlaneEntity)
            anchor.addChild(whitePlaneEntity)
            arView.scene.anchors.append(anchor)
            
            // 画像のデータサイズ取得
            let dataSize = NSData(data: jpegData).count
            let dataSizeKB = Double(dataSize) / 1000.0
            
            let uuid = UUID().uuidString
            
            // Date生成
            // 協定世界時（UTC）をDBに格納、表示はデバイスのタイムゾーンに変換後行う。
            let dt = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let registrationDate = dateFormatter.string(from: dt)
            
            let avatar = Avatar(entity: ModelEntity(),
                                anchor: AnchorEntity(),
                                euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0))
            
            // PhotoDistanceExperiments
            let photo = Reg_Photo(uuid: uuid,
                                  jpegData: jpegData,
                                  dataSizeKB: dataSizeKB,
                                  imageAlbum: true,
                                  registrationDate: registrationDate,
                                  photoPlaneEntity: photoPlaneEntity,
                                  whitePlaneEntity: whitePlaneEntity,
                                  anchor: anchor,
                                  euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0),
                                  avatar: avatar,
                                  animationBool: AnimationBool(photo: false, avatar: false, interval: true),
                                  saved: false,
                                  photoDistance: photoDistance)
            
            reg_photoArray.append(photo)
            
            completion()
        } catch {
            print("Error occurred: \(error.localizedDescription), RegAR.swift, preProcessingPhotoManipulation()")
        }
    }
    
    // MARK: Photo Manipulation
    func photoManipulation(frame: ARFrame) {
        // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
        let distanceToPhoto: Float = photoDistance // PhotoDistanceExperiments
        let cameraPosition_x = frame.camera.transform[3][0]
        let cameraPosition_y = frame.camera.transform[3][1]
        let cameraPosition_z = frame.camera.transform[3][2]
        let cameraEuler_x = frame.camera.eulerAngles.x // down -.pi/2 ~ -0 | 0 ~ .pi/2 up
        let cameraEuler_y = -frame.camera.eulerAngles.y // left -.pi ~ -0 | 0 ~ .pi right
        var cameraEuler_z = frame.camera.eulerAngles.z // tiltBottom .pi ~ 0 | -0 ~ -.pi tiltTop
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let interfaceOrientation = windowScene.windows.first!.windowScene?.interfaceOrientation
        
        // z軸の回転を矯正
        switch interfaceOrientation {
        case .portrait:
            cameraEuler_z += .pi/2
        case .landscapeLeft:
            cameraEuler_z += .pi
        default:
            break
        }
        
        // 写真の向き（TransformはPositionを上書きするので初めに処理）
        reg_photoArray.last!.anchor.transform = Transform(pitch: cameraEuler_x, yaw: -cameraEuler_y, roll: cameraEuler_z)
        
        // 写真の位置
        reg_photoArray.last!.anchor.position = simd_make_float3(cameraPosition_x + distanceToPhoto * cos(cameraEuler_x) * sin(cameraEuler_y),
                                                            cameraPosition_y + distanceToPhoto * sin(cameraEuler_x),
                                                            cameraPosition_z - distanceToPhoto * cos(cameraEuler_x) * cos(cameraEuler_y))
        
        reg_photoArray[reg_photoArray.count - 1].euler = OriginalEuler(x: cameraEuler_x, y: -cameraEuler_y, z: cameraEuler_z)
    }
    
    // need refactoring
    // MARK: Registration Selected Photo From Image Album
    func registrationSelectedPhotoFromImageAlbum(image: UIImage, completion: @escaping () -> Void) {
        // preProcessingPhotoManipulation()のEntityを削除
        reg_photoArray.last!.anchor.removeChild(reg_photoArray.last!.photoPlaneEntity)
        reg_photoArray.last!.anchor.removeChild(reg_photoArray.last!.whitePlaneEntity)
        // 不透明なEntityに差し替え
        var photoMaterial = UnlitMaterial()
        photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(savingTexture!)
        
        // PhotoDistanceExperiments
        let photoPlane = ModelEntity(mesh: .generatePlane(width: 1.0 * photoSize,
                                                          depth: Float(image.size.height / image.size.width) * 1.0 * photoSize,
                                                          cornerRadius: 0.0))
        
        photoPlane.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
        photoPlane.model?.materials = [photoMaterial]
        photoPlane.generateCollisionShapes(recursive: true)
        photoPlane.components[EntityType.self] = EntityType(kind: .photo)
        
        // PhotoDistanceExperiments
        let whitePlane = ModelEntity(mesh: .generatePlane(width: 1.05 * photoSize,
                                                          depth: Float(image.size.height / image.size.width) * 1.05 * photoSize,
                                                          cornerRadius: 0.0))
        
        let whiteMaterial = UnlitMaterial(color: .white)
        whitePlane.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
        whitePlane.position = simd_make_float3(0.0, 0.0, -0.001)
        whitePlane.model?.materials = [whiteMaterial]
        
        reg_photoArray.last!.anchor.addChild(photoPlane)
        reg_photoArray.last!.anchor.addChild(whitePlane)
        
        reg_photoArray[reg_photoArray.count - 1].photoPlaneEntity = photoPlane
        reg_photoArray[reg_photoArray.count - 1].whitePlaneEntity = whitePlane
        
        reg_photoArray[reg_photoArray.count - 1].animationBool = AnimationBool(photo: true, avatar: false, interval: false)
        
        // Avatar生成
        let avatarAnchor = AnchorEntity()
        
        var sceneURL: URL? = nil
        switch randomInt {
        case 0:
            sceneURL = Bundle.main.url(forResource: "man", withExtension: "usdz", subdirectory: "art.scnassets")!
            randomInt += 1
        default:
            sceneURL = Bundle.main.url(forResource: "woman", withExtension: "usdz", subdirectory: "art.scnassets")!
            randomInt = 0
        }
        
        guard let avatarModel = try? Entity.loadModel(contentsOf: sceneURL!) else { return } // art.scnassets UI, Emission 230
        avatarModel.generateCollisionShapes(recursive: true)
        avatarModel.components[EntityType.self] = EntityType(kind: .avatar)
        avatarAnchor.addChild(avatarModel)
        
        let arFrame = arView.session.currentFrame
        
        // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
        let cameraPosition_x = arFrame!.camera.transform[3][0]
        let cameraPosition_y = arFrame!.camera.transform[3][1]
        let cameraPosition_z = arFrame!.camera.transform[3][2]
        let cameraEuler_x = arFrame!.camera.eulerAngles.x
        let cameraEuler_y = -arFrame!.camera.eulerAngles.y
        
        // Avatarの位置は、カメラの位置から1.65m（日本人平均身長）下、0.3m後方（ユーザの位置）に配置
        let avatarDown: Float = -1.65
        let distanceToUser: Float = -0.3
        
        avatarAnchor.transform = Transform(pitch: 0, yaw: -cameraEuler_y, roll: 0)
        
        avatarAnchor.position = simd_make_float3(cameraPosition_x + distanceToUser * cos(cameraEuler_x) * sin(cameraEuler_y),
                                                 cameraPosition_y + distanceToUser * sin(cameraEuler_x) + avatarDown,
                                                 cameraPosition_z - distanceToUser * cos(cameraEuler_x) * cos(cameraEuler_y))
        
        avatarAnchor.scale = simd_make_float3(0.001, 0.001, 0.001)
        
        arView.scene.anchors.append(avatarAnchor)
        
        let avatar = Avatar(entity: avatarModel,
                               anchor: avatarAnchor,
                               euler: OriginalEuler(x: 0.0, y: reg_photoArray.last!.euler.y, z: 0.0))
        
        reg_photoArray[reg_photoArray.count - 1].avatar = avatar
        
        completion()
    }
    
    // MARK: Position Change Avatar
    func positionChangeAvatar(index: Int, diff: Float) {
        reg_photoArray[index].avatar.anchor.position.y -= diff * 0.001
    }
    
    // MARK: Remove Photo
    func removePhoto() {
        arView.scene.anchors.remove(reg_photoArray[willRemoveIndex].anchor)
        arView.scene.anchors.remove(reg_photoArray[willRemoveIndex].avatar.anchor)
        
        reg_photoArray.remove(at: willRemoveIndex)
    }
    
    private let time = 0.5
    private let expansion = simd_make_float3(1000, 1000, 1000)
    private let shrinkage = simd_make_float3(0.001, 0.001, 0.001)
    
    // MARK: Animation
    func animationProcess(frame: ARFrame) {
        for (index, ar_photo) in reg_photoArray.enumerated() {
            if ar_photo.animationBool.interval == false {
                // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
                let cameraPosition = OriginalPosition(x: frame.camera.transform[3][0], y: frame.camera.transform[3][1], z: frame.camera.transform[3][2])
                let cameraEuler = OriginalEuler(x: frame.camera.eulerAngles.x, y: -frame.camera.eulerAngles.y, z: frame.camera.eulerAngles.z) // left -.pi ~ -0 | 0 ~ .pi right
                let camera = OriginalPositionAndEuler(position: cameraPosition, euler: cameraEuler)
                
                let photoAnchor = ar_photo.anchor
                let photoPosition = OriginalPosition(x: photoAnchor.position.x, y: photoAnchor.position.y, z: photoAnchor.position.z)
                
                let avatarAnchor = ar_photo.avatar.anchor
                let avatarPosition = OriginalPosition(x: avatarAnchor.position.x, y: avatarAnchor.position.y, z: avatarAnchor.position.z)
                
                // PhotoDistanceExperiments
                if let animationInstruction = animation.expansionAndShrinkage(camera: camera, photoPosition: photoPosition, avatarPosition: avatarPosition, animationBool: ar_photo.animationBool, photoDistance: ar_photo.photoDistance) {
                    
                    switch animationInstruction.0.kind {
                    case .photo:
                        scaleAnimation(anchor: photoAnchor, animationType: expansion)
                        reg_photoArray[index].animationBool.photo = true
                    case .avatar:
                        if animationInstruction.1 {
                            scaleAnimation(anchor: avatarAnchor, animationType: expansion)
                            reg_photoArray[index].animationBool.avatar = true
                        } else {
                            scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            reg_photoArray[index].animationBool.avatar = false
                        }
                    case .photoAndAvatar:
                        if animationInstruction.1 {
                            scaleAnimation(anchor: photoAnchor, animationType: expansion)
                            scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            reg_photoArray[index].animationBool.photo = true
                            reg_photoArray[index].animationBool.avatar = false
                        } else {
                            scaleAnimation(anchor: photoAnchor, animationType: shrinkage)
                            scaleAnimation(anchor: avatarAnchor, animationType: expansion)
                            reg_photoArray[index].animationBool.photo = false
                            reg_photoArray[index].animationBool.avatar = true
                        }
                    }
                    
                    reg_photoArray[index].animationBool.interval = true
                    Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                        self.reg_photoArray[index].animationBool.interval = false
                    }
                }
            }
        }
    }
    
    private func scaleAnimation(anchor: AnchorEntity, animationType: simd_float3) {
        anchor.move(to: Transform(scale: animationType),
                    relativeTo: anchor,
                    duration: time)
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
}
