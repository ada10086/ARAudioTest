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
                                .background(Color.black)
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
    var urlCanceller: Cancellable?
    
    init(arViewAudioData:ARViewAudioData){
        self.arViewAudioData = arViewAudioData
        
        //receive audio url and attach to selectedEntity in callback
        urlCanceller = arViewAudioData.urlSubject.sink(receiveValue: { url in
            print("urlCanceller received audioURL: \(url!)")
            arViewAudioData.url = url
        
            
            ///safely unwrap arViewTest
            if let arView = arViewAudioData.arViewTest {
                print("myARView = arViewAudioData.arViewTest")
                arView.attachAudio(entityData: arView.selectedEntityData!, url: url!)
            }
        })
    }
    
    
    func makeUIView(context: Context) -> ARViewTest {
        let arViewTest = ARViewTest()
        arViewAudioData.arViewTest = arViewTest

        return arViewTest
    }
    
    func updateUIView(_ uiView: ARViewTest, context: Context) {
    }
    
}


class ARViewTest: ARView {
    /// assets
    var boxEntity: Entity!
    var capsuleEntity: Entity!
    var sphereEntity: Entity!
    
    var boxEntityData: EntityData!
    var capsuleEntityData: EntityData!
    var sphereEntityData: EntityData!
    var entityDataArray: [EntityData] = []
    var selectedEntityData: EntityData?
    
    var audioPlaybackController: AudioPlaybackController?
    
    /// init
    required init() {
        super.init(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)

        let boxAnchor = try! Experience.loadMyScene()
        self.scene.anchors.append(boxAnchor)

        boxEntity = self.scene.findEntity(named: "Steel Box")

        //add CollisionComponent for hitTest
        boxEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])]) ///can get self size???

        capsuleEntity = self.scene.findEntity(named: "capsule")
        capsuleEntity.setPosition([1,0,0], relativeTo: nil)
        capsuleEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateCapsule(height: 0.2, radius: 0.05)])///radius vs diameter??? bottom does not respond with tapping sometimes

        sphereEntity = self.scene.findEntity(named:"ball")
        sphereEntity.setPosition([2,0,0], relativeTo: nil)

        sphereEntity.components[CollisionComponent] = CollisionComponent(shapes: [ .generateSphere(radius: 0.05)])

        ///if audio was created for object before, initialize with audioURL
        boxEntityData = EntityData(entity: boxEntity, audioFileName: nil, audioURL: nil, audioShouldLoop: false)
        capsuleEntityData = EntityData(entity: capsuleEntity, audioFileName: nil, audioURL: nil, audioShouldLoop: false)
        sphereEntityData = EntityData(entity:sphereEntity, audioFileName: nil, audioURL: nil, audioShouldLoop: false)

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
                /// if in play mode, tap on entity to play audio
                if let audioPlaybackController = entityDataArray[index].audioPlaybackController {
                    audioPlaybackController.play()
                    print("entity audio url: \(entityDataArray[index].audioURL)")
                }
                /// if in edit mode, tap on entity to open entity edit menu and add audio
                selectedEntityData = entityDataArray[index]
                print("selectedEntityData:\(entity)" )

            }

        }

    }

    func attachAudio(entityData: EntityData, url: URL){
        entityData.audioURL = url
        
        ///[Audio] Failed to read file: (null)????? ====> exported audio format needs to be .caf, .pcmFormatFloat32
        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")   //discounnected after completion
        }, receiveValue: { loadedAudio in
            entityData.audio = loadedAudio
            entityData.audioPlaybackController = entityData.entity.prepareAudio(loadedAudio)
            print("successfully attacheed")
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
    var audioFileName: String? //take out
    var audioURL: URL?
    var audio: AudioFileResource?
    var audioPlaybackController: AudioPlaybackController?
    var audioShouldLoop: Bool? = false
    
    //take out audioFileName
    init(entity: Entity, audioFileName: String?, audioURL: URL?, audioShouldLoop: Bool?) {
        self.entity = entity
        self.audioFileName = audioFileName
        self.audioURL = audioURL
        self.audioShouldLoop = audioShouldLoop
        
///  load audio with test file
//        guard let fileName = audioFileName else {return}
//        let loadRequest = AudioFileResource.loadAsync(named: fileName, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
        
/// if audio was created for object before, load audio from audioURL:
//        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
        
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
    
    @Published var url: URL? = nil

    //publisher for exported audio url
    let urlSubject = PassthroughSubject<URL?, Never>()
    
    var arViewTest: ARViewTest?
}
