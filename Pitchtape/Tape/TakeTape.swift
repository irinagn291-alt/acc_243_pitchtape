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
            x: inset + 52,
            y: inset + 18,
            width: max(8, size.width - inset * 2 - 52),
            height: max(8, size.height - inset * 2 - 18)
        )
        drawSprockets(context: context, size: size, color: muted)

        let homeLane = CGRect(x: track.minX, y: track.minY, width: track.width, height: track.height / 2)
        let awayLane = CGRect(x: track.minX, y: track.midY, width: track.width, height: track.height / 2)
        context.fill(Path(homeLane), with: .color(Color(accent).opacity(0.06)))
        context.fill(Path(awayLane), with: .color(Color(muted).opacity(0.08)))

        drawLaneLabel(context: context, title: "HOME", at: CGPoint(x: 28, y: homeLane.midY), color: ink)
        drawLaneLabel(context: context, title: "AWAY", at: CGPoint(x: 28, y: awayLane.midY), color: muted)

        var axis = Path()
        axis.move(to: CGPoint(x: track.minX, y: track.midY))
        axis.addLine(to: CGPoint(x: track.maxX, y: track.midY))
        context.stroke(axis, with: .color(Color(muted).opacity(0.7)), lineWidth: 1)

        let elapsed = period?.clock(at: now) ?? 0
        let span = max(elapsed, period?.calls.map(\.clockAt).max() ?? 0, 1)
        drawTimeRail(context: context, track: track, span: span, color: muted)

        guard let period else { return }
        let marks = period.calls.sorted { $0.takeOrder < $1.takeOrder }

        for mark in marks {
            let x = track.minX + CGFloat(mark.clockAt / span) * track.width
            let up = mark.side == .home
            let y1 = track.midY
            let y2 = up ? track.minY + 10 : track.maxY - 10
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: y1))
            tick.addLine(to: CGPoint(x: x, y: y2))
            context.stroke(tick, with: .color(Color(accent)), lineWidth: 2)
            let label = "\(TapeCopy.kind(mark.kind)) \(TapeStamp.clock(mark.clockAt))"
            let resolved = context.resolve(
                Text(label)
                    .font(TapeFace.font(.caption))
                    .foregroundColor(Color(ink))
            )
            let textSize = resolved.measure(in: CGSize(width: 120, height: 20))
            let labelX = min(max(track.minX + 4, x - textSize.width / 2), track.maxX - textSize.width - 4)
            let labelY = up ? y2 : y2 - textSize.height
            context.draw(resolved, at: CGPoint(x: labelX, y: labelY), anchor: .topLeading)
        }

        let headX = track.minX + CGFloat(elapsed / span) * track.width
        var head = Path()
        head.move(to: CGPoint(x: headX, y: track.minY))
        head.addLine(to: CGPoint(x: headX, y: track.maxY))
        context.stroke(head, with: .color(Color(ink)), lineWidth: 1.5)

        let clock = context.resolve(
            Text(TapeStamp.clock(elapsed))
                .font(TapeFace.font(.headline))
                .foregroundColor(Color(accent))
        )
        context.draw(clock, at: CGPoint(x: track.maxX - 4, y: 6), anchor: .topTrailing)
    }

    private func drawLaneLabel(context: GraphicsContext, title: String, at point: CGPoint, color: UIColor) {
        let resolved = context.resolve(
            Text(title)
                .font(TapeFace.font(.caption))
                .foregroundColor(Color(color).opacity(0.7))
        )
        context.draw(resolved, at: point, anchor: .center)
    }

    private func drawTimeRail(context: GraphicsContext, track: CGRect, span: TimeInterval, color: UIColor) {
        let steps = 4
        for index in 0...steps {
            let fraction = CGFloat(index) / CGFloat(steps)
            let x = track.minX + fraction * track.width
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: track.midY - 6))
            tick.addLine(to: CGPoint(x: x, y: track.midY + 6))
            context.stroke(tick, with: .color(Color(color).opacity(0.45)), lineWidth: 1)
            let stamp = context.resolve(
                Text(TapeStamp.clock(span * Double(index) / Double(steps)))
                    .font(TapeFace.font(.caption))
                    .foregroundColor(Color(color))
            )
            context.draw(stamp, at: CGPoint(x: x, y: track.maxY - 2), anchor: .bottom)
        }
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
