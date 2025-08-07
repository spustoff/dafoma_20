import SwiftUI

struct RecommendationListView: View {
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    @State private var showingFilters = false
    @State private var selectedRecommendation: Recommendation?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    RecommendationHeaderView()
                    
                    // Search and filters
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText, placeholder: "Search recommendations...")
                            .onChange(of: searchText) { newValue in
                                recommendationViewModel.searchText = newValue
                            }
                        
                        FilterButtonsRow(showingFilters: $showingFilters)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Recommendations content
                    if recommendationViewModel.isGenerating {
                        GeneratingView()
                    } else if recommendationViewModel.filteredRecommendations.isEmpty {
                        EmptyRecommendationsView()
                    } else {
                        RecommendationsList(selectedRecommendation: $selectedRecommendation)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        recommendationViewModel.generateNewRecommendations()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "fcc418"))
                    }
                    .disabled(recommendationViewModel.isGenerating)
                }
            }
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            RecommendationDetailView(recommendation: recommendation)
        }
        .sheet(isPresented: $showingFilters) {
            RecommendationFiltersView()
        }
    }
}

struct RecommendationHeaderView: View {
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Featured recommendation
            if let featured = recommendationViewModel.featuredRecommendation {
                FeaturedRecommendationCard(recommendation: featured)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatPill(
                    title: "Total",
                    value: "\(recommendationViewModel.totalRecommendationsCount)",
                    color: Color(hex: "fcc418")
                )
                
                StatPill(
                    title: "Unread",
                    value: "\(recommendationViewModel.totalRecommendationsCount - recommendationViewModel.readRecommendationsCount)",
                    color: Color(hex: "3cc45b")
                )
                
                StatPill(
                    title: "In Library",
                    value: "\(recommendationViewModel.inLibraryCount)",
                    color: .blue
                )
            }
        }
        .padding()
    }
}

struct FeaturedRecommendationCard: View {
    let recommendation: Recommendation
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Recommendation")
                    .font(.headline)
                    .foregroundColor(Color(hex: "fcc418"))
                
                Spacer()
                
                ConfidenceBadge(level: recommendation.confidenceLevel)
            }
            
            HStack(spacing: 16) {
                // Book cover placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color(hex: "fcc418").opacity(0.3), Color(hex: "3cc45b").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.white.opacity(0.7))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("by \(recommendation.author)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Text(recommendation.genre)
                        .font(.caption)
                        .foregroundColor(Color(hex: "fcc418"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(hex: "fcc418").opacity(0.2))
                        )
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            HStack {
                Button("Add to Library") {
                    recommendationViewModel.addToLibrary(recommendation)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Learn More") {
                    // Show detail view
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "fcc418").opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Featured recommendation: \(recommendation.title) by \(recommendation.author)")
    }
}

struct FilterButtonsRow: View {
    @Binding var showingFilters: Bool
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") {
                    recommendationViewModel.clearFilters()
                }
                .buttonStyle(FilterChipStyle(isSelected: recommendationViewModel.selectedType == nil))
                
                ForEach(recommendationViewModel.availableTypes, id: \.self) { type in
                    Button(type.rawValue) {
                        recommendationViewModel.selectedType = type
                    }
                    .buttonStyle(FilterChipStyle(isSelected: recommendationViewModel.selectedType == type))
                }
                
                Button("Filters") {
                    showingFilters = true
                }
                .buttonStyle(FilterChipStyle(isSelected: false, isFilterButton: true))
            }
            .padding(.horizontal)
        }
    }
}

