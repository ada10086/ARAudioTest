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
    
    var body: some View {
        VStack{
            ForEach(self.audioEngine.recordedFiles, id: \.self){ file in
                Button(file.title){
                    ////have to restart AudioKit, or '*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'required condition is false: _engine->IsRunning()'
                    ////once tapped, object's audio in scene stops playing
                    try? AudioKit.stop()
                    try? AudioKit.start()
                    ////--------------------------------
                    print("url \(file.fileURL)")
                    try? self.audioEngine.recordedPlayer!.load(url: file.fileURL)
                    self.audioEngine.recordedPlayer!.play()
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

