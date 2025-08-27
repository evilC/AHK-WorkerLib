#Requires AutoHotkey v2.0
#Include MessageLib.ahk


Class MasterLib{
    nodeName := ""
    nodeTitle := ""
    _isMaster := 0

    _workers := Map()
    _taskCompleteCallbacks := Map()
    _debugTaskStartedCallback := 0

    __New(nodeName, debugMode := 0){
        this._log("Initialized")
        this.nodeName := nodeName
        this.nodeTitle := nodeName
        this._debugMode := debugMode
        this._msg := MessageLib(this, debugMode)
        this._msg.registerMessage("WorkerLibInitInfo", this._receiveWorkerInit.Bind(this))
    }

    ; Normal operation - start a worker and pass it needed info to send a message back with it's HWND
    ; We can't just get the HWND from the process ID, because we are using Run, and the GUI may not be active by the time Run executes.
    ; We can't use RunWait because it would never return
    runWorker(scriptName, workerNodeName, workerTitle, taskName, task, callback){
        workerNodeName := workerNodeName ""
        workerTitle := workerTitle ""
        this._taskCompleteCallbacks[workerTitle] := callback
        this._workers[workerNodeName] := Map("workerTitle", workerTitle, "workerHwnd", 0, "workerTask", Map("taskName", taskName, "task", task))
        Run(A_AhkPath " WorkerDemo.ahk " A_ScriptHwnd " `"" workerNodeName "`" `"" workerTitle "`" " this._debugMode,,,)
    }

    ; Normal operation - worker was launched. It replies with it's HWND
    _receiveWorkerInit(senderHwnd, payload){
        workerNodeName := payload["nodeName"]
        workerTitle := payload["nodeTitle"]
        this._workers[workerNodeName]["workerHwnd"] := senderHwnd
        ScheduleCall(this._sendWorkerInit.Bind(this,workerNodeName, workerTitle))
        return 1
    }

    ; Allows launching of a worker in "Worker Debug" mode (Allows debugging of a worker)
    ; The Master will already be running (And potentially in debug mode too)
    ; The *Master* will call this method to set it up ready to receive a request from the worker to connect
    debugWorker(workerNodeName, workerTitle, taskName, task, callback, debugTaskStartedCallback){
        this._taskCompleteCallbacks[workerTitle] := callback
        this._debugTaskStartedCallback := debugTaskStartedCallback
        this._msg.registerMessage("WorkerLibDebugRequest", this._receiveWorkerInitDebug.Bind(this, workerNodeName, workerTitle, taskName, task))
    }

    ; Equivalent of _receiveWorkerInit, but when running in "Worker Debug" mode
    _receiveWorkerInitDebug(workerNodeName, workerTitle, taskName, task, senderHwnd, payload){
        workerNodeName := workerNodeName ""
        workerTitle := workerTitle ""
        this._workers[workerNodeName] := Map("workerTitle", workerTitle, "workerHwnd", 0, "workerTask", Map("taskName", taskName, "task", task))
        this._workers[workerNodeName]["workerHwnd"] := senderHwnd
        ScheduleCall(this._sendWorkerInit.Bind(this,workerNodeName, workerTitle))
        return 1
    }

    ; Send initialization data to a Worker (Used in normal mode and Worker Debug mode)
    _sendWorkerInit(workerNodeName, workerTitle){
        body :=  Map("workerNodeName", workerNodeName, "workerTitle", workerTitle, "masterTitle", this.nodeTitle, "taskData", this._workers[workerNodeName]["workerTask"])
        this._msg.registerMessage("WorkerLibTaskEnded", this._workerTaskEnded.Bind(this))
        if (this._debugTaskStartedCallback != 0){
            ; In "Worker Debug" mode. Notify Master script that we started debugging a worker
            this._debugTaskStartedCallback.Call(body)
        }
        retVal := this._msg.sendMessage("WorkerLibInitInfo", body, this._workers[workerNodeName]["workerHwnd"])
        if (retVal != 1){
            throw "Worker did not respond OK to WorkerLibInitInfo message"
        }
        return 1
    }

    ; Worker signalled task ended
    _workerTaskEnded(senderHwnd, payload){
        ScheduleCall(this._taskCompleteCallbacks[payload["nodeTitle"]].Bind(payload))
    }

    ; Builds human friendly "To:" string when a Master sends or Responds to a message
    _buildLogTo(data){
        return data["nodeTitle"]
    }

    _log(string){
        OutputDebug("AHK| MASTERLIB " this.nodeName "(" A_ScriptHwnd ") | " string)
    }
}