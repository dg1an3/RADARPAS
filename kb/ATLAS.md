# RADARPAS Symbol Atlas & Lineage Map

A comprehensive cross-reference of every procedure, function, and data type across all 25 snapshots (1985-1992), tracing each symbol from birth through the Pascal-to-Modula-2 transition to its final form.

---

## Reading This Atlas

- **First seen**: earliest snapshot containing the symbol
- **Last seen**: latest snapshot containing the symbol (or "final" if present in 19921228)
- **Lineage**: `PAS` = Turbo Pascal monolith, `M2` = Modula-2 module, `ASM` = x86 assembly
- **Migration**: symbols that crossed the Pascal/Modula-2 boundary are marked with arrow notation

---

## 1. Architectural Layers

```
 Layer 5: MAIN ── ExecCom, ModemLoop, InterLoop, DoAuto
            │
 Layer 4: STATIONS ── SelectStation, CallStation, AddStation
          PICTURES ── SavePicture, SelectPicture, PictureMenu
          AUTO ── DoAuto, ProgramMenu
          ANALYSIS ── Analyze, DefineArea, DrawMarkers
            │
 Layer 3: SCREENHA ── WritePic, WriteParams, WriteHelp, DrawScale
          SELECTOR ── Select (menu UI abstraction)
          LOCATOR ── MoveCursor, CalcBearing, CalcRange
          MODEM ── Dial, HangUp, WaitResult
          E300INTE ── GetParam, SetParam, MakePic, GetLine
            │
 Layer 2: GRAPHICS ── Plot, Line, Circle, SetPlane, SetFunc
          RS / RS2 ── TxChar, RxChar, SetupRxInt
          FIO ── Open, Create, RdBin, WrBin
          CRC ── CalcCRC, AddCRC
          MEMCOMPR ── Compress, Decompress
            │
 Layer 1: LIB ── Move, Fill, Dos, Intr, QSort, RANDOM
          STR ── string ops
          ASCII ── character constants
          TIMEDATE ── GetTime, SetTime
          IO ── RdStr, WrStr (console)
```

---

## 2. Procedure & Function Lineage

### 2.1 Graphics & Display

| Symbol | Type | Pascal Origin | M2 Module | First Seen | Last Seen | Notes |
|--------|------|---------------|-----------|------------|-----------|-------|
| `InitEGA` | proc | RADAR.PAS | GRAPHICS | 1985xxxx | 19921228 | EGA mode 0x10, 640x350x16 |
| `SelectPlane(ForPlanes)` | proc | RADAR.PAS | GRAPHICS | 1985xxxx | 19921228 | VGA write plane select (BITSET in M2) |
| `ShowPlane(ForPlanes)` | proc | RADAR.PAS | GRAPHICS | 19870412 | 19880801 | Pascal only; merged into EnablePlane in M2 |
| `EnablePlane(ForPlanes)` | proc | -- | GRAPHICS | 19880815 | 19921228 | M2 replacement for ShowPlane |
| `SelectFunc(ForFunc)` | proc | RADAR.PAS | GRAPHICS | 1985xxxx | 19921228 | ROP mode: clr/and/or/xor |
| `SetFunc(ToFunc, Rotate)` | proc | -- | GRAPHICS | 19880815 | 19921228 | Extended version with rotation |
| `GRPlot(X,Y)` | proc | RADAR.PAS | GRAPHICS | 1985xxxx | 19921228 | PAS: inline; M2: dispatches to EGAPlot |
| `GRLine(X1,Y1,X2,Y2)` | proc | RADAR.PAS | GRAPHICS | 1985xxxx | 19921228 | Bresenham line draw |
| `Plot(x,y,Color)` | proc | -- | GRAPH | 19880815 | 19921228 | Color-aware variant |
| `Point(x,y): CARDINAL` | func | -- | GRAPH | 19880815 | 19921228 | Read pixel color |
| `HLine(x,y,x2,FillColor)` | proc | -- | GRAPH | 19880815 | 19921228 | Horizontal line fill |
| `Line(x1,y1,x2,y2,Color)` | proc | -- | GRAPH | 19880815 | 19921228 | Color-aware line |
| `Circle(x0,y0,r,c)` | proc | -- | GRAPH | 19880815 | 19921228 | Circle via midpoint algorithm |
| `Disc(x0,y0,r,FillColor)` | proc | -- | GRAPH | 19880815 | 19921228 | Filled circle |
| `Ellipse(x0,y0,rx,ry,c)` | proc | -- | GRAPH | 19880815 | 19921228 | Ellipse drawing |
| `Polygon(n,px,py,Fill)` | proc | -- | GRAPH | 19880815 | 19921228 | Filled polygon |
| `EGAPlot/EGAPoint/EGAHLine` | proc | -- | GRAPH | 19880815 | 19921228 | EGA device drivers |
| `CGAPlot/CGAPoint/CGAHLine` | proc | -- | GRAPH | 19880815 | 19921228 | CGA device drivers |
| `HercPlot/HercPoint/HercHLine` | proc | -- | GRAPH | 19880815 | 19921228 | Hercules device drivers |
| `ATTPlot/ATTPoint/ATTHLine` | proc | -- | GRAPH | 19880815 | 19921228 | AT&T device drivers |
| `ScreenMode(ToMode)` | proc | -- | GRAPHICS | 19880815 | 19921228 | Video mode abstraction |
| `SetPalette(ToPalette)` | proc | -- | GRAPHICS | 19880815 | 19921228 | 16-color palette |
| `SetWindow(X1,Y1,XSize,YSize)` | proc | -- | GRAPHICS | 19880815 | 19921228 | Clipping window |
| `Clip(X,Y): BOOLEAN` | func | -- | GRAPHICS | 19880815 | 19921228 | Point-in-window test |
| `DispLine(var LinePtr)` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | RLE decompress + render line |
| `ConOut(ForChar)` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Graphics-mode character output |
| `GRWrite(ForStr, X, Y)` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Text at pixel coords |
| `GRMessage(ForStr, WaitKey)` | proc | RADAR.PAS | SCREENHA | 19870412 | 19921228 | Status bar message |
| `ClearScreen` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Clear all planes |
| `DrawScale` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Range ring overlay |
| `WriteRngMks` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Range marks at 10/25/50/100/200nm |
| `WriteGfx(AtLand, AtSeg)` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Landmark + segment overlay |
| `WriteParams(ForParams)` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Tilt/Range/Gain/Time readout |
| `WriteHelp` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | F-key reference overlay |
| `WritePic` | proc | -- | SCREENHA | 19880815 | 19921228 | Full picture render to screen |
| `ToggleGraphics` | proc | RADAR.PAS | -- | 19880801 | 19880801 | Pascal only; removed in M2 |
| `SetMask(ToMask)` | proc | RADAR.PAS | -- | 19870412 | 19880801 | Pascal only; removed in M2 |
| `Window(...)` | proc | RADAR.PAS | WINDOWS | 1985xxxx | 19921228 | Became WINDOWS module in M2 |
| `EpsonMX80PrtSc` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Dot-matrix screen dump |
| `ColorJetPrtSc` / `PrtSc` | proc | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Color inkjet screen dump |

