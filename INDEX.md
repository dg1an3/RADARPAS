# RADARPAS Source Code Index

This index catalogs all data structures, procedures, and functions found in the Pascal and Modula-2 source files.

---

## Pascal Source Files

### Data Types

#### Core Types (19880114 RADAR.PAS, pascal/1988-08-01-RADIO/RADAR.PAS)

| Type | Definition | Description |
|------|------------|-------------|
| `TiltType` | `0..11` | Antenna tilt angle index |
| `RangeType` | `0..4` | Radar range setting index |
| `GainType` | `1..17` | Receiver gain setting |
| `LineType` | `string[80]` | Text line buffer |
| `Gen8Type` | `array[1..8] of byte` | 8-byte general buffer |
| `ModeType` | `(Modem,Interactive,WaitPic,RxPic,RxGraph)` | Operating mode enumeration |
| `BufType` | `array[1..2000] of byte` | Communication buffer |
| `TimeRec` | `record Year,Month,Day,Hour,Minute end` | Date/time record |
| `RegisterType` | `record AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags / AL,AH,BL,BH,CL,CH,DL,DH end` | CPU register overlay |
| `PicRec` | `record FileName,FileDate,FileTime,Time,Tilt,Range,Gain end` | Picture metadata record |

#### Graphics Types (GRAPH.RDR, GRAPH.P)

| Type | Definition | Description |
|------|------------|-------------|
| `CharTab14Type` | `array[0..127,0..13] of byte` | 14-line character table |
| `CharTab8Type` | `array[0..127,0..7] of byte` | 8-line character table |
| `PlaneSet` | `set of 0..3` | EGA plane selection |
| `FuncType` | `(Rot1..Rot7,_Clr,_And,_Or,_Xor)` | Graphics function type |
| `ListType` | `array[1..640] of byte` | Scanline buffer |

#### Map Types (19880114 RADAR.PAS)

| Type | Definition | Description |
|------|------------|-------------|
| `LandMarkRec` | `record Bear,Range,Name[1..3],Nothing end` | Landmark overlay record |
| `SegmentRec` | `record Range1,Bear1,Range2,Bear2 end` | Map segment record |

#### Radio Terminal Types (RADTERM.PAS)

| Type | Definition | Description |
|------|------------|-------------|
| `StringType` | `string[80]` | String buffer |
| `RadarParams` | `record Tilt,Range,Gain,Time end` | Radar parameter set |

#### EME Types (gdem/1985-EME/EME.PAS)

| Type | Definition | Description |
|------|------------|-------------|
| `String40` | `string[40]` | 40-character string |
| `SegmentRec` | `record Range1,Bear1,Range2,Bear2 end` | Map segment |
| `LandmarkRec` | `record Bear,Range,Name,Space end` | Landmark record |

---

### Pascal Procedures and Functions

#### Miscellaneous Routines

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `SetDTA` | RADAR.PAS:111, MISC.RDR:5 | `procedure SetDTA(var DTA)` | Set Disk Transfer Address |
| `SetDir` | RADAR.PAS:122, MISC.RDR:16 | `procedure SetDir(Mask:LineType;Attr:byte)` | Set directory search mask |
| `DirEntry` | RADAR.PAS:135, MISC.RDR:29 | `function DirEntry:LineType` | Get next directory entry |
| `ReadKbd` | RADAR.PAS:153, MISC.RDR:47 | `procedure ReadKbd` | Read keyboard input |
| `WriteTime` | RADAR.PAS:162, MISC.RDR:56 | `procedure WriteTime(Time:TimeRec)` | Display time |
| `IOError` | RADAR.PAS:807 | `function IOError:boolean` | Check I/O error status |

