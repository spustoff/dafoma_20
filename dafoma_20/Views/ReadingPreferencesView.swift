import SwiftUI

struct ReadingPreferencesView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookViewModel: BookViewModel
    
    @State private var fontSize: CGFloat
    @State private var fontFamily: FontFamily
    @State private var backgroundColor: BackgroundColor
    @State private var textColor: TextColor
    @State private var brightness: Double = 0.5
    @State private var autoScroll: Bool = false
    @State private var scrollSpeed: Double = 1.0
    @State private var lineSpacing: Double = 1.2
    @State private var paragraphSpacing: Double = 8.0
    @State private var margins: Double = 24.0
    
    init(book: Book) {
        self.book = book
        self._fontSize = State(initialValue: book.fontSize)
        self._fontFamily = State(initialValue: book.fontFamily)
        self._backgroundColor = State(initialValue: book.backgroundColor)
        self._textColor = State(initialValue: book.textColor)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.color.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preview Section
                        ReadingPreviewCard(
                            fontSize: fontSize,
                            fontFamily: fontFamily,
                            backgroundColor: backgroundColor,
                            textColor: textColor,
                            lineSpacing: lineSpacing,
                            paragraphSpacing: paragraphSpacing,
                            margins: margins
                        )
                        
                        // Font Settings
                        FontSettingsSection(
                            fontSize: $fontSize,
                            fontFamily: $fontFamily
                        )
                        
                        // Appearance Settings
                        AppearanceSettingsSection(
                            backgroundColor: $backgroundColor,
                            textColor: $textColor,
                            brightness: $brightness
                        )
                        
                        // Reading Settings
                        ReadingSettingsSection(
                            lineSpacing: $lineSpacing,
                            paragraphSpacing: $paragraphSpacing,
                            margins: $margins,
                            autoScroll: $autoScroll,
                            scrollSpeed: $scrollSpeed
                        )
                        
                        // Preset Themes
                        PresetThemesSection(
                            fontSize: $fontSize,
                            fontFamily: $fontFamily,
                            backgroundColor: $backgroundColor,
                            textColor: $textColor
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(backgroundColor == .dark || backgroundColor == .night ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(textColor.color)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "fcc418"))
                }
            }
        }
    }
    
    private func savePreferences() {
        bookViewModel.updateReadingPreferences(
            fontSize: fontSize,
            fontFamily: fontFamily,
            backgroundColor: backgroundColor,
            textColor: textColor
        )
    }
}

struct ReadingPreviewCard: View {
    let fontSize: CGFloat
    let fontFamily: FontFamily
    let backgroundColor: BackgroundColor
    let textColor: TextColor
    let lineSpacing: Double
    let paragraphSpacing: Double
    let margins: Double
    
    private let sampleText = """
    Chapter 1: The Beginning
    
    In the heart of every great story lies a moment of infinite possibility. The characters stand at the threshold of their journey, unaware of the adventures that await them. Each page turns like a season, bringing new revelations and deeper understanding.
    
    The art of storytelling has captivated humanity for millennia. From ancient oral traditions to modern digital narratives, we have always sought to make sense of our world through the power of story.
    """
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(textColor.color)
                .accessibilityHeading(.h2)
            
            ScrollView {
                Text(sampleText)
                    .font(fontFamily.font.size(fontSize))
                    .foregroundColor(textColor.color)
                    .lineSpacing(CGFloat(lineSpacing) * 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CGFloat(margins))
                    .padding(.vertical, CGFloat(paragraphSpacing))
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(textColor.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reading preview with current settings")
    }
}

struct FontSettingsSection: View {
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: FontFamily
    
