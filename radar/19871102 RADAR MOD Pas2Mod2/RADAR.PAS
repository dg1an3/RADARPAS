MODULE RadarTerminal; (* 2.0 *)

FROM SYSTEM IMPORT
  BYTE;

TYPE
  TiltType         = [0..11];
  RangeType        = [0..4];
  GainType         = [1..17];

  LineType         = ARRAY [0..80] OF CHAR;

  Gen8Type         = ARRAY [1..8] OF BYTE;

  ModeType         = [ Modem, Interactive, WaitPic, RxPic, RxGraph ];

  BufType          = ARRAY[1..2000] OF BYTE;

  TimeRec          = RECORD
    Year           :   [1980..2099];
    Month          :   [1..12];
    Day            :   [1..31];
    Hour           :   [0..23];
    Minute         :   [0..59];
  END; (* RECORD *)

  RegisterType     = RECORD
    CASE : CARDINAL OF
      1  : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : INTEGER);
      2  : (AL,AH,BL,BH,CL,CH,DL,DH          : BYTE);
    END; (* CASE *)
  END; (* CASE *)

  DirPath          : ARRAY [0..63] OF CHAR;
  ModemType        : [ Hayes, RacalVadic ];
  ComPort          : CARDINAL;
  Printer          : [ EpsonMX80, InkJet ];
  Clock            : [ Hour12, Hour24 ];

CONST
  OnOff            = 001C;
  SendPic          = 004C;
  CheckGraph       = 020C;
  SendGraph        = 012C;
  TiltUp           = 002C;
  TiltDown         = 005C;
  RangeUp          = 003C;
  RangeDown        = 006C;
  GainUp           = 015C;
  GainDown         = 016C;

  TiltVal          : ARRAY TiltType OF CARDINAL;
                       (0,1,2,3,4,5,6,8,10,12,15,20);
  RangeVal         : ARRAY RangeType OF CARDINAL;
                       (10,25,50,100,200);


TYPE
  PicRec           = RECORD
    FileName       :   ARRAY [0..11] OF CHAR;
    FileDate,
    FileTime       :   CARDINAL;
    Time           :   TimeRec;
    Tilt           :   TiltType;
    Range          :   RangeType;
    Gain           :   GainType;
  END; (* RECORD *)

VAR
  StationName      : ARRAY [0..11] OF CHAR;
  Pic              : ARRAY [0..100] OF PicRec;
  CurrPic, MaxPic  : INTEGER;
  RT               : BYTE;

VAR
  Mode             : ModeType;

  (* Mode Flags *)
  ErrorFlag        : BOOLEAN;
  GraphicsOn       : BOOLEAN;
  OldCon           : INTEGER;

  (* Miscellaneous Variables *)
  Registers        : RegisterType;
  Key              : CHAR;
  DTA              : ARRAY [0..127] OF BYTE;
  Escape           : BOOLEAN;
  I,J              : INTEGER;
  Map1             : ARRAY [1..512,1..8] OF BYTE;
  Map2             : ARRAY [1..512,1..8] OF BYTE;
  Map1Size         : INTEGER;

(*.PA*)
(*******************************************************************************)
(** Miscellaneous Routines                                                    **)
(*******************************************************************************)
PROCEDURE SetDTA(VAR DTA);
BEGIN
  WITH Registers DO
    AH:=1AH;
    DS:=Seg(DTA);
    DX:=Ofs(DTA);
    MsDos(Registers);
    ErrorFlag:=(Flags and 01)<>0;
  END; (* WITH *)
END SetDTA;

PROCEDURE SetDir(Mask : LineType; Attr : BYTE);
BEGIN
  SetDTA(DTA);
  WITH Registers DO
    AH:=4EH;
    DS:=Seg(Mask);
    DX:=Ofs(Mask)+1;
    CX:=Attr;
    MsDos(Registers);
    ErrorFlag:=(Flags and 01H)<>0;
  END; (* WITH *)
END SetDir;

PROCEDURE DirEntry : LineType;
VAR
  Line           : LineType;
BEGIN
  Line:='';I:=30;
  REPEAT
    Line:=Line+Chr(DTA[I]);
    I:=I+1;
  UNTIL DTA[I]=0;
  DirEntry:=Line;
  WITH Registers DO
    AH:=$4F;
    CX:=22;
    MSDos(Registers);
    ErrorFlag:=(Flags and $01)<>0;
  END; (* WITH *)
END DirEntry;

PROCEDURE ReadKbd;
BEGIN
  Read(Kbd,Key);
  IF KeyPressed THEN
    Read(Kbd,Key);
    Escape:=true;
  ELSE
    Escape:=false;
  END; (* IF *)
END ReadKbd;

PROCEDURE WriteTime(Time : TimeRec);
BEGIN
  CASE Clock OF
    0 :
      IF Time.Hour<13 THEN
        Write(Time.Hour:2,':')
      ELSE
        Write((Time.Hour-12):2,':')
      END; |
    1 :
      Write(Time.Hour:2,':'); |
  END; (* CASE *)
  IF Time.Minute<10 THEN
    Write('0');
  END; (* IF *)
  Write(Time.Minute);
  IF Clock=0 THEN
    IF Time.Hour>12 THEN
      Write('pm')
    ELSE
      Write('am')
    END; (* IF *)
  ELSE
    Write('  ')
  END; (* IF *)
END WriteTime;


(*.PA*)
(*******************************************************************************)
(** Graphics Routines                                                         **)
(*******************************************************************************)

TYPE
  CharTab14Type    = ARRAY [0..127,0..13] OF BYTE;
  CharTab8Type     = ARRAY [0..127,0..7] OF BYTE;
  PlaneSet         = SET OF 0..3;
  FuncType         = (Rot1,Rot2,Rot3,Rot4,Rot5,Rot6,Rot7,_Clr,_And,_Or,_Xor);
  ListType         = ARRAY [1..640] OF BYTE;

VAR
  CharTab14        : POINTER TO CharTab14Type;
  CharTab8         : POINTER TO CharTab8Type;
  CharSize         : BYTE;

CONST
  Colors           : ARRAY [0..15] OF BYTE =
    ($00,36,50,54,$3F,$3F,$3F,$3F,$09,$09,$09,$09,$09,$09,$09,$09);

VAR
  CurrPlane      : PlaneSet;

PROCEDURE SelectPlane(ForPlanes : PlaneSet);
VAR
  Data           : BYTE absolute ForPlanes;
BEGIN
  port[$3C4]:=$02;
  port[$3C5]:=Data;
  CurrPlane:=ForPlanes;
END SelectPlane;

PROCEDURE ShowPlane(ForPlanes : PlaneSet);
VAR
  Data           : BYTE absolute ForPlanes;
  Q              : BYTE;
BEGIN
  Q:=port[$3DA];
  port[$3C0]:=$12;
  port[$3C0]:=Data;
  port[$3C0]:=$20;
END ShowPlane;

VAR
  CurrFunc       : FuncType;

PROCEDURE SelectFunc(ForFunc : FuncType);
BEGIN
  port[$3CE]:=$03;
  IF ForFunc IN [Rot1..Rot7] THEN
    port[$3CF]:=Ord(ForFunc)+1
  ELSE
    port[$3CF]:=(Ord(ForFunc)-7) shl 3;
  END; (* IF *)
  CurrFunc:=ForFunc;
END SelectFunc;

VAR
  CurrMask       : BYTE;

PROCEDURE SetMask(ToMask : BYTE);
BEGIN
  port[$3CE]:=$08;
  port[$3CF]:=ToMask;
  CurrMask:=ToMask;
END SetMask;

VAR
  CursX,CursY      : BYTE;
  XPos,YPos        : BYTE;
  XMax,YMax        : BYTE;

PROCEDURE GotoXY(X,Y : INTEGER);
BEGIN
  CursX:=X; CursY:=Y;
END;

PROCEDURE ConOut(ForChar : CHAR);
VAR
  I,Q            : BYTE;
  CharPos        : INTEGER;
BEGIN
  CASE ForChar OF
    010C :
      IF CursX>0 THEN
        CursX:=CursX-1;
      END; (* IF *) |
    012C :
      IF CursY<YMax THEN
        CursY:=CursY+1;
      END; (* IF *) |
    015C :
      CursX:=0; |
  ELSE
    CharPos:=(CursX+XPos)+(CursY+YPos)*CharSize*80;
    FOR I:=0 TO CharSize-1 DO
      CASE CharSize OF
        8 :
          Mem[$A000:CharPos+I*80]:=CharTab8^[Ord(ForChar),I]; |
        14 :
          Mem[$A000:CharPos+I*80]:=CharTab14^[Ord(ForChar),I]; |
      END; (* CASE *)
    END; (* FOR *)
    IF CursX<XMax THEN
      CursX:=CursX+1;
    ELSE
      CursX:=0;
      CursY:=CursY+1;
    END; (* IF *)
  END; (* CASE *)
END ConOut;

PROCEDURE ReadStr(Len : BYTE) : LineType;
VAR
  Line           : LineType;
  I,TempX        : BYTE;
BEGIN
  TempX:=CursX;
  FOR I:=1 TO Len DO Write(' ');
  CursX:=TempX;
  Line:=''; Write('Û');
  REPEAT
    ReadKbd; Key:=UpCase(Key);
    CASE Key OF
      #32..#126 :
        IF Length(Line)<=Len THEN
          Line:=Line+Key;
          Write(^H,Key,'Û');
        END; (* IF *) |
      ^H :
        IF Length(Line)>0 THEN
          Write(^H,^H,'Û ',^H);
          Line:=Copy(Line,1,Length(Line)-1);
        END; (* IF *) |
    END; (* CASE *)
  UNTIL Key=#13;
  Write(^H,' ');
  ReadStr:=Line;