### 2.2 RS-232 / Serial Communication

| Symbol | Type | Pascal Origin | M2 Module | First Seen | Last Seen | Notes |
|--------|------|---------------|-----------|------------|-----------|-------|
| `RS232Interupt` | ISR | RADAR.PAS | -- | 1985xxxx | 19880801 | Pascal ISR; replaced by M2 RS module |
| `InitRS232` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | Pascal init; replaced by RS2.SetupRxInt |
| `ResetBuf` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | Pascal; replaced by RS buffer mgmt |
| `Tx(Charac)` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS `Tx` -> M2 `RS.TxChar` |
| `Rx(var Charac)` / `Rx(): char` | proc/func | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS `Rx` -> M2 `RS.RxChar` |
| `TxChar(C)` | proc | -- | RS / RS2 | 19880329 | 19921228 | M2 serial transmit |
| `RxChar(): CHAR` | func | -- | RS / RS2 | 19880329 | 19921228 | M2 serial receive |
| `RxReady(): BOOLEAN` | func | -- | RS / RS2 | 19880329 | 19921228 | Buffer status check |
| `TxEmpty(): BOOLEAN` | func | -- | RS / RS2 | 19880329 | 19921228 | Transmit buffer empty |
| `RxCount(): CARDINAL` | func | -- | RS / RS2 | 19880329 | 19921228 | Chars in receive buffer |
| `SetupRxInt(...)` | proc | -- | RS2 | 19880815 | 19921228 | Configure receive interrupt |
| `SetupTxInt(...)` | proc | -- | RS2 | 19880815 | 19921228 | Configure transmit interrupt |
| `SendCom(Command, DelTime)` | proc | RADAR.PAS | E300INTE | 1985xxxx | 19921228 | PAS: inline; M2: via E300INTE protocol |

### 2.3 E300 Radar Interface (Modula-2 only)

| Symbol | Type | M2 Module | First Seen | Last Seen | Notes |
|--------|------|-----------|------------|-----------|-------|
| `GetParam(VAR Tilt, Range, Gain, Time, RT)` | proc | E300INTE | 19880815 | 19921228 | Read current radar state |
| `SetParam(Tilt, Range, Gain, VAR Time, RT)` | proc | E300INTE | 19880815 | 19921228 | Set radar parameters |
| `MakePic()` | proc | E300INTE | 19880815 | 19921228 | Initiate picture capture |
| `PicReady(): BOOLEAN` | func | E300INTE | 19880815 | 19921228 | Poll for picture completion |
| `GetLine(VAR LineNum, RedBitMap, GrnBitMap)` | proc | E300INTE | 19880815 | 19921228 | Retrieve one scan line |
| `AbortPic()` | proc | E300INTE | 19880815 | 19921228 | Cancel picture in progress |
| `CheckMaps(Map1): BOOLEAN` | func | E300INTE | 19880815 | 19921228 | Verify map version currency |
| `GetMaps(VAR Map1, Map2)` | proc | E300INTE | 19880815 | 19921228 | Download overlay maps |

### 2.4 Modem & Station Control

| Symbol | Type | Pascal Origin | M2 Module | First Seen | Last Seen | Notes |
|--------|------|---------------|-----------|------------|-----------|-------|
| `HangUp` | proc | RADAR.PAS | MODEM | 1985xxxx | 19921228 | DTR/RTS drop |
| `CallStation` | proc | RADAR.PAS | STATIONS | 1985xxxx | 19921228 | PAS: inline; M2: returns BOOLEAN |
| `SelectStation` | proc | RADAR.PAS | STATIONS | 1985xxxx | 19921228 | Station menu |
| `AddStation` | proc | RADAR.PAS (nested) | STATIONS | 19870412 | 19921228 | Was nested in SelectStation in PAS |
| `DelStation` | proc | RADAR.PAS (nested) | STATIONS | 19870412 | 19921228 | Was nested in SelectStation in PAS |
| `StationMenu(...)` | proc | -- | STATIONS | 19880815 | 19921228 | M2 unified station UI |
| `InitStationDir(...)` | proc | -- | STATIONS | 19880815 | 19921228 | Load station database |
| `Dial(PhoneNumber)` | proc | -- | MODEM | 19880815 | 19921228 | Hayes AT dial |
| `WaitResult(): ResultCode` | func | -- | MODEM | 19880815 | 19921228 | Parse modem response |
| `LoadStation` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS only; M2 uses InitStationDir |
| `SaveStation` | proc | RADAR.PAS | -- | 19870412 | 19880801 | PAS only |

