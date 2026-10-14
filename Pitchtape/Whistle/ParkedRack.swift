import SwiftUI

/// Role: Whistle. Insights. Parked tapes and PDF. ReviewScreen log.
@MainActor
struct ParkedRack: View {
    @Bindable var desk: BoothDesk
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let fault = desk.fault, desk.parkedTapes.isEmpty {
                errorPage(fault)
            } else if desk.parkedTapes.isEmpty {
                emptyPage
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background)
    }

    private var emptyPage: some View {
        TapeVacant(
            art: TapeArt.emptyList,
            title: "No parked tapes yet.",
            line: "Blow the whistle on the live board to seal a period.",
            action: "Back to the live tape"
        ) {
            desk.closeScene()
        }
        .padding(TapeBevel.space(2))
    }

    private func errorPage(_ line: String) -> some View {
        VStack(spacing: TapeBevel.space(2)) {
            Text("Insights could not load.")
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
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Parked tapes")
                            .font(TapeFace.font(.title))
                            .foregroundStyle(TapeInk.ink)
                        Text("Tap a tape to export it as PDF.")
                            .font(TapeFace.font(.body))
                            .foregroundStyle(TapeInk.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    tapeRack
                    if sizeClass == .regular {
                        boothReadout
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .padding(.horizontal, TapeBevel.space(2))
                .padding(.top, TapeBevel.space(1))
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
            }
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TapeDock {
                Button {
                    desk.exportParked()
                } label: {
                    Text("Export parked tapes")
                        .font(TapeFace.font(.headline))
                        .foregroundStyle(TapeInk.background)
                        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                        .background(TapeInk.accent)
                        .clipShape(TapeBevel.cardShape)
                        .contentShape(TapeBevel.cardShape)
                }
                .buttonStyle(TapePress(enabled: !desk.isBusy))
                .disabled(desk.isBusy)
                .accessibilityLabel("Export parked tapes as PDF")
            }
        }
    }

    @ViewBuilder
    private var tapeRack: some View {
        LazyVGrid(
            columns: sizeClass == .regular
                ? [GridItem(.adaptive(minimum: 280), spacing: TapeBevel.space(2))]
                : [GridItem(.flexible())],
            alignment: .leading,
            spacing: TapeBevel.space(2)
        ) {
            ForEach(desk.parkedTapes) { period in
                tapeButton(period)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var boothReadout: some View {
        let calls = desk.parkedTapes.reduce(0) { $0 + $1.calls.count }
        let last = desk.parkedTapes.max { $0.periodIndex < $1.periodIndex }
        return VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            Text("Booth tally")
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
            Text("Parked periods stay on this device. Tap a tape above to export one, or export the lot.")
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
            HStack(spacing: TapeBevel.space(2)) {
                readoutStat("Parked", TapeStamp.count(desk.parkedTapes.count))
                readoutStat("Calls", TapeStamp.count(calls))
                readoutStat("Last clock", last.map { TapeStamp.clock($0.accumulated) } ?? "—")
            }
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
        .accessibilityElement(children: .combine)
    }

    private func readoutStat(_ title: String, _ value: String) -> some View {
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

    private func tapeButton(_ period: OpenPeriod) -> some View {
        Button {
            desk.exportParked([period])
        } label: {
            tapeFace(period)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel(
            "\(period.homeName) \(TapeFold.scoreText(period)) \(period.awayName), period \(TapeStamp.count(period.periodIndex))"
        )
        .accessibilityHint("Export this parked tape as PDF")
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func tapeFace(_ period: OpenPeriod) -> some View {
        let pair = TapeFold.score(calls: period.calls)
        let marks = period.calls.sorted { $0.takeOrder < $1.takeOrder }
        return VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            HStack {
                Text(period.homeName)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
                Text("\(TapeStamp.count(pair.home))–\(TapeStamp.count(pair.away))")
                    .font(TapeFace.font(.title))
                    .foregroundStyle(TapeInk.accent)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(period.awayName)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            HStack {
                Text("Period \(TapeStamp.count(period.periodIndex))")
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(1)
                Text(TapeCopy.sport(period.sport))
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(1)
                Text(TapeStamp.clock(period.accumulated))
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(TapeStamp.count(marks.count) + " calls")
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if marks.isEmpty {
                Text("No calls on this tape.")
                    .font(TapeFace.font(.body))
                    .foregroundStyle(TapeInk.muted)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
                    ForEach(marks) { mark in
                        markRow(mark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
        .contentShape(TapeBevel.cardShape)
    }

    private func markRow(_ mark: CallMark) -> some View {
        HStack(spacing: TapeBevel.space(1)) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(TapeInk.accent)
                .frame(width: 4)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(TapeCopy.kind(mark.kind))
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.ink)
                .lineLimit(1)
            Text(TapeCopy.side(mark.side))
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .lineLimit(1)
            if let hand = mark.hand {
                Text("\(hand.name) \(TapeStamp.count(hand.shirt))")
                    .font(TapeFace.font(.body))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
            }
            Text(TapeStamp.clock(mark.clockAt))
                .font(TapeFace.font(.headline))
                .foregroundStyle(TapeInk.accent)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
