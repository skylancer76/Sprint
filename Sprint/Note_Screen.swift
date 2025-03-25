//
//  Note_Screen.swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import UIKit
import Speech
import AVFoundation

class Note_Screen: UIViewController,
                   UITextFieldDelegate,
                   UITextViewDelegate,
                   UIImagePickerControllerDelegate,
                   UINavigationControllerDelegate
{
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
            .font: bodyTextView.font ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white
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
    
    /// The Save button: uploads images, then calls your backend to save the note.
    @IBAction func saveButtonTapped(_ sender: Any) {
        let newNote = Note(title: titleTextField.text ?? "",
                           body: bodyTextView.attributedText)
        
        uploadImagesAndSave(note: newNote)
    }
    
    /// Upload images in the note's attributed text, replace them with placeholders,
    /// then call an API to create/update the note on the server.
    private func uploadImagesAndSave(note: Note) {
        let mutableAttrString = NSMutableAttributedString(attributedString: note.body)
        let fullRange = NSRange(location: 0, length: mutableAttrString.length)
        
        // Find all image attachments
        var attachments: [(range: NSRange, attachment: NSTextAttachment)] = []
        mutableAttrString.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, _ in
            if let attachment = value as? NSTextAttachment {
                attachments.append((range, attachment))
            }
        }
        
        // If there are no attachments, just save directly
        guard !attachments.isEmpty else {
            saveNoteToServer(note: note)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        for (range, attachment) in attachments {
            if let image = attachment.image {
                dispatchGroup.enter()
                // Upload image
                Note.uploadImage(image) { result in
                    defer { dispatchGroup.leave() }
                    switch result {
                    case .success(let urlString):
                        // Replace the attachment with a placeholder or URL reference
                        let placeholder = NSAttributedString(
                            string: "[Image: \(urlString)]",
                            attributes: [.foregroundColor: UIColor.white]
                        )
                        mutableAttrString.replaceCharacters(in: range, with: placeholder)
                    case .failure(let error):
                        print("Image upload failed: \(error)")
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let finalNote = Note(
                id: note.id,
                title: note.title,
                body: mutableAttrString,
                createdAt: note.createdAt,
                updatedAt: Date()
            )
            self.saveNoteToServer(note: finalNote)
        }
    }
    
    /// Saves the note by calling your API endpoint (PUT /api/notes/:id or POST /api/notes).
    private func saveNoteToServer(note: Note) {
        guard let url = URL(string: "https://sprint-six.vercel.app/api/notes/\(note.id)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"  // or "POST" if creating a new note
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(note)
        } catch {
            print("Encoding error: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }
            guard let data = data, !data.isEmpty else {
                print("No data received.")
                return
            }
            print("Successfully saved note to server.")
        }
        .resume()
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
    
    /// AI button: show a spinner, call /generate, parse HTML -> NSAttributedString, present AI screen.
    @IBAction func didTapAIButton(_ sender: Any) {
        let spinner = UIActivityIndicatorView(style: .large)
           spinner.center = view.center
           spinner.startAnimating()
           view.addSubview(spinner)
           
           generateAIText(for: bodyTextView.attributedText.string) { [weak self] result in
               DispatchQueue.main.async {
                   spinner.removeFromSuperview()
                   guard let self = self else { return }
                   
                   switch result {
                   case .success(let generatedAttrString):
                       // Present the AI screen using the generated attributed string.
                       let aiVC = AIViewController()
                       aiVC.aiInitialAttributedText = generatedAttrString
                       aiVC.onReplace = { newAttributedText in
                           // Replace the note body with the AI-generated text.
                           // Ensure white text is enforced.
                           let mutable = NSMutableAttributedString(attributedString: newAttributedText)
                           let range = NSRange(location: 0, length: mutable.length)
                           mutable.addAttribute(.foregroundColor, value: UIColor.white, range: range)
                           self.bodyTextView.attributedText = mutable
                       }
                       
                       let nav = UINavigationController(rootViewController: aiVC)
                       nav.modalPresentationStyle = .pageSheet
                       self.present(nav, animated: true)
                       
                   case .failure(let error):
                       print("Failed to generate AI text:", error)
                   }
               }
           }
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
            .font: bodyTextView.font ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
    }
    
    /// Helper function: Resize and round the image.
    func resizeAndRoundImage(_ image: UIImage, targetSize: CGSize, cornerRadius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let roundedImage = renderer.image { _ in
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
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
    
    // MARK: - The generateAIText function (HTML to NSAttributedString)
    /// This version sends "content" and "prompt" to /api/generate,
    /// and expects an HTML string in "generatedText".
    /// We convert the HTML to an NSAttributedString and return that.
    
 
    func generateAIText(for noteText: String,
                        completion: @escaping (Result<NSAttributedString, Error>) -> Void) {
        guard let url = URL(string: "https://sprint-six.vercel.app/api/generate") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // Send the note text as the prompt (adjust the payload keys if needed)
        let payload: [String: Any] = [
            "content": noteText,
            "prompt": "Rephrase and write a comprehensive document that I can present in the meeting. PS: preserve the images"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(APIError.noData))
                return
            }
            
            // Convert the HTML response directly to an NSAttributedString
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            do {
                let attrStr = try NSMutableAttributedString(data: data,
                                                              options: options,
                                                              documentAttributes: nil)
                // Force the entire string to use white text
                let fullRange = NSRange(location: 0, length: attrStr.length)
                attrStr.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
                
                completion(.success(attrStr))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

   
}
