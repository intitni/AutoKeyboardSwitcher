# AutoKeyboardSwitcher

This is a simple command line tool to switch input method for you according to the frontmost application automatically. It stops your nightmare when your input method was set to Chinese, and then you switch to iTerm and start to type your password, and someone else is staring at your monitor. God knows why iTerm does not force input method to be English when inputting passwords.

To use it, just launch the tool any way you like. 

Not really. Before that, you will need to create a file at `~/Documents/AutoKeyboardSwitcher.json`, and type in the rules.

```json
{
    "com.apple.dt.Xcode": "en",
    "com.googlecode.iterm2": "en",
    "com.microsoft.VSCode": "en"
}
```

If you want a different path, change it in code.