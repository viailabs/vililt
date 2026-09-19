//
//  AudioPlayer.swift
//  viLilt
//
//  Lightweight AVPlayer wrapper with delegate callbacks
//

import Foundation
import AVFoundation

public final class AudioPlayer: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = AudioPlayer()
    
    private var player: AVAudioPlayer?
    public var onPlaybackFinished: (@Sendable () -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func play(url: URL) {
        halt()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            onPlaybackFinished?()
        }
    }
    
    public func halt() {
        player?.stop()
        player = nil
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?()
    }
}
