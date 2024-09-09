import SwiftUI
import AppKit

@main
struct ClipboardTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    let updateChecker = GitHubUpdateChecker(owner: "hkgood", repo: "ClipboardTranslator")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        checkForUpdates()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusBarButton = statusItem?.button {
            statusBarButton.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Translate")
            statusBarButton.action = #selector(togglePopover)
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 416, height: 600)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MainWindow())
    }
    
    @objc func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let statusBarButton = statusItem?.button {
                    popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
                }
            }
        }
    }
    
    private func checkForUpdates() {
        print("Debug: Starting update check")
        updateChecker.checkForUpdates { (updateAvailable, latestVersion) in
            DispatchQueue.main.async {
                if updateAvailable, let version = latestVersion {
                    print("Debug: Update available - Latest version: \(version)")
                    self.showUpdateAlert(latestVersion: version)
                } else {
                    print("Debug: No update available or failed to check for updates")
                }
            }
        }
    }

    private func showUpdateAlert(latestVersion: String) {
        print("Debug: Showing update alert for version \(latestVersion)")
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version (\(latestVersion)) is available. Would you like to download it?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        print("Debug: User response to update alert - \(response == .alertFirstButtonReturn ? "Download" : "Later")")
        
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "https://github.com/hkgood/ClipboardTranslator/releases/latest") {
                print("Debug: Opening download URL - \(url)")
                NSWorkspace.shared.open(url)
            } else {
                print("Debug: Failed to create download URL")
            }
        }
    }
}
