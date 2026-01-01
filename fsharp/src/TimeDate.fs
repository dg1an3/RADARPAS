/// Time and Date handling module
/// Translated from Modula-2 TIMEDATE.DEF/MOD
module Radarpas.TimeDate

open System
open Radarpas.CoreTypes

// The core Time type is defined in CoreTypes.fs
// This module provides additional operations and conversions

// ============================================================================
// TIME OPERATIONS
// ============================================================================

/// Get current system time
/// Original: PROCEDURE GetTime(VAR curTime: Time)
let getTime () : Time = Time.now ()

/// Set system time (no-op in modern systems without admin privileges)
/// Original: PROCEDURE SetTime(curTime: Time)
let setTime (_time: Time) : unit =
    // In modern .NET, setting system time requires admin privileges
    // This is left as a no-op for compatibility
    ()

/// Compare two times
/// Original: PROCEDURE CompareTime(t1, t2: Time): INTEGER
/// Returns: -1 if t1 < t2, 0 if equal, +1 if t1 > t2
let compareTime (t1: Time) (t2: Time) : int =
    Time.compare t1 t2

/// Initialize time to zero
/// Original: PROCEDURE TimeToZero(VAR t: Time)
let timeToZero () : Time = Time.zero

/// Convert time to string format "yy-mm-dd hh:nn:ss"
/// Original: PROCEDURE TimeToString(t: Time; VAR s: ARRAY OF CHAR)
let timeToString (t: Time) : string = Time.toString t

// ============================================================================
// ADDITIONAL TIME UTILITIES
// ============================================================================

/// Check if time is valid
let isValidTime (t: Time) : bool =
    let day = Time.dayOfMonth t
    let month = Time.month t
    let hour = Time.hour t
    let minute = Time.minute t
    let second = Time.second t

    day >= 1 && day <= 31 &&
    month >= 1 && month <= 12 &&
    hour >= 0 && hour <= 23 &&
    minute >= 0 && minute <= 59 &&
    second >= 0 && second <= 59

/// Add minutes to a time
let addMinutes (minutes: int) (t: Time) : Time =
    let dt = Time.toDateTime t
    let newDt = dt.AddMinutes(float minutes)
    Time.fromDateTime newDt

/// Add hours to a time
let addHours (hours: int) (t: Time) : Time =
    addMinutes (hours * 60) t

/// Add days to a time
let addDays (days: int) (t: Time) : Time =
    let dt = Time.toDateTime t
    let newDt = dt.AddDays(float days)
    Time.fromDateTime newDt

/// Calculate difference in minutes between two times
let diffMinutes (t1: Time) (t2: Time) : int =
    let dt1 = Time.toDateTime t1
    let dt2 = Time.toDateTime t2
    int (dt1 - dt2).TotalMinutes

/// Format time in different formats
module Format =
    /// Format as "HH:MM"
    let timeShort (t: Time) : string =
        sprintf "%02d:%02d" (Time.hour t) (Time.minute t)

    /// Format as "HH:MM:SS"
    let timeLong (t: Time) : string =
        sprintf "%02d:%02d:%02d" (Time.hour t) (Time.minute t) (Time.second t)

    /// Format as "DD/MM/YY"
    let dateShort (t: Time) : string =
        sprintf "%02d/%02d/%02d" (Time.dayOfMonth t) (Time.month t) (Time.year t % 100)

    /// Format as "DD-Mon-YYYY"
    let dateLong (t: Time) : string =
        let monthNames = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
                            "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |]
        let monthIdx = max 0 (min 11 (Time.month t - 1))
        sprintf "%02d-%s-%04d" (Time.dayOfMonth t) monthNames.[monthIdx] (Time.year t)

    /// Format as full datetime string
    let dateTime (t: Time) : string =
        sprintf "%s %s" (dateShort t) (timeLong t)

// ============================================================================
// PARSING
// ============================================================================

/// Parse time from string "HH:MM" or "HH:MM:SS"
let parseTime (s: string) : Time option =
    let parts = s.Split(':')
    match parts.Length with
    | 2 ->
        match Int32.TryParse(parts.[0]), Int32.TryParse(parts.[1]) with
        | (true, h), (true, m) when h >= 0 && h < 24 && m >= 0 && m < 60 ->
            Some (Time.create 1900 1 1 h m 0 0)
        | _ -> None
    | 3 ->
        match Int32.TryParse(parts.[0]), Int32.TryParse(parts.[1]), Int32.TryParse(parts.[2]) with
        | (true, h), (true, m), (true, s)
            when h >= 0 && h < 24 && m >= 0 && m < 60 && s >= 0 && s < 60 ->
            Some (Time.create 1900 1 1 h m s 0)
        | _ -> None
    | _ -> None

/// Parse date from string "DD/MM/YY" or "DD/MM/YYYY"
let parseDate (s: string) : Time option =
    let parts = s.Split('/')
    if parts.Length <> 3 then None
    else
        match Int32.TryParse(parts.[0]), Int32.TryParse(parts.[1]), Int32.TryParse(parts.[2]) with
        | (true, d), (true, m), (true, y)
            when d >= 1 && d <= 31 && m >= 1 && m <= 12 ->
            let year = if y < 100 then y + 1900 else y
            Some (Time.create year m d 0 0 0 0)
        | _ -> None

/// Parse full datetime "DD/MM/YY HH:MM:SS"
let parseDateTime (s: string) : Time option =
    let parts = s.Split(' ')
    if parts.Length < 2 then None
    else
        match parseDate parts.[0], parseTime parts.[1] with
        | Some datePart, Some timePart ->
            Some {
                Day = datePart.Day
                Minute = timePart.Minute
                Millisec = timePart.Millisec
            }
        | _ -> None

// ============================================================================
// TIMEOUT AND DELAY UTILITIES
// ============================================================================

/// Represents a timeout that can be checked
type Timeout = {
    StartTime: Time
    DurationMs: int
}

module Timeout =
    /// Create a timeout starting now
    let create (durationMs: int) : Timeout =
        { StartTime = getTime (); DurationMs = durationMs }

    /// Check if timeout has elapsed
    let hasElapsed (timeout: Timeout) : bool =
        let now = getTime ()
        let elapsedMs =
            (diffMinutes now timeout.StartTime) * 60 * 1000 +
            int now.Millisec - int timeout.StartTime.Millisec
        elapsedMs >= timeout.DurationMs

    /// Get remaining milliseconds (0 if elapsed)
    let remaining (timeout: Timeout) : int =
        let now = getTime ()
        let elapsedMs =
            (diffMinutes now timeout.StartTime) * 60 * 1000 +
            int now.Millisec - int timeout.StartTime.Millisec
        max 0 (timeout.DurationMs - elapsedMs)