#### Graphics Routines

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `SelectPlane` | GRAPH.RDR:23 | `procedure SelectPlane(ForPlanes:PlaneSet)` | Select EGA plane for writing |
| `ShowPlane` | GRAPH.RDR:32 | `procedure ShowPlane(ForPlanes:PlaneSet)` | Enable plane visibility |
| `SelectFunc` | GRAPH.RDR:44 | `procedure SelectFunc(ForFunc:FuncType)` | Set graphics function |
| `SetMask` | GRAPH.RDR:53 | `procedure SetMask(ToMask:byte)` | Set bit mask |
| `GotoXY` | GRAPH.RDR:65 | `procedure GotoXY(X,Y:integer)` | Position cursor |
| `ConOut` | GRAPH.RDR:70 | `procedure ConOut(ForChar:char)` | Output character |
| `ReadStr` | GRAPH.RDR:95 | `function ReadStr(Len:byte):LineType` | Read string input |
| `GRWrite` | GRAPH.RDR:120 | `procedure GRWrite(ForStr:linetype;X,Y:integer)` | Write text in graphics mode |
| `GRPlot` | GRAPH.RDR:135 | `procedure GRPlot(X,Y:integer)` | Plot pixel |
| `GRLine` | GRAPH.RDR:148 | `procedure GRLine(X1,Y1,X2,Y2:integer)` | Draw line |
| `Window` | GRAPH.RDR:174 | `procedure Window(X,Y,XSize,YSize:byte)` | Create window |
| `GRMessage` | GRAPH.RDR:190 | `procedure GRMessage(ForStr:linetype;WaitKey:boolean)` | Display message |
| `Ask` | GRAPH.RDR:219 | `function Ask(ForStr:linetype):boolean` | Ask yes/no question |
| `ToggleGraphics` | GRAPH.RDR:225 | `procedure ToggleGraphics` | Toggle graphics/text mode |
| `DispLine` | GRAPH.RDR:234 | `procedure DispLine(var LinePtr)` | Display radar line |
| `DrawScale` | GRAPH.RDR:289 | `procedure DrawScale` | Draw range scale |
| `InitEGA` | GRAPH.RDR:304 | `procedure InitEGA` | Initialize EGA graphics |

#### Screen Routines

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `WriteRngMks` | SCREEN.RDR:57 | `procedure WriteRngMks` | Draw range markers |
| `WriteGfx` | SCREEN.RDR:134 | `procedure WriteGfx(var At)` | Write graphics overlay |
| `WriteHelp` | SCREEN.RDR:193 | `procedure WriteHelp` | Display help screen |
| `WriteParams` | SCREEN.RDR:242 | `procedure WriteParams` | Display radar parameters |
| `ClearScreen` | SCREEN.RDR:259 | `procedure ClearScreen` | Clear display |
| `UnWindow` | SCREEN.RDR:270 | `procedure UnWindow` | Remove window |

#### Communication Routines

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `HangUp` | RADAR.PAS:851 | `procedure HangUp` | Disconnect modem |
| `Tx` | RADAR.PAS:857 | `procedure Tx(Charac:char)` | Transmit character |
| `Rx` | RADAR.PAS:863 | `procedure Rx(var Charac:char)` | Receive character |
| `ResetBuf` | RADAR.PAS:874 | `procedure ResetBuf` | Reset communication buffer |
| `SendCom` | RADAR.PAS:879 | `procedure SendCom(Command:char;DelTime:integer)` | Send command |
| `RS232Interupt` | RADAR.PAS:946 | `procedure RS232Interupt` | RS-232 interrupt handler |
| `InitRS232` | RADAR.PAS:1055 | `procedure InitRS232` | Initialize RS-232 port |

#### Picture Management

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `SetParams` | RADAR.PAS:906 | `procedure SetParams(var ForBuf;var Params:PicRec)` | Set picture parameters |
| `FetchPic` | RADAR.PAS:1080 | `procedure FetchPic` | Fetch picture from radar |
| `InsertPic` | RADAR.PAS:1111 | `procedure InsertPic(ForPic:PicRec)` | Insert picture in list |
| `SavePic` | RADAR.PAS:1127 | `procedure SavePic(Size:integer)` | Save picture to disk |
| `Storage` | RADAR.PAS:1149 | `procedure Storage` | Storage management |

#### Station Management

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `LoadStation` | RADAR.PAS:1204 | `procedure LoadStation` | Load station data |
| `CallStation` | RADAR.PAS:1252 | `procedure CallStation` | Dial station |
| `SelectStation` | RADAR.PAS:1301 | `procedure SelectStation` | Select station |
| `AddStation` | RADAR.PAS:1303 | `procedure AddStation` | Add new station |
| `DelStation` | RADAR.PAS:1333 | `procedure DelStation` | Delete station |

