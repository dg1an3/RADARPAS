# RADAR Source File Lineage

A chronological trace of every source file, backup, artifact, and support file under `radar/`, spanning 1985–1992 with a 2026 FreePascal revival.

---

## Phase 1: Turbo Pascal Monolith (1985–1987)

### 1985xxxx E300PC Demo

The earliest surviving version. A single-file Turbo Pascal program.

| File | Size | Description |
|---|---|---|
| `RADAR.PAS` | ~1,678 lines | `Program E300_Radar_Terminal; {version 1.0}`. Copyright (C) 1985 Derek Lane. 1200 baud RS-232, EGA graphics via direct port I/O, interrupt-driven serial handler, map overlay rendering, demo loop with canned radar data. |
| `RADAR.BAK.pas` | 54,156 bytes | Backup of RADAR.PAS. Same program with slightly different editor state. Renamed from `.BAK` to `.BAK.pas` for repo inclusion. Contains `{$C+,V-,I-}` compiler directives. |

### 19870412 RADARPAS Radiotx

Upgraded to 2400 baud. Radio TX/RX split into separate files.

| File | Description |
|---|---|
| `RADAR.PAS` | Main program, updated for 2400 baud |
| `RADAR2.PAS` | Secondary radar routines |
| `RADIO.PAS` | Radio subsystem |
| `RADIORX.PAS` | Radio receive module |
| `RADIOTX.PAS` | Radio transmit module |
| `CUSTOM.PAS` | Per-site customization stub |

### 19870416 RADARPAS RadioTx Enhanced

First preserved compiled binary.

| File | Size | Description |
|---|---|---|
| `RADAR.PAS` | — | Main program |
| `RADAR.BAK` | 33,964 bytes | Backup of prior RADAR.PAS revision. Pascal source with `{$C-,V-,I-,R-,U-,K-}` directives, `ModeType = (Modem, Interactive, WaitPic, RxPic, RxGraph)`, `TimeRec` with Year 1980..2099. CR+LF line endings (DOS). |
| `RADAR.COM` | 36,177 bytes | Compiled Turbo Pascal binary — first preserved executable. |
| `RADIORX.PAS` | — | Radio receive |
| `RADIOTX.PAS` | — | Radio transmit |
| `CUSTOM.PAS` | — | Site customization |

### 19870506 RADAR Marion Bin

Binary-only deployment for "Marion" site. Source not preserved.

| File | Description |
|---|---|
| `AUTOEXEC.BAT` | DOS startup script — only surviving file from this deployment |

### 19870512 RADARPAS Tennterm

Deployed to a Tennessee terminal site.

| File | Description |
|---|---|
| `RADAR.PAS` | Main program, same copyright header as 1985 version |
| `RADIORX.PAS` | Radio receive |
| `RADIOTX.PAS` | Radio transmit |
| `TEMP.PAS` | Scratch/temporary file |

---

## Phase 2: Pascal-to-Modula-2 Transition (November 1987)

### 19871102 RADAR MOD Pas2Mod2

**The pivot point.** Both languages exist side-by-side. The Logitech Modula-2/86 compiler was used for the initial port.

#### Source Files

| File | Description |
|---|---|
| `RADAR.PAS` | Pascal original, kept as reference |
| `RADAR.MOD` | Modula-2 port: `MODULE RadarVersion2point0`. Header: "Created 1/3/87, Last Edit 9/30/87, Author: Derek Lane, System: Logitech Modula-2/86" |
| `RADAR2.MOD` | Secondary radar routines (Modula-2) |
| `RADARTER.MOD` | Radar terminal module |
| Various `.DEF` files | Interface definitions for M2 modules |

#### Assembly Files (Logitech Runtime — NOT authored by DGL)

All Copyright (C) 1984, 1985 Logitech SA, CH-1143 Apples, Switzerland. Release 1.20.

