//
//  PresAR+AddPhoto.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/11/17.
//

import ARKit
import RealityKit

extension PresAR {
    // need refactoring
    // MARK: Take And Registration Photo
    func reg_takeAndRegistrationPhoto() {
        // 写真生成
        guard let arFrame = arView.session.currentFrame else { return }
        let viewportSize = CGSize(width: 0, height: 0)
        
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
            
            let photoAnchor = AnchorEntity()
            let photoPlaneEntity = ModelEntity(mesh: .generatePlane(width: interfaceOrientation == .portrait ? 1.0 : Float(uiImage.size.width / uiImage.size.height * 1.0),
                                                                    depth: interfaceOrientation == .portrait ? Float(uiImage.size.height / uiImage.size.width * 1.0) : 1.0,
                                                                    cornerRadius: 0.1))
            photoPlaneEntity.name = "photoPlane"
            print("Debug - photoPlaneEntity name set to: \(photoPlaneEntity.name ?? "No Name")")
            
            photoPlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            photoPlaneEntity.model?.materials = [photoMaterial]
            photoPlaneEntity.generateCollisionShapes(recursive: true)
            photoPlaneEntity.components[EntityType.self] = EntityType(kind: .photo)
            
            let whitePlaneEntity = ModelEntity(mesh: .generatePlane(width: interfaceOrientation == .portrait ? 1.05 : Float(uiImage.size.width / uiImage.size.height * 1.05),
                                                                    depth: interfaceOrientation == .portrait ? Float(uiImage.size.height / uiImage.size.width * 1.05) : 1.05,
                                                                    cornerRadius: 0.1))
            whitePlaneEntity.name = "whitePlane"
            print("Debug - whitePlaneEntity name set to: \(whitePlaneEntity.name ?? "No Name")")
            
            let whiteMaterial = UnlitMaterial(color: .white)
            whitePlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            whitePlaneEntity.position = simd_make_float3(0.0, 0.0, -0.001)
            whitePlaneEntity.model?.materials = [whiteMaterial]
            
            // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
            let distanceToPhoto: Float = 1.0 // 1.0m前方に表示
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
            
            //デバック出力
            photoAnchor.children.forEach { entity in
                if let modelEntity = entity as? ModelEntity {
                    print("Debug - After adding to anchor: \(modelEntity.name ?? "No Name")")
                }
            }
            
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
                                  photoDistance: 1.0)
            
