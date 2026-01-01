/// I/O module - Console and basic I/O operations
/// Translated from Modula-2 IO.DEF
module Radarpas.IO

open System

// ============================================================================
// CONSOLE OUTPUT FUNCTIONS
// ============================================================================

/// Write a single character
/// Original: PROCEDURE WrChar(V: CHAR)
let wrChar (c: char) : unit = Console.Write(c)

/// Write a boolean value
/// Original: PROCEDURE WrBool(V: BOOLEAN; Length: INTEGER)
let wrBool (v: bool) (length: int) : unit =
    let s = if v then "TRUE" else "FALSE"
    Console.Write(s.PadLeft(max (String.length s) length))

/// Write a short integer
/// Original: PROCEDURE WrShtInt(V: SHORTINT; Length: INTEGER)
let wrShtInt (v: int8) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write an integer
/// Original: PROCEDURE WrInt(V: INTEGER; Length: INTEGER)
let wrInt (v: int) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write a long integer
/// Original: PROCEDURE WrLngInt(V: LONGINT; Length: INTEGER)
let wrLngInt (v: int64) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write a short cardinal (unsigned byte)
/// Original: PROCEDURE WrShtCard(V: SHORTCARD; Length: INTEGER)
let wrShtCard (v: byte) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write a cardinal
/// Original: PROCEDURE WrCard(V: CARDINAL; Length: INTEGER)
let wrCard (v: uint32) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write a long cardinal
/// Original: PROCEDURE WrLngCard(V: LONGCARD; Length: INTEGER)
let wrLngCard (v: uint64) (length: int) : unit =
    Console.Write((sprintf "%d" v).PadLeft(length))

/// Write a short hex value
/// Original: PROCEDURE WrShtHex(V: SHORTCARD; Length: INTEGER)
let wrShtHex (v: byte) (length: int) : unit =
    Console.Write((sprintf "%X" v).PadLeft(length))

/// Write a hex value
/// Original: PROCEDURE WrHex(V: CARDINAL; Length: INTEGER)
let wrHex (v: uint32) (length: int) : unit =
    Console.Write((sprintf "%X" v).PadLeft(length))

/// Write a long hex value
/// Original: PROCEDURE WrLngHex(V: LONGCARD; Length: INTEGER)
let wrLngHex (v: uint64) (length: int) : unit =
    Console.Write((sprintf "%X" v).PadLeft(length))

/// Write a real number
/// Original: PROCEDURE WrReal(V: REAL; Precision: CARDINAL; Length: INTEGER)
let wrReal (v: float32) (precision: int) (length: int) : unit =
    let fmt = sprintf "%%.%df" precision
    Console.Write((sprintf fmt v).PadLeft(length))

/// Write a long real number
/// Original: PROCEDURE WrLngReal(V: LONGREAL; Precision: CARDINAL; Length: INTEGER)
let wrLngReal (v: float) (precision: int) (length: int) : unit =
    let fmt = sprintf "%%.%df" precision
    Console.Write((sprintf fmt v).PadLeft(length))

/// Write repeated character
/// Original: PROCEDURE WrCharRep(V: CHAR; Count: CARDINAL)
let wrCharRep (c: char) (count: int) : unit =
    Console.Write(String(c, count))

/// Write a string
/// Original: PROCEDURE WrStr(S: ARRAY OF CHAR)
let wrStr (s: string) : unit = Console.Write(s)

/// Write a string with adjustment (padding/truncation)
/// Original: PROCEDURE WrStrAdj(S: ARRAY OF CHAR; Length: INTEGER)
let wrStrAdj (s: string) (length: int) : unit =
    if length >= 0 then
        Console.Write(s.PadRight(length).Substring(0, length))
    else
        Console.Write(s.PadLeft(-length).Substring(0, -length))

/// Write a newline
/// Original: PROCEDURE WrLn
let wrLn () : unit = Console.WriteLine()