| File | Description |
|---|---|
| `DBUG.ASM` | Run-Time Support (RTS) — post-mortem dump and runtime debugger interface. Nov 1985. |
| `LOADER.ASM` | RTS — loads Modula-2/86 `.LOD` files into memory. Oct 1985. |
| `RTS.ASM` | RTS — mainline runtime support: memory management, startup, error handling. Defines CGROUP/DGROUP/SGROUP segments. Nov 1985. |
| `SERVICES.ASM` | RTS — "Provides most of the functions to execute Modula-2/86 programs." CASE functions, set/get error code, ISR install/uninstall. Nov 1985. |
| `TRANSFER.ASM` | RTS — handles interrupts and processes. Implements NEWPROCESS (coroutine creation), TRANSFER/IOTRANSFER (context switching). Nov 1985. |

---

## Phase 3: Dual-Language Releases (1988)

### 19880114 RADAR.PAS

Single standalone file at root of this snapshot (1,895 lines). The last major Pascal-only snapshot. Contains the `{DID YOU JUST CHANGE SOMETHING? IF SO, CHANGE THE DATE!}` banner.

### 19880226 RADARPAS SN8801

First versioned production release. "SN8801" = Serial Number 8801 (first production unit, January 1988).

#### Source and Include Files

| File | Size | Description |
|---|---|---|
| `SCREEN.RDR` | 11,967 bytes | Pascal `{$I}` include file — "Screen Format Routines." Contains display state flags (`HelpOn`, `Gfx1On`, `Gfx2On`, `RngMksOn`) and five pre-computed `Circle` lookup tables (176 to 39 entries) for range ring drawing at different spacings. Includes `WriteRngMks` procedure. |
| `GRAPH.P` | 3,328 bytes | Turbo Pascal external declaration file. Declares `const North=0; East=90; South=180; West=270` and 20 routines (`GraphMode`, `Plot`, `Draw`, `Circle`, `Arc`, `GetPic`, `PutPic`, etc.) via `external Graphics[N]` offsets into GRAPH.BIN. |
| `GRAPH.BIN` | 5,134 bytes | DOS COM-format binary. Compiled Turbo Pascal graphics library — the runtime implementations of all routines declared in GRAPH.P. Jump table at start (series of `E9 xx xx` near-jumps). |

#### Text and Screen Template Files

| File | Size | Description |
|---|---|---|
| `COPYRITE.TXT` | tiny | Copyright notice: "ELLASON E300 RADAR TERMINAL, ver 2.0 / Revision 6/25/87 / Copyright (C) 1987 / D. G. Lane / All rights reserved" |
| `DIR.TXT` | large | Captured MS-DOS `DIR` output from `C:\RADAR2\SIU.STA`. Lists 95 `.PIC` files (radar picture captures) with dates ranging from 1980-01-01 (DOS epoch) through 1987-06-27. |
| `SELSTA.TXT` | small | Screen template for "SELECT STATION" dialog with box-drawing characters. F1=Add station, F2=Remove station, ESC=Exit. |
| `STORAGE.TXT` | small | Screen template for "STORAGE" dialog. Columns: Time, Tilt, Range, Gain. F1=Delete, RET=Select. |
| `SPACE.TXT` | 673 lines | Blank dot-fill screen template — 79-column lines of `.` characters. Used as a background canvas for the screen editor. |

#### Reference and Tool Files

| File | Size | Description |
|---|---|---|
| `ILIST.DOC` | 4,477 bytes | WordPerfect document containing C code listings for SIMPP (Simple Image Processing Package) — histogram equalization, contrast stretching, LUT highlight colorization. Reference material. |
| `PT.LAS` | 73 bytes | PT editor session/last-file config. Two entries point to `D:\PRDATA\pttemp.add` and `C:\RADAR2\radar.pas` — records what the developer was last editing. |

#### Batch Build Scripts

