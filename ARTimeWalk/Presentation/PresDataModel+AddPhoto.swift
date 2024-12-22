//
//  PresDataModel+AddPhoto.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/06/26.
//

import SwiftUI
import RealityKit

extension PresDataModel {
    func startPhotoManipulation() {
        presAr.reg_preProcessingPhotoManipulation(uiImage: inputFromImageAlbum!) {
            self.duringPhotoManipulation = true
            self.currentMode = .registrationSelectedPhotoFromImageAlbum
        }
    }
    
    func stopPhotoManipulation() {
        self.duringPhotoManipulation = false
        presAr.reg_registrationSelectedPhotoFromImageAlbum(image: inputFromImageAlbum!) {
            self.reg_photoCount += 1
            self.currentMode = .takeAndRegistrationPhoto
        }
    }
    
    func tapProcessing(entityType: EntityType, entity: Entity) {
        switch entityType.kind {
        case .photo:
            if let index = presAr.reg_photoArray.firstIndex(where: {$0.photoPlaneEntity == entity}) {
                reg_photoImage = UIImage(data: presAr.reg_photoArray[index].jpegData)!
                
                presAr.willRemoveIndex = index
                isCustomAlert_Photo = true
            }
        case .avatar:
            if let index = presAr.reg_photoArray.firstIndex(where: {$0.avatar.entity == entity}) {
                reg_photoImage = UIImage(data: presAr.reg_photoArray[index].jpegData)!
                
                presAr.willRemoveIndex = index
                isCustomAlert_Photo = true
            }
        default:
            break
        }
    }
    
    func stateCheck(selectedDataSource: DataSource) {
        // 参照点と写真の数をCheck
        if 0 < reg_photoCount && detectedReferenceImage != nil {
            switch selectedDataSource {
            case .local:
                isAlert_savePhoto.toggle()
            case .global:
                isAlert_postPhoto.toggle()
            }
        } else if detectedReferenceImage != nil {
            isAlert_photoIsRequired.toggle()
        } else {
            isAlert_referenceAnchorIsRequired.toggle()
        }
    }
    
