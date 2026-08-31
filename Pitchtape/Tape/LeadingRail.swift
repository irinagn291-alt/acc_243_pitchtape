import SwiftUI

/// Role: Tape. Leading drawer. Matches, Insights, and Settings open as separate scenes. No TabView.
@MainActor
struct LeadingRail: View {
    @Bindable var desk: BoothDesk

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: TapeBevel.space(2)) {
                    HStack {
                        Button {
                            desk.closeDrawer()
                        } label: {
                            HStack(spacing: TapeBevel.space(1)) {
                                Image(systemName: "xmark")
                                    .font(TapeFace.font(.headline))
                                Text("Drawer")
                                    .font(TapeFace.font(.title))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(TapeInk.ink)
                            .padding(.horizontal, TapeBevel.space(2))
                            .frame(minHeight: TapeBevel.tap)
                            .background(TapeBevel.plate(TapeBevel.chipShape))
                            .contentShape(TapeBevel.chipShape)
                        }
                        .buttonStyle(TapePress())
                        .accessibilityLabel("Close drawer")
                        Spacer(minLength: 0)
                    }
                    railButton("Matches", line: "Start or resume a fixture") {
                        desk.openScene(.rack)
                    }
                    railButton("Insights", line: "Parked tapes and PDF") {
                        desk.openScene(.reels)
                    }
                    railButton("Settings", line: "Contact, reset, onboarding") {
                        desk.openScene(.card)
                    }
                    railButton("Whistle-split", line: "Park the period, open the next tape") {
                        desk.openScene(.split)
                    }
                    Spacer(minLength: TapeBevel.space(2))
                }
                .padding(TapeBevel.space(2))
                .frame(width: min(geo.size.width * 0.82, 400), alignment: .leading)
                .frame(maxHeight: .infinity)
                .background(TapeInk.surface.ignoresSafeArea())
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(TapeInk.muted.opacity(0.45))
                        .frame(width: 1)
                }
                Color.black.opacity(0.45)
                    .contentShape(Rectangle())
                    .onTapGesture { desk.closeDrawer() }
                    .accessibilityLabel("Dismiss drawer")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func railButton(_ title: String, line: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
                Text(line)
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(2)
            }
            .padding(TapeBevel.space(2))
            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, alignment: .leading)
            .background(TapeBevel.plate(TapeBevel.cardShape))
            .contentShape(TapeBevel.cardShape)
        }
        .buttonStyle(TapePress())
        .accessibilityLabel(title)
        .accessibilityHint(line)
    }
}
