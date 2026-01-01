# Few-Shot Prompt: Modula-2 to F# Translation

This document provides example translations to guide the conversion of RADARPAS code
from Modula-2 to idiomatic F#.

---

## System Prompt for Translation

```
You are an expert at translating Modula-2 code to idiomatic F#. Follow these principles:

1. IMMUTABILITY: Convert mutable state to immutable data structures. Return new values
   instead of mutating VAR parameters.

2. PURE FUNCTIONS: Prefer pure functions without side effects. Isolate I/O and other
   effects at the boundaries.

3. COMPUTATION EXPRESSIONS: Use `result { }` for error handling, `async { }` for I/O,
   and `option { }` for optional values.

4. TYPE SAFETY: Use discriminated unions for enums and variants. Use Option<T> instead
   of null/NIL. Use Result<T,E> instead of boolean success flags.

5. HIGHER-ORDER FUNCTIONS: Replace loops with map, filter, fold, etc. where appropriate.

6. PATTERN MATCHING: Use pattern matching instead of CASE statements and IF chains.

7. NAMING: Use camelCase for functions/values, PascalCase for types/modules.
```

---

## Example 1: Simple Pure Function

### Modula-2 Input:
```modula2
PROCEDURE Hex(Num: BYTE): ARRAY[0..1] OF CHAR;
VAR
  digit: CARDINAL;
  result: ARRAY[0..1] OF CHAR;
BEGIN
  digit := Num DIV 16;
  IF digit < 10 THEN
    result[0] := CHR(ORD('0') + digit);
  ELSE
    result[0] := CHR(ORD('A') + digit - 10);
  END;
  digit := Num MOD 16;
  IF digit < 10 THEN
    result[1] := CHR(ORD('0') + digit);
  ELSE
    result[1] := CHR(ORD('A') + digit - 10);
  END;
  RETURN result;
END Hex;
```

### F# Output:
```fsharp
let hex (num: byte) : string =
    let hexDigit n =
        if n < 10uy then char (int '0' + int n)
        else char (int 'A' + int n - 10)
    sprintf "%c%c" (hexDigit (num / 16uy)) (hexDigit (num % 16uy))
```

---

## Example 2: Record Type with Associated Functions

### Modula-2 Input:
```modula2
TYPE
  Time = RECORD
    day, minute, millisec: CARDINAL;
  END;

PROCEDURE CompareTime(t1, t2: Time): INTEGER;
BEGIN
  IF t1.day < t2.day THEN RETURN -1;
  ELSIF t1.day > t2.day THEN RETURN 1;
  ELSIF t1.minute < t2.minute THEN RETURN -1;
  ELSIF t1.minute > t2.minute THEN RETURN 1;
  ELSIF t1.millisec < t2.millisec THEN RETURN -1;
  ELSIF t1.millisec > t2.millisec THEN RETURN 1;
  ELSE RETURN 0;
  END;
END CompareTime;
```

### F# Output:
```fsharp
type Time = {
    Day: uint16        // Bits: 0-4=day, 5-8=month, 9-15=year-1900
    Minute: uint16     // hour * 60 + minutes
    Millisec: uint16   // second * 1000 + milliseconds
}

module Time =
    let zero = { Day = 0us; Minute = 0us; Millisec = 0us }

    let compare (t1: Time) (t2: Time) : int =
        match compare t1.Day t2.Day with
        | 0 ->
            match compare t1.Minute t2.Minute with
            | 0 -> compare t1.Millisec t2.Millisec
            | c -> c
        | c -> c

    // Implement IComparable for the type
    let (|<|) t1 t2 = compare t1 t2 < 0
    let (|>|) t1 t2 = compare t1 t2 > 0
    let (|=|) t1 t2 = compare t1 t2 = 0
```

---

## Example 3: VAR Parameters → Return Tuple

### Modula-2 Input:
```modula2
PROCEDURE FileParam(VAR Picture: PictureRec;
                    NameofFile: ARRAY OF CHAR;
                    VAR OK: BOOLEAN);
VAR
  TimeString: ARRAY[0..1] OF CHAR;
  Hour, Minute: CARDINAL;
BEGIN
  Slice(TimeString, NameofFile, 0, 2);
  Hour := StrToCard(TimeString, 10, OK);
  IF NOT OK THEN RETURN END;

  Slice(TimeString, NameofFile, 2, 2);
  Minute := StrToCard(TimeString, 10, OK);
  IF NOT OK THEN RETURN END;

  WITH Picture DO
    TimeofPic.minute := Hour * 60 + Minute;
    Tilt := ORD(NameofFile[4]) - 65;
    Range := ORD(NameofFile[5]) - 65;
    Gain := ORD(NameofFile[6]) - 64;
    Data := NIL;
    Flags := PicFlagSet{};
  END;
END FileParam;
```

