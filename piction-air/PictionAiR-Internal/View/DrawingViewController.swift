//
//  DrawingViewController.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 8/31/23.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity
import UIColorHexSwift

class DrawingViewController: UIViewController {
    private static let sphereAnchorName = "sphereAnchor"
    
    var arPictionaryGame: ARPictionaryGame?
    private var sceneView: ARSCNView!
    private var lastActionList: [Int] = []
    private var lastUndoneActionList: [Int] = []
    
    private var strokes: [[ARAnchor]] = []
    private var strokesDeleted: [[ARAnchor]] = []
    
    
    var nodeManager : NodeManager = NodeManager(penColor: .red, defaultSphereRadius: 0.005)
    var lastTransform: simd_float4x4?
    {
        didSet {
            DispatchQueue.main.async {
                self.arPictionaryGame?.canAnalyzeDrawing = (self.lastTransform != nil)
            }
        }
    }
    var myAnchors: [ARAnchor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
//        arPictionaryGame?.canAnalyzeDrawing = false
        sceneView.preferredFramesPerSecond = 60
        sceneView.delegate = self
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        beginMultiplayerSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard arPictionaryGame?.gameMode == .freeDraw || arPictionaryGame?.myPlayer?.isDrawer == true, let touch = touches.first else { return }
                
        if arPictionaryGame!.isCurrentlyDrawing {
            lastUndoneActionList = []
            lastActionList.append(1)
            strokesDeleted = []
            strokes.append([])
            createSphereAnchor(at: touch)
        } else {
            lastUndoneActionList = []
            lastActionList.append(-1)
            strokesDeleted = []
            strokes.append([])
            eraseSphereAnchor(at: touch)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard arPictionaryGame?.gameMode == .freeDraw || arPictionaryGame?.myPlayer?.isDrawer == true, let touch = touches.first else { return }
        
        if arPictionaryGame!.isCurrentlyDrawing {
            createSphereAnchor(at: touch)
        } else {
            eraseSphereAnchor(at: touch)
        }
    }
    
    @objc
    func beginMultiplayerSession() {
        arPictionaryGame?.didReceiveDataHandler = self.receivedData
        arPictionaryGame?.arSnapshotHandler = self.snapShot
        arPictionaryGame?.undoHandler = self.undoStroke
        arPictionaryGame?.redoHandler = self.redoStroke
        arPictionaryGame?.clearHandler = self.clearAllAnchors
        arPictionaryGame?.imageRecognitionHandler = self.imageRecognition

        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.arPictionaryGame?.multipeerSession?.sendToAllPeers(data, reliably: true)
        }
    }
    
    private func snapShot() {
        let image = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func undoStroke() {
        print(strokes)
        if strokes.count > 0 {
            print("UNDO UNDO UNDO")
            let stroke = strokes.removeLast()
            strokesDeleted.append(stroke)
            let action = lastActionList.removeLast()
            lastUndoneActionList.append(action)
            if action == 1 {
                for anchor in stroke {
                    sceneView.session.remove(anchor: anchor)
                    sendAnchorIdToMultipeers(anchorId: anchor.identifier.uuidString)
                }
            } else if action == -1 {
                for anchor in stroke {
                    sceneView.session.add(anchor: anchor)
                    sendToMultipeers(anchor)
                }
            }
        }
    }
    
    
    private func redoStroke() {
        if strokesDeleted.count > 0 {
            print("REDO REDO REDO")
            let stroke = strokesDeleted.removeLast()
            strokes.append(stroke)
            let action = lastUndoneActionList.removeLast()
            lastActionList.append(action)
            if action == 1 {
                for anchor in stroke {
                    sceneView.session.add(anchor: anchor)
                    sendToMultipeers(anchor)
                }
            } else if action == -1 {
                for anchor in stroke {
                    sceneView.session.remove(anchor: anchor)
                    sendAnchorIdToMultipeers(anchorId: anchor.identifier.uuidString)
                }
            }
        }
    }
    
    
    // MARK: - Private
    
    private func createSphereAnchor(at touchLocation: UITouch) {
        guard let touchPositionInFrontOfCamera = sceneView.position(of: touchLocation.location(in: sceneView))
        else { return }
        
        let sphereAnchor = ARAnchor(name: "\(nodeManager.penColor.hexString()),\(nodeManager.defaultSphereRadius)",
                                    transform: float4x4(SIMD4(1, 0, 0, 0),
                                                        SIMD4(0, 1, 0, 0),
                                                        SIMD4(0, 0, 1, 0),
                                                        SIMD4(touchPositionInFrontOfCamera.x,
                                                              touchPositionInFrontOfCamera.y,
                                                              touchPositionInFrontOfCamera.z,
                                                              1)
                                                       )
        )
        strokes[strokes.endIndex-1].append(sphereAnchor)
        myAnchors.append(sphereAnchor)
        sceneView.session.add(anchor: sphereAnchor)
        sendToMultipeers(sphereAnchor)
    }
    
    private func createSphereNode(withColor color: UIColor, withRadius radius: CGFloat) -> SCNNode {
        // Get the reference sphere node and clone it
        let referenceSphereNode = nodeManager.sphereNode(color, radius)
        let newSphereNode = referenceSphereNode.clone()
        
        return newSphereNode
    }
    
    private func eraseSphereAnchor(at touchLocation: UITouch) {
        guard let touchPositionInFrontOfCamera = sceneView.position(of: touchLocation.location(in: sceneView))
        else { return }


        guard let cameraPosition = sceneView.cameraPosition else {return}
        let results = sceneView.scene.rootNode.hitTestWithSegment(from: cameraPosition, to: touchPositionInFrontOfCamera)
        for res in results {
            guard let anchor = sceneView.anchor(for: res.node) else { return }
            strokes[strokes.endIndex-1].append(anchor)
            sceneView.session.remove(anchor: anchor)
            sendAnchorIdToMultipeers(anchorId: anchor.identifier.uuidString)
        }
    }
    
    private func clearAllAnchors() {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors {
            sceneView.session.remove(anchor: anchor)
            sendAnchorIdToMultipeers(anchorId: anchor.identifier.uuidString)
        }
    }
    
    
    private func clearOnlyMyAnchors() {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in myAnchors {
            if (frame.anchors.contains(anchor)) {
                sceneView.session.remove(anchor: anchor)
                sendAnchorIdToMultipeers(anchorId: anchor.identifier.uuidString)
            }
        }
        myAnchors = []
    }
    
    private func imageRecognition() {
        let temp = sceneView.scene.background.contents
        // we can make a secondary model for other phone iOS in future
        if #available(iOS 17.0, *) {
            do {
                let model = try PictionAiRFruitClassifier()
                sceneView.isOpaque = false
                sceneView.scene.background.contents = UIColor.white
                let image = sceneView.snapshot()
                sceneView.scene.background.contents = temp
                
                
                
                
                guard let pixelBuffer = image.buffer() else {
                    fatalError("Couldn't convert image")
                }
                
                guard let predictionOutput = try? model.prediction(image: pixelBuffer) else {
                    fatalError("Unexpected runtime error.")
                }

                self.clearOnlyMyAnchors()
                
                let prediction = predictionOutput.target
                let chance = predictionOutput.targetProbability
                
                makeFruitAnchor(name: prediction)
                print(prediction)
                print(chance)
            } catch {
                print("Error initializing PictionAiRFruitClassifier: \(error)")
            }
        } else {
            print("iOS version is older than 17.0. PictionAiRFruitClassifier is not available.")
        }
    }
    
