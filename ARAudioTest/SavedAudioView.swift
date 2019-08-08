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
                .font(.title)
                .foregroundColor(Color.white)
                .frame(width: 150, height: 150, alignment: .center)
                .padding()
                .background(Color.black)
                .cornerRadius(5)
            }
        }
    }
}

