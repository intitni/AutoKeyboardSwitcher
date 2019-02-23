import AppKit
import Carbon

let defaultPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Documents/AutoKeyboardSwitcher.json"

struct Pref: Codable {
    struct InputSource: Codable {
        let language: String?
        let inputSourceId: String?
    }
    let apps: [String: InputSource]
    let defaultInputSource: InputSource?
    
    static var empty: Pref { return .init(apps: [:], defaultInputSource: nil) }
}

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
            return .empty
        }
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(Pref.self, from: data) else {
            verboseDo { print("\(confPath) format incorrect") }
            return .empty
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
        
        if let source = pref.apps[identifier] {
            switchToInputSource(source)
        } else if let defaultInputSource = pref.defaultInputSource {
            verboseDo { print("Switching to default source") }
            switchToInputSource(defaultInputSource)
        }
    }
    
    func switchToInputSource(_ source: Pref.InputSource) {
        func switchToLanguage(_ language: String) {
            guard let source = TISCopyInputSourceForLanguage(language as CFString) else {
                verboseDo { print("Source for \(language) not found") }
                return
            }
            let value = source.takeRetainedValue()
            TISSelectInputSource(value)
            verboseDo { print("Done!") }
        }
        
        func switchToInputSourceId(_ id: String) {
            func allInputSources() -> Array<TISInputSource> {
                let selectableIsProperties = [
                    kTISPropertyInputSourceIsEnableCapable: true,
                    kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
                    ] as CFDictionary
                return TISCreateInputSourceList(selectableIsProperties, false).takeUnretainedValue() as! [TISInputSource]
            }
            
            guard let inputSourceOfId = allInputSources().first(where: {
                guard let rawid = TISGetInputSourceProperty($0, kTISPropertyInputSourceID) else { return false }
                let cfString = Unmanaged<CFString>.fromOpaque(rawid).takeUnretainedValue()
                return id == cfString as String
            }) else {
                verboseDo { print("Source for \(id) not found") }
                return
            }
            TISSelectInputSource(inputSourceOfId)
            verboseDo { print("Done!") }
        }
        
        if let language = source.language {
            verboseDo { print("Best Match! Switching to source of name \(language)") }
            switchToLanguage(language)
        } else if let inputSourceId = source.inputSourceId {
            verboseDo { print("Best Match! Switching to source of id \(inputSourceId)") }
            switchToInputSourceId(inputSourceId)
        }
    }
    
    private func verboseDo(_ block: ()->Void) {
        if verbose { block() }
    }
}

let args = Arguments(CommandLine.arguments)
let observer = Observer(confPath: args.conf, verbose: args.verbose)

CFRunLoopRun()
