/// Core types for RADARPAS - translated from Modula-2 and Pascal definitions
/// This module contains the fundamental data types used throughout the system.
module Radarpas.CoreTypes

open System

// ============================================================================
// UNITS OF MEASURE
// ============================================================================

/// Units of measure for type-safe numeric operations
[<Measure>] type degrees
[<Measure>] type nauticalMiles
[<Measure>] type milliseconds
[<Measure>] type minutes

// ============================================================================
// BASIC RADAR TYPES (from Pascal RADAR.PAS and Modula-2 E300INTERFACE)
// ============================================================================

/// Antenna tilt angle index (0..11)
/// Original: TiltType = 0..11
type TiltIndex = byte

module TiltIndex =
    let min : TiltIndex = 0uy
    let max : TiltIndex = 11uy
    let isValid (t: TiltIndex) = t >= min && t <= max
    let create (value: byte) : TiltIndex option =
        if isValid value then Some value else None

/// Radar range setting index (0..4)
/// Original: RangeType = 0..4
type RangeIndex = byte

module RangeIndex =
    let min : RangeIndex = 0uy
    let max : RangeIndex = 4uy
    let isValid (r: RangeIndex) = r >= min && r <= max
    let create (value: byte) : RangeIndex option =
        if isValid value then Some value else None

/// Receiver gain setting (1..17)
/// Original: GainType = 1..17
type GainSetting = byte

module GainSetting =
    let min : GainSetting = 1uy
    let max : GainSetting = 17uy
    let isValid (g: GainSetting) = g >= min && g <= max
    let create (value: byte) : GainSetting option =
        if isValid value then Some value else None

// ============================================================================
// TIME/DATE TYPES (from Modula-2 TIMEDATE.DEF)
// ============================================================================

/// Time record - stores date and time in packed format
/// Original: Time = RECORD day, minute, millisec: CARDINAL; END
/// 'day' bits: 0-4=day(1-31), 5-8=month(1-12), 9-15=year-1900
/// 'minute' = hour * 60 + minutes
/// 'millisec' = second * 1000 + milliseconds
type Time = {
    Day: uint16        // Packed date
    Minute: uint16     // Minutes since midnight
    Millisec: uint16   // Milliseconds within the minute
}

module Time =
    /// Zero time (epoch)
    let zero = { Day = 0us; Minute = 0us; Millisec = 0us }

    /// Extract day of month (1-31)
    let dayOfMonth (t: Time) : int = int (t.Day &&& 0x1Fus)

    /// Extract month (1-12)
    let month (t: Time) : int = int ((t.Day >>> 5) &&& 0xFus)

    /// Extract year (actual year, not offset from 1900)
    let year (t: Time) : int = int (t.Day >>> 9) + 1900

    /// Extract hour (0-23)
    let hour (t: Time) : int = int t.Minute / 60

    /// Extract minute within hour (0-59)
    let minute (t: Time) : int = int t.Minute % 60

    /// Extract second (0-59)
    let second (t: Time) : int = int t.Millisec / 1000

    /// Extract millisecond within second (0-999)
    let millisecond (t: Time) : int = int t.Millisec % 1000

    /// Pack date components into Day field
    let packDate (year: int) (month: int) (day: int) : uint16 =
        let yearOffset = max 0 (year - 1900) |> min 127
        uint16 (day &&& 0x1F) |||
        (uint16 (month &&& 0xF) <<< 5) |||
        (uint16 yearOffset <<< 9)

    /// Pack time components into Minute and Millisec fields
    let packTime (hour: int) (minute: int) (second: int) (millisec: int) : uint16 * uint16 =
        let minuteField = uint16 (hour * 60 + minute)
        let millisecField = uint16 (second * 1000 + millisec)
        (minuteField, millisecField)

    /// Create Time from components
    let create (year: int) (month: int) (day: int) (hour: int) (minute: int) (second: int) (millisec: int) : Time =
        let minuteField, millisecField = packTime hour minute second millisec
        {
            Day = packDate year month day
            Minute = minuteField
            Millisec = millisecField
        }

    /// Create Time from DateTime
    let fromDateTime (dt: DateTime) : Time =
        create dt.Year dt.Month dt.Day dt.Hour dt.Minute dt.Second dt.Millisecond

    /// Convert Time to DateTime
    let toDateTime (t: Time) : DateTime =
        DateTime(year t, month t, dayOfMonth t, hour t, minute t, second t, millisecond t)

    /// Get current system time
    let now () : Time = fromDateTime DateTime.Now

    /// Compare two times
    let compare (t1: Time) (t2: Time) : int =
        match compare t1.Day t2.Day with
        | 0 ->
            match compare t1.Minute t2.Minute with
            | 0 -> compare t1.Millisec t2.Millisec
            | c -> c
        | c -> c

    /// Format time as string "yy-mm-dd hh:nn:ss"
    let toString (t: Time) : string =
        sprintf "%02d-%02d-%02d %02d:%02d:%02d"
            (year t % 100) (month t) (dayOfMonth t)
            (hour t) (minute t) (second t)