### 2.5 File Storage & Picture Management

| Symbol | Type | Pascal Origin | M2 Module | First Seen | Last Seen | Notes |
|--------|------|---------------|-----------|------------|-----------|-------|
| `FetchPic` | proc | RADAR.PAS | PICTURES | 1985xxxx | 19921228 | Load picture from disk |
| `SavePic(Size)` | proc | RADAR.PAS | PICTURES | 1985xxxx | 19921228 | PAS `SavePic` -> M2 `SavePicture` |
| `SavePicture` | proc | -- | PICTURES | 19880815 | 19921228 | M2 version with station dir |
| `InsertPic(ForPic)` | proc | RADAR.PAS | PICTURES | 1985xxxx | 19921228 | PAS -> M2 `AddPicture` |
| `AddPicture` | proc | -- | PICTURES | 19880815 | 19921228 | M2: sorted insertion |
| `DeletePicture` | proc | RADAR.PAS | PICTURES | 1985xxxx | 19921228 | Remove + file delete |
| `SelectPicture` | proc | -- | PICTURES | 19880815 | 19921228 | Display selected picture |
| `ReserveMem` | proc | -- | PICTURES | 19880815 | 19921228 | Memory mgmt with LRU purge |
| `FileName` | proc | -- | PICTURES | 19880815 | 19921228 | Generate filename from PictureRec |
| `FileParam` | proc | -- | PICTURES | 19880815 | 19921228 | Parse filename to PictureRec |
| `WritePictureEntry` | proc | -- | PICTURES | 19880815 | 19921228 | Format one gallery line |
| `PictureMenu` | proc | -- | PICTURES | 19880815 | 19921228 | Full picture gallery UI |
| `Storage` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS gallery; replaced by PictureMenu |
| `SetDTA(var DTA)` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | DOS DTA; M2 uses FIO.ReadFirstEntry |
| `SetDir(Mask, Attr)` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | DOS dir enum; M2 uses FIO |
| `DirEntry(): LineType` | func | RADAR.PAS | -- | 1985xxxx | 19880801 | DOS dir entry; M2 uses FIO |
| `SetParams(var ForBuf, Params)` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS: parse buffer; M2: via E300INTE |
| `IOError(): boolean` | func | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS: inline I/O check; M2: FIO.IOresult |

### 2.6 Main Control Loop & State Machine

| Symbol | Type | Pascal Origin | M2 Module | First Seen | Last Seen | Notes |
|--------|------|---------------|-----------|------------|-----------|-------|
| `Initialize` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Startup sequence |
| `DeInit` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Shutdown cleanup |
| `Config` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | PAS inline; M2 OptionMenu |
| `OptionMenu` | proc | -- | MAIN | 19880815 | 19921228 | M2 replacement for Config |
| `ExecCom` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Dispatch key -> command |
| `ModemLoop` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Idle state loop |
| `InterLoop` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Connected mode loop |
| `RxPicLoop` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Picture receive loop |
| `RxGraphLoop` | proc | RADAR.PAS | MAIN | 1985xxxx | 19921228 | Map overlay receive loop |
| `DoAuto` | proc | -- | AUTO/MAIN | 19880815 | 19921228 | Timed auto-capture |
| `AutoMenu` | proc | -- | MAIN | 19880815 | 19921228 | Set auto interval |
| `ProgramMenu` | proc | -- | AUTO | 19880815 | 19921228 | Auto-capture settings |
| `ReadKbd` | proc | RADAR.PAS | EXTENDKE | 1985xxxx | 19921228 | Keyboard input |
| `ReadStr(Len): LineType` | func | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS; M2 uses IO.RdStr |
| `WriteTime` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS; M2 uses TIMEDATE |
| `GotoXY(X,Y)` | proc | RADAR.PAS | -- | 1985xxxx | 19880801 | PAS cursor; M2 uses SCREENHA |
| `Ask(ForStr): boolean` | func | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Yes/No prompt |

### 2.7 Analysis & Storm Tracking (Late additions)

| Symbol | Type | M2 Module | First Seen | Last Seen | Notes |
|--------|------|-----------|------------|-----------|-------|
| `DefineArea` | proc | ANALYSIS | 19921023 | 19921228 | Define storm cell search area |
| `Analyze` | proc | ANALYSIS | 19921023 | 19921228 | Run storm cell recognition |
| `LastMarker` | proc | ANALYSIS | 19921023 | 19921228 | Track marker position |
| `Trail` | proc | ANALYSIS | 19921023 | 19921228 | Compute storm trajectory |
| `DrawMarkers` | proc | ANALYSIS | 19921023 | 19921228 | Render markers on display |

### 2.8 CRC & Compression

| Symbol | Type | M2 Module | First Seen | Last Seen | Notes |
|--------|------|-----------|------------|-----------|-------|
| `CalcCRC(BufAdr, BufSize): CARDINAL` | func | CRC | 19880815 | 19921228 | Block CRC calculation |
| `AddCRC(VAR crc, ch)` | proc | CRC | 19880815 | 19921228 | Incremental CRC update |
| `Compress(...)` | proc | MEMCOMPR | 19880815 | 19921228 | RLE compression |
| `Decompress(...)` | proc | MEMCOMPR | 19880815 | 19921228 | RLE decompression |

### 2.9 Sweep Engine (Assembly, 1989)

