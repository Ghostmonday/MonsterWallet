import Foundation

public enum LogLevel {
    case debug
    case info
    case warning
    case error
}

public enum LogCategory: String {
    case lifecycle = "Lifecycle"
    case protocolCall = "Protocol"
    case stateTransition = "State"
    case boundary = "Boundary"
    case error = "Error"
    case security = "Security"
    // Added for comprehensive logging
    case blockchain = "Blockchain"
    case transaction = "Transaction"
    case network = "Network"
    case simulation = "Simulation"
    case appLifecycle = "AppLifecycle"
}

public protocol LoggerProtocol {
    func log(level: LogLevel, category: LogCategory, message: String, metadata: [String: String]?)
    func logEntry(module: String, function: String, params: [String: String]?)
    func logExit(module: String, function: String, result: String?)
    func logProtocolCall(module: String, protocolName: String, method: String, params: [String: String]?)
    func logStateTransition(module: String, from: String, to: String)
    func logError(module: String, error: Error)
}

public class KryptoLogger: LoggerProtocol {
    public static let shared = KryptoLogger()

    private init() {}

    public func log(level: LogLevel, category: LogCategory, message: String, metadata: [String: String]? = nil) {
        #if DEBUG
            print("[\(category.rawValue)] \(message) \(metadata ?? [:])")
        #else
            if level == .error {
                let fingerprint = String(message.hashValue)
                print("[\(category.rawValue)] Error Fingerprint: \(fingerprint)")
            }
        #endif
    }

    public func logEntry(module: String, function: String, params: [String: String]? = nil) {
        #if DEBUG
            let paramString = params?.description ?? "[:]"
            print("[\(module)] Entry: \(function)(params: \(paramString))")
        #endif
    }

    public func logExit(module: String, function: String, result: String? = nil) {
        #if DEBUG
            let resultString = result ?? "void"
            print("[\(module)] Exit: \(function)(result: \(resultString))")
        #endif
    }

    public func logProtocolCall(module: String, protocolName: String, method: String, params _: [String: String]? = nil) {
        #if DEBUG
            print("[\(module)] Protocol Call: \(protocolName).\(method)")
        #endif
    }

    public func logStateTransition(module: String, from: String, to: String) {
        #if DEBUG
            print("[\(module)] State Transition: \(from) -> \(to)")
        #endif
    }

    public func logError(module: String, error: Error) {
        #if DEBUG
            print("[\(module)] Error: \(error)")
        #else
            let fingerprint = String(String(describing: error).hashValue)
            print("[\(module)] Error Fingerprint: \(fingerprint)")
        #endif
    }
}
