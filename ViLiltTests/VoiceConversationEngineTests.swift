//
//  VoiceConversationEngineTests.swift
//  ViLiltTests
//
//  Unit tests verifying voice conversation engine states and controls
//

import XCTest
@testable import ViLilt

final class VoiceConversationEngineTests: XCTestCase {
    
    func testInitialState() {
        let engine = VoiceConversationEngine.shared
        XCTAssertEqual(engine.state, .idle)
        XCTAssertTrue(engine.isHandsFreeMode)
        XCTAssertEqual(engine.activePersona.id, Persona.defaultPersona.id)
    }
    
    func testStateTransitionsEnum() {
        let states: [VoiceConversationEngine.State] = [.idle, .listening, .thinking, .speaking, .paused]
        XCTAssertEqual(states.count, 5)
    }
    
    func testEndCallSessionResetsState() {
        let engine = VoiceConversationEngine.shared
        engine.endCallSession()
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.liveUserUtterance, "")
        XCTAssertEqual(engine.liveAssistantReply, "")
    }
}
