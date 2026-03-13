import AVFoundation
import UIKit

/// Premium game audio via layered FM synthesis with AVAudioEngine effects.
///
/// Architecture:
/// - Each sound is pre-rendered as a PCM buffer
/// - Played through AVAudioEngine with shared reverb + EQ chain
/// - Thread-safe: all playback serialized on a dedicated audio queue
/// - Result: studio-quality spatial audio, zero latency
final class AudioManager: @unchecked Sendable {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let playerPool: [AVAudioPlayerNode]
    private let poolSize = 6  // concurrent sounds

    // Mixer to combine all players before effects
    private let playerMixer = AVAudioMixerNode()

    // Effect units — shared signal chain
    private let reverb = AVAudioUnitReverb()
    private let eq = AVAudioUnitEQ(numberOfBands: 3)

    private var buffers: [SoundType: AVAudioPCMBuffer] = [:]
    private var currentPlayerIndex = 0
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    /// Serial queue for thread-safe player access.
    private let audioQueue = DispatchQueue(label: "com.ufuk.twotapgame.audio", qos: .userInteractive)

    enum SoundType: CaseIterable {
        case tap, correctTap, wrongTap, success, combo, lifeLost, gameOver
    }

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Create player pool
        var pool: [AVAudioPlayerNode] = []
        for _ in 0..<poolSize {
            pool.append(AVAudioPlayerNode())
        }
        playerPool = pool

        setupAudioSession()
        setupEngine()
        generateAllSounds()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        // Attach nodes
        for player in playerPool {
            engine.attach(player)
        }
        engine.attach(playerMixer)
        engine.attach(reverb)
        engine.attach(eq)

        // Configure reverb — small room, subtle
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 20  // subtle spatial feel

        // Configure EQ
        // Band 0: cut mud (low-mid)
        let band0 = eq.bands[0]
        band0.filterType = .parametric
        band0.frequency = 300
        band0.bandwidth = 1.5
        band0.gain = -3
        band0.bypass = false

        // Band 1: presence boost (2-4kHz)
        let band1 = eq.bands[1]
        band1.filterType = .parametric
        band1.frequency = 3000
        band1.bandwidth = 1.0
        band1.gain = 2.5
        band1.bypass = false

        // Band 2: air / sparkle (10kHz+)
        let band2 = eq.bands[2]
        band2.filterType = .highShelf
        band2.frequency = 10000
        band2.bandwidth = 0.5
        band2.gain = 1.5
        band2.bypass = false

        // Signal chain: players → playerMixer → EQ → reverb → mainMixer
        let mainMixer = engine.mainMixerNode

        for player in playerPool {
            engine.connect(player, to: playerMixer, format: format)
        }
        engine.connect(playerMixer, to: eq, format: format)
        engine.connect(eq, to: reverb, format: format)
        engine.connect(reverb, to: mainMixer, format: format)

        do {
            try engine.start()
        } catch {
            print("⚠️ AVAudioEngine start failed: \(error)")
        }
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
        // Read sound preference directly from UserDefaults (thread-safe)
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        guard let buffer = buffers[type] else { return }

