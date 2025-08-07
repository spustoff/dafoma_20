import Foundation
import SwiftUI

class NoteService: ObservableObject {
    @Published var notes: [Note] = []
    private let userDefaults = UserDefaults.standard
    private let notesKey = "SavedNotes"
    
    init() {
        loadNotes()
    }
    
    // MARK: - Note Management
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func createNote(title: String, content: String, bookId: UUID, pageReference: Int? = nil, category: NoteCategory = .general, color: NoteColor = .yellow) -> Note {
        let note = Note(title: title, content: content, bookId: bookId, pageReference: pageReference)
        var newNote = note
        newNote.category = category
        newNote.color = color
        
        addNote(newNote)
        return newNote
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.dateModified = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }
    
    func getNote(by id: UUID) -> Note? {
        return notes.first { $0.id == id }
    }
    
    // MARK: - Note Organization
    
    func toggleBookmark(for noteId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isBookmarked.toggle()
            notes[index].dateModified = Date()
            saveNotes()
        }
    }
    
    func updateNoteCategory(noteId: UUID, category: NoteCategory) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].category = category
            notes[index].dateModified = Date()
            saveNotes()
        }
    }
    
    func updateNoteColor(noteId: UUID, color: NoteColor) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].color = color
            notes[index].dateModified = Date()
            saveNotes()
        }
    }
    
    // MARK: - Tag Management
    
    func addTag(to noteId: UUID, tag: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].addTag(tag)
            saveNotes()
        }
    }
    
    func removeTag(from noteId: UUID, tag: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].removeTag(tag)
            saveNotes()
        }
    }
    
    func getAllTags() -> [String] {
        let allTags = notes.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    func getPopularTags(limit: Int = 10) -> [String] {
        let tagCounts = Dictionary(grouping: notes.flatMap { $0.tags }, by: { $0 })
            .mapValues { $0.count }
        
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    // MARK: - Filtering and Searching
    
    func getNotes(for bookId: UUID) -> [Note] {
        return notes.filter { $0.bookId == bookId }
            .sorted { $0.dateModified > $1.dateModified }
    }
    
    func getBookmarkedNotes() -> [Note] {
        return notes.filter { $0.isBookmarked }
            .sorted { $0.dateModified > $1.dateModified }
    }
    
    func getNotes(by category: NoteCategory) -> [Note] {
        return notes.filter { $0.category == category }
            .sorted { $0.dateModified > $1.dateModified }
    }
    
    func getNotes(with tag: String) -> [Note] {
        return notes.filter { $0.tags.contains(tag) }
            .sorted { $0.dateModified > $1.dateModified }
    }
    
    func searchNotes(_ query: String) -> [Note] {
        guard !query.isEmpty else { return getAllNotesSorted() }
        
        return notes.filter { note in
            note.title.lowercased().contains(query.lowercased()) ||
            note.content.lowercased().contains(query.lowercased()) ||
            note.tags.contains { $0.lowercased().contains(query.lowercased()) }
        }.sorted { $0.dateModified > $1.dateModified }
    }
    
    func getAllNotesSorted() -> [Note] {
        return notes.sorted { $0.dateModified > $1.dateModified }
    }
    
    func getRecentNotes(limit: Int = 10) -> [Note] {
        return getAllNotesSorted().prefix(limit).map { $0 }
    }
    
    // MARK: - Analytics
    
    var totalNotesCount: Int {
        notes.count
    }
    
    var bookmarkedNotesCount: Int {
        notes.filter { $0.isBookmarked }.count
    }
    
    func getNotesCount(for bookId: UUID) -> Int {
        notes.filter { $0.bookId == bookId }.count
    }
    
    func getCategoryDistribution() -> [NoteCategory: Int] {
        return Dictionary(grouping: notes, by: { $0.category })
            .mapValues { $0.count }
    }
    
    func getNotesCreatedInLast(days: Int) -> [Note] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return notes.filter { $0.dateCreated >= cutoffDate }
            .sorted { $0.dateCreated > $1.dateCreated }
    }
    
    func getAverageNotesPerBook() -> Double {
        let uniqueBookIds = Set(notes.map { $0.bookId })
        guard !uniqueBookIds.isEmpty else { return 0.0 }
        
        return Double(notes.count) / Double(uniqueBookIds.count)
    }
    
    // MARK: - Export and Sharing
    
    func exportNote(_ note: Note) -> String {
        var exportText = """
        # \(note.title)
        
        **Category:** \(note.category.rawValue)
        **Created:** \(note.formattedDate)
        """
        
        if let pageRef = note.pageReference {
            exportText += "\n**Page Reference:** \(pageRef)"
        }
        
        if !note.tags.isEmpty {
            exportText += "\n**Tags:** \(note.tags.joined(separator: ", "))"
        }
        
        exportText += """
        
        ---
        
        \(note.content)
        """
        
        return exportText
    }
    
    func exportAllNotes(for bookId: UUID) -> String {
        let bookNotes = getNotes(for: bookId)
        guard !bookNotes.isEmpty else { return "No notes found for this book." }
        
        var exportText = "# All Notes\n\n"
        
        for note in bookNotes {
            exportText += exportNote(note) + "\n\n---\n\n"
        }
        
        return exportText
    }
    
    // MARK: - Persistence
    
    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            userDefaults.set(data, forKey: notesKey)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
    
    private func loadNotes() {
        guard let data = userDefaults.data(forKey: notesKey) else { return }
        
        do {
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("Failed to load notes: \(error)")
        }
    }
    
    // MARK: - Bulk Operations
    
    func deleteAllNotes(for bookId: UUID) {
        notes.removeAll { $0.bookId == bookId }
        saveNotes()
    }
    
    func bulkUpdateCategory(noteIds: [UUID], category: NoteCategory) {
        for noteId in noteIds {
            updateNoteCategory(noteId: noteId, category: category)
        }
    }
    
    func bulkUpdateColor(noteIds: [UUID], color: NoteColor) {
        for noteId in noteIds {
            updateNoteColor(noteId: noteId, color: color)
        }
    }
    
    func duplicateNote(_ note: Note) -> Note {
        var duplicatedNote = note
        duplicatedNote = Note(
            title: "\(note.title) (Copy)",
            content: note.content,
            bookId: note.bookId,
            pageReference: note.pageReference
        )
        duplicatedNote.category = note.category
        duplicatedNote.color = note.color
        duplicatedNote.tags = note.tags
        
        addNote(duplicatedNote)
        return duplicatedNote
    }
}