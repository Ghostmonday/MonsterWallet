import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Shapes & Patterns

/// A diamond pattern shape for "Elite" themes.
public struct DiamondPattern: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let size: CGFloat = 20 // Size of each diamond
        let rows = Int(rect.height / size) + 1
        let cols = Int(rect.width / size) + 1

        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * size
                let y = CGFloat(r) * size
                let offset = (r % 2 == 0) ? 0 : size / 2

                let centerX = x + offset
                let centerY = y

                path.move(to: CGPoint(x: centerX, y: centerY - size/4))
                path.addLine(to: CGPoint(x: centerX + size/4, y: centerY))
                path.addLine(to: CGPoint(x: centerX, y: centerY + size/4))
                path.addLine(to: CGPoint(x: centerX - size/4, y: centerY))
                path.closeSubpath()
            }
        }
        return path
    }
}

public struct KryptoButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isPrimary: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false
    
    public var body: some View {
        Button(action: {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(themeManager.currentTheme.font(style: .headline))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isPrimary ? themeManager.currentTheme.accentColor : Color.clear)
            .foregroundColor(isPrimary ? .white : themeManager.currentTheme.textPrimary)
            .cornerRadius(2) // Razor-edged
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: isPrimary ? 0 : 2)
            )
            .shadow(color: isHovering ? themeManager.currentTheme.accentColor.opacity(0.8) : .clear, radius: 10, x: 0, y: 0) // Glow on hover
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .buttonStyle(SquishButtonStyle())
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Subtle press
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct KryptoCard<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            if themeManager.currentTheme.glassEffectOpacity < 1.0 {
                // Glassmorphism
                if #available(iOS 15.0, *) {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .opacity(themeManager.currentTheme.glassEffectOpacity)
                } else {
                    themeManager.currentTheme.cardBackground
                        .opacity(themeManager.currentTheme.glassEffectOpacity)
                }
            } else {
                themeManager.currentTheme.cardBackground
            }

            if themeManager.currentTheme.hasDiamondTexture {
                DiamondPattern()
                    .fill(Color.white.opacity(0.03))
                    .clipped()
            }

            content
                .padding(20)
        }
        .background(themeManager.currentTheme.glassEffectOpacity == 1.0 ? themeManager.currentTheme.cardBackground : Color.clear)
        .cornerRadius(themeManager.currentTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }
}

struct KryptoTextField: View {
    let placeholder: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(themeManager.currentTheme.backgroundSecondary)
            .cornerRadius(themeManager.currentTheme.cornerRadius)
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius)
                    .stroke(themeManager.currentTheme.borderColor.opacity(0.5), lineWidth: 1)
            )
            .font(themeManager.currentTheme.addressFont)
    }
}

// MARK: - List Row
public struct KryptoListRow: View {
    let title: String
    let subtitle: String?
    let value: String?
    let icon: String? // SF Symbol name or URL placeholder
    let isSystemIcon: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(title: String, subtitle: String? = nil, value: String? = nil, icon: String? = nil, isSystemIcon: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.isSystemIcon = isSystemIcon
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let iconName = icon {
                Group {
                    if isSystemIcon {
                        Image(systemName: iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Network image placeholder
                        AsyncImage(url: URL(string: iconName)) { phase in
                            if let image = phase.image {
                                image.resizable()
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                    }
                }
                .frame(width: 32, height: 32)
                .cornerRadius(4)
                .foregroundColor(themeManager.currentTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeManager.currentTheme.font(style: .body))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .lineLimit(1)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let val = value {
                Text(val)
                    .font(themeManager.currentTheme.font(style: .body))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle ?? ""), \(value ?? "")")
    }
}

// MARK: - Header
public struct KryptoHeader: View {
    let title: String
    let onBack: (() -> Void)?
    let actionIcon: String?
    let onAction: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(title: String, onBack: (() -> Void)? = nil, actionIcon: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.onBack = onBack
        self.actionIcon = actionIcon
        self.onAction = onAction
    }
    
    public var body: some View {
        HStack {
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .accessibilityLabel("Go Back")
            } else {
                Spacer().frame(width: 24) // Balance spacing if no back button but action exists
            }
            
            Spacer()
            
            Text(title)
                .font(themeManager.currentTheme.font(style: .headline))
                .foregroundColor(themeManager.currentTheme.textPrimary)
            
            Spacer()
            
            if let icon = actionIcon, let onAction = onAction {
                Button(action: onAction) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .accessibilityLabel("Action")
            } else {
                Spacer().frame(width: 24)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundMain)
    }
}

// MARK: - Tab Segment
public struct KryptoTab: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(tabs: [String], selectedIndex: Binding<Int>) {
        self.tabs = tabs
        self._selectedIndex = selectedIndex
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(themeManager.currentTheme.font(style: .subheadline))
                            .foregroundColor(selectedIndex == index ? themeManager.currentTheme.accentColor : themeManager.currentTheme.textSecondary)
                        
                        Rectangle()
                            .fill(selectedIndex == index ? themeManager.currentTheme.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(tabs[index])
                .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
            }
        }
        .padding(.horizontal)
    }
}
