import SwiftUI

public enum SecurityLevel {
    case standard
    case secureEnclave
    case hardwareKey
}

public struct SecurityBadge: View {
    let level: SecurityLevel
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(level: SecurityLevel) {
        self.level = level
    }
    
    var title: String {
        switch level {
        case .standard: return "Standard Encryption"
        case .secureEnclave: return "Secure Enclave"
        case .hardwareKey: return "Hardware Key Protected"
        }
    }
    
    var icon: String {
        switch level {
        case .standard: return "lock.fill"
        case .secureEnclave: return "checkmark.shield.fill"
        case .hardwareKey: return "key.fill"
        }
    }
    
    var color: Color {
        switch level {
        case .standard: return themeManager.currentTheme.textSecondary
        case .secureEnclave: return themeManager.currentTheme.secureEnclaveColor
        case .hardwareKey: return themeManager.currentTheme.accentColor
        }
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .stroke(color.opacity(0.5), lineWidth: 1)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Security Level: \(title)")
        .accessibilityHint("Indicates the level of protection for this wallet.")
    }
}
