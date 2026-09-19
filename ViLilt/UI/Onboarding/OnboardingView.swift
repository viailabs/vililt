//
//  OnboardingView.swift
//  viLilt
//
//  Multi-step localized onboarding: Language selection, on-device privacy, permissions, and persona customization
//

import SwiftUI

public struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    public enum OnboardingStep: Int, CaseIterable {
        case language = 0
        case features = 1
        case persona = 2
    }
    
    @State private var step: OnboardingStep = .language
    @State private var selectedLanguage: String = LanguageManager.shared.currentLanguage
    @State private var currentSlide: Int = 0
    @State private var isRequestingPermissions: Bool = false
    @State private var permissionsGranted: Bool = false
    @State private var voiceEngine = VoiceConversationEngine.shared
    @State private var speechEngine = SpeechRecognitionEngine.shared
    
    @AppStorage("voice_feedback_enabled") private var voiceFeedbackEnabled = true
    @AppStorage("voice_speech_rate") private var voiceSpeechRate = 0.52
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            LiltTheme.darkBackgroundGradient
                .ignoresSafeArea()
            
            switch step {
            case .language:
                languageStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .features:
                featuresStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .persona:
                personaStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .environment(\.locale, LanguageManager.shared.locale)
        .id(LanguageManager.shared.effectiveLanguage)
    }
    
    // MARK: - Step 0: Language Selection
    private var languageStepView: some View {
        VStack(spacing: 20) {
            // Brand Pill
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title3)
                        .foregroundColor(LiltTheme.liltCyan)
                    Text("viLilt")
                        .font(.title3.weight(.heavy))
                        .foregroundColor(LiltTheme.pureWhite)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            // Header with Chromatic Icon
            ZStack {
                Circle()
                    .fill(LiltTheme.liltGradient.opacity(0.35))
                    .frame(width: 96, height: 96)
                    .blur(radius: 12)
                
                Circle()
                    .fill(LiltTheme.orbGradient)
                    .frame(width: 76, height: 76)
                    .shadow(color: LiltTheme.liltViolet.opacity(0.5), radius: 16)
                
                Image(systemName: "globe")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(LiltTheme.pureWhite)
            }
            .padding(.top, 4)
            
            VStack(spacing: 6) {
                Text(String(localized: "Choose Your Language"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(LiltTheme.pureWhite)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "Select your preferred language to customize your viLilt voice companion experience."))
                    .font(.caption)
                    .foregroundColor(LiltTheme.pearl.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            
            // 11 Language Options (Scrollable)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(LanguageManager.availableLanguages) { option in
                        Button {
                            selectedLanguage = option.id
                            LanguageManager.shared.setLanguage(option.id)
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(LiltTheme.pureWhite)
                                    Text(option.localizedName)
                                        .font(.caption2)
                                        .foregroundColor(LiltTheme.pearl.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if selectedLanguage == option.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(LiltTheme.liltCyan)
                                } else {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedLanguage == option.id ? LiltTheme.liltViolet.opacity(0.35) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedLanguage == option.id ? LiltTheme.liltCyan : Color.white.opacity(0.1), lineWidth: selectedLanguage == option.id ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            
            // Continue Button
            Button {
                LanguageManager.shared.setLanguage(selectedLanguage)
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = .features
                }
            } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "Continue"))
                        .font(.headline.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundColor(LiltTheme.pureWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(LiltTheme.liltGradient, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: LiltTheme.liltViolet.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Step 1: Features & Necessary Permissions
    private var featuresStepView: some View {
        VStack(spacing: 20) {
            // Top Nav
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        step = .language
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "Language"))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LiltTheme.pearl.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: Capsule())
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut) {
                        step = .persona
                    }
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LiltTheme.pearl.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            // Feature Carousel
            TabView(selection: $currentSlide) {
                featureSlide(
                    tag: 0,
                    icon: "lock.shield.fill",
                    title: String(localized: "100% On-Device & Private"),
                    description: String(localized: "Zero cloud telemetry, zero remote servers, complete privacy."),
                    badges: [
                        String(localized: "100% On-Device Execution"),
                        String(localized: "Zero Cloud Guarantee"),
                        String(localized: "100% Free Forever")
                    ]
                )
                
                featureSlide(
                    tag: 1,
                    icon: "waveform.circle.fill",
                    title: String(localized: "Voice & Speech"),
                    description: String(localized: "Speak replies aloud using high-fidelity neural TTS."),
                    badges: [
                        String(localized: "Hands-Free Voice"),
                        String(localized: "Real-Time STT"),
                        String(localized: "Neural Audio")
                    ]
                )
                
                featureSlide(
                    tag: 2,
                    icon: "sparkles",
                    title: String(localized: "Personas & Tones"),
                    description: String(localized: "A gentle, caring companion who listens attentively, offers encouragement, and provides thoughtful conversation."),
                    badges: [
                        String(localized: "Empathetic Friend"),
                        String(localized: "Intellectual Mentor"),
                        String(localized: "Language Practice Partner")
                    ]
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            // Bottom Action
            VStack(spacing: 10) {
                if currentSlide == 2 {
                    Button {
                        Task {
                            isRequestingPermissions = true
                            let granted = await speechEngine.requestPermissions()
                            permissionsGranted = granted
                            isRequestingPermissions = false
                            withAnimation(.easeInOut(duration: 0.35)) {
                                step = .persona
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRequestingPermissions {
                                ProgressView()
                                    .tint(LiltTheme.pureWhite)
                            } else {
                                Image(systemName: "mic.fill")
                                Text(String(localized: "Enable Voice & Continue"))
                                    .font(.headline.weight(.bold))
                            }
                        }
                        .foregroundColor(LiltTheme.pureWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LiltTheme.liltGradient, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: LiltTheme.liltCyan.opacity(0.4), radius: 12, y: 6)
                    }
                } else {
                    Button {
                        withAnimation(.easeInOut) {
                            currentSlide += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(String(localized: "Continue"))
                                .font(.headline.weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundColor(LiltTheme.pureWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LiltTheme.liltGradient, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Step 2: Optional Persona & Tuning
    private var personaStepView: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        step = .features
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "Back"))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LiltTheme.pearl.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: Capsule())
                }
                
                Spacer()
                
                Button {
                    completeOnboarding()
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LiltTheme.pearl.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            VStack(spacing: 6) {
                Text(String(localized: "Choose Your Companion"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(LiltTheme.pureWhite)
                
                Text(String(localized: "Select an initial persona. You can change this at any time."))
                    .font(.caption)
                    .foregroundColor(LiltTheme.pearl.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Personas List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Persona.presets) { p in
                        let isSel = voiceEngine.activePersona.id == p.id
                        Button {
                            voiceEngine.activePersona = p
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: p.icon)
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(isSel ? LiltTheme.pureWhite : LiltTheme.liltCyan)
                                    .frame(width: 38, height: 38)
                                    .background(isSel ? LiltTheme.liltGradient : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedStringKey(p.name))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(LiltTheme.pureWhite)
                                    Text(LocalizedStringKey(p.title))
                                        .font(.caption2)
                                        .foregroundColor(LiltTheme.pearl.opacity(0.7))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if isSel {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(LiltTheme.liltCyan)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSel ? LiltTheme.liltViolet.opacity(0.35) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSel ? LiltTheme.liltCyan : Color.white.opacity(0.1), lineWidth: isSel ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 2)
            }
            
            // Action Buttons: Start Voice or Open Chat
            VStack(spacing: 10) {
                Button {
                    completeOnboarding()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        voiceEngine.startCallSession()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                        Text(String(localized: "Start Hands-Free Voice Call"))
                            .font(.headline.weight(.bold))
                    }
                    .foregroundColor(LiltTheme.pureWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(LiltTheme.liltGradient, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: LiltTheme.liltCyan.opacity(0.4), radius: 12, y: 6)
                }
                
                Button {
                    completeOnboarding()
                } label: {
                    Text(String(localized: "Open Chat"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LiltTheme.pearl.opacity(0.8))
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Slide Builder
    @ViewBuilder
    private func featureSlide(
        tag: Int,
        icon: String,
        title: String,
        description: String,
        badges: [String]
    ) -> some View {
        VStack(spacing: 18) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LiltTheme.liltGradient.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: 16)
                
                Circle()
                    .fill(LiltTheme.orbGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: LiltTheme.liltViolet.opacity(0.5), radius: 20)
                
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(LiltTheme.pureWhite)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(LiltTheme.pureWhite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(LiltTheme.pearl.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            HStack(spacing: 6) {
                ForEach(badges, id: \.self) { badge in
                    Text(badge)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(LiltTheme.pureWhite)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
            }
            
            Spacer()
            Spacer()
        }
        .tag(tag)
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        withAnimation(.easeInOut(duration: 0.35)) {
            isPresented = false
        }
    }
}
