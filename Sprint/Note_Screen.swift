//
//  Note_Screen.swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import UIKit
import Speech
import AVFoundation

class Note_Screen: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet var noteAccessoryToolBar: UIToolbar!
    
    // MARK: - Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    
    // Store the final recognized transcript to avoid clearing it.
    private var finalTranscript: String = ""
    
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
        
        // Configure text view appearance.
        bodyTextView.backgroundColor = .clear
        bodyTextView.textColor = .white
        bodyTextView.typingAttributes = [
            NSAttributedString.Key.font: bodyTextView.font ?? UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        // Set dynamic date in the navigation title.
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let dateString = formatter.string(from: Date())
        self.navigationItem.title = dateString
        
        // Set delegates.
        titleTextField.delegate = self
        bodyTextView.delegate = self
        
        // Request Speech Recognition Authorization.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not available/authorized")
            @unknown default:
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Attach the accessory toolbar to the text view.
        bodyTextView.inputAccessoryView = noteAccessoryToolBar
    }
    
    // MARK: - IBActions
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        // Implement save functionality here.
    }
    
    @IBAction func didTapAaButton(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let formatVC = storyboard.instantiateViewController(withIdentifier: "FormatViewController") as? FormatViewController {
            
            formatVC.targetTextView = bodyTextView
            if let sheet = formatVC.sheetPresentationController {
                sheet.detents = [.medium()]
            }
            
            present(formatVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapImageButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func didTapVoiceButton(_ sender: Any) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
        isRecording.toggle()
    }
    
    @IBAction func didTapAIButton(_ sender: Any) {
        // Implement AI feature functionality here.
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        // Process the image to have fixed dimensions and rounded corners.
        let targetSize = CGSize(width: 360, height: 170)
        guard let processedImage = resizeAndRoundImage(image, targetSize: targetSize, cornerRadius: 12) else { return }
        
        // Create an NSTextAttachment with the processed image.
        let attachment = NSTextAttachment()
        attachment.image = processedImage
        attachment.bounds = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        // Insert the attachment into the text view at the current cursor location.
        let attrStringWithImage = NSAttributedString(attachment: attachment)
        let mutableAttrText = NSMutableAttributedString(attributedString: bodyTextView.attributedText)
        let selectedRange = bodyTextView.selectedRange
        mutableAttrText.insert(attrStringWithImage, at: selectedRange.location)
        
        // Ensure that the entire attributed text has white text color.
        let entireRange = NSRange(location: 0, length: mutableAttrText.length)
        mutableAttrText.addAttribute(.foregroundColor, value: UIColor.white, range: entireRange)
        
        bodyTextView.attributedText = mutableAttrText
        
        // Move the cursor after the inserted image.
        bodyTextView.selectedRange = NSRange(location: selectedRange.location + 1, length: 0)
        
        // Reapply typing attributes so new text remains white.
        bodyTextView.typingAttributes = [
            NSAttributedString.Key.font: bodyTextView.font ?? UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
    }
    
    // Helper function: Resize and round the image.
    func resizeAndRoundImage(_ image: UIImage, targetSize: CGSize, cornerRadius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let roundedImage = renderer.image { context in
            let rect = CGRect(origin: .zero, size: targetSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            image.draw(in: rect)
        }
        return roundedImage
    }
    
    // MARK: - Speech Recognition Functions
    
    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let newTranscript = result.bestTranscription.formattedString
                // Only update if new transcript is not empty.
                if !newTranscript.isEmpty {
                    self.finalTranscript = newTranscript
                }
                DispatchQueue.main.async {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .foregroundColor: UIColor.white,
                        .font: self.bodyTextView.font ?? UIFont.systemFont(ofSize: 16)
                    ]
                    self.bodyTextView.attributedText = NSAttributedString(string: self.finalTranscript, attributes: attributes)
                    self.bodyTextView.typingAttributes = attributes
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error)")
        }
        
        print("Recording started...")
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        print("Recording stopped.")
    }
}

