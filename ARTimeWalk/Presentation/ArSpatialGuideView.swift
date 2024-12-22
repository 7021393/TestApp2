//
//  ArSpatialGuideView.swift
//  ARTimeWalk
//
//  Created by 黒崎蓮 on 2023/06/01.
//

import SwiftUI
import simd

struct ArSpatialGuideView: View {
    let model: PresDataModel
    let viewingPositions: [ViewingPosition]
    
    let frameSize: CGFloat = 100
    let ringSize: CGFloat = 55
    let sfCircleIconSize: CGFloat = 60
    let sfAvatarIconSize: CGFloat = 40
    
    // ArSpatialGuide
    var body: some View {
        GeometryReader { geometry in
            ForEach(viewingPositions) { viewingPosition in
                if viewingPosition.onFrame == false { // Avatarがフレーム外にある場合
                    ZStack {
                        // 人アイコン
                        Image(systemName: "circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.clear)
                            .font(.system(size: sfCircleIconSize))
                            .shadow(radius: 40)
                        Image(systemName: "figure.stand")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.clear)
                            .font(.system(size: sfAvatarIconSize))
                        
                        // プログレスリング
                        Circle()
                            .stroke(lineWidth: 4.7)
                            .foregroundStyle(Color.white)
                            .frame(width: ringSize, height: ringSize)
                        Circle()
                            .trim(from: 0, to: 1 - viewingPosition.fixedGreatCircleDistanceToFrame)
                            .stroke(style: StrokeStyle(lineWidth: 5.0,
                                                       lineCap: .round,
                                                       lineJoin: .round))
                            .foregroundStyle(Color.digitalBlue_color)
                            .rotationEffect(.radians(Double.pi / 2 * -1))
                            .frame(width: ringSize, height: ringSize)
                        
                        // 矢印
                        Image(systemName: "chevron.compact.up")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 40))
                            .rotationEffect(.radians(Double.pi / 2))
                            .position(x: 90, y: 50)
                            .rotationEffect(.radians(calculateArrowDirection(iconPosition: viewingPosition.position)))
                    }
                    .frame(width: frameSize, height: frameSize)
                    .position(fixIconPosition(position: viewingPosition.position,
                                              iconSize: Int(frameSize),
                                              safeAreaTop: geometry.safeAreaInsets.top,
                                              safeAreaBottom: geometry.safeAreaInsets.bottom,
                                              safeAreaRight: geometry.safeAreaInsets.trailing,
                                              safeAreaLeft: geometry.safeAreaInsets.leading))
                    
                } else if viewingPosition.onFrame { // Avatarがフレーム内にある場合
                    ZStack {
                        Image(systemName: "figure.stand")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.clear)
                            .font(.system(size: sfAvatarIconSize))
                        Circle()
                            .stroke(lineWidth: 5.0)
                            .foregroundStyle(Color.digitalBlue_color)
                            .frame(width: ringSize, height: ringSize)
                            .shadow(radius: 40)
                    }
                    .opacity((viewingPosition.fixedDistanceFromCenter - 0.5) / 0.5) // フェード処理
                    .position(fixIconPosition(position: viewingPosition.position,
                                              iconSize: Int(frameSize),
                                              safeAreaTop: geometry.safeAreaInsets.top,
                                              safeAreaBottom: geometry.safeAreaInsets.bottom,
                                              safeAreaRight: geometry.safeAreaInsets.trailing,
                                              safeAreaLeft: geometry.safeAreaInsets.leading))
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // アイコンの表示位置を調整する
    func fixIconPosition(position: CGPoint, iconSize: Int, safeAreaTop: CGFloat, safeAreaBottom: CGFloat, safeAreaRight: CGFloat, safeAreaLeft: CGFloat) -> CGPoint {
        var fixedPosition: CGPoint = position
        if position.x < CGFloat(iconSize / 2) + safeAreaLeft {
            fixedPosition.x = CGFloat(iconSize / 2) + safeAreaLeft
        }else if UIScreen.main.bounds.width - CGFloat(iconSize / 2) - safeAreaRight < position.x {
            fixedPosition.x = UIScreen.main.bounds.width - CGFloat(iconSize / 2) - safeAreaRight
        }
        if position.y < CGFloat(iconSize / 2) + safeAreaTop {
            fixedPosition.y = CGFloat(iconSize / 2) + safeAreaTop
        }else if UIScreen.main.bounds.height - CGFloat(iconSize / 2) - safeAreaBottom < position.y {
            fixedPosition.y = UIScreen.main.bounds.height - CGFloat(iconSize / 2) - safeAreaBottom
        }
        return fixedPosition
    }
    
    // ディスプレイ上の座標から矢印の角度を計算する
    func calculateArrowDirection(iconPosition: CGPoint) -> CGFloat {
        let x = iconPosition.x - UIScreen.main.bounds.width / 2
        let y = iconPosition.y - UIScreen.main.bounds.height / 2
        let length = sqrt(x * x + y * y)
        let angle = sign(y) * acos(x / length)
        return angle
    }
}

struct ViewingPosition: Identifiable {
    var id: Int
    var theta: Float = 0
    var phi: Float = 0
    var radius: Float = 0
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var onFrame: Bool = false
    var fixedDistanceFromCenter: Double = 1
    var fixedGreatCircleDistanceToFrame: Double = 0
}
