//
//  ArSpatialGuide.swift
//  ARTimeWalk
//
//  Created by 黒崎蓮 on 2023/06/01.
//

import SwiftUI
import ARKit

extension PresAR {
    // ArSpatialGuide
    func spatialGuide(frame: ARFrame, index: Int, interfaceOrientation: UIInterfaceOrientation, viewPortSize: CGSize, pixelFocalLenX: Float, pixelFocalLenY: Float, fovX: Float, fovY: Float) -> ViewingPosition {
        // ARガイド用処理
        let adjustedAnchor = simd_make_float3(ar_photoArray[index].avatar.anchor.position.x,
                                              ar_photoArray[index].avatar.anchor.position.y + 1.65,
                                              ar_photoArray[index].avatar.anchor.position.z)
        let avatarPosition = simd_make_float4(adjustedAnchor, 1)
        // カメラ座標系でのAvatarの座標
        let avatarPosInCameraCoordinate = simd_make_float3(frame.camera.transform.inverse * avatarPosition)
        // 球面座標表現（単位はラジアンとメートル）
        let radius = simd_length(avatarPosInCameraCoordinate)
        var theta: Float = Float.pi / 2
        var phi: Float = 0
        // 画面の向きによって座標軸を変えて球面座標系に変換
        switch interfaceOrientation {
        case .portrait:
            theta = acos(avatarPosInCameraCoordinate.x / radius)
            let yzLength = simd_length(simd_make_float2(avatarPosInCameraCoordinate.y, avatarPosInCameraCoordinate.z))
            phi = sign(avatarPosInCameraCoordinate.y) * acos(avatarPosInCameraCoordinate.z * -1 / yzLength)
        case .portraitUpsideDown:
            theta = acos(avatarPosInCameraCoordinate.x * -1 / radius)
            let yzLength = simd_length(simd_make_float2(avatarPosInCameraCoordinate.y, avatarPosInCameraCoordinate.z))
            phi = sign(avatarPosInCameraCoordinate.y * -1) * acos(avatarPosInCameraCoordinate.z * -1 / yzLength)
        case .landscapeLeft:
            theta = acos(avatarPosInCameraCoordinate.y / radius)
            let xzLength = simd_length(simd_make_float2(avatarPosInCameraCoordinate.x, avatarPosInCameraCoordinate.z))
            phi = sign(avatarPosInCameraCoordinate.x * -1) * acos(avatarPosInCameraCoordinate.z * -1 / xzLength)
        case .landscapeRight:
            theta = acos(avatarPosInCameraCoordinate.y * -1 / radius)
            let xzLength = simd_length(simd_make_float2(avatarPosInCameraCoordinate.x, avatarPosInCameraCoordinate.z))
            phi = sign(avatarPosInCameraCoordinate.x) * acos(avatarPosInCameraCoordinate.z * -1 / xzLength)
        case .unknown:
            print("UIInterfaceOrientation is .unknown")
        @unknown default:
            print("Unknown interface orientation case.")
        }
        
        // 2Dガイドの座標を計算
        var viewPortPos = CGPoint(x: 0, y: 0)
        viewPortPos.x = CGFloat(viewPortSize.width / 2) + CGFloat(tan(phi) * pixelFocalLenX)
        viewPortPos.y = CGFloat(viewPortSize.height / 2) + CGFloat(tan(Float.pi / 2 - theta) * pixelFocalLenY)
        
        // 視野の外にオブジェクトがある場合の座標
        if abs(phi) <= fovX / 2 { // 視野角内
            // いらない処理?
            if viewPortSize.width < viewPortPos.x {
                viewPortPos.x = viewPortSize.width
            }
            if viewPortPos.x < 0 {
                viewPortPos.x = 0
            }
        }else if fovX / 2 < phi { // 右の視野外
            viewPortPos.x = viewPortSize.width
        }else if phi < -1 * fovX / 2 { // 左の視野外
            viewPortPos.x = 0
        }
        if abs(theta - Float.pi / 2) < fovY / 2 { // 視野角内
            // いらない処理?
            if viewPortSize.height < viewPortPos.y {
                viewPortPos.y = viewPortSize.height
            }
            if viewPortPos.y < 0 {
                viewPortPos.y = 0
            }
        }else if theta - Float.pi / 2 < fovY / 2 * -1 { // 下の視野外
            viewPortPos.y = viewPortSize.height
        }else if fovY / 2 < theta - Float.pi / 2 { // 上の視野外
            viewPortPos.y = 0
        }
        
        // フレーム内外判定
        var onFrame = false
        if abs(phi) <= fovX / 2 && abs(theta - Float.pi / 2) < fovY / 2 {
            onFrame = true
        }else {
            onFrame = false
        }
        
        let fixedDistanceFromCenter = calculateFixedDistanceFromCenter(position: viewPortPos)
        let fixedGreatCircleDistanceToFrame = calculateFixedGreatCircleDistanceToFrame(theta: theta, phi: phi, fovX: fovX, fovY: fovY)
        
        let viewingPosition = ViewingPosition(id: index, theta: theta, phi: phi, radius: radius, position: viewPortPos, onFrame: onFrame, fixedDistanceFromCenter: fixedDistanceFromCenter, fixedGreatCircleDistanceToFrame: fixedGreatCircleDistanceToFrame)
        
        return viewingPosition
    }
    
    // ディスプレイ中心からの重み付き距離（0~1を返す)
    func calculateFixedDistanceFromCenter(position: CGPoint) -> Double {
        let screenSize = UIScreen.main.bounds.size
        let aspectRatio = screenSize.height / screenSize.width
        let x = position.x - screenSize.width / 2
        let y = (position.y - screenSize.height / 2) / aspectRatio
        var fixedDistance: Double = sqrt(x * x + y * y) / (screenSize.width / 2)
        if 1 < fixedDistance {
            fixedDistance = 1
        }
        return fixedDistance
    }
    
    // オブジェクトがフレームに入るまでの大円距離を0~1で返す
    func calculateFixedGreatCircleDistanceToFrame(theta: Float, phi: Float, fovX: Float, fovY: Float) -> Double {
        let maxTheta = Float.pi / 2 - fovY / 2
        let maxPhi = Float.pi - fovX / 2
        let max = acos(cos(maxTheta) * cos(maxPhi)) // 大円距離（直角球面三角形の公式）
        var deltaTheta = abs(theta - Float.pi / 2) - fovY / 2
        var deltaPhi = abs(phi) - fovX / 2
        if deltaTheta < 0 {
            deltaTheta = 0
        }
        if deltaPhi < 0 {
            deltaPhi = 0
        }
        let delta = acos(cos(deltaTheta) * cos(deltaPhi))   // 大円距離（直角球面三角形の公式）
        return Double(delta / max)  // 0~1
    }
}
