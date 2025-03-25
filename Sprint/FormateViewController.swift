import UIKit

class FormatViewController: UIViewController {
    
    @IBOutlet weak var styleSegmentedControl: UISegmentedControl!  // Title, Heading, Subheading, Body
    @IBOutlet weak var boldButton: UIButton!
    @IBOutlet weak var italicButton: UIButton!
    @IBOutlet weak var underlineButton: UIButton!
    @IBOutlet weak var strikethroughButton: UIButton!
    @IBOutlet weak var bulletButton: UIButton!
    
    weak var targetTextView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func styleSegmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: applyTextStyle(.title)
        case 1: applyTextStyle(.heading)
        case 2: applyTextStyle(.subheading)
        case 3: applyTextStyle(.body)
        default: break
        }
    }
    
    @IBAction func boldButtonTapped(_ sender: Any) {
        applyToggleAttribute(.bold)
    }
    
    @IBAction func italicButtonTapped(_ sender: Any) {
        applyToggleAttribute(.italic)
    }
    
    @IBAction func underlineButtonTapped(_ sender: Any) {
        applyToggleAttribute(.underline)
    }
    
    @IBAction func strikethroughButtonTapped(_ sender: Any) {
        applyToggleAttribute(.strikethrough)
    }
    
    @IBAction func bulletButtonTapped(_ sender: Any) {
        applyBulletList()
    }
    
    enum TextStyle {
        case title, heading, subheading, body
    }
    
    private func applyTextStyle(_ style: TextStyle) {
        guard let textView = targetTextView else { return }
        let selectedRange = textView.selectedRange
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        let font: UIFont
        switch style {
        case .title:      font = UIFont.boldSystemFont(ofSize: 24)
        case .heading:    font = UIFont.boldSystemFont(ofSize: 20)
        case .subheading: font = UIFont.systemFont(ofSize: 18)
        case .body:       font = UIFont.systemFont(ofSize: 16)
        }
        
        mutableText.addAttribute(.font, value: font, range: selectedRange)
        mutableText.addAttribute(.foregroundColor, value: UIColor.white, range: selectedRange)
        
        textView.attributedText = mutableText
        textView.selectedRange = selectedRange
    }
    
    enum ToggleAttribute {
        case bold, italic, underline, strikethrough
    }
    
    private func applyToggleAttribute(_ attribute: ToggleAttribute) {
        guard let textView = targetTextView else { return }
        let selectedRange = textView.selectedRange
        if selectedRange.length == 0 { return }
        
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        mutableText.enumerateAttributes(in: selectedRange, options: []) { attrs, range, _ in
            var newAttrs = attrs
            
            switch attribute {
            case .bold:
                if let currentFont = attrs[.font] as? UIFont {
                    let descriptor = currentFont.fontDescriptor
                    if descriptor.symbolicTraits.contains(.traitBold) {
                        // Remove bold
                        if let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitBold)) {
                            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                            newAttrs[.font] = newFont
                        }
                    } else {
                        // Add bold
                        if let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitBold)) {
                            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                            newAttrs[.font] = newFont
                        }
                    }
                }
            case .italic:
                if let currentFont = attrs[.font] as? UIFont {
                    let descriptor = currentFont.fontDescriptor
                    if descriptor.symbolicTraits.contains(.traitItalic) {
                        // Remove italic
                        if let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitItalic)) {
                            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                            newAttrs[.font] = newFont
                        }
                    } else {
                        // Add italic
                        if let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) {
                            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                            newAttrs[.font] = newFont
                        }
                    }
                }
            case .underline:
                if let underlineStyle = attrs[.underlineStyle] as? Int, underlineStyle != 0 {
                    newAttrs[.underlineStyle] = 0
                } else {
                    newAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
            case .strikethrough:
                if let strikeStyle = attrs[.strikethroughStyle] as? Int, strikeStyle != 0 {
                    newAttrs[.strikethroughStyle] = 0
                } else {
                    newAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
            }
            
            newAttrs[.foregroundColor] = UIColor.white
            mutableText.setAttributes(newAttrs, range: range)
        }
        
        textView.attributedText = mutableText
        textView.selectedRange = selectedRange
    }
    
    private func applyBulletList() {
        guard let textView = targetTextView else { return }
        let selectedRange = textView.selectedRange
        if selectedRange.length == 0 { return }
        
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        mutableText.enumerateAttribute(.paragraphStyle, in: selectedRange, options: []) { (value, range, _) in
            let style = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.headIndent = 15
            style.firstLineHeadIndent = 15
            style.paragraphSpacingBefore = 5
            mutableText.addAttribute(.paragraphStyle, value: style, range: range)
        }
        
        textView.attributedText = mutableText
        textView.selectedRange = selectedRange
    }
}