| Symbol | Type | File | First Seen | Last Seen | Notes |
|--------|------|------|------------|-----------|-------|
| `SWEEP` | ASM | SWEEP.ASM | 19890319 | 19890326 | Initial PPI sweep renderer |
| `SWEEP2` | ASM | SWEEP2.ASM | 19890326 | 19890326 | Optimized sweep (DGL, July 1987) |
| `SWEEP3-5` | ASM | SWEEP3-5.ASM | 19890326 | 19890326 | Iterative optimizations |
| `ALTSWP` | ASM | ALTSWP.ASM | 19890326 | 19890326 | Alternative sweep algorithm |
| `SWPLNE` | ASM | SWPLNE.ASM | 19890326 | 19890326 | Line-by-line sweep draw |
| `INCTABX` | ASM | INCTABX.ASM | 19890326 | 19890326 | Bresenham X increment table |
| `INCTABY` | ASM | INCTABY.ASM | 19890326 | 19890326 | Bresenham Y increment table |
| `GENTAB` | PAS | GENTAB.PAS | 19890326 | 19890326 | Table generator (Hex, MakeXTable, MakeYTable) |

### 2.10 Library Layer (M2 Runtime)

| Symbol | Type | M2 Module | Procedures | Notes |
|--------|------|-----------|------------|-------|
| `LIB` | lib | LIB | `Move`, `Fill`, `WordFill`, `WordMove`, `AddAddr`, `SubAddr`, `IncAddr`, `DecAddr`, `Dos`, `Intr`, `QSort`, `HSort`, `RANDOM`, `RAND`, `Execute`, `Sound`, `Delay`, `Environment`, `ParamCount`, `ParamStr`, `HashString`, `FatalError`, `Terminate`, `SetReturnCode`, `SetJmp`, `LongJmp`, `ScanR`, `ScanL`, `ScanNeR`, `ScanNeL`, `Compare`, `MathError`, `MathError2` | 35 procedures |
| `FIO` | lib | FIO | `Open`, `Create`, `Append`, `Close`, `IOresult`, `Size`, `GetPos`, `Seek`, `Truncate`, `RdChar`, `RdBool`, `RdShtInt`, `RdInt`, `RdLngInt`, `RdShtCard`, `RdCard`, `RdLngCard`, `RdShtHex`, `RdHex`, `RdLngHex`, `RdBin`, `WrChar`, `WrBool`, `WrShtInt`, `WrInt`, `WrLngInt`, `WrShtCard`, `WrCard`, `WrLngCard`, `WrShtHex`, `WrHex`, `WrLngHex`, `WrReal`, `WrLngReal`, `WrStr`, `WrStrAdj`, `WrLn`, `WrCharRep`, `WrBin`, `AssignBuffer`, `ChDir`, `MkDir`, `RmDir`, `GetDir`, `ReadFirstEntry`, `ReadNextEntry`, `Exists`, `Erase`, `Rename` | 50+ procedures |
| `IO` | lib | IO | `RdStr`, `WrStr`, `RdChar`, `WrChar`, `RdInt`, `WrInt`, `RdCard`, `WrCard`, `RdLn`, `WrLn` | Console I/O |
| `STR` | lib | STR | `StrLen`, `StrCpy`, `StrConcat`, `StrComp`, case conversion, `CHARSET` type | String ops |
| `TIMEDATE` | lib | TIMEDATE | `GetTime`, `SetTime`, `GetDate`, `SetDate` | Clock access |
| `ASCII` | lib | ASCII | Constants: `nul`, `soh`..`us`, `del`, `EOL` | No procedures |
| `PROCESS` | lib | PROCESS | Coroutine/process management | Logitech RTS |
| `STORAGE` | lib | STORAGE | `ALLOCATE`, `DEALLOCATE`, `Available` | Heap management |

---

## 3. Data Type Lineage

### 3.1 Core Radar Types

| Type | Kind | Pascal | M2 Module | First Seen | Last Seen | Definition |
|------|------|--------|-----------|------------|-----------|------------|
| `TiltType` | subrange | `0..11` | E300INTE | 1985xxxx | 19921228 | 12 tilt positions (0-20 degrees) |
| `RangeType` | subrange | `0..4` | E300INTE | 1985xxxx | 19921228 | 5 range settings (10-200nm) |
| `GainType` | subrange | `1..17` | E300INTE | 1985xxxx | 19921228 | 17 gain levels |
| `ModeType` | enum | `(Modem,Interactive,WaitPic,RxPic,RxGraph)` | MAIN | 1985xxxx | 19921228 | M2 drops WaitPic |
| `RTState` | enum | -- | E300INTE | 19880815 | 19921228 | `(NoRT, RTOn, RTOff, RTFault)` |
| `ResultCode` | enum | -- | MODEM | 19880815 | 19921228 | Modem response codes |
| `PicFlag` | enum | -- | PICTURES | 19880815 | 19921228 | `(NotSaved, ...)` |

### 3.2 Record Types

| Type | Pascal | M2 Module | First Seen | Last Seen | Fields |
|------|--------|-----------|------------|-----------|--------|
| `TimeRec` | RADAR.PAS | -- | 1985xxxx | 19880801 | `Hour, Minute, Month, Day, Year` |
| `Time` | -- | TIMEDATE | 19880329 | 19921228 | `day, minute` (M2 compressed form) |
| `PicRec` | RADAR.PAS | -- | 1985xxxx | 19880801 | `FileName, FileDate, FileTime, Time, Tilt, Range, Gain` |
| `PictureRec` | -- | PICTURES | 19880815 | 19921228 | `TimeofPic, Tilt, Range, Gain, Data, Size, Flags, Purge` |
| `RadarParams` | RADAR.PAS | -- | 19870412 | 19880801 | `Station, Time, Range, Tilt, Gain, RT` |
| `LandMarkRec` | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | `Bear, Range, Name[1..3], Nothing` |
| `SegmentRec` | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | `Range1, Bear1, Range2, Bear2` |
| `StationRec` | RADAR.PAS | STATIONS | 19870412 | 19921228 | PAS: fixed array; M2: linked list with `Next: StationPtr` |
| `Options` | -- | MAIN | 19880815 | 19921228 | `Baud, ComPort, Update, ArmyTime, Maps, Banner` |
| `MapEntry` | -- | E300INTE | 19880815 | 19921228 | Variant record for map identification |
| `RegisterType` | RADAR.PAS | -- | 1985xxxx | 19880801 | DOS register set (variant record) |
| `DirEntry` | -- | FIO | 19880815 | 19921228 | DOS directory entry |