struct RecommendationsList: View {
    @Binding var selectedRecommendation: Recommendation?
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(recommendationViewModel.filteredRecommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                        .onTapGesture {
                            selectedRecommendation = recommendation
                        }
                }
            }
            .padding()
        }
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Book cover
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color(hex: "fcc418").opacity(0.3), Color(hex: "3cc45b").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 70)
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and author
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("by \(recommendation.author)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    // Genre and type
                    HStack {
                        Text(recommendation.genre)
                            .font(.caption)
                            .foregroundColor(Color(hex: "fcc418"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "fcc418").opacity(0.2))
                            )
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: recommendation.recommendationType.icon)
                                .foregroundColor(recommendation.recommendationType.color)
                                .font(.caption2)
                            
                            Text(recommendation.recommendationType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Reason
                    Text(recommendation.reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                VStack(spacing: 8) {
                    ConfidenceBadge(level: recommendation.confidenceLevel)
                    
                    if recommendation.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "3cc45b"))
                            .font(.caption)
                    }
                    
                    if recommendation.isInLibrary {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(Color(hex: "fcc418"))
                            .font(.caption)
                    }
                }
            }
            .padding(16)
            
            // Action buttons
            HStack(spacing: 8) {
                if !recommendation.isInLibrary {
                    Button("Add to Library") {
                        recommendationViewModel.addToLibrary(recommendation)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                if !recommendation.isRead {
                    Button("Mark as Read") {
                        recommendationViewModel.markAsRead(recommendation)
                    }
                    .buttonStyle(TertiaryButtonStyle())
                }
                
                Button("Details") {
                    // Show details
                }
                .buttonStyle(TertiaryButtonStyle())
                
                Spacer()
                
                Menu {
                    Button("Rate") {
                        // Show rating
                    }
                    
                    Button("Share") {
                        // Share recommendation
                    }
                    
                    Button(role: .destructive) {
                        recommendationViewModel.deleteRecommendation(recommendation)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .contextMenu {
            Button("Add to Library") {
                recommendationViewModel.addToLibrary(recommendation)
            }
            
            Button("Mark as Read") {
                recommendationViewModel.markAsRead(recommendation)
            }
            
            Button("Share") {
                // Share functionality
            }
            
            Button(role: .destructive) {
                recommendationViewModel.deleteRecommendation(recommendation)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recommendation: \(recommendation.title) by \(recommendation.author). \(recommendation.reason)")
    }
}

struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)
            
            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(level.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(level.color.opacity(0.2))
        )
        .accessibilityLabel("Confidence level: \(level.rawValue)")
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct GeneratingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "fcc418")))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Generating Recommendations")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Analyzing your reading preferences and creating personalized suggestions...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyRecommendationsView: View {
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "fcc418").opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Recommendations")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Start reading and taking notes to get personalized book recommendations")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button("Generate Recommendations") {
                recommendationViewModel.generateNewRecommendations()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Button Styles

struct FilterChipStyle: ButtonStyle {
    let isSelected: Bool
    let isFilterButton: Bool
    
    init(isSelected: Bool, isFilterButton: Bool = false) {
        self.isSelected = isSelected
        self.isFilterButton = isFilterButton
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "fcc418") : Color.white.opacity(0.2))
            )
            .overlay(
                Group {
                    if isFilterButton {
                        Capsule()
                            .stroke(Color(hex: "fcc418").opacity(0.5), lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "fcc418"))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2)
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Supporting Views

struct RecommendationFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Type filter
                        FilterSection(title: "Recommendation Type") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(RecommendationType.allCases, id: \.self) { type in
                                    FilterOptionCard(
                                        title: type.rawValue,
                                        icon: type.icon,
                                        isSelected: recommendationViewModel.selectedType == type,
                                        onTap: {
                                            recommendationViewModel.selectedType = type
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Confidence filter
                        FilterSection(title: "Confidence Level") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ConfidenceLevel.allCases, id: \.self) { level in
                                    FilterOptionCard(
                                        title: level.rawValue,
                                        icon: level.icon,
                                        isSelected: recommendationViewModel.selectedConfidenceLevel == level,
                                        onTap: {
                                            recommendationViewModel.selectedConfidenceLevel = level
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Status filters
                        FilterSection(title: "Status") {
                            VStack(spacing: 12) {
                                FilterToggle(
                                    title: "Show read only",
                                    isOn: recommendationViewModel.showReadOnly,
                                    onToggle: { recommendationViewModel.showReadOnly.toggle() }
                                )
                                
                                FilterToggle(
                                    title: "Show unread only",
                                    isOn: recommendationViewModel.showUnreadOnly,
                                    onToggle: { recommendationViewModel.showUnreadOnly.toggle() }
                                )
                                
                                FilterToggle(
                                    title: "Show in library only",
                                    isOn: recommendationViewModel.showInLibraryOnly,
                                    onToggle: { recommendationViewModel.showInLibraryOnly.toggle() }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        recommendationViewModel.clearFilters()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "fcc418"))
                }
            }
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
    }
}

struct FilterOptionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? Color(hex: "fcc418") : .white.opacity(0.6))
                .font(.title3)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color(hex: "fcc418") : .white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "fcc418").opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(hex: "fcc418") : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FilterToggle: View {
    let title: String
    let isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "fcc418")))
                .onTapGesture(perform: onToggle)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Book details
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "fcc418").opacity(0.4), Color(hex: "3cc45b").opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 160)
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 30))
                                )
                            
                            VStack(spacing: 8) {
                                Text(recommendation.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("by \(recommendation.author)")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(recommendation.genre)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "fcc418"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "fcc418").opacity(0.2))
                                    )
                            }
                        }
                        
                        // Details cards
                        VStack(spacing: 16) {
                            DetailCard(title: "Why This Book?", content: recommendation.reason)
                            DetailCard(title: "Synopsis", content: recommendation.synopsis)
                            
                            HStack(spacing: 16) {
                                VStack {
                                    Text("\(recommendation.confidencePercentage)%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(recommendation.confidenceLevel.color)
                                    Text("Confidence")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                                
                                VStack {
                                    Image(systemName: recommendation.recommendationType.icon)
                                        .font(.title2)
                                        .foregroundColor(recommendation.recommendationType.color)
                                    Text(recommendation.recommendationType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            if !recommendation.isInLibrary {
                                Button("Add to Library") {
                                    recommendationViewModel.addToLibrary(recommendation)
                                    dismiss()
                                }
                                .buttonStyle(OnboardingPrimaryButtonStyle())
                            }
                            
                            HStack(spacing: 12) {
                                if !recommendation.isRead {
                                    Button("Mark as Read") {
                                        recommendationViewModel.markAsRead(recommendation)
                                    }
                                    .buttonStyle(OnboardingSecondaryButtonStyle())
                                }
                                
                                Button("Share") {
                                    // Share functionality
                                }
                                .buttonStyle(OnboardingSecondaryButtonStyle())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    RecommendationListView()
        .environmentObject(RecommendationViewModel(
            recommendationService: RecommendationService(
                bookService: BookService(),
                noteService: NoteService()
            )
        ))
}
