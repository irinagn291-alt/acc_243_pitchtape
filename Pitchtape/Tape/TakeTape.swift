import SwiftUI

/// Role: Tape. The only custom-drawn surface. TimelineView drives clock; Canvas draws Calls in take order.
@MainActor
struct TakeTape: View {
    var period: OpenPeriod?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                    reel(now: timeline.date)
                }
            } else {
                TimelineView(.animation) { timeline in
                    reel(now: timeline.date)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeBevel.plate(TapeBevel.cardShape))
        .clipShape(TapeBevel.cardShape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(period == nil ? "Empty take tape" : "Live take tape")
        .accessibilityValue(valueLine)
    }

    private var valueLine: String {
        guard let period else { return "No match yet" }
        let board = TapeFold.board(period, now: Date())
        return "\(TapeStamp.clock(board.clock)), \(TapeStamp.count(board.callCount)) calls"
    }

    private func reel(now: Date) -> some View {
        Canvas { context, size in
            drawReel(context: context, size: size, now: now)
        }
        .clipShape(TapeBevel.cardShape)
    }

    private func drawReel(context: GraphicsContext, size: CGSize, now: Date) {
        let ink = TapeInk.inkUI
        let accent = TapeInk.accentUI
        let muted = TapeInk.mutedUI
        let inset: CGFloat = 16
        let track = CGRect(
            x: inset,
            y: inset + 10,
            width: max(8, size.width - inset * 2),
            height: max(8, size.height - inset * 2 - 10)
        )
        drawSprockets(context: context, size: size, color: muted)

        var axis = Path()
        axis.move(to: CGPoint(x: track.minX, y: track.midY))
        axis.addLine(to: CGPoint(x: track.maxX, y: track.midY))
        context.stroke(axis, with: .color(Color(muted).opacity(0.7)), lineWidth: 1)

        guard let period else { return }
        let elapsed = period.clock(at: now)
        let span = max(elapsed, period.calls.map(\.clockAt).max() ?? 0, 1)
        let marks = period.calls.sorted { $0.takeOrder < $1.takeOrder }

        for mark in marks {
            let x = track.minX + CGFloat(mark.clockAt / span) * track.width
            let up = mark.side == .home
            let y1 = track.midY
            let y2 = up ? track.minY + 8 : track.maxY - 8
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: y1))
            tick.addLine(to: CGPoint(x: x, y: y2))
            context.stroke(tick, with: .color(Color(accent)), lineWidth: 2)
            let label = TapeCopy.kind(mark.kind)
            let resolved = context.resolve(
                Text(label)
                    .font(TapeFace.font(.caption))
                    .foregroundColor(Color(ink))
            )
            let textSize = resolved.measure(in: CGSize(width: 72, height: 20))
            let textOrigin = CGPoint(
                x: min(max(track.minX, x - textSize.width / 2), track.maxX - textSize.width),
                y: up ? y2 : y2 - textSize.height
            )
            context.draw(resolved, at: CGPoint(x: textOrigin.x, y: textOrigin.y), anchor: .topLeading)
        }

        let headX = track.minX + CGFloat(elapsed / span) * track.width
        var head = Path()
        head.move(to: CGPoint(x: headX, y: track.minY))
        head.addLine(to: CGPoint(x: headX, y: track.maxY))
        context.stroke(head, with: .color(Color(ink)), lineWidth: 1.5)
    }

    private func drawSprockets(context: GraphicsContext, size: CGSize, color: UIColor) {
        let pitch: CGFloat = 14
        var x: CGFloat = 10
        while x < size.width - 8 {
            let top = CGRect(x: x, y: 4, width: 5, height: 5)
            let bottom = CGRect(x: x, y: size.height - 9, width: 5, height: 5)
            context.fill(Path(ellipseIn: top), with: .color(Color(color).opacity(0.55)))
            context.fill(Path(ellipseIn: bottom), with: .color(Color(color).opacity(0.55)))
            x += pitch
        }
    }
}