| File | Size | Description |
|---|---|---|
| `LOAD.BAT` | 601 bytes | Copies 30 radar picture files (`HHMM*.PIC`) from floppy disk (drive A:) to current directory. Loaded a day's worth of recorded radar pictures for the demo unit. |
| `RECOMP.BAT` | 579 bytes | Recompiles 10 customer-specific builds (directories `D:\8701` through `D:\8712`). For each: copies that customer's `CUSTOM.PAS`, runs `TURBO` compiler, copies resulting `RADAR.COM` back. |
| `REMAKE.BAT` | 463 bytes | Same as RECOMP.BAT but for a subset of customers (8701–8712 minus 8704–8706). |

### 19880329 RADARPAS Tenn

Both languages coexist. Deployed to Tennessee site.

| File | Description |
|---|---|
| Various `.PAS` | Pascal source files |
| `ENVIRONM.MOD/DEF` | Environment module (Modula-2) |
| `MODEM.MOD/DEF` | Modem interface |
| `RS232.MOD/DEF` | Serial port driver |
| `SCREEN.MOD/DEF` | Screen handling |
| `STORAGE.MOD/DEF` | Data storage |

### 19880519 RADAR MOD Rad1dot1

Patch-file collection with monthly revision files.

| File | Description |
|---|---|
| `RADAR.PAS` | Main Pascal source |
| `R8701.PAS`…`R8802.PAS` | Monthly revision patches (87=1987, 01=January, etc.) |
| `RADAR10.PAS`, `RADAR2.PAS`, `RADART.PAS` | Alternate builds |
| `RADAR.MOD` | Main Modula-2 module, now named `E300RadarTerm` |

### 19880801 RADARPAS RADIO

All-Pascal RADIO variant with four `.RDR` include files.

#### Source Files

| File | Description |
|---|---|
| `RADAR.PAS` | Main program |
| `RADARBAK.PAS` | Backup of main |
| `RADIO.PAS` | Radio subsystem |
| `RADIORX.PAS` | Radio receive |
| `RADIOTX.PAS` | Radio transmit |
| `RADTERM.PAS` | Stripped-down terminal variant |
| `CUSTOM.PAS` | Site customization |

#### .RDR Include Files

| File | Size | Description |
|---|---|---|
| `SCREEN.RDR` | 11,638 bytes | "Screen Format Routines." Nearly identical to SN8801 version — same circle tables, same flags. Slightly smaller (11,638 vs 11,967 bytes). |
| `GRAPH.RDR` | 9,387 bytes | "Graphics Routines for EGA Card." Defines `CharTab14Type`, `CharTab8Type`, `PlaneSet`, `FuncType (Rot1..Rot7, _Clr, _And, _Or, _Xor)`. Implements low-level EGA register routines: `SelectPlane` (port $3C4/$3C5), `ShowPlane` (port $3C0), `SelectFunc` (port $3CE/$3CF), `SetMask`. |
| `GRAPHBAK.RDR` | 9,613 bytes | **Backup of GRAPH.RDR** with `SelectPlane` body commented out (`(* ... *)`). Preserves an intermediate state where EGA plane selection was being reworked. |
| `MISC.RDR` | 1,546 bytes | "Miscellaneous Routines." DOS interrupt wrappers: `SetDTA` (INT 21h AH=$1A), `SetDir` (INT 21h AH=$4E), `DirEntry` (reads filename from DTA offset 30), `ReadNextEntry` (INT 21h AH=$4F). Supports disk file browsing. |

### 19880815 RADAR MOD

**Major Modula-2 release.** Full separation of concerns into 30+ module pairs.

#### Module Set

| Module | Description |
|---|---|
| `MAIN.MOD` / `MAIN2.MOD` | Main program modules |
| `SCREENHA.MOD/DEF` | Screen handler |
| `PICTURES.MOD/DEF` | Picture storage and display |
| `STATIONS.MOD/DEF` | Station management |
| `SELECTOR.MOD/DEF` | Station selector UI |
| `LOCATOR.MOD/DEF` | Cursor/locator (CX, CY, bearing/range) |
| `MODEM.MOD/DEF` | Modem communication |
| `AUTO.MOD/DEF` | Automated operation scheduling |
| `CRC.DF2` | 448-byte Modula-2 v2 definition file. "Created: 8/10/87, Author: Derek Lane, Logitech Modula-2/86." Defines `CalcCRC(ForBuffer: ARRAY OF BYTE; VAR CRC: CARDINAL)` for transmission integrity. |

