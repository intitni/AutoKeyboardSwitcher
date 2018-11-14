import AppKit
import Carbon

typealias Pref = [String: String]

class Observer: NSObject {
    lazy var pref: Pref = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        guard let data = FileManager().contents(atPath: "\(home)/Documents/AutoKeyboardSwitcher.json") else { fatalError() }
        let decoder = JSONDecoder()
        let result = try! decoder.decode(Pref.self, from: data)
        return result
    }()
    
    @objc func handleChange(_ noti: NSNotification) {
        guard let info = noti.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard let identifier = info.bundleIdentifier else { return }
        assert({ print(identifier); return true }())
        
        if let language = pref[identifier] {
            guard let source = TISCopyInputSourceForLanguage(language as CFString) else { return }
            let value = source.takeRetainedValue()
            TISSelectInputSource(value)
        }
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

let observer = Observer()
NSWorkspace.shared.notificationCenter.addObserver(
    observer,
    selector: #selector(Observer.handleChange(_:)),
    name: NSWorkspace.didActivateApplicationNotification,
    object: nil)

RunLoop.main.run()
