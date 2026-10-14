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

/// Role: Tape. Full-page vacant. Regular width sits art beside copy; compact stacks them.
struct TapeVacant<Footer: View>: View {
    var art: String
    var title: String
    var line: String
    var action: String
    var actionHandler: () -> Void
    @ViewBuilder var footer: Footer
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(
        art: String,
        title: String,
        line: String,
        action: String,
        actionHandler: @escaping () -> Void,
        @ViewBuilder footer: () -> Footer
    ) {
        self.art = art
        self.title = title
        self.line = line
        self.action = action
        self.actionHandler = actionHandler
        self.footer = footer()
    }

    var body: some View {
        GeometryReader { geo in
            let stacked = sizeClass != .regular || geo.size.width < TapeBevel.stackBreak
            ViewThatFits(in: .vertical) {
                pageFill(stacked: stacked)
                pageScroll
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TapeDock {
                VStack(spacing: TapeBevel.space(2)) {
                    Button(action: actionHandler) {
                        Text(action)
                            .font(TapeFace.font(.headline))
                            .foregroundStyle(TapeInk.background)
                            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                            .background(TapeInk.accent)
                            .clipShape(TapeBevel.cardShape)
                            .contentShape(TapeBevel.cardShape)
                    }
                    .buttonStyle(TapePress())
                    footer
                }
            }
        }
    }

    private func pageFill(stacked: Bool) -> some View {
        Group {
            if stacked {
                VStack(spacing: TapeBevel.space(2)) {
                    TapeHeroArt(name: art)
                    copyColumn(leading: false)
                }
            } else {
                HStack(alignment: .top, spacing: TapeBevel.space(2)) {
                    TapeHeroArt(name: art)
                    copyColumn(leading: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageScroll: some View {
        ScrollView {
            VStack(spacing: TapeBevel.space(2)) {
                TapeHeroArt(name: art)
                    .frame(height: 220)
                copyColumn(leading: false)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func copyColumn(leading: Bool) -> some View {
        let textAlign: TextAlignment = leading ? .leading : .center
        let frameAlign: Alignment = leading ? .leading : .center
        return VStack(alignment: leading ? .leading : .center, spacing: TapeBevel.space(1)) {
            Text(TapeFace.aired(title, step: .title))
                .foregroundStyle(TapeInk.ink)
                .multilineTextAlignment(textAlign)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlign)
            Text(TapeFace.aired(line, step: .body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(textAlign)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlign)
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, alignment: frameAlign)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }
}

extension TapeVacant where Footer == EmptyView {
    init(art: String, title: String, line: String, action: String, actionHandler: @escaping () -> Void) {
        self.init(
            art: art,
            title: title,
            line: line,
            action: action,
            actionHandler: actionHandler,
            footer: { EmptyView() }
        )
    }
}
