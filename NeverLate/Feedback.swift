import UIKit
import AVFoundation

/// Haptics plus short synthesized tones. Sound uses the ambient category,
/// so it respects the silent switch and plays over music or radio.
@MainActor
final class Feedback {
    var soundOn = true

    private let tick = UIImpactFeedbackGenerator(style: .rigid)
    private let thump = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()
    private let tones = TonePlayer()

    func prepare() {
        tick.prepare()
        thump.prepare()
        notify.prepare()
    }

    func start() {
        tick.impactOccurred(intensity: 0.6)
        if soundOn { tones.play(.start) }
        prepare()
    }

    func hit(perfect: Bool) {
        if perfect {
            thump.impactOccurred()
        } else {
            tick.impactOccurred()
        }
        if soundOn { tones.play(perfect ? .perfect : .tick) }
        prepare()
    }

    func miss() {
        notify.notificationOccurred(.error)
        if soundOn { tones.play(.miss) }
    }
}

private final class TonePlayer {
    enum Sound: CaseIterable { case start, tick, perfect, miss }

    private enum Wave { case sine, square, saw }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        buffers[.start] = Self.tone(880, 0.08, .sine, 0.30, format)
        buffers[.tick] = Self.tone(1320, 0.05, .square, 0.10, format)
        buffers[.perfect] = Self.tone(1760, 0.07, .square, 0.12, format)
        buffers[.miss] = Self.tone(140, 0.35, .saw, 0.18, format)

        try? engine.start()
    }

    func play(_ sound: Sound) {
        guard let buffer = buffers[sound] else { return }
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private static func tone(_ freq: Double, _ duration: Double, _ wave: Wave, _ volume: Float,
                             _ format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) {
            let t = Double(i) / format.sampleRate
            let cycle = (t * freq).truncatingRemainder(dividingBy: 1)
            let sample: Double
            switch wave {
            case .sine: sample = sin(cycle * 2 * .pi)
            case .square: sample = cycle < 0.5 ? 1 : -1
            case .saw: sample = cycle * 2 - 1
            }
            let envelope = exp(-5 * t / duration)
            data[i] = Float(sample * envelope) * volume
        }
        return buffer
    }
}
