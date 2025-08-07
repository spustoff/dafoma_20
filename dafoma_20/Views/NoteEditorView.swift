import SwiftUI

struct NoteEditorView: View {
    let bookId: UUID
    let pageReference: Int?
    let selectedText: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var noteViewModel: NoteViewModel
    @EnvironmentObject var bookService: BookService
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: NoteCategory = .general
    @State private var selectedColor: NoteColor = .yellow
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var includeSelectedText = true
    @State private var isBookmarked = false
    
    private var book: Book? {
        bookService.getBook(by: bookId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Context Information
                        if let book = book {
                            ContextCard(book: book, pageReference: pageReference)
                        }
                        
                        // Selected Text Preview
                        if !selectedText.isEmpty {
                            SelectedTextCard(
                                selectedText: selectedText,
                                includeInNote: $includeSelectedText
                            )
                        }
                        
                        // Note Content
                        NoteContentEditor(
                            title: $title,
                            content: $content,
                            selectedCategory: $selectedCategory,
                            selectedColor: $selectedColor,
                            isBookmarked: $isBookmarked
                        )
                        
                        // Tags Section
                        TagsEditor(tags: $tags, newTag: $newTag)
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(Color(hex: "fcc418"))
                    .disabled(!canSaveNote)
                }
            }
        }
        .onAppear {
            setupInitialContent()
        }
    }
    
    private func setupInitialContent() {
        if !selectedText.isEmpty && includeSelectedText {
            content = "\"\(selectedText)\"\n\n"
            title = "Note from page \(pageReference ?? 1)"
        }
    }
    
    private func saveNote() {
        var finalContent = content
        
        if !selectedText.isEmpty && includeSelectedText && !content.contains(selectedText) {
            finalContent = "\"\(selectedText)\"\n\n\(content)"
        }
        
        let note = noteViewModel.createNote(
            title: title.isEmpty ? "Untitled Note" : title,
            content: finalContent,
            bookId: bookId,
            pageReference: pageReference,
            category: selectedCategory,
            color: selectedColor
        )
        
        // Add tags
        for tag in tags {
            noteViewModel.addTagToNote(note, tag: tag)
        }
        
        if isBookmarked {
            noteViewModel.toggleBookmark(for: note)
        }
        
        dismiss()
    }
    
    private var canSaveNote: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ContextCard: View {
    let book: Book
    let pageReference: Int?
    
    var body: some View {
        HStack {
            // Book icon
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "fcc418").opacity(0.3))
                .frame(width: 40, height: 50)
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(Color(hex: "fcc418"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                if let pageRef = pageReference {
                    Text("Page \(pageRef)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "fcc418"))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Creating note for \(book.title) by \(book.author)")
    }
}

struct SelectedTextCard: View {
    let selectedText: String
    @Binding var includeInNote: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Text")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("Include", isOn: $includeInNote)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "fcc418")))
            }
            
            Text(selectedText)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "fcc418").opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected text to include in note")
    }
}

