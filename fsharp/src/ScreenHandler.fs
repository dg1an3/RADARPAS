/// Screen handler module - radar display and UI
/// Translated from Modula-2 SCREENHA.DEF/MOD and Pascal SCREEN.RDR
module Radarpas.ScreenHandler

open System
open Radarpas.CoreTypes
open Radarpas.Graphics
open Radarpas.TimeDate

// ============================================================================
// DISPLAY CONSTANTS
// ============================================================================

/// Screen layout constants
module Layout =
    let radarCenterX = 320
    let radarCenterY = 175
    let maxRadius = 170
    let paramsX = 500
    let paramsY = 10
    let helpX = 10
    let helpY = 280
    let messageX = 100
    let messageY = 320

// ============================================================================
// SCREEN STATE
// ============================================================================

/// Current screen state
type ScreenState = {
    Graphics: GraphicsState
    MapOn: bool array           // Maps 1 and 2 on/off
    RangeMarkersOn: bool
    HelpMode: int               // 0-3 for different help screens
    HelpVisible: bool
    CurrentMessage: string option
}

module ScreenState =
    let initial = {
        Graphics = GraphicsState.defaultState
        MapOn = [| false; false |]
        RangeMarkersOn = true
        HelpMode = 0
        HelpVisible = false
        CurrentMessage = None
    }

    let toggleMap (mapNum: int) (state: ScreenState) : ScreenState =
        if mapNum >= 0 && mapNum < 2 then
            let newMapOn = Array.copy state.MapOn
            newMapOn.[mapNum] <- not newMapOn.[mapNum]
            { state with MapOn = newMapOn }
        else state

    let toggleRangeMarkers (state: ScreenState) : ScreenState =
        { state with RangeMarkersOn = not state.RangeMarkersOn }

    let toggleHelp (state: ScreenState) : ScreenState =
        { state with HelpVisible = not state.HelpVisible }

    let setHelpMode (mode: int) (state: ScreenState) : ScreenState =
        { state with HelpMode = mode % 4 }

    let setMessage (msg: string option) (state: ScreenState) : ScreenState =
        { state with CurrentMessage = msg }

// ============================================================================
// DISPLAY FORMATTING FUNCTIONS (Pure)
// ============================================================================

/// Format time for display
/// Original: PROCEDURE WriteTime(ForTime: Time)
let formatTime (time: Time) : string =
    sprintf "%02d:%02d" (Time.hour time) (Time.minute time)

/// Format date for display
/// Original: PROCEDURE WriteDate(ForTime: Time)
let formatDate (time: Time) : string =
    sprintf "%02d/%02d/%02d" (Time.dayOfMonth time) (Time.month time) (Time.year time % 100)

/// Format tilt for display
/// Original: PROCEDURE WriteTilt(Tilt: CARDINAL)
let formatTilt (tilt: TiltIndex) : string =
    if tilt = 255uy then "---"
    else
        let values = [| "-1"; "-½"; "0"; "½"; "1"; "1½"; "2"; "2½"; "3"; "4"; "5"; "7" |]
        if int tilt < values.Length then values.[int tilt]
        else sprintf "%d" tilt

/// Format range for display
/// Original: PROCEDURE WriteRange(Range: CARDINAL)
let formatRange (range: RangeIndex) : string =
    if range = 255uy then "---"
    else
        let values = [| "25"; "50"; "100"; "200"; "400" |]
        if int range < values.Length then values.[int range]
        else sprintf "%d" range

/// Format gain for display
/// Original: PROCEDURE WriteGain(Gain: CARDINAL)
let formatGain (gain: GainSetting) : string =
    if gain = 255uy then "---"
    else sprintf "%2d" gain

/// Format all radar parameters
/// Original: PROCEDURE WriteParams(Tilt, Range, Gain: CARDINAL; ForTime: Time)
let formatParams (tilt: TiltIndex) (range: RangeIndex) (gain: GainSetting) (time: Time) : string =
    sprintf "Date: %s  Time: %s\nTilt: %s  Range: %s nm  Gain: %s"
        (formatDate time) (formatTime time)
        (formatTilt tilt) (formatRange range) (formatGain gain)

