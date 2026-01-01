# Modula-2 to F# Translation Strategy

This document outlines the strategy for translating RADARPAS Modula-2 code to idiomatic F#,
prioritizing immutable pure functions and using computation expressions for imperative patterns.

---

## 1. Core Translation Principles

### 1.1 Prefer Immutability
- **Modula-2 VAR parameters** → Return new values or tuples
- **Mutable state** → Immutable data with transformation functions
- **In-place updates** → Copy-and-update with `{ record with field = newValue }`

### 1.2 Use Computation Expressions for Effects
- **I/O operations** → `async { }` or custom `io { }` computation expression
- **Error handling** → `result { }` computation expression
- **Stateful operations** → `state { }` computation expression
- **Optional values** → `option { }` computation expression

### 1.3 Leverage F# Type System
- **Discriminated unions** for variant types and enumerations
- **Option types** for nullable pointers
- **Result types** for error-prone operations
- **Units of measure** for typed numeric values (e.g., degrees, milliseconds)

---

## 2. Type Translation Rules

| Modula-2 Type | F# Translation | Notes |
|---------------|----------------|-------|
| `CARDINAL` | `uint32` or `uint16` | Use units of measure where appropriate |
| `INTEGER` | `int32` or `int16` | |
| `SHORTCARD` | `byte` or `uint8` | |
| `LONGCARD` | `uint64` | |
| `REAL` | `float32` | |
| `LONGREAL` | `float` (float64) | |
| `BOOLEAN` | `bool` | |
| `CHAR` | `char` | |
| `BYTE` | `byte` | |
| `BITSET` | `Set<int>` or `int` with bit ops | Use custom type for clarity |
| `SET OF enum` | `Set<EnumType>` | |
| `ARRAY[a..b] OF T` | `T array` or `T list` | Use list for immutable sequences |
| `POINTER TO T` | `T option` or `T ref` | Option for nullable, ref for mutation |
| `RECORD ... END` | `type Name = { ... }` | Immutable record |
| `(A,B,C)` enum | `type Name = A \| B \| C` | Discriminated union |
| `ADDRESS` | `nativeint` or abstracted | Avoid raw pointers |

---

## 3. Procedure Translation Rules

### 3.1 Pure Functions (No VAR, No Side Effects)

**Modula-2:**
```modula2
PROCEDURE Square(x: INTEGER): INTEGER;
BEGIN
  RETURN x * x;
END Square;
```

**F#:**
```fsharp
let square (x: int) : int = x * x
```

### 3.2 Functions with VAR Output Parameters

**Modula-2:**
```modula2
PROCEDURE Divide(a, b: INTEGER; VAR quotient, remainder: INTEGER);
BEGIN
  quotient := a DIV b;
  remainder := a MOD b;
END Divide;
```

**F#:** Return a tuple instead of mutating parameters:
```fsharp
let divide (a: int) (b: int) : int * int =
    (a / b, a % b)
```

### 3.3 Functions with VAR In-Out Parameters

**Modula-2:**
```modula2
PROCEDURE Increment(VAR x: INTEGER);
BEGIN
  INC(x);
END Increment;
```

**F#:** Return the new value:
```fsharp
let increment (x: int) : int = x + 1
```

### 3.4 Fallible Operations → Result Type

**Modula-2:**
```modula2
PROCEDURE ParseInt(s: ARRAY OF CHAR; VAR value: INTEGER; VAR ok: BOOLEAN);
BEGIN
  (* parsing logic *)
  ok := success;
END ParseInt;
```

**F#:**
```fsharp
let parseInt (s: string) : Result<int, string> =
    match System.Int32.TryParse(s) with
    | true, value -> Ok value
    | false, _ -> Error $"Cannot parse '{s}' as integer"
```

### 3.5 Imperative Loops → Recursive Functions or Higher-Order Functions

**Modula-2:**
```modula2
PROCEDURE Sum(arr: ARRAY OF INTEGER; n: CARDINAL): INTEGER;
VAR i: CARDINAL; total: INTEGER;
BEGIN
  total := 0;
  FOR i := 0 TO n-1 DO
    total := total + arr[i];
  END;
  RETURN total;
END Sum;
```

**F#:**
```fsharp
let sum (arr: int array) : int =
    Array.sum arr

// Or with fold:
let sum (arr: int array) : int =
    arr |> Array.fold (+) 0
```

### 3.6 Side-Effecting Procedures → Computation Expressions

**Modula-2:**
```modula2
PROCEDURE SaveData(filename: ARRAY OF CHAR; data: ARRAY OF BYTE): BOOLEAN;
VAR f: File;
BEGIN
  f := Create(filename);
  IF f = MAX(CARDINAL) THEN RETURN FALSE END;
  WrBin(f, data, HIGH(data)+1);
  Close(f);
  RETURN TRUE;
END SaveData;
```

**F#:**
```fsharp
let saveData (filename: string) (data: byte array) : Result<unit, string> =
    result {
        try
            System.IO.File.WriteAllBytes(filename, data)
            return ()
        with ex ->
            return! Error $"Failed to save: {ex.Message}"
    }

// Or with async for I/O:
let saveDataAsync (filename: string) (data: byte array) : Async<Result<unit, string>> =
    async {
        try
            do! System.IO.File.WriteAllBytesAsync(filename, data) |> Async.AwaitTask
            return Ok ()
        with ex ->
            return Error $"Failed to save: {ex.Message}"
    }
```

---

## 4. Module Translation

### 4.1 DEFINITION MODULE → F# Signature File (.fsi)

