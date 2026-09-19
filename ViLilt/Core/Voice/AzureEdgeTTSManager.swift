//
//  AzureEdgeTTSManager.swift
//  viLilt
//
//  High-fidelity neural voice synthesis client with Edge TTS WebSocket protocol
//

import Foundation
import AVFoundation

public final class AzureEdgeTTSManager: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    public static let shared = AzureEdgeTTSManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioDataBuffer = Data()
    private var completionHandler: ((URL?) -> Void)?
    
    private override init() {
        super.init()
    }
    
    public static func voiceForLanguage(_ langCode: String) -> String {
        let lower = langCode.lowercased()
        if lower.contains("zh-hant") || lower.contains("tw") || lower.contains("hk") {
            return "zh-TW-HsiaoChenNeural"
        } else if lower.contains("zh-hans") || lower.contains("cn") || lower.hasPrefix("zh") {
            return "zh-CN-XiaoxiaoNeural"
        } else if lower.hasPrefix("ja") {
            return "ja-JP-NanamiNeural"
        } else if lower.hasPrefix("ko") {
            return "ko-KR-SunHiNeural"
        } else if lower.hasPrefix("es") {
            return "es-ES-ElviraNeural"
        } else if lower.hasPrefix("fr") {
            return "fr-FR-DeniseNeural"
        } else if lower.hasPrefix("de") {
            return "de-DE-KatjaNeural"
        } else if lower.hasPrefix("it") {
            return "it-IT-ElsaNeural"
        } else {
            return "en-US-JennyNeural"
        }
    }
    
    public func synthesize(text: String, voice: String, completion: @escaping (URL?) -> Void) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            completion(nil)
            return
        }
        
        self.completionHandler = completion
        self.audioDataBuffer = Data()
        
        let endpoint = "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=6A5AA1D4EAFF4E9FB37E23D68491D6F4"
        guard let url = URL(string: endpoint) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://app.speech.microsoft.com", forHTTPHeaderField: "Origin")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let ws = session.webSocketTask(with: request)
        self.webSocketTask = ws
        ws.resume()
        
        let ssml = """
        <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
            <voice name='\(voice)'>
                <prosody pitch='+0Hz' rate='+0%'>\(cleanText)</prosody>
            </voice>
        </speak>
        """
        
        let configMsg = "Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}"
        let requestMsg = "X-RequestId:\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n\(ssml)"
        
        ws.send(.string(configMsg)) { [weak self] error in
            if error != nil {
                self?.finishSynthesis(success: false)
                return
            }
            ws.send(.string(requestMsg)) { [weak self] err in
                if err != nil {
                    self?.finishSynthesis(success: false)
                } else {
                    self?.listenMessages()
                }
            }
        }
    }
    
    private func listenMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let str):
                    if str.contains("Path:turn.end") {
                        self.finishSynthesis(success: true)
                        return
                    }
                case .data(let data):
                    if let separatorRange = data.range(of: Data("Path:audio\r\n".utf8)) {
                        let audioBytes = data.subdata(in: separatorRange.upperBound..<data.count)
                        self.audioDataBuffer.append(audioBytes)
                    }
                @unknown default:
                    break
                }
                self.listenMessages()
            case .failure:
                self.finishSynthesis(success: false)
            }
        }
    }
    
    private func finishSynthesis(success: Bool) {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        guard success && !audioDataBuffer.isEmpty else {
            completionHandler?(nil)
            completionHandler = nil
            return
        }
        
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("viLilt_speech_\(UUID().uuidString).mp3")
        do {
            try audioDataBuffer.write(to: tempFile)
            completionHandler?(tempFile)
        } catch {
            completionHandler?(nil)
        }
        completionHandler = nil
    }
}
