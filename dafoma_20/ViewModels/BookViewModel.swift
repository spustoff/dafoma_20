import Foundation
import SwiftUI
import Combine

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var currentBook: Book?
    @Published var searchText = ""
    @Published var selectedGenre: String = "All"
    @Published var sortOption: BookSortOption = .dateAdded
    @Published var showCompleted = true
    @Published var showInProgress = true
    @Published var showUnread = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let bookService: BookService
    private var cancellables = Set<AnyCancellable>()
    
    init(bookService: BookService) {
        self.bookService = bookService
        setupBindings()
        loadBooks()
    }
    
    private func setupBindings() {
        // Observe changes from the service
        bookService.$books
            .receive(on: DispatchQueue.main)
            .sink { [weak self] books in
                self?.books = books
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadBooks() {
        isLoading = true
        // The service loads automatically, so we just need to wait
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func refreshBooks() {
        loadBooks()
    }
    
    // MARK: - Book Management
    
    func addBook(title: String, author: String, genre: String, synopsis: String, content: String, totalPages: Int = 100) {
        let book = Book(title: title, author: author, genre: genre, synopsis: synopsis, content: content, totalPages: totalPages)
        bookService.addBook(book)
    }
    
    func updateBook(_ book: Book) {
        bookService.updateBook(book)
        if currentBook?.id == book.id {
            currentBook = book
        }
    }
    
    func deleteBook(_ book: Book) {
        bookService.deleteBook(book)
        if currentBook?.id == book.id {
            currentBook = nil
        }
    }
    
    func selectBook(_ book: Book) {
        currentBook = book
    }
    
    // MARK: - Reading Progress
    
    func updateReadingProgress(currentPage: Int) {
        guard let book = currentBook else { return }
        bookService.updateReadingProgress(bookId: book.id, currentPage: currentPage)
        
        // Update local current book
        if let updatedBook = bookService.getBook(by: book.id) {
            currentBook = updatedBook
        }
    }
    
    func markCurrentBookCompleted() {
        guard let book = currentBook else { return }
        bookService.markAsCompleted(bookId: book.id)
        
        if let updatedBook = bookService.getBook(by: book.id) {
            currentBook = updatedBook
        }
    }
    
    func rateCurrentBook(_ rating: Int) {
        guard let book = currentBook else { return }
        bookService.rateBook(bookId: book.id, rating: rating)
        
        if let updatedBook = bookService.getBook(by: book.id) {
            currentBook = updatedBook
        }
    }
    
    // MARK: - Reading Preferences
    
    func updateReadingPreferences(fontSize: CGFloat, fontFamily: FontFamily, backgroundColor: BackgroundColor, textColor: TextColor) {
        guard let book = currentBook else { return }
        bookService.updateReadingPreferences(
            bookId: book.id,
            fontSize: fontSize,
            fontFamily: fontFamily,
            backgroundColor: backgroundColor,
            textColor: textColor
        )
        
        if let updatedBook = bookService.getBook(by: book.id) {
            currentBook = updatedBook
        }
    }
    
    // MARK: - Tag Management
    
    func addTag(to book: Book, tag: String) {
        bookService.addTag(to: book.id, tag: tag)
    }
    
    func removeTag(from book: Book, tag: String) {
        bookService.removeTag(from: book.id, tag: tag)
    }
    
    // MARK: - Filtering and Searching
    
    var filteredBooks: [Book] {
        var result = books
        
        // Apply text search
        if !searchText.isEmpty {
            result = bookService.searchBooks(searchText)
        }
        
        // Apply genre filter
        if selectedGenre != "All" {
            result = result.filter { $0.genre == selectedGenre }
        }
        
        // Apply status filters
        result = result.filter { book in
            (showCompleted && book.isCompleted) ||
            (showInProgress && !book.isCompleted && book.currentPage > 0) ||
            (showUnread && book.currentPage == 0)
        }
        
        // Apply sorting
        return sortBooks(result)
    }
    
    private func sortBooks(_ books: [Book]) -> [Book] {
        switch sortOption {
        case .title:
            return books.sorted { $0.title < $1.title }
        case .author:
            return books.sorted { $0.author < $1.author }
        case .genre:
            return books.sorted { $0.genre < $1.genre }
        case .dateAdded:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .lastRead:
            return books.sorted { ($0.lastReadDate ?? Date.distantPast) > ($1.lastReadDate ?? Date.distantPast) }
        case .progress:
            return books.sorted { $0.progress > $1.progress }
        case .rating:
            return books.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
    }
    
    var availableGenres: [String] {
        let genres = Set(books.map { $0.genre })
        return ["All"] + Array(genres).sorted()
    }
    
    // MARK: - Statistics
    
    var totalBooksCount: Int {
        bookService.totalBooksCount
    }
    
    var completedBooksCount: Int {
        bookService.completedBooksCount
    }
    
    var currentlyReadingCount: Int {
        bookService.currentlyReadingCount
    }
    
    var averageRating: Double {
        bookService.averageRating
    }
    
    var favoriteGenres: [String] {
        bookService.favoriteGenres
    }
    
    var readingStreak: Int {
        // Calculate current reading streak
        let recentBooks = books.filter { book in
            guard let lastRead = book.lastReadDate else { return false }
            return Calendar.current.isDateInToday(lastRead) || Calendar.current.isDateInYesterday(lastRead)
        }
        return recentBooks.count
    }
    
    var totalPagesRead: Int {
        books.reduce(0) { total, book in
            total + book.currentPage
        }
    }
    
    var averageProgress: Double {
        guard !books.isEmpty else { return 0.0 }
        let totalProgress = books.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(books.count)
    }
    
    // MARK: - Quick Actions
    
    func getRecentlyRead() -> [Book] {
        return books
            .filter { $0.lastReadDate != nil }
            .sorted { $0.lastReadDate! > $1.lastReadDate! }
            .prefix(5)
            .map { $0 }
    }
    
    func getCurrentlyReading() -> [Book] {
        return bookService.getCurrentlyReading()
    }
    
    func getNextToRead() -> [Book] {
        return bookService.getUnreadBooks().prefix(3).map { $0 }
    }
    
    func getBooksByRating(_ rating: Int) -> [Book] {
        return books.filter { $0.rating == rating }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

enum BookSortOption: String, CaseIterable {
    case title = "Title"
    case author = "Author"
    case genre = "Genre"
    case dateAdded = "Date Added"
    case lastRead = "Last Read"
    case progress = "Progress"
    case rating = "Rating"
    
    var systemImage: String {
        switch self {
        case .title:
            return "textformat.abc"
        case .author:
            return "person.circle"
        case .genre:
            return "tag"
        case .dateAdded:
            return "calendar.badge.plus"
        case .lastRead:
            return "clock"
        case .progress:
            return "chart.bar"
        case .rating:
            return "star"
        }
    }
}