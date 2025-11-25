// MODULE: HapticEngine
// VERSION: 1.0.0
// PURPOSE: Semantic haptic feedback system using CoreHaptics for rich tactile experiences

import Foundation
#if canImport(CoreHaptics)
import CoreHaptics
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptic Event Types

/// Semantic haptic events for consistent tactile feedback across the app
public enum HapticEvent: Sendable {
    // MARK: - Standard Events
    case success
    case error
    case warning
    case notification
    
    // MARK: - Impact Events
    case lightImpact
    case mediumImpact
    case heavyImpact
    case softImpact
    case rigidImpact
    
    // MARK: - Selection Events
    case selection
    case selectionChanged
    
    // MARK: - Crypto-Specific Events
    case cryptoSwapLock       // Satisfying "lock-in" feeling when confirming a swap
    case transactionSent      // Success with momentum
    case transactionReceived  // Gentle arrival notification
    case walletUnlocked       // Biometric success feedback
    case securityAlert        // Urgent warning pattern
    case balanceRefresh       // Subtle refresh indicator
    case qrScanned            // Quick confirmation
    case addressCopied        // Subtle copy confirmation
    
    // MARK: - Navigation Events
    case tabSwitch
    case sheetPresent
    case sheetDismiss
    case buttonPress
    
    // MARK: - Gesture Events
    case dragStart
    case dragEnd
    case swipeComplete
}

// MARK: - HapticEngine

/// Thread-safe singleton for managing haptic feedback with automatic engine state management.
///
/// Features:
/// - Pre-warms the haptic engine to eliminate latency on first event
/// - Graceful degradation on devices without haptic support
/// - Custom haptic patterns for crypto-specific interactions
/// - Respects system haptic settings
@MainActor
public final class HapticEngine {
    
    // MARK: - Singleton
    
    /// Shared instance of the HapticEngine
    public static let shared = HapticEngine()
    
    // MARK: - Properties
    
    #if canImport(CoreHaptics)
    /// The CoreHaptics engine (nil on unsupported devices)
    private var engine: CHHapticEngine?
    #endif
    
    #if canImport(UIKit)
    /// Fallback generators for simpler haptics
    private lazy var impactLight = UIImpactFeedbackGenerator(style: .light)
    private lazy var impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private lazy var impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private lazy var impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()
    private lazy var notificationGenerator = UINotificationFeedbackGenerator()
    #endif
    
    /// Whether haptics are currently enabled
    public private(set) var isEnabled: Bool = true
    
    /// Whether the engine is in a warmed state
    private var isEngineWarmed: Bool = false
    
