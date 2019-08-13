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
    @ObservedObject var entitiesModel: EntitiesModel

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
            ARViewContainer(arViewAudioData: arViewAudioData, entitiesModel:entitiesModel)
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
    @ObservedObject var entitiesModel: EntitiesModel
    var urlCanceller: Cancellable?

//    var arViewTest: ARViewTest
    
    
    init(arViewAudioData:ARViewAudioData, entitiesModel: EntitiesModel){
        self.arViewAudioData = arViewAudioData
        self.entitiesModel = entitiesModel
        
//        arViewTest = ARViewTest()

        //receive entity and url attach in callback
        urlCanceller = arViewAudioData.urlSubject.sink(receiveValue: { url in
            print("urlCanceller received audioURL: \(url)")
            arViewAudioData.url = url
//            entitiesModel.attachAudio(entityData: entitiesModel.boxEntityData, url: url)
            
            arViewAudioData.arViewTest!.attachAudio(entityData: arViewAudioData.arViewTest!.boxEntityData, url: url)
            
//            if let myARView = arViewAudioData.arViewTest {
//                print("myARView = arViewAudioData.arViewTest")
//                myARView.attachAudio(entityData: myARView.selectedEntityData!, url: url)
//                myARView.attachAudio(entityData: myARView.boxEntityData, url: url)

//                for (index, entityData) in myARView.entityDataArray.enumerated() {
//                    if entityData.isSelected {
//                        myARView.attachAudio(entityData: entityData, url: url)
//                        print("audio attached to selected entity : \(entityData.entity)")
//                    }
//                }
//            }
        })
    }
    
    
    func makeUIView(context: Context) -> ARViewTest {
//        let arViewTest = ARViewTest(entitiesModel: entitiesModel)
        let arViewTest = ARViewTest()
        arViewAudioData.arViewTest = arViewTest

        return arViewTest
    }
    
    //called when any variable inside is changed
    func updateUIView(_ uiView: ARViewTest, context: Context) {
//        uiView.attachAudio(entityData: uiView.boxEntityData, url: arViewAudioData.url)
    }
    
    
}

class ARViewTest: ARView {
    /// assets
    var boxEntity: Entity!
    var capsuleEntity: Entity!
    var sphereEntity: Entity!
//    let myView = UIView(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
    var audioPlaybackController: AudioPlaybackController?
    var entityDataArray: [EntityData] = []
    var boxEntityData: EntityData!
    var capsuleEntityData: EntityData!
    var sphereEntityData: EntityData!

    var selectedEntityData: EntityData?

    /// init
    required init() {
        super.init(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)

//        self.myView.backgroundColor = .blue
//        self.addSubview(myView)

        let boxAnchor = try! Experience.loadMyScene()
        self.scene.anchors.append(boxAnchor)

        boxEntity = self.scene.findEntity(named: "Steel Box")

        //add CollisionComponent for hitTest
        boxEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])]) //can get self size???


        capsuleEntity = self.scene.findEntity(named: "capsule")
        capsuleEntity.setPosition([1,0,0], relativeTo: nil)
        capsuleEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateCapsule(height: 0.2, radius: 0.05)])//radius vs diameter??? bottom does not respond with tapping
//        let mesh: MeshResource = capsuleEntity.generateCollisionShapes(recursive:false)


        sphereEntity = self.scene.findEntity(named:"ball")
        sphereEntity.setPosition([2,0,0], relativeTo: nil)

        sphereEntity.components[CollisionComponent] = CollisionComponent(shapes: [ .generateSphere(radius: 0.05)])
//        sphereEntity.components[CollisionComponent] = CollisionComponent(shapes: [       .generateCollisionShapes(recursive: true)])
//        sphereEntity.generateCollisionShapes(recursive: true)


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
                    print("entity audio url: \(entityDataArray[index].audioURL)")
                }
                entityDataArray[index].isSelected = true
//                selectedEntityData = entityDataArray[index]
//                print("selectedEntityData:\(selectedEntityData?.entity)" )
                print("selectedEntityData:\(entity)" )

            }
            else {
                entityDataArray[index].isSelected = false
            }
        }

    }

    func attachAudio(entityData: EntityData, url: URL){
        entityData.audioURL = url
//        let loadedAudio = try? AudioFileResource.load(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
//        entityData.audio = loadedAudio
//        entityData.audioPlaybackController = entityData.entity.prepareAudio(loadedAudio!)
        
        ///[Audio] Failed to read file: (null)?????
        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")
        }, receiveValue: { loadedAudio in
            print("here")

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
        
        guard let fileName = audioFileName else {return}
//        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
        let loadRequest = AudioFileResource.loadAsync(named: fileName, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: audioShouldLoop!)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")
        }, receiveValue: { loadedAudio in
            self.audio = loadedAudio
            self.audioPlaybackController = self.entity.prepareAudio(loadedAudio)
        })
        loadRequest.subscribe(observer)
    }
}




final class ARViewAudioData: ObservableObject  {
    
//    @Published var url: URL? = nil
    @Published var url: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    //publishing url from exported audio
    let urlSubject = PassthroughSubject<URL, Never>()
    
