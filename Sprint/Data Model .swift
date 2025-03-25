import Foundation
import UIKit

struct Note: Codable {
    var id: UUID
    var title: String
    
  
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.bodyRTFData = try container.decodeIfPresent(Data.self, forKey: .bodyRTFData)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }


    
    private var bodyRTFData: Data?
    
    var body: NSAttributedString {
        get {
            guard let data = bodyRTFData else { return NSAttributedString(string: "") }
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
    
    init(title: String, body: NSAttributedString = NSAttributedString()) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Convert attributed string to RTF
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
    
    // Add coding keys, custom decode/encode if needed...
    
    // Example image upload function:
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
    
    // Example fetchAllNotes:
    static func fetchAllNotes(completion: @escaping (Result<[Note], Error>) -> Void) {
        guard let url = URL(string: "https://sprint-six.vercel.app/api/notes") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                // Suppose the server returns { "data": [Note], "total": ... }
                // Adjust if your structure is different.
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

// Helper for standard API response shape.
struct APIResponse<T: Codable>: Codable {
    let data: T
}

// Basic error enum
enum APIError: Error {
    case invalidURL
    case noData
}