#### Printing

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ColorJetPrtSc` | RADAR.PAS:1406 | `procedure ColorJetPrtSc` | Print to HP ColorJet |
| `EpsonMX80PrtSc` | RADAR.PAS:1451 | `procedure EpsonMX80PrtSc` | Print to Epson MX-80 |

#### Main Program Flow

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `Initialize` | RADAR.PAS:1491 | `procedure Initialize` | Program initialization |
| `DeInit` | RADAR.PAS:1528 | `procedure DeInit` | Program cleanup |
| `Config` | RADAR.PAS:1543 | `procedure Config` | Configuration menu |
| `ExecCom` | RADAR.PAS:1612 | `procedure ExecCom` | Execute command |
| `RxGraphLoop` | RADAR.PAS:1650 | `procedure RxGraphLoop` | Receive graphics loop |
| `RxPicLoop` | RADAR.PAS:1689 | `procedure RxPicLoop` | Receive picture loop |
| `InterLoop` | RADAR.PAS:1764 | `procedure InterLoop` | Interactive mode loop |
| `ModemLoop` | RADAR.PAS:1835 | `procedure ModemLoop` | Modem mode loop |

#### Radio TX/RX (RADIOTX.PAS, RADIORX.PAS)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `TxBlock_with_Check` | RADIOTX.PAS:3 | `procedure TxBlock_with_Check(var BlockAt;Size:INTEGER)` | Transmit block with CRC |
| `RadioTx` | RADIOTX.PAS:28 | `procedure RadioTx(FileName:STRING[80])` | Radio file transmit |
| `RxBlock_with_Check` | RADIORX.PAS:3 | `procedure RxBlock_with_Check(var BlockAt;Size:INTEGER;OK:BOOLEAN)` | Receive block with CRC |
| `RadioRx` | RADIORX.PAS:30 | `procedure RadioRx` | Radio file receive |

#### Image Processing (RADTEST.PAS)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `getarea` | RADTEST.PAS:898 | `procedure getarea` | Get image area |
| `getpix` | RADTEST.PAS:911 | `function getpix(x,y:integer):integer` | Get pixel value |
| `setpix` | RADTEST.PAS:929 | `procedure setpix(x,y:integer;V:integer)` | Set pixel value |
| `stretch` | RADTEST.PAS:940 | `procedure stretch(x,y,dx,dy:integer;xs,ys:real)` | Stretch image |

#### EME Editor (gdem/1985-EME/EME.PAS)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ReadString` | EME.PAS:30 | `procedure ReadString(var ToString:String40)` | Read string input |
| `WriteSegment` | EME.PAS:100 | `procedure WriteSegment(ForSegment:SegmentRec)` | Display segment |
| `WriteLandmark` | EME.PAS:123 | `procedure WriteLandmark(ForLandmark:LandmarkRec)` | Display landmark |
| `Disk` | EME.PAS:145 | `procedure Disk` | Disk operations |
| `EditLandmarks` | EME.PAS:160 | `procedure EditLandmarks` | Edit landmarks |
| `EditSegments` | EME.PAS:167 | `procedure EditSegments` | Edit segments |

#### Sweep Table Generation (GENTAB.PAS)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `Hex` | GENTAB.PAS:18 | `function Hex(Num:byte):string3` | Convert to hex string |
| `OutTable` | GENTAB.PAS:34 | `procedure OutTable` | Output lookup table |
| `MakeXTable` | GENTAB.PAS:52 | `procedure MakeXTable` | Generate X increment table |
| `MakeYTable` | GENTAB.PAS:76 | `procedure MakeYTable` | Generate Y increment table |

---

## Modula-2 Source Files

### Data Types

#### Pictures Module (PICTURES.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| `PictureRec` | `RECORD PicTime,Tilt,Range,Gain,Source,Valid,FileName,PicNum,BufferAt,BufferSize END` | Picture metadata |

#### Stations Module (STATIONS.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| `StationRec` | `RECORD Name,Phone,CallSign,Buffer,NextStation END` | Station record |
| `StationPtr` | `POINTER TO StationRec` | Station pointer |

#### Graphics Module (GRAPHICS.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| `ScreenModeType` | `(Text,Mono,Color)` | Display mode |
| `FuncType` | `(clr,And,Or,Xor)` | Graphics function |

#### RS-232 Module (RS2.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| Buffer types for serial communication |

#### Screen Handler (SCREENHA.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| Screen management types |

#### Time/Date Module (TIMEDATE.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| `Time` | Time/date record | System time structure |

#### CRC Module (CRC.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| CRC calculation types |

#### I/O Module (IO.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| Standard I/O types |

#### Graph Module (GRAPH.DEF)

| Type | Definition | Description |
|------|------------|-------------|
| Low-level graphics types |

#### Map Types (E250DRAW.MOD)

| Type | Definition | Description |
|------|------------|-------------|
| `MapEntry` | `RECORD Bear,Range,Ident OR Range1,Bear1,Range2,Bear2 END` | Map entry variant |
| `MapTable` | `ARRAY[0..1023] OF MapEntry` | Map table |
| `SinCosTable` | `ARRAY[0..359] OF INTEGER` | Trig lookup table |

