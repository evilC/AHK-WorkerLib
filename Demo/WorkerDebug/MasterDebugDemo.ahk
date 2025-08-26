#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\..\Lib\MasterLib.ahk

Persistent()
OutputDebug "DBGVIEWCLEAR"
master := MasterLib("WorkerDebug Master", 1)
masterGui := Gui("", master.nodeTitle)

masterGui.Add("Text", "xm w80" , "Worker status:")
txtStatus := masterGui.Add("Text", "x+10 w100 yp" , "Awaiting debug")
masterGui.Add("Text", "xm w80" , "Task Name:")
txtTaskName := masterGui.Add("Text", "x+10 w250 yp" , "")
masterGui.Add("Text", "xm w80", "Return value:")
txtRet := masterGui.Add("Text", "x+10 w250 yp" , "")
controls := Map("txtStatus", txtStatus, "txtTaskName", txtTaskName, "txtRet", txtRet)

masterGui.Show("x+50 y+" A_ScreenHeight - 200)
master.debugWorker("1", "WorkerDebug W1", "Sample Command", "Do Something", TaskComplete, DebugWorkerStarted)
masterGui.OnEvent("Close", Gui_Close)

DebugWorkerStarted(payload){
    global controls
    controls["txtStatus"].Text := "Running" 
    controls["txtTaskName"].Text := payload["taskData"]["taskName"]
    controls["txtRet"].Text := ""
}

TaskComplete(payload){
    global controls
    controls["txtStatus"].Text := "Ended"
    controls["txtRet"].Text := "ERRORLEVEL: " payload["body"]["result"]["ERRORLEVEL"] ", Text: " payload["body"]["result"]["text"]
}

Gui_Close(thisGui){
    ExitApp
}
