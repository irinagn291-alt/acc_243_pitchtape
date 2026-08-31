import SwiftUI

/// Role: Tape. Host. The ON-AIR board stays mounted. Drawer and covers sit above it.
struct ContentView: View {
    @Bindable var desk: BoothDesk
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase

    init(desk: BoothDesk, handlesLaunch: Bool = true) {
        self.desk = desk
        self.handlesLaunch = handlesLaunch
    }

    var body: some View {
        ConsoleBoard(desk: desk)
            .tint(TapeInk.accent)
            .preferredColorScheme(.dark)
            .task {
                guard handlesLaunch else { return }
                await desk.bootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                guard handlesLaunch else { return }
                if phase == .active {
                    desk.refreshDayAnchor()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                desk.refreshDayAnchor()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                desk.refreshDayAnchor()
            }
    }
}
