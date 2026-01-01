/// Communication module - Serial port and modem operations
/// Translated from Modula-2 RS.MOD, RS2.MOD, MODEM.MOD
/// and Pascal RADAR.PAS communication routines
module Radarpas.Communication

open System
open System.IO.Ports
open Radarpas.CoreTypes
open Radarpas.Crc

// ============================================================================
// SERIAL PORT ABSTRACTION
// ============================================================================

/// Serial port configuration
type SerialConfig = {
    PortName: string        // e.g., "COM1" or "/dev/ttyUSB0"
    BaudRate: int
    DataBits: int
    StopBits: StopBits
    Parity: Parity
    ReadTimeout: int        // milliseconds
    WriteTimeout: int
}

module SerialConfig =
    let default2400 = {
        PortName = "COM1"
        BaudRate = 2400
        DataBits = 8
        StopBits = StopBits.One
        Parity = Parity.None
        ReadTimeout = 1000
        WriteTimeout = 1000
    }

    let default9600 = { default2400 with BaudRate = 9600 }

/// Serial port state
type SerialState =
    | Closed
    | Open of SerialPort
    | Error of string

/// Interface for serial port operations
type ISerialPort =
    abstract member Open : unit -> Result<unit, string>
    abstract member Close : unit -> unit
    abstract member Send : byte array -> Result<unit, string>
    abstract member SendChar : char -> Result<unit, string>
    abstract member Receive : int -> Result<byte array, string>
    abstract member ReceiveChar : unit -> Result<char, string>
    abstract member BytesAvailable : unit -> int
    abstract member ClearBuffers : unit -> unit
    abstract member SendBreak : int -> unit
    abstract member IsOpen : bool

/// Real serial port implementation
type RealSerialPort(config: SerialConfig) =
    let mutable port : SerialPort option = None

    interface ISerialPort with
        member _.Open () =
            try
                let p = new SerialPort(
                    config.PortName,
                    config.BaudRate,
                    config.Parity,
                    config.DataBits,
                    config.StopBits)
                p.ReadTimeout <- config.ReadTimeout
                p.WriteTimeout <- config.WriteTimeout
                p.Open()
                port <- Some p
                Ok ()
            with ex ->
                Error ex.Message

        member _.Close () =
            port |> Option.iter (fun p ->
                if p.IsOpen then p.Close()
                p.Dispose())
            port <- None

        member _.Send data =
            match port with
            | None -> Error "Port not open"
            | Some p ->
                try
                    p.Write(data, 0, data.Length)
                    Ok ()
                with ex -> Error ex.Message

        member _.SendChar c =
            match port with
            | None -> Error "Port not open"
            | Some p ->
                try
                    p.Write([| byte c |], 0, 1)
                    Ok ()
                with ex -> Error ex.Message

        member _.Receive count =
            match port with
            | None -> Error "Port not open"
            | Some p ->
                try
                    let buffer = Array.zeroCreate count
                    let read = p.Read(buffer, 0, count)
                    Ok (buffer.[0..read-1])
                with
                | :? TimeoutException -> Ok [||]
                | ex -> Error ex.Message

        member _.ReceiveChar () =
            match port with
            | None -> Error "Port not open"
            | Some p ->
                try
                    let b = p.ReadByte()
                    Ok (char b)
                with
                | :? TimeoutException -> Error "Timeout"
                | ex -> Error ex.Message

        member _.BytesAvailable () =
            port |> Option.map (fun p -> p.BytesToRead) |> Option.defaultValue 0

        member _.ClearBuffers () =
            port |> Option.iter (fun p ->
                p.DiscardInBuffer()
                p.DiscardOutBuffer())

        member _.SendBreak durationMs =
            port |> Option.iter (fun p ->
                p.BreakState <- true
                Threading.Thread.Sleep(durationMs)
                p.BreakState <- false)

        member _.IsOpen =
            port |> Option.map (fun p -> p.IsOpen) |> Option.defaultValue false

    interface IDisposable with
        member this.Dispose() = (this :> ISerialPort).Close()

// ============================================================================
// RS-232 OPERATIONS (from RS.MOD, RS2.MOD)
// ============================================================================

/// Receive count
/// Original: PROCEDURE RxCount(): CARDINAL
let rxCount (port: ISerialPort) : int =
    port.BytesAvailable()

/// Transmit single character
/// Original: PROCEDURE Tx(Charac: char)
let tx (port: ISerialPort) (c: char) : Result<unit, string> =
    port.SendChar c

/// Receive single character
/// Original: PROCEDURE Rx(VAR Charac: char)
let rx (port: ISerialPort) : Result<char, string> =
    port.ReceiveChar()