### F# Output:
```fsharp
let parseFileName (nameOfFile: string) : Result<PictureRec, string> =
    result {
        do! if nameOfFile.Length < 7 then Error "Filename too short" else Ok ()

        let! hour =
            match System.UInt16.TryParse(nameOfFile.Substring(0, 2)) with
            | true, h -> Ok h
            | false, _ -> Error "Invalid hour in filename"

        let! minute =
            match System.UInt16.TryParse(nameOfFile.Substring(2, 2)) with
            | true, m -> Ok m
            | false, _ -> Error "Invalid minute in filename"

        return {
            TimeOfPic = { Day = 0us; Minute = hour * 60us + minute; Millisec = 0us }
            Tilt = byte (int nameOfFile.[4] - int 'A')
            Range = byte (int nameOfFile.[5] - int 'A')
            Gain = byte (int nameOfFile.[6] - int '@')
            Data = None
            Flags = Set.empty
        }
    }
```

---

## Example 4: Stateful CRC Calculation → Fold

### Modula-2 Input:
```modula2
PROCEDURE CalcCRC(BufAdr: ADDRESS; BufSize: CARDINAL): CARDINAL;
VAR
  i, crc: CARDINAL;
BEGIN
  crc := 0;
  FOR i := 0 TO BufSize - 1 DO
    AddCRC(crc, PeekByte(BufAdr, i));
  END;
  RETURN crc;
END CalcCRC;

PROCEDURE AddCRC(VAR crc: CARDINAL; ch: BYTE);
VAR
  tab: CARDINAL;
BEGIN
  tab := CARDINAL((BITSET(crc) / BITSET(ch)) * {0..7});
  crc := CARDINAL((BITSET(crc * 256) * {0..7}) / crctab[tab]);
END AddCRC;
```

### F# Output:
```fsharp
module Crc =
    let private crcTable : uint16 array =
        [| 0x0000us; 0xC0C1us; 0xC181us; 0x0140us; (* ... full table ... *) |]

    let addCrc (crc: uint16) (byte: byte) : uint16 =
        let index = int ((crc ^^^ uint16 byte) &&& 0xFFus)
        ((crc >>> 8) &&& 0xFFus) ^^^ crcTable.[index]

    let calcCrc (data: byte array) : uint16 =
        data |> Array.fold addCrc 0us

    // Alternative with ReadOnlySpan for performance
    let calcCrcSpan (data: System.ReadOnlySpan<byte>) : uint16 =
        let mutable crc = 0us
        for i = 0 to data.Length - 1 do
            crc <- addCrc crc data.[i]
        crc
```

---

## Example 5: Linked List with Iteration → F# List

### Modula-2 Input:
```modula2
TYPE
  StationPtr = POINTER TO StationRec;
  StationRec = RECORD
    StationName: ARRAY[0..11] OF CHAR;
    Phone: ARRAY[0..63] OF CHAR;
    Next: StationPtr;
  END;

PROCEDURE FindStation(list: StationPtr; num: CARDINAL): StationPtr;
VAR
  current: StationPtr;
  count: CARDINAL;
BEGIN
  current := list;
  count := 1;
  WHILE (current # NIL) & (count < num) DO
    current := current^.Next;
    INC(count);
  END;
  RETURN current;
END FindStation;
```

### F# Output:
```fsharp
type Station = {
    StationName: string
    Phone: string
    // No 'Next' pointer - we use F# list instead
}

module Station =
    let findByIndex (index: int) (stations: Station list) : Station option =
        stations |> List.tryItem index

    // Or with 1-based indexing like the original:
    let findByNumber (num: int) (stations: Station list) : Station option =
        if num < 1 then None
        else stations |> List.tryItem (num - 1)
```

---

## Example 6: Side-Effecting I/O → Async Result

