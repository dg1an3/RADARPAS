/// Graphics module - Drawing primitives and screen management
/// Translated from Modula-2 GRAPHICS.DEF and GRAPH.DEF
/// Note: This provides an abstract interface; actual rendering
/// would be implemented via a graphics library (e.g., SkiaSharp, OpenGL)
module Radarpas.Graphics

open System
open Radarpas.CoreTypes

// ============================================================================
// GRAPHICS CONFIGURATION
// ============================================================================

/// Screen dimensions for different modes
type ScreenDimensions = {
    Width: int
    Height: int
    Colors: int
}

module ScreenDimensions =
    let cga = { Width = 320; Height = 200; Colors = 4 }
    let ega = { Width = 640; Height = 350; Colors = 16 }
    let vga = { Width = 640; Height = 480; Colors = 16 }
    let herc = { Width = 720; Height = 348; Colors = 2 }

/// Current graphics state (immutable)
type GraphicsState = {
    ScreenMode: ScreenMode
    Dimensions: ScreenDimensions
    CurrentPlane: PlaneSet
    CurrentFunction: GraphicsFunction
    RotateAmount: int
    WindowX: int
    WindowY: int
    WindowWidth: int
    WindowHeight: int
    CursorX: int
    CursorY: int
    FontSize: int
    IsBold: bool
    IsItalic: bool
    IsUnderline: bool
    IsProportional: bool
    IsHalftone: bool
}

module GraphicsState =
    let defaultState = {
        ScreenMode = Color
        Dimensions = ScreenDimensions.ega
        CurrentPlane = PlaneSet.all
        CurrentFunction = Clear
        RotateAmount = 0
        WindowX = 0
        WindowY = 0
        WindowWidth = 640
        WindowHeight = 350
        CursorX = 0
        CursorY = 0
        FontSize = 8
        IsBold = false
        IsItalic = false
        IsUnderline = false
        IsProportional = false
        IsHalftone = false
    }

// ============================================================================
// PURE GRAPHICS STATE TRANSFORMATIONS
// ============================================================================

/// Set screen mode (returns new state)
/// Original: PROCEDURE ScreenMode(ToMode: CARDINAL)
let setScreenMode (mode: ScreenMode) (state: GraphicsState) : GraphicsState =
    let dims =
        match mode with
        | Text -> ScreenDimensions.cga
        | Mono -> ScreenDimensions.herc
        | Color -> ScreenDimensions.ega
    { state with ScreenMode = mode; Dimensions = dims }

/// Set active plane(s)
/// Original: PROCEDURE SetPlane(ToPlanes: BITSET)
let setPlane (planes: PlaneSet) (state: GraphicsState) : GraphicsState =
    { state with CurrentPlane = planes }

/// Get active plane(s)
/// Original: PROCEDURE GetPlane(VAR ToPlanes: BITSET)
let getPlane (state: GraphicsState) : PlaneSet =
    state.CurrentPlane

/// Set graphics function
/// Original: PROCEDURE SetFunc(ToFunc: FuncType; Rotate: RotateRange)
let setFunction (func: GraphicsFunction) (rotate: int) (state: GraphicsState) : GraphicsState =
    { state with CurrentFunction = func; RotateAmount = rotate }

/// Set window region
/// Original: PROCEDURE SetWindow(X1, Y1, XSize, YSize: INTEGER)
let setWindow (x: int) (y: int) (width: int) (height: int) (state: GraphicsState) : GraphicsState =
    { state with WindowX = x; WindowY = y; WindowWidth = width; WindowHeight = height }

/// Get window region
/// Original: PROCEDURE GetWindow(VAR X1, Y1, XSize, YSize: INTEGER)
let getWindow (state: GraphicsState) : int * int * int * int =
    (state.WindowX, state.WindowY, state.WindowWidth, state.WindowHeight)

/// Set cursor position
/// Original: PROCEDURE GotoXY(X, Y: CARDINAL)
let gotoXY (x: int) (y: int) (state: GraphicsState) : GraphicsState =
    { state with CursorX = x; CursorY = y }

/// Set cursor by row/column
/// Original: PROCEDURE GotoRowCol(Row, Col: CARDINAL)
let gotoRowCol (row: int) (col: int) (state: GraphicsState) : GraphicsState =
    let x = col * 8  // 8 pixels per character
    let y = row * state.FontSize
    gotoXY x y state

/// Set font size
/// Original: PROCEDURE SetFont(Size: CARDINAL)
let setFont (size: int) (state: GraphicsState) : GraphicsState =
    { state with FontSize = size }

/// Set text attributes
let setBold (on: bool) (state: GraphicsState) = { state with IsBold = on }
let setItalic (on: bool) (state: GraphicsState) = { state with IsItalic = on }
let setUnderline (on: bool) (state: GraphicsState) = { state with IsUnderline = on }
let setProportional (on: bool) (state: GraphicsState) = { state with IsProportional = on }
let setHalftone (on: bool) (state: GraphicsState) = { state with IsHalftone = on }