END ReadStr;

PROCEDURE GRWrite(ForStr : linetype;X,Y : INTEGER);
VAR
  I,J,Q,
  AdjX,Rot       : BYTE;
BEGIN
  AdjX:=X div 8; Rot:=X mod 8;
  FOR I:=2 TO Length(ForStr) DO
    FOR J:=0 TO 7 DO
      Q:=Mem[$A000:(Y+J)*80+AdjX+I-1];
      Mem[$A000:(Y+J)*80+AdjX+I-1]:=
        (CharTab8^[Ord(ForStr[I-1]),J] shl (8-Rot)) or
        (CharTab8^[Ord(ForStr[I]),J] shr Rot);
    END; (* FOR *)
  END; (* FOR *)
END GRWrite;

PROCEDURE GRPlot(X,Y : INTEGER);
VAR
  AtByte         : INTEGER;
  Q,AtBit        : BYTE;
BEGIN
  AtByte:=Y*80+(X shr 3);
  AtBit:=$80 shr (X and $07);
  SetMask(AtBit);
  Q:=Mem[$A000:AtByte];
  Mem[$A000:AtByte]:=$FF;
  SetMask($FF);
END GRPlot;

PROCEDURE GRLine(X1,Y1,X2,Y2 : INTEGER);
VAR
  Add            : real;
  Dir            : INTEGER;
  XReal,YReal    : real;
BEGIN
  XReal:=X1; YReal:=Y1;
  IF Abs(Y2-Y1)>Abs(X2-X1) THEN
    Add:=(X2-X1)/Abs(Y2-Y1);
    IF Y2>Y1 THEN
      Dir:=1;
    ELSE
      Dir:=-1;
    END; (* IF *)
    WHILE Y1<>Y2 DO
      GRPlot(Trunc(XReal),Y1);
      XReal:=XReal+Add;
      Y1:=Y1+Dir;
    END; (* WHILE *)
  ELSE
    IF X2<>X1 THEN
      Add:=(Y2-Y1)/Abs(X2-X1);
    ELSE
      Add:=0;
    END; (* IF *)
    IF X2>X1 THEN
      Dir:=1
    ELSE
      Dir:=-1;
    END; (* IF *)
    WHILE X1<>X2 DO BEGIN
      GRPlot(X1,Trunc(YReal));
      YReal:=YReal+Add;
      X1:=X1+Dir;
    END; (* WHILE *)
  END; (* IF *)
END GRLine;

PROCEDURE Window(X,Y,XSize,YSize : BYTE);
BEGIN
  FOR I:=Y TO Y+YSize DO
    FOR J:=0 TO CharSize-1 DO
      SelectPlane([2]);
      FillChar(Mem[$A000:(I*CharSize+J)*80+X],XSize+1,$FF);
      SelectPlane([3]);
      FillChar(Mem[$A000:(I*CharSize+J)*80+X],XSize+1,$00);
    END; (* FOR *)
  END; (* FOR *)
  XPos:=0; YPos:=0; XMax:=79; YMax:=24;
  XPos:=X; YPos:=Y;
  XMax:=XSize; YMax:=YSize;
  CursX:=0; CursY:=0;
END Window;

VAR
  LastMess       : linetype;

PROCEDURE GRMessage(ForStr : linetype; WaitKey : BOOLEAN);
VAR
  I,J,Left       : INTEGER;
  OXPos,OYPos    : BYTE;
  OXMax,OYMax    : BYTE;
CONST
  Space : string[50] = '                                                  ';
BEGIN
  OXPos:=XPos; OYPos:=YPos; OXMax:=XMax; OYMax:=YMax;
  SelectFunc(_Clr);
  SelectPlane([2]);
  IF Length(LastMess)>0 THEN
    Window(40-Length(LastMess) shr 1,24,Length(LastMess)-1,1);
    SelectPlane([2,3]);
    Write(Copy(Space,1,Length(LastMess)));
    SelectPlane([3]);
  END; (* IF *)
  LastMess:=ForStr;
  IF Length(LastMess)>0 THEN
    Window(40-Length(LastMess) shr 1,24,Length(LastMess)-1,1);
    Write(LastMess);
    IF WaitKey THEN
      ReadKbd;
      GRMessage('',false);
    END; (* IF *)
  END; (* IF *)
  XPos:=OXPos; YPos:=OYPos; XMax:=OXMax; YMax:=OYMax;
END GRMessage;

PROCEDURE Ask(ForStr : linetype) : BOOLEAN;
BEGIN
  GRMessage(ForStr+' (Y/N)?',true);
  Ask:=UpCase(Key)='Y';
END Ask;

PROCEDURE ToggleGraphics;
BEGIN
  IF GraphicsOn THEN
    ShowPlane([0,1]);
  ELSE
    ShowPlane([0..3]);
  END; (* IF *)
  GraphicsOn:=not(GraphicsOn);
END ToggleGraphics;

VAR
  LastLine         : INTEGER;
  LineSize         : INTEGER;

PROCEDURE DispLine( VAR LinePtr );
VAR
  LineNum        : INTEGER absolute LinePtr;
  Line           : ARRAY [0..1279] OF BYTE absolute LinePtr;
  count,rept     : INTEGER;
  AtByte         : INTEGER;
  AtBit          : BYTE;
  ROn,GOn        : BOOLEAN;
  RByte,GByte    : BYTE;
  Size           : INTEGER;
BEGIN
  AtByte:=LineNum*80;
  AtBit:=0;
  RByte:=$00;
  GByte:=$00;
  Count:=2;
  LastLine:=LineNum;
  SelectFunc(_Clr);
  REPEAT
    Size:=((Line[Count] and $07) shl 8) or Line[Count+1];
    CASE (Line[Count] shr 5) and $03 OF
      0 :
        ROn:=false;
        GOn:=false; |
      1 :
        ROn:= true;
        GOn:=false; |
      2 :
        ROn:=false;
        GOn:= true; |
      3 :
        ROn:= true;
        GOn:= true; |
    END; (* CASE *)
    IF Size+AtBit<=8 THEN
      IF ROn THEN
        RByte:=RByte or ($FF shr (8-Size) shl AtBit);
      END; (* IF *)
      IF GOn THEN
        GByte:=GByte or ($FF shr (8-Size) shl AtBit);
      END; (* IF *)
      AtBit:=AtBit+Size;
    ELSE
      IF ROn THEN
        RByte:=RByte or ($FF shl AtBit);
      END; (* IF *)
      IF GOn THEN
        GByte:=GByte or ($FF shl AtBit);
      END; (* IF *)
      SelectPlane([0]);
      Mem[$A000:AtByte]:=RByte;
      SelectPlane([1]);
      Mem[$A000:AtByte]:=GByte;
      Size:=Size-8+AtBit;
      AtBit:=0;
      AtByte:=AtByte+1;
      IF Size+AtBit>8 THEN
        SelectPlane([0]);
        IF ROn THEN
          RByte:=$FF;
        ELSE
          RByte:=$00;
        END; (* IF *)
        FillChar(Mem[$A000:AtByte],Size shr 3,RByte);
        SelectPlane([1]); IF GOn THEN GByte:=$FF ELSE GByte:=$00; END;
        FillChar(Mem[$A000:AtByte],Size shr 3,GByte);
        AtByte:=AtByte+(Size shr 3); AtBit:=Size and $07;
      ELSE
        AtBit:=Size;
      END; (* IF *)
      IF ROn THEN
        RByte:=$FF shr (8-AtBit);
      ELSE
        RByte:=$00;
      END; (* IF *)
      IF GOn THEN
        GByte:=$FF shr (8-AtBit);
      ELSE
        GByte:=$00;
      END; (* IF *)
    END; (* IF *)
    IF AtBit=8 THEN
      SelectPlane([0]);
      Mem[$A000:AtByte]:=RByte;
      SelectPlane([1]);
      Mem[$A000:AtByte]:=GByte;
      AtByte:=AtByte+1;
      AtBit:=0;
      RByte:=$00;
      GByte:=$00;
    END; (* IF *)
    Count:=Count+2;
  UNTIL (Line[Count]=$18) or KeyPressed;
  LineSize:=Count+2;
END DispLine;

PROCEDURE DrawScale;
VAR
  I              : INTEGER;
  WriteVal       : BYTE;
BEGIN
  SelectPlane([0,1]); SelectFunc(_Clr);
  FOR I:=0 TO 349 DO
    WriteVal:=$C0;
    IF (I mod 100)=0 THEN
      WriteVal:=$FF;
    ELSIF (I mod 50)=0 THEN
      WriteVal:=$FC;
    ELSIF (I mod 10)=0 THEN
      WriteVal:=$F0;
    END; (* IF *)
    Mem[$A000:I*80]:=WriteVal;
  END; (* FOR *)
END DrawScale;

PROCEDURE InitEGA;
VAR
  I,Q            : BYTE;
  Time           : TimeRec;
