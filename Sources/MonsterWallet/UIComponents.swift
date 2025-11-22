import SwiftUI

struct MonsterButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isPrimary: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? themeManager.currentTheme.accentColor : themeManager.currentTheme.backgroundSecondary)
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .cornerRadius(12)
        }
    }
}

struct MonsterCard<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(themeManager.currentTheme.backgroundSecondary)
            .cornerRadius(16)
    }
}

struct MonsterTextField: View {
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
