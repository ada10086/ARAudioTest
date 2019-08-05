//
//  ContentView.swift
//  ARAudioTest
//
//  Created by Chuchu Jiang on 8/2/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import RealityKit
import UIKit

struct ContentView : View {
    @State var loopOn: Bool = true
    @State var isPlaying: Bool = false
    
    var body: some View {
        return ZStack{
            ARViewContainer(loopOn: $loopOn, isPlaying: $isPlaying).edgesIgnoringSafeArea(.all)
            HStack{
                Button("toggle loop"){
                    self.loopOn.toggle()
                }
                Button("play/pause"){
                    self.isPlaying.toggle()
                }
            }
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    @Binding var loopOn: Bool
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> ARViewTest {
        return ARViewTest(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: .random())
    }
    
    func updateUIView(_ uiView: ARViewTest, context: Context) {
        uiView.loopAudio(loopOn)
        uiView.playStopAudio(isPlaying)
    }
    
}

class ARViewTest: ARView {
    /// assets
    var audio: AudioFileResource!
    let myView = UIView(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
    var audioPlaybackController: AudioPlaybackController!
    
    /// init
    override init(frame frameRect: CGRect, cameraMode: ARView.CameraMode, automaticallyConfigureSession: Bool) {
        super.init(frame: frameRect)

        self.myView.backgroundColor = .blue
        self.addSubview(myView)
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadMyScene()

        // Add the box anchor to the scene
        self.scene.anchors.append(boxAnchor)

        let box = self.scene.findEntity(named: "Steel Box")
        self.audio = try! AudioFileResource.load(named: "hello.mp3", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
        audioPlaybackController = box!.prepareAudio(self.audio)
//        audioPlaybackController.play()
    }
    
    func loopAudio(_ loopOn: Bool) {
        self.audio.shouldLoop = loopOn
        self.myView.backgroundColor = loopOn ? .red : .green
        print("looping:\(self.audio.shouldLoop)")
    }
    
    func playStopAudio(_ isPlaying: Bool){
        if isPlaying {
            self.audioPlaybackController.play()
        } else {
            self.audioPlaybackController.stop()
        }
    }
    
    
    @available(*, unavailable)
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(*, unavailable)
    @objc required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
