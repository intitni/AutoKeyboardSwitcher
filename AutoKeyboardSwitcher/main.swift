import AppKit
import Carbon

typealias Pref = [String: String]

let defaultPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Documents/AutoKeyboardSwitcher.json"

struct Arguments {
    let conf: String
    let verbose: Bool
    
    init(_ arguments: [String]) {
        self.conf = {
            guard let i = arguments.firstIndex(of: "--conf"), i < arguments.endIndex - 1 else { return defaultPath }
            let p = arguments[i + 1]
            if let first = p.first, first == "~" {
                return FileManager.default.homeDirectoryForCurrentUser.path + String(p[p.index(after: p.startIndex)...])
            }
            return p
        }()
        self.verbose = arguments.contains("--verbose")
    }
}

class Observer: NSObject {
    let confPath: String
    let verbose: Bool
    var pref: Pref {
        guard let data = FileManager().contents(atPath: confPath) else {
            verboseDo { print("\(confPath) not found") }
            return [:]
        }
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(Pref.self, from: data) else {
            verboseDo { print("\(confPath) format incorrect") }
            return [:]
        }
        return result
    }
    
    init(confPath: String, verbose: Bool) {
        self.confPath = confPath
        self.verbose = verbose
        super.init()
        
        verboseDo { print("Using pref under \(confPath)") }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(Observer.handleChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil)
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc func handleChange(_ noti: NSNotification) {
        guard let info = noti.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard let identifier = info.bundleIdentifier else { return }
        verboseDo { print("Switch to app: \(identifier)") }
        
        if let language = pref[identifier] {
            verboseDo { print("Best Match! Switching to source of name \(language)") }
            guard let source = TISCopyInputSourceForLanguage(language as CFString) else {
                verboseDo { print("Source for \(language) not found") }
                return
            }
            let value = source.takeRetainedValue()
            TISSelectInputSource(value)
            verboseDo { print("Done!") }
        }
    }

    private func verboseDo(_ block: ()->Void) {
        if verbose { block() }
    }
}

let args = Arguments(CommandLine.arguments)
let observer = Observer(confPath: args.conf, verbose: args.verbose)

RunLoop.main.run()
