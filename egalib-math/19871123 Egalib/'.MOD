DEFINITION MODULE ModGraphBase;


TYPE
  GraphicModeRec   = RECORD
    HorizRes,
    VertRes        : CARDINAL;
    PixPerByte     : CARDINAL;
    BitMaps        : CARDINAL;
    SegmentStart   : CARDINAL;
    InitProc       : PROC;
    MapSelectProc  : PROCEDURE(BITSET);
    FuncSelectProc : PROCEDURE(FuncType);
    ClearProc      : PROC;
    PlotProc       : PROCEDURE(INTEGER,INTEGER);
  END; (* RECORD *)

VAR
  MonoText40x25  : GraphicModeRec;
  ColorText40x25 : GraphicModeRec;
  MonoText80x25  : GraphicModeRec;
  ColorText80x25 : GraphicModeRec;
  MonoText80x43  : GraphicModeRec;
  ColorText80x43 : GraphicModeRec;

  CGA320x200x2   : GraphicModeRec;
  CGA320x200x4   : GraphicModeRec;
  CGA640x200x2   : GraphicModeRec;
 
  EGA640x350x4   : GraphicModeRec;
  EGA640x350x16  : GraphicModeRec;
  EGA720x350x2   : GraphicModeRec;

  Herc740x348x2  : GraphicModeRec;

  CurrentMode    : GraphicModeRec;

PROCEDURE SetMode(GraphicModeRec);

VAR
  InitProc       : PROC;
  MapSelectProc  : PROCEDURE(BITSET);
  FuncSelectProc : PROCEDURE(FuncType);
  ClearProc      : PROC;
  PlotProc       : PROCEDURE(INTEGER,INTEGER);

PROCEDURE Plot(X, Y : INTEGER);

END ModGraphBase.
