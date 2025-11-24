import Foundation

public enum ErrorTranslator {
    public static func userFriendlyMessage(for error: Error) -> String {
        if let blockchainError = error as? BlockchainError {
            switch blockchainError {
            case .networkError:
                return "Unable to connect. Please check your internet connection."
            case .invalidAddress:
                return "Invalid recipient address. Please check and try again."
            case .rpcError:
                return "Transaction failed. The network rejected the request."
            case .parsingError:
                return "Unable to process server response. Please try again."
            case .unsupportedChain:
                return "This blockchain network is not supported."
            case .insufficientFunds:
                return "Insufficient funds to complete this transaction."
            }
        }

        if let walletError = error as? WalletError {
            switch walletError {
            case .invalidMnemonic:
                return "Invalid recovery phrase. Please check and try again."
            case .derivationFailed:
                return "Failed to generate wallet. Please try again."
            }
        }

        if let keyStoreError = error as? KeyStoreError {
            switch keyStoreError {
            case .itemNotFound:
                return "Key not found. Please create or import a wallet."
            case .invalidData:
                return "Invalid key data. Please try again."
            case .accessControlSetupFailed:
                return "Security setup failed. Please check your device settings."
            case .unhandledError:
                return "Key storage error. Please try again."
            }
        }

        if let recoveryError = error as? RecoveryError {
            switch recoveryError {
            case .invalidThreshold:
                return "Invalid recovery threshold. Please check your recovery shares."
            case .encodingError:
                return "Recovery encoding failed. Please try again."
            case .invalidShares:
                return "Invalid recovery shares. Please verify your recovery phrase."
            case .reconstructionFailed:
                return "Failed to reconstruct wallet. Please check your recovery shares."
            }
        }

        if let nftError = error as? NFTError {
            switch nftError {
            case .invalidContract:
                return "Invalid NFT contract address."
            case .fetchFailed:
                return "Failed to fetch NFTs. Please try again."
            case .timeout:
                return "Request timed out. Please check your connection and try again."
            }
        }

        if let validationError = error as? Contact.ValidationError {
            switch validationError {
            case let .invalidName(message):
                return message
            case .invalidAddress:
                return "Invalid address format. Please check and try again."
            }
        }

        return "An unexpected error occurred. Please try again."
    }
}
