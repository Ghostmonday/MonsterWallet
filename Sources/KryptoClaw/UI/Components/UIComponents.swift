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

// MARK: - KryptoButton

public struct KryptoButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isPrimary: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovering = false

    public init(title: String, icon: String, action: @escaping () -> Void, isPrimary: Bool) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isPrimary = isPrimary
    }

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
            .frame(height: themeManager.currentTheme.buttonHeight)
            .themedButton(theme: themeManager.currentTheme, isPrimary: isPrimary)
        }
    }
}

// MARK: - SquishButtonStyle

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - KryptoCard

public struct KryptoCard<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .themedCard(theme: themeManager.currentTheme)
    }
}

// MARK: - KryptoTextField

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

// MARK: - KryptoListRow

public struct KryptoListRow: View {
    let title: String
    let subtitle: String?
    let value: String?
    let icon: String?
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
        HStack(spacing: themeManager.currentTheme.spacingM) {
            if let iconName = icon {
                Group {
                    if isSystemIcon {
                        Image(systemName: iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        AsyncImage(url: URL(string: iconName)) { phase in
                            if let image = phase.image {
                                image.resizable()
                            } else {
                                themeManager.currentTheme.backgroundSecondary.opacity(0.5)
                            }
                        }
                    }
                }
                .frame(width: themeManager.currentTheme.avatarSizeSmall, height: themeManager.currentTheme.avatarSizeSmall)
                .cornerRadius(themeManager.currentTheme.cornerRadiusSmall)
                .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: themeManager.currentTheme.spacingXS) {
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
        .padding(.vertical, themeManager.currentTheme.spacingM)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle ?? ""), \(value ?? "")")
    }
}

// MARK: - KryptoHeader

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
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .accessibilityLabel("Go Back")
            } else {
                Spacer().frame(width: themeManager.currentTheme.spacingXL)
            }

            Spacer()

            Text(title)
                .font(themeManager.currentTheme.font(style: .headline))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            if let icon = actionIcon, let onAction {
                Button(action: onAction) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .accessibilityLabel("Action")
            } else {
                Spacer().frame(width: themeManager.currentTheme.spacingXL)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundMain)
    }
}

// MARK: - KryptoTab

public struct KryptoTab: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    @EnvironmentObject var themeManager: ThemeManager

    public init(tabs: [String], selectedIndex: Binding<Int>) {
        self.tabs = tabs
        _selectedIndex = selectedIndex
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< tabs.count, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    VStack(spacing: themeManager.currentTheme.spacingS) {
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

// MARK: - KryptoActionButton (Circular)

public struct KryptoActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    let isPrimary: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(icon: String, label: String, isPrimary: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.isPrimary = isPrimary
        self.action = action
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        Button(action: action) {
            VStack(spacing: theme.spacingS) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.cornerRadius * 2)
                        .fill(isPrimary ? theme.accentColor.opacity(0.1) : theme.backgroundSecondary)
                        .frame(width: theme.actionButtonSize, height: theme.actionButtonSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius * 2)
                                .stroke(isPrimary ? theme.accentColor.opacity(0.5) : theme.borderColor, lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isPrimary ? theme.accentColor : theme.textPrimary)
                }
                
                Text(label)
                    .font(theme.captionFont.bold())
                    .foregroundColor(theme.textPrimary)
            }
        }
        .accessibilityLabel(label)
    }
}

// MARK: - KryptoStatusBadge

public struct KryptoStatusBadge: View {
    public enum Status {
        case success
        case warning
        case error
        case info
        case neutral
    }
    
    let text: String
    let status: Status
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(_ text: String, status: Status = .neutral) {
        self.text = text
        self.status = status
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        let color = statusColor(theme: theme)
        
        Text(text)
            .font(theme.captionFont)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(theme.cornerRadiusSmall)
    }
    
    private func statusColor(theme: ThemeProtocolV2) -> Color {
        switch status {
        case .success: return theme.successColor
        case .warning: return theme.warningColor
        case .error: return theme.errorColor
        case .info: return theme.accentColor
        case .neutral: return theme.textSecondary
        }
    }
}

// MARK: - KryptoAssetIcon

public struct KryptoAssetIcon: View {
    let imageURL: URL?
    let fallbackText: String
    let size: IconSize
    
    public enum IconSize {
        case small, medium, large
    }
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(imageURL: URL?, fallbackText: String, size: IconSize = .medium) {
        self.imageURL = imageURL
        self.fallbackText = fallbackText
        self.size = size
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        let iconSize = iconSizeValue(theme: theme)
        
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.backgroundSecondary)
                    .frame(width: iconSize, height: iconSize)
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.borderColor, lineWidth: 0.5)
                    )
            case .failure:
                Circle()
                    .fill(theme.backgroundSecondary)
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Text(fallbackText.prefix(1))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                    )
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func iconSizeValue(theme: ThemeProtocolV2) -> CGFloat {
        switch size {
        case .small: return theme.avatarSizeSmall
        case .medium: return theme.avatarSizeMedium
        case .large: return theme.avatarSizeLarge
        }
    }
}

// MARK: - KryptoSectionHeader

public struct KryptoSectionHeader: View {
    let title: String
    let action: String?
    let onAction: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        HStack {
            Text(title)
                .font(theme.font(style: .title3))
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(theme.captionFont)
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - KryptoEmptyState

public struct KryptoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(spacing: theme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.textSecondary)
            
            VStack(spacing: theme.spacingS) {
                Text(title)
                    .font(theme.font(style: .headline))
                    .foregroundColor(theme.textPrimary)
                
                Text(message)
                    .font(theme.font(style: .body))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(theme.font(style: .headline))
                        .foregroundColor(theme.accentColor)
                }
            }
        }
        .padding(theme.spacing2XL)
    }
}

// MARK: - KryptoLoadingRow (Skeleton)

public struct KryptoLoadingRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        HStack {
            Circle()
                .fill(theme.textSecondary.opacity(0.2))
                .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
            
            VStack(alignment: .leading, spacing: theme.spacingS) {
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(width: 100, height: 16)
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(width: 60, height: 12)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: theme.spacingS) {
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(width: 50, height: 12)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - KryptoDivider

public struct KryptoDivider: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    public init() {}
    
    public var body: some View {
        Divider()
            .background(themeManager.currentTheme.borderColor)
    }
}

// MARK: - KryptoCloseButton

public struct KryptoCloseButton: View {
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(theme.textSecondary)
                .font(.system(size: 28))
        }
        .accessibilityLabel("Close")
    }
}

// MARK: - KryptoProgressButton

public struct KryptoProgressButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void
    let isPrimary: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(
        title: String,
        icon: String,
        isLoading: Bool,
        isPrimary: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isPrimary = isPrimary
        self.action = action
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        Button(action: {
            if !isLoading {
                #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                #endif
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isPrimary ? theme.backgroundMain : theme.accentColor))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                }
                Text(isLoading ? "Loading..." : title)
                    .font(theme.font(style: .headline))
            }
            .frame(maxWidth: .infinity)
            .frame(height: theme.buttonHeight)
            .themedButton(theme: theme, isPrimary: isPrimary)
        }
        .disabled(isLoading)
    }
}
