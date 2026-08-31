import Foundation
import Observation
import UIKit

/// Role: Tape. Presentation seam. Views call park, commit, and undo. They never hold a phase enum.
@MainActor
@Observable
final class BoothDesk {
    let booth: TapeBooth
    let prefs: TapePrefs
    private var review = TapeLaneReader()
    private var bootstrapped = false
    private var spinnerTask: Task<Void, Never>?

    var fixtures: [FixtureMatch] = []
    var selectedFixtureID: UUID?
    var openPeriod: OpenPeriod?
    var fault: String?
    var onboarded = false
    var showOnboarding = false
    var drawerOpen = false
    var scene: BoothScene = .board
    var side: TapeSide = .home
    var isBusy = false
    var showSpinner = false
    var commitFlash = false
    var sharePDF: Data?
    var reviewLane: TapeLane?
    var dayAnchor = Calendar.current.startOfDay(for: Date())

    init(booth: TapeBooth, prefs: TapePrefs = TapePrefs()) {
        self.booth = booth
        self.prefs = prefs
    }

    var parkedTapes: [OpenPeriod] {
        fixtures.flatMap(\.parkedTapes).sorted { lhs, rhs in
            if lhs.fixtureDay != rhs.fixtureDay { return lhs.fixtureDay > rhs.fixtureDay }
            if lhs.homeName != rhs.homeName { return lhs.homeName < rhs.homeName }
            return lhs.periodIndex < rhs.periodIndex
        }
    }

    var liveMatch: FixtureMatch? {
        if let selectedFixtureID {
            return fixtures.first { $0.id == selectedFixtureID }
        }
        return fixtures.reversed().first { $0.openTape != nil } ?? fixtures.first
    }

    var canTap: Bool { openPeriod?.isRunning == true && !isBusy }
    var canUndo: Bool { canTap && !(openPeriod?.calls.isEmpty ?? true) }
    var canWhistle: Bool { openPeriod?.isRunning == true && !isBusy }
    var hasMatch: Bool { openPeriod != nil }

    func bootstrap(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        now: Date = Date(),
        permitSeed: Bool = true
    ) async {
        guard !bootstrapped else { return }
        bootstrapped = true
        await load()
        if permitSeed {
            do {
                try await TapeSeed.plantIfNeeded(using: booth, prefs: prefs, now: now)
                try await refresh()
            } catch {
                fault = "The demo tapes could not be planted."
            }
        }
        onboarded = prefs.onboarded
        if onboarded {
            applyReview(arguments: arguments)
        } else {
            showOnboarding = true
        }
    }

    func load() async {
        beginWork()
        do {
            try await refresh()
            fault = nil
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func tap(_ kind: CallKind, at now: Date = Date()) async {
        guard let id = openPeriod?.id, canTap else { return }
        beginWork()
        do {
            openPeriod = try await booth.commit(kind, side: side, hand: nil, at: now, on: id)
            try await refresh()
            fault = nil
            flashCommit()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func undoLast() async {
        guard let id = openPeriod?.id, canUndo else { return }
        beginWork()
        do {
            openPeriod = try await booth.undo(on: id)
            try await refresh()
            fault = nil
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func blowWhistle(at now: Date = Date()) async {
        guard let id = openPeriod?.id, canWhistle else { return }
        beginWork()
        do {
            let pair = try await booth.parkTape(on: id, at: now)
            openPeriod = pair.next
            try await refresh()
            fault = nil
            flashCommit()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func startFixture(
        home: String,
        away: String,
        sport: SportPattern,
        at now: Date = Date()
    ) async {
        guard !isBusy else { return }
        beginWork()
        do {
            let opened = try await booth.startFixture(home: home, away: away, sport: sport, at: now)
            selectedFixtureID = opened.fixtureID
            openPeriod = opened
            prefs.sport = sport
            try await refresh()
            scene = .board
            drawerOpen = false
            fault = nil
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func resume(_ match: FixtureMatch) {
        selectedFixtureID = match.id
        openPeriod = match.openTape
        scene = .board
        drawerOpen = false
    }

    func resetAllData() async {
        beginWork()
        do {
            try await booth.resetAllData()
            fixtures = []
            selectedFixtureID = nil
            openPeriod = nil
            sharePDF = nil
            fault = nil
        } catch {
            fault = TapeCopy.fault(error)
        }
        endWork()
    }

    func exportParked(_ tapes: [OpenPeriod]? = nil) {
        let data = ParkedReelPDF.render(tapes ?? parkedTapes)
        if data.isEmpty {
            fault = "The parked reel could not be inked."
        } else {
            sharePDF = data
            fault = nil
        }
    }

    func finishOnboarding(sport: SportPattern = .pitch) {
        prefs.writeDefaults(sport: sport)
        onboarded = true
        showOnboarding = false
        applyReview()
    }

    func rerunOnboarding() {
        prefs.clearOnboarding()
        onboarded = false
        drawerOpen = false
        scene = .board
        showOnboarding = true
        review = TapeLaneReader()
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let lane = review.take(arguments: arguments, onboarded: onboarded) else { return }
        reviewLane = lane
        switch lane {
        case .today:
            scene = .board
            drawerOpen = false
        case .log:
            scene = .reels
            drawerOpen = false
        case .goals:
            scene = .card
            drawerOpen = false
        }
    }

    func openDrawer() {
        drawerOpen = true
    }

    func closeDrawer() {
        drawerOpen = false
    }

    func openScene(_ next: BoothScene) {
        scene = next
        drawerOpen = false
    }

    func closeScene() {
        scene = .board
    }

    func refreshDayAnchor(now: Date = Date()) {
        let start = Calendar.current.startOfDay(for: now)
        if start != dayAnchor {
            dayAnchor = start
        }
    }

    func choose(_ next: TapeSide) {
        side = next
    }

    private func refresh() async throws {
        fixtures = try await booth.loadFixtures()
        if let selectedFixtureID, let match = fixtures.first(where: { $0.id == selectedFixtureID }) {
            openPeriod = match.openTape
        } else if let live = fixtures.reversed().first(where: { $0.openTape != nil }) {
            self.selectedFixtureID = live.id
            openPeriod = live.openTape
        } else {
            openPeriod = fixtures.first?.openTape
            selectedFixtureID = fixtures.first?.id
        }
    }

    private func flashCommit() {
        commitFlash = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            self?.commitFlash = false
        }
    }

    private func beginWork() {
        isBusy = true
        spinnerTask?.cancel()
        spinnerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.showSpinner = self?.isBusy == true
        }
    }

    private func endWork() {
        isBusy = false
        showSpinner = false
        spinnerTask?.cancel()
        spinnerTask = nil
    }
}

enum TapeLaunch {
    case ready(BoothDesk)
    case failed

    @MainActor
    static func open() -> TapeLaunch {
        switch TapeChest.open() {
        case .success(let container):
            return .ready(BoothDesk(booth: TapeBooth(modelContainer: container)))
        case .failure:
            return .failed
        }
    }
}
