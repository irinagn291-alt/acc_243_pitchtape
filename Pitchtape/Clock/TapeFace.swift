import SwiftUI
import UIKit

/// Role: Clock. DIN Alternate only. Six Dynamic Type steps via UIFont, never Font.custom.
enum TapeFace {
    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case callout
        case caption
    }

    static func font(_ step: Step) -> Font {
        Font(uiFont(step))
    }

    static func uiFont(_ step: Step) -> UIFont {
        let style = textStyle(step)
        let pointSize = UIFont.preferredFont(forTextStyle: style).pointSize
        let base = UIFont(name: "DINAlternate-Bold", size: pointSize) ?? UIFont.preferredFont(forTextStyle: style)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    private static func textStyle(_ step: Step) -> UIFont.TextStyle {
        switch step {
        case .display: return .largeTitle
        case .title: return .title2
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .caption: return .caption1
        }
    }
}

/// Role: Clock. Locale-aware stamps. Numbers go through NumberFormatter.
enum TapeStamp {
    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func clock(_ seconds: TimeInterval) -> String {
        TapeClock.display(seconds)
    }

    static func count(_ value: Int) -> String {
        TapeClock.wholeNumber(value)
    }
}

/// Role: Clock. User-facing labels. Axis values never appear here.
enum TapeCopy {
    static func kind(_ kind: CallKind) -> String {
        switch kind {
        case .goal: return "Goal"
        case .foul: return "Foul"
        case .card: return "Card"
        case .sub: return "Sub"
        }
    }

    static func side(_ side: TapeSide) -> String {
        switch side {
        case .home: return "Home"
        case .away: return "Away"
        }
    }

    static func sport(_ sport: SportPattern) -> String {
        switch sport {
        case .pitch: return "Pitch"
        case .ice: return "Ice"
        case .court: return "Court"
        }
    }

    static func sportLine(_ sport: SportPattern) -> String {
        switch sport {
        case .pitch: return "Next kickoff opens a pitch tape."
        case .ice: return "Next kickoff opens an ice tape."
        case .court: return "Next kickoff opens a court tape."
        }
    }

    static func fault(_ error: Error) -> String {
        if let whistle = error as? WhistleFault {
            switch whistle {
            case .blankSide: return "Home and away both need a name."
            case .blankHand: return "That player name is blank."
            case .noOpenTape: return "There is no open tape."
            case .tapeParked: return "That tape is already parked."
            case .tapeEmpty: return "The open tape has no call to peel."
            case .alreadyParked: return "The whistle already sealed this period."
            }
        }
        if let tape = error as? TapeFault {
            switch tape {
            case .containerFailed: return "The tape chest could not open."
            case .saveFailed: return "The last write did not reach disk."
            case .missingPeriod: return "That period is gone."
            case .bentRow: return "A stored row could not be read."
            }
        }
        return "The tape could not finish that write."
    }
}