#### Sweep Types (SWEEP.MOD)

| Type | Definition | Description |
|------|------------|-------------|
| `RadialTableEntry` | `ARRAY[0..2] OF SHORTCARD` | Radial decision entry |
| `RadialTable` | `ARRAY[0..31] OF RadialTableEntry` | Radial lookup |

#### Analysis Types (ANALYSIS.MOD)

| Type | Definition | Description |
|------|------------|-------------|
| `MarkerRec` | `RECORD X,Y,Picture END` | Analysis marker |

#### Radio TX Types (RADIOTX.MOD)

| Type | Definition | Description |
|------|------------|-------------|
| `DirUtilRec` | `RECORD BufferPtr,BufferSize,BufferPos,PrefixTab END` | Directory utility |
| `BigBuffer` | `ARRAY[0..31],[0..63] OF CHAR` | Large buffer |

---

### Modula-2 Procedures

#### Screen Handler (SCREENHA.MOD/DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `WriteTime` | SCREENHA.MOD:28 | `PROCEDURE WriteTime(ForTime:Time)` | Display time |
| `WriteDate` | SCREENHA.MOD:54 | `PROCEDURE WriteDate(ForTime:Time)` | Display date |
| `WriteTilt` | SCREENHA.MOD:69 | `PROCEDURE WriteTilt(Tilt:CARDINAL)` | Display tilt |
| `WriteRange` | SCREENHA.MOD:83 | `PROCEDURE WriteRange(Range:CARDINAL)` | Display range |
| `WriteGain` | SCREENHA.MOD:96 | `PROCEDURE WriteGain(Gain:CARDINAL)` | Display gain |
| `WriteParams` | SCREENHA.MOD:112 | `PROCEDURE WriteParams(Tilt,Range,Gain:CARDINAL;ForTime:Time)` | Display all params |
| `WriteRngMks` | SCREENHA.MOD:178 | `PROCEDURE WriteRngMks(On:BOOLEAN)` | Draw range markers |
| `WriteMap` | SCREENHA.MOD:200 | `PROCEDURE WriteMap(Num:CARDINAL;On:BOOLEAN)` | Draw map overlay |
| `SetHelpMode` | SCREENHA.MOD:272 | `PROCEDURE SetHelpMode(Mode:CARDINAL)` | Set help mode |
| `WriteHelp` | SCREENHA.MOD:277 | `PROCEDURE WriteHelp(On:BOOLEAN)` | Display help |
| `DrawScale` | SCREENHA.MOD:381 | `PROCEDURE DrawScale` | Draw scale |
| `ComprLine` | SCREENHA.MOD:403 | `PROCEDURE ComprLine(Number:CARDINAL;...)` | Compress line |
| `WritePic` | SCREENHA.MOD:518 | `PROCEDURE WritePic(VAR Buffer:ARRAY OF BYTE;BufSize:CARDINAL)` | Display picture |
| `ClearScreen` | SCREENHA.MOD:609 | `PROCEDURE ClearScreen` | Clear screen |
| `Redraw` | SCREENHA.MOD:616 | `PROCEDURE Redraw` | Redraw screen |
| `ToggleGraphics` | SCREENHA.MOD:638 | `PROCEDURE ToggleGraphics` | Toggle mode |
| `Message` | SCREENHA.MOD:651 | `PROCEDURE Message(String:ARRAY OF CHAR)` | Show message |
| `Prompt` | SCREENHA.MOD:676 | `PROCEDURE Prompt(String:ARRAY OF CHAR;VAR Response:ARRAY OF CHAR)` | Prompt user |
| `Pause` | SCREENHA.MOD:710 | `PROCEDURE Pause(String:ARRAY OF CHAR):CHAR` | Pause for key |

