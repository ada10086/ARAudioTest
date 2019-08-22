//
//  recordButton.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 7/25/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import AudioKit
import Combine

struct RecordButton : View {
    @ObservedObject var audioEngine: AudioEngine
    @Binding var recordingFinished: Bool
    @State var isPressed : Bool = false
    @State var endTrim : CGFloat = 0
    
    var lineWidth: CGFloat = 5
    var buttonRadius: CGFloat = 25
    var trackPathRadius: CGFloat = 40

    var body: some View {
        
        return ZStack{
            
            //visulizer
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .scaleEffect(self.isPressed ? 1 + 10 * CGFloat(self.audioEngine.amplitude) : 1)
                .animation(Animation.easeInOut)
            
            //center circle button
            CircleButton(audioEngine: audioEngine, recordingFinished: $recordingFinished, endTrim: $endTrim, isPressed: $isPressed, radius: buttonRadius)
            
            //background path
            Circle()
                .trim(from:0, to:1)
                .stroke(Color.gray, lineWidth: lineWidth)
                .frame(width: trackPathRadius*2, height: trackPathRadius*2)
            
            //track path
            Circle()
                .trim(from: 0, to: self.endTrim)
                .stroke(Color.red, lineWidth: lineWidth)
                .frame(width: trackPathRadius*2, height: trackPathRadius*2)
                .rotationEffect(.degrees(-90))
                .animation(Animation.linear(duration:10))
        }
        
    }
}

struct CircleButton : View {
    @ObservedObject var audioEngine: AudioEngine
    @Binding var recordingFinished: Bool
    @Binding var endTrim: CGFloat
    @Binding var isPressed : Bool
    var radius: CGFloat
    
    @State private var startTime : Date = Date()
    @State private var scale : CGFloat = 1

    var pulse: Animation {
        Animation.easeInOut(duration: 0.8)
            .repeatForever(autoreverses:true)
    }
    
    var pulseReturn: Animation {
        Animation.easeInOut(duration: 0.4)
            .repeatCount(1)
    }
    
    var fill: Animation {
        Animation.linear(duration: 10)
    }
    
    var body: some View {
        
        return Circle()
            .fill(Color.gray)
            .frame(width: radius*2, height: radius*2, alignment: .center)
            .scaleEffect(scale)
            .animation(isPressed ? pulse : pulseReturn)
            .onLongPressGesture(minimumDuration: 10, pressing: { pressed in
                self.isPressed = pressed
                self.scale = pressed ? 1.1 : 1
                
                if pressed {
                    ////breakpoint: required condition is false: [AVAudioPlayerNode.mm:568:StartImpl: (_engine->IsRunning())]
                    try? AudioKit.start()

                    ///start microphone amplitude tracker
                    self.audioEngine.tracker.start()
                    
                    do {
                        try self.audioEngine.recorder.reset() ////reset in case user wants to rerecord before entering EffecPreview
                        try self.audioEngine.recorder.record()
                    } catch { AKLog("Errored recording.") }
                    
                    self.startTime = Date()
                    
                    withAnimation(self.fill) {
                        self.endTrim = 1
                    }
                    
                } else {
                    print("recording length: \(self.startTime.timeIntervalSinceNow * -1)")
//                    withAnimation() {
//                        self.endTrim = CGFloat(self.startTime.timeIntervalSinceNow * -1/10)
//                    }
                    
                    ///stop microphone amplitude tracker
                    self.audioEngine.tracker.stop()
                    
                    print("recorderDuration\(self.audioEngine.recorder.audioFile!.duration)")
                    
                    //export original recording
                    if let _ = self.audioEngine.recorder.audioFile?.duration {
                        self.audioEngine.recorder.stop()
                        self.audioEngine.recorder.audioFile!.exportAsynchronously(
                            name: "tempRecording.caf",
                            baseDir: .documents,
                            exportFormat: .caf) { file, exportError in
                                if let error = exportError {
                                    AKLog("Export Failed \(error)")
                                } else {
                                    AKLog("Export succeeded")
                                }
                        }
                    }
                    
                    //load effectPlayers with orinigal recording
                    for playerData in self.audioEngine.effectPlayers {
                        playerData.player.load(audioFile: self.audioEngine.recorder.audioFile!)
                    }
                    
                    self.recordingFinished = true
                }
            }, perform: {})
    }
}
