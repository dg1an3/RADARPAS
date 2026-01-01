/// Main radar module - Application logic and loops
/// Translated from Pascal RADAR.PAS and Modula-2 MAIN.MOD
module Radarpas.Radar

open System
open Radarpas.CoreTypes
open Radarpas.TimeDate
open Radarpas.IO
open Radarpas.Graphics
open Radarpas.Pictures
open Radarpas.Stations
open Radarpas.ScreenHandler
open Radarpas.Communication

// ============================================================================
// APPLICATION STATE
// ============================================================================

/// Current application mode
/// Original: ModeType = (Modem, Interactive, WaitPic, RxPic, RxGraph)
type AppMode =
    | ModemMode
    | InteractiveMode
    | WaitingForPicture
    | ReceivingPicture
    | ReceivingGraph

/// Complete application state (immutable)
type AppState = {
    Mode: AppMode
    Stations: Station list
    CurrentStation: Station option
    CurrentPicture: PictureRec option
    PictureList: PictureRec list
    RadarParams: RadarParams
    Screen: ScreenState
    Connected: bool
    AutoMode: bool
    LastError: string option
}

module AppState =
    let initial = {
        Mode = InteractiveMode
        Stations = []
        CurrentStation = None
        CurrentPicture = None
        PictureList = []
        RadarParams = RadarParams.empty
        Screen = ScreenState.initial
        Connected = false
        AutoMode = false
        LastError = None
    }

    let setMode mode state = { state with Mode = mode }
    let setCurrentStation station state = { state with CurrentStation = Some station }
    let setConnected connected state = { state with Connected = connected }
    let setError error state = { state with LastError = Some error }
    let clearError state = { state with LastError = None }

// ============================================================================
// COMMAND HANDLING (Pure Functions)
// ============================================================================

/// Commands that can be executed
type Command =
    | ToggleMap1
    | ToggleMap2
    | ToggleRangeMarkers
    | ToggleHelp
    | NextHelpScreen
    | ShowPictureMenu
    | ShowStationMenu
    | NextPicture
    | PreviousPicture
    | FirstPicture
    | LastPicture
    | DeletePicture
    | SavePicture
    | FetchNewPicture
    | CallStation
    | HangUp
    | ToggleAutoMode
    | Configure
    | Quit
    | NoOp

/// Map keyboard input to command
/// Original: Part of PROCEDURE ExecCom(Key: CHAR)
let keyToCommand (key: ExtendedKey) : Command =
    match key with
    | F1 -> ToggleHelp
    | F2 -> ToggleMap1
    | F3 -> ToggleMap2
    | F4 -> ToggleRangeMarkers
    | F5 -> ShowPictureMenu
    | F6 -> ShowStationMenu
    | F7 -> ToggleAutoMode
    | F8 -> Configure
    | PageUp -> PreviousPicture
    | PageDown -> NextPicture
    | Home -> FirstPicture
    | End -> LastPicture
    | Delete -> DeletePicture
    | Char 's' | Char 'S' -> SavePicture
    | Char 'f' | Char 'F' -> FetchNewPicture
    | Char 'c' | Char 'C' -> CallStation
    | Char 'h' | Char 'H' -> HangUp
    | Escape -> Quit
    | _ -> NoOp

/// Apply a command to the state (pure transformation)
let applyCommand (command: Command) (state: AppState) : AppState =
    match command with
    | ToggleMap1 ->
        { state with Screen = ScreenState.toggleMap 0 state.Screen }

    | ToggleMap2 ->
        { state with Screen = ScreenState.toggleMap 1 state.Screen }

    | ToggleRangeMarkers ->
        { state with Screen = ScreenState.toggleRangeMarkers state.Screen }

    | ToggleHelp ->
        { state with Screen = ScreenState.toggleHelp state.Screen }

    | NextHelpScreen ->
        { state with Screen = ScreenState.setHelpMode (state.Screen.HelpMode + 1) state.Screen }

    | NextPicture ->
        let newList = state.PictureList
        let currentIdx =
            state.CurrentPicture
            |> Option.bind (fun p -> newList |> List.tryFindIndex (fun x -> x = p))
            |> Option.defaultValue -1
        let nextIdx = min (List.length newList - 1) (currentIdx + 1)
        let nextPic = if nextIdx >= 0 then Some newList.[nextIdx] else None
        { state with CurrentPicture = nextPic }

    | PreviousPicture ->
        let newList = state.PictureList
        let currentIdx =
            state.CurrentPicture
            |> Option.bind (fun p -> newList |> List.tryFindIndex (fun x -> x = p))
            |> Option.defaultValue 0
        let prevIdx = max 0 (currentIdx - 1)
        let prevPic = if prevIdx < List.length newList then Some newList.[prevIdx] else None
        { state with CurrentPicture = prevPic }

    | FirstPicture ->
        let firstPic = state.PictureList |> List.tryLast  // Oldest is last in sorted list
        { state with CurrentPicture = firstPic }

    | LastPicture ->
        let lastPic = state.PictureList |> List.tryHead  // Newest is first in sorted list
        { state with CurrentPicture = lastPic }

    | ToggleAutoMode ->
        { state with AutoMode = not state.AutoMode }

    | _ ->
        state  // Commands with side effects handled separately

