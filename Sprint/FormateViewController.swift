//
//  FormateViewController.swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import UIKit

class FormatViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var styleSegmentedControl: UISegmentedControl!  // Title, Heading, Subheading, Body
    @IBOutlet weak var boldButton: UIButton!
    @IBOutlet weak var italicButton: UIButton!
    @IBOutlet weak var underlineButton: UIButton!
    @IBOutlet weak var strikethroughButton: UIButton!
    @IBOutlet weak var bulletButton: UIButton!
    
    // This is how we'll apply formatting to the text in Note_Screen.
    weak var targetTextView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func styleSegmentChanged(_ sender: UISegmentedControl) {
        // 0 = Title, 1 = Heading, 2 = Subheading, 3 = Body
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
    
    // MARK: - Formatting Methods
    
    // Example enum for text styles
    enum TextStyle {
        case title, heading, subheading, body
    }
    
    // Apply a font style (Title, Heading, Subheading, Body) to the selected range
    private func applyTextStyle(_ style: TextStyle) {
        guard let textView = targetTextView else { return }
        let selectedRange = textView.selectedRange
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        // Pick a font
        let font: UIFont
        switch style {
        case .title:
            font = UIFont.boldSystemFont(ofSize: 24)
        case .heading:
            font = UIFont.boldSystemFont(ofSize: 20)
        case .subheading:
            font = UIFont.systemFont(ofSize: 18)
        case .body:
            font = UIFont.systemFont(ofSize: 16)
        }
        
        mutableText.addAttribute(.font, value: font, range: selectedRange)
        // For good measure, ensure foreground color is still white
        mutableText.addAttribute(.foregroundColor, value: UIColor.white, range: selectedRange)
        
        textView.attributedText = mutableText
        // Keep the cursor selection
        textView.selectedRange = selectedRange
    }
    
    // For toggling Bold, Italic, Underline, Strikethrough
    enum ToggleAttribute {
        case bold, italic, underline, strikethrough
    }
    
    private func applyToggleAttribute(_ attribute: ToggleAttribute) {
        guard let textView = targetTextView else { return }
        let selectedRange = textView.selectedRange
        if selectedRange.length == 0 { return }  // No text selected
        
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        // Inspect the current attributes in the selected range
        mutableText.enumerateAttributes(in: selectedRange, options: []) { attrs, range, _ in
            var newAttrs = attrs
            
            switch attribute {
            case .bold:
                // Toggle bold by changing the font descriptor
                if let currentFont = attrs[.font] as? UIFont {
                    let descriptor = currentFont.fontDescriptor
                    if descriptor.symbolicTraits.contains(.traitBold) {
                        // If already bold, remove bold
                        if let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitBold)) {
                            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                            newAttrs[.font] = newFont
                        }
                    } else {
                        // If not bold, add bold
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
                // Toggle .underlineStyle
                if let underlineStyle = attrs[.underlineStyle] as? Int, underlineStyle != 0 {
                    newAttrs[.underlineStyle] = 0
                } else {
                    newAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
            case .strikethrough:
                // Toggle .strikethroughStyle
                if let strikeStyle = attrs[.strikethroughStyle] as? Int, strikeStyle != 0 {
                    newAttrs[.strikethroughStyle] = 0
                } else {
                    newAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
            }
            
            // Always ensure color remains white
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
        
        // We'll add a bullet to the start of each paragraph in the selection
        // by applying a paragraph style
        mutableText.enumerateAttribute(.paragraphStyle, in: selectedRange, options: []) { (value, range, _) in
            let style = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            
            // Indent and add bullet
            // Using a basic approach with .headIndent and .firstLineHeadIndent
            style.headIndent = 15
            style.firstLineHeadIndent = 15
            style.paragraphSpacingBefore = 5
            
            // For a real bullet, we can use list style in iOS 16, or prepend "• ":
            // But here we do a simple approach with .paragraphSpacing or .headIndent
            // Alternatively, you can manually insert "• " at the start of the range.
            
            mutableText.addAttribute(.paragraphStyle, value: style, range: range)
        }
        
        // Optionally prepend "• " to each line in the selection
        // This is a simple approach:
        let textRange = mutableText.mutableString.range(of: mutableText.string)
        let lines = mutableText.string.components(separatedBy: .newlines)
        // For each line in selection, you could insert a bullet.
        // This can get more complex. A simpler approach is the paragraph style list attribute in iOS 16+.
        
        textView.attributedText = mutableText
        textView.selectedRange = selectedRange
    }
}