struct NoteContentEditor: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var selectedCategory: NoteCategory
    @Binding var selectedColor: NoteColor
    @Binding var isBookmarked: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter note title...", text: $title)
                    .textFieldStyle(NoteTextFieldStyle())
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $content)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                    .foregroundColor(.white)
                    .accentColor(Color(hex: "fcc418"))
            }
            
            // Category and Color
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color(hex: "fcc418"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(NoteColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                                .accessibilityLabel(color.rawValue)
                                .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
                        }
                    }
                }
            }
            
            // Bookmark toggle
            HStack {
                Label("Bookmark this note", systemImage: "bookmark")
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("Bookmark", isOn: $isBookmarked)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "fcc418")))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct TagsEditor: View {
    @Binding var tags: [String]
    @Binding var newTag: String
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    var popularTags: [String] {
        noteViewModel.popularTags.filter { !tags.contains($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.white)
            
            // Add new tag
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(NoteTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .foregroundColor(Color(hex: "fcc418"))
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Current tags
            if !tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(
                            text: tag,
                            isRemovable: true,
                            onRemove: { removeTag(tag) }
                        )
                    }
                }
            }
            
            // Popular tags suggestions
            if !popularTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Popular Tags")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(popularTags.prefix(6), id: \.self) { tag in
                            TagChip(
                                text: tag,
                                isRemovable: false,
                                onTap: { addExistingTag(tag) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        
        tags.append(trimmedTag)
        newTag = ""
    }
    
    private func addExistingTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct TagChip: View {
    let text: String
    let isRemovable: Bool
    var onRemove: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if isRemovable {
                Button(action: { onRemove?() }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isRemovable ? Color(hex: "fcc418").opacity(0.3) : Color.white.opacity(0.2))
        )
        .onTapGesture {
            if !isRemovable {
                onTap?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .accessibilityAddTraits(isRemovable ? .isButton : [])
    }
}

struct NoteTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            .foregroundColor(.white)
            .accentColor(Color(hex: "fcc418"))
    }
}

// MARK: - Book Notes View

struct BookNotesView: View {
    let bookId: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var noteViewModel: NoteViewModel
    @EnvironmentObject var bookService: BookService
    @State private var showingNoteEditor = false
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategory?
    @State private var showBookmarkedOnly = false
    
    private var book: Book? {
        bookService.getBook(by: bookId)
    }
    
    private var filteredNotes: [Note] {
        var notes = noteViewModel.getNotes(for: bookId)
        
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let category = selectedCategory {
            notes = notes.filter { $0.category == category }
        }
        
        if showBookmarkedOnly {
            notes = notes.filter { $0.isBookmarked }
        }
        
        return notes.sorted { $0.dateModified > $1.dateModified }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Book info header
                    if let book = book {
                        BookNotesHeader(book: book)
                    }
                    
                    // Search and filters
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText, placeholder: "Search notes...")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    title: "All",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(NoteCategory.allCases, id: \.self) { category in
                                    FilterChip(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                                
                                FilterChip(
                                    title: "Bookmarked",
                                    isSelected: showBookmarkedOnly,
                                    action: { showBookmarkedOnly.toggle() }
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // Notes list
                    if filteredNotes.isEmpty {
                        EmptyNotesView(showingNoteEditor: $showingNoteEditor)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    NoteListCard(note: note)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNoteEditor = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(hex: "fcc418"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorView(bookId: bookId, pageReference: nil, selectedText: "")
        }
    }
}

struct BookNotesHeader: View {
    let book: Book
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "fcc418").opacity(0.3))
                .frame(width: 40, height: 50)
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(Color(hex: "fcc418"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "fcc418") : Color.white.opacity(0.2))
                )
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct NoteListCard: View {
    let note: Note
    @EnvironmentObject var noteViewModel: NoteViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: note.category.icon)
                        .foregroundColor(note.category.color)
                        .font(.caption)
                    
                    Text(note.category.rawValue)
                        .font(.caption)
                        .foregroundColor(note.category.color)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if note.isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(Color(hex: "fcc418"))
                            .font(.caption)
                    }
                    
                    if let pageRef = note.pageReference {
                        Text("p.\(pageRef)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text(note.formattedDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Title
            Text(note.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Content preview
            Text(note.previewText)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(note.color.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(note.color.color.opacity(0.3), lineWidth: 1)
                )
        )
        .contextMenu {
            Button(action: {
                noteViewModel.toggleBookmark(for: note)
            }) {
                Label(note.isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: note.isBookmarked ? "bookmark.slash" : "bookmark")
            }
            
            Button(action: {
                noteViewModel.duplicateNote(note)
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button(role: .destructive, action: {
                noteViewModel.deleteNote(note)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note: \(note.title). \(note.previewText)")
    }
}

struct EmptyNotesView: View {
    @Binding var showingNoteEditor: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "fcc418").opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Start taking notes to capture your thoughts and insights while reading")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button("Create First Note") {
                showingNoteEditor = true
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding()
    }
}

#Preview {
    NoteEditorView(
        bookId: UUID(),
        pageReference: 42,
        selectedText: "This is some selected text from the book that the user wants to include in their note."
    )
    .environmentObject(NoteViewModel(noteService: NoteService()))
    .environmentObject(BookService())
}