    var arViewTest: ARViewTest?
}


class EntitiesModel: ObservableObject {

    var willChange = PassthroughSubject<AudioEngine, Never>()
    
    var boxEntity: Entity!
    var sphereEntity: Entity!
    var capsuleEntity: Entity!
    var boxEntityData: EntityData!
    var capsuleEntityData: EntityData!
    var sphereEntityData: EntityData!
    var entityDataArray: [EntityData] = []
    var selectedEntityData: EntityData?

    init() {
        let metal = SimpleMaterial(color:.gray, isMetallic:true)
        boxEntity = ModelEntity(mesh:MeshResource.generateBox(size: [0.1,0.1,0.1]), materials: [metal])
        boxEntityData = EntityData(entity: boxEntity, audioFileName: nil, audioShouldLoop: false)
        boxEntity.setPosition([0,0,0], relativeTo: nil)
        boxEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])]) //can get self size???

        capsuleEntity = ModelEntity(mesh:MeshResource.generateSphere(radius: 0.1), materials:[metal])
        capsuleEntityData = EntityData(entity: capsuleEntity, audioFileName: nil, audioShouldLoop: false)
        capsuleEntity.setPosition([0.5,0,0], relativeTo: nil)
        capsuleEntity.components[CollisionComponent] = CollisionComponent(shapes: [.generateSphere(radius: 0.1)])//radius vs diameter??? bottom does not respond with tapping

        sphereEntity = ModelEntity(mesh:MeshResource.generateSphere(radius: 0.07), materials: [metal])
        sphereEntityData = EntityData(entity: sphereEntity, audioFileName: nil, audioShouldLoop: false)
        sphereEntity.setPosition([1,0,0], relativeTo: nil)
        sphereEntity.components[CollisionComponent] = CollisionComponent(shapes: [ .generateSphere(radius: 0.05)])

        entityDataArray = [boxEntityData, capsuleEntityData, sphereEntityData]
    }

    func attachAudio(entityData: EntityData, url: URL){
        entityData.audioURL = url
        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
            print("completed")
        }, receiveValue: { loadedAudio in
            entityData.audio = loadedAudio
            entityData.audioPlaybackController = entityData.entity.prepareAudio(loadedAudio)
            print("successfully attacheed")
        })
        loadRequest.subscribe(observer)
    }

}
//
//
//class ARViewTest: ARView {
//    /// assets
//
//    @ObservedObject var entitiesModel : EntitiesModel
//
//    /// init
//    required init(entitiesModel: EntitiesModel) {
//        self.entitiesModel = entitiesModel
//        super.init(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
//
////        self.myView.backgroundColor = .blue
////        self.addSubview(myView)
//
//        let myAnchor = try! Experience.loadMyScene()
//        self.scene.anchors.append(myAnchor)
//
//        myAnchor.addChild(entitiesModel.boxEntity)
//        myAnchor.addChild(entitiesModel.capsuleEntity)
//        myAnchor.addChild(entitiesModel.sphereEntity)
//
//        let tap = UITapGestureRecognizer(target:self, action: #selector(handleTap(_:)))
//        self.addGestureRecognizer(tap)
//        self.isUserInteractionEnabled = true
//    }
//
//    @objc func handleTap(_ sender: UITapGestureRecognizer){
//        print("tapped")
//        let location = sender.location(in: self)
//        guard let hitEntity = self.entity(at: location) else { return }
//        print("hitEntity: \(hitEntity)")
//        let entities = entitiesModel.entityDataArray.map({ $0.entity })
//        for (index, entity) in entities.enumerated() {
//            if hitEntity == entity {
//                if let audioPlaybackController = entitiesModel.entityDataArray[index].audioPlaybackController {
//                    audioPlaybackController.play()
//                    print("entity audio: \(entitiesModel.entityDataArray[index].audioURL)")
//                }
//                entitiesModel.entityDataArray[index].isSelected = true
////                selectedEntityData = entityDataArray[index]
////                print("selectedEntityData:\(selectedEntityData?.entity)" )
//
//            }
//            else {
//                entitiesModel.entityDataArray[index].isSelected = false
//            }
//        }
//
//    }
//
////    func attachAudio(entityData: EntityData, url: URL){
////        entityData.audioURL = url
////        let loadRequest = AudioFileResource.loadAsync(contentsOf: url, withName: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
////        let observer = Subscribers.Sink<AudioFileResource, Error>(receiveCompletion: { completion in
////            print("completed")
////        }, receiveValue: { loadedAudio in
////            entityData.audio = loadedAudio
////            entityData.audioPlaybackController = entityData.entity.prepareAudio(loadedAudio)
////            print("successfully attacheed")
////        })
////        loadRequest.subscribe(observer)
////    }
//
//
//    @available(*, unavailable)
//    @objc required dynamic init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @available(*, unavailable)
//    @objc required dynamic init(frame frameRect: CGRect) {
//        fatalError("init(frame:) has not been implemented")
//    }
//}
