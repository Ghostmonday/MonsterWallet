import SwiftUI

// MARK: - Apple Default Theme
// VERSION: 2.0.0
// PURPOSE: Canonical theme definition - all future themes MUST follow this structure

/// The Apple Default Theme provides a clean, modern iOS-native aesthetic.
/// This theme serves as the canonical reference for the Monster Wallet design system.
/// All other themes must implement the same properties and adhere to this structure.
public struct AppleDefaultTheme: ThemeProtocolV2 {
    
    // MARK: - Identity
    
    public let id = "apple_default"
    public let name = "Default"
    
    // MARK: - Core Colors
    
    /// Primary background - used for main screen backgrounds
    public var backgroundMain: Color { Color(red: 0.95, green: 0.95, blue: 0.97) }
    
    /// Secondary background - used for cards, inputs, elevated surfaces
    public var backgroundSecondary: Color { Color.white }
    
    /// Primary text - used for headings, important content
    public var textPrimary: Color { Color(red: 0.11, green: 0.11, blue: 0.12) }
    
    /// Secondary text - used for labels, captions, less important content
    public var textSecondary: Color { Color(red: 0.45, green: 0.45, blue: 0.47) }
    
    /// Accent color - used for interactive elements, highlights, CTAs
    public var accentColor: Color { Color(red: 0.0, green: 0.48, blue: 1.0) }
    
    /// Success color - used for confirmations, positive states
    public var successColor: Color { Color(red: 0.2, green: 0.78, blue: 0.35) }
    
    /// Error color - used for errors, destructive actions, warnings
    public var errorColor: Color { Color(red: 1.0, green: 0.23, blue: 0.19) }
    
    /// Warning color - used for cautions, alerts requiring attention
    public var warningColor: Color { Color(red: 1.0, green: 0.58, blue: 0.0) }
    
    // MARK: - Surface Colors
    
    /// Card background - used for card components, modal overlays
    public var cardBackground: Color { Color.white }
    
    /// Border color - used for dividers, outlines, separators
    public var borderColor: Color { Color(red: 0.85, green: 0.85, blue: 0.87) }
    
    // MARK: - V2 Advanced Properties
    
    /// Glass effect opacity for glassmorphism effects
    public var glassEffectOpacity: Double { 0.95 }
    
    /// Material style for blur effects
    public var materialStyle: Material { .regular }
    
    /// Whether to show diamond pattern overlay (premium themes)
    public var showDiamondPattern: Bool { false }
    
    /// Background animation type
    public var backgroundAnimation: BackgroundAnimationType { .none }
    
    /// Chart gradient colors for data visualization
    public var chartGradientColors: [Color] { [accentColor, Color(red: 0.35, green: 0.78, blue: 0.98)] }
    
    /// Security warning color for poisoning/phishing alerts
    public var securityWarningColor: Color { warningColor }
    
    // MARK: - Corner Radii
    
    /// Standard corner radius for cards, buttons, inputs
    public var cornerRadius: CGFloat { 12.0 }
    
    /// Small corner radius for badges, tags, chips
    public var cornerRadiusSmall: CGFloat { 6.0 }
    
    /// Large corner radius for modals, bottom sheets
    public var cornerRadiusLarge: CGFloat { 20.0 }
    
    /// Pill corner radius for fully rounded elements
    public var cornerRadiusPill: CGFloat { 100.0 }
    
    // MARK: - Typography
    
