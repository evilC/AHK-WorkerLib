#Requires AutoHotkey v2.0
#SingleInstance Off
#Include ..\Lib\WorkerLib.ahk

worker := WorkerLib()
worker.init(MyTask)
workerGui := Gui("", worker.nodeTitle)
workerGui.Show("w250 h50 x+50 Minimize")

workerGui.OnEvent("Close", Gui_Close)

MyTask(taskName, task){
    static results := ["operation succeeded", "failure message 1", "failure message 2"]
    Sleep 2000
    errorLevel := Random(0, 2)
    worker.taskEnded(Map("ERRORLEVEL", errorLevel, "text", results[errorLevel+1]))
    ExitApp
}

Gui_Close(thisGui){
    ExitApp
}