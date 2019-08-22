//
//  AudioEngine.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 7/30/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import Foundation
import AudioKit
import AudioKitUI
import Combine

class AudioEngine: ObservableObject {
    
    @Published var recordedFileData: RecordedFileData? = nil
    @Published var recordedFiles: [RecordedFileData] = []
    @Published var activePlayerData = PlayerData(effect: "normal")
    @Published var amplitude: Double = 0
    
    //mic
    let mic = AKMicrophone()
    var micMixer: AKMixer!
    var recorder: AKNodeRecorder!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    //effect nodes
    var echoDelay: AKDelay!
    var echoReverb: AKReverb!
    var variSpeedFast: AKVariSpeed!
    var variSpeedSlow: AKVariSpeed!
    var robotDelay: AKDelay!
    var chorus: AKChorus!
    
    var booster: AKBooster!
    var mainMixer: AKMixer!

    
    //data storing effect players
    var normalPlayerData = PlayerData(effect: "normal")
    var echoPlayerData = PlayerData(effect: "echo")
    var fastPlayerData = PlayerData(effect: "fast")
    var slowPlayerData = PlayerData(effect: "slow")
    var robotPlayerData = PlayerData(effect: "robot")
    var chorusPlayerData = PlayerData(effect: "chorus")
    var effectPlayers : [PlayerData] = []
    
    //player for saved audio
    var recordedPlayer: AKPlayer!
    
    init() {
        //mic
        micMixer = AKMixer(mic)
        recorder = try? AKNodeRecorder(node: micMixer)
        tracker = AKFrequencyTracker(micMixer)
        tracker.stop()
        silence = AKBooster(tracker, gain: 0)
        
        //echo
        echoDelay = AKDelay(echoPlayerData.player)
        echoDelay.time = 0.1
        echoDelay.feedback = 0.4
        echoDelay.dryWetMix = 0.5
        echoReverb = AKReverb(echoDelay)
        echoReverb.loadFactoryPreset(.cathedral)
        
        //fast
        variSpeedFast = AKVariSpeed(fastPlayerData.player)
        variSpeedFast.rate = 1.7
        
        //slow
        variSpeedSlow = AKVariSpeed(slowPlayerData.player)
        variSpeedSlow.rate = 0.7
        
        //robot
        robotDelay = AKDelay(robotPlayerData.player)
        robotDelay.time = 0.015 // seconds
        robotDelay.lowPassCutoff = 17593 //Hz
        robotDelay.feedback = 0.75 // Normalized Value 0 - 1
        robotDelay.dryWetMix = 0.47 // Normalized Value 0 - 1
        
        //chorus
        chorus = AKChorus(chorusPlayerData.player)
        chorus.feedback = 0.7
        chorus.depth = 0.5
        chorus.dryWetMix = 0.5
        chorus.frequency = 8
        
        effectPlayers = [normalPlayerData, echoPlayerData, fastPlayerData, slowPlayerData, robotPlayerData, chorusPlayerData]
        activePlayerData = normalPlayerData

        recordedPlayer = AKPlayer()
        recordedPlayer.isLooping = false
        recordedPlayer.buffering = .always
        
        
        ///have to wire everything to mixer--> output before AudioKit.start(), cannot rewire on the go
        mainMixer = AKMixer(normalPlayerData.player, echoReverb, variSpeedFast, variSpeedSlow, robotDelay, chorus, recordedPlayer, silence)
        booster = AKBooster(mainMixer)
        AudioKit.output = booster

//        startAudioKit()
        
        AKPlaygroundLoop(every: 0.1) {
            if self.tracker.isStarted{
                self.amplitude = self.tracker.amplitude
                print("audioengine tracker amplitude: \(self.amplitude)")
            }
        }
    }
    
//    func startAudioKit() {
//        do {
//            try AudioKit.start()
//        } catch {
//            AKLog("AudioKit did not start!")
//        }
//    }
    
}

struct RecordedFileData: Hashable {
    var id: UUID
    var fileURL: URL
    var title: String
    var effect: String
}

struct PlayerData: Hashable {
    var player: AKPlayer!
    var effect: String!  //for button texts
    //var image for button image
    
    init(effect: String){
        self.effect = effect
        
        player.isLooping = false
        player.buffering = .always
    }
}

