import Foundation

public struct ErrorTranslator {
    public static func userFriendlyMessage(for error: Error) -> String {
        if let blockchainError = error as? BlockchainError {
            switch blockchainError {
            case .networkError:
                return "Unable to connect. Please check your internet connection."
            case .invalidAddress:
                return "Invalid recipient address. Please check and try again."
            case .rpcError:
                // Mask raw RPC errors
                return "Transaction failed. The network rejected the request."
            case .parsingError:
                return "Unable to process server response. Please try again."
            case .unsupportedChain:
                return "This blockchain network is not supported."
            case .insufficientFunds:
                return "Insufficient funds to complete this transaction."
            }
        }
        
        // Handle other known error types if any
        
        // Fallback for unknown errors (Masking raw details)
        return "An unexpected error occurred. Please try again."
    }
}
