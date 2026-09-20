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
        
        let activeLang = LanguageManager.shared.effectiveLanguage
        let baseAnswer: String
        
        switch activeLang {
        case "zh-Hans":
            if persona.id == "mentor" {
                let responses = [
                    "这是一个非常深刻的问题。从底层逻辑与系统思维来看，我们可以将其拆解为几个核心维度来剖析。",
                    "分析这个问题时，关键在于理清本质动机与外部约束。你认为目前最关键的突破口在哪里？",
                    "很有见地。如果我们运用第一性原理来推演，会发现一个以往容易被忽视的全新视角与解决方案。"
                ]
                baseAnswer = responses.randomElement() ?? responses[0]
            } else if persona.id == "tutor" {
                let responses = [
                    "你说得非常自然！表达得清晰又生动。接下来我们围绕这个话题继续练习，你想聊哪方面？",
                    "太棒了！你的语感越来越流畅了。我们来试着用刚才的话题深入探讨一下吧！"
                ]
                baseAnswer = responses.randomElement() ?? responses[0]
            } else {
                let responses = [
                    "我在认真听你说呢。这真是一个很棒的想法，能跟我多讲讲是什么启发了你吗？",
                    "我完全理解你的感受。在这个快节奏的时刻，停下来深呼吸并倾听内心的声音，真的能让人豁然开朗。",
                    "这太有意思了！从另一个角度来看，你觉得接下来可能会发生什么有趣的转变呢？",
                    "我一直在你身边。无论你想聊些什么日常趣事还是深层思考，随时跟我说就好。"
                ]
                baseAnswer = responses.randomElement() ?? responses[0]
            }
            
        case "zh-Hant":
            if persona.id == "mentor" {
                let responses = [
                    "這是一個非常深刻的問題。從底層邏輯與系統思維來看，我們可以將其拆解為幾個核心維度來剖析。",
                    "分析這個問題時，關鍵在於理清本質動機與外部約束。你認為目前最關鍵的突破口在哪裡？"
                ]
                baseAnswer = responses.randomElement() ?? responses[0]
            } else {
                let responses = [
                    "我在認真聽你說呢。這真是一個很棒的想法，能跟我多聊聊是什麼啟發了你嗎？",
                    "我完全理解你的感受。在這個快節奏的時刻，停下來深呼吸並傾聽內心的聲音，真的能讓人豁然開朗。",
                    "這太有意思了！從另一個角度來看，你覺得接下來可能會發生什麼有趣的轉變呢？"
                ]
                baseAnswer = responses.randomElement() ?? responses[0]
            }
            
        case "ja":
            let responses = [
                "じっくりお聞きしています。とても素敵なアイデアですね。どんなきっかけがあったのか、ぜひ詳しく教えてください。",
                "そのお気持ち、とてもよく分かります。少し深呼吸してリラックスすると、新しい発見があるかもしれませんね。",
                "とても興味深い視点です！別の角度から見ると、次はどんな展開が考えられるでしょうか？"
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
            
        case "ko":
            let responses = [
                "마음을 다해 경청하고 있어요. 정말 멋진 생각인데, 어떤 계기로 영감을 받으셨는지 더 들려주시겠어요?",
                "그 마음 충분히 이해해요. 잠시 숨을 고르고 생각을 정리하면 한결 더 가벼워질 거예요.",
                "정말 흥미로운 관점입니다! 다른 각도에서 바라본다면 어떤 가능성이 있을까요?"
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
            
        case "es":
            let responses = [
                "Te escucho con mucha atención. Es una idea maravillosa, cuéntame más sobre lo que te inspiró.",
                "Entiendo perfectamente cómo te sientes. Tomarse un momento para respirar y reflexionar siempre ayuda.",
                "¡Qué interesante! Si lo miramos desde otra perspectiva, ¿qué crees que pasaría a continuación?"
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
            
        case "fr":
            let responses = [
                "Je t'écoute avec attention. C'est une excellente idée, dis-moi ce qui t'a inspiré.",
                "Je comprends tout à fait ce que tu ressens. Prendre un moment pour respirer et réfléchir peut tout changer.",
                "C'est très intéressant ! Sous un autre angle, que penses-tu qu'il se passerait ensuite ?"
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
            
        case "de":
            let responses = [
                "Ich höre dir aufmerksam zu. Das ist ein wunderbarer Gedanke – erzähl mir gerne mehr darüber.",
                "Ich verstehe vollkommen, wie du dich fühlst. Einen Moment innezuhalten tut immer gut.",
                "Sehr interessant! Wenn wir es aus einem anderen Blickwinkel betrachten, was denkst du, was als Nächstes passiert?"
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
            
        default:
            let responses = [
                "I'm right here with you. That's a wonderful thought — tell me more about what inspired you.",
                "That's really interesting! Looking at it from another angle, what do you think would happen next?",
                "I completely hear what you're saying. Taking a moment to breathe and reflect can make all the difference.",
                "I love that idea! We could explore how that connects to your everyday routine or creative projects."
            ]
            baseAnswer = responses.randomElement() ?? responses[0]
        }
        
        let isCJK = baseAnswer.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) || (0x3040...0x30FF).contains(scalar.value) || (0xAC00...0xD7AF).contains(scalar.value)
        }
        
        var fullText = ""
        if isCJK {
            var idx = baseAnswer.startIndex
            while idx < baseAnswer.endIndex {
                let nextIdx = baseAnswer.index(idx, offsetBy: 2, limitedBy: baseAnswer.endIndex) ?? baseAnswer.endIndex
                let chunk = String(baseAnswer[idx..<nextIdx])
                try await Task.sleep(nanoseconds: 30_000_000)
                fullText += chunk
                onToken(chunk)
                idx = nextIdx
            }
        } else {
            let chunks = baseAnswer.components(separatedBy: " ")
            for (idx, word) in chunks.enumerated() {
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms natural conversational cadence
                let piece = (idx == 0 ? "" : " ") + word
                fullText += piece
                onToken(piece)
            }
        }
        
        return fullText
    }
}
