//
//  SettingsView.swift
//  viLilt
//
//  Settings, on-device model selection, voice speed, and language options
//

import SwiftUI

public struct SettingsView: View {
    @State private var modelManager = LLMModelManager.shared
    @State private var languageManager = LanguageManager.shared
    @AppStorage("voice_feedback_enabled") private var voiceFeedbackEnabled = true
    @AppStorage("voice_speech_rate") private var voiceSpeechRate = 0.52
    @State private var showRestartAlert: Bool = false
    @State private var pendingLang: String = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Section: Local Intelligence Model
                Section(String(localized: "On-Device Model")) {
                    Picker(String(localized: "Active Model"), selection: Binding(
                        get: { modelManager.selectedModel.id },
                        set: { newId in
                            if let found = ModelCatalog.availableModels.first(where: { $0.id == newId }) {
                                modelManager.selectModel(found)
                            }
                        }
                    )) {
                        ForEach(ModelCatalog.availableModels) { model in
                            Text("\(model.displayName) (\(model.parameterCount))").tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(LiltTheme.liltViolet)
                    
                    Text(modelManager.selectedModel.description)
                        .font(.caption)
                        .foregroundColor(LiltTheme.secondaryText)
                }
                
                // Section: Voice & Speech
                Section(String(localized: "Voice & Speech")) {
                    Toggle(isOn: $voiceFeedbackEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Automatic Voice Feedback"))
                                .font(.headline)
                            Text(String(localized: "Speak replies aloud using high-fidelity neural TTS."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                    .tint(LiltTheme.liltViolet)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "Speaking Rate"))
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.2fx", voiceSpeechRate * 2))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                        Slider(value: $voiceSpeechRate, in: 0.25...0.75, step: 0.05)
                            .tint(LiltTheme.liltViolet)
                    }
                }
                
                // Section: Language
                Section(String(localized: "Language")) {
                    Picker(String(localized: "App & Voice Language"), selection: Binding(
                        get: { languageManager.currentLanguage },
                        set: { newLang in
                            if newLang != languageManager.currentLanguage {
                                pendingLang = newLang
                                showRestartAlert = true
                            }
                        }
                    )) {
                        ForEach(LanguageManager.availableLanguages) { opt in
                            Text(opt.displayName).tag(opt.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(LiltTheme.liltViolet)
                }
                
                // Section: Zero Cloud Guarantee
                Section(String(localized: "Privacy & Zero Cloud Guarantee")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(LiltTheme.liltCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "100% On-Device Execution"))
                                .font(.subheadline.weight(.semibold))
                            Text(String(localized: "Zero cloud telemetry, zero remote servers, complete privacy."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "creditcard.slash.fill")
                            .foregroundColor(LiltTheme.liltCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "100% Free Forever"))
                                .font(.subheadline.weight(.semibold))
                            Text(String(localized: "No mandatory subscriptions or API token charges."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                }
                
                // Section: About
                Section(String(localized: "About")) {
                    HStack {
                        Text(String(localized: "Version"))
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "Family"))
                        Spacer()
                        Text("VI Intelligence Ecosystem")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .alert(String(localized: "Restart Required"), isPresented: $showRestartAlert) {
                Button(String(localized: "Cancel"), role: .cancel) {
                    pendingLang = ""
                }
                Button(String(localized: "Apply & Restart")) {
                    languageManager.setLanguage(pendingLang)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        exit(0)
                    }
                }
            } message: {
                Text(String(localized: "Changing the app language requires a restart. Your dialogue threads will be preserved."))
            }
        }
    }
}
