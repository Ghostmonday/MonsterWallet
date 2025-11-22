import Foundation

public class BasicHeuristicAnalyzer: SecurityPolicyProtocol {
    
    public init() {}
    
    public func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert] {
        var alerts: [RiskAlert] = []
        
        if !result.success {
            alerts.append(RiskAlert(level: .high, description: "Transaction is likely to fail"))
        }
        
        // Example heuristic: High Value
        // If value string length > 19 (roughly > 10 ETH), warn.
        if tx.value.count > 19 {
            alerts.append(RiskAlert(level: .medium, description: "High value transaction"))
        }
        
        // Example: Contract interaction (data not empty)
        if !tx.data.isEmpty {
            alerts.append(RiskAlert(level: .medium, description: "Interaction with contract"))
        }
        
        return alerts
    }
    
    public func onBreach(alert: RiskAlert) {
        MonsterLogger.shared.log(level: .warning, category: .boundary, message: "Security Breach: \(alert.description)")
    }
}
