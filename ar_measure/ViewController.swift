//
//  ViewController.swift
//  ar_measure
//
//  Created by Will Oakley on 10/6/24.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var arView: ARView!
        
    // Storing the dot1 and dot2 to calc distance btwn
    var dotNode1: ModelEntity?
    var dotNode2: ModelEntity?
    
    var bestDot: ModelEntity?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        arView.session.delegate = self
        
        // Setup the AR Tracking configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        arView.session.run(configuration)
        
        self.arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleViewTap(_:))))
    }
    
    @objc
    func handleViewTap(_ sender: UITapGestureRecognizer? = nil) {
        
        guard let tapLocation = sender?.location(in: arView), let rayCastQuery = arView.makeRaycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .any) else {
            print("Oops something went wrong")
            return
        }
        
        arView.session.trackedRaycast(rayCastQuery) { results in
            print("CLOSURE CALLED")
            print(results)
            
            
            guard let res = results.first else {
                return
            }
            
            if self.bestDot != nil {
                self.arView.scene.anchors.removeAll();
            }
                
            let resultAnchor = AnchorEntity(world:res.worldTransform)
            
            let currDot = self.createDot()
            resultAnchor.addChild(currDot)
            self.arView.scene.addAnchor(resultAnchor)
            
            self.bestDot = currDot
        }
    }
    
    // Generate the dot entity
    func createDot() -> ModelEntity {
        let dot = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        dot.position.y = 0.02
        return dot
    }
    
    func getDistance() -> Double {
        // Get position relative to world space
        guard let pos1 = dotNode1?.position(relativeTo: nil), let pos2 = dotNode2?.position(relativeTo: nil) else {
            return -1.0
        }
                
        // 3D Vector distance sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
        let x = pow(pos2.x - pos1.x, 2)
        let y = pow(pos2.y - pos1.y, 2)
        let z = pow(pos2.z - pos1.z, 2)
        let meters = Double(sqrt(x + y + z))
        
        // ARKit positions in m -> convert to in
        let inches = Measurement(value: meters, unit: UnitLength.meters)
            .converted(to: UnitLength.inches).value
        return round(1000.0 * inches) / 1000.0 // Nearest hundredth
    }

}

