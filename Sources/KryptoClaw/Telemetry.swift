import Foundation

public class Telemetry {
    public static let shared = Telemetry()

    private init() {}

    public func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        // TODO: Integrate production analytics backend
        print("[Telemetry] \(event) - \(parameters ?? [:])")
    }
}
