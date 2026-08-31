import Foundation

/// Role: Tape. Onboarding flag, sport default, demo key. Skip still writes these.
@MainActor
final class TapePrefs {
    static let demoKey = "ptp.demo.v1"
    static let onboardKey = "ptp.onboarded"
    static let sportKey = "ptp.sport"
    static let contactURL = URL(string: "https://zalupik-pupiuk.pro/contact-us")!

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var onboarded: Bool {
        get { defaults.bool(forKey: Self.onboardKey) }
        set { defaults.set(newValue, forKey: Self.onboardKey) }
    }

    var demoPlanted: Bool {
        get { defaults.bool(forKey: Self.demoKey) }
        set { defaults.set(newValue, forKey: Self.demoKey) }
    }

    var sport: SportPattern {
        get {
            SportPattern(rawValue: defaults.string(forKey: Self.sportKey) ?? "") ?? .pitch
        }
        set { defaults.set(newValue.rawValue, forKey: Self.sportKey) }
    }

    func writeDefaults(sport: SportPattern = .pitch) {
        self.sport = sport
        onboarded = true
    }

    func clearOnboarding() {
        onboarded = false
    }
}
