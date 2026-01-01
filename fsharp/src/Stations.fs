/// Station management module
/// Translated from Modula-2 STATIONS.DEF/MOD
module Radarpas.Stations

open System
open System.IO
open Radarpas.CoreTypes
open Radarpas.IO
open Radarpas.Pictures

// ============================================================================
// STATION TYPES
// ============================================================================

/// Full station record with all data
type Station = {
    Name: string              // Directory name (e.g., "STATION1.STA")
    Phone: string             // Phone number with dial modifiers
    Pictures: PictureRec list // Pictures for this station
    CurrentPicture: int       // Currently selected picture index
}

module Station =
    /// Create empty station
    let empty = {
        Name = ""
        Phone = ""
        Pictures = []
        CurrentPicture = 0
    }

    /// Get short name (without .STA extension)
    let shortName (station: Station) : string =
        let idx = station.Name.IndexOf('.')
        if idx > 0 then station.Name.Substring(0, idx)
        else station.Name

    /// Get directory path for station
    let directoryPath (baseDir: string) (station: Station) : string =
        Path.Combine(baseDir, station.Name)

// ============================================================================
// STATION LIST OPERATIONS (Pure Functions)
// ============================================================================

/// Add a new station to the list
/// Original: PROCEDURE AddStation(VAR StationList: StationPtr; VAR NumofStations: CARDINAL)
let addStation (stations: Station list) (newStation: Station) : Station list =
    stations @ [newStation]

/// Remove a station from the list by index
/// Original: PROCEDURE DelStation(VAR StationList: StationPtr; StationNum: CARDINAL; ...)
let deleteStation (stations: Station list) (index: int) : Station list * Station option =
    if index < 0 || index >= List.length stations then
        (stations, None)
    else
        let deleted = stations.[index]
        let newList =
            stations
            |> List.indexed
            |> List.filter (fun (i, _) -> i <> index)
            |> List.map snd
        (newList, Some deleted)

/// Find station by name
let findByName (stations: Station list) (name: string) : Station option =
    stations |> List.tryFind (fun s ->
        String.Equals(s.Name, name, StringComparison.OrdinalIgnoreCase))

/// Find station by index (1-based for compatibility)
let findByNumber (stations: Station list) (num: int) : Station option =
    if num < 1 || num > List.length stations then None
    else Some stations.[num - 1]

/// Update a station in the list
let updateStation (stations: Station list) (index: int) (update: Station -> Station)
    : Station list =
    stations
    |> List.mapi (fun i s -> if i = index then update s else s)

// ============================================================================
// STATION I/O (Effectful Functions)
// ============================================================================

/// Create a new station directory
let createStationDirectory (baseDir: string) (station: Station)
    : Result<unit, string> =
    try
        let stationDir = Station.directoryPath baseDir station
        Directory.CreateDirectory(stationDir) |> ignore

        // Write phone number file
        let phoneFile = Path.Combine(stationDir, "PHONENUM.TXT")
        File.WriteAllText(phoneFile, station.Phone)
        Ok ()
    with ex ->
        Error ex.Message

/// Delete a station directory and all its contents
let deleteStationDirectory (baseDir: string) (station: Station)
    : Result<unit, string> =
    try
        let stationDir = Station.directoryPath baseDir station
        if Directory.Exists(stationDir) then
            Directory.Delete(stationDir, true)
        Ok ()
    with ex ->
        Error ex.Message

/// Load station data from a directory
let loadStation (stationDir: string) : Async<Result<Station, string>> =
    async {
        try
            let name = Path.GetFileName(stationDir)

            // Read phone number
            let phoneFile = Path.Combine(stationDir, "PHONENUM.TXT")
            let phone =
                if File.Exists(phoneFile) then
                    File.ReadAllText(phoneFile).Trim()
                else
                    "--"

            // Load picture headers
            let! picturesResult = loadPictureHeaders stationDir
            match picturesResult with
            | Error msg ->
                return Error (sprintf "Failed to load pictures: %s" msg)
            | Ok pictures ->
                return Ok {
                    Name = name
                    Phone = phone
                    Pictures = pictures
                    CurrentPicture = 0
                }
        with ex ->
            return Error ex.Message
    }

/// Initialize station directory - find all .STA directories
/// Original: PROCEDURE InitStationDir(VAR StationList: StationPtr; VAR NumofStations: CARDINAL)
let initStationDir (baseDir: string) : Async<Result<Station list, string>> =
    async {
        try
            // Find all .STA directories
            let staDirs =
                Directory.GetDirectories(baseDir, "*.STA")
                |> Array.toList

            // Load each station
            let! loadResults =
                staDirs
                |> List.map loadStation
                |> Async.Parallel

            let stations =
                loadResults
                |> Array.choose (function Ok s -> Some s | Error _ -> None)
                |> Array.toList

            return Ok stations
        with ex ->
            return Error ex.Message
    }

