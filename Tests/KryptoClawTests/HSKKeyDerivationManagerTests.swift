import XCTest
import Combine
@testable import KryptoClaw

final class HSKKeyDerivationManagerTests: XCTestCase {
    
    var mockManager: MockHSKKeyDerivationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockManager = MockHSKKeyDerivationManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        mockManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - State Tests
    
    func testInitialState() {
        var receivedState: HSKWalletCreationState?
        
        mockManager.statePublisher
            .sink { state in
                receivedState = state
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(receivedState, .initiation)
    }
    
    func testListenForHSKTransitionsToAwaitingInsertion() {
        let expectation = XCTestExpectation(description: "State transitions to awaitingInsertion")
        var states: [HSKWalletCreationState] = []
        
        mockManager.statePublisher
            .sink { state in
                states.append(state)
                if state == .awaitingInsertion {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockManager.listenForHSK()
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(states.contains(.awaitingInsertion))
    }
    
    func testSuccessfulDerivationEmitsEvents() {
        let expectation = XCTestExpectation(description: "Derivation events emitted")
        var events: [HSKEvent] = []
        
        mockManager.simulatedDelay = 0.1
        
        mockManager.eventPublisher
            .sink { event in
                events.append(event)
                if case .keyDerivationComplete = event {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockManager.listenForHSK()
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertTrue(events.contains(where: { 
            if case .hskDetected = $0 { return true }
            return false
        }))
        XCTAssertTrue(events.contains(where: {
            if case .keyDerivationStarted = $0 { return true }
            return false
        }))
        XCTAssertTrue(events.contains(where: {
            if case .keyDerivationComplete = $0 { return true }
            return false
        }))
    }
    
    func testFailedDerivationEmitsError() {
        let expectation = XCTestExpectation(description: "Error event emitted")
        mockManager.shouldSucceed = false
        mockManager.simulatedDelay = 0.1
        
        mockManager.eventPublisher
            .sink { event in
                if case .derivationError = event {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockManager.listenForHSK()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCancelOperationEmitsUserCancelledError() {
        var finalState: HSKWalletCreationState?
        
        mockManager.statePublisher
            .sink { state in
                finalState = state
            }
            .store(in: &cancellables)
        
        mockManager.cancelOperation()
        
        if case .error(let error) = finalState {
            XCTAssertEqual(error, .userCancelled)
        } else {
            XCTFail("Expected error state with userCancelled")
        }
    }
    
    func testSimulateSuccessTransitionsToComplete() {
        let expectation = XCTestExpectation(description: "Wallet created event")
        let testAddress = "0x1234567890abcdef"
        
        mockManager.eventPublisher
            .sink { event in
                if case .walletCreated(let address) = event {
                    XCTAssertEqual(address, testAddress)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockManager.simulateSuccess(address: testAddress)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - HSK Types Tests

final class HSKTypesTests: XCTestCase {
    
    func testHSKErrorDescriptions() {
        let errors: [HSKError] = [
            .detectionFailed("test"),
            .derivationFailed("test"),
            .verificationFailed("test"),
            .bindingFailed("test"),
            .keyNotFound,
            .userCancelled,
            .unsupportedDevice,
            .enclaveNotAvailable,
            .invalidCredential,
            .timeout
        ]
        
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testHSKWalletCreationStateDisplayTitles() {
        let states: [HSKWalletCreationState] = [
            .initiation,
            .awaitingInsertion,
            .derivingKey,
            .verifying,
            .complete,
            .error(.keyNotFound)
        ]
        
        for state in states {
            XCTAssertFalse(state.displayTitle.isEmpty)
            XCTAssertFalse(state.displaySubtitle.isEmpty)
        }
    }
    
    func testHSKWalletCreationStateTerminalStates() {
        XCTAssertFalse(HSKWalletCreationState.initiation.isTerminal)
        XCTAssertFalse(HSKWalletCreationState.awaitingInsertion.isTerminal)
        XCTAssertFalse(HSKWalletCreationState.derivingKey.isTerminal)
        XCTAssertFalse(HSKWalletCreationState.verifying.isTerminal)
        XCTAssertTrue(HSKWalletCreationState.complete.isTerminal)
        XCTAssertTrue(HSKWalletCreationState.error(.keyNotFound).isTerminal)
    }
    
    func testHSKBoundWalletCodable() throws {
        let wallet = HSKBoundWallet(
            hskId: "test-hsk-id",
            derivedKeyHandle: Data(repeating: 0xAB, count: 32),
            address: "0x1234567890abcdef1234567890abcdef12345678"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(wallet)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HSKBoundWallet.self, from: data)
        
        // SECURITY TEST: Verify that non-sensitive fields are preserved
        XCTAssertEqual(wallet.hskId, decoded.hskId)
        XCTAssertEqual(wallet.address, decoded.address)
        XCTAssertEqual(wallet.id, decoded.id)
        
        // SECURITY TEST: Verify that derivedKeyHandle is NOT persisted
        // This is intentional - the key handle is stored only in Secure Enclave
        XCTAssertEqual(decoded.derivedKeyHandle.count, 0, 
            "SECURITY: derivedKeyHandle should NOT be persisted to disk")
        
        // Verify the encoded JSON doesn't contain the key handle
        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertFalse(jsonString.contains("derivedKeyHandle"), 
            "SECURITY: derivedKeyHandle should not appear in JSON")
    }
    
    func testHSKFlowModeIsBinding() {
        XCTAssertFalse(HSKFlowMode.createNewWallet.isBinding)
        XCTAssertTrue(HSKFlowMode.bindToExistingWallet(walletId: "test").isBinding)
    }
    
    func testHSKDetectionResultSuccess() {
        let result = HSKDetectionResult.detected(
            credentialId: Data(repeating: 0x01, count: 16),
            publicKey: Data(repeating: 0x02, count: 32)
        )
        XCTAssertTrue(result.isSuccess)
        
        XCTAssertFalse(HSKDetectionResult.notFound.isSuccess)
        XCTAssertFalse(HSKDetectionResult.error(.keyNotFound).isSuccess)
    }
}

// MARK: - Wallet Binding Manager Tests

final class WalletBindingManagerTests: XCTestCase {
    
    var mockBindingManager: MockWalletBindingManager!
    
    override func setUp() {
        super.setUp()
        mockBindingManager = MockWalletBindingManager()
    }
    
    override func tearDown() {
        mockBindingManager = nil
        super.tearDown()
    }
    
    func testCompleteBindingSuccess() async throws {
        let hskId = "test-hsk-id-12345"
        let keyHandle = Data(repeating: 0xCD, count: 32)
        let address = "0x1234567890abcdef1234567890abcdef12345678"
        
        let binding = try await mockBindingManager.completeBinding(
            hskId: hskId,
            derivedKeyHandle: keyHandle,
            address: address,
            credentialId: nil
        )
        
        XCTAssertEqual(binding.hskId, hskId)
        XCTAssertEqual(binding.address, address)
        let count = await mockBindingManager.getBindingsCount()
        XCTAssertEqual(count, 1)
    }
    
    func testGetBindingByAddress() async throws {
        let address = "0x1234567890abcdef1234567890abcdef12345678"
        _ = try await mockBindingManager.completeBinding(
            hskId: "hsk1-test-id",
            derivedKeyHandle: Data(repeating: 0x01, count: 32),
            address: address,
            credentialId: nil
        )
        
        let retrieved = await mockBindingManager.getBinding(for: address)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.address, address)
    }
    
    func testGetBindingByHskId() async throws {
        let hskId = "unique-hsk-id-test"
        let address = "0xabcdef1234567890abcdef1234567890abcdef12"
        _ = try await mockBindingManager.completeBinding(
            hskId: hskId,
            derivedKeyHandle: Data(repeating: 0x02, count: 32),
            address: address,
            credentialId: nil
        )
        
        let retrieved = await mockBindingManager.getBinding(byHskId: hskId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.hskId, hskId)
    }
    
    func testIsWalletBound() async throws {
        let address = "0xboundaddress1234567890abcdef1234567890ab"
        
        let isInitiallyBound = await mockBindingManager.isWalletBound(address)
        XCTAssertFalse(isInitiallyBound)
        
        _ = try await mockBindingManager.completeBinding(
            hskId: "hsk-test-id",
            derivedKeyHandle: Data(repeating: 0xAB, count: 32),
            address: address,
            credentialId: nil
        )
        
        let isBoundAfter = await mockBindingManager.isWalletBound(address)
        XCTAssertTrue(isBoundAfter)
    }
    
    func testRemoveBinding() async throws {
        let address = "0xtoremove1234567890abcdef1234567890abcd"
        _ = try await mockBindingManager.completeBinding(
            hskId: "hsk-test-id",
            derivedKeyHandle: Data(repeating: 0xEF, count: 32),
            address: address,
            credentialId: nil
        )
        
        let isBoundBefore = await mockBindingManager.isWalletBound(address)
        XCTAssertTrue(isBoundBefore)
        
        try await mockBindingManager.removeBinding(for: address)
        
        let isBoundAfter = await mockBindingManager.isWalletBound(address)
        XCTAssertFalse(isBoundAfter)
    }
    
    func testBindingFailure() async {
        await mockBindingManager.setShouldFail(true)
        
        do {
            _ = try await mockBindingManager.completeBinding(
                hskId: "hsk-test",
                derivedKeyHandle: Data(repeating: 0x01, count: 32),
                address: "0x1234567890abcdef1234567890abcdef12345678",
                credentialId: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is HSKError)
        }
    }
}

// MARK: - Secure Enclave Interface Tests

final class SecureEnclaveInterfaceTests: XCTestCase {
    
    var mockInterface: MockSecureEnclaveInterface!
    
    override func setUp() {
        super.setUp()
        mockInterface = MockSecureEnclaveInterface()
    }
    
    override func tearDown() {
        mockInterface = nil
        super.tearDown()
    }
    
    func testArmForHSK() async throws {
        let isArmedBefore = await mockInterface.isArmed()
        XCTAssertFalse(isArmedBefore)
        
        try await mockInterface.armForHSK()
        
        let isArmedAfter = await mockInterface.isArmed()
        XCTAssertTrue(isArmedAfter)
    }
    
    func testStoreAndRetrieveKey() async throws {
        let keyHandle = Data(repeating: 0xEF, count: 32)
        let identifier = "test-key"
        
        try await mockInterface.storeHSKDerivedKey(keyHandle: keyHandle, identifier: identifier)
        
        let retrieved = try await mockInterface.retrieveHSKDerivedKey(identifier: identifier)
        
        XCTAssertEqual(keyHandle, retrieved)
    }
    
    func testRetrieveNonExistentKeyThrows() async {
        do {
            _ = try await mockInterface.retrieveHSKDerivedKey(identifier: "nonexistent")
            XCTFail("Expected error")
        } catch let error as HSKError {
            XCTAssertEqual(error, .keyNotFound)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testDeleteKey() async throws {
        let identifier = "to-delete"
        try await mockInterface.storeHSKDerivedKey(keyHandle: Data(repeating: 0x01, count: 32), identifier: identifier)
        
        try await mockInterface.deleteHSKDerivedKey(identifier: identifier)
        
        do {
            _ = try await mockInterface.retrieveHSKDerivedKey(identifier: identifier)
            XCTFail("Key should be deleted")
        } catch {
            // Expected
        }
    }
    
    func testArmFailure() async {
        await mockInterface.setShouldFail(true)
        
        do {
            try await mockInterface.armForHSK()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is HSKError)
        }
    }
}

