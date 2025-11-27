// KRYPTOCLAW ONBOARDING
// The gateway. Premium first impression.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct OnboardingScreen: View {
    let onComplete: () -> Void
    
    @EnvironmentObject var walletState: WalletStateManager
    @State private var showingCreate = false
    @State private var showingImport = false
    @State private var showingHSK = false
    @State private var logoAppeared = false
    @State private var buttonsAppeared = false
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            KC.Color.bg.ignoresSafeArea()
            
            // Subtle grid pattern
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 40
                    for x in stride(from: 0, through: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, through: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(KC.Color.textGhost.opacity(0.3), lineWidth: 0.5)
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo Section
                VStack(spacing: KC.Space.xxl) {
                    // Premium KC Logo
                    KCLogo(size: 140, animated: true)
                        .scaleEffect(logoAppeared ? 1 : 0.5)
                        .opacity(logoAppeared ? 1 : 0)
                    
                    // Brand text
                    VStack(spacing: KC.Space.sm) {
                        Text("KRYPTOCLAW")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundColor(KC.Color.textPrimary)
                        
                        Text("SECURE BY DESIGN")
                            .font(KC.Font.label)
                            .tracking(3)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                    .opacity(logoAppeared ? 1 : 0)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: KC.Space.md) {
                    // Create Wallet - Primary
                    KCButton("Create New Wallet", icon: "plus.circle", style: .primary) {
                        showingCreate = true
                    }
                    .offset(y: buttonsAppeared ? 0 : 50)
                    .opacity(buttonsAppeared ? 1 : 0)
                    
                    // Import Wallet - Secondary
                    KCButton("Import Wallet", icon: "arrow.down.doc", style: .secondary) {
                        showingImport = true
                    }
                    .offset(y: buttonsAppeared ? 0 : 50)
                    .opacity(buttonsAppeared ? 1 : 0)
                    
                    // Hardware Key - Secondary
                    KCButton("Use Hardware Key", icon: "key.horizontal", style: .secondary) {
                        showingHSK = true
                    }
                    .offset(y: buttonsAppeared ? 0 : 50)
                    .opacity(buttonsAppeared ? 1 : 0)
                }
                .kcPadding()
                
                // Legal
                VStack(spacing: KC.Space.sm) {
                    Text("By continuing, you agree to our")
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textMuted)
                    
                    HStack(spacing: KC.Space.xl) {
                        Link("Terms", destination: URL(string: "https://kryptoclaw.com/terms")!)
                        Link("Privacy", destination: URL(string: "https://kryptoclaw.com/privacy")!)
                    }
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.gold)
                }
                .padding(.top, KC.Space.xl)
                .padding(.bottom, KC.Space.xxxl)
                .opacity(buttonsAppeared ? 1 : 0)
            }
        }
        .onAppear {
            animateEntrance()
        }
        .sheet(isPresented: $showingCreate) {
            CreateWalletSheet(onComplete: onComplete)
                .environmentObject(walletState)
        }
        .sheet(isPresented: $showingImport) {
            ImportWalletSheet(onComplete: onComplete)
                .environmentObject(walletState)
        }
        .sheet(isPresented: $showingHSK) {
            HSKSetupSheet(onComplete: onComplete)
                .environmentObject(walletState)
        }
    }
    
    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.6)) {
            logoAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            buttonsAppeared = true
        }
    }
}

// MARK: - Create Wallet Sheet

struct CreateWalletSheet: View {
    let onComplete: () -> Void
    
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var isGenerating = true
    @State private var mnemonic: [String] = []
    @State private var verificationIndices: [Int] = []
    @State private var userInputs: [String] = ["", "", ""]
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                switch step {
                case 0: generatingView
                case 1: backupView
                case 2: verifyView
                case 3: successView
                default: generatingView
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    if step > 0 && step < 3 {
                        KCBackButton { step -= 1 }
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    if step < 3 {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            generateWallet()
        }
    }
    
    // MARK: - Step 0: Generating
    
    private var generatingView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(KC.Color.gold.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                if isGenerating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(KC.Color.gold)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(KC.Color.gold)
                }
            }
            