**Modula-2:**
```modula2
DEFINITION MODULE CRC;
  PROCEDURE CalcCRC(BufAdr: ADDRESS; BufSize: CARDINAL): CARDINAL;
  PROCEDURE AddCRC(VAR crc: CARDINAL; ch: BYTE);
END CRC.
```

**F#:** `Crc.fsi`
```fsharp
module Crc

val calcCrc : data: byte array -> uint16
val addCrc : crc: uint16 -> byte: byte -> uint16
```

### 4.2 IMPLEMENTATION MODULE → F# Module (.fs)

The implementation follows the signature, with internal helpers kept private.

---

## 5. Specific Pattern Translations

### 5.1 Linked Lists → F# Lists or Custom Types

**Modula-2:**
```modula2
TYPE
  NodePtr = POINTER TO NodeRec;
  NodeRec = RECORD
    Data: INTEGER;
    Next: NodePtr;
  END;
```

**F#:** Use built-in list or custom DU:
```fsharp
// Using F# list (preferred for simple cases):
type NodeList = int list

// Custom type for more control:
type Node =
    | Empty
    | Node of data: int * next: Node
```

### 5.2 BITSET Operations

**Modula-2:**
```modula2
VAR planes: BITSET;
planes := {0, 1, 2};
IF 2 IN planes THEN ... END;
```

**F#:**
```fsharp
type Bitset = Set<int>

let planes : Bitset = Set.ofList [0; 1; 2]
if Set.contains 2 planes then ...

// Or for performance-critical code, use int with bit operations:
let planes = 0b111  // bits 0, 1, 2 set
if planes &&& (1 <<< 2) <> 0 then ...
```

### 5.3 WITH Statements → Let Bindings or Pipelines

**Modula-2:**
```modula2
WITH picture DO
  WriteTime(TimeofPic);
  WriteTilt(Tilt);
END;
```

**F#:**
```fsharp
let { timeOfPic = time; tilt = tilt } = picture
writeTime time
writeTilt tilt

// Or with pipeline:
picture
|> fun p -> writeTime p.timeOfPic; writeTilt p.tilt
```

### 5.4 CASE Statements → Pattern Matching

**Modula-2:**
```modula2
CASE result OF
  Connect2400,
  Connect1200: Message("Connected") |
  NoCarrier: Message("No carrier") |
ELSE
  Message("Unknown error")
END;
```

**F#:**
```fsharp
match result with
| Connect2400 | Connect1200 -> message "Connected"
| NoCarrier -> message "No carrier"
| _ -> message "Unknown error"
```

---

## 6. Computation Expressions

### 6.1 Result Computation Expression

```fsharp
type ResultBuilder() =
    member _.Bind(x, f) = Result.bind f x
    member _.Return(x) = Ok x
    member _.ReturnFrom(x) = x
    member _.Zero() = Ok ()

let result = ResultBuilder()

// Usage:
let processData data =
    result {
        let! parsed = parseData data
        let! validated = validate parsed
        return transform validated
    }
```

### 6.2 State Computation Expression

For stateful operations that thread state through:

```fsharp
type State<'s, 'a> = 's -> 'a * 's

type StateBuilder() =
    member _.Bind(m: State<'s, 'a>, f: 'a -> State<'s, 'b>) : State<'s, 'b> =
        fun s ->
            let (a, s') = m s
            f a s'
    member _.Return(x) : State<'s, 'a> = fun s -> (x, s)
    member _.ReturnFrom(m) = m

let state = StateBuilder()

let getState : State<'s, 's> = fun s -> (s, s)
let setState (s: 's) : State<'s, unit> = fun _ -> ((), s)
```

---

## 7. Handling Imperative Code That Cannot Be Made Pure

Some code inherently requires mutation (e.g., I/O, hardware interfaces). For these:

### 7.1 Isolate Effects

Create a boundary between pure and impure code:

```fsharp
// Pure domain logic
module Domain =
    let calculateCrc (data: byte array) : uint16 = ...
    let formatFileName (time: Time) (params: PicParams) : string = ...

// Impure I/O operations
module IO =
    let savePicture (filename: string) (data: byte array) : Async<Result<unit, IOError>> = ...
    let loadPicture (filename: string) : Async<Result<byte array, IOError>> = ...
```

### 7.2 Use Dependency Injection for Testability

```fsharp
type IFileSystem =
    abstract member WriteAllBytes: string -> byte array -> Async<Result<unit, string>>
    abstract member ReadAllBytes: string -> Async<Result<byte array, string>>

let savePictureWith (fs: IFileSystem) (filename: string) (data: byte array) =
    fs.WriteAllBytes filename data
```

---

## 8. Migration Strategy

1. **Start with leaf modules** (no dependencies): CRC, TimeDate, IO primitives
2. **Move up the dependency tree**: Graphics, then Pictures, then Stations
3. **Create thin wrappers** for external interfaces (serial ports, file system)
4. **Test each module** before moving to dependents
5. **Maintain type compatibility** at module boundaries during migration

---

## 9. Naming Conventions

| Modula-2 | F# |
|----------|-----|
| `PROCEDURE FooBar` | `let fooBar` (camelCase) |
| `TYPE FooBar` | `type FooBar` (PascalCase) |
| `MODULE FooBar` | `module FooBar` (PascalCase) |
| `CONST FOO_BAR` | `let [<Literal>] FooBar` or module value |
| `VAR fooBar` | Avoid, or use `let mutable` sparingly |

---

## 10. Example Complete Module Translation

See the accompanying F# source files for complete translations of:
- `Crc.fs` - CRC calculation (pure functions)
- `TimeDate.fs` - Time/date handling (mostly pure with some system calls)
- `Pictures.fs` - Picture management (uses Result and Async)
- `Stations.fs` - Station management (uses Result and Async)
