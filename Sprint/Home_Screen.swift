//
//  ViewController.swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import UIKit

class Home_Screen: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    @IBOutlet var collectionView: UICollectionView!
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
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(notes.count)
        return notes.count
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Note.fetchAllNotes { result in
            switch result {
            case .success(let notes):
                print("Fetched notes: \(notes)")
                DispatchQueue.main.async {
                                self.notes = notes
                                self.collectionView.reloadData()
                            }
            case .failure(let error):
                print("Failed to fetch notes:", error)
            }
        }
     
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "Collection",
                for: indexPath
        ) as? HomeCollectionViewCell else {
                // Fallback to a default cell if casting fails
                return UICollectionViewCell()
            }
            
            // 2. Get the data for this index.
        let item = notes[indexPath.item]
        
            
            // 3. Configure the cell’s UI elements.
//        cell.dateLabel.text = item.dateString
//            cell.myImageView.image = UIImage(named: item.imageName)
        cell.noteTitleLabel.text = item.title
        cell.secBackView.layer.cornerRadius = 12
        cell.firstViewLettersLabel.text = item.body.string
//            cell.subtitleLabel.text = item.subtitle
            
            // 4. Return the configured cell.
            return cell
        
    }
    
    @IBOutlet weak var addNewCollection: UIImageView!
    
    var notes: [Note] = []
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // 1) Define how each item fills its group
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 2) Define the group to be the full width of the collection
            //    with a fixed height (adjust to fit your design).
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(180) // or 200, etc.
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // 3) Create a section with the group, and add some spacing/insets
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            
            return section
        }
    }

    
    @objc func addNewCollectionTapped() {
        performSegue(withIdentifier: "goToNote", sender: self)
    }

}

