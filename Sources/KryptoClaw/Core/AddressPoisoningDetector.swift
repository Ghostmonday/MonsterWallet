import Foundation

/// A service dedicated to detecting "Address Poisoning" attacks.
/// These attacks involve scammers sending small amounts (dust) or zero-value token transfers
/// from an address that looks very similar to one the user frequently interacts with (e.g. same first/last 4 chars).
/// The goal is to trick the user into copying the wrong address from history.
public class AddressPoisoningDetector {
    private let similarityThreshold: Double = 0.8

    public init() {}

    public enum PoisonStatus {
        case safe
        case potentialPoison(reason: String)
    }

    /// Analyzes a target address against a history of legitimate addresses.
    /// - Parameters:
    ///   - targetAddress: The address the user is about to send to.
    ///   - safeHistory: A list of addresses the user has historically trusted or used.
    /// - Returns: A PoisonStatus indicating if this looks like a spoof.
    public func analyze(targetAddress: String, safeHistory: [String]) -> PoisonStatus {
        let target = targetAddress.lowercased()

        for safeAddr in safeHistory {
            let safe = safeAddr.lowercased()

            if target == safe {
                continue
            }

            if hasMatchingEndpoints(addr1: target, addr2: safe) {
                return .potentialPoison(reason: "Warning: This address looks similar to \(shorten(safe)) but is different. Verify every character.")
            }
        }

        return .safe
    }

    private func hasMatchingEndpoints(addr1: String, addr2: String) -> Bool {
        guard addr1.count > 10, addr2.count > 10 else { return false }

        let prefix1 = addr1.prefix(4)
        let suffix1 = addr1.suffix(4)

        let prefix2 = addr2.prefix(4)
        let suffix2 = addr2.suffix(4)

        return prefix1 == prefix2 && suffix1 == suffix2
    }

    private func shorten(_ addr: String) -> String {
        guard addr.count > 10 else { return addr }
        return "\(addr.prefix(4))...\(addr.suffix(4))"
    }
}
