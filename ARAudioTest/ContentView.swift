//
//  ContentView.swift
//  ARAudioTest
//
//  Created by Chuchu Jiang on 8/2/19.
//  Copyright © 2019 adajiang. All rights reserved.
//

import SwiftUI
import RealityKit
import Combine

struct ContentView : View {
    @State var loopOn: Bool = false
    @State var isPlaying: Bool = false
    
    var body: some View {
        return ZStack{
            ARViewContainer(loopOn: $loopOn, isPlaying: $isPlaying).edgesIgnoringSafeArea(.all)
            HStack{
                Button("toggle loop"){
                    self.loopOn.toggle()
                }
                Button("play/stop"){
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
    
    //called when anything inside is changed
    func updateUIView(_ uiView: ARViewTest, context: Context) {
        //      uiView.loopAudio(loopOn)
        //        uiView.playStopAudio(isPlaying)
    }
    
}

class ARViewTest: ARView {
    /// assets
    var audio1: AudioFileResource?
    var audio2: AudioFileResource?
    var boxEntity: Entity!
    var capsuleEntity: Entity!
    let myView = UIView(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
    var audioPlaybackController: AudioPlaybackController?
    var entityDataArray: [EntityData] = []
    
    var boxEntityData: EntityData!
    var capsuleEntityData: EntityData!
    /// init
    override init(frame frameRect: CGRect, cameraMode: ARView.CameraMode, automaticallyConfigureSession: Bool) {
        super.init(frame: frameRect)
        
        self.myView.backgroundColor = .blue
        self.addSubview(myView)
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadMyScene()
        
        // Add the box anchor to the scene
        self.scene.anchors.append(boxAnchor)
        
        boxEntity = self.scene.findEntity(named: "Steel Box")
        
        //add CollisionComponent for hitTest
        boxEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])]) //can get self size???
        
        
        capsuleEntity = self.scene.findEntity(named: "capsule")
        capsuleEntity!.setPosition([1,0,0], relativeTo: nil)
        capsuleEntity!.components[CollisionComponent] = CollisionComponent(shapes: [.generateCapsule(height: 0.2, radius: 0.05)])//radius vs diameter???
        
        
        boxEntityData = EntityData(entity: boxEntity, audioFileName: "hello.mp3")
        capsuleEntityData = EntityData(entity: capsuleEntity, audioFileName: "bottle.wav")
        
        entityDataArray = [boxEntityData, capsuleEntityData]
        // audio = try! AudioFileResource.load(named: "hello.mp3", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
        // audioPlaybackController = box!.prepareAudio(self.audio)
        
//        //loadAsync
//        let loadRequest1 = AudioFileResource.loadAsync(named: "hello.mp3", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
//        let observer1 = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
//            print("completed")
//        }, receiveValue: { audio in
//            // Use loaded audio here
//            self.audioPlaybackController = self.boxEntity!.prepareAudio(audio)
//            self.audio1 = audio
//        })
//        loadRequest1.subscribe(observer1)
//
//        let loadRequest2 = AudioFileResource.loadAsync(named: "bottle.wav", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
//        let observer2 = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
//            print("completed")
//        }, receiveValue: { audio in
//            // Use loaded audio here
//            //            self.audioPlaybackController = self.box!.prepareAudio(audio)
//            //            self.audioPlaybackController!.play()
//            self.audio2 = audio
//        })
//        loadRequest2.subscribe(observer2)
        
        
        let tap = UITapGestureRecognizer(target:self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        print("tapped")
        let location = sender.location(in: self)
        guard let hitEntity = self.entity(at: location) else { return }
        print("hitEntity: \(hitEntity)")
        let entities = entityDataArray.map({ $0.entity })
        for (index, entity) in entities.enumerated() {
            if hitEntity == entity {
                entityDataArray[index].audioPlaybackController.play()
            }
        }
//        if hitEntity == boxEntity {
//            if let audio = audio1 {
//                hitEntity.playAudio(audio)
//            }
//        } else if hitEntity == capsuleEntity {
//            if let audio = audio2 {
//                hitEntity.playAudio(audio)
//            }
//        }
        //            if let controller = audioPlaybackController {
        ////                //if looped, toggle play/stop
        ////                if controller.isPlaying {
        ////                    controller.stop()
        ////                } else {
        ////                    controller.play()
        ////                }
        //                //if not looped, tap to play once
        //                controller.play()
        //            }
    }
    
    //        func loopAudio(_ loopOn: Bool) {
    //            if let controller = audioPlaybackController {
    //                if controller.isPlaying {
    //                    controller.stop()
    //                }
    //                audio?.shouldLoop = loopOn
    //                controller.play()
    //            }
    //            myView.backgroundColor = loopOn ? .green : .red
    ////            print("looping:\(self.audio.shouldLoop)")
    //        }
    
    //    func playStopAudio(_ isPlaying: Bool){
    //            if let controller = audioPlaybackController {
    //                //if looped, toggle play/stop
    //                if isPlaying {
    //                    controller.play()
    //                } else {
    //                    controller.stop()
    //                }
    //                //if not looped, tap to play once
    //                controller.play()
    //            }
    //        }
    
    
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


//struct(Escaping closure captures mutating 'self' parameter)
//vs class('self' captured by a closure before all members were initialized)
class EntityData {
    var entity: Entity!
    var audioFileName: String! //URL
    var audio: AudioFileResource
    var audioPlaybackController: AudioPlaybackController
    var audioShouldLoop: Bool = false
    
    init(entity: Entity, audioFileName: String) {
        self.entity = entity
        self.audioFileName = audioFileName
        //initialize first
        audio = try! AudioFileResource.load(named: "piano.wav", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: true)
        audioPlaybackController = entity.prepareAudio(audio)
        
        let loadRequest = AudioFileResource.loadAsync(named: audioFileName, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")
        }, receiveValue: { loadedAudio in
            self.audio = loadedAudio
            self.audioPlaybackController = self.entity.prepareAudio(loadedAudio)
        })
        loadRequest.subscribe(observer)
    }
    
//    func loadAudioFile(){
//        let loadRequest = AudioFileResource.loadAsync(named: audioFileName, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop)
//        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
//            print("completed")
//        }, receiveValue: { loadedAudio in
//            self.audio = loadedAudio
//            self.audioPlaybackController = self.entity.prepareAudio(loadedAudio)
//        })
//        loadRequest.subscribe(observer)
//    }
    
}
