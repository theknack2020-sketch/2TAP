import AVFoundation
import UIKit

/// Manages all game audio — sound effects and background music.
///
/// Sound effects: cartoon tap, error/bomb
/// Music: background loops (when available)
///
/// Respects SettingsManager for sound/music enabled state.
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var tapPlayer: AVAudioPlayer?
    private var errorPlayer: AVAudioPlayer?
    private var successPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session for game
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }

        // Generate sound effects programmatically
        tapPlayer = createTonePlayer(frequency: 880, duration: 0.08, volume: 0.3)
        errorPlayer = createTonePlayer(frequency: 200, duration: 0.25, volume: 0.4)
        successPlayer = createTonePlayer(frequency: 1200, duration: 0.1, volume: 0.25)
    }

    // MARK: - Sound Effects

    func playTap() {
        guard SettingsManager.shared.soundEnabled else { return }
        tapPlayer?.currentTime = 0
        tapPlayer?.play()
    }

    func playError() {
        guard SettingsManager.shared.soundEnabled else { return }
        errorPlayer?.currentTime = 0
        errorPlayer?.play()
    }

    func playSuccess() {
        guard SettingsManager.shared.soundEnabled else { return }
        successPlayer?.currentTime = 0
        successPlayer?.play()
    }

    // MARK: - Music

    func startMusic() {
        guard SettingsManager.shared.musicEnabled else { return }
        // Music loops will be added with actual audio files in S06 or later
        // For now, no background music plays
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func toggleMusic() {
        if musicPlayer?.isPlaying == true {
            stopMusic()
        } else {
            startMusic()
        }
    }

    // MARK: - Tone Generation

    /// Creates a simple sine wave tone as an AVAudioPlayer.
    private func createTonePlayer(
        frequency: Double,
        duration: Double,
        volume: Float
    ) -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let numSamples = Int(sampleRate * duration)

        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            // Sine wave with exponential decay envelope
            let envelope = exp(-t * 15.0) // Fast decay for "pop" sound
            let wave = sin(2.0 * .pi * frequency * t)
            samples[i] = Float(wave * envelope) * volume
        }

        // Create WAV data
        guard let wavData = createWAVData(samples: samples, sampleRate: Int(sampleRate)) else {
            return nil
        }

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
    private func createWAVData(samples: [Float], sampleRate: Int) -> Data? {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
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
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) }) // chunk size
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })  // PCM format
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        // Sample data (convert float to Int16)
        for sample in samples {
            let intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(withUnsafeBytes(of: intSample.littleEndian) { Data($0) })
        }

        return data
    }
}
