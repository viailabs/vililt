//
//  AzureEdgeTTSVoiceTests.swift
//  ViLiltTests
//
//  Unit tests verifying Edge TTS neural voice mapping across international locales
//

import XCTest
@testable import ViLilt

final class AzureEdgeTTSVoiceTests: XCTestCase {
    
    func testVoiceMappingForChinese() {
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("zh-CN"), "zh-CN-XiaoxiaoNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("zh-Hans"), "zh-CN-XiaoxiaoNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("zh-TW"), "zh-TW-HsiaoChenNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("zh-Hant"), "zh-TW-HsiaoChenNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("zh-HK"), "zh-TW-HsiaoChenNeural")
    }
    
    func testVoiceMappingForEuropeanLanguages() {
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("es-ES"), "es-ES-ElviraNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("fr-FR"), "fr-FR-DeniseNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("de-DE"), "de-DE-KatjaNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("it-IT"), "it-IT-ElsaNeural")
    }
    
    func testVoiceMappingForAsianLanguages() {
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("ja-JP"), "ja-JP-NanamiNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("ko-KR"), "ko-KR-SunHiNeural")
    }
    
    func testVoiceMappingFallbackEnglish() {
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("en-US"), "en-US-JennyNeural")
        XCTAssertEqual(AzureEdgeTTSManager.voiceForLanguage("unknown-locale"), "en-US-JennyNeural")
    }
}
