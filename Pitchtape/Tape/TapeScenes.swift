import SwiftUI

/// Role: Tape. Named Console scene. ReviewScreen today stays on the ON-AIR board.
struct ConsoleBoard: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        OnAirBoard(desk: desk)
    }
}

/// Role: Tape. Named Matches scene. Fixtures, not a post-game sheet.
struct MatchesRack: View {
    @Bindable var desk: BoothDesk
    var startKickoff: () -> Void

    var body: some View {
        FixtureRack(desk: desk, startKickoff: startKickoff)
    }
}

/// Role: Tape. Named Insights scene. ReviewScreen log. Parked tapes and PDF.
struct InsightsRack: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        ParkedRack(desk: desk)
    }
}

/// Role: Tape. Named Settings scene. ReviewScreen goals. Contact, reset, onboarding.
struct SettingsBoard: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        BoothCard(desk: desk)
    }
}
