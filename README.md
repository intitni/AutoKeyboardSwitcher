# AutoKeyboardSwitcher

This is a simple command line tool to switch input method for you according to the frontmost application automatically. It stops your nightmare when your input method was set to Chinese, and then you switch to iTerm and start to type your password, and someone else is staring at your monitor. God knows why iTerm does not force input method to be English when inputting passwords.

To use it, just launch the tool any way you like. 

Not really. Before that, you will need to create a configuration file in JSON format with rules.

```json
{
    "apps": {
        "com.apple.dt.Xcode": {
            "language": "en"
        },
        "com.googlecode.iterm2": {
            "inputSourceId": "com.apple.keylayout.ABC"
        },
        "com.microsoft.VSCode": {
            "inputSourceId": "com.apple.keylayout.ABC"
        },
        "co.zeit.hyper": {
            "inputSourceId": "com.apple.keylayout.ABC"
        },
        "com.tencent.qq": {
            "inputSourceId": "com.apple.inputmethod.SCIM.ITABC"
        }
    },
    "defaultInputSource": {
        "inputSourceId": "com.apple.keylayout.ABC"
    }
}
```

You may specify configuration path with argument `--conf` following by the file path. 

You may use `--verbose` to inspect outputs, for example, to get identifiers of apps when you switch between apps.