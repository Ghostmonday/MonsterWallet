import SwiftUI

public struct SwapView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var fromAmount: String = ""
    @State private var fromToken: Chain = .ethereum
    @State private var toToken: Chain = .solana // Example cross-chain swap interface

    // Simulation state
    @State private var isSimulating = false
    @State private var swapQuote: String? = nil

    public init() {}

    public var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            theme.backgroundMain.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Header
                Text("Swap")
                    .font(theme.font(style: .title2))
                    .foregroundColor(theme.textPrimary)
                    .padding(.top)

                // From Card
                VStack(alignment: .leading) {
                    Text("Pay")
                        .foregroundColor(theme.textSecondary)
                    HStack {
                        TextField("0.0", text: $fromAmount)
                            .font(theme.balanceFont)
                            .foregroundColor(theme.textPrimary)
                            .modifier(DecimalKeyboard())

                        Spacer()

                        // Token Selector (Mock)
                        Text(fromToken.nativeCurrency)
                            .font(theme.font(style: .headline))
                            .padding(8)
                            .background(theme.backgroundSecondary)
                            .cornerRadius(8)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
                .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius).stroke(theme.borderColor, lineWidth: 1))
                .padding(.horizontal)

                // Arrow
                Image(systemName: "arrow.down")
                    .foregroundColor(theme.accentColor)
                    .font(.title2)

                // To Card
                VStack(alignment: .leading) {
                    Text("Receive (Estimated)")
                        .foregroundColor(theme.textSecondary)
                    HStack {
                        Text(swapQuote ?? "0.0")
                            .font(theme.balanceFont)
                            .foregroundColor(theme.textPrimary)

                        Spacer()

                        // Token Selector (Mock)
                        Text(toToken.nativeCurrency)
                            .font(theme.font(style: .headline))
                            .padding(8)
                            .background(theme.backgroundSecondary)
                            .cornerRadius(8)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
                .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius).stroke(theme.borderColor, lineWidth: 1))
                .padding(.horizontal)

                Spacer()

                // Action Button
                Button(action: {
                    simulateSwap()
                }) {
                    Text(isSimulating ? "Simulating..." : "Review Swap")
                        .font(theme.font(style: .headline))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accentColor)
                        .cornerRadius(theme.cornerRadius)
                }
                .padding()
                .disabled(fromAmount.isEmpty || isSimulating)

                // Compliance / Risk Warning (Crucial for App Store)
                Text("Trades are executed by third-party providers. KryptoClaw is a non-custodial interface and does not hold your funds.")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onChange(of: fromAmount) { newValue in
            // Basic debounce simulation
            if !newValue.isEmpty {
                // Mock calculation: 1 ETH = 40 SOL (approx)
                if let val = Double(newValue) {
                    swapQuote = String(format: "%.2f", val * 40.0)
                }
            } else {
                swapQuote = nil
            }
        }
    }

    func simulateSwap() {
        isSimulating = true
        // Mock API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSimulating = false
            // Navigate to confirmation (Mock)
        }
    }
}

struct DecimalKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        return content.keyboardType(.decimalPad)
        #else
        return content
        #endif
    }
}
