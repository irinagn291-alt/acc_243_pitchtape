import SwiftUI

/// Role: Whistle. Twist scene. Whistle parks the period; taps land on the open tape.
@MainActor
struct WhistleReel: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        Group {
            if let fault = desk.fault, desk.parkedTapes.isEmpty, desk.openPeriod == nil {
                errorPage(fault)
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background)
    }

    private func errorPage(_ line: String) -> some View {
        VStack(spacing: TapeBevel.space(2)) {
            Text("Whistle-split could not load.")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text(line)
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(.center)
            Button {
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
        ScrollView {
            VStack(alignment: .leading, spacing: TapeBevel.space(2)) {
                TapeArt.image(TapeArt.twistHero, fill: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: TapeBevel.space(22))
                    .clipShape(TapeBevel.cardShape)
                    .accessibilityHidden(true)
                Text("Whistle-split tape")
                    .font(TapeFace.font(.title))
                    .foregroundStyle(TapeInk.ink)
                Text("A tap always writes a Call on the open tape. The whistle parks that period and opens the next empty tape. Undo peels only the last Call on the open period.")
                    .font(TapeFace.font(.body))
                    .foregroundStyle(TapeInk.muted)
                HStack(spacing: TapeBevel.space(2)) {
                    stat("Open", desk.openPeriod == nil ? "None" : "Period \(TapeStamp.count(desk.openPeriod?.periodIndex ?? 0))")
                    stat("Parked", TapeStamp.count(desk.parkedTapes.count))
                }
                .padding(TapeBevel.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TapeBevel.plate(TapeBevel.cardShape))
                if desk.parkedTapes.isEmpty {
                    Text("No period has been whistled yet. The live board still holds the open tape.")
                        .font(TapeFace.font(.body))
                        .foregroundStyle(TapeInk.muted)
                } else {
                    ForEach(desk.parkedTapes) { period in
                        Button {
                            desk.exportParked([period])
                        } label: {
                            markRow(period)
                        }
                        .buttonStyle(TapePress())
                        .accessibilityLabel("\(period.homeName) period \(TapeStamp.count(period.periodIndex))")
                        .accessibilityHint("Export this parked tape as PDF")
                    }
                }
            }
            .padding(TapeBevel.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.visible)
        .contentMargins(.bottom, TapeBevel.space(3))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                desk.closeScene()
            } label: {
                Text("Back to the live tape")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.cardShape)
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
            .padding(TapeBevel.space(2))
            .background(TapeInk.background.ignoresSafeArea(edges: .bottom))
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func markRow(_ period: OpenPeriod) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(period.homeName) · period \(TapeStamp.count(period.periodIndex))")
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
            Text("Whistled at \(TapeStamp.clock(period.accumulated)). Next tape opened empty.")
                .font(TapeFace.font(.caption))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(2)
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, alignment: .leading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
        .contentShape(TapeBevel.cardShape)
    }
}
