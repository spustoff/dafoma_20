import SwiftUI

struct ReadingView: View {
    let book: Book
    @Binding var isReading: Bool
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    @State private var currentPageOffset: CGFloat = 0
    @State private var showingMenu = false
    @State private var showingNoteEditor = false
    @State private var selectedText = ""
    @State private var showingSettings = false
    @State private var brightness: Double = 0.5
    @State private var autoScroll = false
    @State private var scrollSpeed: Double = 1.0
    
    private let pageWidth = UIScreen.main.bounds.width
    private let contentPages: [String]
    
    init(book: Book, isReading: Binding<Bool>) {
        self.book = book
        self._isReading = isReading
        self.contentPages = ReadingView.splitContentIntoPages(book.content)
    }
    
    var body: some View {
        ZStack {
            // Background
            book.backgroundColor.color.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top toolbar (hidden by default)
                if showingMenu {
                    ReadingToolbar(
                        book: book,
                        isReading: $isReading,
                        showingSettings: $showingSettings,
                        showingNoteEditor: $showingNoteEditor
                    )
                    .transition(.move(edge: .top))
                }
                
                // Reading content
                ReadingContentView(
                    book: book,
                    pages: contentPages,
                    showingMenu: $showingMenu,
                    selectedText: $selectedText,
                    showingNoteEditor: $showingNoteEditor
                )
                
                // Bottom controls (hidden by default)
                if showingMenu {
                    ReadingBottomControls(
                        book: book,
                        currentPage: getCurrentPageNumber(),
                        totalPages: contentPages.count,
                        onPageChanged: updateCurrentPage
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingMenu)
        .onTapGesture(count: 1) {
            withAnimation {
                showingMenu.toggle()
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorView(
                bookId: book.id,
                pageReference: getCurrentPageNumber(),
                selectedText: selectedText
            )
        }
        .sheet(isPresented: $showingSettings) {
            ReadingPreferencesView(book: book)
        }
        .statusBarHidden()
        .preferredColorScheme(book.backgroundColor == .dark || book.backgroundColor == .night ? .dark : .light)
    }
    
    private func getCurrentPageNumber() -> Int {
        let currentPageIndex = Int(-currentPageOffset / pageWidth)
        let adjustedIndex = max(0, min(currentPageIndex, contentPages.count - 1))
        return adjustedIndex + 1 // 1-based indexing for display
    }
    
    private func updateCurrentPage(_ page: Int) {
        let adjustedPage = max(1, min(page, contentPages.count))
        bookViewModel.updateReadingProgress(currentPage: adjustedPage)
    }
    
    static func splitContentIntoPages(_ content: String, wordsPerPage: Int = 250) -> [String] {
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var pages: [String] = []
        
        for i in stride(from: 0, to: words.count, by: wordsPerPage) {
            let endIndex = min(i + wordsPerPage, words.count)
            let pageWords = Array(words[i..<endIndex])
            pages.append(pageWords.joined(separator: " "))
        }
        
        return pages.isEmpty ? [""] : pages
    }
}

struct ReadingContentView: View {
    let book: Book
    let pages: [String]
    @Binding var showingMenu: Bool
    @Binding var selectedText: String
    @Binding var showingNoteEditor: Bool
    
    @State private var currentPageIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(pages.indices, id: \.self) { index in
                        ReadingPageView(
                            content: pages[index],
                            book: book,
                            pageNumber: index + 1,
                            totalPages: pages.count,
                            selectedText: $selectedText,
                            showingNoteEditor: $showingNoteEditor
                        )
                        .frame(width: geometry.size.width)
                    }
                }
            }

        }
        .onAppear {
            // Start from the book's current page
            let startPage = max(0, min(book.currentPage - 1, pages.count - 1))
            currentPageIndex = startPage
        }
    }
}

