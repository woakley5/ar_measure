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
        
    var dotNode1: ModelEntity?
    var dotNode2: ModelEntity?

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
        
        guard let tapLocation = sender?.location(in: arView), let rayCastResult = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first else {
            print("Oops something went wrong")
            return
        }
        
        // result is RayCast from the view port onto the world mesh and get the first hit
        let pos = rayCastResult.worldTransform
        let resultAnchor = AnchorEntity(world: pos)
        
        // Put a dot centered on the result of the raycast
        let currDot = createDot()
        resultAnchor.addChild(currDot)
        arView.scene.addAnchor(resultAnchor)
        
        // If there are no dots already, set the first
        if dotNode1 == nil && dotNode2 == nil {
            dotNode1 = currDot;
        // If theres one dot set, set the second and calculate the distance to show
        } else if dotNode2 == nil {
            dotNode2 = currDot;
            distanceLabel.text = "Distance: \(String(describing: getDistance()))\""
        // If theres two dots set, clear it and reset the label
        } else {
            arView.scene.anchors.removeAll();
            dotNode1 = nil;
            dotNode2 = nil;
            distanceLabel.text = "Distance: -"
        }
    }
    
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