// ============================================================================
// CONSOLE INPUT FUNCTIONS
// ============================================================================

/// Read a character
/// Original: PROCEDURE RdChar(): CHAR
let rdChar () : char =
    let key = Console.ReadKey(true)
    key.KeyChar

/// Read a boolean
/// Original: PROCEDURE RdBool(): BOOLEAN
let rdBool () : bool =
    let line = Console.ReadLine()
    match line.ToUpperInvariant().Trim() with
    | "TRUE" | "T" | "YES" | "Y" | "1" -> true
    | _ -> false

/// Read a short integer
/// Original: PROCEDURE RdShtInt(): SHORTINT
let rdShtInt () : int8 option =
    let line = Console.ReadLine()
    match SByte.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read an integer
/// Original: PROCEDURE RdInt(): INTEGER
let rdInt () : int option =
    let line = Console.ReadLine()
    match Int32.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a long integer
/// Original: PROCEDURE RdLngInt(): LONGINT
let rdLngInt () : int64 option =
    let line = Console.ReadLine()
    match Int64.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a short cardinal
/// Original: PROCEDURE RdShtCard(): SHORTCARD
let rdShtCard () : byte option =
    let line = Console.ReadLine()
    match Byte.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a cardinal
/// Original: PROCEDURE RdCard(): CARDINAL
let rdCard () : uint32 option =
    let line = Console.ReadLine()
    match UInt32.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a long cardinal
/// Original: PROCEDURE RdLngCard(): LONGCARD
let rdLngCard () : uint64 option =
    let line = Console.ReadLine()
    match UInt64.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a hex value
/// Original: PROCEDURE RdHex(): CARDINAL
let rdHex () : uint32 option =
    let line = Console.ReadLine().Trim()
    match UInt32.TryParse(line, Globalization.NumberStyles.HexNumber, null) with
    | true, v -> Some v
    | false, _ -> None

/// Read a real number
/// Original: PROCEDURE RdReal(): REAL
let rdReal () : float32 option =
    let line = Console.ReadLine()
    match Single.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a long real number
/// Original: PROCEDURE RdLngReal(): LONGREAL
let rdLngReal () : float option =
    let line = Console.ReadLine()
    match Double.TryParse(line) with
    | true, v -> Some v
    | false, _ -> None

/// Read a string
/// Original: PROCEDURE RdStr(VAR S: ARRAY OF CHAR)
let rdStr () : string =
    Console.ReadLine() |> Option.ofObj |> Option.defaultValue ""

/// Read an item (whitespace-delimited)
/// Original: PROCEDURE RdItem(VAR V: ARRAY OF CHAR)
let rdItem () : string =
    let line = rdStr ()
    let parts = line.Split([|' '; '\t'|], StringSplitOptions.RemoveEmptyEntries)
    if parts.Length > 0 then parts.[0] else ""

/// Read and discard rest of line
/// Original: PROCEDURE RdLn
let rdLn () : unit =
    Console.ReadLine() |> ignore

/// Check if at end of input
/// Original: PROCEDURE EndOfRd(Skip: BOOLEAN): BOOLEAN
let endOfRd (_skip: bool) : bool =
    Console.In.Peek() = -1

// ============================================================================
// KEYBOARD FUNCTIONS
// ============================================================================

/// Check if a key has been pressed
/// Original: PROCEDURE KeyPressed(): BOOLEAN
let keyPressed () : bool =
    Console.KeyAvailable

/// Read a key (blocking)
/// Original: PROCEDURE RdKey(): CHAR
let rdKey () : char =
    let key = Console.ReadKey(true)
    key.KeyChar

/// Read key info (extended key support)
let rdKeyInfo () : ConsoleKeyInfo =
    Console.ReadKey(true)

// ============================================================================
// EXTENDED KEY SUPPORT (from EXTENDKE.MOD)
// ============================================================================

