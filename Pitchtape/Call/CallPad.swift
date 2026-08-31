import SwiftUI

/// Role: Call. One-tap pad. Writes a Call on the open Running tape only.
@MainActor
struct CallPad: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        VStack(spacing: TapeBevel.space(1)) {
            HStack(spacing: TapeBevel.space(1)) {
                sideChip(.home)
                sideChip(.away)
            }
            HStack(spacing: TapeBevel.space(1)) {
                callKey(.goal)
                callKey(.foul)
            }
            HStack(spacing: TapeBevel.space(1)) {
                callKey(.card)
                callKey(.sub)
            }
            HStack(spacing: TapeBevel.space(1)) {
                verbKey("Undo", enabled: desk.canUndo, prominent: false) {
                    Task { await desk.undoLast() }
                }
                .accessibilityLabel("Undo last call on the open tape")
                verbKey("Whistle", enabled: desk.canWhistle, prominent: true) {
                    Task { await desk.blowWhistle() }
                }
                .accessibilityLabel("Whistle. Parks this period and opens the next tape")
            }
        }
    }

    private func sideChip(_ side: TapeSide) -> some View {
        let selected = desk.side == side
        return Button {
            desk.choose(side)
        } label: {
            Text(TapeCopy.side(side))
                .font(TapeFace.font(.headline))
                .foregroundStyle(selected ? TapeInk.background : TapeInk.ink)
                .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                .background(selected ? TapeInk.accent : TapeInk.surface)
                .clipShape(TapeBevel.chipShape)
                .overlay(TapeBevel.chipShape.strokeBorder(TapeInk.muted.opacity(0.55), lineWidth: 1))
                .contentShape(TapeBevel.chipShape)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel(TapeCopy.side(side))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func callKey(_ kind: CallKind) -> some View {
        let enabled = desk.canTap
        return Button {
            Task { await desk.tap(kind) }
        } label: {
            HStack(spacing: TapeBevel.space(1)) {
                if kind == .goal, TapeArt.present(TapeArt.controlFace) {
                    TapeArt.image(TapeArt.controlFace, fill: false)
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                }
                Text(TapeCopy.kind(kind))
                    .font(TapeFace.font(.headline))
                    .lineLimit(1)
            }
            .foregroundStyle(TapeInk.background)
            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
            .background(enabled ? TapeInk.accent : TapeInk.muted)
            .clipShape(TapeBevel.cardShape)
            .overlay(TapeBevel.cardShape.strokeBorder(TapeInk.ink.opacity(0.18), lineWidth: 1))
            .contentShape(TapeBevel.cardShape)
        }
        .buttonStyle(TapePress(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(TapeCopy.kind(kind))
        .accessibilityHint("Writes this call on the open tape")
    }

    private func verbKey(
        _ title: String,
        enabled: Bool,
        prominent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(TapeFace.font(.headline))
                .foregroundStyle(prominent ? TapeInk.background : TapeInk.ink)
                .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                .background(prominent ? (enabled ? TapeInk.accent : TapeInk.muted) : TapeInk.surface)
                .clipShape(TapeBevel.cardShape)
                .overlay(TapeBevel.cardShape.strokeBorder(TapeInk.muted.opacity(0.55), lineWidth: 1))
                .contentShape(TapeBevel.cardShape)
        }
        .buttonStyle(TapePress(enabled: enabled))
        .disabled(!enabled)
    }
}
