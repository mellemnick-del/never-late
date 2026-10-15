import Foundation

/// Deterministic random numbers so every player gets the same Daily Challenge run.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    // SplitMix64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Today's challenge, plus the player's daily record (stored on device).
enum Daily {
    /// Day 1 of the Daily Challenge.
    private static let firstDay = DateComponents(calendar: Calendar(identifier: .gregorian),
                                                 year: 2026, month: 11, day: 1).date!

    /// The challenge changes at local midnight, so everyone's "today" matches their own calendar.
    static func key(for date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Challenge number shown on share cards, like "Never Late #12".
    static func number(for date: Date = Date()) -> Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: firstDay),
                                      to: cal.startOfDay(for: date)).day ?? 0
        return max(1, days + 1)
    }

    static func seed(for date: Date = Date()) -> UInt64 {
        // FNV-1a over the date key: stable across devices and app versions.
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in key(for: date).utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01B3
        }
        return hash
    }

    // MARK: Record

    private static let defaults = UserDefaults.standard

    static var todaysScore: Int? {
        defaults.string(forKey: "dailyKey") == key() ? defaults.integer(forKey: "dailyScore") : nil
    }

    static var streak: Int {
        guard let last = defaults.string(forKey: "dailyKey") else { return 0 }
        let yesterday = key(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        return (last == key() || last == yesterday) ? defaults.integer(forKey: "dailyStreak") : 0
    }

    /// Records today's first attempt. Returns the updated streak.
    @discardableResult
    static func record(score: Int) -> Int {
        guard todaysScore == nil else { return streak }
        let newStreak = streak + 1
        defaults.set(key(), forKey: "dailyKey")
        defaults.set(score, forKey: "dailyScore")
        defaults.set(newStreak, forKey: "dailyStreak")
        return newStreak
    }
}
