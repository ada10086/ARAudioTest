//
//  EffectButtons.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 7/30/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import AudioKit

struct EffectPreview: View {
    @ObservedObject var audioEngine: AudioEngine
//    @Binding var audioSaved: Bool
    @State var title: String = "my audio"
    
    @ObservedObject var arViewAudioData: ARViewAudioData

    var body: some View {
        VStack{
            
            //preview buttons
            ForEach(self.audioEngine.effectPlayers, id: \.self){ playerData in
                Button(playerData.effect){
//                    try? AudioKit.start()
                    ////breakpoint: required condition is false: [AVAudioPlayerNode.mm:568:StartImpl: (_engine->IsRunning())]
                    playerData.player.play()
                    self.audioEngine.activePlayerData = playerData
                }
                .frame(width: 70, height: 30, alignment: .center)
                .background(Color.black)  //if active, change color
                .cornerRadius(5)
                .foregroundColor(Color.white)
                .padding(3)
            }

            //save title
            HStack {
                Spacer()
                TextField("type your title here", text: $title)
//                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            
            Button("save to object"){
                if let _ = self.audioEngine.recorder.audioFile?.duration {
                    
                    do {
                        //export audio file with applied effect .wav
                        let id = UUID()
                        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(id.uuidString + ".caf")
                        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
                        let audioFile = try! AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
                        try AudioKit.renderToFile(audioFile, duration:
                            //fix duration!!
                            self.audioEngine.activePlayerData.player.duration + 1, prerender: {
                            self.audioEngine.activePlayerData.player.load(audioFile: self.audioEngine.recorder.audioFile!)
                            self.audioEngine.activePlayerData.player.play()
                        })
                        print("audio file rendered")
                        
                        //send url to subscriber in ARViewTest
                        self.arViewAudioData.urlSubject.send(url)

                        
                        //add data to recordedfiles array
                        self.audioEngine.recordedFileData = RecordedFileData(id: id, fileURL: audioFile.directoryPath.appendingPathComponent(id.uuidString + ".caf"), title: self.title, effect: self.audioEngine.activePlayerData.effect)
                        self.audioEngine.recordedFiles.append(self.audioEngine.recordedFileData!)
                        print("audioFiles: \(self.audioEngine.recordedFiles)")
                        
                        //reset recorder, clear recorder audiofile
                        try self.audioEngine.recorder.reset()
                        
//                        self.audioSaved = true
                        
                    } catch {
                        print("error rendering", error)
                    }
                }
            }
            .foregroundColor(Color.red)
            .frame(width: 110, height: 30, alignment: .center)
            .background(Color.black)
            .cornerRadius(5)
        }
    }
}