    /// Whether the device supports haptics
    public var supportsHaptics: Bool {
        #if canImport(CoreHaptics)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    
    private init() {
        setupEngine()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupEngine() {
        #if canImport(CoreHaptics)
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            
            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }
            
            // Handle engine stop
            engine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.isEngineWarmed = false
                    // Log for telemetry
                    print("[HapticEngine] Stopped: \(reason.rawValue)")
                }
            }
            
        } catch {
            print("[HapticEngine] Failed to create engine: \(error)")
            engine = nil
        }
        #endif
    }
    
    private func setupObservers() {
        #if canImport(UIKit)
        // Observe app lifecycle to manage engine state
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.warmEngine()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopEngine()
            }
        }
        #endif
    }
    
    // MARK: - Engine Management
    
    /// Pre-warm the engine to eliminate latency on first haptic
    public func warmEngine() {
        guard isEnabled, !isEngineWarmed else { return }
        
        #if canImport(CoreHaptics)
        do {
            try engine?.start()
            isEngineWarmed = true
        } catch {
            print("[HapticEngine] Failed to start engine: \(error)")
        }
        #endif
        
        // Also prepare fallback generators
        #if canImport(UIKit)
        impactMedium.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        #endif
    }
    
    /// Stop the engine to conserve resources
    public func stopEngine() {
        #if canImport(CoreHaptics)
        engine?.stop(completionHandler: nil)
        isEngineWarmed = false
        #endif
    }
    
    private func restartEngine() {
        #if canImport(CoreHaptics)
        do {
            try engine?.start()
            isEngineWarmed = true
        } catch {
            print("[HapticEngine] Failed to restart engine: \(error)")
        }
        #endif
    }
    
    // MARK: - Public Interface
    
    /// Play a semantic haptic event
    /// - Parameter event: The haptic event to play
    public func play(_ event: HapticEvent) {
        guard isEnabled else { return }
        
        // Ensure engine is warmed
        if !isEngineWarmed {
            warmEngine()
        }
        
        #if canImport(UIKit)
        switch event {
        // Standard Events
        case .success:
            playNotificationFeedback(.success)
        case .error:
            playNotificationFeedback(.error)
        case .warning:
            playNotificationFeedback(.warning)
        case .notification:
            playNotificationFeedback(.success)
            
        // Impact Events
        case .lightImpact:
            playImpactFeedback(.light)
        case .mediumImpact:
            playImpactFeedback(.medium)
        case .heavyImpact:
            playImpactFeedback(.heavy)
        case .softImpact:
            playImpactFeedback(.soft)
        case .rigidImpact:
            playImpactFeedback(.rigid)
            
        // Selection Events
        case .selection, .selectionChanged:
            playSelectionFeedback()
            
        // Crypto-Specific Events
        case .cryptoSwapLock:
            playCryptoSwapLock()
        case .transactionSent:
            playTransactionSent()
        case .transactionReceived:
            playTransactionReceived()
        case .walletUnlocked:
            playWalletUnlocked()
        case .securityAlert:
            playSecurityAlert()
        case .balanceRefresh:
            playBalanceRefresh()
        case .qrScanned:
            playQRScanned()
        case .addressCopied:
            playAddressCopied()
            
        // Navigation Events
        case .tabSwitch:
            playSelectionFeedback()
        case .sheetPresent:
            playImpactFeedback(.light)
        case .sheetDismiss:
            playImpactFeedback(.soft)
        case .buttonPress:
            playImpactFeedback(.light)
            
        // Gesture Events
        case .dragStart:
            playImpactFeedback(.soft)
        case .dragEnd:
            playImpactFeedback(.medium)
        case .swipeComplete:
            playImpactFeedback(.light)
        }
        #else
        // No haptic feedback on non-UIKit platforms
        _ = event
        #endif
    }
    
    /// Enable or disable haptic feedback
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopEngine()
        }
    }
    
    // MARK: - Fallback Generators
    
    #if canImport(UIKit)
    private func playImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = impactLight
        case .medium:
            generator = impactMedium
        case .heavy:
            generator = impactHeavy
        case .soft:
            generator = impactSoft
        case .rigid:
            generator = impactRigid
        @unknown default:
            generator = impactMedium
        }
        generator.impactOccurred()
    }
    
    private func playSelectionFeedback() {
        selectionGenerator.selectionChanged()
    }
    
    private func playNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
    #endif
    
    // MARK: - Custom Patterns
    
    /// Crypto Swap Lock - satisfying confirmation with "click-lock" feel
    private func playCryptoSwapLock() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.success)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            // Initial impact
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ),
            // Brief pause then lock-in click
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.08
            ),
            // Confirmation rumble
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.12,
                duration: 0.15
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.success)
        }
        #endif
    }
    
    /// Transaction Sent - momentum with confirmation
    private func playTransactionSent() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.success)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            // Whoosh start
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: 0.1
            ),
            // Rising intensity
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.12
            ),
            // Success confirmation
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.25
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.success)
        }
        #endif
    }
    
    /// Transaction Received - gentle arrival notification
    private func playTransactionReceived() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.success)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            // Soft arrival
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0
            ),
            // Gentle confirmation
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.15
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.success)
        }
        #endif
    }
    
    /// Wallet Unlocked - biometric success
    private func playWalletUnlocked() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.success)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            // Quick unlock click
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0
            ),
            // Smooth confirmation
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0.05,
                duration: 0.1
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.success)
        }
        #endif
    }
    
    /// Security Alert - urgent warning pattern
    private func playSecurityAlert() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.warning)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            // First alert
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ),
            // Second alert
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.12
            ),
            // Third alert
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.24
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.warning)
        }
        #endif
    }
    
    /// Balance Refresh - subtle refresh indicator
    private func playBalanceRefresh() {
        #if canImport(UIKit)
        impactLight.impactOccurred(intensity: 0.5)
        #endif
    }
    
    /// QR Scanned - quick confirmation
    private func playQRScanned() {
        #if canImport(CoreHaptics) && canImport(UIKit)
        guard supportsHaptics, let engine = engine else {
            playNotificationFeedback(.success)
            return
        }
        
        let pattern = try? CHHapticPattern(events: [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            )
        ], parameters: [])
        
        if let pattern = pattern {
            playPattern(pattern, on: engine)
        } else {
            playNotificationFeedback(.success)
        }
        #endif
    }
    
    /// Address Copied - subtle copy confirmation
    private func playAddressCopied() {
        #if canImport(UIKit)
        impactLight.impactOccurred(intensity: 0.6)
        #endif
    }
    
    // MARK: - Pattern Playback
    
    #if canImport(CoreHaptics) && canImport(UIKit)
    private func playPattern(_ pattern: CHHapticPattern, on engine: CHHapticEngine) {
        do {
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticEngine] Failed to play pattern: \(error)")
            // Fallback to simple haptic
            playNotificationFeedback(.success)
        }
    }
    #endif
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add haptic feedback to a view on tap
    public func hapticFeedback(_ event: HapticEvent) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticEngine.shared.play(event)
                }
        )
    }
}