#### Binaries and IDE Files

| File | Size | Description |
|---|---|---|
| `MAIN.EXE` | 59,928 bytes | Compiled binary |
| `M2.SES` | binary | Logitech TopSpeed Modula-2 IDE session. References `C:\PROJ\E300\M2.CFG`, working directory `C:\PROJ\E300`. |

#### OLD/ Subdirectory

Preserves two superseded generations of the main module, showing the v2→v3.0→current progression within this snapshot.

| File | Description |
|---|---|
| `OLD/MAIN.MOD` | Original `MODULE Main`. Imports: `ASCII`, `Auto`, `ExtendKey`, `E300Interface`, `FIO`, `Graph`, `Graphics`, `IO`, `Lib`, `Locator`, `MemCompress`. Moved to OLD/ when MAIN2.MOD replaced it. |
| `OLD/MAIN2.MOD` | `MODULE Main; (* E300 PC terminal version 3.0 *)`. "This is the main module of the E300PC 3.0 software." Nearly identical imports to MAIN.MOD but adds `UpdateTimes` to Auto imports. Itself superseded by a later version. |
| `OLD/OPTIONS.DEF` | Skeleton definition module with typo: `DEFINITIOM MODULE Options;`. Exports only `PROCEDURE OptionMenu;`. |

---

## Phase 4: Assembly Sweep Engine + RS811A Experiment (1989)

### 19890101 RADARPAS 2dot1

Version 2.1 label. Mostly Pascal variant patch files.

### 19890316 RADAR RS811A_Interface

**Experimental — not carried forward.**

| File | Description |
|---|---|
| `RS811A_I.MOD` | "Created: 3/14/89, Author: D. Lane. Bendix RS811A Radar Receiver/Transmitter interface. Communicates via an interface card, an ARINC 429 control bus, and an ARINC 453 high-speed data bus." An attempt to interface with the Bendix RS811A airborne weather radar — a completely different hardware platform using avionics-standard buses. |

### 19890319 RADAR MOD Release

Official Modula-2 release with E300 interface abstraction.

| File | Description |
|---|---|
| `MAIN.MOD` | Main module |
| `E300INTE.MOD/DEF` | E300 interface abstraction |
| `AUTO.MOD/DEF` | Automated operation |
| `LOCATOR`, `MODEM`, `PICTURES`, `SCREENHA`, `SELECTOR`, `STATIONS` | Full module set |
| `TEST.MOD` | Test harness |

### 19890319 Radar Sweep

| File | Description |
|---|---|
| `SWEEP.EXE` | Standalone radar sweep display program (binary only) |

### 19890326 Radar Sweep

The radar PPI (Plan Position Indicator) display required real-time pixel drawing at EGA resolution. This snapshot contains the complete evolution of the x86 assembly sweep renderer, including design documents and cycle-count timing analyses.

#### Sweep Engine Variants