            reg_photoArray.append(photo)
        } catch {
            print("Error occurred: \(error.localizedDescription), PresAR+AddPhoto.swift, reg_takeAndRegistrationPhoto()")
        }
    }
    
    // need refactoring
    // MARK: Pre Processing Photo Manipulation
    func reg_preProcessingPhotoManipulation(uiImage: UIImage, completion: @escaping () -> Void) {
        // Server保存用Jpegデータ
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.0) else { return }
        
        let cgImage = uiImage.cgImage
        
        do {
            let texture = try TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: nil, mipmapsMode: .none))
            savingTexture = texture
            
            var photoMaterial = UnlitMaterial(color: .white.withAlphaComponent(0.7))
            photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
            
            let anchor = AnchorEntity()
            let photoPlaneEntity = ModelEntity(mesh: .generatePlane(width: 1.0,
                                                                    depth: Float((uiImage.size.height) / (uiImage.size.width) * 1.0),
                                                                    cornerRadius: 0.0))
            
            photoPlaneEntity.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
            photoPlaneEntity.model?.materials = [photoMaterial]
            
            let whitePlaneEntity = ModelEntity(mesh: .generatePlane(width: 1.05,
                                                                    depth: Float(uiImage.size.height / uiImage.size.width * 1.05),
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
                                  photoDistance: 1.0)
            
            reg_photoArray.append(photo)
            
            completion()
        } catch {
            print("Error occurred: \(error.localizedDescription), PresAR+AddPhoto.swift, reg_preProcessingPhotoManipulation()")
        }
    }
    
    // MARK: Photo Manipulation
    func reg_photoManipulation(frame: ARFrame) {
        // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
        let distanceToPhoto: Float = 1.0 // 1.0m前方に表示
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
    func reg_registrationSelectedPhotoFromImageAlbum(image: UIImage, completion: @escaping () -> Void) {
        // preProcessingPhotoManipulation()のEntityを削除
        reg_photoArray.last!.anchor.removeChild(reg_photoArray.last!.photoPlaneEntity)
        reg_photoArray.last!.anchor.removeChild(reg_photoArray.last!.whitePlaneEntity)
        // 不透明なEntityに差し替え
        var photoMaterial = UnlitMaterial()
        photoMaterial.color.texture = PhysicallyBasedMaterial.Texture(savingTexture!)
        
        let photoPlane = ModelEntity(mesh: .generatePlane(width: 1.0,
                                                          depth: Float((image.size.height) / (image.size.width) * 1.0),
                                                          cornerRadius: 0.0))
        
        photoPlane.transform = Transform(pitch: .pi/2, yaw: 0, roll: 0)
        photoPlane.model?.materials = [photoMaterial]
        photoPlane.generateCollisionShapes(recursive: true)
        photoPlane.components[EntityType.self] = EntityType(kind: .photo)
        
        let whitePlane = ModelEntity(mesh: .generatePlane(width: 1.05,
                                                          depth: Float(image.size.height / image.size.width * 1.05),
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
    func reg_positionChangeAvatar(index: Int, diff: Float) {
        reg_photoArray[index].avatar.anchor.position.y -= diff * 0.001
    }
    
    // MARK: Remove Photo
    func reg_removePhoto() {
        arView.scene.anchors.remove(reg_photoArray[willRemoveIndex].anchor)
        arView.scene.anchors.remove(reg_photoArray[willRemoveIndex].avatar.anchor)
        
        reg_photoArray.remove(at: willRemoveIndex)
    }
    
    func resetVariable() {
        reg_process_photoArray.removeAll()
        tmp_reg_photoIndex.removeAll()
        tmp_sumImageDataSizeInAppDocumentsKB = 0.0
    }
    
    // 保存されていないデータを抽出
    func setVariable() {
        for (index, reg_photo) in reg_photoArray.enumerated() {
            if reg_photo.saved == false {
                reg_process_photoArray.append(Reg_Process_Photo(reg_photo: reg_photo))
                tmp_reg_photoIndex.append(index)
            }
        }
    }
    
    // MARK: Animation
    func reg_animationProcess(frame: ARFrame) {
        for (index, reg_photo) in reg_photoArray.enumerated() {
            if reg_photo.animationBool.interval == false {
                // 式を一般的な形に整えるため、y軸方向の回転にマイナスをかけていることに注意
                let cameraPosition = OriginalPosition(x: frame.camera.transform[3][0], y: frame.camera.transform[3][1], z: frame.camera.transform[3][2])
                let cameraEuler = OriginalEuler(x: frame.camera.eulerAngles.x, y: -frame.camera.eulerAngles.y, z: frame.camera.eulerAngles.z) // left -.pi ~ -0 | 0 ~ .pi right
                let camera = OriginalPositionAndEuler(position: cameraPosition, euler: cameraEuler)
                
                let photoAnchor = reg_photo.anchor
                let photoPosition = OriginalPosition(x: photoAnchor.position.x, y: photoAnchor.position.y, z: photoAnchor.position.z)
                
                let avatarAnchor = reg_photo.avatar.anchor
                let avatarPosition = OriginalPosition(x: avatarAnchor.position.x, y: avatarAnchor.position.y, z: avatarAnchor.position.z)
                
                // PhotoDistanceExperiments
                if let animationInstruction = animation.expansionAndShrinkage(camera: camera, photoPosition: photoPosition, avatarPosition: avatarPosition, animationBool: reg_photo.animationBool, photoDistance: 1.0) {
                    
                    switch animationInstruction.0.kind {
                    case .photo:
                        reg_scaleAnimation(anchor: photoAnchor, animationType: expansion)
                        reg_photoArray[index].animationBool.photo = true
                    case .avatar:
                        if animationInstruction.1 {
                            reg_scaleAnimation(anchor: avatarAnchor, animationType: expansion)
                            reg_photoArray[index].animationBool.avatar = true
                        } else {
                            reg_scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            reg_photoArray[index].animationBool.avatar = false
                        }
                    case .photoAndAvatar:
                        if animationInstruction.1 {
                            reg_scaleAnimation(anchor: photoAnchor, animationType: expansion)
                            reg_scaleAnimation(anchor: avatarAnchor, animationType: shrinkage)
                            reg_photoArray[index].animationBool.photo = true
                            reg_photoArray[index].animationBool.avatar = false
                        } else {
                            reg_scaleAnimation(anchor: photoAnchor, animationType: shrinkage)
                            reg_scaleAnimation(anchor: avatarAnchor, animationType: expansion)
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
    
    // MARK: Change Photo and Avatar
    func reg_changePhotoAndAvatar() {
        for (index, photo) in reg_photoArray.enumerated() {
            if photo.animationBool.photo {
                reg_scaleAnimation(anchor: photo.anchor, animationType: shrinkage)
                reg_photoArray[index].animationBool.photo = false
                
                reg_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.reg_photoArray[index].animationBool.interval = false
                }
            }
            if photo.animationBool.avatar {
                reg_scaleAnimation(anchor: photo.avatar.anchor, animationType: shrinkage)
                reg_photoArray[index].animationBool.avatar = false
                
                reg_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.reg_photoArray[index].animationBool.interval = false
                }
            }
        }
        for (index, photo) in ar_photoArray.enumerated() {
            if photo.animationBool.avatar == false {
                reg_scaleAnimation(anchor: photo.avatar.anchor, animationType: expansion)
                ar_photoArray[index].animationBool.avatar = true
                
                ar_photoArray[index].animationBool.interval = true
                Timer.scheduledTimer(withTimeInterval: time, repeats: false) {_ in
                    self.ar_photoArray[index].animationBool.interval = false
                }
            }
        }
    }
    
    private func reg_scaleAnimation(anchor: AnchorEntity, animationType: simd_float3) {
        anchor.move(to: Transform(scale: animationType),
                    relativeTo: anchor,
                    duration: time)
    }
}
