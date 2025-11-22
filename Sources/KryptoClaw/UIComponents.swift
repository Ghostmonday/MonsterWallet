import SwiftUI

public struct KryptoButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isPrimary: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isPrimary ? themeManager.currentTheme.accentColor : Color.clear)
            .foregroundColor(isPrimary ? .white : themeManager.currentTheme.textPrimary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 2)
            )
            .shadow(color: isPrimary ? themeManager.currentTheme.borderColor.opacity(0.2) : .clear, radius: 0, x: 4, y: 4)
        }
        .buttonStyle(SquishButtonStyle())
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(themeManager.currentTheme.borderColor.opacity(0.1), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct KryptoTextField: View {
    let placeholder: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeManager.currentTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}