#### Pictures Module (PICTURES.MOD/DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `FileName` | PICTURES.MOD:50 | `PROCEDURE FileName(Picture:PictureRec;VAR Name:ARRAY OF CHAR)` | Get filename |
| `FileParam` | PICTURES.MOD:96 | `PROCEDURE FileParam(VAR Picture:PictureRec;Name:ARRAY OF CHAR)` | Parse filename |
| `SavePicture` | PICTURES.MOD:136 | `PROCEDURE SavePicture(VAR ForPicture:PictureRec;...)` | Save to disk |
| `ReserveMem` | PICTURES.MOD:176 | `PROCEDURE ReserveMem(VAR ForBuffer:ADDRESS;...)` | Allocate memory |
| `SelectPicture` | PICTURES.MOD:244 | `PROCEDURE SelectPicture(VAR ForPicture:PictureRec)` | Select picture |
| `AddPicture` | PICTURES.MOD:315 | `PROCEDURE AddPicture(VAR PicList:ARRAY OF PictureRec;...)` | Add to list |
| `DeletePicture` | PICTURES.MOD:403 | `PROCEDURE DeletePicture(VAR PicList:ARRAY OF PictureRec;...)` | Remove from list |
| `PictureMenu` | PICTURES.MOD:479 | `PROCEDURE PictureMenu(VAR PicList:ARRAY OF PictureRec;...)` | Picture menu |

#### Stations Module (STATIONS.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `CallStation` | STATIONS.MOD:63 | `PROCEDURE CallStation(VAR ForStation:StationRec):BOOLEAN` | Dial station |
| `SelectStation` | STATIONS.MOD:139 | `PROCEDURE SelectStation(VAR ForStation:StationRec)` | Select station |
| `AddStation` | STATIONS.MOD:199 | `PROCEDURE AddStation(VAR StationList:StationPtr;...)` | Add station |
| `DelStation` | STATIONS.MOD:265 | `PROCEDURE DelStation(VAR StationList:StationPtr;...)` | Delete station |
| `StationMenu` | STATIONS.MOD:373 | `PROCEDURE StationMenu(VAR StationList:StationPtr;...)` | Station menu |
| `InitStationDir` | STATIONS.MOD:484 | `PROCEDURE InitStationDir(VAR StationList:StationPtr;...)` | Init directory |

#### RS-232 Module (RS.MOD, RS2.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `TX` | RS.MOD:36 | `PROCEDURE TX` | Transmit handler |
| `RX` | RS.MOD:46 | `PROCEDURE RX` | Receive handler |
| `ReportBreak` | RS.MOD:64 | `PROCEDURE ReportBreak` | Report break |
| `Int` | RS.MOD:74 | `PROCEDURE Int` | Interrupt handler |
| `RxCount` | RS.MOD:124 | `PROCEDURE RxCount():CARDINAL` | Rx buffer count |
| `TxCount` | RS.MOD:129 | `PROCEDURE TxCount():CARDINAL` | Tx buffer count |
| `TxFree` | RS.MOD:134 | `PROCEDURE TxFree():CARDINAL` | Tx buffer free |
| `Break` | RS.MOD:141 | `PROCEDURE Break(Time:CARDINAL)` | Send break |
| `Init` | RS.MOD:149 | `PROCEDURE Init(Baud:CARDINAL;...)` | Initialize port |
| `Receive` | RS.MOD:177 | `PROCEDURE Receive(VAR Buf:ARRAY OF BYTE;Len:CARDINAL)` | Receive data |
| `Send` | RS.MOD:199 | `PROCEDURE Send(Buf:ARRAY OF BYTE;Len:CARDINAL)` | Send data |
| `CloseDown` | RS.MOD:212 | `PROCEDURE CloseDown` | Close port |
| `Install` | RS.MOD:254 | `PROCEDURE Install(Port:CARDINAL)` | Install driver |
| `BreakTest` | RS.MOD:263 | `PROCEDURE BreakTest():BOOLEAN` | Test for break |

#### Radio TX/RX (RADIOTX.MOD, RADIORX.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `SetNextPrefix` | RADIOTX.MOD:57 | `PROCEDURE SetNextPrefix(FileNum:CARDINAL)` | Set file prefix |
| `SetNextFile` | RADIOTX.MOD:81 | `PROCEDURE SetNextFile(VAR FileNum:CARDINAL)` | Set next file |
| `TransmitProc` | RADIOTX.MOD:105 | `PROCEDURE TransmitProc` | Transmit process |
| `Transmit` | RADIOTX.MOD:139 | `PROCEDURE Transmit` | Start transmission |
| `FileAt` | RADIOTX.MOD:160 | `PROCEDURE FileAt(ForFile:CARDINAL):LONGCARD` | Get file position |
| `SendPic` | RADIOTX.MOD:169 | `PROCEDURE SendPic(ForPic:PictureRec)` | Send picture |
| `SendText` | RADIOTX.MOD:185 | `PROCEDURE SendText(ForText:ARRAY OF CHAR)` | Send text |
| `ReceiveProc` | RADIORX.MOD:59 | `PROCEDURE ReceiveProc` | Receive process |
| `Receive` | RADIORX.MOD:132 | `PROCEDURE Receive` | Start reception |
| `ErrorCount` | RADIORX.MOD:166 | `PROCEDURE ErrorCount():CARDINAL` | Get error count |

