//
//  PresAR.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/07/22.
//

import ARKit
import RealityKit

class PresAR: NSObject, ARCoachingOverlayViewDelegate {
    let arView: ARView = ARView()
    
    let originalURLSession = OriginalURLSession()
    let animation = SpatialAnimation()
    
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
    
    // MARK: Session Pause
    func sessionPause() {
        arView.session.pause()
    }
    
    var ar_reference: Pres_Reference?
    var ar_photoArray: [Pres_Photo] = []
    
    var tmp_reference: Pres_Reference?
    
    var ar_referenceArray: [referencePositionAndEulerContainer] = [] // ?
    
    var randomInt = Int.random(in: 0...1)
    
    // Add Photo
    var reg_photoArray: [Reg_Photo] = []
    
    var savingTexture: TextureResource?
    
    var willRemoveIndex: Int = 0
    
    var reg_process_photoArray: [Reg_Process_Photo] = []
    
    var tmp_reg_photoIndex: [Int] = []
    var tmp_sumImageDataSizeInAppDocumentsKB: Double = 0.0
    
    // PhotoDistanceExperiments
    var photoSize: Float = 0.0
    
    // PhotoDistanceExperiments Parameters
    func setPhotoSize(photoDistance: Float) {
        // 写真の距離に対してどの程度の写真サイズにするのかは調整してください。
        //　写真のカメラからの距離と同じ写真サイズになるように設定しています（距離が1mであれば写真サイズも1m）。
        photoSize = photoDistance // 写真サイズ[m]
    }
    
    // MARK: Set Image For Reference Detection
    func setImageForReferenceDetection(reference: ReferenceContainer) {
        guard let uiImage = UIImage(data: reference.jpegData!) else { return }
        guard let cgImage = uiImage.cgImage else { return }
        
        // ARReferenceImageを作成
        let detectImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: CGFloat(reference.physicalWidth))
        // Configuration Run
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = [detectImage]
        arView.session.run(configuration)
        
        // Anchor/Entity Set
        let anchor = AnchorEntity()
        let plane = ModelEntity(mesh: .generatePlane(width: Float(reference.physicalWidth), depth: Float(reference.physicalWidth * uiImage.size.height / uiImage.size.width)))
        let material = UnlitMaterial(color: .digitalBlue_uiColor!.withAlphaComponent(0.5))
        plane.model?.materials = [material]
        anchor.addChild(plane)
        
