import UIKit

class AIViewController: UIViewController {
    
    /// The initial AI-generated text as an attributed string.
    var aiInitialAttributedText: NSAttributedString = NSAttributedString(
        string: "Loading...",
        attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16)
        ]
    )
    
    /// Closure to return the updated text back to the Note screen.
    var onReplace: ((NSAttributedString) -> Void)?
    
    private let aiTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set overall view background to black.
        view.backgroundColor = .black
        
        title = "AI Assistant"
        
        // Set up navigation bar items.
        let redoItem = UIBarButtonItem(title: "Redo", style: .plain, target: self, action: #selector(redoTapped))
        let replaceItem = UIBarButtonItem(title: "Replace", style: .done, target: self, action: #selector(replaceTapped))
        navigationItem.leftBarButtonItem = redoItem
        navigationItem.rightBarButtonItem = replaceItem
        
        // Configure the text view.
        aiTextView.frame = view.bounds
        aiTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        aiTextView.backgroundColor = .black
        aiTextView.textColor = .white
        aiTextView.font = UIFont.systemFont(ofSize: 16)
        aiTextView.keyboardAppearance = .dark
        view.addSubview(aiTextView)
        
        // Display the initial AI-generated attributed text.
        aiTextView.attributedText = aiInitialAttributedText
    }
    
    @objc func redoTapped() {
        // Optionally, call your AI endpoint again here.
        // For demonstration, we append new text with a larger font (scaled up).
        let mutable = NSMutableAttributedString(attributedString: aiTextView.attributedText)
        let extraAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18)  // Scaling up the font size
        ]
        let extraText = NSAttributedString(string: "\nAnother suggestion...", attributes: extraAttributes)
        mutable.append(extraText)
        aiTextView.attributedText = mutable
    }
    
    @objc func replaceTapped() {
        // Ensure the entire text uses white color before replacing.
        let mutable = NSMutableAttributedString(attributedString: aiTextView.attributedText)
        let range = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: UIColor.white, range: range)
        
        onReplace?(mutable)
        dismiss(animated: true)
    }
}
