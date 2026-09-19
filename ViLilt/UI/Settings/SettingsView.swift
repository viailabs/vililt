//
//  SettingsView.swift
//  viLilt
//
//  Settings, on-device model selection, voice speed, and language options
//

import SwiftUI

public struct SettingsView: View {
    @State private var modelManager = LLMModelManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("voice_feedback_enabled") private var voiceFeedbackEnabled = true
    @AppStorage("voice_speech_rate") private var voiceSpeechRate = 0.52
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Section: Local Intelligence Model
                Section(LocalizedStringKey("On-Device Model")) {
                    Picker(LocalizedStringKey("Active Model"), selection: Binding(
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
                    
                    Text(LocalizedStringKey(modelManager.selectedModel.description))
                        .font(.caption)
                        .foregroundColor(LiltTheme.secondaryText)
                }
                
                // Section: Voice & Speech
                Section(LocalizedStringKey("Voice & Speech")) {
                    Toggle(isOn: $voiceFeedbackEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey("Automatic Voice Feedback"))
                                .font(.headline)
                            Text(LocalizedStringKey("Speak replies aloud using high-fidelity neural TTS."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                    .tint(LiltTheme.liltViolet)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStringKey("Speaking Rate"))
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
                Section(LocalizedStringKey("Language")) {
                    Picker(LocalizedStringKey("App & Voice Language"), selection: Binding(
                        get: { languageManager.currentLanguage },
                        set: { newLang in
                            languageManager.setLanguage(newLang)
                        }
                    )) {
                        ForEach(LanguageManager.availableLanguages) { opt in
                            Text("\(opt.displayName) (\(opt.localizedName(in: languageManager.locale)))").tag(opt.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(LiltTheme.liltViolet)
                }
                
                // Section: Zero Cloud Guarantee
                Section(LocalizedStringKey("Privacy & Zero Cloud Guarantee")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(LiltTheme.liltCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey("100% On-Device Execution"))
                                .font(.subheadline.weight(.semibold))
                            Text(LocalizedStringKey("Zero cloud telemetry, zero remote servers, complete privacy."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "creditcard.slash.fill")
                            .foregroundColor(LiltTheme.liltCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey("100% Free Forever"))
                                .font(.subheadline.weight(.semibold))
                            Text(LocalizedStringKey("No mandatory subscriptions or API token charges."))
                                .font(.caption)
                                .foregroundColor(LiltTheme.secondaryText)
                        }
                    }
                }
                
                // Section: About
                Section(LocalizedStringKey("About")) {
                    HStack {
                        Text(LocalizedStringKey("Version"))
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(LocalizedStringKey("Family"))
                        Spacer()
                        Text(LocalizedStringKey("VI Intelligence Ecosystem"))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Settings"))
        }
    }
}
