//
//  VoiceOrbView.swift
//  viLilt
//
//  Ambient voice call view with breathing chromatic pulsating orb and live subtitles
//

import SwiftUI

public struct VoiceOrbView: View {
    @State private var voiceEngine = VoiceConversationEngine.shared
    @State private var speechEngine = SpeechRecognitionEngine.shared
    @State private var pulseScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            LiltTheme.darkBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Persona Pill Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: voiceEngine.activePersona.icon)
                            .font(.subheadline)
                            .foregroundColor(LiltTheme.liltCyan)
                        Text(LocalizedStringKey(voiceEngine.activePersona.name))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(LiltTheme.pureWhite)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    statusPill
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // Pulsating Chromatic Resonance Orb
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { idx in
                        let level = CGFloat(speechEngine.audioLevel)
                        let baseSize: CGFloat = 180 + CGFloat(idx * 40)
                        let activeScale: CGFloat = voiceEngine.state == .listening ? (1.0 + level * CGFloat(idx + 1) * 0.4) : (voiceEngine.state == .speaking ? 1.08 : 1.0)
                        
                        Circle()
                            .stroke(
                                LiltTheme.liltGradient,
                                lineWidth: 2
                            )
                            .frame(width: baseSize, height: baseSize)
                            .scaleEffect(activeScale)
                            .opacity(voiceEngine.state == .idle ? 0.15 : Double(3 - idx) * 0.25)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: activeScale)
                    }
                    
                    // Central Chromatic Orb
                    Circle()
                        .fill(LiltTheme.orbGradient)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(orbRotation))
                        .shadow(color: LiltTheme.liltViolet.opacity(0.6), radius: 24)
                        .scaleEffect(voiceEngine.state == .speaking ? 1.12 : (voiceEngine.state == .listening ? 1.0 + CGFloat(speechEngine.audioLevel) * 0.3 : 1.0))
                        .animation(.easeInOut(duration: 0.15), value: speechEngine.audioLevel)
                    
                    // Center Icon / State
                    Group {
                        switch voiceEngine.state {
                        case .idle:
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(LiltTheme.pureWhite)
                        case .listening:
                            Image(systemName: "waveform")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(LiltTheme.pureWhite)
                        case .thinking:
                            ProgressView()
                                .tint(LiltTheme.pureWhite)
                                .scaleEffect(1.6)
                        case .speaking:
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(LiltTheme.pureWhite)
                        case .paused:
                            Image(systemName: "pause.fill")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(LiltTheme.pureWhite)
                        }
                    }
                }
                .onTapGesture {
                    handleOrbTap()
                }
                
                Spacer()
                
                // Real-time Subtitle & Transcription Stream
                VStack(spacing: 10) {
                    if !voiceEngine.liveUserUtterance.isEmpty {
                        Text("\"\(voiceEngine.liveUserUtterance)\"")
                            .font(.body.weight(.medium))
                            .foregroundColor(LiltTheme.liltCyan)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }
                    
                    if !voiceEngine.liveAssistantReply.isEmpty {
                        Text(voiceEngine.liveAssistantReply)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(LiltTheme.pureWhite)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }
                    
                    if voiceEngine.state == .idle {
                        Text(String(localized: "Tap orb to start hands-free voice companion call"))
                            .font(.caption)
                            .foregroundColor(LiltTheme.pearl.opacity(0.6))
                    }
                }
                .frame(minHeight: 80)
                
                Spacer()
                
                // Bottom Call Controls
                HStack(spacing: 28) {
                    Button {
                        if voiceEngine.state == .speaking {
                            voiceEngine.interrupt()
                        }
                    } label: {
                        Image(systemName: "hand.raised.fill")
                            .font(.title2)
                            .foregroundColor(voiceEngine.state == .speaking ? LiltTheme.pureWhite : LiltTheme.pureWhite.opacity(0.3))
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(voiceEngine.state != .speaking)
                    
                    Button {
                        if voiceEngine.state == .idle {
                            voiceEngine.startCallSession()
                        } else {
                            voiceEngine.endCallSession()
                        }
                    } label: {
                        Image(systemName: voiceEngine.state == .idle ? "phone.fill" : "phone.down.fill")
                            .font(.title)
                            .foregroundColor(LiltTheme.pureWhite)
                            .frame(width: 72, height: 72)
                            .background(voiceEngine.state == .idle ? LiltTheme.liltCyan : Color.red)
                            .clipShape(Circle())
                            .shadow(color: (voiceEngine.state == .idle ? LiltTheme.liltCyan : Color.red).opacity(0.5), radius: 12)
                    }
                    
                    Button {
                        voiceEngine.isHandsFreeMode.toggle()
                    } label: {
                        Image(systemName: voiceEngine.isHandsFreeMode ? "ear.badge.checkmark" : "ear")
                            .font(.title2)
                            .foregroundColor(voiceEngine.isHandsFreeMode ? LiltTheme.liltCyan : LiltTheme.pureWhite.opacity(0.4))
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
        }
    }
    
    @ViewBuilder
    private var statusPill: some View {
        let (titleKey, color) = statusDetails
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(titleKey)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var statusDetails: (LocalizedStringKey, Color) {
        switch voiceEngine.state {
        case .idle:
            return (LocalizedStringKey("STANDBY"), LiltTheme.pearl.opacity(0.6))
        case .listening:
            return (LocalizedStringKey("LISTENING"), LiltTheme.liltCyan)
        case .thinking:
            return (LocalizedStringKey("THINKING"), LiltTheme.liltViolet)
        case .speaking:
            return (LocalizedStringKey("TALKING"), Color.orange)
        case .paused:
            return (LocalizedStringKey("PAUSED"), Color.yellow)
        }
    }
    
    private func handleOrbTap() {
        if voiceEngine.state == .idle {
            voiceEngine.startCallSession()
        } else if voiceEngine.state == .speaking {
            voiceEngine.interrupt()
        } else {
            voiceEngine.endCallSession()
        }
    }
}
