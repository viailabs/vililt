//
//  TextChatView.swift
//  viLilt
//
//  Clean, distraction-free conversational chat with interactive keyboard dismissal and inline voice dock
//

import SwiftUI
import SwiftData

public struct TextChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConversationThread.updatedAt, order: .reverse) private var threads: [ConversationThread]
    
    @State private var currentThread: ConversationThread? = nil
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var isVoiceDockActive: Bool = false
    @State private var speechEngine = SpeechRecognitionEngine.shared
    @State private var voiceFeedback = VoiceFeedbackManager.shared
    @State private var modelManager = LLMModelManager.shared
    @State private var voiceEngine = VoiceConversationEngine.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let thread = currentThread {
                    messageScrollView(thread: thread)
                    
                    if isVoiceDockActive {
                        inlineVoiceDock(thread: thread)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    bottomInputBar(thread: thread)
                } else {
                    emptyWelcomeState
                }
            }
            .navigationTitle(currentThread?.title ?? String(localized: "viLilt Chat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        startNewDialogue()
                    } label: {
                        Image(systemName: "plus.bubble.fill")
                            .foregroundColor(LiltTheme.liltViolet)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleVoiceDock()
                    } label: {
                        Image(systemName: isVoiceDockActive ? "waveform.circle.fill" : "waveform.circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isVoiceDockActive ? LiltTheme.liltCyan : LiltTheme.liltViolet)
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isInputFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LiltTheme.liltViolet)
                    }
                }
            }
            .onAppear {
                if currentThread == nil, let first = threads.first {
                    currentThread = first
                }
                
                speechEngine.onTranscriptionComplete = { recognized in
                    handleVoiceTranscribed(recognized)
                }
            }
            .onDisappear {
                speechEngine.stopListening()
                voiceFeedback.stop()
            }
        }
    }
    
    // MARK: - Message List
    @ViewBuilder
    private func messageScrollView(thread: ConversationThread) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(thread.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .onChange(of: thread.messages.count) {
                if let last = thread.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Bubble
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if msg.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LiltTheme.pureWhite)
                    .frame(width: 28, height: 28)
                    .background(LiltTheme.liltGradient)
                    .clipShape(Circle())
            } else {
                Spacer()
            }
            
            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 6) {
                if !msg.content.isEmpty {
                    Text(msg.content)
                        .font(.body)
                        .foregroundColor(msg.role == .user ? LiltTheme.pureWhite : LiltTheme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(msg.role == .user ? LiltTheme.liltViolet : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Voice Listen / Stop Audio Pill for Assistant Bubbles
                if msg.role == .assistant && !msg.content.isEmpty {
                    let clean = VoiceFeedbackManager.sanitizeTextForVoice(msg.content)
                    let isPlayingThis = voiceFeedback.isSpeaking && voiceFeedback.currentSpokenText == clean
                    
                    HStack(spacing: 8) {
                        Button {
                            if isPlayingThis {
                                voiceFeedback.stop()
                            } else {
                                voiceFeedback.speak(msg.content)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: isPlayingThis ? "speaker.wave.3.fill" : "speaker.wave.2")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isPlayingThis ? String(localized: "Stop Voice") : String(localized: "Listen"))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isPlayingThis ? LiltTheme.liltCyan.opacity(0.18) : LiltTheme.liltViolet.opacity(0.08))
                            .foregroundColor(isPlayingThis ? LiltTheme.liltCyan : LiltTheme.liltViolet)
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: 320, alignment: msg.role == .user ? .trailing : .leading)
            
            if msg.role == .user {
                Image(systemName: "person.fill")
                    .font(.caption.weight(.bold))
                    .foregroundColor(LiltTheme.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            } else {
                Spacer()
            }
        }
    }
    
    // MARK: - Inline Voice Dock
    @ViewBuilder
    private func inlineVoiceDock(thread: ConversationThread) -> some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(speechEngine.isListening ? LiltTheme.liltCyan : LiltTheme.liltViolet)
                        .frame(width: 7, height: 7)
                    Text(speechEngine.isListening ? String(localized: "LISTENING...") : (voiceFeedback.isSpeaking ? String(localized: "SPEAKING") : String(localized: "VOICE ACTIVE")))
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(speechEngine.isListening ? LiltTheme.liltCyan : LiltTheme.liltViolet)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((speechEngine.isListening ? LiltTheme.liltCyan : LiltTheme.liltViolet).opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        speechEngine.stopListening()
                        voiceFeedback.stop()
                        isVoiceDockActive = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LiltTheme.secondaryText)
                }
            }
            
            // Audio Wave Visualizer
            if speechEngine.isListening || voiceFeedback.isSpeaking {
                HStack(spacing: 4) {
                    ForEach(0..<9) { idx in
                        let level = CGFloat(speechEngine.audioLevel)
                        let height = speechEngine.isListening ? max(4.0, level * 28.0 * CGFloat((idx % 3) + 1)) : 12.0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LiltTheme.liltGradient)
                            .frame(width: 4, height: height)
                            .animation(.easeOut(duration: 0.1), value: height)
                    }
                }
                .frame(height: 30)
            }
            
            // Transcription Preview
            if !speechEngine.transcribedText.isEmpty {
                Text("\"\(speechEngine.transcribedText)\"")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(LiltTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
            } else {
                Text(String(localized: "Listening for your voice..."))
                    .font(.caption)
                    .foregroundColor(LiltTheme.secondaryText)
            }
            
            // Inline Voice Controls
            HStack(spacing: 16) {
                Button {
                    toggleListening()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: speechEngine.isListening ? "stop.fill" : "mic.fill")
                        Text(speechEngine.isListening ? String(localized: "Stop & Send") : String(localized: "Speak"))
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(speechEngine.isListening ? Color.red.opacity(0.85) : LiltTheme.liltCyan)
                    .foregroundColor(LiltTheme.pureWhite)
                    .clipShape(Capsule())
                }
                
                if !speechEngine.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        let text = speechEngine.stopListening()
                        handleVoiceTranscribed(text)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text(String(localized: "Send Now"))
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LiltTheme.liltViolet)
                        .foregroundColor(LiltTheme.pureWhite)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LiltTheme.liltCyan.opacity(0.25), lineWidth: 1.5)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
    
    // MARK: - Bottom Input Bar
    @ViewBuilder
    private func bottomInputBar(thread: ConversationThread) -> some View {
        HStack(spacing: 8) {
            Button {
                toggleVoiceDock()
            } label: {
                Image(systemName: isVoiceDockActive ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundColor(isVoiceDockActive ? LiltTheme.liltCyan : LiltTheme.liltViolet)
            }
            
            TextField(String(localized: "Type a message or question..."), text: $inputText)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage(thread: thread)
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Button {
                sendMessage(thread: thread)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? LiltTheme.secondaryText : LiltTheme.liltViolet)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Welcome State
    @ViewBuilder
    private var emptyWelcomeState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(LiltTheme.liltGradient)
            
            Text(String(localized: "Welcome to viLilt"))
                .font(.title2.weight(.bold))
                .foregroundColor(LiltTheme.primaryText)
            
            Text(String(localized: "100% On-Device Neural Voice & Text AI Companion. Talk. Listen. Nothing else."))
                .font(.subheadline)
                .foregroundColor(LiltTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                startNewDialogue()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(String(localized: "Start New Dialogue"))
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(LiltTheme.liltViolet)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func toggleVoiceDock() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isVoiceDockActive.toggle()
            if isVoiceDockActive {
                startListening()
            } else {
                speechEngine.stopListening()
                voiceFeedback.stop()
            }
        }
    }
    
    private func toggleListening() {
        if speechEngine.isListening {
            let text = speechEngine.stopListening()
            handleVoiceTranscribed(text)
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        voiceFeedback.stop()
        Task {
            let granted = await speechEngine.requestPermissions()
            guard granted else { return }
            try? await speechEngine.startListening()
        }
    }
    
    private func handleVoiceTranscribed(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        guard let thread = currentThread else {
            startNewDialogue()
            if let first = currentThread {
                sendUserMessage(clean, thread: first)
            }
            return
        }
        sendUserMessage(clean, thread: thread)
    }
    
    private func sendMessage(thread: ConversationThread) {
        let clean = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        inputText = ""
        sendUserMessage(clean, thread: thread)
    }
    
    private func sendUserMessage(_ text: String, thread: ConversationThread) {
        let userMsg = ChatMessage(role: .user, content: text)
        thread.messages.append(userMsg)
        
        let assistantMsg = ChatMessage(role: .assistant, content: "", isStreaming: true)
        thread.messages.append(assistantMsg)
        thread.updatedAt = Date()
        thread.previewText = text
        try? modelContext.save()
        
        Task {
            var streamAccumulator = ""
            do {
                _ = try await modelManager.generateStream(
                    prompt: text,
                    persona: voiceEngine.activePersona,
                    conversationHistory: thread.messages
                ) { token in
                    streamAccumulator += token
                    Task { @MainActor in
                        assistantMsg.content = streamAccumulator
                    }
                }
                
                await MainActor.run {
                    assistantMsg.isStreaming = false
                    try? modelContext.save()
                    
                    if !streamAccumulator.isEmpty {
                        voiceFeedback.speak(streamAccumulator)
                    }
                }
            } catch {
                await MainActor.run {
                    assistantMsg.content = "Error: \(error.localizedDescription)"
                    assistantMsg.isStreaming = false
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func startNewDialogue() {
        let thread = ConversationThread()
        modelContext.insert(thread)
        try? modelContext.save()
        currentThread = thread
    }
}
