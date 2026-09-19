//
//  ConversationThread.swift
//  viLilt
//
//  Thread model for organizing voice & text dialogues
//

import Foundation
import SwiftData

@Model
public final class ConversationThread: Identifiable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var previewText: String
    public var selectedPersonaId: String
    
    @Relationship(deleteRule: .cascade)
    public var messages: [ChatMessage]
    
    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        previewText: String = "",
        selectedPersonaId: String = "companion",
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewText = previewText
        self.selectedPersonaId = selectedPersonaId
        self.messages = messages
    }
}
