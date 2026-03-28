import SwiftUI
import ServiceManagement

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
        VStack(spacing: 4) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(sleepManager.isActive ? 1.0 : 0.4)
                .animation(.spring(duration: 0.25), value: sleepManager.isActive)

            HStack(spacing: 8) {
                Text("Stay Awake")
                    .font(.headline)
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
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(sleepManager.isActive ? Color.accentColor.opacity(0.08) : .clear)
                .animation(.spring(duration: 0.25), value: sleepManager.isActive)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(spacing: 4) {
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
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $launchAtLogin) {
                Text("Launch at Login")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: launchAtLogin) { _, newValue in
                if newValue {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }
            .padding(.vertical, 4)

            Divider()

            Toggle(isOn: Binding(
                get: { sleepManager.rememberLastState },
                set: { sleepManager.rememberLastState = $0 }
            )) {
                Text("Remember Last State")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(isHoveringQuit ? Color.primary.opacity(0.08) : .clear)
        }
        .onHover { hovering in
            isHoveringQuit = hovering
        }
    }
}
