import Foundation
import SwiftUI

struct Note: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var content: String
    var bookId: UUID
    var pageReference: Int?
    var tags: [String]
    var dateCreated: Date
    var dateModified: Date
    var isBookmarked: Bool
    var category: NoteCategory
    var color: NoteColor
    
    init(title: String, content: String, bookId: UUID, pageReference: Int? = nil) {
        self.title = title
        self.content = content
        self.bookId = bookId
        self.pageReference = pageReference
        self.tags = []
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isBookmarked = false
        self.category = .general
        self.color = .yellow
    }
    
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.dateModified = Date()
    }
    
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            dateModified = Date()
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        dateModified = Date()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }
    
    var previewText: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }
}

enum NoteCategory: String, CaseIterable, Codable {
    case general = "General"
    case quote = "Quote"
    case idea = "Idea"
    case question = "Question"
    case analysis = "Analysis"
    case review = "Review"
    case summary = "Summary"
    
    var icon: String {
        switch self {
        case .general:
            return "note.text"
        case .quote:
            return "quote.bubble"
        case .idea:
            return "lightbulb"
        case .question:
            return "questionmark.circle"
        case .analysis:
            return "magnifyingglass"
        case .review:
            return "star"
        case .summary:
            return "list.bullet"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return .blue
        case .quote:
            return .purple
        case .idea:
            return Color(hex: "fcc418")
        case .question:
            return .orange
        case .analysis:
            return .indigo
        case .review:
            return Color(hex: "3cc45b")
        case .summary:
            return .cyan
        }
    }
}

enum NoteColor: String, CaseIterable, Codable {
    case yellow = "Yellow"
    case blue = "Blue"
    case green = "Green"
    case pink = "Pink"
    case purple = "Purple"
    case orange = "Orange"
    case red = "Red"
    case gray = "Gray"
    
    var color: Color {
        switch self {
        case .yellow:
            return Color(hex: "fcc418")
        case .blue:
            return .blue
        case .green:
            return Color(hex: "3cc45b")
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .orange:
            return .orange
        case .red:
            return .red
        case .gray:
            return .gray
        }
    }
    
    var backgroundColor: Color {
        color.opacity(0.2)
    }
}