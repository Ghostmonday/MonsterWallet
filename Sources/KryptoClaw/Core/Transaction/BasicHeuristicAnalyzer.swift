import Foundation

public class BasicHeuristicAnalyzer: SecurityPolicyProtocol {
    public init() {}

    public func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert] {
        var alerts: [RiskAlert] = []

        if !result.success {
            alerts.append(RiskAlert(level: .high, description: "Transaction is likely to fail"))
        }

        if tx.value.count > 19 {
            alerts.append(RiskAlert(level: .medium, description: "High value transaction"))
        }

        if !tx.data.isEmpty {
            alerts.append(RiskAlert(level: .medium, description: "Interaction with contract"))
        }

        return alerts
    }

    public func onBreach(alert: RiskAlert) {
        KryptoLogger.shared.log(level: .warning, category: .boundary, message: "Security Breach: \(alert.description)", metadata: ["level": alert.level.rawValue, "module": "BasicHeuristicAnalyzer"])
    }
}
