import UIKit

class AIViewController: UIViewController {
    
    /// The AI-generated text to display as an NSAttributedString.
    var aiInitialAttributedText: NSAttributedString = NSAttributedString(string: "Loading...", attributes: [.foregroundColor: UIColor.white])
    
    /// Closure to return the updated text back to the Note screen.
    var onReplace: ((NSAttributedString) -> Void)?
    
    private let aiTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AI Assistant"
        
        // Set up navigation bar items.
        let redoItem = UIBarButtonItem(title: "Redo", style: .plain, target: self, action: #selector(redoTapped))
        let replaceItem = UIBarButtonItem(title: "Replace", style: .done, target: self, action: #selector(replaceTapped))
        navigationItem.leftBarButtonItem = redoItem
        navigationItem.rightBarButtonItem = replaceItem
        
        // Configure the text view.
        aiTextView.frame = view.bounds
        aiTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        aiTextView.backgroundColor = .clear
        aiTextView.textColor = .white
        aiTextView.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(aiTextView)
        
        // Display the initial AI text.
        aiTextView.attributedText = aiInitialAttributedText
    }
    
    @objc func redoTapped() {
        // Optionally, re-call the AI endpoint here. For now, we simply append a new suggestion.
        let mutable = NSMutableAttributedString(attributedString: aiTextView.attributedText)
        let extra = NSAttributedString(string: "\nAnother suggestion...", attributes: [.foregroundColor: UIColor.white])
        mutable.append(extra)
        aiTextView.attributedText = mutable
    }
    
    @objc func replaceTapped() {
        // Ensure the entire text is set to white.
        let mutable = NSMutableAttributedString(attributedString: aiTextView.attributedText)
        let range = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: UIColor.white, range: range)
        
        // Call the onReplace closure with the updated text.
        onReplace?(mutable)
        dismiss(animated: true)
    }
}