        audioQueue.async { [self] in
            let player = playerPool[currentPlayerIndex]
            currentPlayerIndex = (currentPlayerIndex + 1) % poolSize

            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        }
    }

    // MARK: - Sound Generation

    private func generateAllSounds() {
        buffers[.tap] = renderTap()
        buffers[.correctTap] = renderCorrectTap()
        buffers[.wrongTap] = renderWrongTap()
        buffers[.success] = renderSuccess()
        buffers[.combo] = renderCombo()
        buffers[.lifeLost] = renderLifeLost()
        buffers[.gameOver] = renderGameOver()
    }

    // MARK: - FM Synthesis Core

    /// FM synthesis with optional feedback for richer timbres.
    private func fm(
        t: Double,
        carrier: Double,
        modulator: Double,
        index: Double,
        feedback: Double = 0
    ) -> Double {
        let modPhase = 2.0 * .pi * modulator * t
        let modSignal = sin(modPhase + feedback * sin(modPhase)) * index
        return sin(2.0 * .pi * carrier * t + modSignal)
    }

    /// Multi-operator FM: carrier modulated by two modulators (stacked).
    private func fm2(
        t: Double,
        carrier: Double,
        mod1Freq: Double, mod1Index: Double,
        mod2Freq: Double, mod2Index: Double
    ) -> Double {
        let mod2 = sin(2.0 * .pi * mod2Freq * t) * mod2Index
        let mod1 = sin(2.0 * .pi * mod1Freq * t + mod2) * mod1Index
        return sin(2.0 * .pi * carrier * t + mod1)
    }

    /// Percussive envelope — instant attack, exponential decay.
    private func perc(_ t: Double, attack: Double = 0.002, decay: Double) -> Double {
        if t < attack { return t / attack }
        return exp(-(t - attack) / decay * 3.5)
    }

    /// ADSR-ish envelope for notes.
    private func adsr(_ t: Double, a: Double = 0.004, d: Double = 0.05, s: Double = 0.7, r: Double) -> Double {
        if t < a { return t / a }
        if t < a + d { return 1.0 - (1.0 - s) * ((t - a) / d) }
        return s * exp(-(t - a - d) / r * 2.5)
    }

    /// Noise generator (white noise for transient layers).
    private func noise() -> Double {
        Double.random(in: -1...1)
    }

    // MARK: - Sound Designs

    /// Tap: ultra-short crystalline tick with metallic transient.
    private func renderTap() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.07) { t in
            let env = self.perc(t, decay: 0.02)
            // Metallic FM click
            let click = self.fm(t: t, carrier: 3200, modulator: 7200, index: 2.5 * env) * env
            // Filtered noise transient for realism
            let trans = self.noise() * max(0, 1.0 - t / 0.003) * 0.15
            return (click * 0.35 + trans) * 0.4
        }
    }

    /// Correct tap: lush crystalline bell with harmonic shimmer.
    /// Two detuned FM bells + high harmonic sparkle.
    private func renderCorrectTap() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.28) { t in
            let env = self.perc(t, decay: 0.12)

            // Primary bell — inharmonic ratio for bell timbre
            let bell1 = self.fm2(
                t: t, carrier: 1318,
                mod1Freq: 1845, mod1Index: 2.5 * env,
                mod2Freq: 3690, mod2Index: 0.8 * env
            ) * env

            // Detuned bell — slight chorus effect
            let bell2 = self.fm(
                t: t, carrier: 1322, modulator: 1851,
                index: 2.0 * env
            ) * env * 0.4

            // High sparkle harmonic
            let sparkle = self.fm(
                t: t, carrier: 3956, modulator: 5540,
                index: 1.0 * env * env
            ) * env * env * 0.15

            return (bell1 + bell2 + sparkle) * 0.28
        }
    }

    /// Wrong tap: thick distorted thump with sub-bass rumble.
    private func renderWrongTap() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.18) { t in
            let env = self.perc(t, decay: 0.06)
            let modDecay = exp(-t * 40) // mod index decays fast → buzzy→clean

            // Distorted FM thump
            let thump = self.fm2(
                t: t, carrier: 130,
                mod1Freq: 195, mod1Index: 5.0 * modDecay,
                mod2Freq: 390, mod2Index: 2.0 * modDecay
            ) * env

            // Sub bass layer
            let sub = sin(2.0 * .pi * 65 * t) * env * 0.5

            // Noise burst transient
            let noiseT = self.noise() * max(0, 1.0 - t / 0.006) * 0.2

            return (thump * 0.5 + sub + noiseT) * 0.4
        }
    }

    /// Round success: lush ascending arpeggio — E6 → G#6 → B6 (major triad).
    /// Each note is a rich FM bell with chorus.
    private func renderSuccess() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.45) { t in
            var out = 0.0

            // Note 1: E6 (1318 Hz) at t=0
            if t < 0.30 {
                let e = self.adsr(t, d: 0.03, s: 0.6, r: 0.08)
                out += self.fm2(t: t, carrier: 1318, mod1Freq: 1845, mod1Index: 2.0 * e,
                               mod2Freq: 3690, mod2Index: 0.6 * e) * e
            }

            // Note 2: G#6 (1661 Hz) at t=0.10
            if t >= 0.08 && t < 0.38 {
                let t2 = t - 0.08
                let e = self.adsr(t2, d: 0.03, s: 0.6, r: 0.08)
                out += self.fm2(t: t2, carrier: 1661, mod1Freq: 2326, mod1Index: 1.8 * e,
                               mod2Freq: 4652, mod2Index: 0.5 * e) * e * 0.85
            }

            // Note 3: B6 (1976 Hz) at t=0.16
            if t >= 0.16 {
                let t3 = t - 0.16
                let e = self.adsr(t3, d: 0.03, s: 0.5, r: 0.10)
                out += self.fm2(t: t3, carrier: 1976, mod1Freq: 2766, mod1Index: 1.5 * e,
                               mod2Freq: 5532, mod2Index: 0.4 * e) * e * 0.7
            }

            return out * 0.22
        }
    }

    /// Combo: bright rising glissando sweep with FM shimmer + octave layer.
    private func renderCombo() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.16) { t in
            let env = self.perc(t, decay: 0.07)
            let progress = t / 0.16

            // Rising frequency sweep
            let freq = 1400 + progress * 1800
            let sweep = self.fm(t: t, carrier: freq, modulator: freq * 1.41,
                               index: 1.5 * env, feedback: 0.3) * env

            // Octave above — thin shimmer
            let octave = self.fm(t: t, carrier: freq * 2, modulator: freq * 2.82,
                                index: 0.8 * env) * env * 0.2

            // Subtle sparkle noise
            let sparkle = self.noise() * env * env * 0.06

            return (sweep + octave + sparkle) * 0.25
        }
    }

    /// Life lost: melancholy descending minor second — F5 → E5.
    /// Warmer, darker FM timbre.
    private func renderLifeLost() -> AVAudioPCMBuffer? {
        synthesize(duration: 0.40) { t in
            var out = 0.0

            // Note 1: F5 (698 Hz)
            if t < 0.25 {
                let e = self.adsr(t, d: 0.04, s: 0.5, r: 0.06)
                // Warmer: lower mod ratio
                out += self.fm2(t: t, carrier: 698, mod1Freq: 698 * 1.0, mod1Index: 1.2 * e,
                               mod2Freq: 698 * 2.0, mod2Index: 0.4 * e) * e
            }

            // Note 2: E5 (659 Hz) — semitone down, minor second = tension
            if t >= 0.15 {
                let t2 = t - 0.15
                let e = self.adsr(t2, d: 0.04, s: 0.4, r: 0.08)
                out += self.fm2(t: t2, carrier: 659, mod1Freq: 659 * 1.0, mod1Index: 1.0 * e,
                               mod2Freq: 659 * 2.0, mod2Index: 0.3 * e) * e * 0.8
            }

            // Subtle sub-octave for gravity
            let env = self.perc(t, decay: 0.15)
            out += sin(2.0 * .pi * 349 * t) * env * 0.1

            return out * 0.25
        }
    }

    /// Game over: dramatic descending chord dissolve.
    /// Starts wide and bright, descends into dark rumble.
    private func renderGameOver() -> AVAudioPCMBuffer? {
        synthesize(duration: 1.0) { t in
            let progress = t / 1.0
            let masterEnv = self.perc(t, attack: 0.015, decay: 0.35)

            // Descending carrier — starts A4 (440), drops to D3 (147)
            let freq = 440.0 - progress * 293.0

            // Main voice — rich FM with feedback
            let main = self.fm(t: t, carrier: freq, modulator: freq * 1.41,
                              index: 2.5 * masterEnv, feedback: 0.4 * masterEnv) * masterEnv

            // Fifth below — creates power chord feel dissolving
            let fifth = self.fm(t: t, carrier: freq * 0.667, modulator: freq * 0.934,
                               index: 1.5 * masterEnv) * masterEnv * 0.5

            // Rumble sub bass — grows as pitch drops
            let subEnv = self.perc(t, attack: 0.1, decay: 0.4)
            let sub = sin(2.0 * .pi * freq * 0.5 * t) * subEnv * progress * 0.4

            // Fading noise wash
            let wash = self.noise() * masterEnv * masterEnv * 0.04

            return (main + fifth + sub + wash) * 0.28
        }
    }

    // MARK: - Synthesis Infrastructure

    private func synthesize(duration: Double, generator: (Double) -> Double) -> AVAudioPCMBuffer? {
        let numSamples = Int(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(numSamples)

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let sample = generator(t)
            channelData[i] = Float(max(-1.0, min(1.0, sample)))
        }

        return buffer
    }

    // MARK: - Music (unused — kept for future)

    func startMusic() {}
    func stopMusic() {}
    func updateMusicState() {}
}
