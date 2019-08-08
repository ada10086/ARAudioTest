//
//  AudioEngine.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 7/30/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import Foundation
import AudioKit
import Combine

class AudioEngine: ObservableObject {
    
    var willChange = PassthroughSubject<AudioEngine, Never>()
    
    var recordedFileData: RecordedFileData? {
        willSet {
            self.willChange.send(self)
        }
    }
    
    var recordedFiles: [RecordedFileData] = [] {
        willSet {
            willChange.send(self)
        }
    }
    
    var activePlayerData = PlayerData(effect: "normal") {
        willSet {
            self.willChange.send(self)
        }
    }
    
    var file: AKAudioFile!
    
    //mic
    var micMixer: AKMixer!
    var recorder: AKNodeRecorder!
    var micBooster: AKBooster!
    let mic = AKMicrophone()
    var mainMixer: AKMixer!
    var booster: AKBooster!
    
    //effect nodes
    var echoDelay: AKDelay!
    var echoReverb: AKReverb!
    var variSpeedFast: AKVariSpeed!
    var variSpeedSlow: AKVariSpeed!
    var robotDelay: AKDelay!
    var chorus: AKChorus!
    
    //effect players
    var normalPlayerData = PlayerData(effect: "normal")
    var echoPlayerData = PlayerData(effect: "echo")
    var fastPlayerData = PlayerData(effect: "fast")
    var slowPlayerData = PlayerData(effect: "slow")
    var robotPlayerData = PlayerData(effect: "robot")
    var chorusPlayerData = PlayerData(effect: "chorus")
    var effectPlayers : [PlayerData] = []
    
    //player for exported audio
    var recordedPlayer: AKPlayer!
    
    init() {
        do {
            file = try AKAudioFile(readFileName: "hello.mp3")
        } catch {
            AKLog("File Not Found")
            return
        }
        
        micMixer = AKMixer(mic)
        recorder = try? AKNodeRecorder(node: micMixer)
        
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
        
        recordedPlayer = AKPlayer(audioFile: file)
        recordedPlayer.isLooping = false
        recordedPlayer.buffering = .always
        
        activePlayerData = normalPlayerData
        
        //mixer
        mainMixer = AKMixer(normalPlayerData.player, echoReverb, variSpeedFast, variSpeedSlow, robotDelay, chorus, recordedPlayer)
        booster = AKBooster(mainMixer)
        AudioKit.output = booster
        startAudioKit()
    }
    
    func startAudioKit() {
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    func playingEnded() {
        DispatchQueue.main.async {
            AKLog("Playing Ended")
        }
    }
}

struct RecordedFileData: Hashable {
    var id: UUID
    var fileURL: URL
    var title: String
    var effect: String
}

struct PlayerData: Hashable {
    var player: AKPlayer!
    var effect: String!
    //image
    
    init(effect: String){
        self.effect = effect
        
        do {
            //file has to be present
            let myFile = try AKAudioFile(readFileName: "hello.mp3")
            player = AKPlayer(audioFile: myFile)
        } catch {
            AKLog("File Not Found")
            return
        }
        
        player.isLooping = false
        player.buffering = .always
    }
}