// ============================================================================
// DRAWING COMMANDS GENERATION
// ============================================================================

/// Generate range marker circles
/// Original: PROCEDURE WriteRngMks(On: BOOLEAN)
let generateRangeMarkers (rangeIndex: RangeIndex) (state: ScreenState) : DrawCommand list =
    if not state.RangeMarkersOn then []
    else
        let maxRange =
            match rangeIndex with
            | 0uy -> 25
            | 1uy -> 50
            | 2uy -> 100
            | 3uy -> 200
            | _ -> 400

        let markerDistances =
            match rangeIndex with
            | 0uy -> [| 5; 10; 15; 20; 25 |]
            | 1uy -> [| 10; 20; 30; 40; 50 |]
            | 2uy -> [| 20; 40; 60; 80; 100 |]
            | 3uy -> [| 40; 80; 120; 160; 200 |]
            | _ -> [| 100; 200; 300; 400 |]

        let scale = float Layout.maxRadius / float maxRange

        [ for dist in markerDistances do
            let radius = int (float dist * scale)
            yield circle Layout.radarCenterX Layout.radarCenterY radius 7uy  // Light gray
        ]

/// Generate scale/legend
/// Original: PROCEDURE DrawScale
let generateScale (rangeIndex: RangeIndex) : DrawCommand list =
    let maxRange =
        match rangeIndex with
        | 0uy -> "25" | 1uy -> "50" | 2uy -> "100" | 3uy -> "200" | _ -> "400"

    [ DrawText (540, 300, sprintf "Range: %s nm" maxRange, 15uy) ]

/// Generate parameter display
let generateParamsDisplay (tilt: TiltIndex) (range: RangeIndex) (gain: GainSetting) (time: Time)
    : DrawCommand list =
    [
        DrawText (Layout.paramsX, Layout.paramsY, formatDate time, 15uy)
        DrawText (Layout.paramsX, Layout.paramsY + 14, formatTime time, 15uy)
        DrawText (Layout.paramsX, Layout.paramsY + 35, sprintf "Tilt:  %s" (formatTilt tilt), 7uy)
        DrawText (Layout.paramsX, Layout.paramsY + 49, sprintf "Range: %s" (formatRange range), 7uy)
        DrawText (Layout.paramsX, Layout.paramsY + 63, sprintf "Gain:  %s" (formatGain gain), 7uy)
    ]

/// Generate help screen
/// Original: PROCEDURE WriteHelp(On: BOOLEAN)
let generateHelp (mode: int) : DrawCommand list =
    let helpText =
        match mode with
        | 0 ->
            [| "KEYBOARD COMMANDS:"
               "F1 - Help"
               "F2 - Toggle Map 1"
               "F3 - Toggle Map 2"
               "F4 - Range Markers"
               "F5 - Picture Menu"
               "F6 - Station Menu"
               "ESC - Exit" |]
        | 1 ->
            [| "PICTURE COMMANDS:"
               "PgUp - Previous"
               "PgDn - Next"
               "Home - Oldest"
               "End - Newest"
               "Del - Delete"
               "S - Save" |]
        | 2 ->
            [| "STATION COMMANDS:"
               "A - Add Station"
               "D - Delete Station"
               "C - Call Station"
               "Enter - Select" |]
        | _ ->
            [| "RADARPAS v2.0"
               "Weather Radar"
               "Display System" |]

    helpText
    |> Array.mapi (fun i line ->
        DrawText (Layout.helpX, Layout.helpY + i * 12, line, 14uy))
    |> Array.toList

/// Generate message display
/// Original: PROCEDURE Message(String: ARRAY OF CHAR)
let generateMessage (msg: string) : DrawCommand list =
    [ FillRect (Layout.messageX - 5, Layout.messageY - 2, 440, 16, 1uy)  // Blue background
      DrawText (Layout.messageX, Layout.messageY, msg, 15uy) ]

