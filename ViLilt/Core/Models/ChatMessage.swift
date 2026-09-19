//
//  ChatMessage.swift
//  viLilt
//
//  Lightweight SwiftData model for conversational messages
//

import Foundation
import SwiftData

public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

@Model
public final class ChatMessage: Identifiable {
    public var id: UUID
    public var roleRaw: String
    public var content: String
    public var createdAt: Date
    public var isStreaming: Bool
    
    public var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .user }
        set { roleRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        createdAt: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.roleRaw = role.rawValue
        self.content = content
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
}
