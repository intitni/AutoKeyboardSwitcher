import Combine
import SwiftUI

final class PreferencesViewModel: ObservableObject {
    let keyboardSwitcher: KeyboardSwitcherType

    var frontmostAppName: String { keyboardSwitcher.currentApp?.name ?? "" }
    var frontmostAppIdentifier: String { keyboardSwitcher.currentApp?.id ?? "" }
    var configurationPath: String { keyboardSwitcher.configurationPath ?? "Unset" }

    private var cancellables = Set<AnyCancellable>()

    init<KS>(keyboardSwitcher: KS) where KS: KeyboardSwitcherType & ObservableObject {
        self.keyboardSwitcher = keyboardSwitcher
        keyboardSwitcher.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func updateConfigurationPath(_ path: String) {
        keyboardSwitcher.setConfigurationPath(path)
    }
    
    func reloadConfiguration() {
        keyboardSwitcher.reloadConfiguration()
    }

    func pickConfigurationFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let path = panel.url?.path {
            updateConfigurationPath(path)
        }
    }
}
