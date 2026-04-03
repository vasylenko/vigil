import ServiceManagement
import SwiftUI

private let beaconGlow = Color(red: 0.910, green: 0.604, blue: 0.180)

struct MenuBarView: View {
    let sleepManager: SleepManager
    @State private var launchAtLogin = false
    @State private var isHoveringQuit = false
    @State private var isHoveringBeacon = false

    var body: some View {
        VStack(spacing: 0) {
            sceneSection

            modeSection

            settingsSection

            footerSection
        }
        .frame(width: 280)
        .fixedSize()
        .background(controlPanelBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private var controlPanelBackground: some View {
        (sleepManager.isActive
            ? Color(red: 0.05, green: 0.08, blue: 0.15)
            : Color(red: 0.07, green: 0.07, blue: 0.08))
            .animation(.easeInOut(duration: 0.6), value: sleepManager.isActive)
    }

    // MARK: - Scene

    private var sceneSection: some View {
        ZStack {
            skyGradient

            starsLayer

            beaconGlowLayer

            groundLayer

            lighthouseButton
        }
        .frame(width: 280, height: 190)
        .clipped()
        .contentShape(Rectangle())
    }

    private var skyGradient: some View {
        LinearGradient(
            colors: sleepManager.isActive
                ? [
                    Color(red: 0.01, green: 0.02, blue: 0.06),
                    Color(red: 0.03, green: 0.05, blue: 0.12),
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.07, green: 0.11, blue: 0.22),
                    Color(red: 0.09, green: 0.14, blue: 0.26),
                ]
                : [
                    Color(red: 0.04, green: 0.04, blue: 0.06),
                    Color(red: 0.07, green: 0.07, blue: 0.09),
                    Color(red: 0.09, green: 0.09, blue: 0.11),
                    Color(red: 0.11, green: 0.11, blue: 0.13),
                    Color(red: 0.12, green: 0.12, blue: 0.14),
                ],
            startPoint: .top, endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.6), value: sleepManager.isActive)
    }

    private var starsLayer: some View {
        Canvas { context, _ in
            let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, o: Double)] = [
                (22, 12, 1.2, 0.55), (58, 28, 0.8, 0.30), (85, 8, 1.0, 0.45),
                (110, 22, 0.7, 0.25), (138, 10, 1.4, 0.60), (162, 30, 0.8, 0.35),
                (190, 14, 1.0, 0.50), (215, 6, 0.7, 0.28), (235, 24, 1.3, 0.55),
                (255, 16, 0.6, 0.22), (42, 40, 0.7, 0.20), (130, 38, 0.6, 0.18),
                (200, 36, 0.9, 0.40), (30, 55, 0.5, 0.15), (170, 48, 0.7, 0.25),
                (248, 42, 0.8, 0.32), (72, 18, 0.6, 0.22), (150, 52, 0.5, 0.16),
                (100, 45, 0.6, 0.20), (225, 50, 0.5, 0.14),
            ]
            for s in stars {
                let rect = CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)
                context.opacity = s.o
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .opacity(sleepManager.isActive ? 1.0 : 0.12)
        .animation(.easeInOut(duration: 0.6), value: sleepManager.isActive)
        .allowsHitTesting(false)
    }

    private var beaconGlowLayer: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        beaconGlow.opacity(0.25),
                        beaconGlow.opacity(0.06),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            )
            .frame(width: 120, height: 80)
            .offset(y: -10)
            .opacity(sleepManager.isActive ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: sleepManager.isActive)
            .allowsHitTesting(false)
    }

    private var groundLayer: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: sleepManager.isActive
                            ? [
                                Color(red: 0.07, green: 0.11, blue: 0.20).opacity(0.5),
                                Color(red: 0.05, green: 0.08, blue: 0.15).opacity(0.95),
                            ]
                            : [
                                Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.5),
                                Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.95),
                            ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 16)
                .animation(.easeInOut(duration: 0.6), value: sleepManager.isActive)
        }
        .allowsHitTesting(false)
    }

    private var lighthouseButton: some View {
        VStack(spacing: 6) {
            Button {
                sleepManager.toggle()
            } label: {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(sleepManager.isActive ? 1.0 : 0.4)
                    .shadow(
                        color: sleepManager.isActive ? beaconGlow : .clear,
                        radius: sleepManager.isActive ? 10 : 0
                    )
                    .shadow(
                        color: sleepManager.isActive ? beaconGlow.opacity(0.6) : .clear,
                        radius: sleepManager.isActive ? 4 : 0
                    )
                    .scaleEffect(isHoveringBeacon ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: sleepManager.isActive)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringBeacon)
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .onHover { hovering in
                isHoveringBeacon = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Group {
                if sleepManager.isActive {
                    Text("Beacon lit")
                } else {
                    Text("Light the beacon")
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
            .animation(.easeInOut(duration: 0.3), value: sleepManager.isActive)
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(SleepMode.allCases, id: \.self) { mode in
                    let isSelected = sleepManager.sleepMode == mode
                    Button {
                        sleepManager.sleepMode = mode
                    } label: {
                        Text(mode.label)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? beaconGlow : .white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? beaconGlow.opacity(0.10) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isSelected ? beaconGlow.opacity(0.2) : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
            }

            Text(sleepManager.sleepMode.modeDescription)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 4) {
            settingRow("Launch at Login", isOn: launchAtLogin) {
                launchAtLogin.toggle()
                if launchAtLogin {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }

            settingRow("Remember Last State", isOn: sleepManager.rememberLastState) {
                sleepManager.rememberLastState.toggle()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func settingRow(_ title: LocalizedStringResource, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn ? .white : .white.opacity(0.55))
                Spacer()
                Circle()
                    .fill(isOn ? beaconGlow : Color.white.opacity(0.08))
                    .frame(width: 8, height: 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? beaconGlow.opacity(0.06) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }

    // MARK: - Footer

    private var footerSection: some View {
        Button {
            sleepManager.saveState()
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Vigil", systemImage: "power")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHoveringQuit ? Color.white.opacity(0.06) : .clear)
                )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { hovering in
            isHoveringQuit = hovering
        }
    }
}