BEGIN
  WITH Registers DO        (*SET 640 x 350 Hi-Res mode*)
    AH:=$00; AL:=$10;
    Intr($10,Registers);
    AX:=$1130; BH:=$02;    (*SET address FOR CHARacter table pointer - size 14*)
    Intr($10,Registers);
    CharTab14:=Ptr(ES,BP);
    AX:=$1130; BH:=$03;    (*SET address FOR CHARacter table pointer - size 8*)
    Intr($10,Registers);
    CharTab8:=Ptr(ES,BP);
    AH:=$2C;               (*Get Time*)
    Time.Hour:=CH;
    Time.Minute:=CL;
  END; (* WITH *)
  FOR I:=0 TO 15 DO        (*Initialize palette registers*)
    Q:=port[$3DA];
    port[$3C0]:=I;
    port[$3C0]:=Colors[I];
  END; (* FOR *)
  port[$3C0]:=$20;         (*Enable palette registers*)
  CharSize:=14;
  XMax:=79;
  YMax:=24;
  SelectPlane([2]);
  GotoXY(0,0);
  Write('TILT  : XXX');
  GotoXY(65,0);
  Write('TIME : ');
  WriteTime(Time);
  GotoXY(0,24);
  Write('RANGE : XXX');
  GotoXY(65,24);
  Write('GAIN  : XXX');
  GotoXY(0,22);
  Write('H = HELP');
END InitEGA;




(*.PA*)
(*******************************************************************************)
(** Screen Format Routines                                                    **)
(*******************************************************************************)
VAR
  (*Screen Format Flags*)
  HelpOn,
  Gfx1On,
  Gfx2On,
  RngMksOn       : BOOLEAN;
  RngChng        : BOOLEAN;

CONST
  Circle1  : ARRAY [0..175] OF BYTE =
(92, 96, 99,102,105,108,111,114,117,119,122,124,127,129,131,134,
136,138,140,142,144,146,148,150,152,154,156,157,159,161,162,164,
166,167,169,170,172,173,175,176,178,179,181,182,183,185,186,187,
188,190,191,192,193,194,196,197,198,199,200,201,202,203,204,205,
206,207,208,209,210,211,212,213,214,215,216,217,217,218,219,220,
221,221,222,223,224,225,225,226,227,227,228,229,229,230,231,231,
232,233,233,234,235,235,236,236,237,237,238,238,239,239,240,240,
241,241,242,242,243,243,244,244,245,245,245,246,246,247,247,247,
248,248,248,249,249,249,250,250,250,250,251,251,251,251,252,252,
252,252,253,253,253,253,253,254,254,254,254,254,254,254,255,255,
255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255);
  Circle2  : ARRAY [25..175] OF BYTE = (   0,
 20, 31, 39, 45, 51, 56, 60, 64, 68, 72, 76, 79, 82, 85, 88, 91,
 94, 96, 99,101,103,106,108,110,112,114,116,118,120,122,124,125,
127,129,131,132,134,135,137,138,140,141,143,144,145,147,148,149,
151,152,153,154,155,156,158,159,160,161,162,163,164,165,166,167,
168,169,170,171,171,172,173,174,175,176,176,177,178,179,180,180,
181,182,182,183,184,184,185,186,186,187,187,188,188,189,190,190,
191,191,192,192,193,193,194,194,194,195,195,196,196,196,197,197,
197,198,198,198,199,199,199,200,200,200,200,201,201,201,201,201,
202,202,202,202,202,202,203,203,203,203,203,203,203,203,203,203,
203,203,203,203,204,204);
  Circle3  : ARRAY [62..175] OF BYTE = (   0,
 15, 25, 32, 38, 43, 47, 51, 55, 58, 61, 64, 67, 70, 73, 75, 77,
 80, 82, 84, 86, 88, 90, 92, 94, 95, 97, 99,100,102,103,105,106,
108,109,110,112,113,114,115,116,118,119,120,121,122,123,124,125,
126,127,128,128,129,130,131,132,133,133,134,135,136,136,137,138,
138,139,140,140,141,141,142,142,143,143,144,144,145,145,146,146,
146,147,147,148,148,148,149,149,149,149,150,150,150,150,151,151,
151,151,151,152,152,152,152,152,152,152,152,152,152,152,152,153,
153);
  Circle4  : ARRAY [99..175] OF BYTE = (   0,
 10, 19, 25, 30, 34, 38, 41, 44, 47, 49, 51, 54, 56, 58, 60, 62,
 63, 65, 67, 68, 70, 71, 72, 74, 75, 76, 77, 79, 80, 81, 82, 83,
 84, 85, 85, 86, 87, 88, 89, 90, 90, 91, 92, 92, 93, 93, 94, 95,
 95, 96, 96, 97, 97, 97, 98, 98, 98, 99, 99, 99,100,100,100,100,
101,101,101,101,101,101,101,101,101,101,102,102);
  Circle5  : ARRAY [136..175] OF BYTE = (  0,
  5, 12, 17, 20, 23, 25, 28, 30, 31, 33, 35, 36, 37, 38, 40, 41,
 42, 42, 43, 44, 45, 46, 46, 47, 47, 48, 48, 49, 49, 49, 50, 50,
 50, 50, 50, 50, 50, 51, 51);

PROCEDURE WriteRngMks;
BEGIN
  SelectFunc(_CLR);
  SelectPlane([2]);
  FOR I:=175 TO 1 DO BEGIN
    FOR J:=Circle1[I-1] TO Circle1[I] DO BEGIN
      GRPlot(320+J,I); GRPlot(320-J,I);
      GRPlot(320+J,350-I); GRPlot(320-J,350-I);
    END;
    IF I>25 THEN
      FOR J:=Circle2[I-1] TO Circle2[I] DO BEGIN
        GRPlot(320+J,I); GRPlot(320-J,I);
        GRPlot(320+J,350-I); GRPlot(320-J,350-I);
      END;
      IF I>62 THEN
        FOR J:=Circle3[I-1] TO Circle3[I] DO BEGIN
          GRPlot(320+J,I); GRPlot(320-J,I);
          GRPlot(320+J,350-I); GRPlot(320-J,350-I);
        END;
        IF I>99 THEN
          FOR J:=Circle4[I-1] TO Circle4[I] DO BEGIN
            GRPlot(320+J,I); GRPlot(320-J,I);
            GRPlot(320+J,350-I); GRPlot(320-J,350-I);
          END;
          IF I>136 THEN
            FOR J:=Circle5[I-1] TO Circle5[I] DO BEGIN
              GRPlot(320+J,I); GRPlot(320-J,I);
              GRPlot(320+J,350-I); GRPlot(320-J,350-I);
            END;
          END;
        END;
      END;
    END;
  END;
END WriteRngMks;

CONST
  ASin              : ARRAY [0..360] OF BYTE = (
128,128,128,129,129,130,130,131,131,132,132,132,133,133,134,134,135,135,135,136,
136,137,137,138,138,138,139,139,140,140,140,141,141,141,142,142,143,143,143,144,
144,144,145,145,145,146,146,146,147,147,147,147,148,148,148,148,149,149,149,149,
150,150,150,150,151,151,151,151,151,151,152,152,152,152,152,152,152,152,153,153,
153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,
153,153,153,152,152,152,152,152,152,152,152,151,151,151,151,151,151,150,150,150,
150,149,149,149,149,148,148,148,148,147,147,147,147,146,146,146,145,145,145,144,
144,144,143,143,143,142,142,141,141,141,140,140,140,139,139,138,138,138,137,137,
136,136,135,135,135,134,134,133,133,132,132,132,131,131,130,130,129,129,128,128,
128,128,128,127,127,126,126,125,125,124,124,124,123,123,122,122,121,121,121,120,
120,119,119,118,118,118,117,117,116,116,116,115,115,115,114,114,113,113,113,112,
112,112,111,111,111,110,110,110,109,109,109,109,108,108,108,108,107,107,107,107,
106,106,106,106,105,105,105,105,105,105,104,104,104,104,104,104,104,104,103,103,
103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,
103,103,103,104,104,104,104,104,104,104,104,105,105,105,105,105,105,106,106,106,
106,107,107,107,107,108,108,108,108,109,109,109,109,110,110,110,111,111,111,112,
112,112,113,113,113,114,114,115,115,115,116,116,116,117,117,118,118,118,119,119,
120,120,121,121,121,122,122,123,123,124,124,124,125,125,126,126,127,127,128,128,
128);
  ACos              : ARRAY [0..360] OF BYTE = (
146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,145,145,145,145,
145,145,145,145,145,144,144,144,144,144,144,144,143,143,143,143,143,142,142,142,
142,142,141,141,141,141,140,140,140,140,139,139,139,139,138,138,138,138,137,137,
137,137,136,136,136,135,135,135,134,134,134,134,133,133,133,132,132,132,131,131,
131,130,130,130,129,129,129,128,128,128,128,128,128,128,127,127,127,126,126,126,
125,125,125,124,124,124,123,123,123,122,122,122,122,121,121,121,120,120,120,119,
119,119,119,118,118,118,118,117,117,117,117,116,116,116,116,115,115,115,115,114,
114,114,114,114,113,113,113,113,113,113,112,112,112,112,112,112,111,111,111,111,
111,111,111,111,111,110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,111,111,111,111,
111,111,111,111,111,112,112,112,112,112,112,112,113,113,113,113,113,114,114,114,
114,114,115,115,115,115,116,116,116,116,116,117,117,117,118,118,118,118,119,119,
119,119,120,120,120,121,121,121,122,122,122,122,123,123,123,124,124,124,125,125,
125,126,126,126,127,127,127,128,128,128,128,128,128,128,129,129,129,130,130,130,
131,131,131,132,132,132,133,133,133,134,134,134,134,135,135,135,136,136,136,137,
137,137,137,138,138,138,138,139,139,139,139,140,140,140,140,141,141,141,141,142,
142,142,142,142,143,143,143,143,143,143,144,144,144,144,144,144,145,145,145,145,
145,145,145,145,145,146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,
146);

