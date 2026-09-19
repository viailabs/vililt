//
//  VoiceConversationEngine.swift
//  viLilt
//
//  Hands-free continuous bidirectional voice loop coordinator
//

import Foundation
import SwiftUI
import SwiftData

@Observable
public final class VoiceConversationEngine: @unchecked Sendable {
    public static let shared = VoiceConversationEngine()
    
    public enum State: Sendable {
        case idle
        case listening
        case thinking
        case speaking
        case paused
    }
    
    public var state: State = .idle
    public var liveUserUtterance: String = ""
    public var liveAssistantReply: String = ""
    public var activePersona: Persona = Persona.defaultPersona
    public var isHandsFreeMode: Bool = true
    
    private let speechEngine = SpeechRecognitionEngine.shared
    private let voiceFeedback = VoiceFeedbackManager.shared
    private let modelManager = LLMModelManager.shared
    
    private init() {
        speechEngine.onTranscriptionComplete = { [weak self] text in
            Task { @MainActor [weak self] in
                self?.handleUserSpeechCompleted(text)
            }
        }
        
        speechEngine.onPartialTranscription = { [weak self] partial in
            Task { @MainActor [weak self] in
                self?.liveUserUtterance = partial
            }
        }
    }
    
    public func startCallSession() {
        state = .listening
        liveUserUtterance = ""
        liveAssistantReply = ""
        voiceFeedback.stop()
        
        Task {
            let granted = await speechEngine.requestPermissions()
            guard granted else {
                await MainActor.run { self.state = .idle }
                return
            }
            do {
                try await speechEngine.startListening()
            } catch {
                await MainActor.run { self.state = .idle }
            }
        }
    }
    
    public func endCallSession() {
        speechEngine.stopListening()
        voiceFeedback.stop()
        state = .idle
        liveUserUtterance = ""
        liveAssistantReply = ""
    }
    
    public func interrupt() {
        if state == .speaking {
            voiceFeedback.stop()
            if isHandsFreeMode {
                startCallSession()
            } else {
                state = .idle
            }
        }
    }
    
    private func handleUserSpeechCompleted(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            if isHandsFreeMode && state == .listening {
                startCallSession()
            }
            return
        }
        
        state = .thinking
        liveUserUtterance = clean
        liveAssistantReply = ""
        
        Task {
            var replyBuffer = ""
            do {
                _ = try await modelManager.generateStream(
                    prompt: clean,
                    persona: activePersona,
                    conversationHistory: []
                ) { token in
                    replyBuffer += token
                    Task { @MainActor in
                        self.liveAssistantReply = replyBuffer
                    }
                }
                
                await MainActor.run {
                    self.state = .speaking
                    self.voiceFeedback.speak(replyBuffer) { [weak self] in
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            if self.isHandsFreeMode && self.state != .idle {
                                self.startCallSession()
                            } else {
                                self.state = .idle
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .idle
                }
            }
        }
    }
}
