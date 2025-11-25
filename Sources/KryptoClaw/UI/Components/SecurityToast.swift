import SwiftUI

public struct SecurityToast: View {
    @EnvironmentObject var themeManager: ThemeManager
    let message: String
    let isWarning: Bool

    public init(message: String, isWarning: Bool = true) {
        self.message = message
        self.isWarning = isWarning
    }

    public var body: some View {
        let theme = themeManager.currentTheme

        HStack {
            Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isWarning ? theme.securityWarningColor : theme.successColor)
            Text(message)
                .font(theme.captionFont)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(isWarning ? theme.securityWarningColor : theme.successColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: theme.shadowRadius, x: 0, y: theme.shadowY)
        .padding(.horizontal)
    }
}
