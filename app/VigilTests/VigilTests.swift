import Testing
import Foundation
import IOKit.pwr_mgt
@testable import Vigil

@Suite(.serialized)
@MainActor
struct SleepManagerTests {

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    // MARK: - State restoration

    @Test func initRestoresStateWhenRememberEnabled() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "rememberLastState")
        defaults.set(true, forKey: "wasActiveAtQuit")
        let manager = SleepManager(defaults: defaults)
        #expect(manager.isActive == true)
        manager.deactivate()
    }

    @Test func initDoesNotRestoreWhenRememberDisabled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "rememberLastState")
        defaults.set(true, forKey: "wasActiveAtQuit")
        let manager = SleepManager(defaults: defaults)
        #expect(manager.isActive == false)
    }

    // MARK: - IOPMAssertion integration

    @Test func activateCreatesSystemAssertion() {
        let manager = SleepManager(defaults: makeDefaults())
        manager.activate()
        let assertions = findAssertions(forPid: ProcessInfo.processInfo.processIdentifier)
        #expect(assertions.contains { $0.name.contains("Vigil") })
        manager.deactivate()
    }

    @Test func deactivateRemovesSystemAssertion() {
        let manager = SleepManager(defaults: makeDefaults())
        manager.activate()
        manager.deactivate()
        let assertions = findAssertions(forPid: ProcessInfo.processInfo.processIdentifier)
        #expect(!assertions.contains { $0.name.contains("Vigil") })
    }

    @Test func modeSwitchWhileActiveReplacesAssertion() {
        let manager = SleepManager(defaults: makeDefaults())
        manager.sleepMode = .displayAndSystem
        manager.activate()

        manager.sleepMode = .systemOnly

        let assertions = findAssertions(forPid: ProcessInfo.processInfo.processIdentifier)
        #expect(assertions.contains { $0.type == (kIOPMAssertPreventUserIdleSystemSleep as String) })
        #expect(!assertions.contains { $0.type == (kIOPMAssertPreventUserIdleDisplaySleep as String) })
        manager.deactivate()
    }
}

// MARK: - Helpers

private struct PowerAssertion {
    let type: String
    let name: String
}

private func findAssertions(forPid pid: Int32) -> [PowerAssertion] {
    var cfDict: Unmanaged<CFDictionary>?
    guard IOPMCopyAssertionsByProcess(&cfDict) == kIOReturnSuccess,
          let dict = cfDict?.takeRetainedValue() as NSDictionary? else {
        return []
    }

    for (key, value) in dict {
        guard let pidNumber = key as? NSNumber,
              pidNumber.int32Value == pid,
              let assertionList = value as? [[String: Any]] else {
            continue
        }
        return assertionList.compactMap { entry in
            guard let type = entry["AssertType"] as? String,
                  let name = entry["AssertName"] as? String else {
                return nil
            }
            return PowerAssertion(type: type, name: name)
        }
    }
    return []
}