/// Send data
/// Original: PROCEDURE Send(Buf: ARRAY OF BYTE; Len: CARDINAL)
let send (port: ISerialPort) (data: byte array) : Result<unit, string> =
    port.Send data

/// Receive data
/// Original: PROCEDURE Receive(VAR Buf: ARRAY OF BYTE; Len: CARDINAL)
let receive (port: ISerialPort) (count: int) : Result<byte array, string> =
    port.Receive count

/// Send break signal
/// Original: PROCEDURE Break(Time: CARDINAL)
let sendBreak (port: ISerialPort) (durationMs: int) : unit =
    port.SendBreak durationMs

/// Initialize port
/// Original: PROCEDURE Init(Baud: CARDINAL; ...)
let init (config: SerialConfig) : Result<ISerialPort, string> =
    let port = new RealSerialPort(config) :> ISerialPort
    match port.Open() with
    | Ok () -> Ok port
    | Error msg -> Error msg

/// Close port
/// Original: PROCEDURE CloseDown
let closeDown (port: ISerialPort) : unit =
    port.Close()

// ============================================================================
// MODEM OPERATIONS (from MODEM.MOD)
// ============================================================================

/// Modem result codes
type ModemResultCode =
    | Ok
    | Connect of int
    | Ring
    | NoCarrier
    | ErrorCode
    | Connect1200
    | NoDialtone
    | Busy
    | NoAnswer
    | Connect2400
    | Unknown of string

/// Parse modem response
let parseModemResponse (response: string) : ModemResultCode =
    let trimmed = response.Trim().ToUpperInvariant()
    match trimmed with
    | "OK" -> Ok
    | "CONNECT" -> Connect 300
    | "CONNECT 300" -> Connect 300
    | "CONNECT 1200" -> Connect1200
    | "CONNECT 2400" -> Connect2400
    | "RING" -> Ring
    | "NO CARRIER" -> NoCarrier
    | "ERROR" -> ErrorCode
    | "NO DIALTONE" -> NoDialtone
    | "BUSY" -> Busy
    | "NO ANSWER" -> NoAnswer
    | other -> Unknown other

/// Send AT command to modem
let sendCommand (port: ISerialPort) (command: string) : Result<unit, string> =
    port.Send (Text.Encoding.ASCII.GetBytes(command + "\r"))

/// Read response from modem
let readResponse (port: ISerialPort) (timeoutMs: int) : Result<string, string> =
    let endTime = DateTime.Now.AddMilliseconds(float timeoutMs)
    let buffer = Text.StringBuilder()

    let rec readLoop () =
        if DateTime.Now > endTime then
            Ok (buffer.ToString())
        elif port.BytesAvailable() > 0 then
            match port.ReceiveChar() with
            | Ok c ->
                buffer.Append(c) |> ignore
                if c = '\n' && buffer.ToString().TrimEnd().Length > 0 then
                    Ok (buffer.ToString().Trim())
                else
                    readLoop()
            | Error _ ->
                Ok (buffer.ToString())
        else
            Threading.Thread.Sleep(10)
            readLoop()

    readLoop()

/// Clear modem buffer
/// Original: PROCEDURE ClearBuffer
let clearBuffer (port: ISerialPort) : unit =
    port.ClearBuffers()

/// Dial a number
/// Original: PROCEDURE Call
let call (port: ISerialPort) (phoneNumber: string) (timeoutMs: int)
    : Async<ModemResultCode> =
    async {
        clearBuffer port

        match sendCommand port ("ATDT" + phoneNumber) with
        | Error _ -> return ErrorCode
        | Ok () ->
            // Wait for response
            let! _ = Async.Sleep 1000  // Initial delay
            match readResponse port timeoutMs with
            | Error _ -> return ErrorCode
            | Ok response -> return parseModemResponse response
    }

/// Hang up
/// Original: PROCEDURE HangUp
let hangUp (port: ISerialPort) : Async<Result<unit, string>> =
    async {
        // DTR drop or ATH command
        do! Async.Sleep 1000  // Guard time
        match sendCommand port "+++" with
        | Error e -> return Error e
        | Ok () ->
            do! Async.Sleep 1000  // Guard time
            match sendCommand port "ATH" with
            | Error e -> return Error e
            | Ok () -> return Ok ()
    }

// ============================================================================
// BLOCK TRANSFER WITH CRC (from RADIOTX.PAS, RADIORX.PAS)
// ============================================================================

