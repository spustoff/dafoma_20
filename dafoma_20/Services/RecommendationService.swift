import Foundation
import SwiftUI

class RecommendationService: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isGeneratingRecommendations = false
    
    private let userDefaults = UserDefaults.standard
    private let recommendationsKey = "SavedRecommendations"
    private let bookService: BookService
    private let noteService: NoteService
    
    init(bookService: BookService, noteService: NoteService) {
        self.bookService = bookService
        self.noteService = noteService
        loadRecommendations()
        
        // Generate initial recommendations if none exist
        if recommendations.isEmpty {
            generateRecommendations()
        }
    }
    
    // MARK: - Recommendation Generation
    
    func generateRecommendations() {
        isGeneratingRecommendations = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let newRecommendations = RecommendationEngine.generateRecommendations(
                basedOn: self.bookService.books,
                notes: self.noteService.notes
            )
            
            DispatchQueue.main.async {
                self.recommendations = newRecommendations
                self.saveRecommendations()
                self.isGeneratingRecommendations = false
            }
        }
    }
    
    func refreshRecommendations() {
        recommendations.removeAll()
        generateRecommendations()
    }
    
    // MARK: - Recommendation Management
    
    func addRecommendation(_ recommendation: Recommendation) {
        recommendations.append(recommendation)
        saveRecommendations()
    }
    
    func updateRecommendation(_ recommendation: Recommendation) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            recommendations[index] = recommendation
            saveRecommendations()
        }
    }
    
    func deleteRecommendation(_ recommendation: Recommendation) {
        recommendations.removeAll { $0.id == recommendation.id }
        saveRecommendations()
    }
    
    func deleteRecommendation(at indexSet: IndexSet) {
        recommendations.remove(atOffsets: indexSet)
        saveRecommendations()
    }
    
    func getRecommendation(by id: UUID) -> Recommendation? {
        return recommendations.first { $0.id == id }
    }
    
    // MARK: - Recommendation Actions
    
    func markAsRead(recommendationId: UUID) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
            recommendations[index].isRead = true
            saveRecommendations()
        }
    }
    
    func addToLibrary(recommendationId: UUID) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
            let recommendation = recommendations[index]
            
            // Create a new book from the recommendation
            let newBook = Book(
                title: recommendation.title,
                author: recommendation.author,
                genre: recommendation.genre,
                synopsis: recommendation.synopsis,
                content: generateSampleContent(for: recommendation),
                totalPages: Int.random(in: 150...500)
            )
            
            // Add to book service
            bookService.addBook(newBook)
            
            // Mark recommendation as in library
            recommendations[index].isInLibrary = true
            saveRecommendations()
        }
    }
    
    func rateRecommendation(recommendationId: UUID, rating: Double) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
            recommendations[index].rating = max(0.0, min(5.0, rating))
            saveRecommendations()
        }
    }
    
    // MARK: - Filtering and Searching
    
    func getRecommendations(by type: RecommendationType) -> [Recommendation] {
        return recommendations.filter { $0.recommendationType == type }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func getRecommendations(by confidenceLevel: ConfidenceLevel) -> [Recommendation] {
        return recommendations.filter { $0.confidenceLevel == confidenceLevel }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func getUnreadRecommendations() -> [Recommendation] {
        return recommendations.filter { !$0.isRead }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func getRecommendationsNotInLibrary() -> [Recommendation] {
        return recommendations.filter { !$0.isInLibrary }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func searchRecommendations(_ query: String) -> [Recommendation] {
        guard !query.isEmpty else { return getSortedRecommendations() }
        
        return recommendations.filter { recommendation in
            recommendation.title.lowercased().contains(query.lowercased()) ||
            recommendation.author.lowercased().contains(query.lowercased()) ||
            recommendation.genre.lowercased().contains(query.lowercased()) ||
            recommendation.reason.lowercased().contains(query.lowercased()) ||
            recommendation.tags.contains { $0.lowercased().contains(query.lowercased()) }
        }.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func getSortedRecommendations() -> [Recommendation] {
        return recommendations.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    func getTopRecommendations(limit: Int = 5) -> [Recommendation] {
        return getSortedRecommendations().prefix(limit).map { $0 }
    }
    
    // MARK: - Analytics
    
    var totalRecommendationsCount: Int {
        recommendations.count
    }
    
    var readRecommendationsCount: Int {
        recommendations.filter { $0.isRead }.count
    }
    
    var inLibraryCount: Int {
        recommendations.filter { $0.isInLibrary }.count
    }
    
    func getTypeDistribution() -> [RecommendationType: Int] {
        return Dictionary(grouping: recommendations, by: { $0.recommendationType })
            .mapValues { $0.count }
    }
    
    func getConfidenceLevelDistribution() -> [ConfidenceLevel: Int] {
        return Dictionary(grouping: recommendations, by: { $0.confidenceLevel })
            .mapValues { $0.count }
    }
    
    func getAverageConfidenceScore() -> Double {
        guard !recommendations.isEmpty else { return 0.0 }
        let totalScore = recommendations.reduce(0.0) { $0 + $1.confidenceScore }
        return totalScore / Double(recommendations.count)
    }
    
    func getAverageRating() -> Double {
        let ratedRecommendations = recommendations.filter { $0.rating > 0 }
        guard !ratedRecommendations.isEmpty else { return 0.0 }
        
        let totalRating = ratedRecommendations.reduce(0.0) { $0 + $1.rating }
        return totalRating / Double(ratedRecommendations.count)
    }
    
    // MARK: - Smart Recommendations
    
    func getPersonalizedRecommendations(limit: Int = 10) -> [Recommendation] {
        // Get user's reading patterns
        let favoriteGenres = bookService.favoriteGenres
        let completedBooks = bookService.getCompletedBooks()
        let averageRating = bookService.averageRating
        
        var scoredRecommendations = recommendations.map { recommendation -> (Recommendation, Double) in
            var score = recommendation.confidenceScore
            
            // Boost score for favorite genres
            if favoriteGenres.prefix(3).contains(recommendation.genre) {
                score += 0.2
            }
            
            // Boost score for similar authors
            let hasReadSameAuthor = completedBooks.contains { $0.author == recommendation.author }
            if hasReadSameAuthor {
                score += 0.15
            }
            
            // Consider user's rating standards
            if averageRating > 4.0 && recommendation.confidenceScore < 0.7 {
                score -= 0.1 // User has high standards
            }
            
            // Prefer unread recommendations
            if !recommendation.isRead {
                score += 0.1
            }
            
            // Prefer recommendations not already in library
            if !recommendation.isInLibrary {
                score += 0.05
            }
            
            return (recommendation, min(1.0, max(0.0, score)))
        }
        
        return scoredRecommendations
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    func getSimilarRecommendations(to book: Book, limit: Int = 5) -> [Recommendation] {
        return recommendations.filter { recommendation in
            recommendation.genre == book.genre ||
            recommendation.author == book.author ||
            !Set(recommendation.tags).isDisjoint(with: Set(book.tags))
        }
        .sorted { $0.confidenceScore > $1.confidenceScore }
        .prefix(limit)
        .map { $0 }
    }
    
    // MARK: - Persistence
    
    private func saveRecommendations() {
        do {
            let data = try JSONEncoder().encode(recommendations)
            userDefaults.set(data, forKey: recommendationsKey)
        } catch {
            print("Failed to save recommendations: \(error)")
        }
    }
    
    private func loadRecommendations() {
        guard let data = userDefaults.data(forKey: recommendationsKey) else { return }
        
        do {
            recommendations = try JSONDecoder().decode([Recommendation].self, from: data)
        } catch {
            print("Failed to load recommendations: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateSampleContent(for recommendation: Recommendation) -> String {
        return """
        # \(recommendation.title)
        
        ## Synopsis
        \(recommendation.synopsis)
        
        ## Chapter 1: The Beginning
        
        Every great story begins with a single word, a single thought, a single moment of inspiration. In "\(recommendation.title)", \(recommendation.author) crafts a narrative that captivates from the very first page.
        
        The story unfolds in the \(recommendation.genre.lowercased()) tradition, bringing together elements that have made this recommendation particularly suited to your reading preferences. Based on your previous reading history and the patterns in your notes, this book promises to deliver the kind of experience you've come to appreciate.
        
        ## Chapter 2: Development
        
        As the narrative progresses, the themes that drew our recommendation algorithm to suggest this book become more apparent. The author's style resonates with the literary preferences you've demonstrated through your reading choices and note-taking patterns.
        
        \(recommendation.reason)
        
        ## Chapter 3: The Journey Continues
        
        This is where the story truly comes alive, where the characters begin their transformation, and where the themes that made this book a perfect match for your reading profile start to weave together into something extraordinary.
        
        The narrative continues to unfold, promising the kind of literary experience that your reading history suggests you'll find both engaging and meaningful...
        
        [This is a preview of the full book content. The complete text would continue with the full story...]
        """
    }
}