| File | Description |
|---|---|
| `SWEEP.ASM` | Intermediate sweep version. `CurrInc DW 100` (starts mid-table). `NumInc = 400`, `SizeInc = 32`. Bit-plane approach to drawing radar radials via `RotTable` (128-byte rotation table). |
| `SWEEP2.ASM` | Main high-performance sweep routine. `CurrInc DW 0` (starts at entry 0). Same parameters. Core PPI algorithm: rotates radar data words through `RotTable`, uses XInc/YInc tables to step through screen pixels per azimuth. |
| `SWEEP2.BAK` | 16,972-byte backup of SWEEP2.ASM. **"TITLE Sweep -- High-Performance Radar Sweep Routine / SUBTITLE Author: DGL  Date: July 15, 1987."** Preserves the `CurrInc=100` variant. |
| `SWEEP2-2.ASM` | Reorganized variant of SWEEP2 with slightly different organization, same header and data segment. |
| `SWEEP3.ASM` | `SweepOn = 1` (sweep line enabled). `NumInc = 512` (larger table). RGB gradient initialization: `RedData DB 11 DUP(000H), 11 DUP(0FFH), 10 DUP(0FFH)`, `GrnData DB 11 DUP(0FFH), 11 DUP(0FFH), 10 DUP(000H)`. |
| `SWEEP4.ASM` | `SweepOn = 0`, `NumInc = 512`. Same gradient as SWEEP3. Trailing spaces suggest different editor or copy-paste origin. |
| `SWEEP5.ASM` | **Design specification** — no TITLE directive. Documents register assignments: `AX = Radar data (Source)`, `BX = Delta proc`, `DX = Screen data (Dest)`, `CX = Screen Rotate Count`, `SI = Ptr: Radar`, `DI = Ptr: Screen`, `BP = Ptr: Delta proc`. Lists 36 function names for table-driven sweep architecture. |

#### Supporting Assembly

| File | Description |
|---|---|
| `GRAPH.ASM` | "Graphics Routines for EGA Card." Defines `RadarData` segment with `RedData1/GrnData1/RedData2/GrnData2/RedData3/GrnData3` (3 radar returns). `RadarInt PROC NEAR` — hardware interrupt handler called by data acquisition board. `Average PROC NEAR` — averages three returns. |
| `INCTABX.ASM` | `PUBLIC IncTableX`. Massive table of 16-bit words encoding X-direction pixel increment decisions for every radar azimuth angle. Packed bitfield: bit N set = "increment X at pixel N." 400+ entries for Bresenham-derived sweep precision. |
| `INCTABY.ASM` | `PUBLIC IncTableY`. Matching Y-direction increment table. Dense values like `0DB6DH, 0BB6DH` — Bresenham-derived Y-step bit masks per azimuth. Paired with INCTABX to drive pixel-by-pixel radial drawing. |

#### Timing Analysis Files

| File | Description |
|---|---|
| `ALTSWP.ASM` | **Cycle-count timing worksheet** for the "alternate sweep" algorithm. Every instruction annotated: `DEC CH (2 clocks)`, `JNZ (4/16)`, `ROR BX,CL (15)`. Calculates total clocks for "Reload Inc" path (110 clocks) and four movement cases (X+Y+, X+only, Y+only, neither). |
| `SWPLNE.ASM` | Timing analysis of `SweepLn` inner loop. Documents per-data-word load cycle costs: `DEC SI (2)`, `JE (4/16)`, `MOV DX,ES:[SI+OFFSET XInc] (19)` — total 50 clocks per data word. |
| `SWPLNE2.ASM` | Sweep line and sweep flash routine. Shows the EGA port sequence for selecting the white plane ($3C4H/$3C5H, $3CEH/$3CFH), calls `SweepLn`, then `REP MOVSW` to copy IncTableX/Y data for the previous sweep position. |

#### Design Documents

