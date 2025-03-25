import Foundation
import UIKit

struct Note: Codable {
    var id: UUID
    var title: String
    
    /// The raw HTML content from the server. We'll parse it into an NSAttributedString.
    var content: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Property: body
    /// A computed property that interprets `content` (HTML) as an NSAttributedString,
    /// and converts back to HTML when set.
    var body: NSAttributedString {
        get {
            // If there's no HTML content, return a default string.
            guard let htmlString = content, !htmlString.isEmpty else {
                return NSAttributedString(string: "KYYYAAAA", attributes: [.foregroundColor: UIColor.white])
            }
            
            do {
                let data = Data(htmlString.utf8)
                // Parse the HTML into an attributed string.
                let attrString = try NSMutableAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
                // Force the text color to white.
                let fullRange = NSRange(location: 0, length: attrString.length)
                attrString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
                return attrString
            } catch {
                print("Error parsing HTML: \(error)")
                // Fallback if parsing fails.
                return NSAttributedString(string: "KYYYAAAA", attributes: [.foregroundColor: UIColor.white])
            }
        }
        set {
            // Convert the NSAttributedString back to HTML for storage in `content`.
            let range = NSRange(location: 0, length: newValue.length)
            let options: [NSAttributedString.DocumentAttributeKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            do {
                let htmlData = try newValue.data(from: range, documentAttributes: options)
                content = String(data: htmlData, encoding: .utf8) ?? ""
                // Debug print (optional):
                // print("Converted NSAttributedString back to HTML: \(content ?? "")")
            } catch {
                print("Error converting NSAttributedString to HTML: \(error)")
                content = "KYYYAAAA"
            }
        }
    }
    
    // MARK: - Initializers
    
    /// For creating a new note locally.
    init(title: String, body: NSAttributedString = NSAttributedString()) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Convert the NSAttributedString to HTML for `content`.
        let range = NSRange(location: 0, length: body.length)
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        do {
            let htmlData = try body.data(from: range, documentAttributes: options)
            self.content = String(data: htmlData, encoding: .utf8) ?? ""
        } catch {
            self.content = "KYYYAAAA"
        }
    }
    
    /// A more detailed initializer for editing an existing note.
    init(id: UUID,
         title: String,
         body: NSAttributedString,
         createdAt: Date,
         updatedAt: Date)
    {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Convert the NSAttributedString to HTML for `content`.
        let range = NSRange(location: 0, length: body.length)
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        do {
            let htmlData = try body.data(from: range, documentAttributes: options)
            self.content = String(data: htmlData, encoding: .utf8) ?? ""
        } catch {
            self.content = "KYYYAAAA"
        }
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt
        case updatedAt
    }
    
    // MARK: - Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    // MARK: - Encoding
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Image Upload
    static func uploadImage(_ image: UIImage,
                            to urlString: String = "https://sprint-six.vercel.app/api/files",
                            completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(APIError.noData))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(APIError.noData))
                return
            }
            let responseString = String(data: data, encoding: .utf8) ?? ""
            completion(.success(responseString))
        }.resume()
    }
    
    // MARK: - Fetch All Notes
    static func fetchAllNotes(completion: @escaping (Result<[Note], Error>) -> Void) {
        guard let url = URL(string: "https://sprint-six.vercel.app/api/notes") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let apiResponse = try decoder.decode(APIResponse<[Note]>.self, from: data)
                completion(.success(apiResponse.data))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - API Response & Error
struct APIResponse<T: Codable>: Codable {
    let data: T
}

enum APIError: Error {
    case invalidURL
    case noData
}
