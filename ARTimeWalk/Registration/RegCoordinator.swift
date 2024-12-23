//
//  RegCoordinator.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/01/07.
//

import RealityKit
import ARKit

class RegCoordinator: NSObject, ARSessionDelegate {
    let parent: RegARViewContainer
    
    init(_ parent: RegARViewContainer) {
        self.parent = parent
        super.init()
        
        addTapGesture()
        addDragGesture()
    }
    
    var counter = 0
    
    // MARK: Frame Session
    func session(_ session: ARSession, didUpdate frame: ARFrame) { // 1秒間に60回の呼び出し
        // Animation
        counter += 1
        if counter == 6 { // 1秒間に10回の呼び出し（animationにそこまでの頻度は必要ないと判断）
            parent.model.regAr.animationProcess(frame: frame)
            counter = 0
        }
        // Manipulation
        if parent.model.duringPhotoManipulation {
            parent.model.regAr.photoManipulation(frame: frame)
        }
    }
    
    // MARK: Update Reference Anchor
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if parent.model.updateReferenceAnchorTrigger {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                parent.model.failedDetect = false
                parent.model.regAr.updateReferenceAnchor(anchor: imageAnchor)
            }
        }
    }
    
    // MARK: Tap Gesture
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        parent.model.regAr.arView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if !parent.model.duringPostData && !parent.model.duringPhotoManipulation && !parent.model.updateReferenceAnchorTrigger {
            let tapLocation = recognizer.location(in: parent.model.regAr.arView)
            if let tappedEntity = parent.model.regAr.arView.entity(at: tapLocation) as? ModelEntity {
                if let entityType = tappedEntity.components[EntityType.self] as? EntityType {
                    parent.model.tapProcessing(entityType: entityType, entity: tappedEntity)
                }
            }
        }
    }
    
    // MARK: Drag Gesture
    func addDragGesture() {
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(recognizer:)))
        parent.model.regAr.arView.addGestureRecognizer(dragGesture)
    }
    
    var index: Int = 0
    var gestureTranslationCache: Float = 1.0
    @objc func handleDrag(recognizer: UIPanGestureRecognizer) {
        if !parent.model.duringPostData && !parent.model.duringPhotoManipulation && !parent.model.updateReferenceAnchorTrigger {
            let dragLocation = recognizer.location(in: parent.model.regAr.arView)
            if let draggedEntity = parent.model.regAr.arView.entity(at: dragLocation) as? ModelEntity {
                if let entityType = draggedEntity.components[EntityType.self] as? EntityType {
                    switch entityType.kind {
                    case .avatar:
                        switch recognizer.state {
                        case .began:
                            guard let avatarEntityIndex = parent.model.regAr.reg_photoArray.firstIndex(where: {$0.avatar.entity == draggedEntity}) else {
                                break
                            }
                            index = avatarEntityIndex
                            gestureTranslationCache = 1.0
                        case .changed:
                            let gestureTranslation: Float = Float(recognizer.translation(in: parent.model.regAr.arView).y)
                            let diff = gestureTranslation - gestureTranslationCache
                            parent.model.regAr.positionChangeAvatar(index: index, diff: diff)
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
