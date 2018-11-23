# AutoKeyboardSwitcher

This is a simple command line tool to switch input method for you according to the frontmost application automatically. It stops your nightmare when your input method was set to Chinese, and then you switch to iTerm and start to type your password, and someone else is staring at your monitor. God knows why iTerm does not force input method to be English when inputting passwords.

To use it, just launch the tool any way you like. 

Not really. Before that, you will need to create a configuration file in JSON format with rules.

```json
{
    "com.apple.dt.Xcode": "en",
    "com.googlecode.iterm2": "en",
    "com.microsoft.VSCode": "en"
}
```

You may use the configuration file with argument `--conf` following by the file path. You may use `--verbose` to inspect outputs, for example, to get identifiers of apps when you switch between apps.

You are recommended to use launchd to start the tool on startup.