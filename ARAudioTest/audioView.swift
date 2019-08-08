//
//  ContentView.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 7/25/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import AudioKit
import Combine

struct audioView: View {
    @ObservedObject var audioEngine: AudioEngine
    @State var recordingFinished: Bool = false
    @State var audioSaved: Bool = false
    
    @ObservedObject var arViewAudioData: ARViewAudioData

    var body: some View {
        return ZStack{
            Rectangle()
                .fill(Color.black)
                .opacity(0.5)
            
            VStack {
                if !recordingFinished {
                    Button("record"){
                        do {
                            try self.audioEngine.recorder.reset()
                            try self.audioEngine.recorder.record()
                        } catch { AKLog("Errored recording.") }
                        
                    }
                    .frame(width: 70, height: 30, alignment: .center)
                        .background(Color.black)  //if active, change color
                        .cornerRadius(5)
                        .foregroundColor(Color.white)
                        .padding(3)
                    
                    Button("stop"){
                        print("recorderDuration\(self.audioEngine.recorder.audioFile!.duration)")
                        
                        //export original recording file
                        if let _ = self.audioEngine.recorder.audioFile?.duration {
                            self.audioEngine.recorder.stop()
                            self.audioEngine.recorder.audioFile!.exportAsynchronously(
                                name: "tempRecording.wav",
                                baseDir: .documents,
                                exportFormat: .wav) { file, exportError in
                                    if let error = exportError {
                                        AKLog("Export Failed \(error)")
                                    } else {
                                        AKLog("Export succeeded")
                                    }
                            }
                        }
                        
                        //load effectPlayers with recorder audiofile
                        for playerData in self.audioEngine.effectPlayers {
                            playerData.player.load(audioFile: self.audioEngine.recorder.audioFile!)
                        }
                        
                        self.recordingFinished = true
                    }
                    .frame(width: 70, height: 30, alignment: .center)
                        .background(Color.black)  //if active, change color
                        .cornerRadius(5)
                        .foregroundColor(Color.white)
                        .padding(3)
                    
                } else {
                    
                    if !audioSaved {
                        
                        EffectPreview(audioEngine: audioEngine, audioSaved: $audioSaved, arViewAudioData: arViewAudioData)
                        
                    } else {
                        SavedAudioView(audioEngine: audioEngine)
                            .padding()
                        Button("new recording"){
                            self.recordingFinished = false
                            self.audioSaved = false
                        }
                        .font(.title)
                        .foregroundColor(Color.red)
                        .frame(width: 200, height: 30, alignment: .center)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(5)
                    }
                }
            }
        }
    }
}
