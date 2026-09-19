//
//  ModelCatalog.swift
//  viLilt
//
//  Catalog of lightweight, high-performance on-device conversational models
//

import Foundation

public struct ModelMetadata: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let parameterCount: String
    public let quantization: String
    public let downloadSizeMB: Int
    public let memoryRequirementMB: Int
    public let downloadURL: URL?
    public let description: String
    public let isDefault: Bool
    
    public init(
        id: String,
        displayName: String,
        parameterCount: String,
        quantization: String,
        downloadSizeMB: Int,
        memoryRequirementMB: Int,
        downloadURL: URL?,
        description: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.parameterCount = parameterCount
        self.quantization = quantization
        self.downloadSizeMB = downloadSizeMB
        self.memoryRequirementMB = memoryRequirementMB
        self.downloadURL = downloadURL
        self.description = description
        self.isDefault = isDefault
    }
}

public struct ModelCatalog {
    public static let availableModels: [ModelMetadata] = [
        ModelMetadata(
            id: "qwen2.5-0.5b-instruct-q4_k_m",
            displayName: "Qwen 2.5 0.5B (Ultra-Fast)",
            parameterCount: "0.5B",
            quantization: "Q4_K_M",
            downloadSizeMB: 390,
            memoryRequirementMB: 650,
            downloadURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"),
            description: "Instantaneous conversational response time with ultra-low battery consumption. Perfect for voice talk.",
            isDefault: true
        ),
        ModelMetadata(
            id: "qwen2.5-1.5b-instruct-q4_k_m",
            displayName: "Qwen 2.5 1.5B (Balanced)",
            parameterCount: "1.5B",
            quantization: "Q4_K_M",
            downloadSizeMB: 980,
            memoryRequirementMB: 1400,
            downloadURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"),
            description: "Outstanding multi-lingual dialogue, empathy, and fluent everyday conversation."
        ),
        ModelMetadata(
            id: "llama-3.2-1b-instruct-q4_k_m",
            displayName: "Llama 3.2 1B (Instruct)",
            parameterCount: "1.0B",
            quantization: "Q4_K_M",
            downloadSizeMB: 780,
            memoryRequirementMB: 1100,
            downloadURL: URL(string: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"),
            description: "Meta's state-of-the-art compact conversational model with strong English & reasoning skills."
        ),
        ModelMetadata(
            id: "qwen2.5-3b-instruct-q4_k_m",
            displayName: "Qwen 2.5 3B (Pro Conversational)",
            parameterCount: "3.0B",
            quantization: "Q4_K_M",
            downloadSizeMB: 1950,
            memoryRequirementMB: 2600,
            downloadURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"),
            description: "Rich depth, nuanced persona roleplay, philosophy, and advanced language practice partner."
        )
    ]
    
    public static var defaultModel: ModelMetadata {
        availableModels.first(where: { $0.isDefault }) ?? availableModels[0]
    }
}