// ============================================================================
// EFFECTFUL OPERATIONS
// ============================================================================

/// Execute a command that requires I/O
let executeCommand (command: Command) (port: ISerialPort option) (baseDir: string)
    (state: AppState) : Async<AppState> =
    async {
        match command with
        | DeletePicture ->
            match state.CurrentPicture, state.CurrentStation with
            | Some pic, Some station ->
                let stationDir = Station.directoryPath baseDir station
                match deletePictureFile stationDir pic with
                | Ok () ->
                    let newList, _ = deletePicture state.PictureList
                        (state.PictureList |> List.tryFindIndex ((=) pic) |> Option.defaultValue -1)
                    let newPic = newList |> List.tryHead
                    return { state with PictureList = newList; CurrentPicture = newPic }
                | Error msg ->
                    return AppState.setError msg state
            | _ -> return state

        | SavePicture ->
            match state.CurrentPicture, state.CurrentStation with
            | Some pic, Some station when PicFlagSet.contains NotSaved pic.Flags ->
                let stationDir = Station.directoryPath baseDir station
                let! result = savePicture stationDir pic
                match result with
                | Ok savedPic ->
                    let newList =
                        state.PictureList
                        |> List.map (fun p -> if p = pic then savedPic else p)
                    return { state with PictureList = newList; CurrentPicture = Some savedPic }
                | Error msg ->
                    return AppState.setError msg state
            | _ -> return state

        | FetchNewPicture ->
            match port, state.CurrentStation with
            | Some p, Some station when state.Connected ->
                let! result = fetchPic p
                    state.RadarParams.Tilt
                    state.RadarParams.Range
                    state.RadarParams.Gain
                match result with
                | Ok data ->
                    let newPic = {
                        PictureRec.empty with
                            Tilt = state.RadarParams.Tilt
                            Range = state.RadarParams.Range
                            Gain = state.RadarParams.Gain
                            TimeOfPic = getTime()
                            Data = Some data
                            Size = uint32 data.Length
                            Flags = Set.singleton NotSaved
                    }
                    let newList, _ = addPicture state.PictureList newPic
                    return { state with
                                PictureList = newList
                                CurrentPicture = Some newPic
                                Screen = ScreenState.setMessage (Some "Picture received") state.Screen }
                | Error msg ->
                    return AppState.setError msg state
            | _ -> return state

        | CallStation ->
            match port, state.CurrentStation with
            | Some p, Some station ->
                let modem = {
                    new IModem with
                        member _.Dial phone = call p phone 60000
                        member _.HangUp () = hangUp p |> Async.Ignore
                        member _.IsConnected () = state.Connected
                }
                let! result = callStation modem station
                match result with
                | Ok speed ->
                    let msg = if speed > 0 then sprintf "Connected at %d" speed else "Connected"
                    return { state with
                                Connected = true
                                Screen = ScreenState.setMessage (Some msg) state.Screen }
                | Error dialResult ->
                    let msg = sprintf "Call failed: %A" dialResult
                    return AppState.setError msg state
            | _ -> return state

        | HangUp ->
            match port with
            | Some p when state.Connected ->
                let! _ = hangUp p
                return { state with
                            Connected = false
                            Screen = ScreenState.setMessage (Some "Disconnected") state.Screen }
            | _ -> return state

        | _ ->
            return applyCommand command state
    }

// ============================================================================
// MAIN LOOPS
// ============================================================================

/// Interactive mode loop
/// Original: PROCEDURE InterLoop
let interactiveLoop (renderer: IGraphicsRenderer) (port: ISerialPort option)
    (baseDir: string) (initialState: AppState) : Async<AppState> =

    let rec loop state =
        async {
            // Render current state
            let commands = composeScreen state.Screen state.RadarParams
                (state.CurrentPicture |> Option.bind (fun p -> p.Data))
            renderer.ExecuteAll commands
            renderer.Present()

            // Wait for input
            if keyPressed() then
                let key = extRead()
                let command = keyToCommand key

                match command with
                | Quit ->
                    return state
                | ShowPictureMenu ->
                    // Handle picture menu (would need UI implementation)
                    return! loop state
                | ShowStationMenu ->
                    // Handle station menu (would need UI implementation)
                    return! loop state
                | _ ->
                    let! newState = executeCommand command port baseDir state
                    return! loop newState
            else
                do! Async.Sleep 50
                return! loop state
        }

    loop initialState