    /// Large balance display font
    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .rounded) }
    
    /// Monospace font for addresses, hashes, code
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    /// Title font for screen titles
    public var titleFont: Font { .system(size: 28, weight: .bold, design: .default) }
    
    /// Headline font for section headers
    public var headlineFont: Font { .system(size: 17, weight: .semibold, design: .default) }
    
    /// Body font for main content
    public var bodyFont: Font { .system(size: 17, weight: .regular, design: .default) }
    
    /// Caption font for small labels, metadata
    public var captionFont: Font { .system(size: 12, weight: .regular, design: .default) }
    
    /// Dynamic font based on text style
    public func font(style: Font.TextStyle) -> Font {
        .system(style, design: .default)
    }
    
    // MARK: - Icons
    
    /// Send icon
    public var iconSend: String { "arrow.up.circle.fill" }
    
    /// Receive icon
    public var iconReceive: String { "arrow.down.circle.fill" }
    
    /// Swap icon
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    
    /// Settings icon
    public var iconSettings: String { "gear" }
    
    /// Shield/security icon
    public var iconShield: String { "shield.fill" }
    
    // MARK: - Spacing
    
    /// Extra small spacing (4pt)
    public var spacingXS: CGFloat { 4 }
    
    /// Small spacing (8pt)
    public var spacingS: CGFloat { 8 }
    
    /// Medium spacing (12pt)
    public var spacingM: CGFloat { 12 }
    
    /// Large spacing (16pt)
    public var spacingL: CGFloat { 16 }
    
    /// Extra large spacing (24pt)
    public var spacingXL: CGFloat { 24 }
    
    /// 2X large spacing (32pt)
    public var spacing2XL: CGFloat { 32 }
    
    // MARK: - Shadows
    
    /// Standard shadow color
    public var shadowColor: Color { Color.black.opacity(0.08) }
    
    /// Standard shadow radius
    public var shadowRadius: CGFloat { 8 }
    
    /// Standard shadow Y offset
    public var shadowY: CGFloat { 4 }
    
    // MARK: - Animation
    
    /// Standard animation duration
    public var animationDuration: Double { 0.3 }
    
    /// Spring response for bouncy animations
    public var springResponse: Double { 0.5 }
    
    /// Spring damping for bouncy animations
    public var springDamping: Double { 0.8 }
    
    // MARK: - Component Sizing
    
    /// Button height (standard)
    public var buttonHeight: CGFloat { 56 }
    
    /// Button height (compact)
    public var buttonHeightCompact: CGFloat { 44 }
    
    /// Input field height
    public var inputHeight: CGFloat { 52 }
    
    /// Icon button size
    public var iconButtonSize: CGFloat { 44 }
    
    /// Action button circle size
    public var actionButtonSize: CGFloat { 60 }
    
    /// Avatar/logo size (small)
    public var avatarSizeSmall: CGFloat { 32 }
    
    /// Avatar/logo size (medium)
    public var avatarSizeMedium: CGFloat { 40 }
    
    /// Avatar/logo size (large)
    public var avatarSizeLarge: CGFloat { 56 }
    
    // MARK: - Initialization
    
    public init() {}
}

// MARK: - Theme Protocol Extension for New Properties

/// Extension to provide default values for new theme properties
/// This ensures backward compatibility with existing themes
public extension ThemeProtocolV2 {
    
    // Corner radii defaults
    var cornerRadiusSmall: CGFloat { cornerRadius / 2 }
    var cornerRadiusLarge: CGFloat { cornerRadius * 1.67 }
    var cornerRadiusPill: CGFloat { 100.0 }
    
    // Typography defaults
    var titleFont: Font { font(style: .title) }
    var headlineFont: Font { font(style: .headline) }
    var bodyFont: Font { font(style: .body) }
    var captionFont: Font { font(style: .caption) }
    
    // Spacing defaults
    var spacingXS: CGFloat { 4 }
    var spacingS: CGFloat { 8 }
    var spacingM: CGFloat { 12 }
    var spacingL: CGFloat { 16 }
    var spacingXL: CGFloat { 24 }
    var spacing2XL: CGFloat { 32 }
    
    // Shadow defaults
    var shadowColor: Color { Color.black.opacity(0.1) }
    var shadowRadius: CGFloat { cornerRadius / 2 }
    var shadowY: CGFloat { 4 }
    
    // Animation defaults
    var animationDuration: Double { 0.3 }
    var springResponse: Double { 0.5 }
    var springDamping: Double { 0.8 }
    
    // Component sizing defaults
    var buttonHeight: CGFloat { 56 }
    var buttonHeightCompact: CGFloat { 44 }
    var inputHeight: CGFloat { 52 }
    var iconButtonSize: CGFloat { 44 }
    var actionButtonSize: CGFloat { 60 }
    var avatarSizeSmall: CGFloat { 32 }
    var avatarSizeMedium: CGFloat { 40 }
    var avatarSizeLarge: CGFloat { 56 }
    
    // Semantic color accessors
    var destructiveColor: Color { errorColor }
    var interactiveColor: Color { accentColor }
    var disabledColor: Color { textSecondary.opacity(0.5) }
    var overlayColor: Color { Color.black.opacity(0.4) }
    var qrBackgroundColor: Color { Color.white }
    var inputBackgroundColor: Color { backgroundSecondary }
    var placeholderColor: Color { textSecondary.opacity(0.6) }
}
