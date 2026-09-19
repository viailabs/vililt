//
//  SpeechRecognitionEngine.swift
//  viLilt
//
//  100% On-Device & Neural Speech-to-Text (STT) engine with intelligent sentence boundary detection
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

@Observable
public final class SpeechRecognitionEngine: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    public static let shared = SpeechRecognitionEngine()
    
    public var isListening: Bool = false
    public var transcribedText: String = ""
    public var audioLevel: Float = 0.0
    public var permissionStatus: PermissionStatus = .notDetermined
    public var errorMessage: String? = nil
    
    public var onPartialTranscription: (@Sendable (String) -> Void)?
    public var onTranscriptionComplete: (@Sendable (String) -> Void)?
    
    public enum PermissionStatus: Sendable {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var isTapInstalled: Bool = false
    
    public var currentLocale: Locale {
        let lang = LanguageManager.shared.effectiveLanguage
        let lower = lang.lowercased()
        if lower.contains("zh-hant") || lower.contains("tw") || lower.contains("hk") {
            return Locale(identifier: "zh-TW")
        } else if lower.contains("zh-hans") || lower.contains("cn") || lower.hasPrefix("zh") {
            return Locale(identifier: "zh-CN")
        } else if lower.hasPrefix("ja") {
            return Locale(identifier: "ja-JP")
        } else if lower.hasPrefix("ko") {
            return Locale(identifier: "ko-KR")
        } else if lower.hasPrefix("es") {
            return Locale(identifier: "es-ES")
        } else if lower.hasPrefix("fr") {
            return Locale(identifier: "fr-FR")
        } else if lower.hasPrefix("de") {
            return Locale(identifier: "de-DE")
        } else if lower.hasPrefix("it") {
            return Locale(identifier: "it-IT")
        } else if lower.hasPrefix("vi") {
            return Locale(identifier: "vi-VN")
        } else if lower.hasPrefix("pt") {
            return Locale(identifier: "pt-BR")
        } else {
            return Locale(identifier: "en-US")
        }
    }
    
    private override init() {
        super.init()
        updateSpeechRecognizer()
        setupAudioSessionObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioSessionObservers() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopListening()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("LanguageChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSpeechRecognizer()
        }
    }
    
    public func updateSpeechRecognizer() {
        let targetLocale = currentLocale
        speechRecognizer = SFSpeechRecognizer(locale: targetLocale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    public func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
            await MainActor.run {
                self.permissionStatus = speechStatus == .denied ? .denied : .restricted
                self.errorMessage = "Speech recognition permission is required for voice conversation."
            }
            return false
        }
        
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        
        await MainActor.run {
            if micGranted {
                self.permissionStatus = .authorized
                self.errorMessage = nil
            } else {
                self.permissionStatus = .denied
                self.errorMessage = "Microphone permission is required for voice conversation."
            }
        }
        
        return micGranted
    }
    
    public func startListening() async throws {
        stopListening()
        updateSpeechRecognizer()
        
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            throw NSError(domain: "ViLilt.Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone or Speech Recognition permission denied"])
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "ViLilt.Speech", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available"])
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        self.recognitionRequest = request
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw NSError(domain: "ViLilt.Speech", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid audio hardware format"])
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard buffer.frameLength > 0 else { return }
            self?.recognitionRequest?.append(buffer)
            self?.calculateAudioLevel(buffer: buffer)
        }
        self.isTapInstalled = true
        
        do {
            engine.prepare()
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            self.isTapInstalled = false
            self.audioEngine = nil
            self.recognitionRequest = nil
            throw error
        }
        
        await MainActor.run {
            self.isListening = true
            self.transcribedText = ""
            self.errorMessage = nil
        }
        
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcribedText = transcription
                    self.onPartialTranscription?(transcription)
                    
                    if result.isFinal {
                        let final = self.stopListening()
                        self.onTranscriptionComplete?(final)
                    } else {
                        self.resetSilenceTimer(for: transcription)
                    }
                }
            }
            
            if let error = error {
                Task { @MainActor in
                    let nsErr = error as NSError
                    if nsErr.code != 216 && nsErr.code != 1 && nsErr.code != 203 && nsErr.code != 209 && nsErr.code != 211 {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func resetSilenceTimer(for text: String) {
        silenceTimer?.invalidate()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let isSentenceEnd = trimmed.hasSuffix(".") || trimmed.hasSuffix("?") || trimmed.hasSuffix("!") ||
                            trimmed.hasSuffix("。") || trimmed.hasSuffix("？") || trimmed.hasSuffix("！")
        let pauseDuration: TimeInterval = isSentenceEnd ? 1.5 : 2.2
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: pauseDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isListening, !self.transcribedText.isEmpty else { return }
                let finalText = self.stopListening()
                self.onTranscriptionComplete?(finalText)
            }
        }
    }
    
    @discardableResult
    public func stopListening() -> String {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            if isTapInstalled {
                engine.inputNode.removeTap(onBus: 0)
                isTapInstalled = false
            }
        }
        audioEngine = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let result = transcribedText
        Task { @MainActor in
            self.isListening = false
            self.audioLevel = 0.0
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return result
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard buffer.frameLength > 0, let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        
        var sum: Float = 0.0
        for sample in channelDataArray {
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameCount))
        let normalized = min(1.0, max(0.0, rms * 5.0))
        
        Task { @MainActor in
            self.audioLevel = normalized
        }
    }
}
