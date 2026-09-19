//
//  VoiceFeedbackSanitizationTests.swift
//  ViLiltTests
//
//  Unit tests verifying voice feedback text sanitization (stripping thinking tags, markdown, code blocks)
//

import XCTest
@testable import ViLilt

final class VoiceFeedbackSanitizationTests: XCTestCase {
    
    func testSanitizeThinkingTags() {
        let input = "<think>Let me formulate a gentle answer</think>Hello! How are you doing today?"
        let sanitized = VoiceFeedbackManager.sanitizeTextForVoice(input)
        XCTAssertEqual(sanitized, "Hello! How are you doing today?")
    }
    
    func testSanitizeUnclosedThinkingTags() {
        let input = "<think>Incomplete thinking stream... Still processing"
        let sanitized = VoiceFeedbackManager.sanitizeTextForVoice(input)
        XCTAssertEqual(sanitized, "")
    }
    
    func testSanitizeCodeBlocks() {
        let input = "Here is an example: ```python\nprint('hello')\n``` Enjoy coding!"
        let sanitized = VoiceFeedbackManager.sanitizeTextForVoice(input)
        XCTAssertEqual(sanitized, "Here is an example:  Enjoy coding!")
    }
    
    func testSanitizeInlineCodeAndMarkdown() {
        let input = "Try using `let x = 10` with *italic* and **bold** and #headings."
        let sanitized = VoiceFeedbackManager.sanitizeTextForVoice(input)
        XCTAssertEqual(sanitized, "Try using  with italic and bold and headings.")
    }
    
    func testSanitizeWhitespaceAndEmpty() {
        XCTAssertEqual(VoiceFeedbackManager.sanitizeTextForVoice(""), "")
        XCTAssertEqual(VoiceFeedbackManager.sanitizeTextForVoice("   \n\t  "), "")
    }
}
