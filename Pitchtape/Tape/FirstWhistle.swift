import SwiftUI

/// Role: Tape. One-shot onboarding cover. Skip still writes sensible defaults.
@MainActor
struct FirstWhistle: View {
    var onFinish: (SportPattern) -> Void
    @State private var page = 0
    @State private var sport: SportPattern = .pitch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(art: String, title: String, line: String)] = [
        (TapeArt.onboarding1, "Keep a sheet on the touchline.", "Tap live calls onto the running clock. This is not a betting board."),
        (TapeArt.onboarding2, "Tap the call. Do not fill a form.", "Goal, Foul, Card, and Sub land on the open tape at the live clock."),
        (TapeArt.onboarding3, "Blow the whistle to park the period.", "The parked tape seals. The next empty tape is already open."),
        (TapeArt.twistHero, "Matches hold fixtures. Insights hold parked tapes.", "Export parked tapes as PDF when the whistle work is done."),
    ]

    var body: some View {
        VStack(spacing: TapeBevel.space(2)) {
            pageView(pages[page])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(page)
            if page == pages.count - 1 {
                Picker("Sport", selection: $sport) {
                    ForEach(SportPattern.allCases, id: \.self) { pattern in
                        Text(TapeCopy.sport(pattern)).tag(pattern)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: TapeBevel.tap)
                .accessibilityLabel("Sport template")
            }
            dots
            Button {
                if page < pages.count - 1 {
                    if reduceMotion {
                        page += 1
                    } else {
                        withAnimation(TapeBevel.motion) { page += 1 }
                    }
                } else {
                    onFinish(sport)
                }
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
            Button {
                onFinish(sport)
            } label: {
                Text("Skip")
                    .font(TapeFace.font(.body))
                    .foregroundStyle(TapeInk.muted)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip onboarding and write defaults")
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background.ignoresSafeArea())
    }

    private func pageView(_ item: (art: String, title: String, line: String)) -> some View {
        VStack(spacing: TapeBevel.space(2)) {
            TapeArt.image(item.art)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipShape(TapeBevel.cardShape)
                .accessibilityHidden(true)
            Text(item.title)
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
                .multilineTextAlignment(.center)
            Text(item.line)
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dots: some View {
        HStack(spacing: TapeBevel.space(1)) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? TapeInk.accent : TapeInk.muted)
                    .frame(width: index == page ? 18 : 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: TapeBevel.tap / 2)
    }
}
