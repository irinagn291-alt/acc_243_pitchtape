import SwiftUI

/// Role: Whistle. Twist scene. Whistle parks the period; taps land on the open tape.
@MainActor
struct WhistleReel: View {
    @Bindable var desk: BoothDesk
    @Environment(\.horizontalSizeClass) private var sizeClass

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
        Group {
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: TapeBevel.space(2)) {
                    leadColumn
                    trailColumn
                }
                .padding(TapeBevel.space(2))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: TapeBevel.space(2)) {
                        TapeHeroArt(name: TapeArt.twistHero)
                            .frame(height: TapeBevel.space(22))
                        copyBlock
                        statPlate
                        parkedList
                    }
                    .padding(TapeBevel.space(2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.visible)
                .contentMargins(.bottom, TapeBevel.space(3))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TapeDock {
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
            }
        }
    }

    private var leadColumn: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(2)) {
            TapeHeroArt(name: TapeArt.twistHero)
            copyBlock
            statPlate
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var trailColumn: some View {
        ScrollView {
            parkedList
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            Text("Whistle-split tape")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text("A tap always writes a Call on the open tape. The whistle parks that period and opens the next empty tape. Undo peels only the last Call on the open period.")
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statPlate: some View {
        HStack(spacing: TapeBevel.space(2)) {
            stat("Open", desk.openPeriod == nil ? "None" : "Period \(TapeStamp.count(desk.openPeriod?.periodIndex ?? 0))")
            stat("Parked", TapeStamp.count(desk.parkedTapes.count))
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
    }

    @ViewBuilder
    private var parkedList: some View {
        if desk.parkedTapes.isEmpty {
            Text("No period has been whistled yet. The live board still holds the open tape.")
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: TapeBevel.space(1)) {
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
