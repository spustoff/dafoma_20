import Foundation
import SwiftUI
import Combine

class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var currentRecommendation: Recommendation?
    @Published var searchText = ""
    @Published var selectedType: RecommendationType?
    @Published var selectedConfidenceLevel: ConfidenceLevel?
    @Published var showReadOnly = false
    @Published var showUnreadOnly = false
    @Published var showInLibraryOnly = false
    @Published var sortOption: RecommendationSortOption = .confidence
    @Published var isGenerating = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let recommendationService: RecommendationService
    private var cancellables = Set<AnyCancellable>()
    
    init(recommendationService: RecommendationService) {
        self.recommendationService = recommendationService
        setupBindings()
        loadRecommendations()
    }
    
    private func setupBindings() {
        recommendationService.$recommendations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recommendations in
                self?.recommendations = recommendations
            }
            .store(in: &cancellables)
        
        recommendationService.$isGeneratingRecommendations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGenerating in
                self?.isGenerating = isGenerating
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadRecommendations() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
        }
    }
    
    func refreshRecommendations() {
        recommendationService.refreshRecommendations()
    }
    
    func generateNewRecommendations() {
        recommendationService.generateRecommendations()
    }
    
    // MARK: - Recommendation Management
    
    func selectRecommendation(_ recommendation: Recommendation) {
        currentRecommendation = recommendation
    }
    
    func markAsRead(_ recommendation: Recommendation) {
        recommendationService.markAsRead(recommendationId: recommendation.id)
        
        if currentRecommendation?.id == recommendation.id {
            currentRecommendation?.isRead = true
        }
    }
    
    func addToLibrary(_ recommendation: Recommendation) {
        recommendationService.addToLibrary(recommendationId: recommendation.id)
        
        if currentRecommendation?.id == recommendation.id {
            currentRecommendation?.isInLibrary = true
        }
    }
    
    func rateRecommendation(_ recommendation: Recommendation, rating: Double) {
        recommendationService.rateRecommendation(recommendationId: recommendation.id, rating: rating)
        
        if currentRecommendation?.id == recommendation.id {
            currentRecommendation?.rating = rating
        }
    }
    
    func deleteRecommendation(_ recommendation: Recommendation) {
        recommendationService.deleteRecommendation(recommendation)
        
        if currentRecommendation?.id == recommendation.id {
            currentRecommendation = nil
        }
    }
    
    // MARK: - Filtering and Searching
    
    var filteredRecommendations: [Recommendation] {
        var result = recommendations
        
        // Apply text search
        if !searchText.isEmpty {
            result = recommendationService.searchRecommendations(searchText)
        }
        
        // Apply type filter
        if let type = selectedType {
            result = result.filter { $0.recommendationType == type }
        }
        
        // Apply confidence level filter
        if let confidenceLevel = selectedConfidenceLevel {
            result = result.filter { $0.confidenceLevel == confidenceLevel }
        }
        
        // Apply read status filters
        if showReadOnly {
            result = result.filter { $0.isRead }
        } else if showUnreadOnly {
            result = result.filter { !$0.isRead }
        }
        
        // Apply library status filter
        if showInLibraryOnly {
            result = result.filter { $0.isInLibrary }
        }
        
        // Apply sorting
        return sortRecommendations(result)
    }
    
    private func sortRecommendations(_ recommendations: [Recommendation]) -> [Recommendation] {
        switch sortOption {
        case .confidence:
            return recommendations.sorted { $0.confidenceScore > $1.confidenceScore }
        case .title:
            return recommendations.sorted { $0.title < $1.title }
        case .author:
            return recommendations.sorted { $0.author < $1.author }
        case .genre:
            return recommendations.sorted { $0.genre < $1.genre }
        case .rating:
            return recommendations.sorted { $0.rating > $1.rating }
        case .dateGenerated:
            return recommendations.sorted { $0.dateGenerated > $1.dateGenerated }
        case .type:
            return recommendations.sorted { $0.recommendationType.rawValue < $1.recommendationType.rawValue }
        }
    }
    
    func getRecommendations(by type: RecommendationType) -> [Recommendation] {
        return recommendationService.getRecommendations(by: type)
    }
    
    func getRecommendations(by confidenceLevel: ConfidenceLevel) -> [Recommendation] {
        return recommendationService.getRecommendations(by: confidenceLevel)
    }
    
    func getUnreadRecommendations() -> [Recommendation] {
        return recommendationService.getUnreadRecommendations()
    }
    
    func getRecommendationsNotInLibrary() -> [Recommendation] {
        return recommendationService.getRecommendationsNotInLibrary()
    }
    
    func getTopRecommendations(limit: Int = 5) -> [Recommendation] {
        return recommendationService.getTopRecommendations(limit: limit)
    }
    
    func getPersonalizedRecommendations(limit: Int = 10) -> [Recommendation] {
        return recommendationService.getPersonalizedRecommendations(limit: limit)
    }
    
    // MARK: - Statistics
    
    var totalRecommendationsCount: Int {
        recommendationService.totalRecommendationsCount
    }
    
    var readRecommendationsCount: Int {
        recommendationService.readRecommendationsCount
    }
    
    var inLibraryCount: Int {
        recommendationService.inLibraryCount
    }
    
    var typeDistribution: [RecommendationType: Int] {
        recommendationService.getTypeDistribution()
    }
    
    var confidenceLevelDistribution: [ConfidenceLevel: Int] {
        recommendationService.getConfidenceLevelDistribution()
    }
    
    var averageConfidenceScore: Double {
        recommendationService.getAverageConfidenceScore()
    }
    
    var averageRating: Double {
        recommendationService.getAverageRating()
    }
    
    // MARK: - Quick Actions
    
    var featuredRecommendation: Recommendation? {
        return recommendations
            .filter { !$0.isRead && !$0.isInLibrary }
            .max { $0.confidenceScore < $1.confidenceScore }
    }
    
    var todaysRecommendations: [Recommendation] {
        let calendar = Calendar.current
        return recommendations.filter { recommendation in
            calendar.isDateInToday(recommendation.dateGenerated)
        }.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    var highConfidenceRecommendations: [Recommendation] {
        return getRecommendations(by: .high)
    }
    
    var algorithmRecommendations: [Recommendation] {
        return getRecommendations(by: .algorithm)
    }
    
    var trendingRecommendations: [Recommendation] {
        return getRecommendations(by: .trending)
    }
    
    // MARK: - Filters and Options
    
    var availableTypes: [RecommendationType] {
        let typesInUse = Set(recommendations.map { $0.recommendationType })
        return RecommendationType.allCases.filter { typesInUse.contains($0) }
    }
    
    var availableConfidenceLevels: [ConfidenceLevel] {
        let levelsInUse = Set(recommendations.map { $0.confidenceLevel })
        return ConfidenceLevel.allCases.filter { levelsInUse.contains($0) }
    }
    
    var availableGenres: [String] {
        let genres = Set(recommendations.map { $0.genre })
        return Array(genres).sorted()
    }
    
    // MARK: - Actions
    
    func markAllAsRead() {
        for recommendation in recommendations {
            if !recommendation.isRead {
                markAsRead(recommendation)
            }
        }
    }
    
    func addAllTopRecommendationsToLibrary() {
        let topRecommendations = getTopRecommendations().filter { !$0.isInLibrary }
        for recommendation in topRecommendations {
            addToLibrary(recommendation)
        }
    }
    
    func dismissRecommendation(_ recommendation: Recommendation) {
        // Mark as read and low rating to indicate dismissal
        markAsRead(recommendation)
        rateRecommendation(recommendation, rating: 1.0)
    }
    
    // MARK: - Search and Suggestions
    
    func getSearchSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Add genres
        suggestions.append(contentsOf: availableGenres.prefix(5))
        
        // Add authors
        let authors = Set(recommendations.map { $0.author })
        suggestions.append(contentsOf: Array(authors).prefix(5))
        
        // Add recommendation types
        suggestions.append(contentsOf: availableTypes.map { $0.rawValue })
        
        return Array(Set(suggestions)).sorted()
    }
    
    func clearFilters() {
        searchText = ""
        selectedType = nil
        selectedConfidenceLevel = nil
        showReadOnly = false
        showUnreadOnly = false
        showInLibraryOnly = false
    }
    
    // MARK: - Validation
    
    var hasRecommendations: Bool {
        return !recommendations.isEmpty
    }
    
    var hasUnreadRecommendations: Bool {
        return recommendations.contains { !$0.isRead }
    }
    
    var hasHighConfidenceRecommendations: Bool {
        return recommendations.contains { $0.confidenceLevel == .high }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    // MARK: - Export and Sharing
    
    func exportRecommendation(_ recommendation: Recommendation) -> String {
        return """
        # \(recommendation.title)
        
        **Author:** \(recommendation.author)
        **Genre:** \(recommendation.genre)
        **Confidence:** \(recommendation.confidencePercentage)%
        **Type:** \(recommendation.recommendationType.rawValue)
        
        ## Reason
        \(recommendation.reason)
        
        ## Synopsis
        \(recommendation.synopsis)
        
        ---
        Generated by Biblioscribe Road on \(DateFormatter.medium.string(from: recommendation.dateGenerated))
        """
    }
    
    func shareRecommendations() -> String {
        let topRecommendations = getTopRecommendations()
        var shareText = "# My Top Book Recommendations\n\n"
        
        for (index, recommendation) in topRecommendations.enumerated() {
            shareText += "\(index + 1). **\(recommendation.title)** by \(recommendation.author)\n"
            shareText += "   Genre: \(recommendation.genre) | Confidence: \(recommendation.confidencePercentage)%\n"
            shareText += "   \(recommendation.reason)\n\n"
        }
        
        shareText += "Generated by Biblioscribe Road"
        return shareText
    }
}

enum RecommendationSortOption: String, CaseIterable {
    case confidence = "Confidence"
    case title = "Title"
    case author = "Author"
    case genre = "Genre"
    case rating = "Rating"
    case dateGenerated = "Date"
    case type = "Type"
    
    var systemImage: String {
        switch self {
        case .confidence:
            return "gauge.high"
        case .title:
            return "textformat.abc"
        case .author:
            return "person.circle"
        case .genre:
            return "tag"
        case .rating:
            return "star"
        case .dateGenerated:
            return "calendar"
        case .type:
            return "list.bullet"
        }
    }
}

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}