#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\..\Lib\WorkerLib.ahk

; Demos "Worker Debug" mode
OutputDebug "DBGVIEWCLEAR"
worker := WorkerLib("MasterDebugDemo.ahk", "1")
worker.initDebug("Sample Command", "Do Something", DoTask)
workerGui := Gui("")
workerGui.Show("w300 h50 x+50 y+" A_ScreenHeight - 300)
workerGui.OnEvent("Close", Gui_Close)

DoTask(taskName, task){
    global worker, workerGui
    static results := ["operation succeeded", "failure message 1", "failure message 2"]
    workerGui.Title := worker.nodeTitle
    Sleep 2000
    errorLevel := Random(0, 2)
    worker.taskEnded(Map("ERRORLEVEL", errorLevel, "text", results[errorLevel+1]))
    ExitApp
}

Gui_Close(thisGui){
    ExitApp
}