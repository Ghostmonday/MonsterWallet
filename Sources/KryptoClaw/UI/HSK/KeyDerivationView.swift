import SwiftUI

/// View showing key derivation progress from HSK
public struct KeyDerivationView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var coordinator: HSKFlowCoordinator
    
    @State private var progress: Double = 0
    @State private var currentStep = 0
    @State private var showAddressPreview = false
    
    private let steps = [
        "Reading credential...",
        "Deriving wallet key...",
        "Generating address...",
        "Securing in enclave..."
    ]
    
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
                
                // Progress indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 8)
                        .frame(width: 160, height: 160)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor,
                                    themeManager.currentTheme.successColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    
                    // Center content
                    VStack(spacing: 4) {
                        if progress >= 1.0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.successColor)
                        } else {
                            Text("\(Int(progress * 100))%")
                                .font(themeManager.currentTheme.balanceFont)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                    }
                }
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                
                Spacer().frame(height: 48)
                
                // Title & status
                VStack(spacing: 16) {
                    Text("DERIVING WALLET KEY")
                        .font(themeManager.currentTheme.font(style: .title2))
                        .tracking(2)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    Text(steps[min(currentStep, steps.count - 1)])
                        .font(themeManager.currentTheme.font(style: .body))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .animation(.easeInOut, value: currentStep)
                }
                
                Spacer().frame(height: 48)
                
                // Step indicators
                HStack(spacing: 16) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        StepIndicator(
                            index: index,
                            currentStep: currentStep,
                            isComplete: index < currentStep
                        )
                    }
                }
                
                Spacer()
                
                // Address preview (shown when complete)
                if showAddressPreview, let address = coordinator.derivedAddress {
                    VStack(spacing: 12) {
                        Text("WALLET ADDRESS")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        
                        Text(formatAddress(address))
                            .font(themeManager.currentTheme.addressFont)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(themeManager.currentTheme.backgroundSecondary)
                            .cornerRadius(themeManager.currentTheme.cornerRadius)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 40)
                }
                
                if !showAddressPreview {
                    Spacer().frame(height: 100)
                }
            }
        }
        .onAppear {
            startDerivation()
        }
    }
    
    private func startDerivation() {
        // Animate progress through steps
        Task {
            for step in 0..<steps.count {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = step
                    }
                }
                
                // Simulate step progress
                let stepDuration = 0.8
                let stepIncrement = 1.0 / Double(steps.count)
                let stepStart = Double(step) * stepIncrement
                let stepEnd = stepStart + stepIncrement
                
                for i in 0..<10 {
                    try? await Task.sleep(nanoseconds: UInt64(stepDuration / 10 * 1_000_000_000))
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.08)) {
                            progress = stepStart + (stepEnd - stepStart) * Double(i + 1) / 10
                        }
                    }
                }
            }
            
            // Show address preview
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showAddressPreview = true
                }
            }
            
            // Transition to complete after brief delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                coordinator.transitionToComplete()
            }
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        let prefix = String(address.prefix(8))
        let suffix = String(address.suffix(6))
        return "\(prefix)...\(suffix)"
    }
}

// MARK: - Step Indicator Component

private struct StepIndicator: View {
    let index: Int
    let currentStep: Int
    let isComplete: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 12, height: 12)
            
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.backgroundMain)
            }
        }
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: 2)
        )
    }
    
    private var fillColor: Color {
        if isComplete {
            return themeManager.currentTheme.successColor
        } else if index == currentStep {
            return themeManager.currentTheme.accentColor
        } else {
            return Color.clear
        }
    }
    
    private var strokeColor: Color {
        if isComplete || index == currentStep {
            return Color.clear
        } else {
            return themeManager.currentTheme.borderColor
        }
    }
}

