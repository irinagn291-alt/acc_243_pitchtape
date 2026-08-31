import SwiftUI
import UIKit

/// Role: Clock. Named steel-blue tokens. Hex lives only on the asset catalog and here.
enum TapeInk {
    static let backgroundHex = "#141C1F"
    static let surfaceHex = "#1C272B"
    static let inkHex = "#EDF1F2"
    static let accentHex = "#55C2E7"
    static let mutedHex = "#91A5AC"

    static let background = Color("ptp_background")
    static let surface = Color("ptp_surface")
    static let ink = Color("ptp_ink")
    static let accent = Color("ptp_accent")
    static let muted = Color("ptp_muted")

    static var backgroundUI: UIColor { named("ptp_background", red: 20, green: 28, blue: 31) }
    static var surfaceUI: UIColor { named("ptp_surface", red: 28, green: 39, blue: 43) }
    static var inkUI: UIColor { named("ptp_ink", red: 237, green: 241, blue: 242) }
    static var accentUI: UIColor { named("ptp_accent", red: 85, green: 194, blue: 231) }
    static var mutedUI: UIColor { named("ptp_muted", red: 145, green: 165, blue: 172) }

    private static func named(_ name: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