### 3.3 Array & Buffer Types

| Type | Pascal | M2 | First Seen | Last Seen | Definition |
|------|--------|----|------------|-----------|------------|
| `Picture[1..100]` | RADAR.PAS | STATIONS | 1985xxxx | 19921228 | Per-station picture array |
| `Landmark[0..99]` | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Map landmarks |
| `Segment[0..999]` | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Map line segments |
| `LineBuffer[0..159]` | RADAR.PAS | SCREENHA | 1985xxxx | 19921228 | Radar picture scan line (160 bytes) |
| `BufType[1..2000]` | RADAR.PAS | -- | 1985xxxx | 19880801 | Serial receive buffer |
| `Map[0..1023]` | -- | E300INTE | 19880815 | 19921228 | Overlay map (1024 entries) |
| `PaletteType[0..15]` | -- | GRAPHICS | 19880815 | 19921228 | EGA 16-color palette |
| `BufType[0..54000]` | -- | DB | 19921223 | 19921228 | 54KB database buffer |

### 3.4 Graphics Types (M2 only)

| Type | Kind | Module | Definition |
|------|------|--------|------------|
| `FuncType` | enum | GRAPHICS | `(clr, and, or, xor)` — raster operations |
| `RotateRange` | subrange | GRAPHICS | `[0..7]` — bit rotation for patterns |
| `PlaneSet` | set | GRAPHICS | `BITSET` of VGA planes |
| `PicFlagSet` | set | PICTURES | `SET OF PicFlag` |
| `CHARSET` | set | STR | `SET OF CHAR` |

### 3.5 Pointer & Procedure Types (M2 only)

| Type | Module | Definition |
|------|--------|------------|
| `StationPtr` | STATIONS | `POINTER TO StationRec` |
| `ADDRESS` | SYSTEM | Generic memory pointer |
| `CompareProc` | LIB | Sort comparator function type |
| `SwapProc` | LIB | Sort swap function type |
| `CommmandType` | LIB | Command string type |
| `LongLabel` | LIB | `SetJmp`/`LongJmp` label |
| `CP` | LOWLEVEL | `POINTER TO CHAR` |
| `CODE` | LOWLEVEL | `ARRAY[0..60] OF SHORTCARD` (asm buffer) |

---

## 4. Constants Lineage

### 4.1 Radar Commands (Stable across all versions)

| Constant | Value | Pascal | M2 | Notes |
|----------|-------|--------|----|-------|
| `OnOff` | `#1` / `CHR(1)` | RADAR.PAS | E300INTE | Power toggle |
| `TiltUp` | `#2` | RADAR.PAS | E300INTE | Increase tilt |
| `RangeUp` | `#3` | RADAR.PAS | E300INTE | Increase range |
| `SendPic` | `#4` | RADAR.PAS | E300INTE | Request picture |
| `TiltDown` | `#5` | RADAR.PAS | E300INTE | Decrease tilt |
| `RangeDown` | `#6` | RADAR.PAS | E300INTE | Decrease range |
| `SendGraph` | `#10` | RADAR.PAS | E300INTE | Request map overlay |
| `GainUp` | `#13` | RADAR.PAS | E300INTE | Increase gain |
| `GainDown` | `#14` | RADAR.PAS | E300INTE | Decrease gain |
| `CheckGraph` | `#16` | RADAR.PAS | E300INTE | Check map version |

### 4.2 Display Constants

| Constant | Value | Notes |
|----------|-------|-------|
| Screen width | 640 | EGA horizontal pixels |
| Screen height | 350 | EGA vertical pixels |
| VGA planes | 4 | Red=0, Green=1, Cyan=2, Status=3 |
| Max landmarks | 100 | Per map zone |
| Max segments | 1000 | Per map zone |
| Max pictures | 100 | Per station |

### 4.3 Lookup Tables

| Table | Type | Definition | Notes |
|-------|------|------------|-------|
| `TiltVal` | `array[TiltType] of byte` | `(0,1,2,3,4,5,6,8,10,12,15,20)` | Tilt index -> degrees |
| `RangeVal` | `array[RangeType] of byte` | `(10,25,50,100,200)` | Range index -> nautical miles |
| `BaudVal` | array | `(300,1200,2400,9600,19200)` | Baud rate options |

---

## 5. Migration Map: Pascal -> Modula-2

The great transition happened November 1987 (`19871102 Pas2Mod2`). Here is how the monolithic RADAR.PAS decomposed:

```
RADAR.PAS (1,895 lines, one file)
    │
    ├──> MAIN.MOD .............. ExecCom, ModemLoop, InterLoop, RxPicLoop, RxGraphLoop
    ├──> SCREENHA.MOD .......... DispLine, ConOut, GRWrite, DrawScale, WriteParams, WritePic
    ├──> PICTURES.MOD .......... SavePicture, SelectPicture, PictureMenu, FileName, FileParam
    ├──> STATIONS.MOD .......... CallStation, SelectStation, AddStation, DelStation, StationMenu
    ├──> MODEM.MOD ............. HangUp, Dial, WaitResult
    ├──> E300INTE.MOD .......... GetParam, SetParam, MakePic, GetLine (was SendCom/SetParams)
    ├──> GRAPHICS.MOD .......... InitEGA, SelectPlane, SelectFunc, GRPlot, GRLine
    ├──> LOCATOR.MOD ........... MoveCursor, CalcBearing, CalcRange (was GotoXY + inline)
    ├──> RS.MOD / RS2.MOD ...... TxChar, RxChar, RxReady (was Tx, Rx, RS232Interupt)
    ├──> AUTO.MOD .............. DoAuto, ProgramMenu (new in M2)
    ├──> SELECTOR.MOD .......... Select (generic menu; was inline in PAS)
    ├──> EXTENDKE.MOD .......... ReadExtKey (was ReadKbd)
    ├──> OPTIONS.MOD ........... LoadOptions, SaveOptions (was Config)
    ├──> WINDOWS.MOD ........... OpenWindow, CloseWindow (was Window)
    ├──> CRC.MOD ............... CalcCRC, AddCRC (new in M2)
    └──> MEMCOMPR.MOD .......... Compress, Decompress (new in M2)
```

