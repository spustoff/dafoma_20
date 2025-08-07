import Foundation
import SwiftUI
import Combine

class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: Note?
    @Published var searchText = ""
    @Published var selectedCategory: NoteCategory = .general
    @Published var selectedBook: UUID?
    @Published var showBookmarkedOnly = false
    @Published var sortOption: NoteSortOption = .dateModified
    @Published var isEditing = false
    @Published var editingTitle = ""
    @Published var editingContent = ""
    @Published var editingTags: [String] = []
    @Published var newTag = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let noteService: NoteService
    private var cancellables = Set<AnyCancellable>()
    
    init(noteService: NoteService) {
        self.noteService = noteService
        setupBindings()
        loadNotes()
    }
    
    private func setupBindings() {
        noteService.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                self?.notes = notes
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadNotes() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
        }
    }
    
    func refreshNotes() {
        loadNotes()
    }
    
    // MARK: - Note Management
    
    func createNote(title: String, content: String, bookId: UUID, pageReference: Int? = nil, category: NoteCategory = .general, color: NoteColor = .yellow) -> Note {
        let note = noteService.createNote(
            title: title,
            content: content,
            bookId: bookId,
            pageReference: pageReference,
            category: category,
            color: color
        )
        currentNote = note
        return note
    }
    
    func updateNote(_ note: Note) {
        noteService.updateNote(note)
        if currentNote?.id == note.id {
            currentNote = note
        }
    }
    
    func deleteNote(_ note: Note) {
        noteService.deleteNote(note)
        if currentNote?.id == note.id {
            currentNote = nil
        }
    }
    
    func selectNote(_ note: Note) {
        currentNote = note
        startEditing(note)
    }
    
    // MARK: - Note Editing
    
    func startEditing(_ note: Note) {
        editingTitle = note.title
        editingContent = note.content
        editingTags = note.tags
        isEditing = true
    }
    
    func saveCurrentEdit() {
        guard let note = currentNote else { return }
        
        var updatedNote = note
        updatedNote.title = editingTitle
        updatedNote.content = editingContent
        updatedNote.tags = editingTags
        
        updateNote(updatedNote)
        stopEditing()
    }
    
    func cancelEditing() {
        stopEditing()
    }
    
    private func stopEditing() {
        isEditing = false
        editingTitle = ""
        editingContent = ""
        editingTags = []
    }
    
    func startNewNote(for bookId: UUID) {
        editingTitle = ""
        editingContent = ""
        editingTags = []
        selectedBook = bookId
        isEditing = true
        currentNote = nil
    }
    
    func saveNewNote() {
        guard let bookId = selectedBook else { return }
        
        createNote(
            title: editingTitle.isEmpty ? "Untitled Note" : editingTitle,
            content: editingContent,
            bookId: bookId,
            category: selectedCategory
        )
        
        stopEditing()
        selectedBook = nil
    }
    
    // MARK: - Tag Management
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !editingTags.contains(trimmedTag) else { return }
        
        editingTags.append(trimmedTag)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        editingTags.removeAll { $0 == tag }
    }
    
    func addTagToNote(_ note: Note, tag: String) {
        noteService.addTag(to: note.id, tag: tag)
    }
    
    func removeTagFromNote(_ note: Note, tag: String) {
        noteService.removeTag(from: note.id, tag: tag)
    }
    
    var availableTags: [String] {
        noteService.getAllTags()
    }
    
    var popularTags: [String] {
        noteService.getPopularTags()
    }
    
    // MARK: - Note Organization
    
    func toggleBookmark(for note: Note) {
        noteService.toggleBookmark(for: note.id)
    }
    
    func updateNoteCategory(_ note: Note, category: NoteCategory) {
        noteService.updateNoteCategory(noteId: note.id, category: category)
    }
    
    func updateNoteColor(_ note: Note, color: NoteColor) {
        noteService.updateNoteColor(noteId: note.id, color: color)
    }
    
    // MARK: - Filtering and Searching
    
    var filteredNotes: [Note] {
        var result = notes
        
        // Apply text search
        if !searchText.isEmpty {
            result = noteService.searchNotes(searchText)
        }
        
        // Apply book filter
        if let bookId = selectedBook {
            result = result.filter { $0.bookId == bookId }
        }
        
        // Apply bookmark filter
        if showBookmarkedOnly {
            result = result.filter { $0.isBookmarked }
        }
        
        // Apply sorting
        return sortNotes(result)
    }
    
    private func sortNotes(_ notes: [Note]) -> [Note] {
        switch sortOption {
        case .title:
            return notes.sorted { $0.title < $1.title }
        case .dateCreated:
            return notes.sorted { $0.dateCreated > $1.dateCreated }
        case .dateModified:
            return notes.sorted { $0.dateModified > $1.dateModified }
        case .category:
            return notes.sorted { $0.category.rawValue < $1.category.rawValue }
        case .bookmarkStatus:
            return notes.sorted { $0.isBookmarked && !$1.isBookmarked }
        }
    }
    
    func getNotes(for bookId: UUID) -> [Note] {
        return noteService.getNotes(for: bookId)
    }
    
    func getBookmarkedNotes() -> [Note] {
        return noteService.getBookmarkedNotes()
    }
    
    func getNotes(by category: NoteCategory) -> [Note] {
        return noteService.getNotes(by: category)
    }
    
    func getNotes(with tag: String) -> [Note] {
        return noteService.getNotes(with: tag)
    }
    
    func getRecentNotes(limit: Int = 10) -> [Note] {
        return noteService.getRecentNotes(limit: limit)
    }
    
    // MARK: - Statistics
    
    var totalNotesCount: Int {
        noteService.totalNotesCount
    }
    
    var bookmarkedNotesCount: Int {
        noteService.bookmarkedNotesCount
    }
    
    func getNotesCount(for bookId: UUID) -> Int {
        noteService.getNotesCount(for: bookId)
    }
    
    var categoryDistribution: [NoteCategory: Int] {
        noteService.getCategoryDistribution()
    }
    
    var averageNotesPerBook: Double {
        noteService.getAverageNotesPerBook()
    }
    
    func getNotesCreatedInLast(days: Int) -> [Note] {
        return noteService.getNotesCreatedInLast(days: days)
    }
    
    // MARK: - Export and Sharing
    
    func exportNote(_ note: Note) -> String {
        return noteService.exportNote(note)
    }
    
    func exportAllNotes(for bookId: UUID) -> String {
        return noteService.exportAllNotes(for: bookId)
    }
    
    func shareNote(_ note: Note) -> String {
        return exportNote(note)
    }
    
    // MARK: - Quick Actions
    
    func duplicateNote(_ note: Note) {
        let duplicated = noteService.duplicateNote(note)
        currentNote = duplicated
    }
    
    func archiveNote(_ note: Note) {
        // For now, we'll use a tag to mark as archived
        addTagToNote(note, tag: "archived")
    }
    
    func unarchiveNote(_ note: Note) {
        removeTagFromNote(note, tag: "archived")
    }
    
    func getArchivedNotes() -> [Note] {
        return getNotes(with: "archived")
    }
    
    // MARK: - Bulk Operations
    
    func deleteAllNotes(for bookId: UUID) {
        noteService.deleteAllNotes(for: bookId)
    }
    
    func bulkUpdateCategory(notes: [Note], category: NoteCategory) {
        let noteIds = notes.map { $0.id }
        noteService.bulkUpdateCategory(noteIds: noteIds, category: category)
    }
    
    func bulkUpdateColor(notes: [Note], color: NoteColor) {
        let noteIds = notes.map { $0.id }
        noteService.bulkUpdateColor(noteIds: noteIds, color: color)
    }
    
    // MARK: - Search Suggestions
    
    func getSearchSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Add popular tags
        suggestions.append(contentsOf: popularTags.prefix(5))
        
        // Add category names
        suggestions.append(contentsOf: NoteCategory.allCases.map { $0.rawValue })
        
        // Add recent note titles
        let recentTitles = getRecentNotes(limit: 5).map { $0.title }
        suggestions.append(contentsOf: recentTitles)
        
        return Array(Set(suggestions)).sorted()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    // MARK: - Validation
    
    var canSaveNote: Bool {
        return !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !editingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isNoteModified: Bool {
        guard let note = currentNote else { return true }
        return note.title != editingTitle ||
               note.content != editingContent ||
               note.tags != editingTags
    }
}

enum NoteSortOption: String, CaseIterable {
    case title = "Title"
    case dateCreated = "Date Created"
    case dateModified = "Date Modified"
    case category = "Category"
    case bookmarkStatus = "Bookmarked"
    
    var systemImage: String {
        switch self {
        case .title:
            return "textformat.abc"
        case .dateCreated:
            return "calendar.badge.plus"
        case .dateModified:
            return "calendar.badge.clock"
        case .category:
            return "tag"
        case .bookmarkStatus:
            return "bookmark"
        }
    }
}