//
//  AzureEdgeTTSManager.swift
//  viLilt
//
//  High-fidelity Neural Text-to-Speech using Edge Read Aloud WebSocket endpoint.
//  Zero API keys required, zero dummy synthesizer sounds.
//

import Foundation
import AVFoundation
import CommonCrypto

public final class AzureEdgeTTSManager: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    public static let shared = AzureEdgeTTSManager()
    private override init() { super.init() }
    
    // MARK: - Protocol Constants
    private let trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
    private let chromiumVersion = "143.0.3650.75"
    private let defaultVoice = "en-US-EmmaMultilingualNeural"
    
    private var wssBaseURL: String {
        "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1"
    }
    
    private var cache: [String: URL] = [:]
    
    // MARK: - Public API
    
    /// Synthesize `text` into high-quality neural speech audio (MP3).
    public func synthesize(text: String, voice: String? = nil, rate: String = "+0%", completion: @escaping @Sendable (URL?) -> Void) {
        let selectedVoice = voice ?? defaultVoice
        let cacheKey = "\(text)_\(selectedVoice)_\(rate)"
        
        if let cachedURL = cache[cacheKey], FileManager.default.fileExists(atPath: cachedURL.path) {
            DispatchQueue.main.async { completion(cachedURL) }
            return
        }
        
        Task {
            do {
                let url = try await synthesizeAsync(text: text, voice: selectedVoice, rate: rate)
                self.cache[cacheKey] = url
                await MainActor.run { completion(url) }
            } catch {
                print("🔊 [viLilt EdgeTTS] Synthesis failed: \(error)")
                await MainActor.run { completion(nil) }
            }
        }
    }
    
    // MARK: - Async WebSocket Implementation
    private func synthesizeAsync(text: String, voice: String, rate: String) async throws -> URL {
        let connectionId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let secMsGec = generateSecMsGec()
        let secMsGecVersion = "1-\(chromiumVersion)"
        
        let urlString = "\(wssBaseURL)?TrustedClientToken=\(trustedClientToken)&ConnectionId=\(connectionId)&Sec-MS-GEC=\(secMsGec)&Sec-MS-GEC-Version=\(secMsGecVersion)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ViLilt.EdgeTTS", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        let majorVersion = chromiumVersion.components(separatedBy: ".").first ?? "143"
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/\(majorVersion).0.0.0 Safari/537.36 Edg/\(majorVersion).0.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold", forHTTPHeaderField: "Origin")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let wsTask = session.webSocketTask(with: request)
        wsTask.resume()
        
        defer {
            wsTask.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
        }
        
        // 1. Send speech.config
        let configMessage = buildConfigMessage()
        try await wsTask.send(.string(configMessage))
        
        // 2. Send SSML request
        let ssmlMessage = buildSSMLMessage(text: text, voice: voice, rate: rate, requestId: connectionId)
        try await wsTask.send(.string(ssmlMessage))
        
        // 3. Receive audio data
        var audioData = Data()
        var receivedAudio = false
        
        while true {
            let message: URLSessionWebSocketTask.Message
            do {
                message = try await wsTask.receive()
            } catch {
                if receivedAudio { break }
                throw NSError(domain: "ViLilt.EdgeTTS", code: 2, userInfo: [NSLocalizedDescriptionKey: "Connection closed"])
            }
            
            switch message {
            case .string(let text):
                if text.contains("Path:turn.end") {
                    break
                }
                continue
                
            case .data(let data):
                guard data.count >= 2 else { continue }
                let headerLength = Int(data[0]) << 8 | Int(data[1])
                guard headerLength + 2 <= data.count else { continue }
                
                let headerData = data[2..<(2 + headerLength)]
                if let headerStr = String(data: headerData, encoding: .utf8),
                   headerStr.contains("Path:audio") {
                    let audioChunk = data[(2 + headerLength)...]
                    if !audioChunk.isEmpty {
                        audioData.append(audioChunk)
                        receivedAudio = true
                    }
                }
                
            @unknown default:
                continue
            }
            
            if case .string(let text) = message, text.contains("Path:turn.end") {
                break
            }
        }
        
        guard receivedAudio, !audioData.isEmpty else {
            throw NSError(domain: "ViLilt.EdgeTTS", code: 3, userInfo: [NSLocalizedDescriptionKey: "No audio received"])
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vililt_tts_\(UUID().uuidString)")
            .appendingPathExtension("mp3")
        try audioData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Message Construction
    private func buildConfigMessage() -> String {
        let timestamp = dateToString()
        return """
        X-Timestamp:\(timestamp)\r
        Content-Type:application/json; charset=utf-8\r
        Path:speech.config\r
        \r
        {"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}
        """.trimmingCharacters(in: .whitespaces)
    }
    
    private func buildSSMLMessage(text: String, voice: String, rate: String, requestId: String) -> String {
        let timestamp = dateToString()
        let escapedText = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
        
        let ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='\(voice)'><prosody pitch='+0Hz' rate='\(rate)' volume='+0%'>\(escapedText)</prosody></voice></speak>"
        return "X-RequestId:\(requestId)\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:\(timestamp)Z\r\nPath:ssml\r\n\r\n\(ssml)"
    }
    
    private func generateSecMsGec() -> String {
        let winEpoch: Double = 11644473600
        var ticks = Date().timeIntervalSince1970
        ticks += winEpoch
        ticks -= ticks.truncatingRemainder(dividingBy: 300)
        ticks *= 1e9 / 100
        
        let strToHash = String(format: "%.0f", ticks) + trustedClientToken
        guard let data = strToHash.data(using: .ascii) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02X", $0) }.joined()
    }
    
    private func dateToString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss"
        return formatter.string(from: Date()) + " GMT+0000 (Coordinated Universal Time)"
    }
    
    // MARK: - Voice Mapping
    public static func voiceForLanguage(_ langCode: String) -> String {
        switch langCode {
        case "zh-Hans", "zh_CN", "zh-CN":
            return "zh-CN-XiaoxiaoNeural"
        case "zh-Hant", "zh_TW", "zh-TW", "zh-HK":
            return "zh-TW-HsiaoChenNeural"
        case "ja":
            return "ja-JP-NanamiNeural"
        case "ko":
            return "ko-KR-SunHiNeural"
        case "es":
            return "es-ES-ElviraNeural"
        case "fr":
            return "fr-FR-DeniseNeural"
        case "de":
            return "de-DE-KatjaNeural"
        case "it":
            return "it-IT-ElsaNeural"
        case "vi":
            return "vi-VN-HoaiMyNeural"
        case "pt":
            return "pt-BR-FranciscaNeural"
        default:
            return "en-US-EmmaMultilingualNeural"
        }
    }
}
