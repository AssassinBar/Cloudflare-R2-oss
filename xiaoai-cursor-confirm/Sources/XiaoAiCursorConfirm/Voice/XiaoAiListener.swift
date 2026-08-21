import AppKit
import Foundation

@MainActor
final class XiaoAiListener: NSObject, ObservableObject, NSSpeechRecognizerDelegate {
    nonisolated(unsafe) static let shared = XiaoAiListener()

    @Published private(set) var isListening = false
    @Published private(set) var lastHeard = ""

    fileprivate var recognizer: NSSpeechRecognizer?
    fileprivate var continuation: CheckedContinuation<String?, Never>?
    private var timeoutTask: Task<Void, Never>?

    private let approveWords = ["确认", "好的", "可以", "同意", "行", "批准", "运行", "允许", "好", "是", "小爱确认"]
    private let rejectWords = ["取消", "拒绝", "不行", "不要", "算了", "否", "停", "小爱取消"]

    private override init() {
        super.init()
    }

    func start() {
        if recognizer == nil {
            let rec = NSSpeechRecognizer()
            rec?.commands = approveWords + rejectWords
            rec?.listensInForegroundOnly = false
            rec?.blocksOtherRecognizers = false
            rec?.delegate = self
            recognizer = rec
        }
        recognizer?.startListening()
        isListening = recognizer != nil
    }

    func stop() {
        timeoutTask?.cancel()
        timeoutTask = nil
        recognizer?.stopListening()
        isListening = false
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: nil)
        }
    }

    func waitForDecision(timeoutMs: Int) async -> (ConfirmDecision, String)? {
        start()
        defer { stop() }
        let heard: String? = await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.timeoutTask = Task { @MainActor in
                let ns = UInt64(max(timeoutMs, 1_000)) * 1_000_000
                try? await Task.sleep(nanoseconds: ns)
                if let waiting = self.continuation {
                    self.continuation = nil
                    waiting.resume(returning: nil)
                }
            }
        }
        return heard.flatMap { classify($0) }
    }

    func classify(_ raw: String) -> (ConfirmDecision, String)? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        lastHeard = text
        if approveWords.contains(where: { text.contains($0) }) {
            return (.approve, text)
        }
        if rejectWords.contains(where: { text.contains($0) }) {
            return (.reject, text)
        }
        return nil
    }

    nonisolated func speechRecognizer(_ sender: NSSpeechRecognizer, didRecognizeCommand command: String) {
        Task { @MainActor in
            let listener = XiaoAiListener.shared
            listener.lastHeard = command
            if let continuation = listener.continuation {
                listener.continuation = nil
                continuation.resume(returning: command)
            }
        }
    }
}
