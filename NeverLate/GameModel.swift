import SwiftUI
import QuartzCore

/// All game state and rules. Angles are in radians, 0 at 12 o'clock, increasing clockwise.
@MainActor
@Observable
final class GameModel {
    enum State { case ready, playing, paused, over }

    enum Mode: String {
        case classic, daily
    }

    enum Phase: Int {
        case steady = 1, reverse, drift

        static func forHits(_ hits: Int) -> Phase {
            hits >= 15 ? .drift : hits >= 8 ? .reverse : .steady
        }

        var title: String {
            switch self {
            case .steady: "1 · STEADY"
            case .reverse: "2 · REVERSE"
            case .drift: "3 · DRIFT"
            }
        }
    }

    // Tuning
    static let startSpeed = 2.2        // rad/s, about one sweep every 2.9s
    static let maxSpeed = 6.0
    static let speedStep = 0.09
    static let startHalfWidth = 0.30   // half the target arc, in radians
    static let minHalfWidth = 0.11
    static let shrink = 0.96
    static let perfectFraction = 0.3   // inner part of the target that scores double

    private(set) var state: State = .ready
    private(set) var score = 0
    private(set) var hits = 0
    private(set) var best: Int
    private(set) var isNewBest = false
    private(set) var showCard = true

    /// Classic is endless random runs. Daily is the same seeded run for everyone, one scored try per day.
    var mode: Mode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "mode")
            refreshDaily()
        }
    }
    /// True when this Daily run is a replay after today's scored attempt.
    private(set) var isPractice = false
    private(set) var dailyScore: Int?
    private(set) var dailyStreak = 0
    private(set) var dailyNumber = Daily.number()
    /// What the finished run was, for the game over card and share card.
    private(set) var lastRunMode: Mode = .classic
    private(set) var lastRunScored = true

    private(set) var angle = 0.0
    private(set) var direction = 1.0
    private(set) var speed = GameModel.startSpeed
    /// Remaining travel (in the hand's direction) until the hand reaches the target center.
    private(set) var distance = 2.4
    private(set) var halfWidth = GameModel.startHalfWidth
    private(set) var drift = 0.0

    private(set) var flash = 0.0
    private(set) var flashText = ""
    private(set) var flashPerfect = false
    private(set) var shake = 0.0

    var soundOn: Bool {
        didSet {
            feedback.soundOn = soundOn
            UserDefaults.standard.set(soundOn, forKey: "soundOn")
        }
    }

    var phase: Phase { .forHits(hits) }
    var targetAngle: Double { angle + direction * distance }

    @ObservationIgnored private let feedback = Feedback()
    @ObservationIgnored private var displayLink: CADisplayLink?
    @ObservationIgnored private var lastTimestamp: CFTimeInterval = 0
    @ObservationIgnored private var lockUntil: CFTimeInterval = 0
    @ObservationIgnored private var rng = SeededGenerator(seed: UInt64.random(in: 0...UInt64.max))
    @ObservationIgnored private var perfectStreak = 0

    init() {
        let defaults = UserDefaults.standard
        best = defaults.integer(forKey: "bestScore")
        soundOn = defaults.object(forKey: "soundOn") as? Bool ?? true
        mode = Mode(rawValue: defaults.string(forKey: "mode") ?? "") ?? .classic
        feedback.soundOn = soundOn
        refreshDaily()
    }

    /// Re-reads today's Daily record (it changes at midnight and after a scored run).
    func refreshDaily() {
        dailyScore = Daily.todaysScore
        dailyStreak = Daily.streak
        dailyNumber = Daily.number()
    }

    // MARK: Loop

    func startLoop() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: DisplayLinkTarget(self), selector: #selector(DisplayLinkTarget.step(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTimestamp = 0
        feedback.prepare()
        refreshDaily()
    }

    func stopLoop() {
        displayLink?.invalidate()
        displayLink = nil
        if state == .playing {
            state = .paused
            showCard = true
        }
    }

    fileprivate func step(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = lastTimestamp == 0 ? 0 : min(0.05, now - lastTimestamp)
        lastTimestamp = now
        update(dt)
    }

    private func update(_ dt: Double) {
        switch state {
        case .playing:
            angle += direction * speed * dt
            distance += (drift - speed) * dt
            if distance < -halfWidth { miss() }
        case .ready:
            angle += 1.0 * dt  // idle sweep on the title screen
        case .paused, .over:
            break
        }
        angle = angle.truncatingRemainder(dividingBy: .pi * 2)
        if angle < 0 { angle += .pi * 2 }
        if flash > 0 { flash = max(0, flash - dt * 1.6) }
        if shake > 0 { shake = max(0, shake - dt * 2.5) }
    }

    // MARK: Input

    func tap() {
        switch state {
        case .playing:
            abs(distance) <= halfWidth ? hit() : miss()
        case .paused:
            state = .playing
            showCard = false
            lastTimestamp = 0
        case .ready, .over:
            if CACurrentMediaTime() > lockUntil { start() }
        }
    }

    // MARK: Rules

    private func start() {
        refreshDaily()
        if mode == .daily {
            rng = SeededGenerator(seed: Daily.seed())
            isPractice = dailyScore != nil
        } else {
            rng = SeededGenerator(seed: UInt64.random(in: 0...UInt64.max))
            isPractice = false
        }
        perfectStreak = 0
        state = .playing
        score = 0
        hits = 0
        direction = 1
        speed = Self.startSpeed
        halfWidth = Self.startHalfWidth
        drift = 0
        flash = 0
        shake = 0
        isNewBest = false
        showCard = false
        spawnTarget()
        feedback.start()
    }

    private func spawnTarget() {
        distance = .pi * Double.random(in: 0.55...1.55, using: &rng)
    }

    private func hit() {
        let perfect = abs(distance) <= halfWidth * Self.perfectFraction
        hits += 1
        score += perfect ? 2 : 1
        speed = min(Self.maxSpeed, speed + Self.speedStep)
        halfWidth = max(Self.minHalfWidth, halfWidth * Self.shrink)

        let phase = self.phase
        // Always draw the same numbers in the same order so Daily runs match for everyone.
        let flip = Bool.random(using: &rng)
        let driftSign: Double = Bool.random(using: &rng) ? -1 : 1
        let driftSpeed = Double.random(in: 0.3...0.75, using: &rng)
        if phase.rawValue >= Phase.reverse.rawValue && flip { direction *= -1 }
        drift = phase == .drift ? driftSign * driftSpeed : 0
        spawnTarget()

        perfectStreak = perfect ? perfectStreak + 1 : 0
        if perfect { GameCenter.unlock(.firstPerfect) }
        if perfectStreak >= 5 { GameCenter.unlock(.perfectStreak5) }
        if hits == 8 { GameCenter.unlock(.reachReverse) }
        if hits == 15 { GameCenter.unlock(.reachDrift) }

        flash = 1
        flashPerfect = perfect
        flashText = perfect ? "PERFECT +2" : "+1"
        feedback.hit(perfect: perfect)
    }

    private func miss() {
        state = .over
        shake = 1
        lockUntil = CACurrentMediaTime() + 0.65
        lastRunMode = mode
        lastRunScored = !isPractice
        switch mode {
        case .classic:
            if score > best {
                best = score
                isNewBest = true
                UserDefaults.standard.set(best, forKey: "bestScore")
            }
            GameCenter.submit(score: score, daily: false)
        case .daily where !isPractice:
            let streak = Daily.record(score: score)
            refreshDaily()
            GameCenter.submit(score: score, daily: true)
            if streak >= 7 { GameCenter.unlock(.dailyStreak7) }
        case .daily:
            break
        }
        if score >= 25 { GameCenter.unlock(.score25) }
        if score >= 50 { GameCenter.unlock(.score50) }
        if score >= 100 { GameCenter.unlock(.score100) }
        feedback.miss()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            if self?.state == .over { self?.showCard = true }
        }
    }
}

/// CADisplayLink retains its target, so this small proxy keeps the model from leaking.
@MainActor
private final class DisplayLinkTarget: NSObject {
    weak var model: GameModel?
    init(_ model: GameModel) { self.model = model }
    @objc func step(_ link: CADisplayLink) { model?.step(link) }
}
