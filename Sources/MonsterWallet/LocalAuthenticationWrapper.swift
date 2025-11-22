import Foundation
import LocalAuthentication

public protocol LocalAuthenticationProtocol {
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool
}

public class BiometricAuthenticator: LocalAuthenticationProtocol {
    public init() {}
    
    public func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        let context = LAContext()
        return try await context.evaluatePolicy(policy, localizedReason: localizedReason)
    }
}