    var body: some View {
        SettingsCard(title: "Font", icon: "textformat") {
            VStack(spacing: 16) {
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(fontSize))pt")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack {
                        Text("A")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Slider(value: $fontSize, in: 12...28, step: 1)
                            .accentColor(Color(hex: "fcc418"))
                        
                        Text("A")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Font Family
                VStack(alignment: .leading, spacing: 8) {
                    Text("Family")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Picker("Font Family", selection: $fontFamily) {
                        ForEach(FontFamily.allCases, id: \.self) { family in
                            Text(family.displayName)
                                .tag(family)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

struct AppearanceSettingsSection: View {
    @Binding var backgroundColor: BackgroundColor
    @Binding var textColor: TextColor
    @Binding var brightness: Double
    
    var body: some View {
        SettingsCard(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 20) {
                // Background Color
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(BackgroundColor.allCases, id: \.self) { bgColor in
                            ColorOption(
                                color: bgColor.color,
                                title: bgColor.rawValue,
                                isSelected: backgroundColor == bgColor,
                                onTap: { backgroundColor = bgColor }
                            )
                        }
                    }
                }
                
                // Text Color
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Color")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(TextColor.allCases, id: \.self) { txtColor in
                            ColorOption(
                                color: txtColor.color,
                                title: txtColor.rawValue,
                                isSelected: textColor == txtColor,
                                onTap: { textColor = txtColor }
                            )
                        }
                    }
                }
                
                // Brightness
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Brightness")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(brightness * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack {
                        Image(systemName: "sun.min")
                            .foregroundColor(.white.opacity(0.7))
                        
                        Slider(value: $brightness, in: 0.1...1.0)
                            .accentColor(Color(hex: "fcc418"))
                        
                        Image(systemName: "sun.max")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

struct ReadingSettingsSection: View {
    @Binding var lineSpacing: Double
    @Binding var paragraphSpacing: Double
    @Binding var margins: Double
    @Binding var autoScroll: Bool
    @Binding var scrollSpeed: Double
    
    var body: some View {
        SettingsCard(title: "Reading", icon: "doc.text") {
            VStack(spacing: 16) {
                // Line Spacing
                SliderSetting(
                    title: "Line Spacing",
                    value: $lineSpacing,
                    range: 1.0...2.0,
                    step: 0.1,
                    formatter: { String(format: "%.1f", $0) }
                )
                
                // Paragraph Spacing
                SliderSetting(
                    title: "Paragraph Spacing",
                    value: $paragraphSpacing,
                    range: 4.0...20.0,
                    step: 2.0,
                    formatter: { "\(Int($0))pt" }
                )
                
                // Margins
                SliderSetting(
                    title: "Margins",
                    value: $margins,
                    range: 16.0...40.0,
                    step: 4.0,
                    formatter: { "\(Int($0))pt" }
                )
                
                // Auto Scroll
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Scroll")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("Automatically scroll while reading")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("Auto Scroll", isOn: $autoScroll)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "fcc418")))
                }
                
                // Scroll Speed (only if auto scroll is enabled)
                if autoScroll {
                    SliderSetting(
                        title: "Scroll Speed",
                        value: $scrollSpeed,
                        range: 0.5...3.0,
                        step: 0.1,
                        formatter: { String(format: "%.1fx", $0) }
                    )
                }
            }
        }
    }
}

struct PresetThemesSection: View {
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: FontFamily
    @Binding var backgroundColor: BackgroundColor
    @Binding var textColor: TextColor
    
    private let presets: [PresetTheme] = [
        PresetTheme(
            name: "Classic",
            icon: "book.closed",
            fontSize: 16,
            fontFamily: .serif,
            backgroundColor: .light,
            textColor: .black
        ),
        PresetTheme(
            name: "Dark",
            icon: "moon",
            fontSize: 16,
            fontFamily: .system,
            backgroundColor: .dark,
            textColor: .white
        ),
        PresetTheme(
            name: "Sepia",
            icon: "sun.dust",
            fontSize: 17,
            fontFamily: .georgia,
            backgroundColor: .sepia,
            textColor: .sepia
        ),
        PresetTheme(
            name: "Night",
            icon: "moon.stars",
            fontSize: 18,
            fontFamily: .system,
            backgroundColor: .night,
            textColor: .white
        )
    ]
    
    var body: some View {
        SettingsCard(title: "Preset Themes", icon: "paintpalette") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(presets, id: \.name) { preset in
                    PresetThemeCard(
                        preset: preset,
                        isSelected: isCurrentPreset(preset),
                        onSelect: { applyPreset(preset) }
                    )
                }
            }
        }
    }
    
    private func isCurrentPreset(_ preset: PresetTheme) -> Bool {
        return fontSize == preset.fontSize &&
               fontFamily == preset.fontFamily &&
               backgroundColor == preset.backgroundColor &&
               textColor == preset.textColor
    }
    
    private func applyPreset(_ preset: PresetTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            fontSize = preset.fontSize
            fontFamily = preset.fontFamily
            backgroundColor = preset.backgroundColor
            textColor = preset.textColor
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "fcc418"))
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityHeading(.h2)
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ColorOption: View {
    let color: Color
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "fcc418"), lineWidth: isSelected ? 3 : 0)
                )
                .onTapGesture(perform: onTap)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAddTraits(.isButton)
    }
}

struct SliderSetting: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatter: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatter(value))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(Color(hex: "fcc418"))
        }
    }
}

struct PresetThemeCard: View {
    let preset: PresetTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Theme preview
            RoundedRectangle(cornerRadius: 8)
                .fill(preset.backgroundColor.color)
                .frame(height: 60)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: preset.icon)
                            .foregroundColor(preset.textColor.color)
                            .font(.title3)
                        
                        Text("Aa")
                            .font(preset.fontFamily.font.size(preset.fontSize))
                            .foregroundColor(preset.textColor.color)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "fcc418"), lineWidth: isSelected ? 2 : 0)
                )
            
            Text(preset.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.name) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAddTraits(.isButton)
    }
}

struct PresetTheme {
    let name: String
    let icon: String
    let fontSize: CGFloat
    let fontFamily: FontFamily
    let backgroundColor: BackgroundColor
    let textColor: TextColor
}

#Preview {
    ReadingPreferencesView(
        book: Book(
            title: "Sample Book",
            author: "Sample Author",
            genre: "Fiction",
            synopsis: "A sample book",
            content: "Sample content"
        )
    )
    .environmentObject(BookViewModel(bookService: BookService()))
}