#### Radar TX/RX (RADARTX.MOD, RADARRX.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `GenPrefixData` | RADARTX.MOD:11 | `PROCEDURE GenPrefixData(VAR ForPicture:ARRAY OF BYTE;...)` | Generate prefix |
| `SetPrefix` | RADARTX.MOD:18 | `PROCEDURE SetPrefix(At:LONGCARD;Info:ARRAY OF BYTE)` | Set prefix |
| `TransmitPic` | RADARTX.MOD:67 | `PROCEDURE TransmitPic(PicName:ARRAY OF CHAR;...)` | Transmit picture |
| `WritePic` | RADARRX.MOD:17 | `PROCEDURE WritePic(VAR StartAt:LONGCARD;...)` | Write picture |

#### Main Module (MAIN.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ExecCom` | MAIN.MOD:106 | `PROCEDURE ExecCom(Key:CHAR)` | Execute command |
| `DoAuto` | MAIN.MOD:133 | `PROCEDURE DoAuto` | Automatic mode |
| `InterLoop` | MAIN.MOD:301 | `PROCEDURE InterLoop` | Interactive loop |
| `AutoMenu` | MAIN.MOD:590 | `PROCEDURE AutoMenu` | Auto menu |
| `ModemLoop` | MAIN.MOD:594 | `PROCEDURE ModemLoop` | Modem loop |

#### Graphics Module (GRAPHICS.MOD/DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ScreenMode` | GRAPHICS.DEF:29 | `PROCEDURE ScreenMode(Mode:ScreenModeType)` | Set screen mode |
| `SetPalette` | GRAPHICS.DEF:36 | `PROCEDURE SetPalette(...)` | Set palette |
| `SetPlane` | GRAPHICS.DEF:40 | `PROCEDURE SetPlane(Planes:BITSET)` | Set plane |
| `GetPlane` | GRAPHICS.DEF:44 | `PROCEDURE GetPlane():BITSET` | Get plane |
| `EnablePlane` | GRAPHICS.DEF:48 | `PROCEDURE EnablePlane(...)` | Enable plane |
| `SetFunc` | GRAPHICS.DEF:56 | `PROCEDURE SetFunc(Func:FuncType;...)` | Set function |

#### Graph Module (GRAPH.DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `GraphMode` | GRAPH.DEF:12 | `PROCEDURE GraphMode` | Enter graphics |
| `TextMode` | GRAPH.DEF:14 | `PROCEDURE TextMode` | Enter text mode |
| `Plot` | GRAPH.DEF:16 | `PROCEDURE Plot(x,y,Color:CARDINAL)` | Plot pixel |
| `Point` | GRAPH.DEF:19 | `PROCEDURE Point(x,y:CARDINAL):CARDINAL` | Read pixel |
| `HLine` | GRAPH.DEF:22 | `PROCEDURE HLine(x,y,x2,FillColor:CARDINAL)` | Horizontal line |
| `Line` | GRAPH.DEF:29 | `PROCEDURE Line(x1,y1,x2,y2,Color:CARDINAL)` | Draw line |
| `Circle` | GRAPH.DEF:32 | `PROCEDURE Circle(x0,y0,r,c:CARDINAL)` | Draw circle |
| `Disc` | GRAPH.DEF:35 | `PROCEDURE Disc(x0,y0,r,FillColor:CARDINAL)` | Filled circle |
| `Ellipse` | GRAPH.DEF:38 | `PROCEDURE Ellipse(x0,y0,rx,ry,c:CARDINAL;Fill:BOOLEAN)` | Draw ellipse |
| `Polygon` | GRAPH.DEF:45 | `PROCEDURE Polygon(n:CARDINAL;px,py:ARRAY OF CARDINAL;FillColor:CARDINAL)` | Draw polygon |
| `InitCGA` | GRAPH.DEF:54 | `PROCEDURE InitCGA` | Initialize CGA |
| `InitEGA` | GRAPH.DEF:55 | `PROCEDURE InitEGA` | Initialize EGA |
| `InitVGA` | GRAPH.DEF:56 | `PROCEDURE InitVGA` | Initialize VGA |
| `InitHerc` | GRAPH.DEF:57 | `PROCEDURE InitHerc` | Initialize Hercules |