// ============================================================================
// CLIPPING
// ============================================================================

/// Check if point is within current window
/// Original: PROCEDURE Clip(X, Y: INTEGER): BOOLEAN
let clip (x: int) (y: int) (state: GraphicsState) : bool =
    x >= state.WindowX &&
    x < state.WindowX + state.WindowWidth &&
    y >= state.WindowY &&
    y < state.WindowY + state.WindowHeight

/// Clip line to window bounds (Cohen-Sutherland algorithm)
/// Original: PROCEDURE ClipLine(VAR X1, Y1, X2, Y2: INTEGER): BOOLEAN
let clipLine (x1: int) (y1: int) (x2: int) (y2: int) (state: GraphicsState)
    : ((int * int * int * int) option) =

    let left = state.WindowX
    let right = state.WindowX + state.WindowWidth - 1
    let top = state.WindowY
    let bottom = state.WindowY + state.WindowHeight - 1

    let outcode x y =
        (if x < left then 1 else 0) |||
        (if x > right then 2 else 0) |||
        (if y < top then 4 else 0) |||
        (if y > bottom then 8 else 0)

    let rec loop x1 y1 x2 y2 =
        let code1 = outcode x1 y1
        let code2 = outcode x2 y2

        if code1 = 0 && code2 = 0 then
            Some (x1, y1, x2, y2)  // Trivially accept
        elif code1 &&& code2 <> 0 then
            None  // Trivially reject
        else
            let codeOut = if code1 <> 0 then code1 else code2
            let x, y =
                if codeOut &&& 8 <> 0 then
                    (x1 + (x2 - x1) * (bottom - y1) / (y2 - y1), bottom)
                elif codeOut &&& 4 <> 0 then
                    (x1 + (x2 - x1) * (top - y1) / (y2 - y1), top)
                elif codeOut &&& 2 <> 0 then
                    (right, y1 + (y2 - y1) * (right - x1) / (x2 - x1))
                else
                    (left, y1 + (y2 - y1) * (left - x1) / (x2 - x1))

            if codeOut = code1 then
                loop x y x2 y2
            else
                loop x1 y1 x y

    loop x1 y1 x2 y2

// ============================================================================
// DRAWING PRIMITIVES (Pure - returns drawing commands)
// ============================================================================

/// Represents a drawing command
type DrawCommand =
    | SetPixel of x: int * y: int * color: byte
    | DrawLine of x1: int * y1: int * x2: int * y2: int * color: byte
    | DrawCircle of cx: int * cy: int * radius: int * color: byte
    | FillCircle of cx: int * cy: int * radius: int * color: byte
    | DrawEllipse of cx: int * cy: int * rx: int * ry: int * color: byte * fill: bool
    | FillRect of x: int * y: int * width: int * height: int * color: byte
    | DrawText of x: int * y: int * text: string * color: byte
    | ClearArea of x: int * y: int * width: int * height: int

/// Generate point command
/// Original: PROCEDURE Point(X, Y: INTEGER)
let point (x: int) (y: int) (color: byte) (state: GraphicsState) : DrawCommand option =
    let absX = state.WindowX + x
    let absY = state.WindowY + y
    if clip absX absY state then
        Some (SetPixel (absX, absY, color))
    else
        None

/// Generate line command using Bresenham's algorithm
/// Original: PROCEDURE Line(X1, Y1, X2, Y2: INTEGER)
let line (x1: int) (y1: int) (x2: int) (y2: int) (color: byte) (state: GraphicsState)
    : DrawCommand option =
    let absX1 = state.WindowX + x1
    let absY1 = state.WindowY + y1
    let absX2 = state.WindowX + x2
    let absY2 = state.WindowY + y2
    match clipLine absX1 absY1 absX2 absY2 state with
    | Some (cx1, cy1, cx2, cy2) -> Some (DrawLine (cx1, cy1, cx2, cy2, color))
    | None -> None

/// Generate circle command
/// Original: PROCEDURE Circle(x0, y0, r: CARDINAL; c: CARDINAL)
let circle (cx: int) (cy: int) (r: int) (color: byte) : DrawCommand =
    DrawCircle (cx, cy, r, color)

/// Generate filled circle command
/// Original: PROCEDURE Disc(x0, y0, r: CARDINAL; FillColor: CARDINAL)
let disc (cx: int) (cy: int) (r: int) (color: byte) : DrawCommand =
    FillCircle (cx, cy, r, color)

/// Generate ellipse command
/// Original: PROCEDURE Ellipse(x0, y0: CARDINAL; a0, b0: CARDINAL; c: CARDINAL; fill: BOOLEAN)
let ellipse (cx: int) (cy: int) (rx: int) (ry: int) (color: byte) (fill: bool) : DrawCommand =
    DrawEllipse (cx, cy, rx, ry, color, fill)

/// Generate fill area command
/// Original: PROCEDURE FillArea(X1, Y1, XSize, YSize: INTEGER; Pattern: ARRAY OF BYTE)
let fillArea (x: int) (y: int) (width: int) (height: int) (color: byte) : DrawCommand =
    FillRect (x, y, width, height, color)