    private func makeFruitAnchor(name : String) {
        let anchor = ARAnchor(name: name, transform: lastTransform!)
        sceneView.session.add(anchor: anchor)
        sendToMultipeers(anchor)
    }
    
    private func createFruitNode(name: String) -> SCNNode {
        if name == "apple" {
            let appleScene = SCNScene(named: "apple.scn")
            guard let appleNode = appleScene?.rootNode.childNode(withName: "apple", recursively: true) else {
                fatalError("Can't find apple!!!")
            }
            let scaleFactor: Float = 0.02  // Adjust this value as needed
            appleNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            return appleNode
        } else if name == "strawberry" || name == "broccoli" {
            let strawberryScene = SCNScene(named: "strawberry.scn")
            guard let strawberryNode = strawberryScene?.rootNode.childNode(withName: "strawberry", recursively: true) else {
                fatalError("Can't find strawberry!!!")
            }
            let scaleFactor: Float = 0.4  // Adjust this value as needed
            strawberryNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            return strawberryNode
        } else if name == "orange" {
            let orangeScene = SCNScene(named: "orange.scn")
            guard let orangeNode = orangeScene?.rootNode.childNode(withName: "orange", recursively: true) else {
                fatalError("Can't find orange!!!")
            }
            
            let scaleFactor: Float = 0.05  // Adjust this value as needed
            orangeNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            return orangeNode
        } else {
            let orangeScene = SCNScene(named: "orange.scn")
            guard let orangeNode = orangeScene?.rootNode.childNode(withName: "orange", recursively: true) else {
                fatalError("Can't find orange!!!")
            }
            
            let scaleFactor: Float = 0.05  // Adjust this value as needed
            orangeNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            return orangeNode
        }
    }
    
    private func sendToMultipeers(_ anchor: ARAnchor) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        self.arPictionaryGame?.multipeerSession?.sendToAllPeers(data, reliably: true)
        print("SENDING DATA!!!!")
    }
    
    
    private func sendAnchorIdToMultipeers(anchorId: String) {
        let nsId = NSString(string: anchorId)
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: nsId, requiringSecureCoding: true)
            else { fatalError("can't encode anchor id") }
        self.arPictionaryGame?.multipeerSession?.sendToAllPeers(data, reliably: true)
        print("SENDING DATA!!!!")
    }
    
    private func receivedData(_ data: Data, from peer: MCPeerID) {
        if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
            // Run the session with the received world map.
            let configuration = ARWorldTrackingConfiguration()
            configuration.initialWorldMap = worldMap
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("NEW USER!!!")
        } else if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
            sceneView.session.add(anchor: anchor)
            print("NEW ANCHOR!!!")
        } else if let anchorId = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) {
            let anchors = sceneView.session.currentFrame?.anchors ?? []
            for anchor in anchors {
                if anchor.identifier.uuidString == String(anchorId) {
                    sceneView.session.remove(anchor: anchor)
                    break
                }
            }
        }
    }
}

extension DrawingViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This is only used when loading a worldMap
        if let name = anchor.name {
            if name == "apple" || name == "strawberry" || name == "orange" || name == "broccoli" {
                node.addChildNode(createFruitNode(name: name))
            } else if name.hasPrefix("#") {
                print("anchorName: ", name)
                let identifiers = name.split(separator: ",").map { String($0) }
                
                let sphereColor = UIColor(identifiers[0])
                let radius = Double(identifiers[1])
                let r = CGFloat(radius!)
                node.addChildNode(createSphereNode(withColor: sphereColor, withRadius: r))
                lastTransform = myAnchors.last?.transform
            }
        }
    }
}
