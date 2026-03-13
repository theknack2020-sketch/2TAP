import AVFoundation
import UIKit

/// Manages all game audio with synthesized premium sound effects.
///
/// Sound design approach:
/// - Tap: soft, satisfying "pop" — layered harmonics with fast attack/decay
/// - Success: bright ascending chime — two-note arpeggio with shimmer
/// - Error: deep muted thud — low frequency with noise burst
/// - Combo: quick rising tone — pitch sweep
/// - Life lost: descending tone — sad but not harsh
///
/// All sounds generated programmatically via additive synthesis.
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var tapPlayer: AVAudioPlayer?
    private var errorPlayer: AVAudioPlayer?
    private var successPlayer: AVAudioPlayer?
    private var comboPlayer: AVAudioPlayer?
    private var lifeLostPlayer: AVAudioPlayer?

    private let sampleRate: Double = 44100

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }

        tapPlayer = generateTapSound()
        successPlayer = generateSuccessSound()
        errorPlayer = generateErrorSound()
        comboPlayer = generateComboSound()
        lifeLostPlayer = generateLifeLostSound()
    }

    // MARK: - Playback

    func playTap() {
        guard SettingsManager.shared.soundEnabled else { return }
        tapPlayer?.currentTime = 0
        tapPlayer?.play()
    }

    func playSuccess() {
        guard SettingsManager.shared.soundEnabled else { return }
        successPlayer?.currentTime = 0
        successPlayer?.play()
    }

    func playError() {
        guard SettingsManager.shared.soundEnabled else { return }
        errorPlayer?.currentTime = 0
        errorPlayer?.play()
    }

    func playCombo() {
        guard SettingsManager.shared.soundEnabled else { return }
        comboPlayer?.currentTime = 0
        comboPlayer?.play()
    }

    func playLifeLost() {
        guard SettingsManager.shared.soundEnabled else { return }
        lifeLostPlayer?.currentTime = 0
        lifeLostPlayer?.play()
    }

    // MARK: - Sound Synthesis

    /// Tap: satisfying soft pop — fundamental + octave harmonic, fast ADSR, slight pitch drop
    private func generateTapSound() -> AVAudioPlayer? {
        let duration = 0.12
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            // ADSR: instant attack, fast decay
            let attack: Double = 0.005
            let decay: Double = 0.08
            let env: Double
            if t < attack {
                env = t / attack
            } else {
                env = exp(-(t - attack) / decay * 4.0)
            }

            // Slight pitch drop for "pop" feel (660Hz → 580Hz)
            let freq = 660.0 - (t / duration) * 80.0

            // Fundamental + soft octave + quiet fifth
            let fundamental = sin(2.0 * .pi * freq * t)
            let octave = sin(2.0 * .pi * freq * 2.0 * t) * 0.3
            let fifth = sin(2.0 * .pi * freq * 1.5 * t) * 0.1

            // Tiny noise burst at start for "click" texture
            let noise = t < 0.008 ? (Double.random(in: -1...1) * 0.15 * (1.0 - t / 0.008)) : 0

            samples[i] = Float((fundamental + octave + fifth + noise) * env * 0.35)
        }

        return makePlayer(from: samples)
    }

    /// Success: bright two-note ascending chime with shimmer
    private func generateSuccessSound() -> AVAudioPlayer? {
        let duration = 0.28
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            // Two notes: C6 (1047Hz) then E6 (1319Hz)
            let noteSwitch = 0.12
            let freq: Double
            let noteStart: Double

            if t < noteSwitch {
                freq = 1047.0
                noteStart = 0.0
            } else {
                freq = 1319.0
                noteStart = noteSwitch
            }

            let noteT = t - noteStart

            // Per-note envelope: fast attack, gentle sustain, soft release
            let attack: Double = 0.008
            let sustain: Double = 0.06
            let env: Double
            if noteT < attack {
                env = noteT / attack
            } else if noteT < sustain {
                env = 1.0
            } else {
                env = exp(-(noteT - sustain) * 8.0)
            }

            // Sine + shimmer (detuned pair for chorus effect)
            let main = sin(2.0 * .pi * freq * t)
            let detune = sin(2.0 * .pi * (freq * 1.003) * t) * 0.5 // slight detune
            let octaveUp = sin(2.0 * .pi * freq * 2.0 * t) * 0.15  // sparkle

            samples[i] = Float((main + detune + octaveUp) * env * 0.28)
        }

        return makePlayer(from: samples)
    }

    /// Error: muted low thud — not harsh, but clearly "wrong"
    private func generateErrorSound() -> AVAudioPlayer? {
        let duration = 0.22
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            // Envelope: punchy attack, medium decay
            let attack: Double = 0.01
            let env: Double
            if t < attack {
                env = t / attack
            } else {
                env = exp(-(t - attack) * 6.0)
            }

            // Low fundamental with pitch drop (180Hz → 110Hz)
            let freq = 180.0 - (t / duration) * 70.0

            // Warm low tone — fundamental + sub-octave, no harsh harmonics
            let fundamental = sin(2.0 * .pi * freq * t)
            let subOctave = sin(2.0 * .pi * freq * 0.5 * t) * 0.5

            // Filtered noise burst at very start
            let noiseBurst = t < 0.015 ? (Double.random(in: -1...1) * 0.2 * (1.0 - t / 0.015)) : 0

            // Low-pass feel: triangle wave adds warmth without harshness
            let phase = fmod(freq * t, 1.0)
            let triangle = (phase < 0.5 ? (4.0 * phase - 1.0) : (3.0 - 4.0 * phase)) * 0.2

            samples[i] = Float((fundamental + subOctave + triangle + noiseBurst) * env * 0.35)
        }

        return makePlayer(from: samples)
    }

    /// Combo: quick bright rising sweep
    private func generateComboSound() -> AVAudioPlayer? {
        let duration = 0.15
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            let env = exp(-t * 12.0) // very fast decay

            // Rising pitch sweep (800Hz → 1600Hz)
            let freq = 800.0 + (t / duration) * 800.0

            let wave = sin(2.0 * .pi * freq * t)
            let harmonic = sin(2.0 * .pi * freq * 2.0 * t) * 0.2

            samples[i] = Float((wave + harmonic) * env * 0.25)
        }

        return makePlayer(from: samples)
    }

    /// Life lost: sad descending tone — two notes going down
    private func generateLifeLostSound() -> AVAudioPlayer? {
        let duration = 0.35
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate

            // Descending pitch (523Hz → 330Hz) — C5 to E4
            let freq = 523.0 - (t / duration) * 193.0

            // Slow envelope — gentle fade
            let attack: Double = 0.02
            let env: Double
            if t < attack {
                env = t / attack
            } else {
                env = exp(-(t - attack) * 3.5)
            }

            let fundamental = sin(2.0 * .pi * freq * t)
            let softHarmonic = sin(2.0 * .pi * freq * 1.5 * t) * 0.15 // minor feel

            samples[i] = Float((fundamental + softHarmonic) * env * 0.3)
        }

        return makePlayer(from: samples)
    }

    // MARK: - WAV Infrastructure

    private func makePlayer(from samples: [Float]) -> AVAudioPlayer? {
        guard let wavData = createWAVData(samples: samples) else { return nil }
        do {
            let player = try AVAudioPlayer(data: wavData)
            player.prepareToPlay()
            return player
        } catch {
            print("⚠️ Failed to create audio player: \(error)")
            return nil
        }
    }

    /// Creates a minimal WAV file in memory from float samples.
    private func createWAVData(samples: [Float]) -> Data? {
        let sr = Int(sampleRate)
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sr * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(samples.count * Int(bitsPerSample / 8))
        let fileSize = 36 + dataSize

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sr).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            data.append(withUnsafeBytes(of: intSample.littleEndian) { Data($0) })
        }

        return data
    }

    // MARK: - Music (placeholder)

    func startMusic() {}
    func stopMusic() {}
}
