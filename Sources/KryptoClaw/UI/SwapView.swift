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

    @State private var price: Decimal?
    
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
                .onChange(of: fromAmount) { oldValue, newValue in
                    Task {
                        await calculateQuote(input: newValue)
                    }
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
                
                if let p = price {
                    HStack {
                        Text("Price")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                        Text("1 ETH ≈ $\(NSDecimalNumber(decimal: p).stringValue)")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Action
                if isCalculating {
                    ProgressView()
                } else {
                    KryptoButton(
                        title: fromAmount.isEmpty ? "ENTER AMOUNT" : "REVIEW SWAP",
                        icon: "arrow.right.arrow.left",
                        action: {
                            if wsm.currentAddress == nil {
                                showError = true
                                errorMessage = "Please create or import a wallet first."
                            } else if toAmount.isEmpty {
                                // Do nothing
                            } else {
                                // For V1, we don't have a real DEX aggregator yet.
                                // But we have real prices.
                                showError = true
                                errorMessage = "Swap execution requires a DEX Aggregator API key (e.g. 1inch). Price feed is live."
                            }
                        },
                        isPrimary: !fromAmount.isEmpty
                    )
                    .padding()
                    .disabled(fromAmount.isEmpty)
                    .opacity(fromAmount.isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Swap Info"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            Task {
                do {
                    price = try await wsm.fetchPrice(chain: .ethereum)
                } catch {
                    KryptoLogger.shared.logError(module: "SwapView", error: error)
                }
            }
        }
    }

    func calculateQuote(input: String) async {
        isCalculating = true
        defer { isCalculating = false }
        
        guard let amount = Double(input), let currentPrice = price else {
            toAmount = ""
            return
        }

        // Real Calculation based on fetched price
        let quote = Decimal(amount) * currentPrice
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        toAmount = formatter.string(from: NSDecimalNumber(decimal: quote)) ?? ""
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
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

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
