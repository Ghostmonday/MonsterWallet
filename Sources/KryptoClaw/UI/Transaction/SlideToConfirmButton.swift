// MODULE: SlideToConfirmButton
// VERSION: 1.0.0
// PURPOSE: Slide gesture component for transaction confirmation (Logic Only - No Styling)

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

// MARK: - Slide to Confirm Button (Gesture Logic Only)

/// A slide-to-confirm button implementing drag gesture logic.
///
/// **Implementation Notes:**
/// - Uses GeometryReader to calculate relative position
/// - DragGesture to track 0.0 to 1.0 progress
/// - Triggers action only when threshold is crossed
/// - No styling applied (structural only)
public struct SlideToConfirmButton: View {
    
    // MARK: - Properties
    
    /// Current progress (0.0 to 1.0)
    @Binding var progress: CGFloat
    
    /// Whether the button is enabled
    let isEnabled: Bool
    
    /// Configuration
    let config: SlideToConfirmConfig
    
    /// Action to perform when threshold is reached
    let onConfirm: () -> Void
    
    /// Callback for progress changes
    let onProgressChange: ((CGFloat) -> Void)?
    
    // MARK: - State
    
    @State private var isDragging: Bool = false
    @State private var hasTriggered: Bool = false
    
    // MARK: - Initialization
    
    public init(
        progress: Binding<CGFloat>,
        isEnabled: Bool = true,
        config: SlideToConfirmConfig = .default,
        onProgressChange: ((CGFloat) -> Void)? = nil,
        onConfirm: @escaping () -> Void
    ) {
        self._progress = progress
        self.isEnabled = isEnabled
        self.config = config
        self.onProgressChange = onProgressChange
        self.onConfirm = onConfirm
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbSize = geometry.size.height
            let maxOffset = trackWidth - thumbSize
            
            ZStack(alignment: .leading) {
                // Track (background)
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Progress fill
                Rectangle()
                    .frame(width: thumbSize + (maxOffset * progress))
                
                // Thumb (draggable element)
                Circle()
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: maxOffset * progress)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDragChange(value: value, maxOffset: maxOffset)
                            }
                            .onEnded { _ in
                                handleDragEnd()
                            }
                    )
            }
        }
        .disabled(!isEnabled || !config.isEnabled)
        .onChange(of: progress) { _, newValue in
            onProgressChange?(newValue)
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

