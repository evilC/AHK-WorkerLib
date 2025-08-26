#Requires AutoHotkey v2.0
#Include MessageLib.ahk

Class WorkerLib{
    nodeName := "Unnamed Worker"
    nodeTitle := "Untitled Worker"
    masterTitle := ""
    _task := 0
    _masterHwnd := 0
    _isMaster := 0
    _taskFn := 0

    __New(masterScriptName := "", workerName := ""){
        this._log("Initialized")
        if (masterScriptName != ""){
            ; "Worker Debug" mode. Master is already running
            ; Initialize MessageLib in debug mode. This sets a long timeout on messages, to allow us to debug
            this._msg := MessageLib(this, 1)
            ; Get HWND of master
            prevDetectHiddenWindows := A_DetectHiddenWindows
            DetectHiddenWindows True
            this._masterHwnd := WinExist(masterScriptName " ahk_class AutoHotkey")
            DetectHiddenWindows prevDetectHiddenWindows
            if (this._masterHwnd == 0){
                throw "Failed to get Master HWND"
            }
        } else {
            ; Normal Mode - Master launched Worker and passed parameters
            this._masterHwnd := A_Args[1]+0     ; HWND - Convert to int
            this.nodeName := A_Args[2]          ; NodeName of the worker
            this.nodeTitle := A_Args[3]         ; Title of the worker (Mainly used to set GUI title)
            debugMode := A_Args[4]+0            ; MessageLib Debug Mode on / off - Convert to int
            this._msg := MessageLib(this, debugMode)
        }
        this._msg.registerMessage("WorkerLibInitInfo", this._receiveWorkerInit.Bind(this))
    }

    ; Used in Normal Mode - Causes the Worker to request Initialization info from the Master
    init(taskFn){
        this._taskFn := taskFn
        retval := this._msg.sendMessage("WorkerLibInitInfo", "", this._masterHwnd)
        return retval
    }

    ; Used in Worker Debug mode
    initDebug(taskName, task, taskFn){
        ; Send WorkerLibInitInfo message to master
        this._task := Map("taskName", taskName, "task", task)
        this._taskFn := taskFn
        retval := this._msg.sendMessage("WorkerLibDebugRequest", "", this._masterHwnd)
        if (retval != 1){
            throw "Master did not report success to request to Initialize debug"
        }
        return 1
    }

    ; Master sent initialization info to this Worker
    _receiveWorkerInit(senderHwnd, payload){
        this.nodeName := payload["body"]["workerNodeName"]
        this.nodeTitle := payload["body"]["workerTitle"]
        this.masterTitle := payload["body"]["masterTitle"]
        this._task := payload["body"]["taskData"]
        ; Start the Task
        ScheduleCall(this._taskFn.Bind(this._task["taskName"], this._task["task"]))
        return 1
    }

    ; Call when the task is complete
    taskEnded(result){
        this._task["result"] := result
        retVal := this._msg.sendMessage("WorkerLibTaskEnded", this._task, this._masterHwnd)
    }

    _buildLogTo(nodeName := ""){
        if (this.masterTitle == ""){
            ; Used in Worker Debug mode. We don't know the title of the master yet
            ; Master might be windowless and not have a title
            return "Debug Master"
        } else {
            return this.masterTitle
        }
    }

    _log(string){
        OutputDebug("AHK| WORKERLIB " this.nodeName "(" A_ScriptHwnd ") | " string)
    }
}
