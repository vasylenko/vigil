import SwiftUI
import ServiceManagement

private let beaconGlow = Color(red: 0.910, green: 0.604, blue: 0.180)

struct MenuBarView: View {
    let sleepManager: SleepManager
    @State private var launchAtLogin = false
    @State private var isHoveringQuit = false

    var body: some View {
        VStack(spacing: 0) {
            heroSection

            modeSection

            Divider()
                .padding(.horizontal)

            settingsSection

            Divider()
                .padding(.horizontal)

            footerSection
        }
        .frame(width: 280)
        .padding(.vertical, 4)
        .fixedSize()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(sleepManager.isActive ? 1.0 : 0.35)
                .shadow(
                    color: sleepManager.isActive ? beaconGlow : .clear,
                    radius: sleepManager.isActive ? 10 : 0
                )
                .shadow(
                    color: sleepManager.isActive ? beaconGlow.opacity(0.6) : .clear,
                    radius: sleepManager.isActive ? 4 : 0
                )
                .animation(.easeInOut(duration: 0.3), value: sleepManager.isActive)

            HStack(spacing: 8) {
                Text("Stay Awake")
                    .font(.system(size: 14, weight: .semibold))
                Toggle(isOn: Binding(
                    get: { sleepManager.isActive },
                    set: { _ in sleepManager.toggle() }
                )) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Text(sleepManager.isActive ? "Sleep prevention is on" : "Sleep prevention is off")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(spacing: 6) {
            Picker("Mode", selection: Binding(
                get: { sleepManager.sleepMode },
                set: { sleepManager.sleepMode = $0 }
            )) {
                ForEach(SleepMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(sleepManager.sleepMode.modeDescription)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $launchAtLogin) {
                Text("Launch at Login")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: launchAtLogin) { _, newValue in
                if newValue {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }
            .padding(.vertical, 6)

            Divider()

            Toggle(isOn: Binding(
                get: { sleepManager.rememberLastState },
                set: { sleepManager.rememberLastState = $0 }
            )) {
                Text("Remember Last State")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 6)
        }
        .controlSize(.small)
        .toggleStyle(.switch)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - Footer

    private var footerSection: some View {
        Button {
            sleepManager.saveState()
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Vigil", systemImage: "power")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(isHoveringQuit ? Color.primary.opacity(0.06) : .clear)
        }
        .onHover { hovering in
            isHoveringQuit = hovering
        }
    }
}