### Renamed Symbols at Migration

| Pascal Name | Modula-2 Name | Module | Reason |
|-------------|---------------|--------|--------|
| `Tx` | `TxChar` | RS | Naming convention |
| `Rx` | `RxChar` | RS | Naming convention |
| `RS232Interupt` | `SetupRxInt` | RS2 | ISR replaced by configurable interrupt |
| `SavePic` | `SavePicture` | PICTURES | More descriptive |
| `InsertPic` | `AddPicture` | PICTURES | More descriptive |
| `Storage` | `PictureMenu` | PICTURES | Clarified purpose |
| `Config` | `OptionMenu` | MAIN | More descriptive |
| `ShowPlane` | `EnablePlane` | GRAPHICS | Clarified semantics |
| `ReadKbd` | `ReadExtKey` | EXTENDKE | Extracted to module |
| `GotoXY` | (SCREENHA cursor) | SCREENHA | Absorbed into screen handler |
| `SetDTA/SetDir/DirEntry` | `FIO.ReadFirstEntry/ReadNextEntry` | FIO | Library replacement |

---

## 6. Snapshot Timeline

| Date | Snapshot | Language | Key Symbol Changes |
|------|----------|----------|--------------------|
| 1985xxxx | E300PC Demo | TP 3.0 | **Genesis**: all core routines in single RADAR.PAS |
| 19870412 | Radiotx | TP | Split: RADAR + RADIO + RADIORX/TX + CUSTOM |
| 19870416 | RadioTx Enhanced | TP | CUSTOM.PAS added for site-specific config |
| 19870512 | Tennterm | TP | Tennessee deployment variant; TEMP.PAS scratch |
| 19871102 | **Pas2Mod2** | TP+M2 | **THE PIVOT**: RADAR.MOD + RADAR2.MOD alongside original .PAS |
| 19880114 | RADAR.PAS | TP | Final Pascal monolith (1,895 lines) |
| 19880226 | SN8801 | TP | Production release with .RDR includes, GRAPH.BIN |
| 19880329 | Tenn | M2 | M2 modules: ENVIRONM, MODEM, RS232, SCREEN, STORAGE |
| 19880519 | Rad1dot1 | M2 | Patch release |
| 19880801 | RADIO | TP | **Final Pascal variant** with 4 .RDR includes |
| 19880815 | **RADAR MOD** | M2 | **Full M2 release**: 24 .MOD + 27 .DEF. All major modules established |
| 19890101 | 2dot1 | TP | Version 2.1 label; 17 .PAS files (R87xx includes) |
| 19890316 | RS811A | M2 | Experimental ARINC 429/453 interface (one-off) |
| 19890319 | Release | M2 | E300 interface abstraction complete |
| 19890326 | **Radar Sweep** | ASM | 12 x86 assembly files for PPI sweep rendering |
| 19910104 | Cdscrn | M2 | **Compiler change**: Logitech -> TopSpeed Modula-2 |
| 19910309 | E250Term | M2 | E250 Doppler radar; E250SCRN, E250DRAW, E250EDIT, SCRNSEND |
| 19921021 | Testchan | M2 | Test channel module |
| 19921022 | RADIO | M2 | Radio variant |
| 19921023 | AUTO | M2 | ANALYSIS module added (storm cell detection) |
| 19921104 | AUTO | M2 | 31 .MOD + 34 .DEF; CONVERT, TESTRX added |
| 19921223 | RADAR MOD | M2 | DEF/ MOD/ subdirectory reorganization; DB.MOD, CREATDAT, MAINRX added |
| 19921228 | **E300PC 3.1** | M2 | **Final release**: E300PC 3.1SCA with full module suite |

---

## 7. Symbol Census

| Category | Pascal-only | Migrated PAS->M2 | M2-only | ASM | Total |
|----------|-------------|-------------------|---------|-----|-------|
| Graphics & Display | 3 | 18 | 22 | 7 | 50 |
| Serial/Comms | 5 | 3 | 6 | 0 | 14 |
| E300 Interface | 0 | 2 | 8 | 0 | 10 |
| Modem/Station | 2 | 4 | 4 | 0 | 10 |
| File/Picture Mgmt | 5 | 4 | 8 | 0 | 17 |
| Control Loop | 2 | 6 | 4 | 0 | 12 |
| Analysis | 0 | 0 | 5 | 0 | 5 |
| CRC/Compression | 0 | 0 | 4 | 0 | 4 |
| Library (LIB+FIO+IO+STR) | 0 | 0 | 95+ | 0 | 95+ |
| **Total** | **17** | **37** | **156+** | **7** | **217+** |

---

---

## 8. EGALIB & Math Library (egalib-math/)

The `egalib-math/` directory contains Derek's standalone EGA graphics library and mathematical visualization programs — a shared toolkit that predates and underpins the RADARPAS graphics layer. Many symbols in the RADARPAS GRAPHICS module trace their lineage here.

### 8.1 Architectural Layers

