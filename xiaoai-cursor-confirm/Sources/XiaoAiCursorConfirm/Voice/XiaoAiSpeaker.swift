import AVFoundation
import Foundation

@MainActor
final class XiaoAiSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = XiaoAiSpeaker()

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.lowercased().hasPrefix("zh") }
            .sorted { $0.name < $1.name }
    }

    func resolvedVoice() -> AVSpeechSynthesisVoice? {
        let preferred = AppSettings.shared.voiceIdentifier
        if !preferred.isEmpty, let match = AVSpeechSynthesisVoice(identifier: preferred) {
            return match
        }
        let voices = availableVoices()
        return voices.first { $0.identifier.contains("Tingting") }
            ?? voices.first { $0.language == "zh-CN" }
            ?? voices.first
            ?? AVSpeechSynthesisVoice(language: "zh-CN")
    }

    func speak(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        stop()
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = resolvedVoice()
        utterance.rate = Float(AppSettings.shared.speechRate)
        utterance.pitchMultiplier = Float(AppSettings.shared.speechPitch)
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.12
        isSpeaking = true
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        finish()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.finish()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.finish()
        }
    }

    private func finish() {
        continuation?.resume()
        continuation = nil
    }
}