/// Transmit block with CRC check
/// Original: PROCEDURE TxBlock_with_Check(VAR BlockAt; Size: INTEGER)
let txBlockWithCheck (port: ISerialPort) (data: byte array) : Result<unit, string> =
    let crc = calcCrc data
    let crcBytes = [| byte (crc &&& 0xFFus); byte (crc >>> 8) |]
    let fullData = Array.append data crcBytes
    port.Send fullData

/// Receive block with CRC check
/// Original: PROCEDURE RxBlock_with_Check(VAR BlockAt; Size: INTEGER; OK: BOOLEAN)
let rxBlockWithCheck (port: ISerialPort) (size: int) : Result<byte array, string> =
    match port.Receive (size + 2) with
    | Error msg -> Error msg
    | Ok received ->
        if received.Length < size + 2 then
            Error "Incomplete block received"
        else
            let data = received.[0..size-1]
            let receivedCrc =
                uint16 received.[size] |||
                (uint16 received.[size + 1] <<< 8)
            let calculatedCrc = calcCrc data
            if receivedCrc = calculatedCrc then
                Ok data
            else
                Error "CRC mismatch"

// ============================================================================
// RADAR DATA TRANSFER
// ============================================================================

/// Radar command characters
module RadarCommands =
    let requestPicture = 'P'
    let setTilt = 'T'
    let setRange = 'R'
    let setGain = 'G'
    let ack = '\006'  // ACK
    let nak = '\021'  // NAK
    let stx = '\002'  // STX - Start of text
    let etx = '\003'  // ETX - End of text

/// Send command to radar
/// Original: PROCEDURE SendCom(Command: char; DelTime: integer)
let sendRadarCommand (port: ISerialPort) (command: char) (delayMs: int)
    : Async<Result<unit, string>> =
    async {
        match port.SendChar command with
        | Error e -> return Error e
        | Ok () ->
            do! Async.Sleep delayMs
            return Ok ()
    }

/// Fetch picture from radar
/// Original: PROCEDURE FetchPic
let fetchPic (port: ISerialPort) (tilt: byte) (range: byte) (gain: byte)
    : Async<Result<byte array, string>> =
    async {
        // Send picture request
        let! cmdResult = sendRadarCommand port RadarCommands.requestPicture 100
        match cmdResult with
        | Error e -> return Error e
        | Ok () ->
            // Wait for STX
            let! stxResult =
                async {
                    let rec waitLoop attempts =
                        async {
                            if attempts <= 0 then return Error "Timeout waiting for STX"
                            else
                                match port.ReceiveChar() with
                                | Ok c when c = RadarCommands.stx -> return Ok ()
                                | Ok _ -> return! waitLoop (attempts - 1)
                                | Error _ ->
                                    do! Async.Sleep 100
                                    return! waitLoop (attempts - 1)
                        }
                    return! waitLoop 100
                }

            match stxResult with
            | Error e -> return Error e
            | Ok () ->
                // Receive picture data (size depends on range setting)
                let expectedSize =
                    match range with
                    | 0uy -> 8000
                    | 1uy -> 16000
                    | 2uy -> 32000
                    | _ -> 64000

                return! async {
                    match rxBlockWithCheck port expectedSize with
                    | Ok data -> return Ok data
                    | Error e -> return Error e
                }
    }

// ============================================================================
// MOCK IMPLEMENTATIONS FOR TESTING
// ============================================================================

/// Mock serial port for testing
type MockSerialPort() =
    let mutable inputBuffer = ResizeArray<byte>()
    let mutable outputBuffer = ResizeArray<byte>()
    let mutable isOpen = false

    member _.AddToInputBuffer(data: byte array) =
        inputBuffer.AddRange(data)

    member _.GetOutputBuffer() =
        let result = outputBuffer.ToArray()
        outputBuffer.Clear()
        result

    interface ISerialPort with
        member _.Open () =
            isOpen <- true
            Ok ()

        member _.Close () =
            isOpen <- false

        member _.Send data =
            outputBuffer.AddRange(data)
            Ok ()

        member _.SendChar c =
            outputBuffer.Add(byte c)
            Ok ()

        member _.Receive count =
            let available = min count inputBuffer.Count
            let result = inputBuffer.GetRange(0, available).ToArray()
            inputBuffer.RemoveRange(0, available)
            Ok result

        member _.ReceiveChar () =
            if inputBuffer.Count > 0 then
                let c = char inputBuffer.[0]
                inputBuffer.RemoveAt(0)
                Ok c
            else
                Error "No data"

        member _.BytesAvailable () = inputBuffer.Count

        member _.ClearBuffers () =
            inputBuffer.Clear()
            outputBuffer.Clear()

        member _.SendBreak _ = ()

        member _.IsOpen = isOpen

    interface IDisposable with
        member _.Dispose() = isOpen <- false
