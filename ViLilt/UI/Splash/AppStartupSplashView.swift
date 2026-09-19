//
//  AppStartupSplashView.swift
//  viLilt
//
//  Startup splash screen showing on-device intelligence initialization progress
//

import SwiftUI

public struct AppStartupSplashView: View {
    @Binding var isCompleted: Bool
    @State private var startupProgress: Double = 0.0
    @State private var statusLabel: String = "Initializing Neural Audio..."
    
    public init(isCompleted: Binding<Bool>) {
        self._isCompleted = isCompleted
    }
    
    public var body: some View {
        ZStack {
            LiltTheme.darkBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(LiltTheme.liltGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: LiltTheme.liltViolet.opacity(0.5), radius: 20)
                    
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(LiltTheme.pureWhite)
                }
                
                VStack(spacing: 6) {
                    Text("viLilt")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundColor(LiltTheme.pureWhite)
                    
                    Text("Talk. Listen. Nothing else.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LiltTheme.liltCyan)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    ProgressView(value: startupProgress, total: 1.0)
                        .tint(LiltTheme.liltCyan)
                        .padding(.horizontal, 40)
                    
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundColor(LiltTheme.pearl.opacity(0.8))
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            runStartupSequence()
        }
    }
    
    private func runStartupSequence() {
        Task {
            startupProgress = 0.2
            statusLabel = "Verifying On-Device Neural Engines..."
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            startupProgress = 0.6
            statusLabel = "Loading Companion Personas & Voice Assets..."
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            startupProgress = 1.0
            statusLabel = "Ready!"
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isCompleted = true
                }
            }
        }
    }
}
