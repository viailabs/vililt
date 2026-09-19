//
//  VoiceFeedbackManager.swift
//  viLilt
//
//  Centralized coordinator for TTS Voice Feedback, speech synthesis, and audio session management
//

import Foundation
import AVFoundation
import SwiftUI

@Observable
public final class VoiceFeedbackManager: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    public static let shared = VoiceFeedbackManager()
    
    public var isSpeaking: Bool = false
    public var currentSpokenText: String = ""
    public var onPlaybackComplete: (@Sendable () -> Void)?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    public static func sanitizeTextForVoice(_ text: String) -> String {
        var sanitized = text
        sanitized = sanitized.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "<think>[\\s\\S]*", with: "", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "```[\\s\\S]*?```", with: "", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "`[^`]*`", with: "", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "[*#_~]", with: "", options: .regularExpression)
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func speak(_ text: String, onFinished: (@Sendable () -> Void)? = nil) {
        let cleanText = Self.sanitizeTextForVoice(text)
        guard !cleanText.isEmpty else {
            onFinished?()
            return
        }
        
        let feedbackEnabled = UserDefaults.standard.object(forKey: "voice_feedback_enabled") as? Bool ?? true
        guard feedbackEnabled else {
            onFinished?()
            return
        }
        
        stop()
        self.onPlaybackComplete = onFinished
        self.isSpeaking = true
        self.currentSpokenText = cleanText
        
        let activeLanguage = LanguageManager.shared.effectiveLanguage
        let edgeVoice = AzureEdgeTTSManager.voiceForLanguage(activeLanguage)
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        AzureEdgeTTSManager.shared.synthesize(text: cleanText, voice: edgeVoice) { [weak self] url in
            guard let self = self else { return }
            if let url = url {
                AudioPlayer.shared.onPlaybackFinished = { [weak self] in
                    Task { @MainActor in
                        self?.isSpeaking = false
                        self?.currentSpokenText = ""
                        self?.onPlaybackComplete?()
                    }
                }
                AudioPlayer.shared.play(url: url)
            } else {
                self.speakWithAVSpeech(text: cleanText, langCode: activeLanguage)
            }
        }
    }
    
    private func speakWithAVSpeech(text: String, langCode: String) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: langCode) ?? AVSpeechSynthesisVoice(language: "en-US")
        
        let storedRate = UserDefaults.standard.double(forKey: "voice_speech_rate")
        let effectiveRate = storedRate > 0 ? Float(storedRate) : AVSpeechUtteranceDefaultSpeechRate
        utterance.rate = effectiveRate
        utterance.pitchMultiplier = 1.0
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        speechSynthesizer.speak(utterance)
    }
    
    public func stop() {
        AudioPlayer.shared.halt()
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentSpokenText = ""
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentSpokenText = ""
            self.onPlaybackComplete?()
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentSpokenText = ""
            self.onPlaybackComplete?()
        }
    }
}
