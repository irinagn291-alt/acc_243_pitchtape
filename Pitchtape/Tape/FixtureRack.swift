import SwiftUI

/// Role: Tape. Matches scene. Empty, populated, and error. Fixtures, not a post-game sheet.
@MainActor
struct FixtureRack: View {
    @Bindable var desk: BoothDesk
    var startKickoff: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let _ = desk.dayAnchor
        Group {
            if let fault = desk.fault, desk.fixtures.isEmpty {
                errorPage(fault)
            } else if desk.fixtures.isEmpty {
                emptyPage
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TapeInk.background)
    }

    private var emptyPage: some View {
        TapeVacant(
            art: TapeArt.emptyList,
            title: "No fixtures yet.",
            line: "Start a match so the live tape has a home and an away.",
            action: "Start a match",
            actionHandler: startKickoff
        )
        .padding(TapeBevel.space(2))
    }

    private func errorPage(_ line: String) -> some View {
        VStack(spacing: TapeBevel.space(2)) {
            Text("Matches could not load.")
                .font(TapeFace.font(.title))
                .foregroundStyle(TapeInk.ink)
            Text(line)
                .font(TapeFace.font(.body))
                .foregroundStyle(TapeInk.muted)
                .multilineTextAlignment(.center)
            Button {
                Task { await desk.load() }
            } label: {
                Text("Retry")
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.background)
                    .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                    .background(TapeInk.accent)
                    .clipShape(TapeBevel.cardShape)
                    .contentShape(TapeBevel.cardShape)
            }
            .buttonStyle(TapePress())
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        Group {
            if sizeClass == .regular {
                GeometryReader { geo in
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 280), spacing: TapeBevel.space(2))],
                            spacing: TapeBevel.space(2)
                        ) {
                            ForEach(desk.fixtures) { match in
                                Button {
                                    desk.resume(match)
                                } label: {
                                    row(match)
                                }
                                .buttonStyle(TapePress())
                            }
                        }
                        .padding(TapeBevel.space(2))
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
                    }
                    .scrollIndicators(.visible)
                    .scrollBounceBehavior(.basedOnSize)
                }
            } else {
                List {
                    ForEach(desk.fixtures) { match in
                        Button {
                            desk.resume(match)
                        } label: {
                            row(match)
                        }
                        .buttonStyle(TapePress())
                        .listRowInsets(EdgeInsets(
                            top: TapeBevel.space(1),
                            leading: TapeBevel.space(2),
                            bottom: TapeBevel.space(1),
                            trailing: TapeBevel.space(2)
                        ))
                        .listRowBackground(TapeInk.background)
                        .listRowSeparatorTint(TapeInk.muted.opacity(0.4))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(TapeInk.background)
                .contentMargins(.bottom, TapeBevel.space(3))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TapeDock {
                Button(action: startKickoff) {
                    Text("Start a match")
                        .font(TapeFace.font(.headline))
                        .foregroundStyle(TapeInk.background)
                        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                        .background(TapeInk.accent)
                        .clipShape(TapeBevel.cardShape)
                        .contentShape(TapeBevel.cardShape)
                }
                .buttonStyle(TapePress())
            }
        }
    }

    private func row(_ match: FixtureMatch) -> some View {
        let board = TapeFold.fixture(match, now: Date())
        return VStack(alignment: .leading, spacing: TapeBevel.space(1)) {
            HStack {
                Text(match.homeName)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
                Spacer(minLength: TapeBevel.space(1))
                Text("\(TapeStamp.count(board.homeGoals))–\(TapeStamp.count(board.awayGoals))")
                    .font(TapeFace.font(.title))
                    .foregroundStyle(TapeInk.accent)
                    .layoutPriority(1)
                Spacer(minLength: TapeBevel.space(1))
                Text(match.awayName)
                    .font(TapeFace.font(.headline))
                    .foregroundStyle(TapeInk.ink)
                    .lineLimit(1)
            }
            HStack {
                Text(TapeStamp.day(match.kickoffDay))
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(1)
                Spacer(minLength: TapeBevel.space(1))
                Text(TapeCopy.sport(match.sport))
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.muted)
                    .lineLimit(1)
                Text(match.openTape == nil ? "Parked" : "Open tape")
                    .font(TapeFace.font(.caption))
                    .foregroundStyle(TapeInk.accent)
                    .lineLimit(1)
            }
        }
        .padding(TapeBevel.space(2))
        .frame(maxWidth: .infinity, minHeight: TapeBevel.tap, alignment: .leading)
        .background(TapeBevel.plate(TapeBevel.cardShape))
        .contentShape(TapeBevel.cardShape)
        .accessibilityLabel("\(match.homeName) versus \(match.awayName)")
        .accessibilityHint("Resume this fixture on the live board")
    }
}

/// Role: Tape. Names and sport for a new running tape.
@MainActor
struct KickoffSheet: View {
    @Bindable var desk: BoothDesk
    @State var home: String = ""
    @State var away: String = ""
    @State var sport: SportPattern
    @FocusState private var focus: Field?
    @Environment(\.dismiss) private var dismiss

    private enum Field: Hashable {
        case home
        case away
    }

    private var canStart: Bool {
        !desk.isBusy
            && !home.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !away.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sides") {
                    TextField("Home", text: $home)
                        .font(TapeFace.font(.body))
                        .focused($focus, equals: .home)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .onSubmit { focus = .away }
                    TextField("Away", text: $away)
                        .font(TapeFace.font(.body))
                        .focused($focus, equals: .away)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }
                Section("Sport") {
                    Picker("Sport", selection: $sport) {
                        ForEach(SportPattern.allCases, id: \.self) { pattern in
                            Text(TapeCopy.sport(pattern)).tag(pattern)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .tint(TapeInk.accent)
            .navigationTitle("Start the clock")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TapeDock {
                    Button {
                        Task {
                            await desk.startFixture(home: home, away: away, sport: sport)
                            if desk.fault == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Start")
                            .font(TapeFace.font(.headline))
                            .foregroundStyle(TapeInk.background)
                            .frame(maxWidth: .infinity, minHeight: TapeBevel.tap)
                            .background(canStart ? TapeInk.accent : TapeInk.muted)
                            .clipShape(TapeBevel.cardShape)
                            .contentShape(TapeBevel.cardShape)
                    }
                    .buttonStyle(TapePress(enabled: canStart))
                    .disabled(!canStart)
                    .accessibilityLabel("Start the clock")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(TapeFace.font(.headline))
                        .frame(minWidth: TapeBevel.tap, minHeight: TapeBevel.tap)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Close kickoff")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            await desk.startFixture(home: home, away: away, sport: sport)
                            if desk.fault == nil {
                                dismiss()
                            }
                        }
                    }
                    .font(TapeFace.font(.headline))
                    .disabled(!canStart)
                    .frame(minWidth: TapeBevel.tap, minHeight: TapeBevel.tap)
                    .contentShape(Rectangle())
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }
                        .font(TapeFace.font(.headline))
                        .frame(minWidth: TapeBevel.tap, minHeight: TapeBevel.tap)
                        .accessibilityLabel("Dismiss keyboard")
                }
            }
        }
        .onTapGesture { focus = nil }
    }
}
