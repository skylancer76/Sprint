import Foundation
import UIKit

// MARK: - 1) The top-level response for "fetch all notes"
struct AllNotesResponse: Codable {
    let data: [ServerNote]
    let total: Int
}

// MARK: - 2) A single note object as returned by the server
struct ServerNote: Codable {
    let title: String
    let content: String
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let permissions: [String]
    let databaseId: String
    let collectionId: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case id = "$id"
        case createdAt = "$createdAt"
        case updatedAt = "$updatedAt"
        case permissions = "$permissions"
        case databaseId = "$databaseId"
        case collectionId = "$collectionId"
    }
    
    /// Convert this server representation to your local `Note` model.
    func toLocalNote() -> Note {
        // Convert the server's string ID to UUID. If it fails, we generate a fresh UUID.
        let uuid = UUID(uuidString: id) ?? UUID()
        
        // Here, the server's `content` is plain text (or Markdown).
        // We convert it into a simple NSAttributedString for your local model.
        let attributedBody = NSAttributedString(string: content)
        
        return Note(
            id: uuid,
            title: title,
            body: attributedBody,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - 3) Your local `Note` model
struct Note: Codable {
    var id: UUID
    var title: String
    
    // Internally, store the note body as RTF data (to preserve formatting),
    // but expose it as an NSAttributedString in the app.
    private var bodyRTFData: Data?
    
    var body: NSAttributedString {
        get {
            guard let data = bodyRTFData else {
                return NSAttributedString(string: "")
            }
            do {
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                return NSAttributedString(string: "")
            }
        }
        set {
            do {
                let rtfData = try newValue.data(
                    from: NSRange(location: 0, length: newValue.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                bodyRTFData = rtfData
            } catch {
                bodyRTFData = nil
            }
        }
    }
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializers
    
    /// A convenience initializer for creating a new note in-app.
    init(title: String, body: NSAttributedString = NSAttributedString()) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        
        do {
            let rtfData = try body.data(
                from: NSRange(location: 0, length: body.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            self.bodyRTFData = rtfData
        } catch {
            self.bodyRTFData = nil
        }
    }
    
    /// A more detailed initializer used by the `ServerNote.toLocalNote()` bridging.
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
        
        do {
            let rtfData = try body.data(
                from: NSRange(location: 0, length: body.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            self.bodyRTFData = rtfData
        } catch {
            self.bodyRTFData = nil
        }
    }
    
    // MARK: - Codable conformance
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case bodyRTFData
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.bodyRTFData = try container.decodeIfPresent(Data.self, forKey: .bodyRTFData)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(bodyRTFData, forKey: .bodyRTFData)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

fileprivate func customISO8601DateDecodingStrategy(_ decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)
    
    // Create an ISO8601DateFormatter that can handle fractional seconds + offset.
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = formatter.date(from: dateString) {
        return date
    }
    
    throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Expected date to be ISO8601 with fractional seconds, got \(dateString)"
    )
}


// MARK: - 4) Fetching all notes from the new endpoint
extension Note {
    /// Fetch all notes from the `/api/notes` endpoint (based on your sample response).
    static func fetchAllNotes(completion: @escaping (Result<[Note], Error>) -> Void) {
        guard let url = URL(string: "https://sprint-six.vercel.app/api/notes") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // 1) Check for network errors
            if let error = error {
                completion(.failure(error))
                return
            }
            // 2) Ensure we have data
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            // 3) Decode the JSON
            do {
                let decoder = JSONDecoder()
                // Your timestamps look like ISO8601 with timezone offset
                decoder.dateDecodingStrategy = .custom(customISO8601DateDecodingStrategy)

                // Decode the top-level object containing `data` and `total`
                let allNotesResponse = try decoder.decode(AllNotesResponse.self, from: data)
                
                // Convert each `ServerNote` to a local `Note`
                let localNotes = allNotesResponse.data.map { $0.toLocalNote() }
                
                // 4) Return the array of local notes
                completion(.success(localNotes))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }
}

// MARK: - 5) (Optional) NoteCollection model & its API calls
/// Only include this if you still need note collections in your app.
struct NoteCollection: Codable {
    var id: UUID
    var title: String
    var notes: [Note]
    
    init(title: String, notes: [Note] = []) {
        self.id = UUID()
        self.title = title
        self.notes = notes
    }
    
    // Add your existing fetch/create/update/delete logic if still relevant.
    // ...
}

// MARK: - 6) APIError enum
enum APIError: Error {
    case invalidURL
    case noData
}

// MARK: - 7) Image upload helper
extension Note {
    /// Uploads an image to the server as multipart/form-data.
    static func uploadImage(_ image: UIImage,
                            to urlString: String = "https://sprint-six.vercel.app/api/files",
                            completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(APIError.noData))
            return
        }
        
        // Build multipart/form-data request
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
        }
        .resume()
    }
}
