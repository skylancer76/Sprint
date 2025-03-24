//
//  Data Model .swift
//  Sprint
//
//  Created by admin19 on 25/03/25.
//

import Foundation

struct NoteCollection {
    var id: UUID
    var title: String
    var notes: [Note]
    
    init(title: String, notes: [Note] = []) {
        self.id = UUID()
        self.title = title
        self.notes = notes
    }
}

struct Note {
    var id: UUID
    var title: String
    // We'll store the note content as an attributed string to preserve formatting
    var body: NSAttributedString
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, body: NSAttributedString = NSAttributedString()) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