/// Generate clear screen command
/// Original: PROCEDURE ClearScreen
let clearScreen (state: GraphicsState) : DrawCommand =
    ClearArea (0, 0, state.Dimensions.Width, state.Dimensions.Height)

// ============================================================================
// TEXT RENDERING
// ============================================================================

/// Generate text command
let drawText (x: int) (y: int) (text: string) (color: byte) (state: GraphicsState)
    : DrawCommand list =
    let absX = state.WindowX + x
    let absY = state.WindowY + y
    [DrawText (absX, absY, text, color)]

/// Write character at cursor position
/// Original: PROCEDURE Write(ForChar: CHAR)
let writeChar (c: char) (color: byte) (state: GraphicsState) : DrawCommand * GraphicsState =
    let cmd = DrawText (state.CursorX, state.CursorY, string c, color)
    let charWidth = if state.IsProportional then 6 else 8  // Simplified
    let newState = { state with CursorX = state.CursorX + charWidth }
    (cmd, newState)

// ============================================================================
// PALETTE
// ============================================================================

/// Palette entry (RGB)
type PaletteEntry = {
    Red: byte
    Green: byte
    Blue: byte
}

/// Standard EGA palette
let egaPalette : PaletteEntry array =
    [|
        { Red = 0x00uy; Green = 0x00uy; Blue = 0x00uy }   // 0: Black
        { Red = 0x00uy; Green = 0x00uy; Blue = 0xAAuy }   // 1: Blue
        { Red = 0x00uy; Green = 0xAAuy; Blue = 0x00uy }   // 2: Green
        { Red = 0x00uy; Green = 0xAAuy; Blue = 0xAAuy }   // 3: Cyan
        { Red = 0xAAuy; Green = 0x00uy; Blue = 0x00uy }   // 4: Red
        { Red = 0xAAuy; Green = 0x00uy; Blue = 0xAAuy }   // 5: Magenta
        { Red = 0xAAuy; Green = 0x55uy; Blue = 0x00uy }   // 6: Brown
        { Red = 0xAAuy; Green = 0xAAuy; Blue = 0xAAuy }   // 7: Light Gray
        { Red = 0x55uy; Green = 0x55uy; Blue = 0x55uy }   // 8: Dark Gray
        { Red = 0x55uy; Green = 0x55uy; Blue = 0xFFuy }   // 9: Light Blue
        { Red = 0x55uy; Green = 0xFFuy; Blue = 0x55uy }   // 10: Light Green
        { Red = 0x55uy; Green = 0xFFuy; Blue = 0xFFuy }   // 11: Light Cyan
        { Red = 0xFFuy; Green = 0x55uy; Blue = 0x55uy }   // 12: Light Red
        { Red = 0xFFuy; Green = 0x55uy; Blue = 0xFFuy }   // 13: Light Magenta
        { Red = 0xFFuy; Green = 0xFFuy; Blue = 0x55uy }   // 14: Yellow
        { Red = 0xFFuy; Green = 0xFFuy; Blue = 0xFFuy }   // 15: White
    |]

// ============================================================================
// GRAPHICS ABSTRACTION INTERFACE
// ============================================================================

/// Interface for actual graphics rendering
type IGraphicsRenderer =
    abstract member SetMode : ScreenMode -> unit
    abstract member Execute : DrawCommand -> unit
    abstract member ExecuteAll : DrawCommand list -> unit
    abstract member SetPalette : PaletteEntry array -> unit
    abstract member Present : unit -> unit  // Flip buffers / refresh

/// Null renderer for testing
type NullRenderer() =
    interface IGraphicsRenderer with
        member _.SetMode _ = ()
        member _.Execute _ = ()
        member _.ExecuteAll _ = ()
        member _.SetPalette _ = ()
        member _.Present () = ()

// ============================================================================
// SWEEP/RADAR DISPLAY UTILITIES
// ============================================================================

/// Generate sine/cosine lookup table (for radar sweep)
/// Original: SinCosTable = ARRAY[0..359] OF INTEGER
let sinCosTable : (float * float) array =
    [| for deg in 0 .. 359 ->
        let rad = float deg * Math.PI / 180.0
        (sin rad, cos rad)
    |]

/// Convert polar to cartesian coordinates
let polarToCartesian (centerX: int) (centerY: int) (range: float) (bearing: float<degrees>)
    : int * int =
    let rad = float bearing * Math.PI / 180.0
    let x = centerX + int (range * sin rad)
    let y = centerY - int (range * cos rad)  // Y is inverted in screen coords
    (x, y)

/// Generate radar sweep line points
let sweepLinePoints (centerX: int) (centerY: int) (maxRange: int) (bearing: int)
    : (int * int) list =
    let deg = bearing % 360
    let sin, cos = sinCosTable.[deg]
    [ for r in 0 .. maxRange ->
        let x = centerX + int (float r * sin)
        let y = centerY - int (float r * cos)
        (x, y)
    ]
