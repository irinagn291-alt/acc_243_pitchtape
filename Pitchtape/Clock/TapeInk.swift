import SwiftUI
import UIKit

/// Role: Clock. Named steel-blue tokens. Hex lives only on the asset catalog and here.
enum TapeInk {
    static let backgroundHex = "#2E1447"
    static let surfaceHex = "#4E306B"
    static let inkHex = "#FFF6FC"
    static let accentHex = "#982EFF"
    static let mutedHex = "#BD9EDB"

    static let background = Color("ptp_background")
    static let surface = Color("ptp_surface")
    static let ink = Color("ptp_ink")
    static let accent = Color("ptp_accent")
    static let muted = Color("ptp_muted")

    static var backgroundUI: UIColor { named("ptp_background", red: 46, green: 20, blue: 71) }
    static var surfaceUI: UIColor { named("ptp_surface", red: 78, green: 48, blue: 107) }
    static var inkUI: UIColor { named("ptp_ink", red: 255, green: 246, blue: 252) }
    static var accentUI: UIColor { named("ptp_accent", red: 152, green: 46, blue: 255) }
    static var mutedUI: UIColor { named("ptp_muted", red: 189, green: 158, blue: 219) }

    private static func named(_ name: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
