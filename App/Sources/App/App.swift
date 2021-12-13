import Cocoa
import SwiftUI
 
public final class AutoKeyboardSwitcherApp: NSObject {
    let keyboardSwitcher: KeyboardSwitcher
    let preferencesViewModel: PreferencesViewModel
    var statusBarItem: NSStatusItem!
    weak var window: NSWindow?
    
    public override init() {
        keyboardSwitcher = KeyboardSwitcher()
        preferencesViewModel = PreferencesViewModel(keyboardSwitcher: keyboardSwitcher)
    }

    public func applicationDidFinishLaunching(_ appDelegate: NSObject & NSApplicationDelegate) {
        setupStatusBarItem()
    }

    func setupStatusBarItem() {
        let statusBar = NSStatusBar.system
        let statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.image = NSImage(
            systemSymbolName: "keyboard.badge.ellipsis",
            accessibilityDescription: nil
        )
        statusBarItem.button?.target = self
        statusBarItem.button?.action = #selector(showPreferencesWindows)
        self.statusBarItem = statusBarItem
    }

    @objc func showPreferencesWindows() {
        guard self.window == nil else {
            self.window?.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentViewController: NSHostingController(
                rootView: PreferencesView(viewModel: preferencesViewModel)
                    .frame(width: 400, alignment: .center)
            )
        )
        window.level = .floating
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