#### I/O Module (IO.DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `WrChar` | IO.DEF:13 | `PROCEDURE WrChar(V:CHAR)` | Write character |
| `WrBool` | IO.DEF:14 | `PROCEDURE WrBool(V:BOOLEAN;Length:INTEGER)` | Write boolean |
| `WrInt` | IO.DEF:16 | `PROCEDURE WrInt(V:INTEGER;Length:INTEGER)` | Write integer |
| `WrCard` | IO.DEF:19 | `PROCEDURE WrCard(V:CARDINAL;Length:INTEGER)` | Write cardinal |
| `WrReal` | IO.DEF:25 | `PROCEDURE WrReal(V:REAL;Precision,Length:INTEGER)` | Write real |
| `WrStr` | IO.DEF:30 | `PROCEDURE WrStr(S:ARRAY OF CHAR)` | Write string |
| `WrLn` | IO.DEF:34 | `PROCEDURE WrLn` | Write newline |
| `RdChar` | IO.DEF:37 | `PROCEDURE RdChar():CHAR` | Read character |
| `RdInt` | IO.DEF:40 | `PROCEDURE RdInt():INTEGER` | Read integer |
| `RdCard` | IO.DEF:43 | `PROCEDURE RdCard():CARDINAL` | Read cardinal |
| `RdStr` | IO.DEF:52 | `PROCEDURE RdStr(VAR S:ARRAY OF CHAR)` | Read string |
| `RdLn` | IO.DEF:55 | `PROCEDURE RdLn` | Read line |
| `KeyPressed` | IO.DEF:60 | `PROCEDURE KeyPressed():BOOLEAN` | Key pressed? |
| `RdKey` | IO.DEF:62 | `PROCEDURE RdKey():CHAR` | Read key |

#### CRC Module (CRC.DEF/MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `CalcCRC` | CRC.DEF:18 | `PROCEDURE CalcCRC(BufAdr:ADDRESS;BufSize:CARDINAL):CARDINAL` | Calculate CRC |
| `AddCRC` | CRC.DEF:21 | `PROCEDURE AddCRC(VAR crc:CARDINAL;ch:BYTE)` | Add byte to CRC |

#### Modem Module (MODEM.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ClearBuffer` | MODEM.MOD:16 | `PROCEDURE ClearBuffer` | Clear buffer |
| `Call` | MODEM.MOD:26 | `PROCEDURE Call` | Dial number |
| `HangUp` | MODEM.MOD:38 | `PROCEDURE HangUp` | Hang up |
| `ModemCommand` | MODEM.MOD:48 | `PROCEDURE ModemCommand` | Send command |

#### Sweep Module (SWEEP.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `CalcTable` | SWEEP.MOD:32 | `PROCEDURE CalcTable` | Calculate sweep table |
| `LoadTable` | SWEEP.MOD:111 | `PROCEDURE LoadTable` | Load sweep table |
| `DrawSweep` | SWEEP.MOD:126 | `PROCEDURE DrawSweep` | Draw radar sweep |

#### Analysis Module (ANALYSIS.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `DrawMarkers` | ANALYSIS.MOD:33 | `PROCEDURE DrawMarkers` | Draw analysis markers |
| `Analyze` | ANALYSIS.MOD:68 | `PROCEDURE Analyze` | Perform analysis |

#### E250 Terminal (E250Term/*.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `DrawMaps` | E250DRAW.MOD:91 | `PROCEDURE DrawMaps` | Draw map overlays |
| `DrawLocator` | E250DRAW.MOD:167 | `PROCEDURE DrawLocator` | Draw locator |
| `WriteRangeBear` | E250EDIT.MOD:45 | `PROCEDURE WriteRangeBear` | Display range/bearing |
| `WritePic` | E250TERM.MOD:55 | `PROCEDURE WritePic(VAR Buffer:ARRAY OF BYTE;...)` | Display picture |
| `Redraw` | E250TERM.MOD:126 | `PROCEDURE Redraw` | Redraw screen |
| `ShowPic` | E250TERM.MOD:156 | `PROCEDURE ShowPic(Rel:INTEGER)` | Show picture |
| `AddPic` | E250TERM.MOD:235 | `PROCEDURE AddPic(Name:ARRAY OF CHAR)` | Add picture |
| `ErasePic` | E250TERM.MOD:264 | `PROCEDURE ErasePic(Num:CARDINAL)` | Erase picture |
| `RxPic` | E250TERM.MOD:288 | `PROCEDURE RxPic` | Receive picture |
| `DialRadar` | E250TERM.MOD:358 | `PROCEDURE DialRadar` | Dial radar |
| `InitE250Term` | E250TERM.MOD:440 | `PROCEDURE InitE250Term` | Initialize terminal |
| `Options` | E250TERM.MOD:525 | `PROCEDURE Options` | Options menu |
| `SetPlane` | SCRNSEND.MOD:32 | `PROCEDURE SetPlane(ToPlanes:BITSET)` | Set plane |
| `Compr` | SCRNSEND.MOD:45 | `PROCEDURE Compr` | Compress data |
| `TxProcess` | SCRNSEND.MOD:101 | `PROCEDURE TxProcess` | Transmit process |

