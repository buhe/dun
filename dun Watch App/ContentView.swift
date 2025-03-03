//
//  ContentView.swift
//  dun Watch App
//
//  Created by 顾艳华 on 3/1/25.
//

import SwiftUI
import CoreMotion
import WatchKit

class SquatCounter: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var count = 0
    private var isInSquatPosition = false
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else { return }
            
            // 使用加速度计和陀螺仪数据检测蹲起动作
            let gravity = motion.gravity
            let verticalMovement = gravity.y
            
            // 检测蹲下和站起的阈值
            if let strongSelf = self, verticalMovement < -0.0003 && !strongSelf.isInSquatPosition {
                strongSelf.isInSquatPosition = true
            } else if let strongSelf = self, verticalMovement > -0.0001 && strongSelf.isInSquatPosition {
                strongSelf.isInSquatPosition = false
                strongSelf.count += 1
                
                // 每完成5次震动提示一次
                if strongSelf.count % 5 == 0 {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct ContentView: View {
    @StateObject private var squatCounter = SquatCounter()
    @State private var targetSquats = 100.0
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("\(Int(squatCounter.count))/\(Int(targetSquats))")
                    .font(.system(size: 40, weight: .bold))
                
                ProgressView(value: Double(squatCounter.count), total: targetSquats)
                    .tint(.green)
                    .padding(.horizontal)
                
                Text("\(Int(targetSquats))次")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .focusable()
                    .digitalCrownRotation($targetSquats, from: 10.0, through: 100.0, by: 10.0)
            }
            .padding()
            
            if Double(squatCounter.count) >= targetSquats {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    Text("🎉 目标达成！")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Button(action: {
                        squatCounter.count = 0
                    }) {
                        Text("重新开始")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