```
 Layer 3: Applications
    CLOCK.MOD ─── Animated analog clock with second/minute/hour hands
    MANDEL.MOD ── Mandelbrot set visualization
    FRACGEN.MOD ─ Fractal tile generation to binary files
    FRACPLOT.MOD  Fractal tile display with dithering
    JULIAB.MOD ── Julia set (8-fold branching tree algorithm)
    AUTOMATA.MOD  1D cellular automaton with entropy tracking
    2DAUTO.MOD ── 2D cellular automaton
        │
 Layer 2: EGALIB Toolkit
    EGALIB.DEF ── Base: SetHiRes, SetPlane, EnablePlane, SetFunc, SetPalette
    EGALIB2.DEF ─ Extended: FillArea, Line, Window, ScrollUp, GotoXY, Write, Read
    FIGURES.DEF ─ Geometry: Point, AtPoint, Line, Ellipse, Arc
    FONTS.DEF ─── Text: SetFont, SetBold, SetItalic, SetUnderline, Write
    AREA.DEF ──── Area ops: FillArea, MoveArea
    PICSTORE.DEF  Storage: GetPicture, PutPicture (RLE compressed)
    SELECTOR.DEF  Menu: Select (callback-driven)
    WINDOWS.DEF ─ Windowing: OpenWindow, CloseWindow
        │
 Layer 1: TopSpeed M2 Runtime (LIB, FIO, IO, MATHLIB, SYSTEM)
```

### 8.2 EGALIB Core Library (19871123)

| Symbol | Type | Module | Signature | Notes |
|--------|------|--------|-----------|-------|
| `SetHiRes` | proc | EGALIB | `procedure SetHiRes()` | EGA 640x350 mode |
| `SetPalette` | proc | EGALIB | `procedure SetPalette(ToPalette: PaletteType)` | 16-color palette |
| `SetPlane` | proc | EGALIB | `procedure SetPlane(ToPlanes: PlaneSet)` | Write plane select |
| `EnablePlane` | proc | EGALIB | `procedure EnablePlane(ForPlanes: PlaneSet)` | Display plane select |
| `SetFunc` | proc | EGALIB | `procedure SetFunc(ToFunc: FuncType; Rotate: RotateRange)` | ROP mode + rotation |
| `FillArea` | proc | EGALIB2 | `procedure FillArea(X1,Y1,X2,Y2: INTEGER; Value: BYTE)` | Rectangle fill |
| `FillAreaFunc` | proc | EGALIB2 | `procedure FillAreaFunc(X1,Y1,X2,Y2: INTEGER; Value: BYTE; Func: BYTE)` | Fill with custom ROP |
| `Line` | proc | EGALIB2 | `procedure Line(X1,Y1,X2,Y2: INTEGER)` | Line draw |
| `Window` | proc | EGALIB2 | `procedure Window(XPos,YPos,XSize,YSize: INTEGER)` | Set clipping window |
| `ScrollUp` | proc | EGALIB2 | `procedure ScrollUp()` | Scroll window up |
| `ScrollDown` | proc | EGALIB2 | `procedure ScrollDown()` | Scroll window down |
| `GotoXY` | proc | EGALIB2 | `procedure GotoXY(X,Y: INTEGER)` | Cursor position |
| `Write` | proc | EGALIB2 | `procedure Write(ForChar: CHAR)` | Character output |
| `Read` | proc | EGALIB2 | `procedure Read(VAR ForChar: CHAR)` | Keyboard input |

### 8.3 FIGURES Module (Geometric Primitives)

| Symbol | Type | Signature | Notes |
|--------|------|-----------|-------|
| `Point` | proc | `procedure Point(X,Y: INTEGER)` | Plot pixel |
| `AtPoint` | func | `function AtPoint(X,Y: INTEGER): CARDINAL` | Read pixel color |
| `Line` | proc | `procedure Line(X1,Y1,X2,Y2: INTEGER)` | Bresenham line |
| `Ellipse` | proc | `procedure Ellipse(X,Y: INTEGER; Radius: CARDINAL; Aspect: REAL)` | Ellipse/circle |
| `Arc` | proc | `procedure Arc(X,Y: INTEGER; Radius: CARDINAL; Aspect: REAL; Start,End: REAL)` | Arc (unimplemented) |

### 8.4 FONTS Module (Text Rendering)

| Symbol | Type | Signature | Notes |
|--------|------|-----------|-------|
| `SetFont` | proc | `procedure SetFont(Size: CARDINAL)` | 8 or 14 pixel font |
| `SetBold` | proc | `procedure SetBold(OnOff: BOOLEAN)` | Toggle bold |
| `SetItalic` | proc | `procedure SetItalic(OnOff: BOOLEAN)` | Toggle italic |
| `SetUnderline` | proc | `procedure SetUnderline(OnOff: BOOLEAN)` | Toggle underline |
| `GotoRowCol` | proc | `procedure GotoRowCol(Row,Col: CARDINAL)` | Position by char grid |
| `GotoXY` | proc | `procedure GotoXY(X,Y: CARDINAL)` | Position by pixel |
| `Write` | proc | `procedure Write(ForChar: CHAR)` | Render formatted char |

### 8.5 Support Modules

| Module | Procedures | Purpose |
|--------|-----------|---------|
| **AREA** | `FillArea(X1,Y1,XSize,YSize,Value)`, `MoveArea(X1,Y1,XSize,YSize,ToX,ToY)` | Rectangle fill + blit with overlap handling |
| **PICSTORE** | `GetPicture(X1,Y1,XSize,YSize,Buffer)`, `PutPicture(X,Y,Buffer)` | RLE-compressed screen region save/restore |
| **SELECTOR** | `Select(WriteItem: WriteProc; MaxPos: CARDINAL; VAR Item: CARDINAL)` | Arrow-key menu selection with callback |
| **WINDOWS** | `OpenWindow(X1,Y1,XSize,YSize,FillColor,SaveData)`, `CloseWindow(SaveData)` | Popup window with background save |

### 8.6 EGALIB Types & Constants

