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
import AudioKit

struct ContentView : View {

    @State var audioViewOn: Bool = false
    @ObservedObject var audioEngine: AudioEngine

    @ObservedObject var arViewAudioData: ARViewAudioData

    var body: some View {
//        return ZStack{
//                        if !audioViewOn {
//                            ARViewContainer(arViewAudioData: arViewAudioData)
//                            Button("record audio"){self.audioViewOn = true}
//                                .frame(width: 120, height: 30, alignment: .center)
//                                .background(Color.black)  //if active, change color
//                                .cornerRadius(5)
//                                .foregroundColor(Color.white)
//                                .padding(3)
//                        } else {
//                            AudioView(audioEngine: audioEngine, audioViewOn: $audioViewOn, arViewAudioData: arViewAudioData)
//                                .frame(width: 400, height: 400, alignment: .center)
//                                .cornerRadius(5)
//                        }
//        }
        return ZStack{
            ARViewContainer(arViewAudioData: arViewAudioData)
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    ZStack{
                        if !audioViewOn {
                            Button("record audio"){self.audioViewOn = true}
                                .frame(width: 120, height: 30, alignment: .center)
                                .background(Color.black)  //if active, change color
                                .cornerRadius(5)
                                .foregroundColor(Color.white)
                                .padding(3)
                        } else {
                            AudioView(audioEngine: audioEngine, audioViewOn: $audioViewOn, arViewAudioData: arViewAudioData)
                                .frame(width: 400, height: 400, alignment: .center)
                                .cornerRadius(5)
                        }
                    }
                }
            }
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    @ObservedObject var arViewAudioData: ARViewAudioData
    var boxURLCanceller: Cancellable?
    var capsuleURLCanceller: Cancellable?
    var sphereURLCanceller: Cancellable?
    
    //why init here
    init(arViewAudioData:ARViewAudioData){
        self.arViewAudioData = arViewAudioData
        
        //subscriber receiving exported audio url
        boxURLCanceller = arViewAudioData.boxURLSubject.sink(receiveValue: { url in
            print("boxURLCanceller received audioURL: \(url)")
            arViewAudioData.boxURL = url
        })
        capsuleURLCanceller = arViewAudioData.capsuleURLSubject.sink(receiveValue: { url in
            print("capsuleURLCanceller received audioURL: \(url)")
            arViewAudioData.capsuleURL = url
        })
        sphereURLCanceller = arViewAudioData.sphereURLSubject.sink(receiveValue: { url in
            print("sphereURLCanceller received audioURL: \(url)")
            arViewAudioData.sphereURL = url
        })
        
    }
    
    
    func makeUIView(context: Context) -> ARViewTest {
        let arViewTest = ARViewTest(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: .random())
        
        arViewAudioData.arViewTest = arViewTest

        return arViewTest
    }
    
    //called when any variable inside is changed
    func updateUIView(_ uiView: ARViewTest, context: Context) {
        //      uiView.loopAudio(loopOn)
        //      uiView.playStopAudio(isPlaying)
        uiView.attachAudio(entityData: uiView.boxEntityData, url: arViewAudioData.boxURL)
        uiView.attachAudio(entityData: uiView.capsuleEntityData, url: arViewAudioData.capsuleURL)
        uiView.attachAudio(entityData: uiView.sphereEntityData, url: arViewAudioData.sphereURL)
    }
    
}

class ARViewTest: ARView {
    /// assets
    var audio1: AudioFileResource?
    var audio2: AudioFileResource?
    var boxEntity: Entity!
    var capsuleEntity: Entity!
    var sphereEntity: Entity!
//    let myView = UIView(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
    var audioPlaybackController: AudioPlaybackController?
    var entityDataArray: [EntityData] = []
    var boxEntityData: EntityData!
    var capsuleEntityData: EntityData!
    var sphereEntityData: EntityData!
    