        ar_reference = Pres_Reference(id: reference.id,
                                         anchor: anchor,
                                         euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0))
    }
    
    // MARK: Update Reference Anchor
    func updateReferenceAnchor(imageAnchor: ARImageAnchor) {
        // ReferenceAnchorの位置を上書き
        ar_reference!.anchor.transform = Transform(matrix: imageAnchor.transform)
        arView.scene.anchors.append(ar_reference!.anchor)
        
        // ReferenceAnchorの角度を取り出し、加工
        var acosEuler = acos(imageAnchor.transform[0][0]) // .pi ~ 0 | 0 ~ .pi
        let asinEuler = asin(imageAnchor.transform[0][2]) // -0 ~ -.pi/2 ~ -0 | 0 ~ .pi/2 ~ 0
        
        // left .pi ~ 0 | -0 ~ -.pi right
        if 0 < asinEuler {
            acosEuler = -acosEuler
        }
        
        // ReferenceAnchorの角度を上書き
        ar_reference!.euler.y = acosEuler
    }
    
    // MARK: Remove Reference Anchor
    func removeReferenceAnchorFromARView() {
        // Reference認識時の青いプレートを取り除く
        arView.scene.anchors.remove(ar_reference!.anchor)
    }
    
    // MARK: Backup Reference Anchor
    func tmp_ReferenceAnchor() {
        tmp_reference = Pres_Reference(id: ar_reference!.id,
                                             anchor: ar_reference!.anchor,
                                             euler: ar_reference!.euler)
    }
    
    // test
    // MARK: Remove Photo
    func removePhoto(referenceIDArray: [Int]) -> [Pres_Photo] {
        // 削除する要素を一時的な配列に追加する
        var photosToRemove: [Pres_Photo] = []
        
        for ar_photo in ar_photoArray {
            if referenceIDArray.contains(ar_photo.referenceID) {
                arView.scene.anchors.remove(ar_photo.anchor)
                arView.scene.anchors.remove(ar_photo.avatar.anchor)
                photosToRemove.append(ar_photo)
            }
        }
        
        // photosToRemoveに格納された要素をar_photoArrayから削除する
        ar_photoArray.removeAll { ar_photo in
            return photosToRemove.contains { $0.id == ar_photo.id }
        }
        
        return photosToRemove
    }
    
    // MARK: Return Reference Position And Euler
    /**
     現在認識中のReference（ar_reference）の位置と向きを返す。
     */
    func returnReferencePositionAndEuler() -> OriginalPositionAndEuler? {
        guard let anchor = ar_reference?.anchor else { return nil }
        guard let euler = ar_reference?.euler else { return nil }
        
        let referencePosition = OriginalPosition(x: anchor.position.x, y: anchor.position.y, z: anchor.position.z)
        let referencePositionAndEuler = OriginalPositionAndEuler(position: referencePosition, euler: euler)
        
        return referencePositionAndEuler
    }
    
    // MARK: Return Next Reference Position And Euler
    /**
     あるReferenceからLinkで繋がっている次のReferenceの位置と向きを返す。
     */
    func returnNextReferencePositionAndEuler(reference: OriginalPositionAndEuler, relativePositionAndOrientation: OriginalPositionAndEuler) -> OriginalPositionAndEuler {
        let calculation = SpatialCalculation()
        
        let referencePositionAndEuler = calculation.calculateTargetFromRelativePositionAndOrientation(reference: reference, relativePositionAndOrientation: relativePositionAndOrientation)
        
        return referencePositionAndEuler
    }
    
    // MARK: Calculation Reference Link
    /**
     現在認識中のReference（ar_reference）と前回認識したReference（tmp_reference）のデータを使用し、
     Reference間の相対位置と向きを算出
     */
    func calculationReferenceLink() -> (OriginalPositionAndEuler, OriginalPositionAndEuler) {
        let calculation = SpatialCalculation()
        
        let referencePosition = OriginalPosition(x: ar_reference!.anchor.position.x, y: ar_reference!.anchor.position.y, z: ar_reference!.anchor.position.z)
        let referencePositionAndEuler = OriginalPositionAndEuler(position: referencePosition, euler: ar_reference!.euler)
        
        let tmp_referencePosition = OriginalPosition(x: tmp_reference!.anchor.position.x, y: tmp_reference!.anchor.position.y, z: tmp_reference!.anchor.position.z)
        let tmp_referencePositionAndEuler = OriginalPositionAndEuler(position: tmp_referencePosition, euler: tmp_reference!.euler)
        
        
        let calculatedReference0 = calculation.calculateRelativePositionAndOrientation(reference: tmp_referencePositionAndEuler, target: referencePositionAndEuler)
        let calculatedReference1 = calculation.calculateRelativePositionAndOrientation(reference: referencePositionAndEuler, target: tmp_referencePositionAndEuler)
        
        return (calculatedReference0, calculatedReference1)
    }
    
    // need refactoring
    // MARK: Presentation Photo
    func presentationPhoto(referencePositionAndEuler: OriginalPositionAndEuler, LinkContainer_Photo: LinkContainer_Photo) {
        
        // PhotoDistanceExperiments
        setPhotoSize(photoDistance: LinkContainer_Photo.photoDistance)
        
        //dataModel内のselectedPhotoDistanceにphotoDistanceを保存し、後でUIに表示できるようにした
        //dataModel?.selectedPhotoDistance = LinkContainer_Photo.photoDistance
        
        let calculation = SpatialCalculation()
        
        let uiImage = UIImage(data: LinkContainer_Photo.jpegData!)!
        let cgImage = uiImage.cgImage
        
        let photoAnchor = AnchorEntity()
        var photoPlaneModel = ModelEntity()
        var whitePlaneModel = ModelEntity()
        
        do {
            let texture = try TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: nil, mipmapsMode: .none))
            var photoMaterial = UnlitMaterial()
            photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
            
            // PhotoDistanceExperiments
            photoPlaneModel = ModelEntity(mesh: .generatePlane(width: 1.0 * photoSize,
                                                              depth: Float(uiImage.size.height / uiImage.size.width) * 1.0 * photoSize,
                                                              cornerRadius: 0.0))
            
            photoPlaneModel.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            photoPlaneModel.model?.materials = [photoMaterial]
            
            // PhotoDistanceExperiments
            whitePlaneModel = ModelEntity(mesh: .generatePlane(width: 1.05 * photoSize,
                                                              depth: Float(uiImage.size.height / uiImage.size.width) * 1.05 * photoSize,
                                                              cornerRadius: 0.0))
            
            let whiteMaterial = UnlitMaterial(color: .white)
            whitePlaneModel.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            whitePlaneModel.position = simd_make_float3(0.0, 0.0, -0.001)
            whitePlaneModel.model?.materials = [whiteMaterial]
            
            photoAnchor.addChild(photoPlaneModel)
            photoAnchor.addChild(whitePlaneModel)
            
        } catch {
            print("Error occurred: \(error.localizedDescription), PresAR.swift, presentationPhoto()")
        }
        
        // avatar生成
        let avatarAnchor = AnchorEntity()
        var avatarModel = ModelEntity()
        
        var sceneURL: URL? = nil
        switch self.randomInt {
        case 0:
            sceneURL = Bundle.main.url(forResource: "man", withExtension: "usdz", subdirectory: "art.scnassets")!
            randomInt += 1
        default:
            sceneURL = Bundle.main.url(forResource: "woman", withExtension: "usdz", subdirectory: "art.scnassets")!
            randomInt = 0
        }
        
        if let model = try? Entity.loadModel(contentsOf: sceneURL!) { // art.scnassets UI, Emission 230
            avatarModel = model
            avatarAnchor.addChild(avatarModel)
        }
        
        // Calculation
        let calculatedPhoto = calculation.calculateTargetFromRelativePositionAndOrientation(reference: referencePositionAndEuler, relativePositionAndOrientation: LinkContainer_Photo.photo)
        let calculatedAvatar = calculation.calculateTargetFromRelativePositionAndOrientation(reference: referencePositionAndEuler, relativePositionAndOrientation: LinkContainer_Photo.avatar)
        
        // 写真の向き（TransformはPositionを上書きするので初めに処理）
        photoAnchor.transform = Transform(pitch: calculatedPhoto.euler.x,
                                          yaw: calculatedPhoto.euler.y,
                                          roll: calculatedPhoto.euler.z)
        
        // 写真の位置
        photoAnchor.position = simd_make_float3(calculatedPhoto.position.x,
                                                calculatedPhoto.position.y,
                                                calculatedPhoto.position.z)
        
        // 写真は縮小しておく
        photoAnchor.scale = simd_make_float3(0.001, 0.001, 0.001)
        
        // Avatarの向き（TransformはPositionを上書きするので初めに処理）
        avatarAnchor.transform = Transform(pitch: calculatedAvatar.euler.x,
                                           yaw: calculatedAvatar.euler.y,
                                           roll: calculatedAvatar.euler.z)
        
        // Avatarの位置
        avatarAnchor.position = simd_make_float3(calculatedAvatar.position.x,
                                                 calculatedAvatar.position.y,
                                                 calculatedAvatar.position.z)
        
        self.arView.scene.anchors.append(avatarAnchor)
        self.arView.scene.anchors.append(photoAnchor)
        
        let avatar = Avatar(entity: avatarModel,
                               anchor: avatarAnchor,
                               euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0))
        
        // PhotoDistanceExperiments
        let photo = Pres_Photo(id: LinkContainer_Photo.id,
                                  referenceID: LinkContainer_Photo.referenceID,
                                  registrationDate: LinkContainer_Photo.registrationDate,
                                  anchor: photoAnchor,
                                  euler: OriginalEuler(x: 0.0, y: 0.0, z: 0.0),
                                  avatar: avatar,
                               animationBool: AnimationBool(photo: false, avatar: true, interval: false),
                               photoDistance: LinkContainer_Photo.photoDistance,
                               originalPositionAndEuler: LinkContainer_Photo.originalPositionAndEuler
                               )
        
        self.ar_photoArray.append(photo)
    }
    
    let time = 0.5
    let expansion = simd_make_float3(1000, 1000, 1000)
    let shrinkage = simd_make_float3(0.001, 0.001, 0.001)
    
    var animation_presentedPhoto: Bool = false
    var animation_presentedPhotoDate: String = ""
    
    // MARK: Animation
    func ar_animationProcess(frame: ARFrame) -> (Bool, String) {
        for (index, ar_photo) in ar_photoArray.enumerated() {
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
                        ar_scaleAnimation(anchor: photoAnchor, animationType: expansion)
                        ar_photoArray[index].animationBool.photo = true
                        animation_presentedPhoto = true
                        animation_presentedPhotoDate = ar_photoArray[index].registrationDate
                    case .avatar:
                        if animationInstruction.1 {
                            ar_scaleAnimation(anchor: avatarAnchor, animationType: expansion)
                            ar_photoArray[index].animationBool.avatar = true
                        } else {
                            ar_scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            ar_photoArray[index].animationBool.avatar = false
                        }
                    case .photoAndAvatar:
                        if animationInstruction.1 {
                            ar_scaleAnimation(anchor: photoAnchor, animationType: expansion)
                            ar_scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            ar_photoArray[index].animationBool.photo = true
                            ar_photoArray[index].animationBool.avatar = false
                            animation_presentedPhoto = true
                            animation_presentedPhotoDate = ar_photoArray[index].registrationDate
                        } else {
                            ar_scaleAnimation(anchor: photoAnchor, animationType: shrinkage)
                            ar_scaleAnimation(anchor: avatarAnchor, animationType: expansion)
                            ar_photoArray[index].animationBool.photo = false
                            ar_photoArray[index].animationBool.avatar = true
                            animation_presentedPhoto = false
                            animation_presentedPhotoDate = ""
                        }
                    }
                    
                    ar_photoArray[index].animationBool.interval = true
                    Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                        self.ar_photoArray[index].animationBool.interval = false
                    }
                }
            }
        }
        return (animation_presentedPhoto, animation_presentedPhotoDate)
    }
    

    //　リアルタイム処理（主な追加）
    func updatePhotoDistance(_ distance: Float, dataTransfer: DataTransfer) {
        print("updating Distance: \(distance)")
        for photo in ar_photoArray {
            // データを取得
            guard let originalPositionAndEuler = photo.originalPositionAndEuler else {
                        print("Original Position and Euler not found!")
                        continue
                    }
            print("Original Position: \(originalPositionAndEuler.position), Euler: \(originalPositionAndEuler.euler)")
            
     
            // 撮影設置時の位置をsimd_float3に変換
            let originalPositionSimd = simd_float3(
                originalPositionAndEuler.position.x,
                originalPositionAndEuler.position.y,
                originalPositionAndEuler.position.z
            )

     /*
            // 撮影設置時の方向ベクトルを計算
            let forwardVector = simd_make_float3(
                cos(originalPositionAndEuler.euler.x) * sin(originalPositionAndEuler.euler.y),
                sin(originalPositionAndEuler.euler.x),
                -cos(originalPositionAndEuler.euler.x) * cos(originalPositionAndEuler.euler.y)
            )
            // 新しい位置を計算
            let newPosition = originalPositionSimd + forwardVector * distance
            */
            // 回転行列を作成
            let rotationMatrix = simd_float4x4(Transform(pitch: originalPositionAndEuler.euler.x,
                                                         yaw: originalPositionAndEuler.euler.y,
                                                         roll: originalPositionAndEuler.euler.z).matrix)

            // 視線ベクトルを定義
            let forwardVector = simd_make_float3(0, 0, -1)

            // forwardVectorを回転行列で変換
            let transformedVector = simd_make_float3(simd_mul(rotationMatrix, simd_make_float4(forwardVector, 0)).x,
                                                     simd_mul(rotationMatrix, simd_make_float4(forwardVector, 0)).y,
                                                     simd_mul(rotationMatrix, simd_make_float4(forwardVector, 0)).z)

            // 新しい位置を計算
            let newPosition = originalPositionSimd + transformedVector * distance

  
            // Anchor に適用
            photo.anchor.position = newPosition
            photo.anchor.scale = SIMD3<Float>(repeating: distance)
            
            //photoAnchor.positionの同期(一応)
            if let photoAnchor = photo.anchor as? AnchorEntity {
                photoAnchor.position = newPosition
                print("同期済み")
            }

            // サイズを更新
            //let photoSize = distance
            //photo.anchor.scale = SIMD3<Float>(repeating: photoSize)
            photo.anchor.scale = SIMD3<Float>(repeating: distance)
            //let scaleFactor = distance / photo.photoDistance
            //photo.anchor.scale = SIMD3<Float>(repeating: scaleFactor)

            

            print("Updated photo position to \(newPosition), size to \(photoSize)")
        }
    }
    
    
    
    
    // MARK: Change Photo and Avatar
    func ar_changePhotoAndAvatar() {
        for (index, photo) in ar_photoArray.enumerated() {
            if photo.animationBool.photo {
                ar_scaleAnimation(anchor: photo.anchor, animationType: shrinkage)
                ar_photoArray[index].animationBool.photo = false
                
                ar_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.ar_photoArray[index].animationBool.interval = false
                }
            }
            if photo.animationBool.avatar {
                ar_scaleAnimation(anchor: photo.avatar.anchor, animationType: shrinkage)
                ar_photoArray[index].animationBool.avatar = false
                
                ar_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.ar_photoArray[index].animationBool.interval = false
                }
            }
        }
        for (index, photo) in reg_photoArray.enumerated() {
            if photo.animationBool.avatar == false {
                ar_scaleAnimation(anchor: photo.avatar.anchor, animationType: expansion)
                reg_photoArray[index].animationBool.avatar = true
                
                reg_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.reg_photoArray[index].animationBool.interval = false
                }
            }
        }
    }
    
    private func ar_scaleAnimation(anchor: AnchorEntity, animationType: simd_float3) {
        anchor.move(to: Transform(scale: animationType),
                    relativeTo: anchor,
                    duration: time)
    }
}