### Modula-2 Input:
```modula2
PROCEDURE SavePicture(VAR ForPicture: PictureRec; VAR SaveDone: BOOLEAN);
VAR
  DataFileName: ARRAY[1..12] OF CHAR;
  DataFile: File;
BEGIN
  FileName(ForPicture, DataFileName);
  DataFile := Create(DataFileName);
  IF DataFile = MAX(CARDINAL) THEN
    SaveDone := FALSE;
    RETURN;
  END;

  WrBin(DataFile, ForPicture.Data^, ForPicture.Size);
  Close(DataFile);

  IF SaveDone THEN
    EXCL(ForPicture.Flags, NotSaved);
  END;
END SavePicture;
```

### F# Output:
```fsharp
type SaveError =
    | FileCreationFailed of string
    | WriteError of exn

let savePicture (picture: PictureRec) : Async<Result<PictureRec, SaveError>> =
    async {
        match picture.Data with
        | None ->
            return Error (WriteError (System.InvalidOperationException("No data to save")))
        | Some data ->
            let fileName = generateFileName picture
            try
                do! System.IO.File.WriteAllBytesAsync(fileName, data) |> Async.AwaitTask
                return Ok { picture with Flags = picture.Flags |> Set.remove NotSaved }
            with
            | :? System.IO.IOException as ex ->
                return Error (FileCreationFailed ex.Message)
            | ex ->
                return Error (WriteError ex)
    }
```

---

## Example 7: BITSET Operations

### Modula-2 Input:
```modula2
TYPE
  PicFlag = (NotSaved, BeingDownLoaded);
  PicFlagSet = SET OF PicFlag;

VAR
  flags: PicFlagSet;

(* Usage *)
flags := PicFlagSet{};
INCL(flags, NotSaved);
IF NotSaved IN flags THEN ... END;
EXCL(flags, NotSaved);
```

### F# Output:
```fsharp
type PicFlag =
    | NotSaved
    | BeingDownloaded

type PicFlagSet = Set<PicFlag>

module PicFlagSet =
    let empty : PicFlagSet = Set.empty
    let add flag set = Set.add flag set
    let remove flag set = Set.remove flag set
    let contains flag set = Set.contains flag set

// Usage:
let flags = PicFlagSet.empty
let flags' = flags |> PicFlagSet.add NotSaved
if PicFlagSet.contains NotSaved flags' then ...
let flags'' = flags' |> PicFlagSet.remove NotSaved
```

---

## Example 8: Graphics Plane Selection (Bitwise Operations)

### Modula-2 Input:
```modula2
PROCEDURE SetPlane(ToPlanes: BITSET);
BEGIN
  (* ... hardware register manipulation *)
  Port[3CEH] := 5;
  Port[3CFH] := CARDINAL(ToPlanes);
END SetPlane;

(* Usage *)
SetPlane({0, 1});      (* Select planes 0 and 1 *)
SetPlane({2, 3});      (* Select planes 2 and 3 *)
```

### F# Output:
```fsharp
type GraphicsPlane = Plane0 | Plane1 | Plane2 | Plane3

type PlaneSet = Set<GraphicsPlane>

module PlaneSet =
    let ofList = Set.ofList
    let toMask (planes: PlaneSet) : byte =
        planes
        |> Set.fold (fun acc p ->
            match p with
            | Plane0 -> acc ||| 1uy
            | Plane1 -> acc ||| 2uy
            | Plane2 -> acc ||| 4uy
            | Plane3 -> acc ||| 8uy) 0uy

// For low-level graphics, abstract the hardware:
type IGraphicsHardware =
    abstract member SetPlane: PlaneSet -> unit
    abstract member SetFunction: GraphicsFunction -> unit

// Usage:
let planes = PlaneSet.ofList [Plane0; Plane1]
hardware.SetPlane planes
```

---

## Example 9: Menu Loop with User Input → State Machine

### Modula-2 Input:
```modula2
PROCEDURE PictureMenu(VAR Selected: CARDINAL);
VAR
  Key: CHAR;
  Escape: BOOLEAN;
BEGIN
  LOOP
    DrawMenu();
    Select(Selected, Key, Escape);

    IF Escape & (Key = F1) THEN
      DeletePicture(Selected);
    ELSIF ~Escape & (Key = ESC) THEN
      EXIT;
    ELSIF ~Escape & (Key = CR) THEN
      EXIT;
    END;
  END;
END PictureMenu;
```