// ============================================================================
// OPERATING MODE (from Pascal RADAR.PAS)
// ============================================================================

/// Operating mode enumeration
/// Original: ModeType = (Modem, Interactive, WaitPic, RxPic, RxGraph)
type OperatingMode =
    | Modem
    | Interactive
    | WaitPic
    | RxPic
    | RxGraph

// ============================================================================
// PICTURE TYPES (from Modula-2 PICTURES.DEF)
// ============================================================================

/// Picture flags
/// Original: PicFlag = (NotSaved, BeingDownLoaded)
type PicFlag =
    | NotSaved
    | BeingDownloaded

type PicFlagSet = Set<PicFlag>

module PicFlagSet =
    let empty : PicFlagSet = Set.empty
    let add flag set = Set.add flag set
    let remove flag set = Set.remove flag set
    let contains flag set = Set.contains flag set

/// Picture metadata record
/// Original: PictureRec = RECORD Tilt, Range, Gain, TimeofPic, Purge, Flags, Size, Data END
type PictureRec = {
    Tilt: TiltIndex
    Range: RangeIndex
    Gain: GainSetting
    TimeOfPic: Time
    Purge: uint32              // Purge priority number
    Flags: PicFlagSet
    Size: uint32               // Size of compressed data
    Data: byte array option    // Compressed picture data (None if not in memory)
}

module PictureRec =
    /// Create empty picture record
    let empty = {
        Tilt = 0uy
        Range = 0uy
        Gain = 1uy
        TimeOfPic = Time.zero
        Purge = 0u
        Flags = PicFlagSet.empty
        Size = 0u
        Data = None
    }

    /// Generate filename for a picture
    /// Format: HHMM<tilt><range><gain>.WX
    /// where tilt/range are A-L, gain is A-Q
    let generateFileName (pic: PictureRec) : string =
        let hour = Time.hour pic.TimeOfPic
        let minute = Time.minute pic.TimeOfPic
        let tiltChar = char (int 'A' + int pic.Tilt)
        let rangeChar = char (int 'A' + int pic.Range)
        let gainChar = char (int '@' + int pic.Gain)
        sprintf "%02d%02d%c%c%c.WX" hour minute tiltChar rangeChar gainChar

    /// Parse filename to extract picture parameters
    let parseFileName (name: string) : Result<PictureRec, string> =
        if name.Length < 7 then
            Error "Filename too short"
        else
            match UInt16.TryParse(name.Substring(0, 2)),
                  UInt16.TryParse(name.Substring(2, 2)) with
            | (true, hour), (true, minute) when hour < 24us && minute < 60us ->
                let tilt = byte (int name.[4] - int 'A')
                let range = byte (int name.[5] - int 'A')
                let gain = byte (int name.[6] - int '@')
                if TiltIndex.isValid tilt && RangeIndex.isValid range && GainSetting.isValid gain then
                    Ok {
                        empty with
                            TimeOfPic = { Time.zero with Minute = hour * 60us + minute }
                            Tilt = tilt
                            Range = range
                            Gain = gain
                    }
                else
                    Error "Invalid tilt, range, or gain in filename"
            | _ ->
                Error "Invalid time in filename"

// ============================================================================
// MAP TYPES (from Pascal RADAR.PAS and Modula-2 E250DRAW.MOD)
// ============================================================================

/// Landmark record for map overlays
/// Original: LandMarkRec = RECORD Bear, Range, Name[1..3], Nothing END
type LandmarkRec = {
    Bearing: float<degrees>
    Range: float<nauticalMiles>
    Name: string  // 3 characters
}

/// Map segment for drawing coastlines, etc.
/// Original: SegmentRec = RECORD Range1, Bear1, Range2, Bear2 END
type SegmentRec = {
    Range1: float<nauticalMiles>
    Bearing1: float<degrees>
    Range2: float<nauticalMiles>
    Bearing2: float<degrees>
}

/// Map entry - either a landmark or a segment
/// Original: MapEntry = RECORD Bear, Range, Ident OR Range1, Bear1, Range2, Bear2 END
type MapEntry =
    | Landmark of LandmarkRec
    | Segment of SegmentRec

// ============================================================================
// STATION TYPES (from Modula-2 STATIONS.DEF)
// ============================================================================