#### ARINC Interface (RS811A_I.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ARINC429Interrupt` | RS811A_I.MOD:77 | `PROCEDURE ARINC429Interrupt` | ARINC-429 handler |
| `ARINC453Interrupt` | RS811A_I.MOD:190 | `PROCEDURE ARINC453Interrupt` | ARINC-453 handler |

#### Process Module (PROCESS.DEF)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `StartScheduler` | PROCESS.DEF:7 | `PROCEDURE StartScheduler` | Start scheduler |
| `StopScheduler` | PROCESS.DEF:10 | `PROCEDURE StopScheduler` | Stop scheduler |
| `StartProcess` | PROCESS.DEF:13 | `PROCEDURE StartProcess(P:PROC;N,Pr:CARDINAL)` | Start process |
| `SEND` | PROCESS.DEF:17 | `PROCEDURE SEND(s:SIGNAL)` | Send signal |
| `WAIT` | PROCESS.DEF:20 | `PROCEDURE WAIT(s:SIGNAL)` | Wait for signal |
| `Notify` | PROCESS.DEF:23 | `PROCEDURE Notify(s:SIGNAL)` | Notify signal |
| `Awaited` | PROCESS.DEF:32 | `PROCEDURE Awaited(s:SIGNAL):BOOLEAN` | Is awaited? |
| `Init` | PROCESS.DEF:35 | `PROCEDURE Init(VAR s:SIGNAL)` | Init signal |
| `Delay` | PROCESS.DEF:39 | `PROCEDURE Delay(T:CARDINAL)` | Delay ms |
| `Lock` | PROCESS.DEF:42 | `PROCEDURE Lock` | Lock scheduler |
| `Unlock` | PROCESS.DEF:49 | `PROCEDURE Unlock` | Unlock scheduler |

#### Extended Keyboard (EXTENDKE.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ExtRead` | EXTENDKE.MOD:41 | `PROCEDURE ExtRead(VAR Code:CHAR;VAR Extended:BOOLEAN)` | Read extended key |

#### Compression (COMPR.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `ComprLine` | COMPR.MOD:6 | `PROCEDURE ComprLine(Number:CARDINAL;...)` | Compress line |
| `WritePic` | COMPR.MOD:118 | `PROCEDURE WritePic(VAR Buffer:ARRAY OF BYTE;BufSize:CARDINAL)` | Write picture |

#### Auto Module (AUTO.DEF/MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `DoAuto` | AUTO.DEF:4 | `PROCEDURE DoAuto` | Automatic operation |
| `ProgramMenu` | AUTO.DEF:7 | `PROCEDURE ProgramMenu` | Program menu |

#### Options (OPTIONS.MOD)

| Name | Location | Signature | Description |
|------|----------|-----------|-------------|
| `OptionMenu` | OPTIONS.MOD:3 | `PROCEDURE OptionMenu` | Options menu |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Pascal Types | ~25 |
| Pascal Procedures | ~85 |
| Pascal Functions | ~12 |
| Modula-2 Types | ~30 |
| Modula-2 Procedures | ~180 |
| **Total** | **~332** |

---

## Module Dependencies

```
MAIN
├── SCREENHA (Screen Handler)
│   ├── GRAPHICS (Low-level graphics)
│   └── GRAPH (Drawing primitives)
├── PICTURES (Picture management)
├── STATIONS (Station management)
├── RS / RS2 (Serial communication)
├── RADARTX / RADARRX (Radar data transfer)
├── RADIOTX / RADIORX (Radio link)
├── CRC (Error checking)
├── MODEM (Modem control)
├── EXTENDKE (Extended keyboard)
├── TIMEDATE (Time/date functions)
├── IO (Standard I/O)
└── PROCESS (Multi-tasking)
```