PROCEDURE WriteGfx( VAR At);
TYPE
  LandMarkRec      = record
    Bear           :   INTEGER;
    Range          :   INTEGER;
    Name           :   ARRAY [1..3] OF CHAR;
    Nothing        :   BYTE;
                     END;
  SegmentRec       = record
    Range1         :   INTEGER;
    Bear1          :   INTEGER;
    Range2         :   INTEGER;
    Bear2          :   INTEGER;
                     END;
VAR
  LandMark       : ARRAY [1..100] OF LandMarkRec absolute At;
  Segment        : ARRAY [1..1000] OF SegmentRec absolute At;
  Count          : INTEGER;
  Min,Max        : INTEGER;
  Adj            : INTEGER;
BEGIN
  Count:=1; SelectPlane([2]); SelectFunc(_OR);
  Max:=RangeVal[Pic[CurrPic].Range]*10;
  Min:=Max div 7; Adj:=RangeVal[Pic[CurrPic].Range];
  REPEAT
    WITH Landmark[Count] DO BEGIN
      IF (Min<Range) and (Range<Max) THEN
        IF Range>1310 THEN
          GRWrite(' '+Name+' ',
          300+Trunc(Range*(ASin[Bear]-128.0)/Adj),
          170-Trunc(Range*(ACos[Bear]-128.0)/Adj))
        ELSE
          GRWrite(' '+Name+' ',
          300+Range*(ASin[Bear]-128) div Adj,
          170-Range*(ACos[Bear]-128) div Adj);
        END; (* IF *)
      END; (* IF *)
      Count:=Count+1;
    END;
  UNTIL (Landmark[Count].Bear=0) and (Landmark[Count].Range=0) or (Count>100);
  SelectPlane([2]); SelectFunc(_OR);
  Max:=RangeVal[Pic[CurrPic].Range]*10;
  Adj:=RangeVal[Pic[CurrPic].Range];
  REPEAT
    WITH Segment[Count] DO BEGIN
      IF (Range1<Max) and (Range2<Max) THEN
        IF (Range1>1310) or (Range2>1310) THEN
          GRLine(
            320+Trunc(Range1*(ASin[Bear1]-128.0)/Adj),
            174-Trunc(Range1*(ACos[Bear1]-128.0)/Adj),
            320+Trunc(Range2*(ASin[Bear2]-128.0)/Adj),
            174-Trunc(Range2*(ACos[Bear2]-128.0)/Adj));
        END ELSE
          GRLine(Range1*(ASin[Bear1]-128) div Adj+320,
            174-Range1*(ACos[Bear1]-128) div Adj,
            Range2*(ASin[Bear2]-128) div Adj+320,
            174-Range2*(ACos[Bear2]-128) div Adj);
        END;
      END;
      Count:=Count+1;
    END;
  UNTIL (Segment[Count].Range1=0) and (Segment[Count].Bear1=0) or (Count>512);
END;

PROCEDURE WriteHelp;
BEGIN
  SelectPlane([2]);
  GotoXY(0,2);
  Writeln('                 ');
  Writeln('               ');
  Writeln('          ');
  GotoXY(0,19); Write('          ');
  GotoXY(0,20); Write('          ');
  GotoXY(0,21); Write('              ');
  GotoXY(0,1); Write('          ');
  GotoXY(0,23); Write('          ');
  GotoXY(65,23); Write('          ');
  IF HelpOn THEN
    CASE Mode OF
      Modem : BEGIN
        GotoXY(0,2);
        Writeln('F1úSelect Station');
        Writeln('F2úCall Station');
        Writeln('F3úStorage');
        GotoXY(0,19); Write('+ Next Pic');
        GotoXY(0,20); Write('- Prev Pic');
        GotoXY(0,21); Write('ESCúQuit');
      END;
      Interactive : BEGIN
(*        VERSION 2.0
        GotoXY(0,2); Write('F7úSend Picture');
        GotoXY(0,21); Write('ESCúDisconnect');
        GotoXY(0,1); Write('úF1  úF2');
        GotoXY(0,23); Write('úF3  úF4');
        GotoXY(65,23); Write('úF5  úF6');
        END VERSION 2.0 *)
(*        VERSION 2.1 *)
        GotoXY(0,21); Write('ESCúDisconnect');
(*        END VERSION 2.1 *)
      END;
      RxPic : BEGIN
        GotoXY(0,21); Write('ESCúAbort');
      END;
    END;
  END; (* IF *)
  IF HelpOn THEN
    GotoXY(66,2); Write('GúAll Graphics');
    GotoXY(67,3); Write('RúRange Marks');
    GotoXY(73,4); Write('1úMap 1');
    GotoXY(73,5); Write('2úMap 2');
  END ELSE
    GotoXY(66,2); Write('              ');
    GotoXY(67,3); Write('             ');
    GotoXY(73,4); Write('       ');
    GotoXY(73,5); Write('       ');
  END;
END;

PROCEDURE WriteParams;
  BEGIN
    SelectFunc(_Clr); SelectPlane([2]);
    IF CurrPic>0 THEN
      WITH Pic[CurrPic] DO
        GotoXY(8,0); Write(TiltVal[Tilt]:3);
        GotoXY(72,0); WriteTime(Time);
        GotoXY(8,24); Write(RangeVal[Range]:3);
        GotoXY(72,24); IF Gain<17 THEN Write(Gain:4) ELSE Write(' PRE');
        IF Mode=Interactive THEN
          SelectPlane([0]); GotoXY(36,0);
          CASE RT OF
            0   : Write(' RT OFF ');
            1,2 : Write(' RT ON  ');
          END;
        END;
      END
    ELSE
      GotoXY(8,0); Write('XXX');
      GotoXY(72,0); Write('XX:XX  ');
      GotoXY(8,24); Write('XXX');
      GotoXY(72,24); Write(' XXX');
    END; (* IF *)
  END;

PROCEDURE ClearScreen;
  BEGIN
    SelectFunc(_Clr);
    FOR I:=0 TO 175 DO BEGIN
      FillChar(Mem[$A000:40-(1+Circle1[I] shr 3)+I*80],
        2*(1+Circle1[I] shr 3),0);
      FillChar(Mem[$A000:40-(1+Circle1[I] shr 3)+(350-I)*80],
        2*(1+Circle1[I] shr 3),0);
    END;
  END;

PROCEDURE UnWindow;
  BEGIN
    SelectPlane([2,3]); ClearScreen;
    IF Gfx1On THEN WriteGfx(Map1); END;
    IF Gfx2On THEN WriteGfx(Map2); END;
    IF RngMksOn THEN WriteRngMks; END;
    XPos:=0; YPos:=0; XMax:=79; YMax:=24;
  END;




PROCEDURE IOError : BOOLEAN;
  VAR
    Dummy : INTEGER;
  BEGIN
    Dummy:=IOResult;
    IF Dummy=0 THEN
      IOError:=false;
    END ELSE
      CASE Dummy OF
        $99 : GRMessage('ERROR : Unexpected END OF file',true);
        $F0 : GRMessage('ERROR : Disk is full',true);
        $F1 : GRMessage('ERROR : Directory is full',true);
        $F2 : GRMessage('ERROR : File is too big',true);
        $FF : GRMessage('ERROR : Disk changed. Please replace and retry.',true);
      END;
      IOError:=true;
    END;
  END;


(*.PA*)
(*******************************************************************************)
(** RS232 Routines                                                            **)
(*******************************************************************************)
VAR
  Buf              : string[255];
  BufBeg, BufEnd   : INTEGER;
  CheckSum         : BYTE;
  DSave            : INTEGER absolute CSeg:$0006;
  GRBuf            : ARRAY [1..1250] OF BYTE;
  LineNum          : INTEGER absolute GRBuf;
  PhoneNum         : string[31];
  POver            : ARRAY [1..4] OF Gen8Type absolute PhoneNum;
  MapCount         : BYTE;
  Response         : BOOLEAN;
  GfxMatch         : BOOLEAN;
  LineAt,WriteAt   : INTEGER;
  BufPtr           : ^BufType;
  BufCount         : INTEGER;
  GRSize           : INTEGER;
  PicSave          : ARRAY [-20000..30000] OF BYTE;
  PicSaveAt        : INTEGER;
  PicSize          : INTEGER;

PROCEDURE HangUp;

  BEGIN
    Port[ComPort+4]:=$08; Delay(1000); Port[ComPort+4]:=$0B;
  END;

PROCEDURE Tx(Charac : CHAR);
  BEGIN
    REPEAT UNTIL (port[ComPort+5] and $20)=$20;
    Port[ComPort]:=ord(Charac);
  END;

PROCEDURE Rx(VAR Charac : CHAR);
  BEGIN
    IF BufBeg=BufEnd THEN
      Charac:=#0
    ELSE
      Charac:=Buf[BufBeg];
      BufBeg:=BufBeg+1;
      IF BufBeg>255 THEN BufBeg:=1; END;
    END; (* IF *)
  END;

PROCEDURE ResetBuf;
  BEGIN
    BufBeg:=1; BufEnd:=1;
  END; (* ResetBuf *)

