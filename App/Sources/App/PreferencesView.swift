import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    init(viewModel: PreferencesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            FilePicker(viewModel: viewModel)
            Text(viewModel.frontmostAppName)
            Text(viewModel.frontmostAppIdentifier)
            Toggle("Launch at start", isOn: $launchAtLogin.isEnabled)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

struct FilePicker: View {
    @ObservedObject var viewModel: PreferencesViewModel

    init(viewModel: PreferencesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Button(action: { viewModel.pickConfigurationFile() }, label: { Label(viewModel.configurationPath, systemImage: "doc.badge.plus") })
                .buttonStyle(.plain)
            Button(action: { viewModel.reloadConfiguration() },
                   label: { Text("Reload") })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    class FakeKeyboardSwitcher: KeyboardSwitcherType, ObservableObject {
        var configurationPath: String? = "None"
        var configuration: Configuration = .empty
        var currentApp: RunningApp? = .init(
            id: "com.intii.AbnormalMouseApp",
            name: "Abnormal Mouse"
        )

        func setConfigurationPath(_ configurationPath: String) {
            self.configurationPath = configurationPath
        }
        
        func reloadConfiguration() {}
    }

    static var previews: some View {
        PreferencesView(viewModel: PreferencesViewModel(keyboardSwitcher: FakeKeyboardSwitcher()))
            .frame(width: 400, alignment: .center)
    }
}
