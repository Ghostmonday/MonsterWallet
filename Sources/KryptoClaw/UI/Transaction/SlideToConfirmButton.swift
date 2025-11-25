// MODULE: SlideToConfirmButton
// VERSION: 1.0.0
// PURPOSE: Slide gesture component for transaction confirmation

import SwiftUI

// MARK: - Slide to Confirm Configuration

/// Configuration for slide behavior
public struct SlideToConfirmConfig: Sendable {
    /// Threshold to trigger confirmation (0.0 to 1.0)
    public let threshold: CGFloat
    
    /// Whether to reset on release if threshold not met
    public let resetOnRelease: Bool
    
    /// Whether the button is enabled
    public let isEnabled: Bool
    
    public init(
        threshold: CGFloat = 0.95,
        resetOnRelease: Bool = true,
        isEnabled: Bool = true
    ) {
        self.threshold = threshold
        self.resetOnRelease = resetOnRelease
        self.isEnabled = isEnabled
    }
    
    public static let `default` = SlideToConfirmConfig()
}

// MARK: - Slide to Confirm Button

/// A beautifully styled slide-to-confirm button with theme integration.
///
/// **Features:**
/// - Smooth gradient track with glassmorphism effect
/// - Animated thumb with pulsing glow
/// - Progress-based color transitions
/// - Haptic feedback on completion
/// - Full theme integration
public struct SlideToConfirmButton: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Current progress (0.0 to 1.0)
    @Binding var progress: CGFloat
    
    /// Whether the button is enabled
    let isEnabled: Bool
    
    /// Configuration
    let config: SlideToConfirmConfig
    
    /// Label text
    let label: String
    
    /// Action to perform when threshold is reached
    let onConfirm: () -> Void
    
    /// Callback for progress changes
    let onProgressChange: ((CGFloat) -> Void)?
    
    // MARK: - State
    
    @State private var isDragging: Bool = false
    @State private var hasTriggered: Bool = false
    @State private var pulseAnimation: Bool = false
    
    // MARK: - Initialization
    
    public init(
        progress: Binding<CGFloat>,
        isEnabled: Bool = true,
        label: String = "Slide to Confirm",
        config: SlideToConfirmConfig = .default,
        onProgressChange: ((CGFloat) -> Void)? = nil,
        onConfirm: @escaping () -> Void
    ) {
        self._progress = progress
        self.isEnabled = isEnabled
        self.label = label
        self.config = config
        self.onProgressChange = onProgressChange
        self.onConfirm = onConfirm
    }
    
    // MARK: - Body
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbSize: CGFloat = geometry.size.height - 8
            let maxOffset = trackWidth - thumbSize - 8
            
            ZStack(alignment: .leading) {
                // Track background with gradient
                RoundedRectangle(cornerRadius: geometry.size.height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.backgroundSecondary,
                                theme.backgroundSecondary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: geometry.size.height / 2)
                            .stroke(theme.borderColor.opacity(0.5), lineWidth: 1)
                    )
                
                // Progress fill with animated gradient
                RoundedRectangle(cornerRadius: geometry.size.height / 2)
                    .fill(
                        LinearGradient(
                            colors: progressColors(theme: theme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize + 8 + (maxOffset * progress))
                    .animation(.easeOut(duration: 0.1), value: progress)
                
                // Label text (fades as progress increases)
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if progress < 0.3 {
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text(hasTriggered ? "Confirmed!" : label)
                            .font(theme.font(style: .subheadline))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(theme.textSecondary.opacity(max(0.0, 1.0 - Double(progress) * 2.0)))
                    
                    Spacer()
                }
                .padding(.leading, thumbSize + 16)
                
                // Thumb with glow effect
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(thumbGlowColor(theme: theme).opacity(0.4))
                        .frame(width: thumbSize + 10, height: thumbSize + 10)
                        .blur(radius: 8)
                        .scaleEffect(pulseAnimation && !hasTriggered ? 1.1 : 1.0)
                    
                    // Main thumb
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: thumbColors(theme: theme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: theme.shadowColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Icon
                    Image(systemName: hasTriggered ? "checkmark" : "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(hasTriggered ? 0 : (isDragging ? 0 : -10)))
                        .scaleEffect(hasTriggered ? 1.2 : 1.0)
                }
                .offset(x: 4 + maxOffset * progress)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChange(value: value, maxOffset: maxOffset)
                        }
                        .onEnded { _ in
                            handleDragEnd()
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasTriggered)
            }
        }
        .frame(height: 60)
        .opacity(isEnabled && config.isEnabled ? 1.0 : 0.5)
        .disabled(!isEnabled || !config.isEnabled)
        .onChange(of: progress) { _, newValue in
            onProgressChange?(newValue)
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // MARK: - Colors
    
    private func progressColors(theme: any ThemeProtocolV2) -> [Color] {
        if hasTriggered {
            return [theme.successColor, theme.successColor.opacity(0.8)]
        } else if progress > 0.7 {
            return [theme.successColor.opacity(0.8), theme.accentColor]
        } else {
            return [theme.accentColor, theme.accentColor.opacity(0.7)]
        }
    }
    
    private func thumbColors(theme: any ThemeProtocolV2) -> [Color] {
        if hasTriggered {
            return [theme.successColor, theme.successColor.opacity(0.8)]
        } else if progress > 0.7 {
            return [theme.successColor, theme.accentColor]
        } else {
            return [theme.accentColor, theme.accentColor.opacity(0.8)]
        }
    }
    
    private func thumbGlowColor(theme: any ThemeProtocolV2) -> Color {
        if hasTriggered {
            return theme.successColor
        } else if progress > 0.7 {
            return theme.successColor
        } else {
            return theme.accentColor
        }
    }
    
    // MARK: - Animations
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    // MARK: - Gesture Handling
    
    /// Handle drag gesture changes
    private func handleDragChange(value: DragGesture.Value, maxOffset: CGFloat) {
        guard isEnabled, config.isEnabled, !hasTriggered else { return }
        
        isDragging = true
        
        // Calculate progress from drag translation
        let translation = value.translation.width
        let newProgress = max(0, min(translation / maxOffset, 1.0))
        
        progress = newProgress
        
        // Check if threshold is reached
        if newProgress >= config.threshold && !hasTriggered {
            hasTriggered = true
            triggerConfirmation()
        }
    }
    
    /// Handle drag gesture end
    private func handleDragEnd() {
        isDragging = false
        
        // Reset if threshold not met and configured to reset
        if progress < config.threshold && config.resetOnRelease && !hasTriggered {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                progress = 0
            }
        }
    }
    
    /// Trigger the confirmation action
    private func triggerConfirmation() {
        // Complete the animation
        withAnimation(.easeOut(duration: 0.2)) {
            progress = 1.0
        }
        
        // Haptic feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        // Execute action
        onConfirm()
    }
    
    /// Reset the button state
    public mutating func reset() {
        hasTriggered = false
        progress = 0
    }
}

