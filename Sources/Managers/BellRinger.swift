import AVFoundation
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

final class BellRinger: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        preparePlayer()
    }

    func ringBell() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #elseif canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif

        if audioPlayer == nil {
            preparePlayer()
        }

        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    private func preparePlayer() {
        guard let bellData = Self.generateBellTone() else { return }
        audioPlayer = try? AVAudioPlayer(data: bellData)
        audioPlayer?.prepareToPlay()
    }

    private static func generateBellTone(
        frequency: Double = 880,
        sampleRate: Double = 44100,
        duration: Double = 1.5
    ) -> Data? {
        let frameCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: frameCount)

        let decayRate = 4.0 / duration
        for index in 0..<frameCount {
            let time = Double(index) / sampleRate
            let envelope = exp(-decayRate * time)
            let value = sin(2 * .pi * frequency * time) * envelope
            samples[index] = Int16(max(-1.0, min(1.0, value)) * Double(Int16.max))
        }

        return makeWavData(from: samples, sampleRate: UInt32(sampleRate))
    }

    private static func makeWavData(from samples: [Int16], sampleRate: UInt32) -> Data? {
        let byteRate = sampleRate * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let dataChunkSize = UInt32(samples.count * MemoryLayout<Int16>.size)
        let riffChunkSize = 36 + dataChunkSize

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(Data(from: riffChunkSize.littleEndian))
        data.append(contentsOf: "WAVE".utf8)

        data.append(contentsOf: "fmt ".utf8)
        data.append(Data(from: UInt32(16).littleEndian))
        data.append(Data(from: UInt16(1).littleEndian)) // PCM format
        data.append(Data(from: UInt16(1).littleEndian)) // mono channel
        data.append(Data(from: sampleRate.littleEndian))
        data.append(Data(from: byteRate.littleEndian))
        data.append(Data(from: blockAlign.littleEndian))
        data.append(Data(from: bitsPerSample.littleEndian))

        data.append(contentsOf: "data".utf8)
        data.append(Data(from: dataChunkSize.littleEndian))
        samples.withUnsafeBufferPointer { buffer in
            var littleEndianSamples = buffer.map { $0.littleEndian }
            littleEndianSamples.withUnsafeBytes { rawBuffer in
                data.append(rawBuffer)
            }
        }

        return data
    }
}

private extension Data {
    init<T>(from value: T) {
        var value = value
        self = withUnsafeBytes(of: &value) { Data($0) }
    }
}
