#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\Lib\MasterLib.ahk

Persistent()
OutputDebug "DBGVIEWCLEAR"
master := MasterLib("Master Demo", 1)
masterGui := Gui("", master.nodeTitle)
controls := Map()

Loop 3 {
    y := 5 + ((A_Index - 1) * 20)
    masterGui.Add("Text", "xm y" y , "Worker " A_Index)
    btnRun :=  masterGui.Add("Button", "x+10 h20 yp-3", "Run")
    btnRun.OnEvent("Click", RunWorker.Bind(A_Index "")) ; Always ensure node name is a string
    masterGui.Add("Text", "x+10 y" y , "Return value:")
    txtRet := masterGui.Add("Text", "x+10 w250 y" y , "")
    controls[A_Index ""] := Map("btnRun", btnRun, "txtRet", txtRet)
}
masterGui.Show("x+50 Minimize")
; Enable this to automatically run a worker on start
; RunWorker("1", 0, 0)

; Called when run is clicked for a worker
RunWorker(workerNodeName, GuiCtrlObj, Info){
    global master, controls
    controls[workerNodeName]["btnRun"].Enabled := 0
    controls[workerNodeName]["txtRet"].Text := ""
    master.runWorker(workerNodeName, "Worker " workerNodeName, "Sample Command", "Do Something", TaskComplete)
}

; Called when a worker completes a task
TaskComplete(payload){
    global controls
    controls[payload["nodeName"]]["btnRun"].Enabled := 1
    controls[payload["nodeName"]]["txtRet"].Text := "ERRORLEVEL: " payload["body"]["result"]["ERRORLEVEL"] ", Text: " payload["body"]["result"]["text"]
}

masterGui.OnEvent("Close", Gui_Close)

Gui_Close(thisGui){
    ExitApp
}