import Foundation

/// Role: Tape. Simulator-only demo shelf behind ptp.demo.v1. Device never seeds.
enum TapeSeed {
    @MainActor
    static func plantIfNeeded(using booth: TapeBooth, prefs: TapePrefs, now: Date) async throws {
        #if targetEnvironment(simulator)
        guard !prefs.demoPlanted else { return }
        try await plant(using: booth, now: now)
        prefs.demoPlanted = true
        prefs.writeDefaults(sport: .pitch)
        #else
        _ = booth
        _ = prefs
        _ = now
        #endif
    }

    @MainActor
    static func plant(using booth: TapeBooth, now: Date) async throws {
        let liveKick = now.addingTimeInterval(-2 * 3_600)
        var live = try await booth.startFixture(
            home: "Northside",
            away: "Riverside",
            sport: .pitch,
            at: liveKick
        )
        live = try await booth.commit(
            .goal,
            side: .home,
            hand: try SheetHand(name: "Reed", shirt: 9),
            at: liveKick.addingTimeInterval(180),
            on: live.id
        )
        live = try await booth.commit(
            .foul,
            side: .away,
            hand: nil,
            at: liveKick.addingTimeInterval(400),
            on: live.id
        )
        live = try await booth.commit(
            .card,
            side: .away,
            hand: nil,
            at: liveKick.addingTimeInterval(420),
            on: live.id
        )
        var pair = try await booth.parkTape(on: live.id, at: liveKick.addingTimeInterval(1_200))
        var next = pair.next
        next = try await booth.commit(
            .goal,
            side: .away,
            hand: try SheetHand(name: "Vale", shirt: 11),
            at: liveKick.addingTimeInterval(1_380),
            on: next.id
        )
        next = try await booth.commit(
            .sub,
            side: .home,
            hand: try SheetHand(name: "Cole", shirt: 4),
            at: liveKick.addingTimeInterval(1_560),
            on: next.id
        )
        pair = try await booth.parkTape(on: next.id, at: liveKick.addingTimeInterval(2_400))
        _ = try await booth.commit(
            .goal,
            side: .home,
            hand: try SheetHand(name: "Reed", shirt: 9),
            at: now.addingTimeInterval(-40),
            on: pair.next.id
        )

        var calendar = Calendar.current
        calendar.timeZone = .current
        let yesterday = calendar.startOfDay(for: now).addingTimeInterval(-86_400)
        let harborKick = yesterday.addingTimeInterval(18 * 3_600)
        var harbor = try await booth.startFixture(
            home: "Harbor",
            away: "Quay",
            sport: .ice,
            at: harborKick
        )
        harbor = try await booth.commit(
            .goal,
            side: .away,
            hand: nil,
            at: harborKick.addingTimeInterval(90),
            on: harbor.id
        )
        harbor = try await booth.commit(
            .foul,
            side: .home,
            hand: nil,
            at: harborKick.addingTimeInterval(210),
            on: harbor.id
        )
        harbor = try await booth.commit(
            .goal,
            side: .home,
            hand: try SheetHand(name: "Nash", shirt: 7),
            at: harborKick.addingTimeInterval(540),
            on: harbor.id
        )
        pair = try await booth.parkTape(on: harbor.id, at: harborKick.addingTimeInterval(1_000))
        next = pair.next
        next = try await booth.commit(
            .card,
            side: .away,
            hand: nil,
            at: harborKick.addingTimeInterval(1_080),
            on: next.id
        )
        next = try await booth.commit(
            .sub,
            side: .away,
            hand: nil,
            at: harborKick.addingTimeInterval(1_200),
            on: next.id
        )
        _ = try await booth.parkTape(on: next.id, at: harborKick.addingTimeInterval(1_800))
    }
}
