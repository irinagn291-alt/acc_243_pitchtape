import Foundation
import SwiftData

/// Role: Call. SwiftData child. Inverse cascade lives on PeriodRecord.
@Model
final class CallRecord {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var clockAt: Double
    var sideRaw: String
    var takeOrder: Int
    var handID: UUID?
    var handName: String?
    var handShirt: Int
    var period: PeriodRecord?

    init(
        id: UUID,
        kindRaw: String,
        clockAt: Double,
        sideRaw: String,
        takeOrder: Int,
        handID: UUID?,
        handName: String?,
        handShirt: Int,
        period: PeriodRecord? = nil
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.clockAt = clockAt
        self.sideRaw = sideRaw
        self.takeOrder = takeOrder
        self.handID = handID
        self.handName = handName
        self.handShirt = handShirt
        self.period = period
    }

    convenience init(snapshot: CallMark, period: PeriodRecord? = nil) {
        self.init(
            id: snapshot.id,
            kindRaw: snapshot.kind.rawValue,
            clockAt: snapshot.clockAt,
            sideRaw: snapshot.side.rawValue,
            takeOrder: snapshot.takeOrder,
            handID: snapshot.hand?.id,
            handName: snapshot.hand?.name,
            handShirt: snapshot.hand?.shirt ?? 0,
            period: period
        )
    }

    func snapshot() throws -> CallMark {
        guard let kind = CallKind(rawValue: kindRaw) else { throw TapeFault.bentRow }
        guard let side = TapeSide(rawValue: sideRaw) else { throw TapeFault.bentRow }
        let hand: SheetHand?
        if let handID, let handName {
            hand = try SheetHand(id: handID, name: handName, shirt: handShirt)
        } else {
            hand = nil
        }
        return CallMark(
            id: id,
            kind: kind,
            clockAt: clockAt,
            side: side,
            takeOrder: takeOrder,
            hand: hand
        )
    }
}
