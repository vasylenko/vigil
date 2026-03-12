import IOKit.pwr_mgt
import Foundation
import AppKit

enum SleepMode: String, CaseIterable {
    case displayAndSystem
    case systemOnly

    var assertionType: CFString {
        switch self {
        case .displayAndSystem:
            kIOPMAssertPreventUserIdleDisplaySleep as CFString
        case .systemOnly:
            kIOPMAssertPreventUserIdleSystemSleep as CFString
        }
    }

    var assertionReason: String {
        switch self {
        case .displayAndSystem:
            "Vigil is keeping your Mac and display awake"
        case .systemOnly:
            "Vigil is keeping your Mac awake (display may sleep)"
        }
    }

    var label: String {
        switch self {
        case .displayAndSystem: "Display & System"
        case .systemOnly: "System Only"
        }
    }

    var description: String {
        switch self {
        case .displayAndSystem: "Screen and system stay awake"
        case .systemOnly: "Screen may sleep, system stays running"
        }
    }
}

@Observable
class SleepManager {
    var isActive = false
    var rememberLastState: Bool {
        didSet {
            defaults.set(rememberLastState, forKey: DefaultsKey.rememberLastState)
        }
    }
    var sleepMode: SleepMode {
        didSet {
            defaults.set(sleepMode.rawValue, forKey: DefaultsKey.sleepMode)
            if isActive {
                deactivate()
                activate()
            }
        }
    }
    private let defaults: UserDefaults
    private var assertionID: IOPMAssertionID = 0

    enum DefaultsKey {
        static let rememberLastState = "rememberLastState"
        static let sleepMode = "sleepMode"
        static let wasActiveAtQuit = "wasActiveAtQuit"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rememberLastState = defaults.bool(forKey: DefaultsKey.rememberLastState)
        if let stored = defaults.string(forKey: DefaultsKey.sleepMode),
           let mode = SleepMode(rawValue: stored) {
            sleepMode = mode
        } else {
            sleepMode = .displayAndSystem
        }
        if rememberLastState && defaults.bool(forKey: DefaultsKey.wasActiveAtQuit) {
            activate()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.saveState()
            }
        }
    }

    func activate() {
        let result = IOPMAssertionCreateWithName(
            sleepMode.assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            sleepMode.assertionReason as CFString,
            &assertionID
        )
        if result == kIOReturnSuccess {
            isActive = true
        }
    }

    func deactivate() {
        if isActive {
            IOPMAssertionRelease(assertionID)
            isActive = false
            assertionID = 0
        }
    }

    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    func saveState() {
        if rememberLastState {
            defaults.set(isActive, forKey: DefaultsKey.wasActiveAtQuit)
        } else {
            defaults.removeObject(forKey: DefaultsKey.wasActiveAtQuit)
        }
    }
}
