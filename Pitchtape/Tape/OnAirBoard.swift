import SwiftUI

/// Role: Tape. ON-AIR console. Home is the mechanic. ReviewScreen today stays here.
@MainActor
struct OnAirBoard: View {
    @Bindable var desk: BoothDesk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showKickoff = false
    @State private var kickoffDetent: PresentationDetent = .large

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        Group {
            if desk.showOnboarding {
                FirstWhistle { sport in
                    desk.finishOnboarding(sport: sport)
                }
            } else {
                liveRoot
            }
        }
    }

    private var liveRoot: some View {
        ZStack {
            TapeInk.background.ignoresSafeArea()
            boardColumn
            if desk.drawerOpen {
                LeadingRail(desk: desk)
                    .transition(.opacity)
            }
            if desk.scene != .board {
                sceneLayer
                    .transition(.opacity)
            }
            if desk.showSpinner {
                ProgressView()
                    .tint(TapeInk.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TapeInk.background.opacity(0.55))
                    .accessibilityLabel("Loading the tape")
            }
            if desk.commitFlash, TapeArt.present(TapeArt.successMark) {
                TapeArt.image(TapeArt.successMark, fill: false)
                    .frame(width: TapeBevel.space(10), height: TapeBevel.space(10))
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? TapeBevel.fade : TapeBevel.motion, value: desk.drawerOpen)
        .animation(reduceMotion ? TapeBevel.fade : TapeBevel.motion, value: desk.scene)
        .sheet(isPresented: $showKickoff) {
            KickoffSheet(desk: desk, sport: desk.prefs.sport)
                .presentationDetents([.medium, .large], selection: $kickoffDetent)
                .presentationDragIndicator(.visible)
                .presentationBackground(TapeInk.background)
        }
        .onChange(of: showKickoff) { _, open in
            if open { kickoffDetent = .large }
        }
        .sheet(isPresented: Binding(
            get: { desk.sharePDF != nil },
            set: { if !$0 { desk.sharePDF = nil } }
        )) {
            if let data = desk.sharePDF {
                TapeShareBoard(data: data, filename: "Pitchtape-parked.pdf")
            }
        }
    }

    private var boardColumn: some View {
        VStack(spacing: TapeBevel.space(1)) {
            header
            if let fault = desk.fault, desk.scene == .board {
                faultBanner(fault)
            }
            if desk.hasMatch {
                liveBoard
            } else {
                emptyPage
            }
        }
        .padding(.horizontal, TapeBevel.space(2))
        .padding(.top, TapeBevel.space(1))
        .padding(.bottom, TapeBevel.space(1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            TapeArt.image(TapeArt.headerDecor)
                .frame(height: TapeBevel.space(isRegular ? 10 : 7))
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(TapeBevel.cardShape)
                .padding(.horizontal, -TapeBevel.space(2))
                .accessibilityHidden(true)
            HStack(spacing: TapeBevel.space(1)) {
                iconButton("line.3.horizontal", label: "Open the fixture drawer") {
                    desk.openDrawer()
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("ON-AIR")
                        .font(TapeFace.font(.title))
                        .foregroundStyle(TapeInk.ink)
                        .lineLimit(1)
                    Text(jobLine)
                        .font(TapeFace.font(.caption))
                        .foregroundStyle(TapeInk.muted)
                        .lineLimit(2)
                }
                Spacer(minLength: TapeBevel.space(1))
                liveChip
            }
        }
    }

    private var jobLine: String {
        if desk.hasMatch {
            return desk.openPeriod?.calls.isEmpty == true
                ? "Tap Goal on the live clock."
                : "Tap the next call on the open tape."
        }
        return "No match yet. Start the clock."
    }

    private var liveChip: some View {
        Button {
            desk.openScene(.split)
        } label: {
            Text(desk.openPeriod == nil ? "Standby" : "Live tape")
                .font(TapeFace.font(.caption))
                .foregroundStyle(desk.openPeriod == nil ? TapeInk.muted : TapeInk.accent)
                .padding(.horizontal, TapeBevel.space(2))
                .frame(minWidth: TapeBevel.tap, minHeight: TapeBevel.tap)
                .background(TapeBevel.plate(TapeBevel.chipShape))
                .contentShape(TapeBevel.chipShape)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel("Whistle-split tape")
        .accessibilityHint("Opens the whistle-split board")
    }

    private var liveBoard: some View {
        Group {
            if isRegular {
                regularBoard
            } else {
                compactBoard
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactBoard: some View {
        VStack(spacing: TapeBevel.space(1)) {
            scoreStrip
            CallPad(desk: desk)
                .layoutPriority(1)
            TakeTape(period: desk.openPeriod)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            parkedStrip
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var regularBoard: some View {
        GeometryReader { geo in
            let padWidth = min(max(geo.size.width * 0.42, 280), 420)
            VStack(spacing: TapeBevel.space(1)) {
                scoreStrip
                HStack(alignment: .top, spacing: TapeBevel.space(1)) {
                    CallPad(desk: desk)
                        .frame(width: padWidth)
                        .frame(maxHeight: .infinity)
                    TakeTape(period: desk.openPeriod)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: 140)
                }
                parkedStrip
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var scoreStrip: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
            let period = desk.openPeriod
            let board = period.map { TapeFold.board($0, now: timeline.date) }
            HStack(spacing: TapeBevel.space(1)) {
                sideName(period?.homeName ?? "Home", caption: "Home")
                VStack(spacing: 0) {
                    Text(TapeStamp.clock(board?.clock ?? 0))
                        .font(TapeFace.font(.display))
                        .foregroundStyle(TapeInk.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(1)
                    Text(scoreLine(board))
                        .font(TapeFace.font(.title))
                        .foregroundStyle(TapeInk.accent)
                        .lineLimit(1)
                    Text(periodLine(period))
                        .font(TapeFace.font(.caption))
                        .foregroundStyle(TapeInk.muted)
                        .lineLimit(1)
                    Text(lastMarkLine(period))
                        .font(TapeFace.font(.caption))
                        .foregroundStyle(TapeInk.muted)
                        .lineLimit(1)
                }
                .frame(minWidth: 120)
                sideName(period?.awayName ?? "Away", caption: "Away")
            }
            .padding(TapeBevel.space(2))
            .frame(maxWidth: .infinity)
            .background(TapeBevel.plate(TapeBevel.cardShape))
        }
    }

    private func sideName(_ name: String, caption: String) -> some View {
        VStack(spacing: 0) {
            Text(name)
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(caption)
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreLine(_ board: LiveBoard?) -> String {
        let home = TapeStamp.count(board?.homeGoals ?? 0)
        let away = TapeStamp.count(board?.awayGoals ?? 0)
        return "\(home)–\(away)"
    }

    private func periodLine(_ period: OpenPeriod?) -> String {
        guard let period else { return "Standby" }
        return "Period \(TapeStamp.count(period.periodIndex)) · \(TapeCopy.sport(period.sport))"
    }

    private func lastMarkLine(_ period: OpenPeriod?) -> String {
        guard let call = period?.calls.max(by: { $0.takeOrder < $1.takeOrder }) else {
            return "No mark on this tape."
        }
        return "Last mark · \(markName(call.kind)) \(TapeStamp.clock(call.clockAt))"
    }

    private func markName(_ kind: CallKind) -> String {
        switch kind {
        case .goal: "Goal"
        case .foul: "Foul"
        case .card: "Card"
        case .sub: "Sub"
        }
    }

    private var parkedStrip: some View {
        HStack(spacing: TapeBevel.space(2)) {
            stripStat("Parked", TapeStamp.count(desk.parkedTapes.count))
            stripStat("Calls", TapeStamp.count(desk.openPeriod?.calls.count ?? 0))
            Button {
                desk.openScene(.reels)
            } label: {
                Text("Parked reels")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.chipShape)
                    .overlay(TapeBevel.chipShape.strokeBorder(TapeInk.ink.opacity(0.18), lineWidth: 1))
                    .contentShape(TapeBevel.chipShape)
            }
            .buttonStyle(TapePress())
            .accessibilityLabel("Open parked reels")
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    private func stripStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(1)
            Text(value)
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
        }
        .frame(minWidth: TapeBevel.space(7), alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var emptyPage: some View {
        TapeVacant(
            art: TapeArt.emptyHome,
            title: "No match yet.",
            line: "Start the clock.",
            action: "Start the clock"
        ) {
            showKickoff = true
        }
    }

    private func faultBanner(_ line: String) -> some View {
        HStack(spacing: TapeBevel.space(1)) {
            Text(line)
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(3)
            Spacer(minLength: TapeBevel.space(1))
            Button {
                Task { await desk.load() }
            } label: {
                Text("Retry")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .padding(.horizontal, TapeBevel.space(2))
                    .frame(minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.chipShape)
                    .contentShape(TapeBevel.chipShape)
            }
            .buttonStyle(TapePress())
            .accessibilityLabel("Retry loading the tape")
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    @ViewBuilder
    private var sceneLayer: some View {
        VStack(spacing: 0) {
            sceneChrome
            switch desk.scene {
            case .board:
                EmptyView()
            case .rack:
                MatchesRack(desk: desk) { showKickoff = true }
            case .reels:
                InsightsRack(desk: desk)
            case .card:
                SettingsBoard(desk: desk)
            case .split:
                WhistleReel(desk: desk)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background.ignoresSafeArea())
    }

    private var sceneChrome: some View {
        HStack(spacing: TapeBevel.space(1)) {
            iconButton("chevron.backward", label: "Back to the live board") {
                desk.closeScene()
            }
            Text(sceneTitle)
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TapeBevel.space(2))
        .padding(.top, TapeBevel.space(2))
    }

    private var sceneTitle: String {
        switch desk.scene {
        case .board: return "ON-AIR"
        case .rack: return "Matches"
        case .reels: return "Insights"
        case .card: return "Settings"
        case .split: return "Whistle-split"
        }
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
                .frame(width: TapeBevel.tap, height: TapeBevel.tap)
                .background(TapeBevel.plate(TapeBevel.chipShape))
                .contentShape(TapeBevel.chipShape)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel(label)
    }
}

/// Role: Tape. Recoverable chest failure. Never try!.
struct ChestFaultBoard: View {
    var retry: () -> Void

    var body: some View {
        TapeVacant(
            art: TapeArt.emptyHome,
            title: "The tape chest could not open.",
            line: "Retry keeps the board local. Nothing is sent away.",
            action: "Retry",
            actionHandler: retry
        )
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background.ignoresSafeArea())
    }
}