    func reg_saveDataProcess(dataTransfer: DataTransfer) {
        duringPostData = true
        
        switch selectedDataSource {
        case .local:
            let save_photoArray = presAr.reg_saveToAppDB(referenceID: dataTransfer.referenceContainerArray[selectedReferenceIndex].id)
            
            for (index, appDB_photo) in save_photoArray.enumerated() {
                let photoPosition = OriginalPosition(x: appDB_photo.photoPositionX, y: appDB_photo.photoPositionY, z: appDB_photo.photoPositionZ)
                let photoEuler = OriginalEuler(x: appDB_photo.photoEulerX, y: appDB_photo.photoEulerY, z: appDB_photo.photoEulerZ)
                let avatarPosition = OriginalPosition(x: appDB_photo.avatarPositionX, y: appDB_photo.avatarPositionY, z: appDB_photo.avatarPositionZ)
                let avatarEuler = OriginalEuler(x: appDB_photo.avatarEulerX, y: appDB_photo.avatarEulerY, z: appDB_photo.avatarEulerZ)
                
                let linkOriginalPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: photoEuler)
                
                // PhotoDistanceExperiments
                let photo = LinkContainer_Photo(id: appDB_photo.id,
                                                uuid: appDB_photo.uuid,
                                                serverID: appDB_photo.serverID,
                                                userID: appDB_photo.userID,
                                                userName: appDB_photo.userName,
                                                referenceID: appDB_photo.referenceID,
                                                jpegDataFileName: appDB_photo.jpegDataFileName,
                                                jpegData: presAr.reg_photoArray[presAr.tmp_reg_photoIndex[index]].jpegData,
                                                dataSizeKB: appDB_photo.dataSizeKB,
                                                imageAlbum: appDB_photo.imageAlbum,
                                                registrationDate: appDB_photo.registrationDate,
                                                photo: OriginalPositionAndEuler(position: photoPosition, euler: photoEuler),
                                                avatar: OriginalPositionAndEuler(position: avatarPosition, euler: avatarEuler),
                                                detailButton: false,
                                                photoDistance: 1.0,
                                                originalPositionAndEuler: linkOriginalPositionAndEuler)
                
                dataTransfer.linkContainerArray_photo.append(photo)
                
                reg_photoCountUP(dataTransfer: dataTransfer, index: annotationIndex)
            }
            
            DispatchQueue.main.async {
                dataTransfer.sumImageDataSizeInAppDocumentsMB += self.presAr.tmp_sumImageDataSizeInAppDocumentsKB / 1000.0
            }
            
            reg_saveDataProcess_after(dataTransfer: dataTransfer)
            
        case .global:
            Task {
                presAr.resetVariable()
                presAr.setVariable()
                await presAr.reg_publishPhotoJpegData()
                let publish_photoArray = await presAr.reg_publishPhotoData(referenceID: dataTransfer.referenceContainerArray[selectedReferenceIndex].id)
                
                for (index, publish_photo) in publish_photoArray.enumerated() {
                    let photoPosition = OriginalPosition(x: publish_photo.photoPositionX, y: publish_photo.photoPositionY, z: publish_photo.photoPositionZ)
                    let photoEuler = OriginalEuler(x: publish_photo.photoEulerX, y: publish_photo.photoEulerY, z: publish_photo.photoEulerZ)
                    let avatarPosition = OriginalPosition(x: publish_photo.avatarPositionX, y: publish_photo.avatarPositionY, z: publish_photo.avatarPositionZ)
                    let avatarEuler = OriginalEuler(x: publish_photo.avatarEulerX, y: publish_photo.avatarEulerY, z: publish_photo.avatarEulerZ)
                    
                    let linkOriginalPositionAndEuler = OriginalPositionAndEuler(position: photoPosition, euler: photoEuler)
                    
                    let photo = LinkContainer_Photo(id: presAr.reg_process_photoArray[index].id!,
                                                    uuid: publish_photo.uuid,
                                                    serverID: presAr.reg_process_photoArray[index].id!,
                                                    userID: publish_photo.userID,
                                                    userName: ARTimeWalkApp.isUserName,
                                                    referenceID: publish_photo.referenceID,
                                                    jpegDataFileName: publish_photo.jpegDataFileName,
                                                    jpegData: presAr.reg_photoArray[presAr.tmp_reg_photoIndex[index]].jpegData,
                                                    dataSizeKB: publish_photo.dataSizeKB,
                                                    imageAlbum: publish_photo.imageAlbum,
                                                    registrationDate: publish_photo.registrationDate,
                                                    photo: OriginalPositionAndEuler(position: photoPosition, euler: photoEuler),
                                                    avatar: OriginalPositionAndEuler(position: avatarPosition, euler: avatarEuler),
                                                    detailButton: false,
                                                    photoDistance: 1.0,
                                                    originalPositionAndEuler: linkOriginalPositionAndEuler)
                    
                    dataTransfer.linkContainerArray_photo.append(photo)
                    
                    // [Multiple]
                    if multiple {
                        reg_photoCountUP(dataTransfer: dataTransfer, index: selectedReferenceIndex)
                    } else {
                        reg_photoCountUP(dataTransfer: dataTransfer, index: annotationIndex)
                    }
                }
                reg_saveDataProcess_after(dataTransfer: dataTransfer)
            }
        }
    }
    
    private func reg_photoCountUP(dataTransfer: DataTransfer, index: Int) {
        // 検索されたReferenceとNetworkによって紐付けられている他のReference全てに対してCount変更処理
        for referenceID in dataTransfer.annotationContainerArray[index].connectedReference {
            if let targetIndex = dataTransfer.annotationContainerArray.firstIndex(where: { $0.reference.id == referenceID }) {
                // PhotoCountを変更（MapView）
                dataTransfer.annotationContainerArray[targetIndex].reference.photoCount += 1
                // YourPhotoCountを変更（MapView）
                dataTransfer.annotationContainerArray[targetIndex].reference.yourPhotoCount += 1
            }
        }
    }
    
    private func reg_saveDataProcess_after(dataTransfer: DataTransfer) {
        dataTransfer.photoCountBool.toggle()
        
        duringPostData = false
        showingCheckMark = true
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {_ in
                self.showingCheckMark = false
            }
        }
    }
}