// ============================================================================
// RADAR PICTURE RENDERING
// ============================================================================

/// Decompress and render radar picture
/// Original: PROCEDURE WritePic(VAR Buffer: ARRAY OF BYTE; BufSize: CARDINAL)
let generatePictureCommands (data: byte array) (rangeIndex: RangeIndex) : DrawCommand list =
    // The picture data is compressed using run-length encoding
    // Each radial line is encoded separately
    // This is a simplified version - actual decompression would need the original algorithm

    let maxRange =
        match rangeIndex with
        | 0uy -> 25 | 1uy -> 50 | 2uy -> 100 | 3uy -> 200 | _ -> 400

    let scale = float Layout.maxRadius / float maxRange

    // Generate placeholder - actual implementation would decompress data
    // and generate SetPixel commands for each radar return
    []

/// Compress a radial line
/// Original: PROCEDURE ComprLine(Number: CARDINAL; ...)
let compressLine (lineData: byte array) : byte array =
    // Run-length encoding for radar line
    let result = ResizeArray<byte>()
    let mutable i = 0

    while i < lineData.Length do
        let value = lineData.[i]
        let mutable count = 1

        while i + count < lineData.Length && lineData.[i + count] = value && count < 255 do
            count <- count + 1

        if count > 3 || value = 0xFFuy then
            result.Add(0xFFuy)  // Escape byte
            result.Add(byte count)
            result.Add(value)
        else
            for _ in 1 .. count do
                result.Add(value)

        i <- i + count

    result.ToArray()

// ============================================================================
// SCREEN COMPOSITION
// ============================================================================

/// Compose full screen from state
let composeScreen (state: ScreenState) (params: RadarParams) (pictureData: byte array option)
    : DrawCommand list =

    let clearCmd = clearScreen state.Graphics

    let paramsCmd = generateParamsDisplay params.Tilt params.Range params.Gain params.Time

    let rangeMarkersCmds =
        if state.RangeMarkersOn then generateRangeMarkers params.Range state
        else []

    let scaleCmd = generateScale params.Range

    let helpCmds =
        if state.HelpVisible then generateHelp state.HelpMode
        else []

    let messageCmds =
        match state.CurrentMessage with
        | Some msg -> generateMessage msg
        | None -> []

    let pictureCmds =
        match pictureData with
        | Some data -> generatePictureCommands data params.Range
        | None -> []

    [clearCmd] @ paramsCmd @ rangeMarkersCmds @ scaleCmd @ helpCmds @ messageCmds @ pictureCmds

// ============================================================================
// USER PROMPTS
// ============================================================================

/// Pause and wait for keypress
/// Original: PROCEDURE Pause(String: ARRAY OF CHAR): CHAR
let pause (message: string) : DrawCommand list * (unit -> char) =
    let commands = generateMessage message
    let waitForKey () = IO.rdKey ()
    (commands, waitForKey)

/// Prompt for text input
/// Original: PROCEDURE Prompt(String: ARRAY OF CHAR; VAR Response: ARRAY OF CHAR)
let prompt (message: string) : DrawCommand list * (unit -> string) =
    let commands = generateMessage (message + "_")
    let readInput () = IO.rdStr ()
    (commands, readInput)

// ============================================================================
// TOGGLE GRAPHICS MODE
// ============================================================================

/// Toggle between text and graphics mode
/// Original: PROCEDURE ToggleGraphics
let toggleGraphics (state: ScreenState) : ScreenState =
    let newMode =
        match state.Graphics.ScreenMode with
        | Text -> Color
        | _ -> Text
    { state with Graphics = setScreenMode newMode state.Graphics }

// ============================================================================
// REDRAW
// ============================================================================

/// Trigger full screen redraw
/// Original: PROCEDURE Redraw
let redraw (state: ScreenState) (params: RadarParams) : DrawCommand list =
    composeScreen state params None
