import Combine
import SwiftUI
import CommonCrypto

/// Coordinator managing the HSK wallet creation flow state and navigation
@available(iOS 15.0, macOS 12.0, *)
public class HSKFlowCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var currentState: HSKWalletCreationState = .initiation
    @Published public private(set) var derivedAddress: String?
    @Published public private(set) var isLoading = false
    @Published public var showError = false
    @Published public var errorMessage = ""
    
    // MARK: - Properties
    
    public let mode: HSKFlowMode
    private let derivationManager: HSKKeyDerivationManagerProtocol
    private let bindingManager: WalletBindingManagerProtocol
    private let secureEnclaveInterface: SecureEnclaveInterfaceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    public var onComplete: ((String) -> Void)?
    public var onCancel: (() -> Void)?
    
    private var pendingDerivationResult: HSKDerivationResult?
    
    // MARK: - Initialization
    
    public init(
        mode: HSKFlowMode = .createNewWallet,
        derivationManager: HSKKeyDerivationManagerProtocol? = nil,
        bindingManager: WalletBindingManagerProtocol? = nil,
        secureEnclaveInterface: SecureEnclaveInterfaceProtocol? = nil
    ) {
        self.mode = mode
        
        // Use real implementations or provided mocks
        if let dm = derivationManager {
            self.derivationManager = dm
        } else {
            self.derivationManager = HSKKeyDerivationManager()
        }
        
        let seInterface = secureEnclaveInterface ?? SecureEnclaveInterface()
        self.secureEnclaveInterface = seInterface
        
        if let bm = bindingManager {
            self.bindingManager = bm
        } else {
            self.bindingManager = WalletBindingManager(secureEnclaveInterface: seInterface)
        }
        
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Arm the Secure Enclave for HSK operations
    public func armSecureEnclave() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await secureEnclaveInterface.armForHSK()
    }
    
    /// Transition to the insertion screen
    public func transitionToInsertion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .awaitingInsertion
        }
    }
    
    /// Start listening for HSK
    public func startListeningForHSK() {
        derivationManager.listenForHSK()
    }
    
    /// Transition to derivation screen
    public func transitionToDerivation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .derivingKey
        }
    }
    
    /// Transition to complete screen
    public func transitionToComplete() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .complete
        }
    }
    
    /// Complete the flow and notify delegate
    public func complete() {
        guard let address = derivedAddress else {
            handleError(.bindingFailed("No wallet address available"))
            return
        }
        
        onComplete?(address)
    }
    
    /// Cancel the flow
    public func cancel() {
        derivationManager.cancelOperation()
        onCancel?()
    }
    
    /// Retry after an error
    public func retry() {
        showError = false
        errorMessage = ""
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .initiation
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to state changes from derivation manager
        derivationManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        // Subscribe to events
        derivationManager.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: HSKWalletCreationState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = state
        }
        
        if case .error(let error) = state {
            handleError(error)
        }
    }
    
    private func handleEvent(_ event: HSKEvent) {
        switch event {
        case .hskDetected:
            transitionToDerivation()
            
        case .keyDerivationStarted:
            isLoading = true
            
        case .keyDerivationComplete(let keyData):
            isLoading = false
            Task {
                await finalizeWalletCreation(keyData: keyData)
            }
            
        case .walletCreated(let address):
            derivedAddress = address
            transitionToComplete()
            
        case .derivationError(let error):
            handleError(error)
            
        case .verificationComplete:
            break
            
        case .verificationFailed(let error):
            handleError(error)
        }
    }
    
    private func finalizeWalletCreation(keyData: Data) async {
        do {
            // SECURITY: Validate key data length before proceeding
            guard keyData.count == 32 else {
                throw HSKError.derivationFailed("Invalid key data length: expected 32 bytes")
            }
            
            // Generate address from key data
            let address = generateAddress(from: keyData)
            
            // SECURITY: Validate generated address format
            guard address.hasPrefix("0x") && address.count == 42 else {
                throw HSKError.derivationFailed("Invalid address format generated")
            }
            
            // Create HSK ID from key data
            let hskId = keyData.prefix(16).base64EncodedString()
            
            // Complete binding based on mode
            switch mode {
            case .createNewWallet:
                _ = try await bindingManager.completeBinding(
                    hskId: hskId,
                    derivedKeyHandle: keyData,
                    address: address,
                    credentialId: nil
                )
                
            case .bindToExistingWallet(let walletId):
                // SECURITY: Validate existing wallet ID format
                guard walletId.hasPrefix("0x") && walletId.count == 42 else {
                    throw HSKError.bindingFailed("Invalid wallet ID format")
                }
                _ = try await bindingManager.bindToExistingWallet(
                    walletId: walletId,
                    hskId: hskId,
                    derivedKeyHandle: keyData,
                    credentialId: nil
                )
            }
            
            await MainActor.run {
                derivedAddress = address
                
                // Notify via event for state manager integration
                if let dm = derivationManager as? HSKKeyDerivationManager {
                    dm.markComplete(address: address)
                }
            }
            
        } catch {
            await MainActor.run {
                if let hskError = error as? HSKError {
                    handleError(hskError)
                } else {
                    handleError(.bindingFailed(error.localizedDescription))
                }
            }
        }
    }
    
    private func generateAddress(from keyData: Data) -> String {
        // Generate Ethereum-style address from key data
        // In production, this would use proper key derivation
        let hash = keyData.sha256()
        let addressBytes = hash.suffix(20)
        return "0x" + addressBytes.map { String(format: "%02x", $0) }.joined()
    }
    
    private func handleError(_ error: HSKError) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
        
        KryptoLogger.shared.log(
            level: .error,
            category: .security,
            message: "HSK flow error",
            metadata: ["error": error.localizedDescription]
        )
    }
}