    /// init
    override init(frame frameRect: CGRect, cameraMode: ARView.CameraMode, automaticallyConfigureSession: Bool) {
        super.init(frame: frameRect)
        
//        self.myView.backgroundColor = .blue
//        self.addSubview(myView)

        let boxAnchor = try! Experience.loadMyScene()
        self.scene.anchors.append(boxAnchor)
        
        boxEntity = self.scene.findEntity(named: "Steel Box")
        
        //add CollisionComponent for hitTest
        boxEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])]) //can get self size???
        
        
        capsuleEntity = self.scene.findEntity(named: "capsule")
        capsuleEntity!.setPosition([1,0,0], relativeTo: nil)
        capsuleEntity!.components[CollisionComponent] = CollisionComponent(shapes: [.generateCapsule(height: 0.2, radius: 0.05)])//radius vs diameter??? bottom does not respond with tapping
        
        
        sphereEntity = self.scene.findEntity(named:"ball")
        sphereEntity.setPosition([2,0,0], relativeTo: nil)
        sphereEntity.components[CollisionComponent] = CollisionComponent(shapes: [ .generateSphere(radius: 0.05)])
        
        boxEntityData = EntityData(entity: boxEntity, audioFileName: "hello.mp3", audioShouldLoop: false)
        capsuleEntityData = EntityData(entity: capsuleEntity, audioFileName: "bottle.wav", audioShouldLoop: false)
        sphereEntityData = EntityData(entity:sphereEntity, audioFileName: "blobs.wav", audioShouldLoop: false)
        
        entityDataArray = [boxEntityData, capsuleEntityData, sphereEntityData]
        
        
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
                if let audioPlaybackController = entityDataArray[index].audioPlaybackController {
                    audioPlaybackController.play()
                    print("entity audio: \(entityDataArray[index].audioURL)")
                    entityDataArray[index].isSelected = true
                }
            } else {
                entityDataArray[index].isSelected = false
            }
        }
        
    }
    
    func attachAudio(entityData: EntityData, url: URL){
        entityData.audioURL = url
        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")
        }, receiveValue: { loadedAudio in
            entityData.audio = loadedAudio
            entityData.audioPlaybackController = entityData.entity.prepareAudio(loadedAudio)
        })
        loadRequest.subscribe(observer)
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


//struct(Escaping closure captures mutating 'self' parameter)
//vs class('self' captured by a closure before all members were initialized)
class EntityData {
    var entity: Entity!
    var audioFileName: String? //change to URL
    var audioURL: URL?
    var audio: AudioFileResource?
    var audioPlaybackController: AudioPlaybackController?
    var audioShouldLoop: Bool? = false
    var isSelected: Bool! = false
    
    //change audioFileName to audioURL
    init(entity: Entity, audioFileName: String?, audioShouldLoop: Bool?) {
        self.entity = entity
        self.audioFileName = audioFileName
        self.audioShouldLoop = audioShouldLoop
        
////        //initialize first?????
////        audio = try! AudioFileResource.load(named: "piano.wav", inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
////        audioPlaybackController = entity.prepareAudio(audio)
//
//
//        guard let fileName = audioFileName else {return}
////        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
//        let loadRequest = AudioFileResource.loadAsync(named: fileName, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
//        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
//            print("completed")
//        }, receiveValue: { loadedAudio in
//            self.audio = loadedAudio
//            self.audioPlaybackController = self.entity.prepareAudio(loadedAudio)
//        })
//        loadRequest.subscribe(observer)
    }
}




final class ARViewAudioData: ObservableObject  {
    ////have to initialize first?
    @Published var boxURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    @Published var capsuleURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    @Published var sphereURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    //publishing url from exported audio
    let boxURLSubject = PassthroughSubject<URL, Never>()
    let capsuleURLSubject = PassthroughSubject<URL, Never>()
    let sphereURLSubject = PassthroughSubject<URL, Never>()
    
    var arViewTest: ARViewTest?
}
