import SwiftUI

/// Role: Tape. Settings. ReviewScreen goals. Contact, reset, re-run onboarding.
@MainActor
struct BoothCard: View {
    @Bindable var desk: BoothDesk
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var confirmReset = false
    @State private var revealForm = false
    @State private var sport: SportPattern = .pitch

    var body: some View {
        Group {
            if let fault = desk.fault, isSettingsFault(fault) {
                errorPage(fault)
            } else if isFactoryEmpty && !revealForm {
                emptyPage
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background)
        .onAppear { sport = desk.prefs.sport }
    }

    private var isFactoryEmpty: Bool {
        desk.fixtures.isEmpty && desk.openPeriod == nil && desk.fault == nil
    }

    private func isSettingsFault(_ fault: String) -> Bool {
        fault.contains("reset") || fault.contains("disk") || fault.contains("chest")
    }

    private var emptyPage: some View {
        VStack(spacing: TapeBevel.space(2)) {
            TapeArt.image(TapeArt.emptyList, fill: false)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipShape(TapeBevel.cardShape)
                .padding(.horizontal, TapeBevel.space(2))
                .accessibilityHidden(true)
            Text("No settings yet.")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text("Set the sport, contact us, or wipe stored matches.")
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TapeBevel.space(2))
            Button {
                revealForm = true
            } label: {
                Text("Open settings")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.cardShape)
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
            .padding(.horizontal, TapeBevel.space(2))
            Link(destination: TapePrefs.contactURL) {
                VStack(spacing: 0) {
                    Text("Contact us")
                        .font(TapeFace.font(.headline))
                        .foregroundStyle(TapeInk.ink)
                    Text(TapePrefs.contactURL.absoluteString)
                        .font(TapeFace.font(.caption))
                        .foregroundStyle(TapeInk.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                .background(TapeBevel.plate(TapeBevel.cardShape))
                .contentShape(TapeBevel.cardShape)
            }
            .padding(.horizontal, TapeBevel.space(2))
            .padding(.bottom, TapeBevel.space(2))
            .accessibilityLabel("Contact us")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorPage(_ line: String) -> some View {
        VStack(spacing: TapeBevel.space(2)) {
            Text("Settings could not finish.")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text(line)
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(.center)
            Button {
                desk.fault = nil
                Task { await desk.load() }
            } label: {
                Text("Retry")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.cardShape)
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        GeometryReader { geo in
            ScrollView {
                desk(width: geo.size.width, height: geo.size.height)
            }
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.basedOnSize)
        }
        .confirmationDialog("Reset all data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                Task { await desk.resetAllData() }
            }
            Button("Keep the tapes", role: .cancel) {}
        } message: {
            Text("Every period and call is wiped. This cannot be undone.")
        }
    }

    private func desk(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(2)) {
            headerBlock
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: TapeBevel.space(2)) {
                    sportSurface
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(spacing: TapeBevel.space(2)) {
                        boothPlate
                            .frame(maxHeight: .infinity)
                        deviceSurface
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            } else {
                sportSurface
                boothPlate
                    .frame(maxHeight: .infinity)
                deviceSurface
            }
        }
        .padding(TapeBevel.space(2))
        .frame(width: width, alignment: .topLeading)
        .frame(minHeight: height)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Booth on this device")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text("Set the sport, contact us, or wipe stored matches.")
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sportSurface: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            Text("Sport")
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
            Text("New kickoffs open on this template.")
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
            VStack(spacing: TapeBevel.space(1)) {
                ForEach(SportPattern.allCases, id: \.self) { pattern in
                    sportKey(pattern)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    private var boothPlate: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            Text("This booth")
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
            Text("Live tape and parked counts stay on the device.")
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
            HStack(alignment: .top, spacing: TapeBevel.space(2)) {
                boothStat("Sport", value: TapeCopy.sport(sport))
                boothStat("Fixtures", value: TapeStamp.count(desk.fixtures.count))
                boothStat("Parked", value: TapeStamp.count(desk.parkedTapes.count))
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            VStack(alignment: .leading, spacing: 0) {
                Text(openLine)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(openDetail)
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, alignment: .leading)
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    private var openLine: String {
        if let live = desk.openPeriod {
            return "\(live.homeName) vs \(live.awayName)"
        }
        return "No open tape"
    }

    private var openDetail: String {
        if let live = desk.openPeriod {
            return "Period \(TapeStamp.count(live.periodIndex)) is running on \(TapeCopy.sport(live.sport))."
        }
        return "Start a match from the drawer when the booth is ready."
    }

    private var deviceSurface: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            Text("This device")
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
            Text("Contact stays on the booth. Wipe is local.")
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
            Link(destination: TapePrefs.contactURL) {
                surfaceRow("Contact us", line: TapePrefs.contactURL.absoluteString, ink: TapeInk.accent)
            }
            .buttonStyle(TapePress())
            .accessibilityLabel("Contact us")
            Button {
                desk.rerunOnboarding()
            } label: {
                surfaceRow("Re-run onboarding", line: "Walk the first whistle again.", ink: TapeInk.ink)
            }
            .buttonStyle(TapePress())
            Button(role: .destructive) {
                confirmReset = true
            } label: {
                surfaceRow("Reset all data", line: "Wipe every period and call.", ink: TapeInk.ink)
            }
            .buttonStyle(TapePress())
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    private func sportKey(_ pattern: SportPattern) -> some View {
        let selected = sport == pattern
        return Button {
            sport = pattern
            desk.prefs.sport = pattern
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(TapeCopy.sport(pattern))
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(selected ? TapeInk.background : TapeInk.ink)
                    .lineLimit(1)
                Text(TapeCopy.sportLine(pattern))
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(selected ? TapeInk.background : TapeInk.muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, TapeBevel.space(2))
            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, maxHeight: .infinity, alignment: .leading)
            .background(selected ? TapeInk.accent : TapeInk.background)
            .clipShape(TapeBevel.cardShape)
            .overlay(TapeBevel.cardShape.strokeBorder(TapeInk.muted.opacity(0.55), lineWidth: 1))
            .contentShape(TapeBevel.cardShape)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel(TapeCopy.sport(pattern))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint("Sets the sport for the next kickoff")
    }

    private func boothStat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(1)
            Text(value)
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func surfaceRow(_ title: String, line: String, ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(TapeFace.font(.headline))
                .foregroundStyle(ink)
                .lineLimit(1)
            Text(line)
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, TapeBevel.space(2))
        .padding(.vertical, TapeBevel.space(1))
        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, maxHeight: .infinity, alignment: .leading)
        .background(TapeInk.background)
        .clipShape(TapeBevel.cardShape)
        .overlay(TapeBevel.cardShape.strokeBorder(TapeInk.muted.opacity(0.55), lineWidth: 1))
        .contentShape(TapeBevel.cardShape)
    }
}
