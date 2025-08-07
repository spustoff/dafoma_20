import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var readingPreferences = ReadingPreferences()
    
    let onboardingPages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "3e4464"), Color(hex: "2a2f4a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(onboardingPages.indices, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingPages[index],
                            readingPreferences: $readingPreferences
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Custom page indicator and navigation
                VStack(spacing: 24) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(onboardingPages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color(hex: "fcc418") : Color.white.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(response: 0.5), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .buttonStyle(OnboardingSecondaryButtonStyle())
                        }
                        
                        Spacer()
                        
                        if currentPage < onboardingPages.count - 1 {
                            Button("Next") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                            .buttonStyle(OnboardingPrimaryButtonStyle())
                        } else {
                            Button("Get Started") {
                                completeOnboarding()
                            }
                            .buttonStyle(OnboardingPrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding screen \(currentPage + 1) of \(onboardingPages.count)")
    }
    
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
        
        // Save reading preferences
        UserDefaults.standard.set(readingPreferences.fontSize, forKey: "defaultFontSize")
        UserDefaults.standard.set(readingPreferences.fontFamily.rawValue, forKey: "defaultFontFamily")
        UserDefaults.standard.set(readingPreferences.backgroundColor.rawValue, forKey: "defaultBackgroundColor")
        UserDefaults.standard.set(readingPreferences.textColor.rawValue, forKey: "defaultTextColor")
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var readingPreferences: ReadingPreferences
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "fcc418").opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: page.iconName)
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(Color(hex: "fcc418"))
                }
                .accessibilityHidden(true)
                
                // Title
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityHeading(.h1)
                
                // Description
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                
                // Interactive content for specific pages
                if page.type == .preferences {
                    ReadingPreferencesSetup(preferences: $readingPreferences)
                } else if page.type == .features {
                    FeatureHighlights()
                }
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct ReadingPreferencesSetup: View {
    @Binding var preferences: ReadingPreferences
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Customize Your Reading Experience")
                .font(.headline)
                .foregroundColor(.white)
                .accessibilityHeading(.h2)
            
            VStack(spacing: 16) {
                // Font Size
                PreferenceCard(
                    title: "Font Size",
                    icon: "textformat.size"
                ) {
                    HStack {
                        Text("A")
                            .font(.caption)
                        Slider(value: $preferences.fontSize, in: 12...24, step: 1)
                            .accentColor(Color(hex: "fcc418"))
                        Text("A")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                }
                
                // Font Family
                PreferenceCard(
                    title: "Font Style",
                    icon: "textformat"
                ) {
                    Picker("Font Family", selection: $preferences.fontFamily) {
                        ForEach(FontFamily.allCases, id: \.self) { font in
                            Text(font.displayName)
                                .tag(font)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Background Color
                PreferenceCard(
                    title: "Background",
                    icon: "paintbrush"
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(BackgroundColor.allCases, id: \.self) { bgColor in
                            Circle()
                                .fill(bgColor.color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "fcc418"), lineWidth: preferences.backgroundColor == bgColor ? 2 : 0)
                                )
                                .onTapGesture {
                                    preferences.backgroundColor = bgColor
                                }
                                .accessibilityLabel(bgColor.rawValue)
                                .accessibilityAddTraits(preferences.backgroundColor == bgColor ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

struct PreferenceCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "fcc418"))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .accessibilityElement(children: .combine)
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct FeatureHighlights: View {
    let features = [
        ("Personal Library", "books.vertical", "Organize your digital library with custom categories and tags"),
        ("Smart Notes", "note.text", "Take notes while reading with seamless synchronization"),
        ("AI Recommendations", "brain.head.profile", "Discover your next favorite book with intelligent suggestions")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(features, id: \.0) { feature in
                HStack(spacing: 16) {
                    Image(systemName: feature.1)
                        .font(.title2)
                        .foregroundColor(Color(hex: "fcc418"))
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.0)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(feature.2)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(feature.0): \(feature.2)")
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Button Styles

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "fcc418"))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Supporting Types

struct ReadingPreferences {
    var fontSize: CGFloat = 16
    var fontFamily: FontFamily = .system
    var backgroundColor: BackgroundColor = .dark
    var textColor: TextColor = .primary
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let type: OnboardingPageType
    
    static let allPages = [
        OnboardingPage(
            title: "Welcome to Biblioscribe Road",
            description: "Your premium digital library companion designed for avid readers and literature enthusiasts. Experience reading like never before.",
            iconName: "book.closed",
            type: .welcome
        ),
        OnboardingPage(
            title: "Powerful Features",
            description: "Discover integrated note-taking, smart recommendations, and personalized reading spaces all in one elegant app.",
            iconName: "sparkles",
            type: .features
        ),
        OnboardingPage(
            title: "Personalize Your Experience",
            description: "Customize your reading preferences to create the perfect environment for every book you read.",
            iconName: "slider.horizontal.3",
            type: .preferences
        ),
        OnboardingPage(
            title: "Ready to Begin",
            description: "You're all set to start your literary journey. Let's explore the world of books together!",
            iconName: "checkmark.circle",
            type: .completion
        )
    ]
}

enum OnboardingPageType {
    case welcome
    case features
    case preferences
    case completion
}

#Preview {
    OnboardingView()
}
