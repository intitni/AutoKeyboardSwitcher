import App
import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let app = AutoKeyboardSwitcherApp()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        app.applicationDidFinishLaunching(self)
    }
}
