//
//  ViewController.swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import UIKit

class Home_Screen: UIViewController {
    @IBOutlet weak var addNewCollection: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up gradient background.
        let gradientView = UIView(frame: view.bounds)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.systemPurple.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.5)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
    
        // Enable interaction
        addNewCollection.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addNewCollectionTapped))
        addNewCollection.addGestureRecognizer(tapGesture)
    }
    
    @objc func addNewCollectionTapped() {
        performSegue(withIdentifier: "goToNote", sender: self)
    }

}

