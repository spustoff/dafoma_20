import Foundation
import SwiftUI

struct Book: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var author: String
    var genre: String
    var coverImageName: String?
    var synopsis: String
    var content: String
    var isCompleted: Bool
    var currentPage: Int
    var totalPages: Int
    var dateAdded: Date
    var lastReadDate: Date?
    var rating: Int? // 1-5 stars
    var tags: [String]
    var notes: [Note]
    
    // Reading preferences
    var fontSize: CGFloat
    var fontFamily: FontFamily
    var backgroundColor: BackgroundColor
    var textColor: TextColor
    
    init(title: String, author: String, genre: String, synopsis: String, content: String, totalPages: Int = 100) {
        self.title = title
        self.author = author
        self.genre = genre
        self.synopsis = synopsis
        self.content = content
        self.isCompleted = false
        self.currentPage = 0
        self.totalPages = totalPages
        self.dateAdded = Date()
        self.tags = []
        self.notes = []
        self.fontSize = 16.0
        self.fontFamily = .system
        self.backgroundColor = .dark
        self.textColor = .primary
    }
    
    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
}

enum FontFamily: String, CaseIterable, Codable {
    case system = "System"
    case serif = "Times New Roman"
    case sansSerif = "Helvetica"
    case georgia = "Georgia"
    case palatino = "Palatino"
    
    var displayName: String {
        return self.rawValue
    }
    
    var font: Font {
        switch self {
        case .system:
            return .system(.body)
        case .serif:
            return .custom("Times New Roman", size: 16)
        case .sansSerif:
            return .custom("Helvetica", size: 16)
        case .georgia:
            return .custom("Georgia", size: 16)
        case .palatino:
            return .custom("Palatino", size: 16)
        }
    }
}

enum BackgroundColor: String, CaseIterable, Codable {
    case dark = "Dark"
    case light = "Light"
    case sepia = "Sepia"
    case night = "Night"
    
    var color: Color {
        switch self {
        case .dark:
            return Color(hex: "3e4464")
        case .light:
            return .white
        case .sepia:
            return Color(hex: "f4f1e8")
        case .night:
            return .black
        }
    }
}

enum TextColor: String, CaseIterable, Codable {
    case primary = "Primary"
    case white = "White"
    case black = "Black"
    case sepia = "Sepia"
    
    var color: Color {
        switch self {
        case .primary:
            return .primary
        case .white:
            return .white
        case .black:
            return .black
        case .sepia:
            return Color(hex: "5a4d3b")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}