// MARK: - Slide Progress Modifier

/// View modifier for tracking slide progress
public struct SlideProgressModifier: ViewModifier {
    @Binding var progress: CGFloat
    let threshold: CGFloat
    let onThresholdReached: () -> Void
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: progress) { _, newValue in
                if newValue >= threshold {
                    onThresholdReached()
                }
            }
    }
}

extension View {
    /// Track slide progress and trigger action when threshold is reached
    public func onSlideThreshold(
        progress: Binding<CGFloat>,
        threshold: CGFloat = 0.95,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SlideProgressModifier(
            progress: progress,
            threshold: threshold,
            onThresholdReached: action
        ))
    }
}

// MARK: - Drag Gesture Calculator

/// Utility for calculating drag progress
public struct DragProgressCalculator {
    
    /// Calculate progress from drag gesture
    /// - Parameters:
    ///   - translation: The drag translation
    ///   - bounds: The total draggable distance
    /// - Returns: Progress value between 0.0 and 1.0
    public static func calculateProgress(translation: CGFloat, bounds: CGFloat) -> CGFloat {
        guard bounds > 0 else { return 0 }
        return max(0, min(translation / bounds, 1.0))
    }
    
    /// Check if threshold is reached
    /// - Parameters:
    ///   - progress: Current progress
    ///   - threshold: Threshold to check against
    /// - Returns: True if threshold is reached
    public static func isThresholdReached(progress: CGFloat, threshold: CGFloat = 0.95) -> Bool {
        progress >= threshold
    }
}

// MARK: - Preview

#if DEBUG
struct SlideToConfirmButton_Previews: PreviewProvider {
    static var previews: some View {
        SlideToConfirmPreviewContainer()
    }
}

struct SlideToConfirmPreviewContainer: View {
    @State private var progress: CGFloat = 0
    @State private var confirmed = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Progress: \(progress, specifier: "%.2f")")
            Text("Confirmed: \(confirmed ? "Yes" : "No")")
            
            SlideToConfirmButton(
                progress: $progress,
                isEnabled: !confirmed
            ) {
                confirmed = true
            }
            .frame(height: 60)
            
            Button("Reset") {
                progress = 0
                confirmed = false
            }
        }
        .padding()
    }
}
#endif
