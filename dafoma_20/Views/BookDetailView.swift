import SwiftUI

struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var noteViewModel: NoteViewModel
    @State private var isReading = false
    @State private var showingNotes = false
    @State private var showingPreferences = false
    @State private var selectedRating: Int = 0
    @State private var showingRatingPopover = false
    
    var body: some View {
        ZStack {
            Color(hex: "3e4464").ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isReading {
                    ReadingView(book: book, isReading: $isReading)
                } else {
                    BookOverviewView(
                        book: book,
                        isReading: $isReading,
                        showingNotes: $showingNotes,
                        showingPreferences: $showingPreferences,
                        selectedRating: $selectedRating,
                        showingRatingPopover: $showingRatingPopover
                    )
                }
            }
        }
        .navigationBarHidden(isReading)
        .sheet(isPresented: $showingNotes) {
            BookNotesView(bookId: book.id)
        }
        .sheet(isPresented: $showingPreferences) {
            ReadingPreferencesView(book: book)
        }
        .popover(isPresented: $showingRatingPopover) {
            RatingView(
                currentRating: book.rating ?? 0,
                onRatingChanged: { rating in
                    bookViewModel.rateCurrentBook(rating)
                    showingRatingPopover = false
                }
            )
        }
        .onAppear {
            selectedRating = book.rating ?? 0
        }
    }
}

struct BookOverviewView: View {
    let book: Book
    @Binding var isReading: Bool
    @Binding var showingNotes: Bool
    @Binding var showingPreferences: Bool
    @Binding var selectedRating: Int
    @Binding var showingRatingPopover: Bool
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Header
                BookHeaderView(
                    book: book,
                    showingRatingPopover: $showingRatingPopover
                )
                
                // Action Buttons
                ActionButtonsView(
                    book: book,
                    isReading: $isReading,
                    showingNotes: $showingNotes,
                    showingPreferences: $showingPreferences
                )
                
                // Book Details
                BookDetailsView(book: book)
                
                // Recent Notes Preview
                RecentNotesPreview(
                    bookId: book.id,
                    showingNotes: $showingNotes
                )
            }
            .padding()
        }
    }
}

struct BookHeaderView: View {
    let book: Book
    @Binding var showingRatingPopover: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Book Cover
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "fcc418").opacity(0.4), Color(hex: "3cc45b").opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 240)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(book.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 8)
                    }
                )
                .shadow(radius: 10)
                .accessibilityLabel("Book cover for \(book.title)")
            
            // Book Title and Author
            VStack(spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityHeading(.h1)
                
                Text("by \(book.author)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text(book.genre)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "fcc418"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "fcc418").opacity(0.2))
                    )
            }
            
            // Rating
            HStack {
                if let rating = book.rating {
                    StarRatingView(rating: rating, isInteractive: false)
                    Text("(\(rating)/5)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Not rated")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Button(action: { showingRatingPopover = true }) {
                    Image(systemName: "star.circle")
                        .foregroundColor(Color(hex: "fcc418"))
                }
                .accessibilityLabel("Rate this book")
            }
            
            // Progress
            if book.currentPage > 0 {
                ProgressCard(book: book)
            }
        }
    }
}

struct ProgressCard: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Reading Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(book.progressPercentage)% complete")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "fcc418"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(book.currentPage)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("of \(book.totalPages)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            ProgressView(value: book.progress)
                .accentColor(Color(hex: "fcc418"))
                .scaleEffect(y: 1.5)
            
            if let lastRead = book.lastReadDate {
                Text("Last read: \(lastRead, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading progress: \(book.progressPercentage)% complete, page \(book.currentPage) of \(book.totalPages)")
    }
}

struct ActionButtonsView: View {
    let book: Book
    @Binding var isReading: Bool
    @Binding var showingNotes: Bool
    @Binding var showingPreferences: Bool
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Read/Continue Reading Button
                Button(action: { isReading = true }) {
                    HStack {
                        Image(systemName: book.currentPage > 0 ? "play.fill" : "book.fill")
                        Text(book.currentPage > 0 ? "Continue Reading" : "Start Reading")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "fcc418"))
                    )
                }
                .accessibilityLabel(book.currentPage > 0 ? "Continue reading from page \(book.currentPage)" : "Start reading this book")
            }
            
            HStack(spacing: 12) {
                // Notes Button
                Button(action: { showingNotes = true }) {
                    HStack {
                        Image(systemName: "note.text")
                        Text("Notes")
                        if noteViewModel.getNotesCount(for: book.id) > 0 {
                            Text("(\(noteViewModel.getNotesCount(for: book.id)))")
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("View notes for this book")
                
                // Preferences Button
                Button(action: { showingPreferences = true }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Settings")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Reading preferences")
            }
            
            // Mark as Complete Button (if not completed)
            if !book.isCompleted && book.currentPage > 0 {
                Button(action: {
                    bookViewModel.markCurrentBookCompleted()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Complete")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "3cc45b"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "3cc45b").opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Mark book as completed")
            }
        }
    }
}

struct BookDetailsView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Synopsis
            VStack(alignment: .leading, spacing: 8) {
                Text("Synopsis")
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityHeading(.h2)
                
                Text(book.synopsis)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            
            // Tags
            if !book.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(.white)
                        .accessibilityHeading(.h2)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(book.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                }
            }
            
            // Book Stats
            HStack {
                StatCard(title: "Pages", value: "\(book.totalPages)")
                StatCard(title: "Added", value: book.dateAdded.formatted(.dateTime.month().day()))
                if book.isCompleted {
                    StatCard(title: "Completed", value: "✓")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct RecentNotesPreview: View {
    let bookId: UUID
    @Binding var showingNotes: Bool
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    var recentNotes: [Note] {
        noteViewModel.getNotes(for: bookId).prefix(3).map { $0 }
    }
    
    var body: some View {
        if !recentNotes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .accessibilityHeading(.h2)
                    
                    Spacer()
                    
                    Button("View All") {
                        showingNotes = true
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "fcc418"))
                }
                
                ForEach(recentNotes) { note in
                    NotePreviewCard(note: note)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

struct NotePreviewCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "fcc418"))
                }
                
                Text(note.category.rawValue)
                    .font(.caption)
                    .foregroundColor(note.category.color)
            }
            
            Text(note.previewText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(note.color.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(note.color.color.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note: \(note.title). \(note.previewText)")
    }
}

struct StarRatingView: View {
    let rating: Int
    let isInteractive: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? Color(hex: "fcc418") : .white.opacity(0.3))
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rating) out of 5 stars")
    }
}

struct RatingView: View {
    let currentRating: Int
    let onRatingChanged: (Int) -> Void
    @State private var selectedRating: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rate this book")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        selectedRating = star
                        onRatingChanged(star)
                    }) {
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .foregroundColor(star <= selectedRating ? Color(hex: "fcc418") : .gray)
                            .font(.title2)
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                }
            }
            
            if selectedRating > 0 {
                Text("\(selectedRating) star\(selectedRating == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            selectedRating = currentRating
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(book: Book(
            title: "Sample Book",
            author: "Sample Author",
            genre: "Fiction",
            synopsis: "This is a sample book for preview purposes.",
            content: "Sample content"
        ))
    }
    .environmentObject(BookViewModel(bookService: BookService()))
    .environmentObject(NoteViewModel(noteService: NoteService()))
}
