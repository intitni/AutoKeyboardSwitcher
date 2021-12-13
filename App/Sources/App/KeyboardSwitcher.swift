import AppKit
import Carbon
import SwiftUI

let defaultPath =
    "\(FileManager.default.homeDirectoryForCurrentUser.path)/Documents/AutoKeyboardSwitcher.json"

typealias AppID = String
typealias InputSourceID = String

private var memory = [AppID: InputSourceID]()

struct Configuration: Codable {
    struct InputSource: Codable {
        let language: String?
        let inputSourceId: InputSourceID?
        let memorize: Bool?
    }
    let apps: [AppID: InputSource]
    let defaultInputSource: InputSource?

    static var empty: Configuration { return .init(apps: [:], defaultInputSource: nil) }
}

struct RunningApp {
    var id: AppID
    var name: String
}

protocol KeyboardSwitcherType {
    var configurationPath: String? { get }
    var configuration: Configuration { get }
    var currentApp: RunningApp? { get }

    func setConfigurationPath(_ configurationPath: String)
    func reloadConfiguration()
}

class KeyboardSwitcher: KeyboardSwitcherType, ObservableObject {
    @Published private(set) var configurationPath: String? = UserDefaults.standard.string(
        forKey: "ConfigurationPath"
    )
    @Published private(set) var configuration: Configuration = .empty
    @Published private(set) var currentApp: RunningApp?
    @Published private(set) var isConfiurationUnreadable: Bool = false

    private var inputMethodIdBeforeActivatingApp: String?

    init() {
        currentApp = {
            guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
            return RunningApp(
                id: application.bundleIdentifier ?? "Unknown",
                name: application.localizedName ?? "Unknown"
            )
        }()
        reloadConfiguration()
        Task { await observeActiveAppChange() }
        Task { await observeActiveAppGone() }
    }

    func setConfigurationPath(_ configurationPath: String) {
        self.configurationPath = configurationPath
        UserDefaults.standard.set(configurationPath, forKey: "ConfigurationPath")
        reloadConfiguration()
    }

    func reloadConfiguration() {
        guard let configurationPath = configurationPath else { return }
        guard let data = FileManager().contents(atPath: configurationPath) else {
            isConfiurationUnreadable = true
            return
        }
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(Configuration.self, from: data) else {
            isConfiurationUnreadable = true
            return
        }
        isConfiurationUnreadable = false
        configuration = result
    }

    private func observeActiveAppChange() async {
        for await noti in NSWorkspace.shared.notificationCenter.notifications(
            named: NSWorkspace.didActivateApplicationNotification
        ) {
            guard
                let info = noti.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication,
                let identifier = info.bundleIdentifier,
                identifier != "com.intii.AutoKeyboardSwitcher"
            else { continue }
            print("enter app: \(identifier)")

            await noteDownInputMethodID()
            currentApp = RunningApp(id: identifier, name: info.localizedName ?? "Unknown")
            
            @MainActor func switchInputSource(to inputSource: Configuration.InputSource) {
                if let inputSourceId = inputSource.inputSourceId {
                    switchToInputSourceId(inputSourceId)
                } else if let language = inputSource.language {
                    switchToLanguage(language)
                }
            }
            
            let inputSource = configuration.apps[identifier]
            let defaultInputSource = configuration.defaultInputSource
            if inputSource?.memorize ?? defaultInputSource?.memorize ?? false, let mem = memory[identifier] {
                await switchToInputSourceId(mem)
            } else if let source = inputSource {
                await switchInputSource(to: source)
            } else if let source = defaultInputSource {
                await switchInputSource(to: source)
            }
        }
    }

    private func observeActiveAppGone() async {
        for await noti in NSWorkspace.shared.notificationCenter.notifications(
            named: NSWorkspace.didDeactivateApplicationNotification
        ) {
            guard
                let info = noti.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication,
                let identifier = info.bundleIdentifier
            else { continue }
            print("leave app: \(identifier)")

            if configuration.apps[identifier]?.memorize
                ?? self.configuration.defaultInputSource?.memorize ?? false
            {
                await memorizeInputSource(for: identifier)
            }
        }
    }

    @MainActor
    private func noteDownInputMethodID() {
        inputMethodIdBeforeActivatingApp = Keyboard.currentInputMethodID
    }

    @MainActor
    private func memorizeInputSource(for appID: AppID) {
        print(
            "memorize input source for app: \(appID), \(inputMethodIdBeforeActivatingApp ?? "--")"
        )
        memory[appID] = inputMethodIdBeforeActivatingApp
    }

    @MainActor
    private func switchToLanguage(_ language: String) {
        print("switch to language: \(language)")
        guard let source = TISCopyInputSourceForLanguage(language as CFString) else {
            return
        }
        let value = source.takeRetainedValue()
        TISSelectInputSource(value)
    }

    @MainActor
    private func switchToInputSourceId(_ id: String) {
        print("switch to input source: \(id)")
        func allInputSources() -> [TISInputSource] {
            let selectableIsProperties =
                [
                    kTISPropertyInputSourceIsEnableCapable: true,
                    kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource ?? ""
                        as CFString,
                ] as CFDictionary
            return TISCreateInputSourceList(selectableIsProperties, false).takeUnretainedValue()
                as! [TISInputSource]
        }

        guard
            let inputSourceOfId = allInputSources().first(where: {
                guard let rawid = TISGetInputSourceProperty($0, kTISPropertyInputSourceID) else {
                    return false
                }
                let cfString = Unmanaged<CFString>.fromOpaque(rawid).takeUnretainedValue()
                return id == cfString as String
            })
        else {
            return
        }
        TISSelectInputSource(inputSourceOfId)
    }
}

enum Keyboard {
    static var currentInputMethodID: String {
        let currentInputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let value = TISGetInputSourceProperty(currentInputSource, kTISPropertyInputSourceID)
        guard let value = value,
            let id = Unmanaged<AnyObject>.fromOpaque(value).takeUnretainedValue() as? String
        else { return "" }
        return id
    }
}
