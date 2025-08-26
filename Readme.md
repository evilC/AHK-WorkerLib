# WorkerLib
## About
A library to offload tasks from a "Master" script on to one or more "Worker" scripts.  
Workers can perform long-running Tasks which perform blocking operations, and will notify the Master script once the Task is complete.  
If multiple Tasks are running, Task Complete for each worker will fire in the order they complete.  
This enables a sort of "True Multi-Threading" in AHK
This would not be possible using a non-repeating SetTimer, as subsequent SetTimer calls would interrupt previous ones...  
... so the notification of complete on Task #1 could not happen until Task #2 completes and stops interrupting Task #1.  

## How it works
Workers are separate instances of AutoHotkey
The Master runs new instance AutoHotkey, and has it run a Worker script.  
On the command-line, it passes it's HWND to the Worker script.  
The Worker then uses `SendMessage` to send a message to the Master to get Task info.  
The Master sends the Task info to the Worker.  
The Worker performs the Task and sends a message to the Master to notify when the Task ends.

## Features
1. JSON support  
All communication between the Master and the Workers uses JSON strings.  
There are Serialized / Deserialized for you, so you can easily pass lots of data betwen the Master and Workers  
1. Debuggable  
You can launch the library in Debug Mode, which sets the Timeout of messages to 10 minutes  
This gives you enough time to step through code without messages timing out and causing an error.  
You can debug in two ways:  
    1. Normal Debugging  
    In this mode, you can only debug the Master (Because the Master runs a new copy of AHK)  
    It might be theoretically possible to debug a Worker in this mode (You could maybe attach to the process)...  
    ... but it would probably be cumbersome
    1. "Worker Debug" mode  
    In this mode, you can debug the Master **and** a Worker.  
    The Master is started first in one instance of the IDE (eg VSCode), but it does not issue any Tasks to the Worker.  
    Instead, it sits there and waits for a Worker to send it a Message asking it to perform a specific Task.  
    In another IDE instance, you then debug the Worker, and it sends a message to the Master, causing the Master to send it a Task

## Debugging
My debugging requirements are:  
1. Proper variable inspection whilst debugging (Can inspect contents of Maps)  
2. I wish to see any `OutputDebug` output in [Sysinternals DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview), not in VSCode (So I can see one timeline to help me work out in what order things happened)
3. Ability to interactively debug two scripts simultaneously in two separate copies of VSCode.  

(3) is only really needed if trying to debug Master and Worker scripts at the same time.  
I have found two possible combinations of VSCode extensions that work:  
Langauage extension: [AutoHotkey v2 Language Support](https://marketplace.visualstudio.com/items?itemName=thqby.vscode-autohotkey2-lsp)
If you do not need (3), then the [AutoHotkey Debug](https://github.com/helsmy/autohotkey-debug-adapter) debugging extension  
If you need all 3, then use [vscode-autohotkey-debug](https://marketplace.visualstudio.com/items?itemName=zero-plusplus.vscode-autohotkey-debug) debugging extension with the following modification:  
Modify `<User Dir>\.vscode\extensions\zero-plusplus.vscode-autohotkey-debug-1.11.1\build\extension.js`, delete `this.sendStderrCommand("redirect"),` 
See [here](https://github.com/helsmy/autohotkey-debug-adapter/discussions/28) for a discussion on this.
### Initial setup
1. Install Language and Debugging extensions in VSCode  
1. Open the repo folder in VSCode
1. Select one of the AHK files in the file explorer
1. In the top right, click the down arrow next to the play icon and select `Debug Configurations`
1. Click the `Open 'launch.json'` button in the dialog that appears  
1. `F5` will now allow you to debug
Observed issue - if folder name has a space in it, does not seem to hit breakpoints.

### Simultaneous Master / Worker interactive debugging
#### Initial setup
In order to be able to debug both a Master and Worker in VSCode, I do the following:  
1. Open a 2nd VSCode instance
1. `File > Add Folder to Workspace...`, choose repo folder
1. `File > Save Workspace As...`, save workspace file somewhere (Can be in the repo folder)
1. When opening 2nd instance in the future, right click the workspace file and select `Open with Code`
1. You can now set breakpoints in the 2nd VSCode instance

#### Workflow
The simplest way is to have the Master running before the Worker. This is because the Master launches the Worker...  
So to debug both when running the Master first, you would have to attach to the process of the Worker
You will need a specially crafted Master and Worker to do this (The `WorkerDebug` example shows this)  
ToDo: Add instructions

1. Open a 2nd VSCode instance. use `File > Open File...` and select the 2nd script
You can use `File > Open File...` again to open other files (eg the library). If you do so, changes made in the 1st VSCode instance will instantly appear in the 2nd instance
1. You may now set breakpoints in either file and hit `F5` to debug
1. Note that if you use `SendMessage` and send a message to a script that is being debugged, if you delay that script replying (`return` not executed) before the timeout is reached (Default 5s)
then a timeout error will occur. It is recommended to use [SendMessageCallback](https://www.autohotkey.com/boards/viewtopic.php?t=124720) to avoid this. (See `Sender.ahk (script execution continues after SendMessage):`)