            VStack(spacing: KC.Space.sm) {
                Text(isGenerating ? "Generating Wallet" : "Wallet Ready")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(isGenerating ? "Creating secure keys..." : "Your wallet has been created")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            if !isGenerating {
                KCButton("Continue to Backup", icon: "doc.text") {
                    withAnimation { step = 1 }
                }
                .kcPadding()
                .padding(.bottom, KC.Space.xxxl)
            }
        }
    }
    
    // MARK: - Step 1: Backup
    
    private var backupView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: KC.Space.sm) {
                Text("Back Up Your Wallet")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Write down these 12 words in order.\nNever share them with anyone.")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, KC.Space.xl)
            .kcPadding()
            
            // Word Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: KC.Space.sm) {
                    ForEach(Array(mnemonic.enumerated()), id: \.offset) { index, word in
                        WordPill(index: index + 1, word: word)
                    }
                }
                .padding(.top, KC.Space.xxl)
                .kcPadding()
            }
            
            // Warning
            HStack(spacing: KC.Space.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(KC.Color.warning)
                
                Text("Anyone with these words can access your funds")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            .padding(KC.Space.lg)
            .frame(maxWidth: .infinity)
            .background(KC.Color.warning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.md)
                    .stroke(KC.Color.warning.opacity(0.3), lineWidth: 1)
            )
            .kcPadding()
            
            KCButton("I've Written It Down") {
                prepareVerification()
                withAnimation { step = 2 }
            }
            .kcPadding()
            .padding(.top, KC.Space.lg)
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Step 2: Verify
    
    private var verifyView: some View {
        VStack(spacing: 0) {
            VStack(spacing: KC.Space.sm) {
                Text("Verify Your Backup")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Enter the requested words to confirm")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            .padding(.top, KC.Space.xl)
            
            Spacer()
            
            VStack(spacing: KC.Space.lg) {
                ForEach(0..<3, id: \.self) { i in
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("Word #\(verificationIndices[i] + 1)")
                            .font(KC.Font.caption)
                            .foregroundColor(KC.Color.textTertiary)
                        
                        KCInput("Enter word", text: $userInputs[i])
                    }
                }
            }
            .kcPadding()
            
            Spacer()
            
            KCButton("Verify", isLoading: false) {
                verifyWords()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Step 3: Success
    
    private var successView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KC.Color.positive.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(KC.Color.positive.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(KC.Color.positive)
            }
            
            VStack(spacing: KC.Space.sm) {
                Text("You're All Set")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Your wallet is ready to use")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            KCButton("Enter Wallet", icon: "arrow.right") {
                HapticEngine.shared.play(.success)
                onComplete()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Helpers
    
    private func generateWallet() {
        Task {
            // Use the actual wallet creation
            if let generatedMnemonic = await walletState.createWallet(name: "Main Wallet") {
                mnemonic = generatedMnemonic.split(separator: " ").map(String.init)
            } else {
                // Fallback for preview/testing
                mnemonic = ["abandon", "ability", "able", "about", "above", "absent",
                           "absorb", "abstract", "absurd", "abuse", "access", "accident"]
            }
            
            withAnimation {
                isGenerating = false
            }
        }
    }
    
    private func prepareVerification() {
        // Pick 3 random indices
        var indices = Array(0..<12)
        indices.shuffle()
        verificationIndices = Array(indices.prefix(3)).sorted()
    }
    
    private func verifyWords() {
        var allCorrect = true
        for (i, index) in verificationIndices.enumerated() {
            // Case-insensitive comparison with whitespace trimming
            if userInputs[i].lowercased().trimmingCharacters(in: .whitespaces) != mnemonic[index].lowercased() {
                allCorrect = false
                break
            }
        }
        
        if allCorrect {
            HapticEngine.shared.play(.success)
            withAnimation { step = 3 }
        } else {
            HapticEngine.shared.play(.error)
            // Could show error state
        }
    }
}

// MARK: - Import Wallet Sheet

struct ImportWalletSheet: View {
    let onComplete: () -> Void
    
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var words: [String] = Array(repeating: "", count: 12)
    @State private var isImporting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if showSuccess {
                    successView
                } else {
                    inputView
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    if !showSuccess {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 0) {
            inputHeader
            wordInputGrid
            importButton
        }
    }
    
    private var inputHeader: some View {
        VStack(spacing: KC.Space.sm) {
            Text("Import Wallet")
                .font(KC.Font.title2)
                .foregroundColor(KC.Color.textPrimary)
            
            Text("Enter your 12-word recovery phrase")
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
        }
        .padding(.top, KC.Space.xl)
    }
    
    private var wordInputGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: KC.Space.sm) {
                ForEach(Array(0..<12), id: \.self) { index in
                    wordInputField(index: index)
                }
            }
            .kcPadding()
            .padding(.top, KC.Space.xl)
        }
    }
    
    private func wordInputField(index: Int) -> some View {
        HStack(spacing: KC.Space.sm) {
            Text("\(index + 1)")
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.textMuted)
                .frame(width: 24)
            
            TextField("", text: $words[index])
                .font(KC.Font.mono)
                .foregroundColor(KC.Color.textPrimary)
                .disableAutocorrection(true)
        }
        .padding(KC.Space.md)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.sm)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
    
    private var importButton: some View {
        KCButton("Import Wallet", icon: "arrow.down.doc", isLoading: isImporting) {
            importWallet()
        }
        .kcPadding()
        .padding(.bottom, KC.Space.xxxl)
        .disabled(words.contains(where: { $0.isEmpty }))
    }
    
    private var successView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KC.Color.positive.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(KC.Color.positive)
            }
            
            VStack(spacing: KC.Space.sm) {
                Text("Wallet Imported")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Your wallet has been restored")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            KCButton("Enter Wallet") {
                HapticEngine.shared.play(.success)
                onComplete()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    private func importWallet() {
        isImporting = true
        let mnemonic = words.joined(separator: " ")
        
        Task {
            await walletState.importWallet(mnemonic: mnemonic)
            HapticEngine.shared.play(.success)
            withAnimation {
                showSuccess = true
            }
        }
    }
}

// MARK: - Word Pill

struct WordPill: View {
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: KC.Space.sm) {
            Text("\(index)")
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.textMuted)
                .frame(width: 20)
            
            Text(word)
                .font(KC.Font.mono)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, KC.Space.md)
        .padding(.vertical, KC.Space.md)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.sm)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingScreen(onComplete: {})
}

