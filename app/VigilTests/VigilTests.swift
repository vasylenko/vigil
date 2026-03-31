import Foundation
import IOKit.pwr_mgt
import Testing
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
        defaults.set(true, forKey: SleepManager.DefaultsKey.rememberLastState)
        defaults.set(true, forKey: SleepManager.DefaultsKey.wasActiveAtQuit)
        let manager = SleepManager(defaults: defaults)
        defer { manager.deactivate() }
        #expect(manager.isActive == true)
    }

    @Test func initDoesNotRestoreWhenRememberDisabled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: SleepManager.DefaultsKey.rememberLastState)
        defaults.set(true, forKey: SleepManager.DefaultsKey.wasActiveAtQuit)
        let manager = SleepManager(defaults: defaults)
        #expect(manager.isActive == false)
    }

    // MARK: - IOPMAssertion integration

    @Test func activateCreatesSystemAssertion() {
        let manager = SleepManager(defaults: makeDefaults())
        manager.activate()
        defer { manager.deactivate() }
        let assertions = findAssertions(forPid: ProcessInfo.processInfo.processIdentifier)
        #expect(assertions.contains { $0.name.contains("Vigil") })
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
        defer { manager.deactivate() }

        manager.sleepMode = .systemOnly

        let assertions = findAssertions(forPid: ProcessInfo.processInfo.processIdentifier)
        #expect(assertions.contains { $0.type == (kIOPMAssertPreventUserIdleSystemSleep as String) })
        #expect(!assertions.contains { $0.type == (kIOPMAssertPreventUserIdleDisplaySleep as String) })
    }

    // MARK: - State persistence

    @Test func saveStatePersistsActiveState() {
        let defaults = makeDefaults()
        let manager = SleepManager(defaults: defaults)
        manager.rememberLastState = true
        manager.activate()
        defer { manager.deactivate() }
        manager.saveState()
        #expect(defaults.bool(forKey: SleepManager.DefaultsKey.wasActiveAtQuit) == true)
    }

    @Test func saveStateClearsWhenRememberDisabled() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: SleepManager.DefaultsKey.wasActiveAtQuit)
        let manager = SleepManager(defaults: defaults)
        manager.rememberLastState = false
        manager.saveState()
        #expect(defaults.object(forKey: SleepManager.DefaultsKey.wasActiveAtQuit) == nil)
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
