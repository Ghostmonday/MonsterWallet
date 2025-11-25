import SwiftUI

/// View prompting user to insert or tap their hardware security key
public struct InsertHSKView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var coordinator: HSKFlowCoordinator
    
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    
    public init(coordinator: HSKFlowCoordinator) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.clear
                .themedContainer(theme: themeManager.currentTheme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Animated key icon
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                    
                    // Middle pulse ring
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .opacity(pulseAnimation ? 0.2 : 0.9)
                    
                    // Inner circle
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    // Key icon
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.4), radius: 30, x: 0, y: 0)
                
                Spacer().frame(height: 48)
                
                // Instructions
                VStack(spacing: 16) {
                    Text("INSERT SECURITY KEY")
                        .font(themeManager.currentTheme.font(style: .title2))
                        .tracking(2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    Text("Insert your hardware key into the USB port\nor tap it against your device for NFC")
                        .font(themeManager.currentTheme.font(style: .body))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer().frame(height: 32)
                
                // Status indicator
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    
                    Text("Waiting for key...")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(themeManager.currentTheme.backgroundSecondary.opacity(0.8))
                .cornerRadius(themeManager.currentTheme.cornerRadius)
                
                Spacer()
                
                // Cancel button
                Button(action: { coordinator.cancel() }) {
                    Text("Cancel")
                        .font(themeManager.currentTheme.font(style: .body))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.vertical, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
            coordinator.startListeningForHSK()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
        
        // Subtle rotation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            rotationAngle = 5
        }
    }
    
    private func stopAnimations() {
        pulseAnimation = false
        rotationAngle = 0
    }
}

