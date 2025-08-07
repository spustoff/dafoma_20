import Foundation
import SwiftUI

class BookService: ObservableObject {
    @Published var books: [Book] = []
    private let userDefaults = UserDefaults.standard
    private let booksKey = "SavedBooks"
    
    init() {
        loadBooks()
        
        // Add sample books if none exist
        if books.isEmpty {
            loadSampleBooks()
        }
    }
    
    // MARK: - Book Management
    
    func addBook(_ book: Book) {
        books.append(book)
        saveBooks()
    }
    
    func updateBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
            saveBooks()
        }
    }
    
    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        saveBooks()
    }
    
    func deleteBook(at indexSet: IndexSet) {
        books.remove(atOffsets: indexSet)
        saveBooks()
    }
    
    func getBook(by id: UUID) -> Book? {
        return books.first { $0.id == id }
    }
    
    // MARK: - Reading Progress
    
    func updateReadingProgress(bookId: UUID, currentPage: Int) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].currentPage = min(currentPage, books[index].totalPages)
            books[index].lastReadDate = Date()
            
            // Mark as completed if finished
            if books[index].currentPage >= books[index].totalPages {
                books[index].isCompleted = true
            }
            
            saveBooks()
        }
    }
    
    func markAsCompleted(bookId: UUID) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].isCompleted = true
            books[index].currentPage = books[index].totalPages
            books[index].lastReadDate = Date()
            saveBooks()
        }
    }
    
    func rateBook(bookId: UUID, rating: Int) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].rating = max(1, min(5, rating))
            saveBooks()
        }
    }
    
    // MARK: - Reading Preferences
    
    func updateReadingPreferences(bookId: UUID, fontSize: CGFloat, fontFamily: FontFamily, backgroundColor: BackgroundColor, textColor: TextColor) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].fontSize = fontSize
            books[index].fontFamily = fontFamily
            books[index].backgroundColor = backgroundColor
            books[index].textColor = textColor
            saveBooks()
        }
    }
    
    // MARK: - Tags Management
    
    func addTag(to bookId: UUID, tag: String) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            if !books[index].tags.contains(tag) {
                books[index].tags.append(tag)
                saveBooks()
            }
        }
    }
    
    func removeTag(from bookId: UUID, tag: String) {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].tags.removeAll { $0 == tag }
            saveBooks()
        }
    }
    
    // MARK: - Filtering and Searching
    
    func getBooksByGenre(_ genre: String) -> [Book] {
        return books.filter { $0.genre.lowercased() == genre.lowercased() }
    }
    
    func getBooksByAuthor(_ author: String) -> [Book] {
        return books.filter { $0.author.lowercased().contains(author.lowercased()) }
    }
    
    func searchBooks(_ query: String) -> [Book] {
        guard !query.isEmpty else { return books }
        
        return books.filter { book in
            book.title.lowercased().contains(query.lowercased()) ||
            book.author.lowercased().contains(query.lowercased()) ||
            book.genre.lowercased().contains(query.lowercased()) ||
            book.tags.contains { $0.lowercased().contains(query.lowercased()) }
        }
    }
    
    func getCompletedBooks() -> [Book] {
        return books.filter { $0.isCompleted }
    }
    
    func getCurrentlyReading() -> [Book] {
        return books.filter { !$0.isCompleted && $0.currentPage > 0 }
    }
    
    func getUnreadBooks() -> [Book] {
        return books.filter { $0.currentPage == 0 }
    }
    
    // MARK: - Statistics
    
    var totalBooksCount: Int {
        books.count
    }
    
    var completedBooksCount: Int {
        books.filter { $0.isCompleted }.count
    }
    
    var currentlyReadingCount: Int {
        getCurrentlyReading().count
    }
    
    var averageRating: Double {
        let ratedBooks = books.compactMap { $0.rating }
        guard !ratedBooks.isEmpty else { return 0.0 }
        return Double(ratedBooks.reduce(0, +)) / Double(ratedBooks.count)
    }
    
    var favoriteGenres: [String] {
        let genreCounts = Dictionary(grouping: books, by: { $0.genre })
            .mapValues { $0.count }
        
        return genreCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    // MARK: - Persistence
    
    private func saveBooks() {
        do {
            let data = try JSONEncoder().encode(books)
            userDefaults.set(data, forKey: booksKey)
        } catch {
            print("Failed to save books: \(error)")
        }
    }
    
    private func loadBooks() {
        guard let data = userDefaults.data(forKey: booksKey) else { return }
        
        do {
            books = try JSONDecoder().decode([Book].self, from: data)
        } catch {
            print("Failed to load books: \(error)")
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleBooks() {
        let sampleBooks = [
            Book(
                title: "To Kill a Mockingbird",
                author: "Harper Lee",
                genre: "Classic Literature",
                synopsis: "A gripping tale of racial injustice and loss of innocence in the American South.",
                content: generateSampleContent(),
                totalPages: 281
            ),
            Book(
                title: "1984",
                author: "George Orwell",
                genre: "Dystopian Fiction",
                synopsis: "A chilling vision of a totalitarian future where freedom and truth are under siege.",
                content: generateSampleContent(),
                totalPages: 328
            ),
            Book(
                title: "The Great Gatsby",
                author: "F. Scott Fitzgerald",
                genre: "Classic Literature",
                synopsis: "The story of Jay Gatsby's pursuit of the American Dream and his tragic obsession with Daisy Buchanan.",
                content: generateSampleContent(),
                totalPages: 180
            ),
            Book(
                title: "Dune",
                author: "Frank Herbert",
                genre: "Science Fiction",
                synopsis: "Epic tale of politics, religion, and ecology on the desert planet Arrakis.",
                content: generateSampleContent(),
                totalPages: 688
            ),
            Book(
                title: "Pride and Prejudice",
                author: "Jane Austen",
                genre: "Romance",
                synopsis: "The timeless story of Elizabeth Bennet and Mr. Darcy's tumultuous relationship.",
                content: generateSampleContent(),
                totalPages: 432
            )
        ]
        
        for book in sampleBooks {
            books.append(book)
        }
        
        // Set some reading progress for demo
        if books.count > 0 {
            books[0].currentPage = 45
            books[0].rating = 5
            books[1].currentPage = 120
            books[1].rating = 4
            books[2].isCompleted = true
            books[2].currentPage = books[2].totalPages
            books[2].rating = 5
        }
        
        saveBooks()
    }
    
    private func generateSampleContent() -> String {
        return """
        Chapter 1
        
        In the beginning of every story, there lies a moment of infinite possibility. The characters stand at the threshold of their journey, unaware of the adventures that await them. Each page turns like a season, bringing new revelations and deeper understanding.
        
        The art of storytelling has captivated humanity for millennia. From ancient oral traditions to modern digital narratives, we have always sought to make sense of our world through the power of story. Characters become our companions, their struggles our own, their victories our celebration.
        
        Chapter 2
        
        As we delve deeper into the narrative, the complexities of human nature begin to unfold. Each character carries within them a universe of experiences, hopes, and fears. The skilled author weaves these elements together, creating a tapestry rich with meaning and emotion.
        
        Literature serves as both mirror and window - reflecting our own experiences while offering glimpses into lives vastly different from our own. Through reading, we develop empathy, broaden our perspectives, and gain insights that shape our understanding of the world.
        
        Chapter 3
        
        The power of words to transport us cannot be understated. Within the pages of a book, we can travel to distant lands, experience different time periods, and encounter extraordinary circumstances. Reading expands the boundaries of our reality, offering escape and enlightenment in equal measure.
        
        Every book is a conversation between author and reader, a dialogue that transcends time and space. The author plants seeds of thought and emotion, which bloom differently in each reader's mind, creating a unique and personal experience with every reading.
        
        This is just the beginning of what promises to be an extraordinary literary journey...
        """
    }
}