PROCEDURE SendCom(Command : CHAR; DelTime : INTEGER);
  VAR
    StartTime, CurrTime : INTEGER;
  BEGIN
    IF Mode=Interactive THEN
      Buf:=''; Response:=false;
      Tx('Z'); Delay(15); Tx(Command);
      IF (RT=0) and not(Command=SendGraph) THEN Delay(1000); END;
      WITH Registers DO BEGIN
        AH:=$2C;
        MsDos(Registers);
        StartTime:=DH*100+DL;
        REPEAT
          AH:=$2C;
          MsDos(Registers);
          CurrTime:=DH*100+DL;
          IF CurrTime<StartTime THEN CurrTime:=CurrTime+6000; END;
        UNTIL (CurrTime-StartTime>DelTime) OR Response;
      END; (* WITH *)
      IF Command=SendGraph THEN Mode:=RxGraph; END;
      IF Response THEN
        WriteParams
      ELSE
        Sound(440); Delay(10); NoSound;
      END;
    END;
  END;

PROCEDURE SetParams(VAR ForBuf; VAR Params : PicRec);
  VAR
    Buf            : string[10] absolute ForBuf;
    Comp           : Gen8Type absolute Map1;
  BEGIN
    CheckSum:=0;
    FOR I:=2 TO 9 DO CheckSum:=CheckSum+Ord(Buf[I]);
    Response:=CheckSum=Ord(Buf[10]);
    IF (Buf[1]='Q') and Response THEN
      WITH Params DO BEGIN
        Gain:=(BYTE(Buf[2]) shr 4) +1;
        Tilt:=12-(BYTE(Buf[3]) and $0f);
        IF (BYTE(Buf[3]) and (1 shl 5)) <> 0
          THEN Gain := 17; END;
        CASE (BYTE(Buf[4]) and $38) OF
          $08 : Range:=1;
          $30 : Range:=2;
          $00 : Range:=3;
          $20 : Range:=4;
          $28 : Range:=0;
        END;
        Time.Hour:=(ord(Buf[6])-48)*10+(ord(Buf[7])-48);
        Time.Minute:=(ord(Buf[8])-48)*10+(ord(Buf[9])-48);
        IF (BYTE(Buf[3]) and $80)=$00 THEN
          RT:=2;
        elsIF (BYTE(Buf[3]) and $10)=$00 THEN
          RT:=0
        ELSE
          RT:=1;
        END;
      END;
    END;
    IF (Buf[1]='G') and Response THEN
      I:=2;
      WHILE (Comp[I-1]=Ord(Buf[I])) and (I<9) DO I:=I+1;
      GfxMatch:=not(I<9);
    END;
    Buf:='';
  END;


VAR
  data             : BYTE;
  RI               : INTEGER;

