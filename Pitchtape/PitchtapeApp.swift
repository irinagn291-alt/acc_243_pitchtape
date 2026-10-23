import SwiftUI

@main
struct PitchtapeApp: App {
    @State private var launch: TapeLaunch

    init() {
        _launch = State(initialValue: TapeLaunch.open())
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .ready(let desk):
                ContentView(desk: desk)
            case .failed:
                ChestFaultBoard {
                    launch = TapeLaunch.open()
                }
            }
        }
    }
}