| Type/Const | Kind | Definition | Module |
|------------|------|------------|--------|
| `PaletteType` | array | `ARRAY[0..15] OF BYTE` | EGALIB |
| `PlaneRange` | subrange | `[0..3]` | EGALIB |
| `PlaneSet` | set | `SET OF PlaneRange` | EGALIB |
| `FuncType` | enum | `(clr, and, or, xor)` | EGALIB |
| `RotateRange` | subrange | `[0..7]` | EGALIB |
| `clr` | const | `00H` | EGALIB2 |
| `and` | const | `08H` | EGALIB2 |
| `or` | const | `10H` | EGALIB2 |
| `xor` | const | `18H` | EGALIB2 |
| `WriteProc` | proc type | `PROCEDURE(CARDINAL)` | SELECTOR |
| `DataRec` | record | `Planes, XSize, YSize, PicData[0..64000]` | PICSTORE |

### 8.7 Mathematical Visualization Programs

#### FRACGEN / FRACPLOT (19911218)

| Symbol | Type | Module | Notes |
|--------|------|--------|-------|
| `COMPLEX` | record | FRACGEN | `R, I: LONGREAL` |
| `Square` | record | FRACGEN | `C1, C2: COMPLEX; FileName; Data[150x150]` |
| `Abs(x)` | func | FRACGEN | Complex absolute value |
| `Mult(x,y)` | func | FRACGEN | Complex multiplication |
| `CalcSquare(S)` | proc | FRACGEN | Mandelbrot tile calculation |
| `SaveSquare(S)` | proc | FRACGEN | Binary file output |
| `LoadSquare(S)` | proc | FRACGEN/FRACPLOT | Binary file input |
| `GenSquareFile(...)` | proc | FRACGEN | Generate and save tile |

#### JULIAB (19930221)

| Symbol | Type | Module | Notes |
|--------|------|--------|-------|
| `DrawPlot` | proc | JULIAB | Render Julia set via 8-fold branching |
| `ErasePlot` | proc | JULIAB | Clear previous render |
| `P = 9` | const | JULIAB | Recursion depth |

#### AUTOMATA (19930310)

| Symbol | Type | Module | Notes |
|--------|------|--------|-------|
| `States` | subrange | AUTOMATA | `[0..NumStates]` |
| `Rule` | array | AUTOMATA | `ARRAY Sum OF States` — lookup table |
| `Automaton` | record | AUTOMATA | `Cells[0..640], Rules` |
| `ShowYourself(Bob, Line)` | proc | AUTOMATA | Render one generation |
| `HaveaKid(Bob, BobJr)` | proc | AUTOMATA | Generate next generation |
| `SaveRule(Bob)` | proc | AUTOMATA | Persist rule to file |
| `ReadRandomRule(Bob)` | proc | AUTOMATA | Load or generate rule |
| `SE, TE, PopN` | var | AUTOMATA | Spatial/temporal entropy, population |

### 8.8 Connection to RADARPAS

The EGALIB library directly evolved into the RADARPAS GRAPHICS module:

| EGALIB Symbol | RADARPAS Equivalent | Notes |
|---------------|---------------------|-------|
| `EGALIB.SetHiRes` | `GRAPHICS.InitEGA` | Same INT 10h call |
| `EGALIB.SetPlane` | `GRAPHICS.SelectPlane` | Same port I/O |
| `EGALIB.EnablePlane` | `GRAPHICS.EnablePlane` | Identical |
| `EGALIB.SetFunc` | `GRAPHICS.SetFunc` | Same signature |
| `EGALIB.SetPalette` | `GRAPHICS.SetPalette` | Identical |
| `EGALIB2.Line` | `GRAPHICS.GRLine` | Renamed |
| `EGALIB2.FillArea` | `AREA.FillArea` | Reused directly |
| `EGALIB2.Window` | `GRAPHICS.SetWindow` | Renamed |
| `FIGURES.Point` | `GRAPH.Plot` | Renamed, added color param |
| `FIGURES.Ellipse` | `GRAPH.Ellipse` | Extended signature |
| `SELECTOR.Select` | `SELECTOR.Select` | Reused as-is |
| `WINDOWS.OpenWindow` | `WINDOWS.OpenWindow` | Reused as-is |
| `PICSTORE.GetPicture` | (not in RADARPAS) | Library-only |
| `FONTS.*` | (not in RADARPAS) | RADARPAS uses ConOut/GRWrite instead |

The AUTOMATA module (1993) is an early ancestor of EEVORG — cellular automata with entropy tracking, the same edge-of-chaos idea that would evolve into the `eevorg/` directory's genetic algorithm experiments.

---

## 9. Symbol Census (Updated)

| Category | Pascal-only | Migrated PAS->M2 | M2-only | ASM | EGALIB | Total |
|----------|-------------|-------------------|---------|-----|--------|-------|
| Graphics & Display | 3 | 18 | 22 | 7 | 26 | 76 |
| Serial/Comms | 5 | 3 | 6 | 0 | 0 | 14 |
| E300 Interface | 0 | 2 | 8 | 0 | 0 | 10 |
| Modem/Station | 2 | 4 | 4 | 0 | 0 | 10 |
| File/Picture Mgmt | 5 | 4 | 8 | 0 | 2 | 19 |
| Control Loop | 2 | 6 | 4 | 0 | 0 | 12 |
| Analysis | 0 | 0 | 5 | 0 | 0 | 5 |
| CRC/Compression | 0 | 0 | 4 | 0 | 0 | 4 |
| Math/Fractal | 0 | 0 | 0 | 0 | 12 | 12 |
| Cellular Automata | 0 | 0 | 0 | 0 | 8 | 8 |
| Library (LIB+FIO+IO+STR) | 0 | 0 | 95+ | 0 | 0 | 95+ |
| **Total** | **17** | **37** | **156+** | **7** | **48** | **265+** |

---

*Generated 2026-02-22. Source: 25 radar snapshots, 59 .PAS files, 173 .MOD files, 164 .DEF files, 12 .ASM files, plus egalib-math/ (12 .DEF, 26 .MOD, 4 .PAS, 1 .C).*
