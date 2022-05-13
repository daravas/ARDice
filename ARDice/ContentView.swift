//
//  ContentView.swift
//  ARDice
//
//  Created by Ilia on 13/05/22.
//
import ARKit
import RealityKit
import SwiftUI
import FocusEntity

struct RealityKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView()
        
        // Start AR session
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)
        
        // Set debug options
#if DEBUG
        view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif
        
        // Handle ARSession events via delegate
        context.coordinator.view = view
        session.delegate = context.coordinator
        
        // Handle taps
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )
        
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            debugPrint("Anchors added to the scene: ", anchors)
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            // Create a new anchor to add content to
            let anchor = AnchorEntity()
            view.scene.anchors.append(anchor)
            
            // Add a dice entity
            let diceEntity = try! ModelEntity.loadModel(named: "Dice")
            diceEntity.scale = [0.1, 0.1, 0.1]
            diceEntity.position = focusEntity.position
            
            let size = diceEntity.visualBounds(relativeTo: diceEntity).extents
            let boxShape = ShapeResource.generateBox(size: size)
            diceEntity.collision = CollisionComponent(shapes: [boxShape])
            
            diceEntity.physicsBody = PhysicsBodyComponent(
                massProperties: .init(shape: boxShape, mass: 50),
                material: nil,
                mode: .dynamic
            )
            
            // Create a plane below the dice
            let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
            let material = SimpleMaterial(color: .init(white: 1.0, alpha: 0.1), isMetallic: false)
            let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
            planeEntity.position = focusEntity.position
            planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
            planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.001, depth: 2)])
            planeEntity.position = focusEntity.position
            
            anchor.addChild(diceEntity)
            anchor.addChild(planeEntity)
            
            diceEntity.addForce([0, 2, 0], relativeTo: nil)
            diceEntity.addTorque([Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4)], relativeTo: nil)
        }
    }
    
    func updateUIView(_ view: ARView, context: Context) {
    }
}

struct ContentView: View {
    var body: some View {
        RealityKitView()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
