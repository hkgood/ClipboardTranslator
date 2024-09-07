import Foundation
import Combine
import AppKit

class ClipboardManager: ObservableObject {
    @Published var clipboardContent: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkClipboard()
            }
            .store(in: &cancellables)
    }
    
    private func checkClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            if string != clipboardContent {
                clipboardContent = string
            }
        }
    }
}
