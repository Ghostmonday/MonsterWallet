import SwiftUI

#if os(iOS)
import UIKit
#endif

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
        content
            .padding(20)
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(2) // Razor-edged
            .overlay(
                RoundedRectangle(cornerRadius: 2)
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
            .cornerRadius(2)
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(themeManager.currentTheme.borderColor.opacity(0.5), lineWidth: 1)
            )
            .font(themeManager.currentTheme.addressFont) // Monospace for input usually looks good in this style, or use body
    }
}
