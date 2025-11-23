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
                .font(theme.font(style: .caption))
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
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}