struct ReadingPageView: View {
    let content: String
    let book: Book
    let pageNumber: Int
    let totalPages: Int
    @Binding var selectedText: String
    @Binding var showingNoteEditor: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Page content
                SelectableText(
                    content: content,
                    font: book.fontFamily.font.size(book.fontSize),
                    textColor: book.textColor.color,
                    onTextSelected: { text in
                        selectedText = text
                        showingNoteEditor = true
                    }
                )
                .lineSpacing(4)
                .padding(.top, 20)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .background(book.backgroundColor.color)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page \(pageNumber) of \(totalPages)")
    }
}

struct SelectableText: View {
    let content: String
    let font: Font
    let textColor: Color
    let onTextSelected: (String) -> Void
    
    var body: some View {
        Text(content)
            .font(font)
            .foregroundColor(textColor)
            .textSelection(.enabled)
            .onLongPressGesture {
                // This would trigger text selection in a real implementation
                // For now, we'll simulate it
                let words = content.components(separatedBy: .whitespacesAndNewlines)
                if let randomWord = words.randomElement() {
                    onTextSelected(randomWord)
                }
            }
    }
}

struct ReadingToolbar: View {
    let book: Book
    @Binding var isReading: Bool
    @Binding var showingSettings: Bool
    @Binding var showingNoteEditor: Bool
    
    var body: some View {
        HStack {
            // Back button
            Button(action: { isReading = false }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(book.textColor.color)
            }
            .accessibilityLabel("Back to book details")
            
            Spacer()
            
            // Book title
            Text(book.title)
                .font(.headline)
                .foregroundColor(book.textColor.color)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 16) {
                // Add note button
                Button(action: { showingNoteEditor = true }) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.title2)
                        .foregroundColor(book.textColor.color)
                }
                .accessibilityLabel("Add note")
                
                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "textformat.size")
                        .font(.title2)
                        .foregroundColor(book.textColor.color)
                }
                .accessibilityLabel("Reading settings")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(book.backgroundColor.color.opacity(0.9))
                .overlay(
                    Rectangle()
                        .stroke(book.textColor.color.opacity(0.2), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
        )
    }
}

struct ReadingBottomControls: View {
    let book: Book
    let currentPage: Int
    let totalPages: Int
    let onPageChanged: (Int) -> Void
    
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress slider
            HStack {
                Text("\(currentPage)")
                    .font(.caption)
                    .foregroundColor(book.textColor.color)
                    .frame(width: 30)
                
                Slider(
                    value: $sliderValue,
                    in: 1...Double(totalPages),
                    step: 1
                ) { editing in
                    if !editing {
                        onPageChanged(Int(sliderValue))
                    }
                }
                .accentColor(Color(hex: "fcc418"))
                
                Text("\(totalPages)")
                    .font(.caption)
                    .foregroundColor(book.textColor.color)
                    .frame(width: 30)
            }
            
            // Progress text
            HStack {
                Text("\(Int((Double(currentPage) / Double(totalPages)) * 100))% complete")
                    .font(.caption)
                    .foregroundColor(book.textColor.color.opacity(0.7))
                
                Spacer()
                
                if let rating = book.rating {
                    StarRatingView(rating: rating, isInteractive: false)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(book.backgroundColor.color.opacity(0.9))
                .overlay(
                    Rectangle()
                        .stroke(book.textColor.color.opacity(0.2), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
        )
        .onAppear {
            sliderValue = Double(currentPage)
        }
        .onChange(of: currentPage) { newPage in
            sliderValue = Double(newPage)
        }
    }
}

// MARK: - Font Extension

extension Font {
    func size(_ size: CGFloat) -> Font {
        return Font.system(size: size)
    }
}

#Preview {
    ReadingView(
        book: Book(
            title: "Sample Book",
            author: "Sample Author",
            genre: "Fiction",
            synopsis: "A sample book",
            content: String(repeating: "This is sample content for the reading view. It demonstrates how the text flows and how pages are formatted. ", count: 50)
        ),
        isReading: .constant(true)
    )
    .environmentObject(BookViewModel(bookService: BookService()))
    .environmentObject(NoteViewModel(noteService: NoteService()))
}
