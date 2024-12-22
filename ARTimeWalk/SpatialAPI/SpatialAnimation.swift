//
//  SpatialAnimation.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/12.
//

import Foundation

class SpatialAnimation {
    // 写真を表示する角度（アバターと写真を繋ぐ線の角度を0°としたときの正角と負角、指定した角度の2倍が範囲となる）
    let presentationPhotoDegree: Float = 30.0
    // Animationの基準は、カメラの位置から0.3m後方（ユーザの位置）に設定
    let distanceToUser: Float = -0.3
    
    // Animation
    func expansionAndShrinkage(camera: OriginalPositionAndEuler, photoPosition: OriginalPosition, avatarPosition: OriginalPosition, animationBool: AnimationBool, photoDistance: Float) -> (AnimationTarget, Bool)? {
        
        // Distance Measurement
        let x = (camera.position.x + distanceToUser * cos(camera.euler.x) * sin(camera.euler.y)) - avatarPosition.x
        let z = (camera.position.z - distanceToUser * cos(camera.euler.x) * cos(camera.euler.y)) - avatarPosition.z
        
        let distance = sqrt(x * x + z * z)
        
        // PhotoDistanceExperiments Parameters
        // ジオフェンス半径は調整してください。
        // 写真のカメラからの距離の半分をジオフェンスとして設定しています。
        //let geofenceSize = photoDistance / 2 // 写真を表示するジオフェンス半径[m]
        let geofenceSize: Float = 10.0       //写真横から見える設定[m]
        
        if distance < geofenceSize { // In
            if animationBool.photo == false {
                if animationBool.avatar {
                    // Degree Measurement
                    if degreeMeasurement() {
                        return (AnimationTarget(kind: .photoAndAvatar), true)
                    } else {
                        return (AnimationTarget(kind: .avatar), false)
                    }
                } else {
                    // Degree Measurement
                    if degreeMeasurement() {
                        return (AnimationTarget(kind: .photo), true)
                    }
                }
            }
        } else { // Out
            if animationBool.avatar == false {
                if animationBool.photo {
                    return (AnimationTarget(kind: .photoAndAvatar), false)
                }
                return (AnimationTarget(kind: .avatar), true)
            }
        }
        
        // Degree Measurement
        func degreeMeasurement() -> Bool {
            let cameraConvertPosition_x = camera.position.x + 1.0 * sin(camera.euler.y)
            let cameraConvertPosition_z = camera.position.z - 1.0 * cos(camera.euler.y)
            
            var cameraRadian_y = atan2(camera.position.z - cameraConvertPosition_z, camera.position.x - cameraConvertPosition_x)
            if cameraRadian_y < 0 {
                cameraRadian_y = cameraRadian_y + 2 * .pi
            }
            
            var avatarToPhotoRadian_y = atan2(avatarPosition.z - photoPosition.z, avatarPosition.x - photoPosition.x)
            if avatarToPhotoRadian_y < 0 {
                avatarToPhotoRadian_y = avatarToPhotoRadian_y + 2 * .pi
            }
            
            let cameraDegree = cameraRadian_y * 180 / .pi
            let avatarToPhotoDegree = avatarToPhotoRadian_y * 180 / .pi
            
            if avatarToPhotoDegree < presentationPhotoDegree {
                if cameraDegree <= avatarToPhotoDegree + presentationPhotoDegree || 360 + avatarToPhotoDegree - presentationPhotoDegree <= cameraDegree {
                    return true
                }
                
            } else if 360 - presentationPhotoDegree < avatarToPhotoDegree {
                if cameraDegree <= presentationPhotoDegree - (360 - avatarToPhotoDegree) || avatarToPhotoDegree - presentationPhotoDegree <= cameraDegree {
                    return true
                }
                
            } else {
                if avatarToPhotoDegree - presentationPhotoDegree <= cameraDegree && cameraDegree <= avatarToPhotoDegree + presentationPhotoDegree {
                    return true
                }
            }
            return false
        }
        return nil
    }
}