/// Modem mode loop (waiting for incoming calls)
/// Original: PROCEDURE ModemLoop
let modemLoop (renderer: IGraphicsRenderer) (port: ISerialPort)
    (baseDir: string) (initialState: AppState) : Async<AppState> =

    let rec loop state =
        async {
            // Check for incoming data
            if port.BytesAvailable() > 0 then
                // Handle incoming connection
                return! loop { state with Connected = true }
            else
                // Check for keyboard input
                if keyPressed() then
                    let key = extRead()
                    match keyToCommand key with
                    | Quit -> return state
                    | _ -> return! loop state
                else
                    do! Async.Sleep 100
                    return! loop state
        }

    loop initialState

/// Automatic mode - periodically fetch pictures
/// Original: PROCEDURE DoAuto
let autoLoop (renderer: IGraphicsRenderer) (port: ISerialPort)
    (baseDir: string) (intervalMinutes: int) (initialState: AppState) : Async<AppState> =

    let rec loop state lastFetch =
        async {
            let now = getTime()
            let minutesSinceLastFetch = diffMinutes now lastFetch

            // Time for a new picture?
            let! newState, newLastFetch =
                if minutesSinceLastFetch >= intervalMinutes && state.Connected then
                    async {
                        let! fetchedState = executeCommand FetchNewPicture (Some port) baseDir state
                        return (fetchedState, now)
                    }
                else
                    async { return (state, lastFetch) }

            // Render
            let commands = composeScreen newState.Screen newState.RadarParams
                (newState.CurrentPicture |> Option.bind (fun p -> p.Data))
            renderer.ExecuteAll commands
            renderer.Present()

            // Check for user interrupt
            if keyPressed() then
                let key = extRead()
                match keyToCommand key with
                | Quit | ToggleAutoMode ->
                    return { newState with AutoMode = false }
                | _ ->
                    return! loop newState newLastFetch
            else
                do! Async.Sleep 1000
                return! loop newState newLastFetch
        }

    loop initialState (getTime())

// ============================================================================
// INITIALIZATION AND CONFIGURATION
// ============================================================================

/// Initialize the application
/// Original: PROCEDURE Initialize
let initialize (baseDir: string) (config: SerialConfig option)
    : Async<Result<AppState * ISerialPort option, string>> =
    async {
        // Initialize serial port if configured
        let portResult =
            config
            |> Option.map (fun c ->
                match init c with
                | Ok p -> Some p
                | Error _ -> None)
            |> Option.flatten

        // Load stations
        let! stationsResult = initStationDir baseDir
        match stationsResult with
        | Error msg ->
            return Error msg
        | Ok stations ->
            let state = {
                AppState.initial with
                    Stations = stations
                    Screen = ScreenState.initial
            }
            return Ok (state, portResult)
    }

/// Clean up on exit
/// Original: PROCEDURE DeInit
let deinitialize (port: ISerialPort option) : unit =
    port |> Option.iter closeDown

// ============================================================================
// CONFIGURATION
// ============================================================================

/// Configuration options
type AppConfig = {
    BaseDirectory: string
    SerialPort: SerialConfig option
    AutoFetchInterval: int  // minutes
    DefaultTilt: TiltIndex
    DefaultRange: RangeIndex
    DefaultGain: GainSetting
}

module AppConfig =
    let defaultConfig = {
        BaseDirectory = "."
        SerialPort = None
        AutoFetchInterval = 15
        DefaultTilt = 2uy       // 0 degrees
        DefaultRange = 2uy      // 100 nm
        DefaultGain = 9uy       // Middle gain
    }

/// Load configuration
/// Original: PROCEDURE Config
let loadConfig (path: string) : Result<AppConfig, string> =
    // Would load from config file
    Ok AppConfig.defaultConfig

/// Save configuration
let saveConfig (path: string) (config: AppConfig) : Result<unit, string> =
    // Would save to config file
    Ok ()

// ============================================================================
// PRINTING (from Pascal RADAR.PAS)
// ============================================================================

/// Print interface (abstract)
type IPrinter =
    abstract member PrintPicture : PictureRec -> Result<unit, string>
    abstract member PrintScreen : DrawCommand list -> Result<unit, string>

/// Null printer for when no printer is configured
type NullPrinter() =
    interface IPrinter with
        member _.PrintPicture _ = Error "No printer configured"
        member _.PrintScreen _ = Error "No printer configured"
