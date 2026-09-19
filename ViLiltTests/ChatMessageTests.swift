//
//  ChatMessageTests.swift
//  ViLiltTests
//
//  Unit tests verifying ChatMessage model initialization, roles, and mutations
//

import XCTest
@testable import ViLilt

final class ChatMessageTests: XCTestCase {
    
    func testUserMessageInitialization() {
        let msg = ChatMessage(role: .user, content: "Hello viLilt")
        XCTAssertEqual(msg.role, MessageRole.user)
        XCTAssertEqual(msg.content, "Hello viLilt")
        XCTAssertFalse(msg.id.uuidString.isEmpty)
        XCTAssertFalse(msg.isStreaming)
    }
    
    func testAssistantMessageWithStreaming() {
        let msg = ChatMessage(role: .assistant, content: "I'm doing well!", isStreaming: true)
        XCTAssertEqual(msg.role, MessageRole.assistant)
        XCTAssertEqual(msg.content, "I'm doing well!")
        XCTAssertTrue(msg.isStreaming)
    }
    
    func testMessageRoleRawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }
    
    func testConversationThreadMessages() {
        let thread = ConversationThread(title: "My Chat", selectedPersonaId: "mentor")
        XCTAssertEqual(thread.title, "My Chat")
        XCTAssertEqual(thread.selectedPersonaId, "mentor")
        let msg1 = ChatMessage(role: .user, content: "Hi")
        let msg2 = ChatMessage(role: .assistant, content: "Hello!")
        thread.messages.append(msg1)
        thread.messages.append(msg2)
        XCTAssertEqual(thread.messages.count, 2)
    }
}
