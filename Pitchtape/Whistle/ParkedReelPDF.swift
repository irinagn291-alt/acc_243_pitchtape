import UIKit

/// Role: Whistle. Insights ink for parked tapes. UIGraphicsPDFRenderer, local only.
enum ParkedReelPDF {
    static func render(_ periods: [OpenPeriod]) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let face = UIFont(name: "DINAlternate-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        let body = UIFont(name: "DINAlternate-Bold", size: 12) ?? UIFont.systemFont(ofSize: 12)
        return renderer.pdfData { context in
            context.beginPage()
            var cursor: CGFloat = 48
            let parked = periods.filter { $0.phase == .parked }
            "Pitchtape parked tapes".draw(
                at: CGPoint(x: 48, y: cursor),
                withAttributes: [.font: face, .foregroundColor: UIColor.black]
            )
            cursor += 28
            if parked.isEmpty {
                "No parked tapes".draw(
                    at: CGPoint(x: 48, y: cursor),
                    withAttributes: [.font: body, .foregroundColor: UIColor.darkGray]
                )
                return
            }
            for period in parked {
                let line = "\(period.homeName) \(TapeFold.scoreText(period)) \(period.awayName)  \(TapeClock.display(period.accumulated))"
                line.draw(
                    at: CGPoint(x: 48, y: cursor),
                    withAttributes: [.font: body, .foregroundColor: UIColor.black]
                )
                cursor += 18
                for mark in period.calls.sorted(by: { $0.takeOrder < $1.takeOrder }) {
                    let hand = mark.hand.map { " \($0.name)" } ?? ""
                    let row = "  \(TapeClock.display(mark.clockAt))  \(mark.kind.rawValue)  \(mark.side.rawValue)\(hand)"
                    row.draw(
                        at: CGPoint(x: 48, y: cursor),
                        withAttributes: [.font: body, .foregroundColor: UIColor.darkGray]
                    )
                    cursor += 16
                    if cursor > 740 {
                        context.beginPage()
                        cursor = 48
                    }
                }
                cursor += 10
            }
        }
    }
}