/// Extended key codes for function keys, arrows, etc.
type ExtendedKey =
    | Char of char
    | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12
    | Up | Down | Left | Right
    | Home | End | PageUp | PageDown
    | Insert | Delete
    | Escape | Enter | Tab | Backspace
    | Unknown of ConsoleKey

/// Read an extended key
/// Original: PROCEDURE ExtRead(VAR Code: CHAR; VAR Extended: BOOLEAN)
let extRead () : ExtendedKey =
    let keyInfo = Console.ReadKey(true)
    match keyInfo.Key with
    | ConsoleKey.F1 -> F1
    | ConsoleKey.F2 -> F2
    | ConsoleKey.F3 -> F3
    | ConsoleKey.F4 -> F4
    | ConsoleKey.F5 -> F5
    | ConsoleKey.F6 -> F6
    | ConsoleKey.F7 -> F7
    | ConsoleKey.F8 -> F8
    | ConsoleKey.F9 -> F9
    | ConsoleKey.F10 -> F10
    | ConsoleKey.F11 -> F11
    | ConsoleKey.F12 -> F12
    | ConsoleKey.UpArrow -> Up
    | ConsoleKey.DownArrow -> Down
    | ConsoleKey.LeftArrow -> Left
    | ConsoleKey.RightArrow -> Right
    | ConsoleKey.Home -> Home
    | ConsoleKey.End -> End
    | ConsoleKey.PageUp -> PageUp
    | ConsoleKey.PageDown -> PageDown
    | ConsoleKey.Insert -> Insert
    | ConsoleKey.Delete -> Delete
    | ConsoleKey.Escape -> Escape
    | ConsoleKey.Enter -> Enter
    | ConsoleKey.Tab -> Tab
    | ConsoleKey.Backspace -> Backspace
    | _ when keyInfo.KeyChar <> char 0 -> Char keyInfo.KeyChar
    | other -> Unknown other

// ============================================================================
// FILE I/O ABSTRACTION
// ============================================================================

/// Result type for file operations
type FileResult<'T> = Result<'T, string>

/// Read all bytes from a file
let readAllBytes (path: string) : FileResult<byte array> =
    try
        Ok (IO.File.ReadAllBytes(path))
    with ex ->
        Error ex.Message

/// Write all bytes to a file
let writeAllBytes (path: string) (data: byte array) : FileResult<unit> =
    try
        IO.File.WriteAllBytes(path, data)
        Ok ()
    with ex ->
        Error ex.Message

/// Read all text from a file
let readAllText (path: string) : FileResult<string> =
    try
        Ok (IO.File.ReadAllText(path))
    with ex ->
        Error ex.Message

/// Write text to a file
let writeAllText (path: string) (text: string) : FileResult<unit> =
    try
        IO.File.WriteAllText(path, text)
        Ok ()
    with ex ->
        Error ex.Message

/// Check if file exists
let fileExists (path: string) : bool =
    IO.File.Exists(path)

/// Delete a file
let deleteFile (path: string) : FileResult<unit> =
    try
        IO.File.Delete(path)
        Ok ()
    with ex ->
        Error ex.Message

/// Get files matching pattern
let getFiles (directory: string) (pattern: string) : FileResult<string array> =
    try
        Ok (IO.Directory.GetFiles(directory, pattern))
    with ex ->
        Error ex.Message

// ============================================================================
// ASYNC FILE I/O
// ============================================================================

module Async =
    /// Read all bytes from a file asynchronously
    let readAllBytes (path: string) : Async<FileResult<byte array>> =
        async {
            try
                let! bytes = IO.File.ReadAllBytesAsync(path) |> Async.AwaitTask
                return Ok bytes
            with ex ->
                return Error ex.Message
        }

    /// Write all bytes to a file asynchronously
    let writeAllBytes (path: string) (data: byte array) : Async<FileResult<unit>> =
        async {
            try
                do! IO.File.WriteAllBytesAsync(path, data) |> Async.AwaitTask
                return Ok ()
            with ex ->
                return Error ex.Message
        }