/// Save station phone number
let saveStationPhone (baseDir: string) (station: Station) : Result<unit, string> =
    try
        let phoneFile = Path.Combine(Station.directoryPath baseDir station, "PHONENUM.TXT")
        File.WriteAllText(phoneFile, station.Phone)
        Ok ()
    with ex ->
        Error ex.Message

// ============================================================================
// MAP DATA
// ============================================================================

/// Map data for a station (landmarks and segments)
type MapData = {
    Landmarks: LandmarkRec list
    Segments: SegmentRec list
}

module MapData =
    let empty = { Landmarks = []; Segments = [] }

/// Load map data from station directory
/// Original: Part of PROCEDURE SelectStation
let loadMapData (stationDir: string) (mapNum: int) : Result<MapData, string> =
    try
        let mapFile = Path.Combine(stationDir, sprintf "MAP%d.DAT" mapNum)
        if not (File.Exists(mapFile)) then
            Ok MapData.empty
        else
            let data = File.ReadAllBytes(mapFile)
            // Parse map data format...
            // For now, return empty (parsing would depend on binary format)
            Ok MapData.empty
    with ex ->
        Error ex.Message

// ============================================================================
// MODEM/CALLING (Abstracted Interface)
// ============================================================================

/// Result of a dial attempt
type DialResult =
    | Connected of speed: int
    | NoCarrier
    | Busy
    | NoAnswer
    | NoDialtone
    | ModemError of string
    | Aborted

/// Interface for modem operations
type IModem =
    abstract member Dial : string -> Async<DialResult>
    abstract member HangUp : unit -> Async<unit>
    abstract member IsConnected : unit -> bool

/// Call a station
/// Original: PROCEDURE CallStation(VAR ForStation: StationRec): BOOLEAN
let callStation (modem: IModem) (station: Station) : Async<Result<int, DialResult>> =
    async {
        if station.Phone = "--" || String.IsNullOrWhiteSpace(station.Phone) then
            // No phone number - direct connection assumed
            return Ok 0
        else
            let! result = modem.Dial station.Phone
            match result with
            | Connected speed -> return Ok speed
            | other -> return Error other
    }

// ============================================================================
// STATION SELECTION
// ============================================================================

/// Select a station (change working directory and load maps)
/// Original: PROCEDURE SelectStation(VAR ForStation: StationRec)
type StationSelectionResult = {
    Station: Station
    Map1: MapData
    Map2: MapData
}

let selectStation (baseDir: string) (station: Station)
    : Result<StationSelectionResult, string> =
    let stationDir = Station.directoryPath baseDir station

    if not (Directory.Exists(stationDir)) then
        Error (sprintf "Station directory not found: %s" stationDir)
    else
        // Load map data
        let map1Result = loadMapData stationDir 1
        let map2Result = loadMapData stationDir 2

        match map1Result, map2Result with
        | Ok map1, Ok map2 ->
            Ok { Station = station; Map1 = map1; Map2 = map2 }
        | Error msg, _ | _, Error msg ->
            Error msg

// ============================================================================
// STATION MENU STATE
// ============================================================================

/// Station list display state
type StationListState = {
    Stations: Station list
    SelectedIndex: int
    TopIndex: int
    PageSize: int
}

module StationListState =
    let create (stations: Station list) (pageSize: int) : StationListState = {
        Stations = stations
        SelectedIndex = if List.isEmpty stations then -1 else 0
        TopIndex = 0
        PageSize = pageSize
    }

    let moveUp (state: StationListState) : StationListState =
        if state.SelectedIndex <= 0 then state
        else
            let newIndex = state.SelectedIndex - 1
            let newTop = if newIndex < state.TopIndex then newIndex else state.TopIndex
            { state with SelectedIndex = newIndex; TopIndex = newTop }

    let moveDown (state: StationListState) : StationListState =
        let maxIndex = List.length state.Stations - 1
        if state.SelectedIndex >= maxIndex then state
        else
            let newIndex = state.SelectedIndex + 1
            let newTop =
                if newIndex >= state.TopIndex + state.PageSize
                then newIndex - state.PageSize + 1
                else state.TopIndex
            { state with SelectedIndex = newIndex; TopIndex = newTop }

    let selectedStation (state: StationListState) : Station option =
        if state.SelectedIndex >= 0 && state.SelectedIndex < List.length state.Stations
        then Some state.Stations.[state.SelectedIndex]
        else None

    let visibleStations (state: StationListState) : (int * Station) list =
        state.Stations
        |> List.indexed
        |> List.skip state.TopIndex
        |> List.truncate state.PageSize

/// Station menu actions
type StationMenuAction =
    | SelectStation of int
    | AddStation
    | DeleteStation of int
    | Cancel

/// Format a station entry for display
/// Original: PROCEDURE WriteStationEntry(StationNum: CARDINAL)
let formatStationEntry (station: Station) : string =
    sprintf "%-9s %s"
        (Station.shortName station)
        (if station.Phone.Length > 15 then station.Phone.Substring(0, 15) else station.Phone)
