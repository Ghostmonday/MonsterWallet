// KRYPTOCLAW NAVIGATOR
// Clean navigation state management.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

// MARK: - Platform-Safe Navigation Modifiers

extension View {
    /// Apply inline navigation bar style (iOS only)
    func kcNavigationInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
    
    /// Apply large navigation bar style (iOS only)
    func kcNavigationLarge() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }
}

// MARK: - Platform-Safe Toolbar Placement

extension ToolbarItemPlacement {
    static var kcLeading: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarLeading
        #else
        .automatic
        #endif
    }
    
    static var kcTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarTrailing
        #else
        .automatic
        #endif
    }
}

// MARK: - Navigation State

@MainActor
public final class Navigator: ObservableObject {
    
    // MARK: Sheet States
    @Published public var showingSend = false
    @Published public var showingReceive = false
    @Published public var showingSwap = false
    @Published public var showingBuy = false
    @Published public var showingEarn = false
    @Published public var showingSettings = false
    @Published public var showingHistory = false
    @Published public var showingNFTGallery = false
    @Published public var showingAddressBook = false
    @Published public var showingWalletManagement = false
    @Published public var showingHSKSetup = false
    
    // MARK: Detail States
    @Published public var selectedChain: Chain?
    @Published public var selectedNFT: NFTMetadata?
    @Published public var selectedTransaction: TransactionSummary?
    @Published public var selectedContact: Contact?
    
    // MARK: Alert States
    @Published public var activeAlert: AlertItem?
    @Published public var toastMessage: ToastItem?
    
    public init() {}
    
    // MARK: - Actions
    
    public func dismissAll() {
        showingSend = false
        showingReceive = false
        showingSwap = false
        showingBuy = false
        showingEarn = false
        showingSettings = false
        showingHistory = false
        showingNFTGallery = false
        showingAddressBook = false
        showingWalletManagement = false
        showingHSKSetup = false
        selectedChain = nil
        selectedNFT = nil
        selectedTransaction = nil
        selectedContact = nil
    }
    
    public func showToast(_ message: String, type: ToastItem.ToastType = .info) {
        toastMessage = ToastItem(message: message, type: type)
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.toastMessage = nil
        }
    }
    
    public func showAlert(title: String, message: String, primaryAction: AlertItem.AlertAction? = nil) {
        activeAlert = AlertItem(title: title, message: message, primaryAction: primaryAction)
    }
}

// MARK: - Alert Models

public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let primaryAction: AlertAction?
    
    public struct AlertAction {
        public let title: String
        public let isDestructive: Bool
        public let action: () -> Void
        
        public init(title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isDestructive = isDestructive
            self.action = action
        }
    }
}

public struct ToastItem: Identifiable {
    public let id = UUID()
    public let message: String
    public let type: ToastType
    
    public enum ToastType {
        case success, error, warning, info
    }
}

// MARK: - Toast View Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toast {
                VStack {
                    Spacer()
                    
                    ToastView(item: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, KC.Space.xl)
                        .padding(.bottom, KC.Space.xxxl)
                }
                .animation(KC.Anim.spring, value: toast.id)
            }
        }
    }
}

struct ToastView: View {
    let item: ToastItem
    
    var body: some View {
        HStack(spacing: KC.Space.md) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            Text(item.message)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    private var iconName: String {
        switch item.type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .success: return KC.Color.positive
        case .error: return KC.Color.negative
        case .warning: return KC.Color.warning
        case .info: return KC.Color.gold
        }
    }
}

extension View {
    func toast(item: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: item))
    }
}

// MARK: - Slide-up Sheet Presentation

struct SlideUpSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Backdrop
                KC.Color.bg.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                    .transition(.opacity)
                
                // Sheet
                VStack {
                    Spacer()
                    self.content()
                        .background(KC.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xxl, style: .continuous))
                        .padding(.horizontal, KC.Space.sm)
                        .padding(.bottom, KC.Space.sm)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(KC.Anim.spring, value: isPresented)
    }
}

extension View {
    func slideUpSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(SlideUpSheet(isPresented: isPresented, content: content))
    }
}