| File | Size | Description |
|---|---|---|
| `NEWSWP.DGL` | small | WordPerfect 5.x document (`.DGL` = Derek G. Lane's personal extension for design docs). Describes the table-driven sweep architecture: 36 function codes for all increment combinations. Per-radial cost: 128 × functions 0–35 + 16 × function 36 (load new word) + 1 × function 37 (end radial) = 145 functions. At 106 cycles/function average: **15,370 cycles per 256-pixel radial**. |
| `NEWSWP.DOC` | 1,885 bytes | Plain-text timing worksheet. Register assignment spec and per-function cycle estimates: `INC_None (2 clocks × 25% = 0.5)`, `INC_X (6 clocks × 23.4% = 1.404)`, `INC_Y (59 clocks × 25% = 14.75)`, etc. |

#### Compiled Binaries

| File | Description |
|---|---|
| `GFX.EXE` | Graphics support executable |
| `SWEEP2.EXE` | Compiled sweep renderer |

---

## Phase 5: SCA/Subscription System and E250 (1991–1992)

### 19910104 RADARDB Cdscrn

**Compiler change: Logitech → TopSpeed Modula-2.**

| File | Description |
|---|---|
| `CDSCRN.MOD` | "Created: 11/14/90, Author: D. Lane, System: TopSpeed Modula-2." Screen handler for SCA (Subscription) cable-delivered radar terminal. |
| `SCADB2.MOD` | SCA database module |
| `TESTDB.MOD` | Database test harness |

### 19910309 RADAR E250Term

E250 terminal for KSNP, Coffey County, Kansas (Doppler radar for weather station). Collaborator: Peter James.

| File | Description |
|---|---|
| `README.txt` | Written **1998-01-19** (retrospectively). Describes architecture: server side is Peter James's VGA 640×480 TSR with white bit-plane over black/green/yellow/red double plane. Serial-port ISR auto-answers modem calls, validates serial number, logs access, OCRs screen parameters from EGA character generator, compresses and transmits line-by-line. Notes: "I have somehow misplaced the final release of the source code." |
| `SINCOS.TAB` | Precomputed sine/cosine lookup table. 91 entries, values scaled ×187 (EGA circle radius in pixels). Wraps through full circle: 187 (cos 0°) → 0 (90°) → -187 (180°) → 0 (270°) → 187. Used for fast trig without floating-point hardware. |
| `Alt/DB.EDT` | Screen-definition script for EDT (screen editor/form definition tool). Defines `:Banner` frame (window, blue/brightWhite color scheme, `message` string field), `:MainMenu` frame (Parent Frame: 0 = exits to DOS). **Copyright (C) 1990, D. G. Lane — All rights reserved.** |

### 19921021 RADAR Testchan

| File | Description |
|---|---|
| `TESTCHAN.EXE` | Test channel program (compiled binary only) |

### 19921022 RADARPAS RADIO

Radio subsystem with full TX/RX module pairs.

| File | Description |
|---|---|
| `MAIN.MOD`, `MAIN2.MOD` | Main program modules |
| `E300INTE.DEF` | E300 interface definition |
| `RADIOTX.MOD`, `RADIORX.MOD` | Radio transmit/receive |
| `RADARTX.MOD`, `RADARRX.MOD` | Radar-level transmit/receive |
| `RADIO.MOD` | Radio subsystem |
| `TESTRX.MOD`, `TESTRX.EXE` | Receive test harness |
| `ANALYSIS.MOD` | Analysis module (first appearance) |
| `RADIOTX.D$$` | Draft definition module (`.D$$` = TopSpeed draft format). Defines `MaxFile = 16`, types `PrefixRec` (with `PrefixAt: LONGCARD`, `PrefixData: ARRAY [0..6] OF BYTE`), `PrefixTabPtr`, `DirEntryRec` (with Class, Name, Time, Date, Size, Prefix). Exports `Transmit`, `FileAt`, `Directory`, `GenPrefixData`, `TransmitPic`. |

### 19921023 RADAR MOD AUTO

Automated dialing system with image compression and CRC checking.

| File | Description |
|---|---|
| `AUTO.MOD/DEF` | Automated operation |
| `COMPR.MOD` | Image compression |
| `CONVERT.MOD` | Data conversion |
| `CRC.MOD/DEF` | Cyclic redundancy check |
| `MEMCOMPR.DEF` | Memory compressor interface |
| `OPTIONFI.MOD` | Persistent options file handler |
| `OPTIONS.MOD/DEF` | Options menu |
| `MAIN2.MOD` | Main program |
| `TESTRX.MOD`, `TESTRX.EXE` | Receive test |
| `DB.BAK` | 2,655-byte backup of DB.MOD. Modula-2 `IMPLEMENTATION MODULE DB;`. Imports `Lib, rs2, Process, TimeDate`. Shows `TxProcess` (sends radar picture buffer via `rs2.Send(Buffer, Size)` at 9600 baud) and `InstallTx` (configures RS-232 port, sets up Process scheduler). VAR block (commented out): `Buffer: ARRAY [0..54000] OF BYTE`. |

### 19921104 RADAR MOD AUTO

Near-final release.

| File | Description |
|---|---|
| Full module set | All AUTO system modules |
| `ANALYZE.EXE` | Standalone analysis tool |
| `MAIN.EXE` | Compiled main executable |
| `RADARTX.D$$` | Draft definition: `DEFINITION MODULE RadarTx;`. Imports from RadioTx. Exports `GenPrefixData` and `TransmitPic` — higher-level radar-specific wrapper around RadioTx. |
| `RADIORX.D$$` | Draft definition: `DEFINITION MODULE RadioRx;`. Nearly identical to RADIOTX.D$$ but `PrefixTabPtr` commented out. Receiver-side interface. |
| `COLORADO.NUM` | 1 line: `1 303 757 9891`. Phone number configuration for auto-dial modem. Format: `[line] [area_code] [exchange] [number]`. Area code 303 = Colorado. |
| `M2.RED` | Modula-2 compiler file redirection/search paths: `*.DEF = C:\M2\DEF; .` / `*.MOD = .; C:\M2\MOD` / `*.OBJ = C:\M2\OBJ; .` / `*.EXE = .` / `*.BAK = C:\M2\BAK; .` |

### 19921223 RADAR MOD

Evidence of parallel development branches.

| File | Description |
|---|---|
| `MAINRX.EXE` | 49,752-byte receive-side main executable |
| `CREATDAT.EXE` | Creates the E300 database |
| `E300DB.DAT` | 49 bytes. Site configuration: `Murray Ohio--Lawrenceburg, TN`. Names the customer installation. |
| `DIFF.TXT` | **Hand-written diff** comparing this snapshot against `../e300-2/`. Shows changes in `SCREENHA.DEF` (adds `FullPic: BOOLEAN`, `WritePic` procedure) and `SCREENHA.MOD` (adds `xor` to graphics imports, adds `ScaleChange: BOOLEAN`, scale values `100 | 250 | 500 | 1000`). Confirms at least two parallel development branches existed in December 1992. |
| `M2.SES` | Logitech M2 IDE session. Working directory: `C:\M2\E300DB`. |
| Source subset | Partial module set |

### 19921228 RADAR MOD

**Final archived release. Version 3.1SCA.**

| File | Description |
|---|---|
| `MAIN.MOD` | `E300PC version 3.1SCA` — the SCA subscription system final version. Imports `DB`, `Analysis`, `Process` (concurrency). |
| `TEST.MOD`, `TEST.EXE` | Test harness |
| `MAIN.EXE` | Final compiled executable |
| `E300PC.DAT` | 49-byte binary configuration blob. Contains truncated procedure name fragments (`GetPosL`, `Rename`, `InitBufInfo`, `Assign`). |
| `M2.SES` | Logitech M2 IDE session. Working directory: `C:\M2\E300-2`. Cursor positioned in function `main`. |
| `DEF/`, `MOD/` subdirectories | Reorganized build structure for definition and implementation files |

---

## 2026: FreePascal Revival

### radar.pas (root level)

FreePascal-compatible modernization of the `19880114 RADAR.PAS` snapshot. Header: "FreePascal Compatible Version / Original: 19880114 RADAR.PAS." Pragmas: `{$MODE TP}`, `{$ASMMODE INTEL}`, `uses Dos;`. Targeted by the `Makefile`/`build.sh` Docker/FreePascal container build workflow.

---

## Language and Compiler Evolution

| Period | Language | Compiler/System | Signature |
|---|---|---|---|
| 1985–1987 | Turbo Pascal | Borland Turbo Pascal | `Program E300_Radar_Terminal;`, `{$C+,V-,I-}` |
| 1987 Nov | Modula-2 (initial port) | Logitech Modula-2/86 | `MODULE RadarVersion2point0;` |
| 1988–1989 | Modula-2 | Logitech Modula-2/86 | `MODULE Main;`, `M2.SES` session files |
| 1989 Mar | x86 Assembly | MASM/TASM | Pure 8086 assembly for sweep engine |
| 1990–1992 | Modula-2 | TopSpeed Modula-2 | `System: TopSpeed Modula-2` headers, `.D$$` extension, `M2.RED` |
| 2026 | Free Pascal | FreePascal | `{$MODE TP}`, `uses Dos;` |

---

## Source Provenance

The files in `radar/` were harmonized from three original source trees (commit `848cc91`):

1. **Google Drive archive** (commit `a5168f4`) — primary source of all snapshot material, with `YYYYMMDD`-format folder names.
2. **`pascal/` directory** (from RADARPAS GitHub repo, merged via `066bf5b`) — Pascal-era snapshots with YYYYMMDD directory names. Overlapping source files were identical to `radar/` counterparts (CR/LF differences only). Unique items (`.COM` binaries, `.BAT` scripts) merged into `radar/`. Directory then deleted.
3. **`modula2/` directory** (same origin) — Modula-2 era files. Again, source overlap was identical except line endings. Unique binary artifacts (`.EXE`, `.SES`, `.BIN`) moved into `radar/`. Directory then deleted.

---

## Architectural Lineage

```
1985  RADAR.PAS (monolith, Turbo Pascal, 1200 baud)
  │
  ├─ 1987 Apr  Split: RADAR + RADIO + RADIORX/TX + CUSTOM (2400 baud)
  │             .BAK preserves prior editor state
  │
  ├─ 1987 Nov  ═══ PIVOT: Pas2Mod2 ═══
  │             RADAR.MOD (Logitech M2/86) + 5 Logitech RTS .ASMs
  │             Pascal kept as fallback
  │
  ├─ 1988       Dual-language period
  │  ├─ SN8801: .RDR includes, GRAPH.BIN/P, screen templates, batch builds
  │  ├─ Tenn:   first M2 modules (ENVIRONM, MODEM, RS232, SCREEN, STORAGE)
  │  ├─ RADIO:  4 .RDR files (GRAPHBAK.RDR = work-in-progress backup)
  │  └─ MOD:    30+ modules, MAIN.EXE
  │             OLD/ preserves: MAIN.MOD → MAIN2.MOD (v3.0) → current
  │             CRC.DF2 authored Derek Lane, 8/10/87
  │
  ├─ 1989       Assembly sweep engine + RS811A experiment
  │  └─ 12 .ASM files: SWEEP → SWEEP5 evolution
  │     INCTABX/Y = Bresenham radial tables
  │     ALTSWP/SWPLNE = cycle-count worksheets
  │     NEWSWP.DGL/.DOC = design documents
  │     SWEEP2.BAK = "Author: DGL, July 15, 1987"
  │     RS811A_I.MOD = ARINC 429/453 one-off experiment
  │
  ├─ 1991       Compiler: Logitech → TopSpeed Modula-2
  │  ├─ SCA cable delivery system (CDSCRN, SCADB2)
  │  └─ E250Term (KSNP, Kansas): SINCOS.TAB, DB.EDT (©1990 DGL)
  │     README.txt written 1998 — "misplaced final source"
  │
  └─ 1992       Final releases
     ├─ RADIO:    .D$$ draft definitions, ANALYSIS.MOD (first appearance)
     ├─ AUTO:     COMPR/CONVERT/CRC/OPTIONFI modules
     │            DB.BAK (rs2.Send at 9600 baud)
     │            COLORADO.NUM (303-757-9891 auto-dial)
     ├─ 19921223: DIFF.TXT (parallel branch evidence: e300-2)
     │            E300DB.DAT = "Murray Ohio--Lawrenceburg, TN"
     └─ 19921228: v3.1SCA — final archived version
                  M2.SES cursor in C:\M2\E300-2\MAIN.MOD

2026  radar.pas (FreePascal revival of 19880114 snapshot)
```
