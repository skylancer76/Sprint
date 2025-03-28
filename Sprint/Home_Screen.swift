import UIKit

class Home_Screen: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var addNewCollection: UIImageView!
    
    static var notes: [Note] = []
    
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
        
        // Enable interaction for the "addNewCollection" image
        addNewCollection.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addNewCollectionTapped))
        addNewCollection.addGestureRecognizer(tapGesture)
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fetch notes from the server
        Note.fetchAllNotes { result in
            switch result {
            case .success(let notes):
                print("Fetched notes: \(notes)")
                DispatchQueue.main.async {
                    Home_Screen.notes = notes
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("Failed to fetch notes:", error)
            }
        }
    }
    

    // MARK: - UICollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the selected note from your data source.
        let selectedNote = Home_Screen.notes[indexPath.item]
        // Perform the segue, passing the selected note as the sender.
        performSegue(withIdentifier: "goToNote", sender: selectedNote)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNote",
           let destinationVC = segue.destination as? Note_Screen,
           let selectedNote = sender as? Note {
            destinationVC.note = selectedNote
        }
    }


    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return Home_Screen.notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Collection",
            for: indexPath
        ) as? HomeCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let item = Home_Screen.notes[indexPath.item]
        
        cell.noteTitleLabel.text = item.title
        cell.secBackView.layer.cornerRadius = 12
        
        // If you just want plain text from the body, do item.body.string
        cell.firstViewLettersLabel.text = item.body.string
        
        return cell
    }
    
    
    @objc func addNewCollectionTapped() {
        performSegue(withIdentifier: "goToNote", sender: self)
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 20
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            return section
        }
    }
}