/// Station record - represents a radar station
/// Original: StationRec = RECORD Name, Phone, CallSign, ... END
type StationRec = {
    StationName: string        // Station subdirectory name
    Phone: string              // Phone number (may contain Hayes modifiers)
    CurrentPicture: int        // Index of currently displayed picture
    Pictures: PictureRec list  // List of pictures for this station
}

module StationRec =
    let empty = {
        StationName = ""
        Phone = ""
        CurrentPicture = 0
        Pictures = []
    }

    /// Get short name (without extension)
    let shortName (station: StationRec) : string =
        let idx = station.StationName.IndexOf('.')
        if idx > 0 then station.StationName.Substring(0, idx)
        else station.StationName

// ============================================================================
// GRAPHICS TYPES (from Modula-2 GRAPHICS.DEF)
// ============================================================================

/// Screen mode enumeration
/// Original: ScreenModeType = (Text, Mono, Color)
type ScreenMode =
    | Text
    | Mono
    | Color

/// Graphics function for pixel operations
/// Original: FuncType = (clr, And, Or, Xor)
type GraphicsFunction =
    | Clear
    | And
    | Or
    | Xor

/// Graphics plane (for EGA/VGA)
type GraphicsPlane = Plane0 | Plane1 | Plane2 | Plane3

type PlaneSet = Set<GraphicsPlane>

module PlaneSet =
    let empty : PlaneSet = Set.empty
    let all : PlaneSet = Set.ofList [Plane0; Plane1; Plane2; Plane3]
    let ofList = Set.ofList

    /// Convert plane set to bitmask
    let toBitmask (planes: PlaneSet) : byte =
        planes
        |> Set.fold (fun acc p ->
            match p with
            | Plane0 -> acc ||| 1uy
            | Plane1 -> acc ||| 2uy
            | Plane2 -> acc ||| 4uy
            | Plane3 -> acc ||| 8uy) 0uy

    /// Create plane set from bitmask
    let fromBitmask (mask: byte) : PlaneSet =
        [ if mask &&& 1uy <> 0uy then Plane0
          if mask &&& 2uy <> 0uy then Plane1
          if mask &&& 4uy <> 0uy then Plane2
          if mask &&& 8uy <> 0uy then Plane3 ]
        |> Set.ofList

// ============================================================================
// RADAR PARAMETERS (from Pascal RADTERM.PAS)
// ============================================================================

/// Radar parameter set
/// Original: RadarParams = RECORD Tilt, Range, Gain, Time END
type RadarParams = {
    Tilt: TiltIndex
    Range: RangeIndex
    Gain: GainSetting
    Time: Time
}

module RadarParams =
    let empty = {
        Tilt = 0uy
        Range = 0uy
        Gain = 1uy
        Time = Time.zero
    }

// ============================================================================
// SWEEP TYPES (from Modula-2 SWEEP.MOD)
// ============================================================================

/// Radial table entry for sweep calculations
/// Original: RadialTableEntry = ARRAY[0..2] OF SHORTCARD
type RadialTableEntry = {
    DeltaX: int16
    DeltaY: int16
    Count: int16
}

/// Analysis marker
/// Original: MarkerRec = RECORD X, Y, Picture END
type MarkerRec = {
    X: int
    Y: int
    PictureIndex: int
}

// ============================================================================
// COMMUNICATION TYPES
// ============================================================================

/// Result codes for modem operations
type ModemResult =
    | Ok
    | Connect300
    | Connect1200
    | Connect2400
    | NoCarrier
    | ModemError
    | NoDialtone
    | Busy
    | NoAnswer
    | NoResponse

/// RS-232 configuration
type Rs232Config = {
    BaudRate: int
    DataBits: int
    StopBits: int
    Parity: char  // 'N', 'E', 'O'
}

module Rs232Config =
    let default2400 = { BaudRate = 2400; DataBits = 8; StopBits = 1; Parity = 'N' }
    let default9600 = { BaudRate = 9600; DataBits = 8; StopBits = 1; Parity = 'N' }

// ============================================================================
// ERROR TYPES
// ============================================================================

/// Common error types for the application
type RadarpasError =
    | IoError of string
    | ParseError of string
    | CommunicationError of string
    | GraphicsError of string
    | ValidationError of string
    | NotFound of string

module RadarpasError =
    let toString = function
        | IoError msg -> sprintf "I/O Error: %s" msg
        | ParseError msg -> sprintf "Parse Error: %s" msg
        | CommunicationError msg -> sprintf "Communication Error: %s" msg
        | GraphicsError msg -> sprintf "Graphics Error: %s" msg
        | ValidationError msg -> sprintf "Validation Error: %s" msg
        | NotFound msg -> sprintf "Not Found: %s" msg
