//
//  ViewController.swift
//  FurAR
//
//  Created by Daniel Novoa on 28/03/2019.
//  Copyright © 2019 PAE. All rights reserved.
///Users/danielnovoa/Documents/UNI/PAE/FurAR/FurAR

import UIKit
import SceneKit
import ARKit
import Foundation
import SocketIO

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let manager = SocketManager(socketURL: URL(string: "http://23.97.190.244:3000/")!, config: [.log(true), .compress])
    
    var socket:SocketIOClient!
    
    var model: Bool!
    
    var config: Int!
    
    var scene: SCNNode!


    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureToSceneView()              //Añadimos funcion para añadir barcos
        configureLighting()                     //Configuramos la luz
        
        self.config = 0
        self.socket = manager.defaultSocket;
        self.setSocketEvents();
        self.model = false
       
        self.socket.connect()
        
//        self.loadghost()

    }
    private func setSocketEvents()
    {
        self.socket.on(clientEvent: .connect) {data, ack in
            print("socket connected");
        };
        
        self.socket.on("change") {data, ack in
            print("fe")
            guard let s = data[0] as? String else { return }
            self.changeModel(name: s )
            
        };
        self.socket.on("ghost") {data, ack in
            print("fe")
            self.loadghost()
            
        };
        self.socket.on("ogre") {data, ack in
            print("fe")
            self.load()
            
        };
    };
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()                                        //Cargamos configuracion
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView(){
        
        let configuration = ARWorldTrackingConfiguration()                    // Creamos session de configuration
        configuration.planeDetection = .horizontal                            // Cargamos detecion de plano horizontal
        sceneView.session.run(configuration)                                  // Ejecutamos la sesion del view
        
        sceneView.delegate = self
        if (config == 1){
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]      // Opciones de debug ( Puntitos para localizar planos)
        }
        sceneView.showsStatistics = false                                       // Mostrar info FPS tiempo de carga etc..
    
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    //Funcion load animation
    func loadghost () {
        
        if ( self.model ){
            self.scene.removeFromParentNode()
        }
        // Load the character in the idle animation
        let idleScene = SCNScene(named: "art.scnassets/goast/sambaFixed.dae")!
        
        // This node will be parent of all the animation models
        let node = SCNNode()
        
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        // Set up some properties
        node.position = SCNVector3(-5, -1, -5)
        node.scale = SCNVector3(1, 1, 1)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(node)
        
        self.scene = node
        self.model = true
    
    }
    //Funcion para cargar X
    func load() {
        
        if ( self.model ){
            self.scene.removeFromParentNode()
        }
        // Load the character in the idle animation
        let idleScene = SCNScene(named: "art.scnassets/goast/toy_robot_vintage.usdz")!
        
        // This node will be parent of all the animation models
        let node = SCNNode()
        
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        // Set up some properties
        node.position = SCNVector3(6, -1, -5)
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(node)
        
        self.scene = node
        self.model = true
        
    }

    //Funcion para poner objetos
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        print("Ship")
        
        if ( !self.model && self.config == 1){
            let tapLocation = recognizer.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            
            guard let hitTestResult = hitTestResults.first else { return }
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y
            let z = translation.z
            
            //self.socket.emit("coca",["ndklsnf"] )
            
            guard let shipScene = SCNScene(named: "scene.scn", inDirectory: "art.scnassets/goast" ),
                let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: false)
                else { return }
            
            self.model = true
            shipNode.position = SCNVector3(x,y,z)
            sceneView.scene.rootNode.addChildNode(shipNode)
            
            self.scene = shipNode
    
            
        }
    }
    //Funcion para cambiar el modelo
    func changeModel(name: String){
    
        print(name)
        
        if ( self.model ){
            
            //Cargamos el modelo
            guard let scene = SCNScene(named: name + ".scn", inDirectory: "art.scnassets/" + name ),
                let node = scene.rootNode.childNode(withName: name, recursively: false)
                else { return }
            
            node.position = self.scene.position                 //Asignamos la poscion donde se encontama el modelo anterior
            self.scene.removeFromParentNode()                   //Eliminamos el modelo anterior
            sceneView.scene.rootNode.addChildNode(node)         //Añadimos el modelo nuevo
            
            self.scene = node
            
            
        }
    }
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    
    
    /* *********************************** */
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    
    }
    /* *********************************** */



}
//extension ViewController{
//
//    //Pinta planos
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        let plane = SCNPlane(width: width, height: height)
//
//        // 3
//        //plane.materials.first?.diffuse.contents = UIColor.blue
//
//        // 4
//        let planeNode = SCNNode(geometry: plane)
//
//        // 5
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x,y,z)
//        planeNode.eulerAngles.x = -.pi / 2
//
//        // 6
//        node.addChildNode(planeNode)
//    }
//
//    //Expande planos ya pintados
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as?  ARPlaneAnchor,
//            let planeNode = node.childNodes.first,
//            let plane = planeNode.geometry as? SCNPlane
//            else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        plane.width = width
//        plane.height = height
//
//        // 3
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x, y, z)
//    }
//}
extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}


