import AVFoundation
import UIKit

/// Premium game audio via FM synthesis.
///
/// FM (Frequency Modulation) synthesis creates rich, bell-like timbres
/// that simple additive synthesis can't achieve. A modulator oscillator
/// modulates the frequency of a carrier, creating complex sidebands.
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundType: AVAudioPlayer] = [:]
    private let sampleRate: Double = 44100

    enum SoundType {
        case tap, correctTap, wrongTap, success, combo, lifeLost, gameOver
    }

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }

        players[.tap] = generateTap()
        players[.correctTap] = generateCorrectTap()
        players[.wrongTap] = generateWrongTap()
        players[.success] = generateSuccess()
        players[.combo] = generateCombo()
        players[.lifeLost] = generateLifeLost()
        players[.gameOver] = generateGameOver()
    }

    // MARK: - Public API

    func playTap()        { play(.tap) }
    func playCorrectTap() { play(.correctTap) }
    func playWrongTap()   { play(.wrongTap) }
    func playSuccess()    { play(.success) }
    func playError()      { play(.wrongTap) }
    func playCombo()      { play(.combo) }
    func playLifeLost()   { play(.lifeLost) }
    func playGameOver()   { play(.gameOver) }

    private func play(_ type: SoundType) {
        guard SettingsManager.shared.soundEnabled else { return }
        guard let player = players[type] else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: - FM Synthesis Core

    /// FM synthesis: carrier frequency modulated by modulator.
    /// Creates bell-like, metallic, or percussive timbres depending on parameters.
    private func fmSample(
        t: Double,
        carrierFreq: Double,
        modFreq: Double,
        modIndex: Double,
        envelope: Double
    ) -> Double {
        let modulator = sin(2.0 * .pi * modFreq * t) * modIndex
        return sin(2.0 * .pi * carrierFreq * t + modulator) * envelope
    }

    /// Percussive envelope: instant attack, controlled decay.
    private func percEnvelope(t: Double, attack: Double = 0.003, decay: Double) -> Double {
        if t < attack {
            return t / attack
        }
        return exp(-(t - attack) / decay * 3.0)
    }

    /// Two-stage envelope for multi-note sounds.
    private func noteEnvelope(t: Double, attack: Double = 0.005, hold: Double, release: Double) -> Double {
        if t < attack {
            return t / attack
        } else if t < attack + hold {
            return 1.0
        } else {
            return exp(-(t - attack - hold) / release * 3.0)
        }
    }

    // MARK: - Sound Designs

    /// Tap on any ball: crisp, short, tactile "tick"
    /// FM with high mod ratio → metallic click
    private func generateTap() -> AVAudioPlayer? {
        let duration = 0.06
        let samples = synthesize(duration: duration) { t in
            let env = self.percEnvelope(t: t, decay: 0.025)
            // High carrier, high ratio → crisp metallic tick
            let fm = self.fmSample(t: t, carrierFreq: 2200, modFreq: 4400, modIndex: 1.5 * env, envelope: env)
            // Tiny filtered click layer
            let click = t < 0.004 ? (1.0 - t / 0.004) * 0.3 : 0
            return (fm * 0.4 + click) * 0.35
        }
        return makePlayer(from: samples)
    }

    /// Correct match tap: bright, satisfying "pling" — bell-like FM
    private func generateCorrectTap() -> AVAudioPlayer? {
        let duration = 0.18
        let samples = synthesize(duration: duration) { t in
            let env = self.percEnvelope(t: t, decay: 0.08)
            // Bell-like: carrier:mod ratio near 1:1.4 (inharmonic = bell)
            let bell = self.fmSample(t: t, carrierFreq: 1318, modFreq: 1845, modIndex: 2.0 * env, envelope: env)
            // Bright shimmer layer
            let shimmer = self.fmSample(t: t, carrierFreq: 2636, modFreq: 3690, modIndex: 0.8 * env, envelope: env * 0.3)
            return (bell + shimmer) * 0.3
        }
        return makePlayer(from: samples)
    }

    /// Wrong tap: short dull thump — low FM, fast decay
    private func generateWrongTap() -> AVAudioPlayer? {
        let duration = 0.15
        let samples = synthesize(duration: duration) { t in
            let env = self.percEnvelope(t: t, decay: 0.05)
            // Low carrier, mod index drops fast → starts buzzy, ends clean
            let modIdx = 4.0 * exp(-t * 30)
            let thump = self.fmSample(t: t, carrierFreq: 150, modFreq: 210, modIndex: modIdx, envelope: env)
            // Sub bass
            let sub = sin(2.0 * .pi * 80 * t) * env * 0.4
            return (thump + sub) * 0.4
        }
        return makePlayer(from: samples)
    }

    /// Round success: ascending two-note chime, bell FM timbre
    private func generateSuccess() -> AVAudioPlayer? {
        let duration = 0.32
        let samples = synthesize(duration: duration) { t in
            // Note 1: E6 (1318Hz) at t=0
            // Note 2: A6 (1760Hz) at t=0.13 — perfect fourth up, bright and happy
            var out = 0.0

            // Note 1
            if t < 0.22 {
                let env1 = self.noteEnvelope(t: t, hold: 0.04, release: 0.06)
                out += self.fmSample(t: t, carrierFreq: 1318, modFreq: 1845, modIndex: 1.8 * env1, envelope: env1)
            }

            // Note 2
            if t >= 0.10 {
                let t2 = t - 0.10
                let env2 = self.noteEnvelope(t: t2, hold: 0.04, release: 0.08)
                out += self.fmSample(t: t2, carrierFreq: 1760, modFreq: 2464, modIndex: 1.5 * env2, envelope: env2)
            }

            return out * 0.28
        }
        return makePlayer(from: samples)
    }

    /// Combo streak: quick bright ascending sweep with FM shimmer
    private func generateCombo() -> AVAudioPlayer? {
        let duration = 0.14
        let samples = synthesize(duration: duration) { t in
            let env = self.percEnvelope(t: t, decay: 0.06)
            // Rising carrier frequency
            let freq = 1200.0 + (t / duration) * 1200.0
            let fm = self.fmSample(t: t, carrierFreq: freq, modFreq: freq * 1.5, modIndex: 1.2 * env, envelope: env)
            return fm * 0.25
        }
        return makePlayer(from: samples)
    }

    /// Life lost: descending minor third, gentle FM
    private func generateLifeLost() -> AVAudioPlayer? {
        let duration = 0.35
        let samples = synthesize(duration: duration) { t in
            var out = 0.0

            // Note 1: E5 (659Hz)
            if t < 0.2 {
                let env1 = self.noteEnvelope(t: t, hold: 0.06, release: 0.05)
                out += self.fmSample(t: t, carrierFreq: 659, modFreq: 923, modIndex: 1.0 * env1, envelope: env1)
            }

            // Note 2: C5 (523Hz) — minor third down = sad
            if t >= 0.14 {
                let t2 = t - 0.14
                let env2 = self.noteEnvelope(t: t2, hold: 0.06, release: 0.06)
                out += self.fmSample(t: t2, carrierFreq: 523, modFreq: 732, modIndex: 0.8 * env2, envelope: env2)
            }

            return out * 0.25
        }
        return makePlayer(from: samples)
    }

    /// Game over: low descending chord, longer tail
    private func generateGameOver() -> AVAudioPlayer? {
        let duration = 0.6
        let samples = synthesize(duration: duration) { t in
            let env = self.percEnvelope(t: t, attack: 0.02, decay: 0.2)
            // Descending pitch
            let freq = 440.0 - (t / duration) * 200.0
            let fm = self.fmSample(t: t, carrierFreq: freq, modFreq: freq * 1.41, modIndex: 2.0 * env, envelope: env)
            let low = self.fmSample(t: t, carrierFreq: freq * 0.5, modFreq: freq * 0.7, modIndex: 1.0 * env, envelope: env * 0.5)
            return (fm + low) * 0.3
        }
        return makePlayer(from: samples)
    }

    // MARK: - Infrastructure

    private func synthesize(duration: Double, generator: (Double) -> Double) -> [Float] {
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            samples[i] = Float(generator(t))
        }
        return samples
    }

    private func makePlayer(from samples: [Float]) -> AVAudioPlayer? {
        guard let data = createWAVData(samples: samples) else { return nil }
        do {
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            return player
        } catch {
            print("⚠️ Failed to create audio player: \(error)")
            return nil
        }
    }

    private func createWAVData(samples: [Float]) -> Data? {
        let sr = Int(sampleRate)
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sr * 2)
        let blockAlign: Int16 = 2
        let dataSize = Int32(samples.count * 2)
        let fileSize = 36 + dataSize

        var data = Data()
        data.reserveCapacity(44 + samples.count * 2)

        func append32(_ v: Int32) { data.append(withUnsafeBytes(of: v.littleEndian) { Data($0) }) }
        func append16(_ v: Int16) { data.append(withUnsafeBytes(of: v.littleEndian) { Data($0) }) }

        data.append(contentsOf: "RIFF".utf8); append32(fileSize)
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8); append32(16)
        append16(1); append16(numChannels)
        append32(Int32(sr)); append32(byteRate)
        append16(blockAlign); append16(bitsPerSample)
        data.append(contentsOf: "data".utf8); append32(dataSize)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            append16(Int16(clamped * Float(Int16.max)))
        }

        return data
    }

    // MARK: - Music

    private var musicPlayer: AVAudioPlayer?

    func startMusic() {
        guard SettingsManager.shared.musicEnabled else { return }
        guard musicPlayer == nil || musicPlayer?.isPlaying != true else { return }

        musicPlayer = generateAmbientLoop()
        musicPlayer?.numberOfLoops = -1 // infinite loop
        musicPlayer?.volume = 0.12 // subtle background
        musicPlayer?.play()
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func updateMusicState() {
        if SettingsManager.shared.musicEnabled {
            startMusic()
        } else {
            stopMusic()
        }
    }

    /// Ambient pad loop — warm, evolving chord drone.
    /// Slow FM with detuned oscillators for a dreamy, non-distracting backdrop.
    private func generateAmbientLoop() -> AVAudioPlayer? {
        let duration = 8.0 // 8-second seamless loop
        let samples = synthesize(duration: duration) { t in
            // Gentle amplitude swell
            let swell = 0.4 + 0.6 * (0.5 + 0.5 * sin(2.0 * .pi * t / duration))

            // Root: C3 (130.8 Hz)
            let c3 = self.fmSample(
                t: t, carrierFreq: 130.8, modFreq: 130.8 * 1.002,
                modIndex: 0.3 + 0.2 * sin(2.0 * .pi * t / 3.0), envelope: swell
            )
            // Fifth: G3 (196 Hz)
            let g3 = self.fmSample(
                t: t, carrierFreq: 196.0, modFreq: 196.0 * 0.998,
                modIndex: 0.2 + 0.15 * sin(2.0 * .pi * t / 4.0), envelope: swell * 0.6
            )
            // Minor third: Eb4 (311 Hz)
            let eb4 = self.fmSample(
                t: t, carrierFreq: 311.0, modFreq: 311.0 * 1.003,
                modIndex: 0.15 + 0.1 * sin(2.0 * .pi * t / 5.0), envelope: swell * 0.35
            )
            // Octave: C4 (261.6 Hz)
            let c4 = self.fmSample(
                t: t, carrierFreq: 261.6, modFreq: 261.6 * 0.999,
                modIndex: 0.1, envelope: swell * 0.25
            )

            return (c3 + g3 + eb4 + c4) * 0.18
        }
        return makePlayer(from: samples)
    }
}
