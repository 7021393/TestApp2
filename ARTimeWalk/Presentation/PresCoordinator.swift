//
//  PresCoordinator.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/08.
//

import RealityKit
import ARKit

class PresCoordinator: NSObject, ARSessionDelegate {
    let parent: PresARViewContainer
    
    init(_ parent: PresARViewContainer) {
        self.parent = parent
        super.init()
        
        addTapGesture()
        addDragGesture()
    }
    
    var counter = 0
    
    // MARK: Frame Session
    func session(_ session: ARSession, didUpdate frame: ARFrame) { // 1秒間に60回の呼び出し
        if parent.model.arExperienceAnimationTrigger {
            if parent.model.currentMode == .detectReference || parent.model.currentMode == .viewPhoto {
                // Animation
                counter += 1
                if counter == 6 { // 1秒間に10回の呼び出し（animationにそこまでの頻度は必要ないと判断）
                    let date = parent.model.presAr.ar_animationProcess(frame: frame)
                    if date.0 {
                        parent.model.lookingPhoto = true
                    } else {
                        parent.model.lookingPhoto = false
                    }
                    parent.model.photoDateText = date.1
                    counter = 0
                }
                // ArSpatialGuide
                parent.model.updateViewingPosition(frame: frame)
            } else {
                // Add Photo Animation
                counter += 1
                if counter == 6 { // 1秒間に10回の呼び出し（animationにそこまでの頻度は必要ないと判断）
                    parent.model.presAr.reg_animationProcess(frame: frame)
                    counter = 0
                }
                // Manipulation
                if parent.model.duringPhotoManipulation {
                    parent.model.presAr.reg_photoManipulation(frame: frame)
                }
            }
        }
    }
    
    // MARK: Update Reference Anchor
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if parent.model.currentMode == .detectReference && parent.model.updateReferenceAnchorTrigger {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                parent.model.failedDetect = false // Referenceの認識に成功
                parent.model.showReferenceView = false // Reference画像のUIを非表示
                parent.model.presAr.updateReferenceAnchor(imageAnchor: imageAnchor)
            }
        }
    }
    
    // MARK: Tap Gesture
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        parent.model.presAr.arView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if !parent.model.duringPostData && !parent.model.duringPhotoManipulation && parent.model.currentMode != .detectReference && parent.model.currentMode != .viewPhoto {
            let tapLocation = recognizer.location(in: parent.model.presAr.arView)
            if let tappedEntity = parent.model.presAr.arView.entity(at: tapLocation) as? ModelEntity {
                if let entityType = tappedEntity.components[EntityType.self] as? EntityType {
                    parent.model.tapProcessing(entityType: entityType, entity: tappedEntity)
                }
            }
        }
    }
    
    // MARK: Drag Gesture
    func addDragGesture() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(recognizer:)))
        parent.model.presAr.arView.addGestureRecognizer(dragGesture)
    }
    
    var index: Int = 0
    var gestureTranslationCache: Float = 1.0
    @objc func handleDrag(recognizer: UIPanGestureRecognizer) {
        if !parent.model.duringPostData && !parent.model.duringPhotoManipulation && parent.model.currentMode != .detectReference && parent.model.currentMode != .viewPhoto {
            let dragLocation = recognizer.location(in: parent.model.presAr.arView)
            if let draggedEntity = parent.model.presAr.arView.entity(at: dragLocation) as? ModelEntity {
                if let entityType = draggedEntity.components[EntityType.self] as? EntityType {
                    switch entityType.kind {
                    case .avatar:
                        switch recognizer.state {
                        case .began:
                            guard let avatarEntityIndex = parent.model.presAr.reg_photoArray.firstIndex(where: {$0.avatar.entity == draggedEntity}) else {
                                break
                            }
                            index = avatarEntityIndex
                            gestureTranslationCache = 1.0
                        case .changed:
                            let gestureTranslation: Float = Float(recognizer.translation(in: parent.model.presAr.arView).y)
                            let diff = gestureTranslation - gestureTranslationCache
                            parent.model.presAr.reg_positionChangeAvatar(index: index, diff: diff)
                            gestureTranslationCache = gestureTranslation
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}