// MARK: - HSK Flow View

/// Main container view for the HSK flow
@available(iOS 15.0, macOS 12.0, *)
public struct HSKFlowView: View {
    
    @StateObject private var coordinator: HSKFlowCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    public init(
        mode: HSKFlowMode = .createNewWallet,
        onComplete: ((String) -> Void)? = nil
    ) {
        let coord = HSKFlowCoordinator(mode: mode)
        coord.onComplete = onComplete
        _coordinator = StateObject(wrappedValue: coord)
    }
    
    public var body: some View {
        ZStack {
            // Current state view
            currentView
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
        }
        .alert("Error", isPresented: $coordinator.showError) {
            Button("Retry") {
                coordinator.retry()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(coordinator.errorMessage)
        }
        .onAppear {
            coordinator.onCancel = {
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var currentView: some View {
        switch coordinator.currentState {
        case .initiation:
            HSKWalletInitiationView(coordinator: coordinator)
            
        case .awaitingInsertion:
            InsertHSKView(coordinator: coordinator)
            
        case .derivingKey:
            KeyDerivationView(coordinator: coordinator)
            
        case .verifying:
            KeyDerivationView(coordinator: coordinator)
            
        case .complete:
            WalletCreationCompleteView(coordinator: coordinator)
            
        case .error:
            HSKErrorView(coordinator: coordinator)
        }
    }
}

// MARK: - HSK Error View

@available(iOS 15.0, macOS 12.0, *)
private struct HSKErrorView: View {
    
    @ObservedObject var coordinator: HSKFlowCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Color.clear
                .themedContainer(theme: themeManager.currentTheme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Error icon
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.errorColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(themeManager.currentTheme.errorColor)
                }
                
                VStack(spacing: 12) {
                    Text("OPERATION FAILED")
                        .font(themeManager.currentTheme.font(style: .title2))
                        .tracking(2)
                        .foregroundColor(themeManager.currentTheme.errorColor)
                    
                    Text(coordinator.errorMessage)
                        .font(themeManager.currentTheme.font(style: .body))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    KryptoButton(
                        title: "TRY AGAIN",
                        icon: "arrow.clockwise",
                        action: { coordinator.retry() },
                        isPrimary: true
                    )
                    
                    Button(action: { coordinator.cancel() }) {
                        Text("Cancel")
                            .font(themeManager.currentTheme.font(style: .body))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Data Extension for SHA256

private extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: 32)
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}

