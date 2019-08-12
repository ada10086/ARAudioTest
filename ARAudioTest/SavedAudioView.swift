//
//  SavedAudioView.swift
//  AudioKitTest
//
//  Created by Chuchu Jiang on 8/1/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import AudioKit

struct SavedAudioView: View {
    @ObservedObject var audioEngine: AudioEngine
    @Binding var audioViewOn: Bool
    @ObservedObject var arViewAudioData: ARViewAudioData

    var body: some View {
        VStack{
            //buttons to preview exported audios w/ effects
            ForEach(self.audioEngine.recordedFiles, id: \.self){ file in
                Button(file.title){
    
                    ////do not call stop() once stop() is called, object's audio in scene stops playing
                    //try? AudioKit.stop()
                    
                    ////have to restart AudioKit, or '*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'required condition is false: _engine->IsRunning()'
                    try? AudioKit.start()

                    print("url \(file.fileURL)")
                    try? self.audioEngine.recordedPlayer!.load(url: file.fileURL)
                    self.audioEngine.recordedPlayer!.play()
                    
                    //send url to subscriber in ARViewTest
                    if file.title == "Box" {
                        self.arViewAudioData.boxURLSubject.send(file.fileURL)
                    } else if file.title == "Capsule" {
                        self.arViewAudioData.capsuleURLSubject.send(file.fileURL)
                    } else if file.title == "Sphere" {
                        self.arViewAudioData.sphereURLSubject.send(file.fileURL)
                    }
                }
                .frame(width: 120, height: 30, alignment: .center)
                .background(Color.black)  //if active, change color
                .cornerRadius(5)
                .foregroundColor(Color.white)
                .padding(3)
            }
        }
    }
}

