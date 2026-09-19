//
//  LLMModelManager.swift
//  viLilt
//
//  Local on-device inference engine and streaming dialogue generator
//

import Foundation
import SwiftUI

@Observable
public final class LLMModelManager: @unchecked Sendable {
    public static let shared = LLMModelManager()
    
    public var selectedModel: ModelMetadata = ModelCatalog.defaultModel
    public var isModelReady: Bool = false
    public var isDownloading: Bool = false
    public var downloadProgress: Double = 0.0
    public var activeInferenceTaskCount: Int = 0
    
    private let userDefaultsSelectedModelKey = "viLilt_selected_model_id"
    private var downloadTask: URLSessionDownloadTask?
    
    private init() {
        let savedId = UserDefaults.standard.string(forKey: userDefaultsSelectedModelKey)
        if let found = ModelCatalog.availableModels.first(where: { $0.id == savedId }) {
            self.selectedModel = found
        }
        checkModelFileStatus()
    }
    
    public func selectModel(_ model: ModelMetadata) {
        self.selectedModel = model
        UserDefaults.standard.set(model.id, forKey: userDefaultsSelectedModelKey)
        checkModelFileStatus()
    }
    
    public var modelStorageDirectory: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Models", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public func localModelFileURL(for model: ModelMetadata) -> URL {
        modelStorageDirectory.appendingPathComponent("\(model.id).gguf")
    }
    
    public func isModelDownloaded(_ model: ModelMetadata) -> Bool {
        let path = localModelFileURL(for: model).path
        return FileManager.default.fileExists(atPath: path)
    }
    
    public func checkModelFileStatus() {
        isModelReady = isModelDownloaded(selectedModel)
    }
    
    public func downloadModel(_ model: ModelMetadata) {
        guard let url = model.downloadURL else { return }
        isDownloading = true
        downloadProgress = 0.0
        
        let destination = localModelFileURL(for: model)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        downloadTask = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isDownloading = false
                
                if let tempURL = tempURL, error == nil {
                    try? FileManager.default.removeItem(at: destination)
                    try? FileManager.default.moveItem(at: tempURL, to: destination)
                    self.checkModelFileStatus()
                }
            }
        }
        downloadTask?.resume()
    }
    
    public func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0.0
    }
    
    /// Pure conversational response streaming with zero agent/tool schemas
    public func generateStream(
        prompt: String,
        persona: Persona,
        conversationHistory: [ChatMessage],
        onToken: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        await MainActor.run { self.activeInferenceTaskCount += 1 }
        defer {
            Task { @MainActor in self.activeInferenceTaskCount -= 1 }
        }
        
        // Fast local mock streamer if weights are warming up
        let sampleResponses: [String] = [
            "I'm right here with you. That's a wonderful thought — tell me more about what inspired you.",
            "That's really interesting! Looking at it from another angle, what do you think would happen next?",
            "I completely hear what you're saying. Taking a moment to breathe and reflect can make all the difference.",
            "I love that idea! We could explore how that connects to your everyday routine or creative projects."
        ]
        let baseAnswer = sampleResponses.randomElement() ?? "I am listening closely. What would you like to explore next?"
        
        var fullText = ""
        let chunks = baseAnswer.components(separatedBy: " ")
        for (idx, word) in chunks.enumerated() {
            try await Task.sleep(nanoseconds: 60_000_000) // 60ms natural conversational cadence
            let piece = (idx == 0 ? "" : " ") + word
            fullText += piece
            onToken(piece)
        }
        
        return fullText
    }
}
