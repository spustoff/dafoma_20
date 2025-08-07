import Foundation
import SwiftUI

struct Recommendation: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var author: String
    var genre: String
    var synopsis: String
    var coverImageName: String?
    var rating: Double
    var reason: String
    var confidenceScore: Double // 0.0 to 1.0
    var basedOnBooks: [UUID] // Book IDs that influenced this recommendation
    var basedOnNotes: [UUID] // Note IDs that influenced this recommendation
    var dateGenerated: Date
    var isRead: Bool
    var isInLibrary: Bool
    var tags: [String]
    var recommendationType: RecommendationType
    
    init(title: String, author: String, genre: String, synopsis: String, reason: String, confidenceScore: Double) {
        self.title = title
        self.author = author
        self.genre = genre
        self.synopsis = synopsis
        self.reason = reason
        self.confidenceScore = confidenceScore
        self.rating = 0.0
        self.basedOnBooks = []
        self.basedOnNotes = []
        self.dateGenerated = Date()
        self.isRead = false
        self.isInLibrary = false
        self.tags = []
        self.recommendationType = .algorithm
    }
    
    var confidencePercentage: Int {
        Int(confidenceScore * 100)
    }
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var confidenceLevel: ConfidenceLevel {
        switch confidenceScore {
        case 0.8...1.0:
            return .high
        case 0.6..<0.8:
            return .medium
        case 0.0..<0.6:
            return .low
        default:
            return .low
        }
    }
}

enum RecommendationType: String, CaseIterable, Codable {
    case algorithm = "Algorithm"
    case similarGenre = "Similar Genre"
    case sameAuthor = "Same Author"
    case trending = "Trending"
    case editorial = "Editorial Pick"
    case userRated = "Highly Rated"
    
    var icon: String {
        switch self {
        case .algorithm:
            return "brain.head.profile"
        case .similarGenre:
            return "books.vertical"
        case .sameAuthor:
            return "person.circle"
        case .trending:
            return "chart.line.uptrend.xyaxis"
        case .editorial:
            return "star.circle"
        case .userRated:
            return "hand.thumbsup"
        }
    }
    
    var color: Color {
        switch self {
        case .algorithm:
            return Color(hex: "fcc418")
        case .similarGenre:
            return .blue
        case .sameAuthor:
            return .purple
        case .trending:
            return Color(hex: "3cc45b")
        case .editorial:
            return .orange
        case .userRated:
            return .pink
        }
    }
}

enum ConfidenceLevel: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high:
            return Color(hex: "3cc45b")
        case .medium:
            return Color(hex: "fcc418")
        case .low:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .high:
            return "checkmark.circle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Recommendation Algorithm Data
struct ReadingPattern {
    var favoriteGenres: [String: Double] // Genre -> Weight
    var favoriteAuthors: [String: Double] // Author -> Weight
    var averageRating: Double
    var readingFrequency: Double
    var preferredNoteCategories: [NoteCategory: Double]
    var commonTags: [String: Double]
    
    init() {
        self.favoriteGenres = [:]
        self.favoriteAuthors = [:]
        self.averageRating = 0.0
        self.readingFrequency = 0.0
        self.preferredNoteCategories = [:]
        self.commonTags = [:]
    }
}

struct RecommendationEngine {
    static func generateRecommendations(basedOn books: [Book], notes: [Note]) -> [Recommendation] {
        let pattern = analyzeReadingPattern(books: books, notes: notes)
        return generateSmartRecommendations(pattern: pattern)
    }
    
    private static func analyzeReadingPattern(books: [Book], notes: [Note]) -> ReadingPattern {
        var pattern = ReadingPattern()
        
        // Analyze genre preferences
        for book in books {
            let weight = book.rating.map { Double($0) / 5.0 } ?? 0.5
            pattern.favoriteGenres[book.genre, default: 0.0] += weight
        }
        
        // Analyze author preferences
        for book in books {
            let weight = book.rating.map { Double($0) / 5.0 } ?? 0.5
            pattern.favoriteAuthors[book.author, default: 0.0] += weight
        }
        
        // Calculate average rating
        let ratedBooks = books.compactMap { $0.rating }
        pattern.averageRating = ratedBooks.isEmpty ? 0.0 : Double(ratedBooks.reduce(0, +)) / Double(ratedBooks.count)
        
        // Analyze note categories
        for note in notes {
            pattern.preferredNoteCategories[note.category, default: 0.0] += 1.0
        }
        
        return pattern
    }
    
    private static func generateSmartRecommendations(pattern: ReadingPattern) -> [Recommendation] {
        // This would normally connect to a real recommendation service
        // For now, we'll generate some sample recommendations based on common genres
        
        let sampleRecommendations = [
            Recommendation(
                title: "The Midnight Library",
                author: "Matt Haig",
                genre: "Literary Fiction",
                synopsis: "A magical library between life and death where infinite possibilities exist.",
                reason: "Based on your interest in philosophical themes and character development",
                confidenceScore: 0.85
            ),
            Recommendation(
                title: "Project Hail Mary",
                author: "Andy Weir",
                genre: "Science Fiction",
                synopsis: "A lone astronaut must save humanity in this thrilling space adventure.",
                reason: "Recommended due to your appreciation for problem-solving narratives",
                confidenceScore: 0.78
            ),
            Recommendation(
                title: "The Seven Husbands of Evelyn Hugo",
                author: "Taylor Jenkins Reid",
                genre: "Historical Fiction",
                synopsis: "A reclusive Hollywood icon reveals her scandalous life story.",
                reason: "Matches your preference for character-driven stories with emotional depth",
                confidenceScore: 0.92
            ),
            Recommendation(
                title: "Atomic Habits",
                author: "James Clear",
                genre: "Self-Help",
                synopsis: "Transform your life through the power of small, consistent changes.",
                reason: "Based on your note-taking patterns suggesting interest in personal development",
                confidenceScore: 0.73
            )
        ]
        
        return sampleRecommendations.map { recommendation in
            var rec = recommendation
            rec.recommendationType = determineRecommendationType(recommendation: rec, pattern: pattern)
            return rec
        }
    }
    
    private static func determineRecommendationType(recommendation: Recommendation, pattern: ReadingPattern) -> RecommendationType {
        if pattern.favoriteGenres[recommendation.genre] ?? 0 > 0.7 {
            return .similarGenre
        } else if pattern.favoriteAuthors[recommendation.author] ?? 0 > 0.8 {
            return .sameAuthor
        } else if recommendation.confidenceScore > 0.8 {
            return .algorithm
        } else {
            return .trending
        }
    }
}