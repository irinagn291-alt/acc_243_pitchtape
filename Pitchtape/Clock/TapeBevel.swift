import SwiftUI
import UIKit

/// Role: Clock. Spacing, radii, hairline+fill elevation. Views never invent a second radius.
enum TapeBevel {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 10
    static let chipRadius: CGFloat = 8
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }

    static func plate<S: InsettableShape>(_ shape: S) -> some View {
        shape
            .fill(TapeInk.surface)
            .overlay(shape.strokeBorder(TapeInk.muted.opacity(0.55), lineWidth: 1))
    }
}

/// Role: Clock. Pressed and disabled are visibly different.
struct TapePress: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(enabled ? (configuration.isPressed ? 0.78 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && enabled ? 0.97 : 1)
            .animation(TapeBevel.motion, value: configuration.isPressed)
    }
}

/// Role: Clock. Geometric fallback when generated art is still empty.
struct TapeSlatTile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = max(8, min(rect.width, rect.height) / 10)
        guard step > 0 else { return path }
        var y = rect.minY
        while y < rect.maxY {
            path.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: step * 0.22))
            y += step
        }
        var x = rect.minX + step * 0.4
        while x < rect.maxX {
            path.addEllipse(in: CGRect(x: x - 2, y: rect.minY + 4, width: 4, height: 4))
            path.addEllipse(in: CGRect(x: x - 2, y: rect.maxY - 8, width: 4, height: 4))
            x += step
        }
        return path
    }
}

struct TapeTile: View {
    var body: some View {
        ZStack {
            TapeInk.surface
            TapeSlatTile()
                .stroke(TapeInk.muted.opacity(0.5), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

enum TapeArt {
    static let emptyHome = "ptp_EmptyHome"
    static let emptyList = "ptp_EmptyList"
    static let cardBackdrop = "ptp_CardBackdrop"
    static let controlFace = "ptp_ControlFace"
    static let twistHero = "ptp_TwistHero"
    static let successMark = "ptp_SuccessMark"
    static let headerDecor = "ptp_HeaderDecor"
    static let onboarding1 = "ptp_Onboarding1"
    static let onboarding2 = "ptp_Onboarding2"
    static let onboarding3 = "ptp_Onboarding3"

    static func present(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }

    @ViewBuilder
    static func image(_ name: String, fill: Bool = true) -> some View {
        if present(name) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: fill ? .fill : .fit)
                .background(TapeInk.surface)
        } else {
            TapeTile()
        }
    }
}

/// Role: Clock. Local PDF share. No remote catalog.
struct TapeShareBoard: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            try? Data().write(to: url)
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
        {
            controller.popoverPresentationController?.sourceView = root
            controller.popoverPresentationController?.sourceRect = CGRect(
                x: root.bounds.midX,
                y: root.bounds.midY,
                width: 1,
                height: 1
            )
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
