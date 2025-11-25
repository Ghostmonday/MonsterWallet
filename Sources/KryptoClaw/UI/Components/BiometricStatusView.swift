import SwiftUI
import LocalAuthentication

public struct BiometricStatusView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var biometryType: LABiometryType = .none
    @State private var isAvailable: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Biometric Security")
                    .font(themeManager.currentTheme.font(style: .headline))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Text(statusText)
                    .font(themeManager.currentTheme.font(style: .caption))
                    .foregroundColor(isAvailable ? themeManager.currentTheme.successColor : themeManager.currentTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(isAvailable ? themeManager.currentTheme.secureEnclaveColor : themeManager.currentTheme.textSecondary)
        }
        .padding()
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(themeManager.currentTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
        .onAppear {
            checkBiometry()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Biometric Security: \(statusText)")
    }
    
    private var statusText: String {
        if !isAvailable {
            return "Not Configured"
        }
        switch biometryType {
        case .faceID: return "Face ID Active"
        case .touchID: return "Touch ID Active"
        case .opticID: return "Optic ID Active"
        case .none: return "Not Available"
        @unknown default: return "Unknown"
        }
    }
    
    private var iconName: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "eye.fill"
        case .none: return "lock.slash.fill"
        @unknown default: return "lock.fill"
        }
    }
    
    private func checkBiometry() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAvailable = true
            biometryType = context.biometryType
        } else {
            isAvailable = false
            biometryType = .none
        }
    }
}
