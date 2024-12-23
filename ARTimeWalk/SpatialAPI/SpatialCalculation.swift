//
//  SpatialCalculation.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2023/08/12.
//

import Foundation
import simd

class SpatialCalculation {
    // MARK: Calculate Relative Position And Orientation
    /**
     referenceとtargetに位置(x,y,z)と向き(x,y,z)を渡すと、相対位置と向きを返します。
     相対位置と向きは、referenceを原点としたときのtargetの位置と向きです。
     ※targetにはPhotoやAvatar、Reference（Referenceリンクの算出として）を入れて使用しています。
     */
    func calculateRelativePositionAndOrientation(reference: OriginalPositionAndEuler, target: OriginalPositionAndEuler) -> OriginalPositionAndEuler {
        
        let calculatedPosition = coordinateTransformationToCalculateRelativePositionAndOrientation(reference: reference, targetPosition: target.position)
        let calculatedEuler = OriginalEuler(x: target.euler.x, y: target.euler.y - reference.euler.y, z: target.euler.z)
        
        return OriginalPositionAndEuler(position: calculatedPosition, euler: calculatedEuler)
    }
    
    private func coordinateTransformationToCalculateRelativePositionAndOrientation(reference: OriginalPositionAndEuler, targetPosition: OriginalPosition) -> OriginalPosition {
        // 平行移動
        let transform_parallel = simd_float4x4(rows: [
            simd_float4(1.0, 0.0, 0.0, -reference.position.x),
            simd_float4(0.0, 1.0, 0.0, -reference.position.y),
            simd_float4(0.0, 0.0, 1.0, -reference.position.z),
            simd_float4(0.0, 0.0, 0.0, 1.0)
        ])
        
        let targetVector_parallel = simd_float4(targetPosition.x, targetPosition.y, targetPosition.z, 1.0)
        
        let result_parallel = simd_mul(transform_parallel, targetVector_parallel)
        let transformedPosition_parallel = OriginalPosition(x: result_parallel.x, y: result_parallel.y, z: result_parallel.z)
        
        // 回転
        let transform_rotate = simd_float2x2(rows: [
            simd_float2(cos(reference.euler.y), -sin(reference.euler.y)),
            simd_float2(sin(reference.euler.y),  cos(reference.euler.y))
        ])
        
        let targetVector_rotate = simd_float2(transformedPosition_parallel.x, transformedPosition_parallel.z)
        
        let result_rotate = simd_mul(transform_rotate, targetVector_rotate)
        let transformedPosition_rotate = OriginalPosition(x: result_rotate.x, y: transformedPosition_parallel.y, z: result_rotate.y)
        
        return transformedPosition_rotate
    }
    
    // MARK: Calculate Target From Relative Position And Orientation
    /**
     referenceに位置(x,y,z)と向き(x,y,z)、relativePositionAndOrientationに相対位置と向きを渡すと、対象の位置と向きを返します。
     対象の位置と向きは、referenceからの相対的な位置と向きとして算出されます。
     */
    func calculateTargetFromRelativePositionAndOrientation(reference: OriginalPositionAndEuler, relativePositionAndOrientation: OriginalPositionAndEuler) -> OriginalPositionAndEuler {
        
        let calculatedPosition = coordinateTransformationToCalculateTargetFromRelativePositionAndOrientation(reference: reference, relativePosition: relativePositionAndOrientation.position)
        let calculatedEuler = OriginalEuler(x: relativePositionAndOrientation.euler.x, y: relativePositionAndOrientation.euler.y + reference.euler.y, z: relativePositionAndOrientation.euler.z)
        
        return OriginalPositionAndEuler(position: calculatedPosition, euler: calculatedEuler)
    }
    
    private func coordinateTransformationToCalculateTargetFromRelativePositionAndOrientation(reference: OriginalPositionAndEuler, relativePosition: OriginalPosition) -> OriginalPosition {
        // 回転
        let transform_rotate = simd_float2x2(rows: [
            simd_float2(cos(-reference.euler.y), -sin(-reference.euler.y)),
            simd_float2(sin(-reference.euler.y),  cos(-reference.euler.y))
        ])
        
        let targetVector_rotate = simd_float2(relativePosition.x, relativePosition.z)
        
        let result_rotate = simd_mul(transform_rotate, targetVector_rotate)
        let transformedPosition_rotate = OriginalPosition(x: result_rotate.x, y: relativePosition.y, z: result_rotate.y)
        
        // 平行移動
        let transform_parallel = simd_float4x4(rows: [
            simd_float4(1.0, 0.0, 0.0, reference.position.x),
            simd_float4(0.0, 1.0, 0.0, reference.position.y),
            simd_float4(0.0, 0.0, 1.0, reference.position.z),
            simd_float4(0.0, 0.0, 0.0, 1.0)
        ])
        
        let targetVector_parallel = simd_float4(transformedPosition_rotate.x, relativePosition.y, transformedPosition_rotate.z, 1.0)
        
        let result_parallel = simd_mul(transform_parallel, targetVector_parallel)
        let transformedPosition_parallel = OriginalPosition(x: result_parallel.x, y: result_parallel.y, z: result_parallel.z)
        
        return transformedPosition_parallel
    }
}
