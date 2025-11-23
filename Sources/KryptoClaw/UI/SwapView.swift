import SwiftUI
import BigInt

struct SwapView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var fromAmount: String = ""
    @State private var toAmount: String = "" // In real app, calculated via quote
    @State private var isCalculating = false
    @State private var slippage: Double = 0.5
    @State private var showError = false
    @State private var errorMessage = ""

    // Mock Price (Simulated for V1 Demo)
    // In a full production app, this would be fetched from an Oracle or CoinGecko.
    let ethPrice = 3000.0

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Swap")
                    .font(themeManager.currentTheme.font(style: .title2))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.top)

                // From Card
                SwapInputCard(
                    title: "From",
                    amount: $fromAmount,
                    symbol: "ETH",
                    theme: themeManager.currentTheme
                )
                .onChange(of: fromAmount) { newValue in
                    calculateQuote(input: newValue)
                }

                // Switcher
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundColor(themeManager.currentTheme.accentColor)

                // To Card
                SwapInputCard(
                    title: "To",
                    amount: $toAmount, // Read only mostly
                    symbol: "USDC",
                    theme: themeManager.currentTheme
                )

                // Settings
                HStack {
                    Text("Slippage Tolerance")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", slippage))%")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .padding(.horizontal)

                Spacer()

                // Action
                if isCalculating {
                    ProgressView()
                } else {
                    KryptoButton(
                        title: "REVIEW SWAP",
                        icon: "arrow.right.arrow.left",
                        action: {
                            // Trigger Swap Flow (Approve -> Swap)
                            // This would call wsm.prepareTransaction() with 1inch/Uniswap Router data
                            if wsm.currentAddress == nil {
                                showError = true
                                errorMessage = "Please create or import a wallet first."
                            } else {
                                showError = true
                                errorMessage = "Swap liquidity is currently unavailable in this region."
                            }
                        },
                        isPrimary: true
                    )
                    .padding()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Swap Unavailable"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    func calculateQuote(input: String) {
        // Debounce logic would go here
        guard let amount = Double(input) else {
            toAmount = ""
            return
        }

        // Simulated Quote (ETH -> USDC)
        // Note: Prices are simulated for V1.
        let quote = amount * ethPrice
        toAmount = String(format: "%.2f (Simulated)", quote)
    }
}

struct SwapInputCard: View {
    let title: String
    @Binding var amount: String
    let symbol: String
    let theme: ThemeProtocolV2

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(theme.font(style: .caption))
                .foregroundColor(theme.textSecondary)

            HStack {
                TextField("0.0", text: $amount)
                    .font(theme.font(style: .title))
                    .foregroundColor(theme.textPrimary)
                    .keyboardType(.decimalPad)

                Text(symbol)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                    .padding(8)
                    .background(theme.backgroundMain)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(theme.backgroundSecondary)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