PROCEDURE RS232Interupt;
  BEGIN
    inline($1E/       (*PUSH DS*)
           $50/       (*PUSH AX*)
           $53/       (*PUSH BX*)
           $51/       (*PUSH CX*)
           $52/       (*PUSH DX*)
           $57/       (*PUSH DI*)
           $56/       (*PUSH SI*)
           $06/       (*PUSH ES*)
           $8C/$C8/   (*MOV AX,CS*)
           $8E/$D8/   (*MOV DS,AX*)
           $A1/DSave/ (*MOV AX,DSave*)
           $8E/$D8/$FB);  (*MOV DS,AX*)
    IF port[ComPort+2]=$04 THEN
      data:=port[ComPort];
      port[$20]:=$20; (*EOI FOR 8529*)
      CASE Mode OF
        Modem :
        BEGIN
          Buf[BufEnd]:=chr(data);
          BufEnd:=BufEnd+1;
          IF BufEnd>255 THEN BufEnd:=1; END;
        END;
        Interactive,WaitPic :
        BEGIN
          Buf:=Buf+chr(data);
          IF Length(Buf)=10 THEN
            SetParams(Buf,Pic[CurrPic]);
            Delay(10);
            Tx('A');
            Buf:='';
          END;
          IF Mode=WaitPic THEN
            IF (Buf[1]=#$FF) and (Buf[2]=#$FE) and (Buf[3]=#$FD) THEN
              Mode:=RxPic; GRSize:=0;
              CheckSum:=0;
            END;
          END;
        END;
        RxPic :
        BEGIN
          GRSize:=GRSize+1;
          GRBuf[GRSize]:=data;
          IF (GRSize and $01)=$01 THEN
            IF (GRBuf[GRSize-1]=$18) and
              (GRBuf[GRSize-2]=$18) and (GRSize>6) THEN
              CheckSum:=0;
              FOR RI:=1 TO GRSize-1 DO CheckSum:=CheckSum+GRBuf[RI];
              LineNum:=LineNum div 54;
              IF (LineNum>=LastLine) and (LineNum<=352)
                and (CheckSum=GRBuf[GRSize]) THEN
                Tx('A');
                Move(GRBuf,PicSave[PicSaveAt],GRSize-1);
                LineAt:=PicSaveAt;
                PicSaveAt:=PicSaveAt+GRSize-1;
                Tx('O');
                GRSize:=0;
              END ELSE
                Tx(#0);
                GRSize:=0;
              END;
            END;
          END;
        END;
        RxGraph :
        BEGIN
          BufPtr^[BufCount]:=data; BufCount:=BufCount+1;
          IF BufCount=9 THEN
            CheckSum:=0;
            FOR RI:=1 TO 8 DO CheckSum:=CheckSum+BufPtr^[RI];
            IF (*CheckSum=BufPtr^[BufCount]*)true THEN
              IF (BufPtr^[1]=0) and (BufPtr^[2]=0) and
                (BufPtr^[3]=0) and (BufPtr^[4]=0) THEN
              BEGIN
                Sound(440); Delay(100); NoSound;
                MapCount:=MapCount+1;
                IF MapCount=2 THEN
                  Map1Size:=OFS(BufPtr^)-OFS(Map1);
                  BufPtr:=Ptr(Seg(Map2),Ofs(Map2)-8);
                END;
              END;
              IF Ofs(BufPtr^)<Ofs(Map1Size)-16 THEN
                BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+8);
              END;
              BufCount:=1;
              Delay(5);
              Tx('A');
            END ELSE Tx(#0);
            BufCount:=1;
          END;
        END;
      END; (* CASE *)
    END (* IF *)
    ELSE
      IF port[ComPort+2]=$00 THEN
        IF (port[ComPort+6] and $88)=$08 THEN
          Mode:=Modem;
        END;
      END;
      port[$20]:=$20; (*EOI FOR 8529*)
    END;
    inline($07/       (*POP ES*)
           $5E/       (*POP SI*)
           $5F/       (*POP DI*)
           $5A/       (*POP DX*)
           $59/       (*POP CX*)
           $5B/       (*POP BX*)
           $58/       (*POP AX*)
           $1F);      (*POP DS*)
    inline($FB);      (*STI*)
    inline($CF);      (*IRET*)
  END;

PROCEDURE InitRS232; (*& interrupt routine*)
  BEGIN
    DSave:=DSeg; Buf:='';
    WITH Registers DO BEGIN
      AH:=$25;
      IF ComPort=$3F8 THEN AL:=$0C ELSE AL:=$0B; END;
      DX:=Ofs(RS232Interupt)+7;
      DS:=CSeg;
      Intr($21,Registers);
    END;
    FOR I:=ComPort TO ComPort+6 DO J:=port[I];
    Port[ComPort+3]:=$80; (*SET baud rate access bit*)
    Port[ComPort]:= 48; (*SET baud rate (2400 = 48)*)
    Port[ComPort+1]:=$00;
    Port[ComPort+3]:=$03; (*SET Line Control Data (8 data,1 stop,0 parity)*)
    Port[ComPort+1]:=$09;
    Port[ComPort+4]:=$0B; (*SET DTR & RTS high*)
    UsrOutPtr:=Ofs(Tx);
  END;


(*.PA*)
(*******************************************************************************)
(** Storage                                                                   **)
(*******************************************************************************)
PROCEDURE FetchPic;
  VAR PicFile      : file;
  BEGIN
    WriteParams;
    IF CurrPic=0 THEN
      SelectPlane([0,1]);
      ClearScreen;
      EXIT;
    END;
    IF Gfx1On or Gfx2On THEN
      SelectPlane([2]);
      ClearScreen;
      IF Gfx1On THEN WriteGfx(Map1); END;
      IF Gfx2On THEN WriteGfx(Map2); END;
      IF RngMksOn THEN WriteRngMks; END;
    END;
    Assign(PicFile,Pic[CurrPic].FileName);
    ReSet(PicFile,1);
    IF IOError THEN GRMessage('ERROR : Cannot find that picture file',true)
    ELSE
      BlockRead(PicFile,PicSave,FileSize(PicFile)+1,PicSize);
      PicSize:=PicSize-20000;
      BufPtr:=ADDR(PicSave); LastLine:=0;
      WHILE (LastLine<351) DO BEGIN
        DispLine(BufPtr^);
        BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+LineSize);
      END;
      Close(PicFile);
    END;
  END;

PROCEDURE InsertPic(ForPic : PicRec);
VAR
  Count : INTEGER;
  Later : BOOLEAN;
BEGIN
  Count:=0; Later:=false;
  REPEAT
    Count:=Count+1;
    IF Pic[Count].FileDate>ForPic.FileDate THEN
      Later:=true
    elsIF Pic[Count].FileDate=ForPic.FileDate THEN
      IF Pic[Count].FileTime>ForPic.FileTime THEN
        Later:=true;
      END;
    END;
  UNTIL Later or (Count>MaxPic);
END;

PROCEDURE SavePic(Size : INTEGER);
  VAR PicFile      : file;
  BEGIN
    WITH Pic[CurrPic] DO BEGIN
      FileName[0]:=Chr(7);
      FileName[1]:=Chr(Time.Hour div 10+48);
      FileName[2]:=Chr(Time.Hour mod 10+48);
      FileName[3]:=Chr(Time.Minute div 10+48);
      FileName[4]:=Chr(Time.Minute mod 10+48);
      FileName[5]:=Chr(Tilt+65);
      FileName[6]:=Chr(Range+65);
      FileName[7]:=Chr(Gain+64);
      FileName:=FileName+'.PIC';
      Assign(PicFile,FileName);
      ReWrite(PicFile,1); IF IOError THEN Exit; END;
      BlockWrite(PicFile,PicSave,Size); IF IOError THEN Exit; END;
      Close(PicFile);
      GRMessage('',false);
    END;
  END;


PROCEDURE Storage;
  VAR
    SelectPic,
    TopPic     : INTEGER;
    Count      : INTEGER;
    PicFile    : file;
  BEGIN
    Window(27,1,25,21);
    Write('ÍÍÍÍÍÍÍÍ STORAGE ÍÍÍÍÍÍÍÍÍ');
    Write('  úTimeú úTiltúRangeúGainú');
    GotoXY(0,18);
    Write('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ');
    Writeln(' RET ú Select Picture');
    Writeln(' F1  ú Delete Picture');
    Writeln(' ESC ú Exit');
    SelectPic:=CurrPic;
    TopPic:=MaxPic+1;
    REPEAT
      IF (SelectPic<TopPic) or (SelectPic>TopPic+15) THEN
        IF SelectPic<=8 THEN TopPic:=1 ELSE TopPic:=SelectPic-8; END;
        GotoXY(0,2);
        FOR Count:=TopPic TO TopPic+15 DO
          IF Count<=MaxPic THEN WITH Pic[Count] DO
            Write('  ');
            WriteTime(Time);
            Write(TiltVal[Tilt]:4);
            Write(RangeVal[Range]:6);
            IF Gain<17 THEN Write(Gain:5) ELSE Write('  PRE'); END;
            WriteLn;
          ELSE
            WriteLn('                        ');
          END;
        END;
      END;
      GotoXY(0,SelectPic-TopPic+2);
      IF SelectPic<>0 THEN Write('->');
      ReadKbd;
      CASE Key OF
        '+' : IF SelectPic<MaxPic THEN SelectPic:=SelectPic+1; END;
        '-' : IF SelectPic>0 THEN SelectPic:=SelectPic-1; END;
        ';' : IF SelectPic>0 THEN
                IF Ask('DELETE THIS PICTURE?') THEN
                  Assign(PicFile,Pic[SelectPic].FileName);
                  Erase(PicFile);
                  FOR Count:=SelectPic+1 TO MaxPic DO Pic[Count-1]:=Pic[Count];
                  TopPic:=MaxPic+1;
                  MaxPic:=MaxPic-1;
                END;
              END;
      END;
      Write(^M,'  ');
    UNTIL (Key=^[) or (Key=^M);
    UnWindow;
    IF Key=^M THEN
      CurrPic:=SelectPic;
      FetchPic;
    END;
    Key:=#0;
  END;

PROCEDURE LoadStation;
  VAR
    MapFile        : file;
    PhoneFile      : text;
    PicName        : string[20];
    PicVal         : ARRAY [0..7] OF BYTE absolute PicName;
  BEGIN
    ChDir(StationName); IF IOError THEN Exit; END;
    SelectPlane([2]);
    GotoXY(68,21); Write(StationName:12);
    Assign(PhoneFile,'PHONENUM.TXT');
    ReSet(PhoneFile);
    IF IOError THEN
      PhoneNum:=''
    ELSE
      Readln(PhoneFile,PhoneNum);
      Close(PhoneFile); IF IOError THEN Exit; END;
    END;
    Assign(MapFile,'MAP1.DAT');
    Reset(MapFile);
    IF IOError THEN
      GRMessage('WARNING : No map found FOR '+StationName+'.',true)
    ELSE
      BlockRead(MapFile,Map1,FileSize(MapFile));
      Close(MapFile);
    END;
    Assign(MapFile,'MAP2.DAT');
    Reset(MapFile);
    IF not IOError THEN
      BlockRead(MapFile,Map2,FileSize(MapFile));
      Close(MapFile);
    END;
    SetDir('????????.PIC'+#0,$00);
    MaxPic:=0;
    WHILE not ErrorFlag DO BEGIN
      MaxPic:=MaxPic+1;
      PicName:=DirEntry;
      WITH Pic[MaxPic] DO BEGIN
        FileName:=PicName;
        Time.Hour:=(PicVal[1]-48)*10+PicVal[2]-48;
        Time.Minute:=(PicVal[3]-48)*10+PicVal[4]-48;
        Tilt:=PicVal[5]-65; Range:=PicVal[6]-65;
        Gain:=PicVal[7]-64;
      END;
    END;
    CurrPic:=0;
  END;

PROCEDURE CallStation;
  VAR
    ModemMess : CHAR;
  BEGIN
    IF PhoneNum='' THEN
      IF StationName<>'' THEN Mode:=Interactive; END;
      Exit;
    END;
    Mode:=Modem;
    CASE ModemType OF
      0 : BEGIN
            GRMessage('DIALING - '+PhoneNum,false);
            Write(Usr,'ATDT',PhoneNum,^M);
          END;
      1 : BEGIN
            ResetBuf;
            Write(Usr,^E); Delay(50);
            Write(Usr,^M); Delay(50);
            Write(Usr,'D',PhoneNum,^M);
          END;
    END;
    ResetBuf;
    REPEAT
      Rx(ModemMess);
      CASE ModemMess OF
        '1','L' : GRMessage('CONNECTED AT 2400 BAUD',false);
        '3'     : GRMessage('NO CARRIER',false);
        '4','C' : GRMessage('MODEM ERROR',false);
        '6','E' : GRMessage('NO DIAL TONE',false);
        '7','B' : GRMessage('BUSY!',false);
        '8','F' : GRMessage('NO ANSWER',false);
        'T'     : GRMessage('TIME OUT',false);
        'A'     : GRMessage('ANSWER TONE - '+PhoneNum,false);
        'D'     : GRMessage('DIALING - '+PhoneNum,false);
        'R'     : GRMessage('RINGING - '+PhoneNum,false);
      END;
      IF ModemMess IN ['A','D','R'] THEN ModemMess:=#0; END;
    UNTIL (ModemMess>' ') or KeyPressed;
    IF ModemMess IN ['1','L'] THEN Mode:=Interactive
    ELSE
      ReadKbd; GRMessage('',false); HangUp;
    END;
  END;

VAR
  StatChar       : CHAR;
  MaxChar        : CHAR;
  Stat           : ARRAY ['A'..'M'] OF string[12];

PROCEDURE SelectStation;

  PROCEDURE AddStation;
    VAR
      PhoneFile : text;
      NewName   : string[12];
      NewPhone  : string[50];
    BEGIN
      GotoXY(0,12);
      Write(' NAME :           ');
      GotoXY(8,12);
      NewName:=ReadStr(8)+'.STA';
      IF NewName='' THEN Exit; END;
      Writeln(^M,' PHONE NUM :      ');
      NewPhone:=ReadStr(40);
      MkDir(NewName);
      IF IOResult=0 THEN
        IF NewPhone<>'' THEN
          ChDir(NewName);
          Assign(PhoneFile,'PHONENUM.TXT');
          ReWrite(PhoneFile);
          IF IOResult=0 THEN
            Writeln(PhoneFile,NewPhone);
            Close(PhoneFile);
          END;
          ChDir('..');
        END;
      END ELSE
        GRMessage('UNABLE TO CREATE DIRECTORY',true);
      END;
    END;

  PROCEDURE DelStation;
    VAR
      DelFile : file;
      StatKey : CHAR;
    BEGIN
      GRMessage('STATION LETTER TO DELETE?',true);
      StatKey:=UpCase(Key);
      IF (StatKey>='A') and (StatKey<=MaxChar) THEN
        IF Ask('DELETE '+Stat[StatKey]+'. CONTINUE') THEN
          GRMessage('DELETING STATION '+Stat[StatKey],false);
          ChDir(Stat[StatKey]);
          IF IOResult<>0 THEN Exit; END;
          SetDir('????????.???'+#0,$00);
          WHILE not ErrorFlag DO BEGIN
            Assign(DelFile,DirEntry);
            Erase(DelFile);
          END;
          ChDir('..');
          RmDir(Stat[StatKey]);
          GRMessage('',false);
        END;
      END;
    END;

  BEGIN
    IF StationName<>'' THEN ChDir('..'); END;
    REPEAT
      Window(27,1,25,14);
      GotoXY(0,0);
      Write('ÍÍÍÍÍ SELECT STATION ÍÍÍÍÍ');
      StatChar:='A'; SetDir('????????.STA'+#0,$10);
      WHILE not ErrorFlag DO BEGIN
        Stat[StatChar]:=DirEntry;
        Writeln(' ',StatChar,' ú ',Stat[StatChar]:12);
        StatChar:=Succ(StatChar);
      END;
      MaxChar:=Pred(StatChar);
      GotoXY(0,11);
      Write('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ');
      Writeln(' F1  ú Add station');
      Writeln(' F2  ú Remove station');
      Writeln(' ESC ú Exit');
      ReadKbd; Key:=UpCase(Key);
      IF Escape THEN
        CASE Key OF
          ';' : AddStation;
          '<' : DelStation;
        END;
        Key:=#0;
      END;
    UNTIL Key IN [^[,'A'..'M'];
    UnWindow;
    IF (Key>='A') and (Key<=MaxChar) THEN
      Gfx1On:=false; Gfx2On:=false;
      RngMksOn:=false;
      SelectPlane([0..3]); ClearScreen;
      StationName:=Stat[Key];
      LoadStation;
      FetchPic;
    elsIF StationName<>'' THEN
      ChDir(StationName);
    END;
    Key:=#0;
  END;


(*.PA*)
(*******************************************************************************)
(** Screen Dump                                                               **)
(*******************************************************************************)
VAR
  PrData           : ARRAY [0..79,0..2] OF BYTE;
  PrI,PrJ,PrK      : INTEGER;
  PrQ,RemCount     : BYTE;
  OldPrtScSeg,
  OldPrtScOfs      : INTEGER;
PROCEDURE ColorJetPrtSc;
  label
    AbortPrtSc;
  BEGIN
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    RemCount:=0;
    FOR PrI:=0 TO 359 DO BEGIN
      FOR PrJ:=0 TO 79 DO BEGIN
        IF KeyPressed THEN
          ReadKbd;
          IF Ask('ABORT SCREEN DUMP') THEN goto AbortPrtSc; END;
        END;
        FOR PrQ:=0 TO 2 DO BEGIN
          port[$3CE]:=$04; port[$3CF]:=PrQ;
          PrData[PrJ,PrQ]:=Mem[$A000:PrI*80+PrJ];
        END;
        PrQ:=not(PrData[PrJ,0] or PrData[PrJ,1] or PrData[PrJ,2]);
        PrData[PrJ,2]:=not(PrData[PrJ,2]) or PrQ;
        PrData[PrJ,0]:=PrData[PrJ,0] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,1]:=PrData[PrJ,1] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,2]:=PrQ;
      END;
      REPEAT
        IF RemCount>=48 THEN RemCount:=RemCount-48; END;
        Write(Lst,Chr($1B),Chr($5B),Chr($4F),Chr(245),Chr(0));
        Write(Lst,Chr($80),Chr($1F),Chr($00),Chr(100),Chr(96));
        FOR PrJ:=0 TO 79 DO Write(Lst,Chr(PrData[PrJ,0]));
        FOR PrJ:=0 TO 79 DO Write(Lst,Chr(PrData[PrJ,1]));
        FOR PrJ:=0 TO 79 DO Write(Lst,Chr(PrData[PrJ,2]));
        Write(Lst,#0);
        RemCount:=RemCount+13;
      UNTIL RemCount<48;
    END;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  END;

CONST
  Pat : ARRAY [0..1,1..3] OF BYTE = (($22,$55,$FF),($88,$AA,$FF));

VAR
  PrGrn,PrYel,PrRed,PrWhite : BYTE;

PROCEDURE EpsonMX80PrtSc;
  label
    AbortPrtSc;
  BEGIN
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    Write(Lst,#27,#65,#8,#27,#50);
    port[$3CE]:=$05; port[$3CF]:=$08;
    FOR PrI:=0 TO 79 DO BEGIN
      Write(Lst,#27,'K',#224,#1);
      RemCount:=0; PrJ:=349;
      FOR PrK:=0 TO 479 DO BEGIN
        IF KeyPressed THEN
          ReadKbd;
          IF Ask('ABORT SCREEN DUMP') THEN goto AbortPrtSc; END;
        END;
        port[$3CE]:=$07; port[$3CF]:=$0F;
        port[$3CE]:=$02; port[$3CF]:=$01; PrRed:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$02; port[$3CF]:=$03; PrYel:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$02; port[$3CF]:=$02; PrGrn:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$07; port[$3CF]:=$0C;
        port[$3CE]:=$02; port[$3CF]:=$04; PrWhite:=Mem[$A000:PrJ*80+PrI];
        Write(Lst,CHR((PrGrn and Pat[PrK and 1,1])
                   or (PrYel and Pat[PrK and 1,2])
                   or (PrRed) xor PrWhite));
        RemCount:=RemCount+1;
        IF RemCount>=8 THEN RemCount:=RemCount-8 ELSE PrJ:=PrJ-1; END;
      END;
      Write(Lst,^M,^J);
    END;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  END;


(*.PA*)
(*******************************************************************************)
(** Initialization and Configuration                                          **)
(*******************************************************************************)
PROCEDURE Initialize;
  BEGIN
    FillChar(Mode,Ofs(OldPrtScOfs)+20-Ofs(Mode),0);
    OldCon:=ConOutPtr;
    ConOutPtr:=Ofs(ConOut);
    GraphicsOn:=true;
    InitEGA;
    InitRS232;
    IF ComPort=$3F8 THEN port[$21]:=port[$21] and not(1 shl 4)
    ELSE port[$21]:=port[$21] and not(1 shl 3); END;
    Port[ComPort+1]:=$09;
    CASE ModemType OF
      0 : Write(Usr,'AT &F &C1 &D2 L M1 E V X4',^M);
      1 : BEGIN
            Write(Usr,^E,^M,^E,^M); Delay(100);
            Write(Usr,'O21122211211111112112',^M);
          END;
    END;
    WITH Registers DO BEGIN
      AH:=$35; AL:=$05;
      Intr($21,Registers);
      OldPrtScSeg:=ES; OldPrtScOfs:=BX;
      AH:=$25; AL:=$05;
      CASE Printer OF
        0 : DX:=Ofs(EpsonMX80PrtSc)+7;
        1 : DX:=Ofs(ColorJetPrtSc)+7;
      END;
      DS:=CSeg;
      MsDos(Registers);
    END;
    ChDir(DirPath);
    Pic[0].Range:=0;
    StationName:='';
    MaxPic:=0;
    HelpOn:=true; WriteHelp;
  END;

PROCEDURE DeInit;
  BEGIN
    IF StationName<>'' THEN ChDir('..'); END;
    port[ComPort+4]:=$08;        (*DTR & RTS OFf*)
    port[ComPort+1]:=$00;        (*Disable any interrupts*)
    port[$21]:= port[$21] or (1 shl 4);
    WITH Registers DO BEGIN
      AH:=$25;
      AL:=$05;
      DX:=OldPrtScOfs;
      DS:=OldPrtScSeg;
      Intr($21,Registers);
    END;
  END;

PROCEDURE Config;
  VAR
    ProgFile         : file OF BYTE;
    ProgDir          : string[20];
  BEGIN
    SelectFunc(_Clr);
    Window(24,1,28,8);
    Write('ÍÍÍÍÍÍÍÍÍÍ OPTIONS ÍÍÍÍÍÍÍÍÍÍ');
    Write(' F1: Modem   =               ');
    Write(' F2: Serial  =               ');
    Write(' F3: Clock   =               ');
    Write(' F4: Printer =               ');
    Write(' F5: Directory Path =        ');
    Write('                             ');
    Write(' F10: Update disk and exit   ');
    Write(' ESC: Exit option menu       ');
    REPEAT
      GotoXY(15,1);
      IF ModemType=0 THEN Write('Hayes Compat') ELSE Write('Racal-Vadic '); END;
      GotoXY(15,2); IF ComPort=$3F8 THEN Write('COM1:') ELSE Write('COM2:'); END;
      GotoXY(15,3); IF Clock=0 THEN Write('12 hour') ELSE Write('24 hour'); END;
      GotoXY(15,4);
      CASE Printer OF
        0 : Write('Epson MX80  ');
        1 : Write('Color InkJet');
      END;
      GotoXY(5,6); Write(DirPath);
      ReadKbd;
      CASE Key OF
        ';' : ModemType:=(ModemType+1) mod 2;
        '=' : Clock:=(Clock+1) mod 2;
        '<' : IF ComPort=$3F8 THEN ComPort:=$2F8 ELSE ComPort:=$3F8; END;
        '>' : Printer:=(Printer+1) mod 2;
        '?' : BEGIN
          GotoXY(5,6); Write('                        ');
          GotoXY(5,6); DirPath:=ReadStr(22);
          IF (Length(DirPath)>1) and (DirPath[Length(DirPath)]='\')
            and (DirPath[Length(DirPath)-1]<>':') THEN
            DirPath:=Copy(DirPath,1,Length(DirPath)-1);
          END;
        END;
        'D' : BEGIN
          Window(24,11,28,1);
          Writeln('PROGRAM FILE DIRECTORY?');
          ProgDir:=ReadStr(20);
          UnWindow;
          GRMessage('UPDATING PROGRAM FILE...',false);
          ChDir(ProgDir);
          Assign(ProgFile,'RADAR.COM');
          ReSet(ProgFile);
          IF not IOError THEN
            Seek(ProgFile,Ofs(DirPath)-256);
            FOR I:=Ofs(DirPath) TO Ofs(Clock) DO
              Write(ProgFile,Mem[CSeg:I]);
            Close(ProgFile);
          END ELSE GRMessage('PROGRAM FILE NOT FOUND',true);
          GRMessage('',false);
          Key:=#27;
        END;
      END;
    UNTIL Key=#27;
    Key:=#0;
    DeInit;
    Initialize;
  END;

(*.PA*)
(*******************************************************************************)
(** Main Routines                                                             **)
(*******************************************************************************)
PROCEDURE ExecCom;
  BEGIN
    CASE UpCase(Key) OF (*Process regular key codes*)
      'G'  : ToggleGraphics;
      'R'  : BEGIN
               RngMksOn:=not RngMksOn;
               IF RngMksOn THEN
                 WriteRngMks
               ELSE
                 SelectPlane([2,3]); ClearScreen;
                 IF Gfx1On THEN WriteGfx(Map1); END;
                 IF Gfx2On THEN WriteGfx(Map2); END;
               END;
             END;
      'H'  : BEGIN
               HelpOn:=not HelpOn;
               WriteHelp;
             END;
      '1'  : IF StationName<>'' THEN
               Gfx1On:=not Gfx1On;
               IF Gfx1On THEN
                 WriteGfx(Map1);
               ELSE
                 SelectPlane([2,3]); ClearScreen;
                 IF RngMksOn THEN WriteRngMks; END;
                 IF Gfx2On THEN WriteGfx(Map2); END;
               END;
             END;
      '2'  : IF StationName<>'' THEN
               Gfx2On:=not Gfx2On;
               IF Gfx2On THEN
                 WriteGfx(Map2);
               ELSE
                 SelectPlane([2,3]); ClearScreen;
                 IF RngMksOn THEN WriteRngMks; END;
                 IF Gfx1On THEN WriteGfx(Map1); END;
               END;
             END;
    END;
  END;

PROCEDURE RxGraphLoop;
  VAR
    MapFile : file;
  BEGIN
    BufPtr:=Addr(Map1); BufCount:=1; MapCount:=0;
    SendCom(SendGraph,150);
    IF not Response THEN Exit; END;
    Mode:=RxGraph;
    GRMessage('ONE MOMENT PLEASE... RECEIVING MAP OVERLAY',false);
    REPEAT
      IF KeyPressed THEN
        ReadKbd;
        IF Key=#27 THEN IF Ask('ABORT MAP OVERLAY RECEPTION') THEN Key:=^Q;
      END;
    UNTIL (Key=^Q) or (MapCount>3) or (Mode=Modem);
    IF Key=^Q THEN
      Tx('Y'); Tx('Y');
    END;
    GRMessage('SAVING MAP OVERLAY...',false);
    Assign(MapFile,'MAP1.DAT');
    ReWrite(MapFile,1);
    IF not IOError THEN
      BlockWrite(MapFile,Map1,Map1Size);
      Close(MapFile);
    END;
    Assign(MapFile,'MAP2.DAT');
    ReWrite(MapFile,1);
    IF not IOError THEN
      BlockWrite(MapFile,Map2,Ofs(BufPtr^)-Ofs(Map2)+8);
      Close(MapFile);
    END;
    GRMessage('',false);
    Mode:=Interactive; Key:=#0;
  END;


VAR
  PictureSaved : BOOLEAN;

PROCEDURE RxPicLoop;
  VAR
    AbortPending   : BOOLEAN;
    ContWrite      : BOOLEAN;
  BEGIN
    WriteHelp;
    SendCom(SendPic,200);
    IF not Response THEN Exit; END;
    SelectPlane([0,1]); ClearScreen;
    GRMessage('WAITING FOR PICTURE',false);
    DrawScale;
    Mode:=WaitPic; BufPtr:=Addr(GRBuf);
    LastLine:=0; AbortPending:=false;
    REPEAT
      IF KeyPressed THEN
        ReadKbd;
        ExecCom;
        IF Key=#27 THEN
          IF Ask('ABORT PICTURE') THEN Key:=^Q; END;
        END;
        GRMessage('WAITING FOR PICTURE',false);
      END;
    UNTIL (Key=^Q) or (Mode=RxPic);
    IF Mode=RxPic THEN
      WriteAt:=-20000; LineAt:=-20001; PicSaveAt:=-20000;
      GRMessage('RECEIVING PICTURE',false);
      REPEAT
        REPEAT
          inline($FA); ContWrite:=LineAt>=WriteAt; inline($FB);
          IF ContWrite THEN
            DispLine(PicSave[WriteAt]);
            WriteAt:=WriteAt+LineSize;
          END;
        UNTIL not ContWrite;
        IF KeyPressed THEN
          ReadKbd;
          IF AbortPending THEN
            IF UpCase(Key)='Y' THEN
              Tx('Y'); Tx('Y');
              GRMessage('PICTURE ABORTED',true);
              Tx('Y');
              Key:=^Q;
            ELSE
              GRMessage('RECEIVING PICTURE',false);
              AbortPending:=false;
            END
          ELSE
            ExecCom;
            IF Key IN ['1','2','G','R','H'] THEN
              GRMessage('RECEIVING PICTURE',false);
            END;
            IF Key=#27 THEN
              AbortPending:=true;
              GRMessage('ABORT PICTURE? (Y/N)',false);
            END;
          END;
        END;
      UNTIL (Key=^Q) or (LastLine>=352) or (Mode=Modem);
      IF LastLine>=352 THEN
        IF Mode<>Modem THEN
          HangUp;
          Delay(500);
          Mode:=Modem;
        END;
        GRMessage('SAVING PICTURE...',false);
        SavePic(PicSaveAt+20000);
        PictureSaved:=true;
      END ELSE
        Mode:=Interactive;
        PictureSaved:=false;
      END;
    END;
    GRMessage('',false);
    Key:=#0;
    WriteHelp;
  END;


PROCEDURE InterLoop;
  label Abort;
  BEGIN
    WriteHelp;
    MaxPic:=MaxPic+1;
    CurrPic:=MaxPic;
    PictureSaved:=false;
    SelectPlane([0,1]);
    ClearScreen;
    Buf:=''; SendCom('X',150);
    IF not Response THEN SendCom('X',150); END;
    IF not Response THEN SendCom('X',150); END;
    IF not Response THEN SendCom('X',150); END;
    IF not Response THEN
      GRMessage('NO RESPONSE. PRESS ANY KEY',true);
      HangUp;
      goto Abort;
    END;
    SelectPlane([3]); GotoXY(73,22); Write('ON LINE');
    SendCom(CheckGraph,150);
    IF Response and not GfxMatch THEN
      RxGraphLoop
    ELSE
      GRMessage('',false);
    END;
(*  VERSION 2.0
    REPEAT
      ReadKbd;
      IF Escape THEN
        CASE Key OF              (*Process extended key codes*)
          #59  : SendCom(TiltUp,150);
          #60  : SendCom(TiltDown,150);
          #61  : BEGIN
                   SendCom(RangeUp,300);
                   IF Gfx1On or Gfx2On THEN
                     SelectPlane([2]);
                     ClearScreen;
                     IF Gfx1On THEN WriteGfx(Map1);
                     IF Gfx2On THEN WriteGfx(Map2);
                     IF RngMksOn THEN WriteRngMks;
                   END;
                 END;
          #62  : BEGIN
                   SendCom(RangeDown,300);
                   IF Gfx1On or Gfx2On THEN
                     SelectPlane([2]);
                     ClearScreen;
                     IF Gfx1On THEN WriteGfx(Map1);
                     IF Gfx2On THEN WriteGfx(Map2);
                     IF RngMksOn THEN WriteRngMks;
                   END;
                 END;
          #63  : SendCom(GainUp,150);
          #64  : SendCom(GainDown,150);
          #65  : RxPicLoop;
        END
      ELSE
        ExecCom;
      END;
      IF Key=#27 THEN 
        IF Ask('DISCONNECT STATION') THEN
          Key:=^Q;
        END;
      END;
    UNTIL (Key=^Q) or (Mode=Modem);
    END VERSION 2.0 *)
(*  VERSION 2.1 *)
    RxPicLoop;
(*  END VERSION 2.1 *)
    Abort:
    IF Mode<>Modem THEN HangUp; END;
    Key:=#0;
    IF not PictureSaved THEN
      MaxPic:=MaxPic-1;
      CurrPic:=0;
    END;
    SelectPlane([3]); GotoXY(73,22); Write('       ');
    Mode:=Modem;
    WriteHelp;
  END;

PROCEDURE ModemLoop;
  BEGIN
    REPEAT
      ReadKbd;
      IF Escape THEN
        CASE Key OF
          #59 : BEGIN
                  SelectStation;
                  IF Mode=Interactive THEN InterLoop;
                END;
          #60 : BEGIN
                  CallStation;
                  IF Mode=Interactive THEN InterLoop;
                END;
          #61 : Storage;
          ^X  : ConFig;
         END
      ELSE
        CASE Key OF
          '+' : IF CurrPic<MaxPic THEN CurrPic:=CurrPic+1;
          '-' : IF CurrPic>0 THEN CurrPic:=CurrPic-1;
          ELSE ExecCom;
        END;
        IF Key IN ['+','-'] THEN FetchPic; END;
      END;
      IF Key=#27 THEN IF Ask('QUIT PROGRAM') THEN Key:=^Q; END;
    UNTIL Key=^Q;
  END;

VAR
  OldDir : string[40];

BEGIN
  GetDir(0,OldDir);
  Initialize;
  (*$I CUSTOM.PAS *)
  Window(20,15,41,6);
  Write('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
  Write('º  ELLASON E300 RADAR TERMINAL, ver 2.1  º');
  Write('º            Revision 1/14/88            º');
  Write('º           Copyright (C) 1987           º');
  Write('º               D. G. Lane               º');
  Write('º           All rights reserved          º');
  Write('ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
  GRMessage('PRESS ANY KEY',true);
  UnWindow;
  SelectStation;
  ModemLoop;
  DeInit;
  TextMode;
  ChDir(OldDir);
END.

(*.L-*)
(**********************************)
(* DID YOU JUST CHANGE SOMETHING? *)
(*                                *)
(*    IF SO, CHANGE THE DATE!!!   *)
(*           ---------------      *)
(**********************************)
(*.L+*)