### F# Output:
```fsharp
type MenuAction =
    | Delete of index: int
    | Select of index: int
    | Cancel

type MenuState = {
    SelectedIndex: int
    Items: PictureRec list
}

let rec pictureMenuLoop (state: MenuState) (ui: IUserInterface) : Async<MenuAction> =
    async {
        do! ui.DrawMenu state
        let! input = ui.WaitForInput ()

        match input with
        | Key.F1 when state.SelectedIndex >= 0 ->
            return Delete state.SelectedIndex
        | Key.Escape ->
            return Cancel
        | Key.Enter when state.SelectedIndex >= 0 ->
            return Select state.SelectedIndex
        | Key.Up ->
            let newState = { state with SelectedIndex = max 0 (state.SelectedIndex - 1) }
            return! pictureMenuLoop newState ui
        | Key.Down ->
            let maxIdx = List.length state.Items - 1
            let newState = { state with SelectedIndex = min maxIdx (state.SelectedIndex + 1) }
            return! pictureMenuLoop newState ui
        | _ ->
            return! pictureMenuLoop state ui
    }
```

---

## Example 10: Memory Allocation with Purging → Managed Collections

### Modula-2 Input:
```modula2
PROCEDURE ReserveMem(VAR ForBuffer: ADDRESS;
                     Size: CARDINAL;
                     PicList: ARRAY OF PictureRec;
                     VAR done: BOOLEAN);
BEGIN
  WHILE NOT Available(Size) DO
    (* Find earliest picture and purge it *)
    Earliest := FindEarliest(PicList);
    IF Earliest = 0 THEN
      done := FALSE;
      RETURN;
    END;
    IF NotSaved IN PicList[Earliest].Flags THEN
      SavePicture(PicList[Earliest], done);
    END;
    DEALLOCATE(PicList[Earliest].Data, PicList[Earliest].Size);
  END;
  ALLOCATE(ForBuffer, Size);
  done := TRUE;
END ReserveMem;
```

### F# Output:
```fsharp
// In F#, we let the GC handle memory, but we can still implement
// a cache with LRU eviction policy:

type PictureCache = {
    Pictures: Map<PictureId, PictureRec>
    AccessOrder: PictureId list  // Most recent first
    MaxMemory: int64
    CurrentMemory: int64
}

module PictureCache =
    let private calculateSize (pic: PictureRec) : int64 =
        pic.Data |> Option.map (fun d -> int64 d.Length) |> Option.defaultValue 0L

    let private findLruWithData (cache: PictureCache) : PictureId option =
        cache.AccessOrder
        |> List.rev
        |> List.tryFind (fun id ->
            cache.Pictures
            |> Map.tryFind id
            |> Option.bind (fun p -> p.Data)
            |> Option.isSome)

    let evictIfNeeded (requiredSize: int64) (cache: PictureCache) : Async<Result<PictureCache, string>> =
        async {
            let rec evictLoop currentCache =
                async {
                    if currentCache.MaxMemory - currentCache.CurrentMemory >= requiredSize then
                        return Ok currentCache
                    else
                        match findLruWithData currentCache with
                        | None ->
                            return Error "Cannot free enough memory"
                        | Some picId ->
                            let pic = currentCache.Pictures.[picId]
                            let! saveResult =
                                if Set.contains NotSaved pic.Flags then
                                    savePicture pic
                                else
                                    async { return Ok pic }

                            match saveResult with
                            | Error e -> return Error (sprintf "Save failed: %A" e)
                            | Ok savedPic ->
                                let freedSize = calculateSize pic
                                let newCache = {
                                    currentCache with
                                        Pictures = currentCache.Pictures |> Map.add picId { savedPic with Data = None }
                                        CurrentMemory = currentCache.CurrentMemory - freedSize
                                }
                                return! evictLoop newCache
                }
            return! evictLoop cache
        }
```

---

## Summary: Translation Checklist

For each Modula-2 procedure:

1. [ ] Identify if it's pure (no VAR, no I/O) or has effects
2. [ ] Pure? → Direct F# function
3. [ ] VAR out params? → Return tuple or record
4. [ ] VAR in-out params? → Return new value
5. [ ] Boolean success flag? → Use `Result<'T, 'E>`
6. [ ] Optional/nullable? → Use `Option<'T>`
7. [ ] I/O operations? → Use `Async<Result<'T, 'E>>`
8. [ ] Loops? → Use `fold`, `map`, recursion
9. [ ] CASE? → Use pattern matching
10. [ ] BITSET? → Use `Set<T>` or bit operations
11. [ ] Linked list? → Use F# `list` or custom DU
12. [ ] WITH statement? → Destructure or pipeline
