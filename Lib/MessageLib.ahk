#Requires AutoHotkey v2.0
#Include _JXON.ahk

Class MessageLib{
    _registeredMessages := Map()    ; Holds callbacks for registered messages

    ; node:         A reference to either the MasterLib or WorkerLib that will Send or Receive messages
    ; debugMode:    If on, a long timeout will be set to stop messages timing out during debugging
    __New(node, debugMode := 0){
        this._node := node
        this._timeoutTime := debugMode ? 600000 : 5000 ; Timeout of 10 minutes in debug mode, else AHK default of 5s
    }

    ; Register to receive a message
    registerMessage(messageName, callback){
        this._registeredMessages[messageName] := RegisteredMessage(messageName, callback)
        OnMessage(0x004A, this._messageReceived.Bind(this))
        this._log("Registering for message | MessageName: " messageName)
    }

    ; This function sends the specified string to the specified window and returns the reply.
    ; The reply is 1 if the target window processed the message, or 0 if it ignored it.
    sendMessage(messageName, body, targetHwnd){
        data := this._buildMessage(messageName, body)
        StringToSend := this._jsonEncode(data)
        CopyDataStruct := Buffer(3*A_PtrSize)  ; Set up the structure's memory area.
        ; First set the structure's cbData member to the size of the string, including its zero terminator:
        SizeInBytes := (StrLen(StringToSend) + 1) * 2
        NumPut( "Ptr", SizeInBytes  ; OS requires that this be done.
            , "Ptr", StrPtr(StringToSend)  ; Set lpData to point to the string itself.
            , CopyDataStruct, A_PtrSize)
        this._log("SEND: " messageName " | To: " this._node._buildLogTo(data) " | Payload: " StringToSend)
        RetValue := SendMessage(0x004A, A_ScriptHwnd, CopyDataStruct,, targetHwnd,,,, this._timeoutTime) ; 0x004A is WM_COPYDATA.
        this._log("RESPONSE: " messageName ", Response: " RetValue)
        return RetValue  ; Return SendMessage's reply back to our caller.
    }

    ; Called when a message is received
    _messageReceived(senderHwnd, msg, messageNum, receivingHwnd){
        messageStr := this._decodeCopyData(msg)
        payload := this._jsonDecode(messageStr)
        messageName := payload["messageName"]
        this._log("RECEIVE: " messageName " | Payload: " messageStr)
        registeredMessage := this._registeredMessages[messageName]
        retVal := registeredMessage.callback.Call(senderHwnd, payload)
        this._log("RESPONSE: " messageName " | Response: " retVal)
        return 1    ; Signal message received
    }

    ; Builds the message
    ; Wraps the body in a standard header
    _buildMessage(messageName, body := ""){
        payload := Map("nodeName", this._node.nodeName, "nodeTitle", this._node.nodeTitle, "messageName", messageName, "body", body)
        return payload
    }

    ; Decodes WM_COPYDATA messages to a String
    _decodeCopyData(msg){
        StringAddress := NumGet(msg, 2*A_PtrSize, "Ptr")  ; Retrieves the CopyDataStruct's lpData member.
        return StrGet(StringAddress)  ; Copy the string out of the structure.
    }

    ; Object to String
    _jsonEncode(data){
        return Jxon_Dump(data)
    }

    ; String to Object
    _jsonDecode(data){
        return Jxon_Load(&data)
    }

    _log(string){
        OutputDebug("AHK| MESSAGELIB " this._node.nodeTitle "(" A_ScriptHwnd ") | " string)
    }
}

Class RegisteredMessage{
    __New(messageName, callback){
        this.messageName := messageName
        this.callback := callback
    }
}

; Use this when calling a function or method from within a receive message callback
; ie you received a message, and you want to then send the next message in the chain
; It will ensure that the method call happens AFTER the response has been handled
ScheduleCall(callback){
    Critical                ; Set this thread to be uninterruptable
    SetTimer(callback, -1)  ; Fire the callback once this thread ends
}