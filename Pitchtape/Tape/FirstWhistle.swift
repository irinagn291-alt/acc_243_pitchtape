import SwiftUI

/// Role: Tape. One-shot onboarding cover. Skip still writes sensible defaults.
@MainActor
struct FirstWhistle: View {
    var onFinish: (SportPattern) -> Void
    @State private var page = 0
    @State private var sport: SportPattern = .pitch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let pages: [(art: String, title: String, line: String)] = [
        (TapeArt.onboarding1, "Keep a sheet on the touchline.", "Tap live calls onto the running clock. This is not a betting board."),
        (TapeArt.onboarding2, "Tap the call. Do not fill a form.", "Goal, Foul, Card, and Sub land on the open tape at the live clock."),
        (TapeArt.onboarding3, "Blow the whistle to park the period.", "The parked tape seals. The next empty tape is already open."),
        (TapeArt.twistHero, "Matches hold fixtures. Insights hold parked tapes.", "Export parked tapes as PDF when the whistle work is done."),
    ]

    var body: some View {
        GeometryReader { geo in
            let stacked = sizeClass != .regular || geo.size.width < TapeBevel.stackBreak
            let item = pages[page]
            ViewThatFits(in: .vertical) {
                pageFill(item, stacked: stacked, width: geo.size.width)
                pageScroll(item)
            }
            .padding(TapeBevel.space(2))
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .id(page)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TapeDock {
                controls
            }
        }
    }

    private func pageFill(_ item: (art: String, title: String, line: String), stacked: Bool, width: CGFloat) -> some View {
        Group {
            if stacked {
                VStack(spacing: TapeBevel.space(2)) {
                    TapeHeroArt(name: item.art)
                    copyPlate(item, leading: false)
                }
            } else {
                HStack(alignment: .top, spacing: TapeBevel.space(2)) {
                    TapeHeroArt(name: item.art)
                    copyPlate(item, leading: true)
                        .frame(width: min(max(width * 0.34, 300), 440))
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pageScroll(_ item: (art: String, title: String, line: String)) -> some View {
        ScrollView {
            VStack(spacing: TapeBevel.space(2)) {
                TapeHeroArt(name: item.art)
                    .frame(height: 220)
                copyPlate(item, leading: false)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func copyPlate(_ item: (art: String, title: String, line: String), leading: Bool) -> some View {
        let textAlign: TextAlignment = leading ? .leading : .center
        let frameAlign: Alignment = leading ? .leading : .center
        return VStack(alignment: leading ? .leading : .center, spacing: TapeBevel.space(1)) {
            Text(TapeFace.aired(item.title, step: .title))
                .foregroundStyle(TapeInk.ink)
                .multilineTextAlignment(textAlign)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlign)
            Text(TapeFace.aired(item.line, step: .body))
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

    private var controls: some View {
        VStack(spacing: TapeBevel.space(2)) {
            if page == pages.count - 1 {
                VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
                    Text("Sport template")
                        .font(TapeFace.font(.caption))
                        .foregroundStyle(TapeInk.muted)
                    Picker("Sport", selection: $sport) {
                        ForEach(SportPattern.allCases, id: \.self) { pattern in
                            Text(TapeCopy.sport(pattern)).tag(pattern)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .frame(minHeight: TapeBevel.tap)
                    .accessibilityLabel("Sport template")
                }
            }
            dots
            Button {
                advance()
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start the clock")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.cardShape)
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
            .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Writes defaults and opens the live board")
            Button {
                onFinish(sport)
            } label: {
                Text("Skip")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeBevel.plate(TapeBevel.cardShape))
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
            .accessibilityLabel("Skip onboarding and write defaults")
        }
    }

    private var dots: some View {
        HStack(spacing: 0) {
            ForEach(0..<pages.count, id: \.self) { index in
                Button {
                    move(to: index)
                } label: {
                    Capsule()
                        .fill(index == page ? TapeInk.accent : TapeInk.muted)
                        .frame(width: index == page ? 22 : 10, height: 10)
                        .frame(width: TapeBevel.tap, height: TapeBevel.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Page \(TapeStamp.count(index + 1)) of \(TapeStamp.count(pages.count))")
                .accessibilityAddTraits(index == page ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func advance() {
        if page < pages.count - 1 {
            move(to: page + 1)
        } else {
            onFinish(sport)
        }
    }

    private func move(to index: Int) {
        if reduceMotion {
            page = index
        } else {
            withAnimation(TapeBevel.motion) { page = index }
        }
    }
}
