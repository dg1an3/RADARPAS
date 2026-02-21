{.L-}
(**********************************)
(* DID YOU JUST CHANGE SOMETHING? *)
(*                                *)
(*    IF SO, CHANGE THE DATE!!!   *)
(*           ---------------      *)
(**********************************)
{.L+}

{.HE%F - %D update}
{.FOpage %#}
{.LW80}
{.N+}
{$C-,V-,I-,R-,U-,K-}

Program Radar_Terminal;

type
  TiltType         = 0..11;
  RangeType        = 0..4;
  GainType         = 1..17;

  LineType         = string[80];

  Gen8Type         = array[1..8] of byte;

  ModeType         = (Modem,Interactive,WaitPic,RxPic,RxGraph);

  BufType          = array[1..2000] of byte;

  TimeRec          = record
    Year           :   1980..2099;
    Month          :   1..12;
    Day            :   1..31;
    Hour           :   0..23;
    Minute         :   0..59;
                     end;

  RegisterType     = record
    case integer of
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : integer);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;


const
  DirPath          : string[24] = '';
  ModemType        : byte = 0;
  ComPort          : integer = $3F8;
  Printer          : byte = 0;
  Clock            : byte = 0;

  OnOff            = #1;
  SendPic          = #4;
  CheckGraph       = #16;
  SendGraph        = #10;
  TiltUp           = #2;
  TiltDown         = #5;
  RangeUp          = #3;
  RangeDown        = #6;
  GainUp           = #13;
  GainDown         = #14;

  TiltVal          : array[TiltType] of byte =
                       (0,1,2,3,4,5,6,8,10,12,15,20);
  RangeVal         : array[RangeType] of byte =
                       (10,25,50,100,200);


type
  PicRec           = record
    FileName       :   string[12];
    FileDate,
    FileTime       :   integer;
    Time           :   TimeRec;
    Tilt           :   TiltType;
    Range          :   RangeType;
    Gain           :   GainType;
                     end;

var
  StationName      : string[12];
  Pic              : array[0..100] of PicRec;
  CurrPic, MaxPic  : integer;
  RT               : byte;

var
  Mode             : ModeType;

{Mode Flags}
  ErrorFlag        : boolean;
  GraphicsOn       : boolean;
  OldCon           : integer;

{Miscellaneous Variables}
  Registers        : RegisterType;
  Key              : char;
  DTA              : array[0..127] of byte;
  Escape           : boolean;
  I,J              : integer;
  Map1             : array[1..512,1..8] of byte;
  Map2             : array[1..512,1..8] of byte;
  Map1Size         : integer;

{$ I MISC.RDR}

{.PA}
{*****************************************************************************}
{* Miscellaneous Routines                                                    *}
{*****************************************************************************}
procedure SetDTA(var DTA);
  begin
    with Registers do begin
      AH:=$1A;
      DS:=Seg(DTA);
      DX:=Ofs(DTA);
      MsDos(Registers);
      ErrorFlag:=(Flags and $01)<>0;
    end;
  end;

procedure SetDir(Mask : LineType;Attr : byte);
  begin
    SetDTA(DTA);
    with Registers do begin
      AH:=$4E;
      DS:=Seg(Mask);
      DX:=Ofs(Mask)+1;
      CX:=Attr;
      MsDos(Registers);
      ErrorFlag:=(Flags and $01)<>0;
    end;
  end;

function DirEntry : LineType;
  var
    Line           : LineType;
  begin
    Line:='';I:=30;
    repeat
      Line:=Line+Chr(DTA[I]);
      I:=I+1;
    until DTA[I]=0;
    DirEntry:=Line;
    with Registers do begin
      AH:=$4F;
      CX:=22;
      MSDos(Registers);
      ErrorFlag:=(Flags and $01)<>0;
    end;
  end;

procedure ReadKbd;
  begin
    Read(Kbd,Key);
    if KeyPressed then begin
      Read(Kbd,Key);
      Escape:=true;
    end else Escape:=false;
  end;

procedure WriteTime(Time : TimeRec);
  begin
    case Clock of
      0 : if Time.Hour<13 then Write(Time.Hour:2,':')
             else Write((Time.Hour-12):2,':');
      1 : Write(Time.Hour:2,':');
    end;
    if Time.Minute<10 then Write('0');
    Write(Time.Minute);
    if Clock=0 then if Time.Hour>12 then Write('pm') else Write('am')
      else Write('  ');
  end;


{$ I GRAPH.RDR}
{.PA}
{*****************************************************************************}
{* Graphics Routines                                                         *}
{*****************************************************************************}

type
  CharTab14Type    = array[0..127,0..13] of byte;
  CharTab8Type     = array[0..127,0..7] of byte;
  PlaneSet         = set of 0..3;
  FuncType         = (Rot1,Rot2,Rot3,Rot4,Rot5,Rot6,Rot7,_Clr,_And,_Or,_Xor);
  ListType         = array[1..640] of byte;

var
  CharTab14        : ^CharTab14Type;
  CharTab8         : ^CharTab8Type;
  CharSize         : byte;

const
  Colors           : array[0..15] of byte =
    ($00,36,50,54,$3F,$3F,$3F,$3F,$09,$09,$09,$09,$09,$09,$09,$09);

var CurrPlane      : PlaneSet;
procedure SelectPlane(ForPlanes : PlaneSet);
  var
    Data           : byte absolute ForPlanes;
  begin
    port[$3C4]:=$02;
    port[$3C5]:=Data;
    CurrPlane:=ForPlanes;
  end;

procedure ShowPlane(ForPlanes : PlaneSet);
  var
    Data           : byte absolute ForPlanes;
    Q              : byte;
  begin
    Q:=port[$3DA];
    port[$3C0]:=$12;
    port[$3C0]:=Data;
    port[$3C0]:=$20;
  end;

var CurrFunc       : FuncType;
procedure SelectFunc(ForFunc : FuncType);
  begin
    port[$3CE]:=$03;
    if ForFunc in [Rot1..Rot7] then port[$3CF]:=Ord(ForFunc)+1
      else port[$3CF]:=(Ord(ForFunc)-7) shl 3;
    CurrFunc:=ForFunc;
  end;

var CurrMask       : byte;
procedure SetMask(ToMask : byte);
  begin
    port[$3CE]:=$08;
    port[$3CF]:=ToMask;
    CurrMask:=ToMask;
  end;

var
  CursX,CursY      : byte;
  XPos,YPos        : byte;
  XMax,YMax        : byte;

procedure GotoXY(X,Y : integer);
  begin
    CursX:=X; CursY:=Y;
  end;

procedure ConOut(ForChar : char);
  var
    I,Q            : byte;
    CharPos        : integer;
  begin
    case ForChar of
      #8  : if CursX>0 then CursX:=CursX-1;
      #10 : if CursY<YMax then CursY:=CursY+1;
      #13 : CursX:=0;
      else begin
        CharPos:=(CursX+XPos)+(CursY+YPos)*CharSize*80;
        for I:=0 to CharSize-1 do
          case CharSize of
            8  : Mem[$A000:CharPos+I*80]:=CharTab8^[Ord(ForChar),I];
            14 : Mem[$A000:CharPos+I*80]:=CharTab14^[Ord(ForChar),I];
          end;
        if CursX<XMax then CursX:=CursX+1
        else begin
          CursX:=0;
          CursY:=CursY+1;
        end;
      end;
    end;
  end;

function ReadStr(Len : byte) : LineType;
  var
    Line           : LineType;
    I,TempX        : byte;
  begin
    TempX:=CursX;
    for I:=1 to Len do Write(' ');
    CursX:=TempX;
    Line:=''; Write('�');
    repeat
      ReadKbd; Key:=UpCase(Key);
      case Key of
        #32..#126 : if Length(Line)<=Len then begin
          Line:=Line+Key;
          Write(^H,Key,'�');
        end;
        ^H : if Length(Line)>0 then begin
          Write(^H,^H,'� ',^H);
          Line:=Copy(Line,1,Length(Line)-1);
        end;
      end;
    until Key=#13;
    Write(^H,' '); ReadStr:=Line;
  end;

procedure GRWrite(ForStr : linetype;X,Y : integer);
  var
    I,J,Q,
    AdjX,Rot       : byte;
  begin
    AdjX:=X div 8; Rot:=X mod 8;
    for I:=2 to Length(ForStr) do
      for J:=0 to 7 do begin
        Q:=Mem[$A000:(Y+J)*80+AdjX+I-1];
        Mem[$A000:(Y+J)*80+AdjX+I-1]:=
          (CharTab8^[Ord(ForStr[I-1]),J] shl (8-Rot)) or
          (CharTab8^[Ord(ForStr[I]),J] shr Rot);
      end
  end;

procedure GRPlot(X,Y : integer);
  var
    AtByte         : integer;
    Q,AtBit        : byte;
  begin
    AtByte:=Y*80+(X shr 3);
    AtBit:=$80 shr (X and $07);
    SetMask(AtBit);
    Q:=Mem[$A000:AtByte];
    Mem[$A000:AtByte]:=$FF;
    SetMask($FF);
  end;

procedure GRLine(X1,Y1,X2,Y2 : integer);
  var
    Add            : real;
    Dir            : integer;
    XReal,YReal    : real;
  begin
    XReal:=X1; YReal:=Y1;
    if Abs(Y2-Y1)>Abs(X2-X1) then begin
      Add:=(X2-X1)/Abs(Y2-Y1);
      if Y2>Y1 then Dir:=1 else Dir:=-1;
      while Y1<>Y2 do begin
        GRPlot(Trunc(XReal),Y1);
        XReal:=XReal+Add;
        Y1:=Y1+Dir;
      end;
    end else begin
      if X2<>X1 then Add:=(Y2-Y1)/Abs(X2-X1) else Add:=0;
      if X2>X1 then Dir:=1 else Dir:=-1;
      while X1<>X2 do begin
        GRPlot(X1,Trunc(YReal));
        YReal:=YReal+Add;
        X1:=X1+Dir;
      end;
    end;
  end;

procedure Window(X,Y,XSize,YSize : byte);
  begin
    for I:=Y to Y+YSize do
      for J:=0 to CharSize-1 do begin
        SelectPlane([2]);
        FillChar(Mem[$A000:(I*CharSize+J)*80+X],XSize+1,$FF);
        SelectPlane([3]);
        FillChar(Mem[$A000:(I*CharSize+J)*80+X],XSize+1,$00);
      end;
    XPos:=0; YPos:=0; XMax:=79; YMax:=24;
    XPos:=X; YPos:=Y;
    XMax:=XSize; YMax:=YSize;
    CursX:=0; CursY:=0;
  end;

var LastMess       : linetype;
procedure GRMessage(ForStr : linetype; WaitKey : boolean);
  var
    I,J,Left       : integer;
    OXPos,OYPos    : byte;
    OXMax,OYMax    : byte;
  const
    Space : string[50] = '                                                  ';
  begin
    OXPos:=XPos; OYPos:=YPos; OXMax:=XMax; OYMax:=YMax;
    SelectFunc(_Clr);
    SelectPlane([2]);
    if Length(LastMess)>0 then begin
      Window(40-Length(LastMess) shr 1,24,Length(LastMess)-1,1);
      SelectPlane([2,3]);
      Write(Copy(Space,1,Length(LastMess)));
      SelectPlane([3]);
    end;
    LastMess:=ForStr;
    if Length(LastMess)>0 then begin
      Window(40-Length(LastMess) shr 1,24,Length(LastMess)-1,1);
      Write(LastMess);
      if WaitKey then begin
        ReadKbd;
        GRMessage('',false);
      end;
    end;
    XPos:=OXPos; YPos:=OYPos; XMax:=OXMax; YMax:=OYMax;
  end;

function Ask(ForStr : linetype) : boolean;
  begin
    GRMessage(ForStr+' (Y/N)?',true);
    Ask:=UpCase(Key)='Y';
  end;

procedure ToggleGraphics;
  begin
    if GraphicsOn then ShowPlane([0,1]) else ShowPlane([0..3]);
    GraphicsOn:=not(GraphicsOn);
  end;

var
  LastLine         : integer;
  LineSize         : integer;
procedure DispLine( var LinePtr );
  var
    LineNum        : integer absolute LinePtr;
    Line           : array[0..1279] of byte absolute LinePtr;
    count,rept     : integer;
    AtByte         : integer;
    AtBit          : byte;
    ROn,GOn        : boolean;
    RByte,GByte    : byte;
    Size           : integer;
  begin
    AtByte:=LineNum*80; AtBit:=0;
    RByte:=$00; GByte:=$00;
    Count:=2; LastLine:=LineNum;
    SelectFunc(_Clr);
    repeat
      Size:=((Line[Count] and $07) shl 8) or Line[Count+1];
      case (Line[Count] shr 5) and $03 of
        0 : begin ROn:=false; GOn:=false; end;
        1 : begin ROn:= true; GOn:=false; end;
        2 : begin ROn:=false; GOn:= true; end;
        3 : begin ROn:= true; GOn:= true; end;
      end;
      if Size+AtBit<=8 then begin
        if ROn then RByte:=RByte or ($FF shr (8-Size) shl AtBit);
        if GOn then GByte:=GByte or ($FF shr (8-Size) shl AtBit);
        AtBit:=AtBit+Size;
      end else begin
        if ROn then RByte:=RByte or ($FF shl AtBit);
        if GOn then GByte:=GByte or ($FF shl AtBit);
        SelectPlane([0]); Mem[$A000:AtByte]:=RByte;
        SelectPlane([1]); Mem[$A000:AtByte]:=GByte;
        Size:=Size-8+AtBit;
        AtBit:=0; AtByte:=AtByte+1;
        if Size+AtBit>8 then begin
          SelectPlane([0]); if ROn then RByte:=$FF else RByte:=$00;
          FillChar(Mem[$A000:AtByte],Size shr 3,RByte);
          SelectPlane([1]); if GOn then GByte:=$FF else GByte:=$00;
          FillChar(Mem[$A000:AtByte],Size shr 3,GByte);
          AtByte:=AtByte+(Size shr 3); AtBit:=Size and $07;
        end else AtBit:=Size;
        if ROn then RByte:=$FF shr (8-AtBit) else RByte:=$00;
        if GOn then GByte:=$FF shr (8-AtBit) else GByte:=$00;
      end;
      if AtBit=8 then begin
        SelectPlane([0]); Mem[$A000:AtByte]:=RByte;
        SelectPlane([1]); Mem[$A000:AtByte]:=GByte;
        AtByte:=AtByte+1; AtBit:=0;
        RByte:=$00; GByte:=$00;
      end;
      Count:=Count+2;
    until (Line[Count]=$18) or KeyPressed;
    LineSize:=Count+2;
  end;

procedure DrawScale;
  var
    I              : integer;
    WriteVal       : byte;
  begin
    SelectPlane([0,1]); SelectFunc(_Clr);
    for I:=0 to 349 do begin
      WriteVal:=$C0;
      if (I mod 10)=0 then WriteVal:=$F0;
      if (I mod 50)=0 then WriteVal:=$FC;
      if (I mod 100)=0 then WriteVal:=$FF;
      Mem[$A000:I*80]:=WriteVal;
    end;
  end;

procedure InitEGA;
  var
    I,Q            : byte;
    Time           : TimeRec;
  begin
    with Registers do begin  {Set 640 x 350 Hi-Res mode}
      AH:=$00; AL:=$10;
      Intr($10,Registers);
      AX:=$1130; BH:=$02;    {Set address for character table pointer - size 14}
      Intr($10,Registers);
      CharTab14:=Ptr(ES,BP);
      AX:=$1130; BH:=$03;    {Set address for character table pointer - size 8}
      Intr($10,Registers);
      CharTab8:=Ptr(ES,BP);
      AH:=$2C;               {Get Time}
      Time.Hour:=CH; Time.Minute:=CL;
    end;
    for I:=0 to 15 do begin   {Initialize palette registers}
      Q:=port[$3DA];
      port[$3C0]:=I; port[$3C0]:=Colors[I];
    end;
    port[$3C0]:=$20;         {Enable palette registers}
    CharSize:=14; XMax:=79; YMax:=24;
    SelectPlane([2]);
    GotoXY(0,0); Write('TILT  : XXX');
    GotoXY(65,0); Write('TIME : '); WriteTime(Time);
    GotoXY(0,24); Write('RANGE : XXX'); GotoXY(65,24); Write('GAIN  : XXX');
    GotoXY(0,22); Write('H = HELP');
  end;




{$ I SCREEN.RDR}
{.PA}
{*****************************************************************************}
{* Screen Format Routines                                                    *}
{*****************************************************************************}
var
  {Screen Format Flags}
  HelpOn,
  Gfx1On,
  Gfx2On,
  RngMksOn       : boolean;
  RngChng        : boolean;

const
  Circle1  : array[0..175] of byte =
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
  Circle2  : array[25..175] of byte = (   0,
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
  Circle3  : array[62..175] of byte = (   0,
 15, 25, 32, 38, 43, 47, 51, 55, 58, 61, 64, 67, 70, 73, 75, 77,
 80, 82, 84, 86, 88, 90, 92, 94, 95, 97, 99,100,102,103,105,106,
108,109,110,112,113,114,115,116,118,119,120,121,122,123,124,125,
126,127,128,128,129,130,131,132,133,133,134,135,136,136,137,138,
138,139,140,140,141,141,142,142,143,143,144,144,145,145,146,146,
146,147,147,148,148,148,149,149,149,149,150,150,150,150,151,151,
151,151,151,152,152,152,152,152,152,152,152,152,152,152,152,153,
153);
  Circle4  : array[99..175] of byte = (   0,
 10, 19, 25, 30, 34, 38, 41, 44, 47, 49, 51, 54, 56, 58, 60, 62,
 63, 65, 67, 68, 70, 71, 72, 74, 75, 76, 77, 79, 80, 81, 82, 83,
 84, 85, 85, 86, 87, 88, 89, 90, 90, 91, 92, 92, 93, 93, 94, 95,
 95, 96, 96, 97, 97, 97, 98, 98, 98, 99, 99, 99,100,100,100,100,
101,101,101,101,101,101,101,101,101,101,102,102);
  Circle5  : array[136..175] of byte = (  0,
  5, 12, 17, 20, 23, 25, 28, 30, 31, 33, 35, 36, 37, 38, 40, 41,
 42, 42, 43, 44, 45, 46, 46, 47, 47, 48, 48, 49, 49, 49, 50, 50,
 50, 50, 50, 50, 50, 51, 51);

procedure WriteRngMks;
  begin
    SelectFunc(_CLR);
    SelectPlane([2]);
    for I:=175 downto 1 do begin
      for J:=Circle1[I-1] to Circle1[I] do begin
        GRPlot(320+J,I); GRPlot(320-J,I);
        GRPlot(320+J,350-I); GRPlot(320-J,350-I);
      end;
      if I>25 then begin
        for J:=Circle2[I-1] to Circle2[I] do begin
          GRPlot(320+J,I); GRPlot(320-J,I);
          GRPlot(320+J,350-I); GRPlot(320-J,350-I);
        end;
        if I>62 then begin
          for J:=Circle3[I-1] to Circle3[I] do begin
            GRPlot(320+J,I); GRPlot(320-J,I);
            GRPlot(320+J,350-I); GRPlot(320-J,350-I);
          end;
          if I>99 then begin
            for J:=Circle4[I-1] to Circle4[I] do begin
              GRPlot(320+J,I); GRPlot(320-J,I);
              GRPlot(320+J,350-I); GRPlot(320-J,350-I);
            end;
            if I>136 then
              for J:=Circle5[I-1] to Circle5[I] do begin
                GRPlot(320+J,I); GRPlot(320-J,I);
                GRPlot(320+J,350-I); GRPlot(320-J,350-I);
              end;
            end;
          end;
        end;
      end;
    end;

const
  ASin              : array[0..360] of byte = (
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
  ACos              : array[0..360] of byte = (
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

procedure WriteGfx( var At);
  type
    LandMarkRec      = record
      Bear           :   integer;
      Range          :   integer;
      Name           :   array[1..3] of char;
      Nothing        :   byte;
                       end;
    SegmentRec       = record
      Range1         :   integer;
      Bear1          :   integer;
      Range2         :   integer;
      Bear2          :   integer;
                       end;
  var
    LandMark       : array[1..100] of LandMarkRec absolute At;
    Segment        : array[1..1000] of SegmentRec absolute At;
    Count          : integer;
    Min,Max        : integer;
    Adj            : integer;
  begin
    Count:=1; SelectPlane([2]); SelectFunc(_OR);
    Max:=RangeVal[Pic[CurrPic].Range]*10;
    Min:=Max div 7; Adj:=RangeVal[Pic[CurrPic].Range];
    repeat
      with Landmark[Count] do begin
      if (Min<Range) and (Range<Max) then
        if Range>1310 then
          GRWrite(' '+Name+' ',
          300+Trunc(Range*(ASin[Bear]-128.0)/Adj),
          170-Trunc(Range*(ACos[Bear]-128.0)/Adj))
        else
          GRWrite(' '+Name+' ',
          300+Range*(ASin[Bear]-128) div Adj,
          170-Range*(ACos[Bear]-128) div Adj);
      Count:=Count+1;
      end;
    until (Landmark[Count].Bear=0) and (Landmark[Count].Range=0) or (Count>100);
    SelectPlane([2]); SelectFunc(_OR);
    Max:=RangeVal[Pic[CurrPic].Range]*10;
    Adj:=RangeVal[Pic[CurrPic].Range];
    repeat
      with Segment[Count] do begin
        if (Range1<Max) and (Range2<Max) then
          if (Range1>1310) or (Range2>1310) then begin
            GRLine(
              320+Trunc(Range1*(ASin[Bear1]-128.0)/Adj),
              174-Trunc(Range1*(ACos[Bear1]-128.0)/Adj),
              320+Trunc(Range2*(ASin[Bear2]-128.0)/Adj),
              174-Trunc(Range2*(ACos[Bear2]-128.0)/Adj));
          end else
            GRLine(Range1*(ASin[Bear1]-128) div Adj+320,
              174-Range1*(ACos[Bear1]-128) div Adj,
              Range2*(ASin[Bear2]-128) div Adj+320,
              174-Range2*(ACos[Bear2]-128) div Adj);
        Count:=Count+1;
      end;
    until (Segment[Count].Range1=0) and (Segment[Count].Bear1=0) or (Count>512);
  end;

procedure WriteHelp;
  begin
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
    if HelpOn then case Mode of
      Modem : begin
        GotoXY(0,2);
        Writeln('F1�Select Station');
        Writeln('F2�Call Station');
        Writeln('F3�Storage');
        GotoXY(0,19); Write('+ Next Pic');
        GotoXY(0,20); Write('- Prev Pic');
        GotoXY(0,21); Write('ESC�Quit');
      end;
      Interactive : begin
(*      VERSION 2.0
        GotoXY(0,2); Write('F7�Send Picture');
        GotoXY(0,21); Write('ESC�Disconnect');
        GotoXY(0,1); Write('�F1  �F2');
        GotoXY(0,23); Write('�F3  �F4');
        GotoXY(65,23); Write('�F5  �F6');
        END VERSION 2.0 *)
(*      VERSION 2.1 *)
        GotoXY(0,21); Write('ESC�Disconnect');
(*      END VERSION 2.1 *)
      end;
      RxPic : begin
        GotoXY(0,21); Write('ESC�Abort');
      end;
    end;
    if HelpOn then begin
      GotoXY(66,2); Write('G�All Graphics');
      GotoXY(67,3); Write('R�Range Marks');
      GotoXY(73,4); Write('1�Map 1');
      GotoXY(73,5); Write('2�Map 2');
    end else begin
      GotoXY(66,2); Write('              ');
      GotoXY(67,3); Write('             ');
      GotoXY(73,4); Write('       ');
      GotoXY(73,5); Write('       ');
    end;
  end;

procedure WriteParams;
  begin
    SelectFunc(_Clr); SelectPlane([2]);
    if CurrPic>0 then with Pic[CurrPic] do begin
      GotoXY(8,0); Write(TiltVal[Tilt]:3);
      GotoXY(72,0); WriteTime(Time);
      GotoXY(8,24); Write(RangeVal[Range]:3);
      GotoXY(72,24); if Gain<17 then Write(Gain:4) else Write(' PRE');
      if Mode=Interactive then begin
        SelectPlane([0]); GotoXY(36,0);
        case RT of
          0   : Write(' RT OFF ');
          1,2 : Write(' RT ON  ');
        end;
      end;
    end
    else begin
      GotoXY(8,0); Write('XXX');
      GotoXY(72,0); Write('XX:XX  ');
      GotoXY(8,24); Write('XXX');
      GotoXY(72,24); Write(' XXX');
    end;
  end;

procedure ClearScreen;
  begin
    SelectFunc(_Clr);
    for I:=0 to 175 do begin
      FillChar(Mem[$A000:40-(1+Circle1[I] shr 3)+I*80],
        2*(1+Circle1[I] shr 3),0);
      FillChar(Mem[$A000:40-(1+Circle1[I] shr 3)+(350-I)*80],
        2*(1+Circle1[I] shr 3),0);
    end;
  end;

procedure UnWindow;
  begin
    SelectPlane([2,3]); ClearScreen;
    if Gfx1On then WriteGfx(Map1);
    if Gfx2On then WriteGfx(Map2);
    if RngMksOn then WriteRngMks;
    XPos:=0; YPos:=0; XMax:=79; YMax:=24;
  end;





function IOError : boolean;
  var
    Dummy : integer;
  begin
    Dummy:=IOResult;
    if Dummy=0 then begin
      IOError:=false;
    end else begin
      case Dummy of
        $99 : GRMessage('ERROR : Unexpected end of file',true);
        $F0 : GRMessage('ERROR : Disk is full',true);
        $F1 : GRMessage('ERROR : Directory is full',true);
        $F2 : GRMessage('ERROR : File is too big',true);
        $FF : GRMessage('ERROR : Disk changed. Please replace and retry.',true);
      end;
      IOError:=true;
    end;
  end;


{.PA}
{*****************************************************************************}
{* RS232 Routines                                                            *}
{*****************************************************************************}
var
  Buf              : string[255];
  BufBeg, BufEnd   : integer;
  CheckSum         : byte;
  DSave            : integer absolute CSeg:$0006;
  GRBuf            : array[1..1250] of byte;
  LineNum          : integer absolute GRBuf;
  PhoneNum         : string[31];
  POver            : array[1..4] of Gen8Type absolute PhoneNum;
  MapCount         : byte;
  Response         : boolean;
  GfxMatch         : boolean;
  LineAt,WriteAt   : integer;
  BufPtr           : ^BufType;
  BufCount         : integer;
  GRSize           : integer;
  PicSave          : array[-20000..30000] of byte;
  PicSaveAt        : integer;
  PicSize          : integer;

procedure HangUp;

  begin
    Port[ComPort+4]:=$08; Delay(1000); Port[ComPort+4]:=$0B;
  end;

procedure Tx(Charac : char);
  begin
    repeat until (port[ComPort+5] and $20)=$20;
    Port[ComPort]:=ord(Charac);
  end;

procedure Rx(var Charac : char);
  begin
    if BufBeg=BufEnd then
      Charac:=#0
    else begin
      Charac:=Buf[BufBeg];
      BufBeg:=BufBeg+1;
      if BufBeg>255 then BufBeg:=1;
    end; (* if *)
  end;

procedure ResetBuf;
  begin
    BufBeg:=1; BufEnd:=1;
  end; (* ResetBuf *)

procedure SendCom(Command : char; DelTime : integer);
  var
    StartTime, CurrTime : integer;
  begin
    if Mode=Interactive then begin
      Buf:=''; Response:=false;
      Tx('Z'); Delay(15); Tx(Command);
      if (RT=0) and not(Command=SendGraph) then Delay(1000);
      with Registers do begin
        AH:=$2C;
        MsDos(Registers);
        StartTime:=DH*100+DL;
        repeat
          AH:=$2C;
          MsDos(Registers);
          CurrTime:=DH*100+DL;
          IF CurrTime<StartTime THEN CurrTime:=CurrTime+6000;
        until (CurrTime-StartTime>DelTime) OR Response;
      end; (* with *)
      if Command=SendGraph then Mode:=RxGraph;
      if Response then WriteParams
      else begin
        Sound(440); Delay(10); NoSound;
      end;
    end;
  end;

procedure SetParams(var ForBuf; var Params : PicRec);
  var
    Buf            : string[10] absolute ForBuf;
    Comp           : Gen8Type absolute Map1;
  begin
    CheckSum:=0;
    for I:=2 to 9 do CheckSum:=CheckSum+Ord(Buf[I]);
    Response:=CheckSum=Ord(Buf[10]);
    if (Buf[1]='Q') and Response then
      with Params do begin
        Gain:=(byte(Buf[2]) shr 4) +1;
        Tilt:=12-(byte(Buf[3]) and $0f);
        If (byte(Buf[3]) and (1 shl 5)) <> 0
          then Gain := 17;
        case (byte(Buf[4]) and $38) of
          $08 : Range:=1;
          $30 : Range:=2;
          $00 : Range:=3;
          $20 : Range:=4;
          $28 : Range:=0;
        end;
        Time.Hour:=(ord(Buf[6])-48)*10+(ord(Buf[7])-48);
        Time.Minute:=(ord(Buf[8])-48)*10+(ord(Buf[9])-48);
        if (byte(Buf[3]) and $80)=$00 then RT:=2
          else if (byte(Buf[3]) and $10)=$00 then RT:=0
            else RT:=1;
      end;
    if (Buf[1]='G') and Response then begin
      I:=2;
      while (Comp[I-1]=Ord(Buf[I])) and (I<9) do I:=I+1;
      GfxMatch:=not(I<9);
    end;
    Buf:='';
  end;


var
  data             : byte;
  RI               : integer;

procedure RS232Interupt;
  begin
    inline($1E/       {PUSH DS}
           $50/       {PUSH AX}
           $53/       {PUSH BX}
           $51/       {PUSH CX}
           $52/       {PUSH DX}
           $57/       {PUSH DI}
           $56/       {PUSH SI}
           $06/       {PUSH ES}
           $8C/$C8/   {MOV AX,CS}
           $8E/$D8/   {MOV DS,AX}
           $A1/DSave/ {MOV AX,DSave}
           $8E/$D8/$FB);  {MOV DS,AX}
    if port[ComPort+2]=$04 then begin
      data:=port[ComPort];
      port[$20]:=$20; {EOI for 8529}
      case Mode of
        Modem :
        begin
          Buf[BufEnd]:=chr(data);
          BufEnd:=BufEnd+1;
          if BufEnd>255 then BufEnd:=1;
        end;
        Interactive,WaitPic :
        begin
          Buf:=Buf+chr(data);
          if Length(Buf)=10 then begin
            SetParams(Buf,Pic[CurrPic]);
            Delay(10);
            Tx('A');
            Buf:='';
          end;
          if Mode=WaitPic then
            if (Buf[1]=#$FF) and (Buf[2]=#$FE) and (Buf[3]=#$FD) then begin
              Mode:=RxPic; GRSize:=0;
              CheckSum:=0;
            end;
        end;
RxPic
        begin
          GRSize:=GRSize+1;
          GRBuf[GRSize]:=data;
          if (GRSize and $01)=$01 then
          if (GRBuf[GRSize-1]=$18) and
            (GRBuf[GRSize-2]=$18) and (GRSize>6) then begin
            CheckSum:=0;
            for RI:=1 to GRSize-1 do CheckSum:=CheckSum+GRBuf[RI];
            LineNum:=LineNum div 54;
            if (LineNum>=LastLine) and (LineNum<=352)
              and (CheckSum=GRBuf[GRSize]) then begin
              Tx('A');
              Move(GRBuf,PicSave[PicSaveAt],GRSize-1);
              LineAt:=PicSaveAt;
              PicSaveAt:=PicSaveAt+GRSize-1;
              Tx('O');
              GRSize:=0;
            end else begin
              Tx(#0);
              GRSize:=0;
            end;
          end;
        end;
        RxGraph :
        begin
          BufPtr^[BufCount]:=data; BufCount:=BufCount+1;
          if BufCount=9 then begin
            CheckSum:=0;
            for RI:=1 to 8 do CheckSum:=CheckSum+BufPtr^[RI];
            if {CheckSum=BufPtr^[BufCount]}true then begin
              if (BufPtr^[1]=0) and (BufPtr^[2]=0) and
                (BufPtr^[3]=0) and (BufPtr^[4]=0) then
              begin
                Sound(440); Delay(100); NoSound;
                MapCount:=MapCount+1;
                if MapCount=2 then begin
                  Map1Size:=OFS(BufPtr^)-OFS(Map1);
                  BufPtr:=Ptr(Seg(Map2),Ofs(Map2)-8);
                end;
              end;
              if Ofs(BufPtr^)<Ofs(Map1Size)-16 then
                BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+8);
              BufCount:=1;
              Delay(5);
              Tx('A');
            end else Tx(#0);
            BufCount:=1;
          end;
        end;
      end; (* case *)
    end (* if *)
    else begin
      if port[ComPort+2]=$00 then
        if (port[ComPort+6] and $88)=$08 then
          Mode:=Modem;
      port[$20]:=$20; {EOI for 8529}
    end;
    inline($07/       {POP ES}
           $5E/       {POP SI}
           $5F/       {POP DI}
           $5A/       {POP DX}
           $59/       {POP CX}
           $5B/       {POP BX}
           $58/       {POP AX}
           $1F);      {POP DS}
    inline($FB);      {STI}
    inline($CF);      {IRET}
  end;

procedure InitRS232; {& interrupt routine}
  begin
    DSave:=DSeg; Buf:='';
    with Registers do begin
      AH:=$25;
      if ComPort=$3F8 then AL:=$0C else AL:=$0B;
      DX:=Ofs(RS232Interupt)+7;
      DS:=CSeg;
      Intr($21,Registers);
    end;
    for I:=ComPort to ComPort+6 do J:=port[I];
    Port[ComPort+3]:=$80; {Set baud rate access bit}
    Port[ComPort]:= 48; {Set baud rate (2400 = 48)}
    Port[ComPort+1]:=$00;
    Port[ComPort+3]:=$03; {Set Line Control Data (8 data,1 stop,0 parity)}
    Port[ComPort+1]:=$09;
    Port[ComPort+4]:=$0B; {Set DTR & RTS high}
    UsrOutPtr:=Ofs(Tx);
  end;


{.PA}
{*****************************************************************************}
{* Storage                                                                   *}
{*****************************************************************************}
procedure FetchPic;
  var PicFile      : file;
  begin
    WriteParams;
    if CurrPic=0 then begin
      SelectPlane([0,1]);
      ClearScreen;
      EXIT;
    end;
    if Gfx1On or Gfx2On then begin
      SelectPlane([2]);
      ClearScreen;
      if Gfx1On then WriteGfx(Map1);
      if Gfx2On then WriteGfx(Map2);
      if RngMksOn then WriteRngMks;
    end;
    Assign(PicFile,Pic[CurrPic].FileName);
    ReSet(PicFile,1);
    if IOError then GRMessage('ERROR : Cannot find that picture file',true)
    else begin
      BlockRead(PicFile,PicSave,FileSize(PicFile)+1,PicSize);
      PicSize:=PicSize-20000;
      BufPtr:=ADDR(PicSave); LastLine:=0;
      while (LastLine<351) do begin
        DispLine(BufPtr^);
        BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+LineSize);
      end;
      Close(PicFile);
    end;
  end;

procedure InsertPic(ForPic : PicRec);
var
  Count : integer;
  Later : boolean;
begin
  Count:=0; Later:=false;
  repeat
    Count:=Count+1;
    if Pic[Count].FileDate>ForPic.FileDate then
      Later:=true
    else if Pic[Count].FileDate=ForPic.FileDate then
      if Pic[Count].FileTime>ForPic.FileTime then
        Later:=true;
  until Later or (Count>MaxPic);
end;

procedure SavePic(Size : integer);
  var PicFile      : file;
  begin
    with Pic[CurrPic] do begin
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
      ReWrite(PicFile,1); if IOError then Exit;
      BlockWrite(PicFile,PicSave,Size); if IOError then Exit;
      Close(PicFile);
      GRMessage('',false);
    end;
  end;


procedure Storage;
  var
    SelectPic,
    TopPic     : integer;
    Count      : integer;
    PicFile    : file;
  begin
    Window(27,1,25,21);
    Write('�������� STORAGE ���������');
    Write('  �Time� �Tilt�Range�Gain�');
    GotoXY(0,18);
    Write('��������������������������');
    Writeln(' RET � Select Picture');
    Writeln(' F1  � Delete Picture');
    Writeln(' ESC � Exit');
    SelectPic:=CurrPic;
    TopPic:=MaxPic+1;
    repeat
      if (SelectPic<TopPic) or (SelectPic>TopPic+15) then begin
        if SelectPic<=8 then TopPic:=1 else TopPic:=SelectPic-8;
        GotoXY(0,2);
        for Count:=TopPic to TopPic+15 do
          if Count<=MaxPic then with Pic[Count] do begin
            Write('  ');
            WriteTime(Time);
            Write(TiltVal[Tilt]:4);
            Write(RangeVal[Range]:6);
            if Gain<17 then Write(Gain:5) else Write('  PRE');
            WriteLn;
          end else WriteLn('                        ');
      end;
      GotoXY(0,SelectPic-TopPic+2);
      if SelectPic<>0 then Write('->');
      ReadKbd;
      case Key of
        '+' : if SelectPic<MaxPic then SelectPic:=SelectPic+1;
        '-' : if SelectPic>0 then SelectPic:=SelectPic-1;
        ';' : if SelectPic>0 then if Ask('DELETE THIS PICTURE?') then begin
                Assign(PicFile,Pic[SelectPic].FileName);
                Erase(PicFile);
                for Count:=SelectPic+1 to MaxPic do Pic[Count-1]:=Pic[Count];
                TopPic:=MaxPic+1;
                MaxPic:=MaxPic-1;
              end;
      end;
      Write(^M,'  ');
    until (Key=^[) or (Key=^M);
    UnWindow;
    if Key=^M then begin
      CurrPic:=SelectPic;
      FetchPic;
    end;
    Key:=#0;
  end;

procedure LoadStation;
  var
    MapFile        : file;
    PhoneFile      : text;
    PicName        : string[20];
    PicVal         : array[0..7] of byte absolute PicName;
  begin
    ChDir(StationName); if IOError then Exit;
    SelectPlane([2]);
    GotoXY(68,21); Write(StationName:12);
    Assign(PhoneFile,'PHONENUM.TXT');
    ReSet(PhoneFile);
    if IOError then
      PhoneNum:=''
    else begin
      Readln(PhoneFile,PhoneNum);
      Close(PhoneFile); if IOError then Exit;
    end;
    Assign(MapFile,'MAP1.DAT');
    Reset(MapFile);
    if IOError then
      GRMessage('WARNING : No map found for '+StationName+'.',true)
    else begin
      BlockRead(MapFile,Map1,FileSize(MapFile));
      Close(MapFile);
    end;
    Assign(MapFile,'MAP2.DAT');
    Reset(MapFile);
    if not IOError then begin
      BlockRead(MapFile,Map2,FileSize(MapFile));
      Close(MapFile);
    end;
    SetDir('????????.PIC'+#0,$00);
    MaxPic:=0;
    while not ErrorFlag do begin
      MaxPic:=MaxPic+1;
      PicName:=DirEntry;
      with Pic[MaxPic] do begin
        FileName:=PicName;
        Time.Hour:=(PicVal[1]-48)*10+PicVal[2]-48;
        Time.Minute:=(PicVal[3]-48)*10+PicVal[4]-48;
        Tilt:=PicVal[5]-65; Range:=PicVal[6]-65;
        Gain:=PicVal[7]-64;
      end;
    end;
    CurrPic:=0;
  end;

procedure CallStation;
  var
    ModemMess : char;
  begin
    if PhoneNum='' then begin
      if StationName<>'' then Mode:=Interactive;
      Exit;
    end;
    Mode:=Modem;
    case ModemType of
      0 : begin
            GRMessage('DIALING - '+PhoneNum,false);
            Write(Usr,'ATDT',PhoneNum,^M);
          end;
      1 : begin
            ResetBuf;
            Write(Usr,^E); Delay(50);
            Write(Usr,^M); Delay(50);
            Write(Usr,'D',PhoneNum,^M);
          end;
    end;
    ResetBuf;
    repeat
      Rx(ModemMess);
      case ModemMess of
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
      end;
      if ModemMess in ['A','D','R'] then ModemMess:=#0;
    until (ModemMess>' ') or KeyPressed;
    if ModemMess in ['1','L'] then Mode:=Interactive
    else begin
      ReadKbd; GRMessage('',false); HangUp;
    end;
  end;

var
  StatChar       : char;
  MaxChar        : char;
  Stat           : array['A'..'M'] of string[12];

procedure SelectStation;

  procedure AddStation;
    var
      PhoneFile : text;
      NewName   : string[12];
      NewPhone  : string[50];
    begin
      GotoXY(0,12);
      Write(' NAME :           ');
      GotoXY(8,12);
      NewName:=ReadStr(8)+'.STA';
      if NewName='' then Exit;
      Writeln(^M,' PHONE NUM :      ');
      NewPhone:=ReadStr(40);
      MkDir(NewName);
      if IOResult=0 then begin
        if NewPhone<>'' then begin
          ChDir(NewName);
          Assign(PhoneFile,'PHONENUM.TXT');
          ReWrite(PhoneFile);
          if IOResult=0 then begin
            Writeln(PhoneFile,NewPhone);
            Close(PhoneFile);
          end;
          ChDir('..');
        end;
      end else begin
        GRMessage('UNABLE TO CREATE DIRECTORY',true);
      end;
    end;

  procedure DelStation;
    var
      DelFile : file;
      StatKey : char;
    begin
      GRMessage('STATION LETTER TO DELETE?',true);
      StatKey:=UpCase(Key);
      if (StatKey>='A') and (StatKey<=MaxChar) then
        if Ask('DELETE '+Stat[StatKey]+'. CONTINUE') then begin
          GRMessage('DELETING STATION '+Stat[StatKey],false);
          ChDir(Stat[StatKey]);
          if IOResult<>0 then Exit;
          SetDir('????????.???'+#0,$00);
          while not ErrorFlag do begin
            Assign(DelFile,DirEntry);
            Erase(DelFile);
          end;
          ChDir('..');
          RmDir(Stat[StatKey]);
          GRMessage('',false);
        end;
    end;

  begin
    if StationName<>'' then ChDir('..');
    repeat
      Window(27,1,25,14);
      GotoXY(0,0);
      Write('����� SELECT STATION �����');
      StatChar:='A'; SetDir('????????.STA'+#0,$10);
      while not ErrorFlag do begin
        Stat[StatChar]:=DirEntry;
        Writeln(' ',StatChar,' � ',Stat[StatChar]:12);
        StatChar:=Succ(StatChar);
      end;
      MaxChar:=Pred(StatChar);
      GotoXY(0,11);
      Write('��������������������������');
      Writeln(' F1  � Add station');
      Writeln(' F2  � Remove station');
      Writeln(' ESC � Exit');
      ReadKbd; Key:=UpCase(Key);
      if Escape then begin
        case Key of
          ';' : AddStation;
          '<' : DelStation;
        end;
        Key:=#0;
      end;
    until Key in [^[,'A'..'M'];
    UnWindow;
    if (Key>='A') and (Key<=MaxChar) then begin
      Gfx1On:=false; Gfx2On:=false;
      RngMksOn:=false;
      SelectPlane([0..3]); ClearScreen;
      StationName:=Stat[Key];
      LoadStation;
      FetchPic;
    end else if StationName<>'' then ChDir(StationName);
    Key:=#0;
  end;


{.PA}
{*****************************************************************************}
{* Screen Dump                                                               *}
{*****************************************************************************}
var
  PrData           : array[0..79,0..2] of byte;
  PrI,PrJ,PrK      : integer;
  PrQ,RemCount     : byte;
  OldPrtScSeg,
  OldPrtScOfs      : integer;
procedure ColorJetPrtSc;
  label
    AbortPrtSc;
  begin
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    RemCount:=0;
    for PrI:=0 to 359 do begin
      for PrJ:=0 to 79 do begin
        if KeyPressed then begin
          ReadKbd;
          if Ask('ABORT SCREEN DUMP') then goto AbortPrtSc;
        end;
        for PrQ:=0 to 2 do begin
          port[$3CE]:=$04; port[$3CF]:=PrQ;
          PrData[PrJ,PrQ]:=Mem[$A000:PrI*80+PrJ];
        end;
        PrQ:=not(PrData[PrJ,0] or PrData[PrJ,1] or PrData[PrJ,2]);
        PrData[PrJ,2]:=not(PrData[PrJ,2]) or PrQ;
        PrData[PrJ,0]:=PrData[PrJ,0] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,1]:=PrData[PrJ,1] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,2]:=PrQ;
      end;
      repeat
        if RemCount>=48 then RemCount:=RemCount-48;
        Write(Lst,Chr($1B),Chr($5B),Chr($4F),Chr(245),Chr(0));
        Write(Lst,Chr($80),Chr($1F),Chr($00),Chr(100),Chr(96));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,0]));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,1]));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,2]));
        Write(Lst,#0);
        RemCount:=RemCount+13;
      until RemCount<48;
    end;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  end;

const
  Pat : array[0..1,1..3] of byte = (($22,$55,$FF),($88,$AA,$FF));

var
  PrGrn,PrYel,PrRed,PrWhite : byte;

procedure EpsonMX80PrtSc;
  label
    AbortPrtSc;
  begin
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    Write(Lst,#27,#65,#8,#27,#50);
    port[$3CE]:=$05; port[$3CF]:=$08;
    for PrI:=0 to 79 do begin
      Write(Lst,#27,'K',#224,#1);
      RemCount:=0; PrJ:=349;
      for PrK:=0 to 479 do begin
        if KeyPressed then begin
          ReadKbd;
          if Ask('ABORT SCREEN DUMP') then goto AbortPrtSc;
        end;
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
        if RemCount>=8 then RemCount:=RemCount-8 else PrJ:=PrJ-1;
      end;
      Write(Lst,^M,^J);
    end;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  end;


{.PA}
{*****************************************************************************}
{* Initialization and Configuration                                          *}
{*****************************************************************************}
procedure Initialize;
  begin
    FillChar(Mode,Ofs(OldPrtScOfs)+20-Ofs(Mode),0);
    OldCon:=ConOutPtr;
    ConOutPtr:=Ofs(ConOut);
    GraphicsOn:=true;
    InitEGA;
    InitRS232;
    if ComPort=$3F8 then port[$21]:=port[$21] and not(1 shl 4)
    else port[$21]:=port[$21] and not(1 shl 3);
    Port[ComPort+1]:=$09;
    case ModemType of
      0 : Write(Usr,'AT &F &C1 &D2 L M1 E V X4',^M);
      1 : begin
            Write(Usr,^E,^M,^E,^M); Delay(100);
            Write(Usr,'O21122211211111112112',^M);
          end;
    end;
    with Registers do begin
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
    end;
    ChDir(DirPath);
    Pic[0].Range:=0;
    StationName:='';
    MaxPic:=0;
    HelpOn:=true; WriteHelp;
  end;

procedure DeInit;
  begin
    if StationName<>'' then ChDir('..');
    port[ComPort+4]:=$08;        {DTR & RTS off}
    port[ComPort+1]:=$00;        {Disable any interrupts}
    port[$21]:= port[$21] or (1 shl 4);
    with Registers do begin
      AH:=$25;
      AL:=$05;
      DX:=OldPrtScOfs;
      DS:=OldPrtScSeg;
      Intr($21,Registers);
    end;
  end;

procedure Config;
  var
    ProgFile         : file of byte;
    ProgDir          : string[20];
  begin
    SelectFunc(_Clr);
    Window(24,1,28,8);
    Write('���������� OPTIONS ����������');
    Write(' F1: Modem   =               ');
    Write(' F2: Serial  =               ');
    Write(' F3: Clock   =               ');
    Write(' F4: Printer =               ');
    Write(' F5: Directory Path =        ');
    Write('                             ');
    Write(' F10: Update disk and exit   ');
    Write(' ESC: Exit option menu       ');
    repeat
      GotoXY(15,1);
      if ModemType=0 then Write('Hayes Compat') else Write('Racal-Vadic ');
      GotoXY(15,2); if ComPort=$3F8 then Write('COM1:') else Write('COM2:');
      GotoXY(15,3); if Clock=0 then Write('12 hour') else Write('24 hour');
      GotoXY(15,4);
      case Printer of
        0 : Write('Epson MX80  ');
        1 : Write('Color InkJet');
      end;
      GotoXY(5,6); Write(DirPath);
      ReadKbd;
      case Key of
        ';' : ModemType:=(ModemType+1) mod 2;
        '=' : Clock:=(Clock+1) mod 2;
        '<' : if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
        '>' : Printer:=(Printer+1) mod 2;
        '?' : begin
          GotoXY(5,6); Write('                        ');
          GotoXY(5,6); DirPath:=ReadStr(22);
          if (Length(DirPath)>1) and (DirPath[Length(DirPath)]='\')
            and (DirPath[Length(DirPath)-1]<>':') then
            DirPath:=Copy(DirPath,1,Length(DirPath)-1);
        end;
        'D' : begin
          Window(24,11,28,1);
          Writeln('PROGRAM FILE DIRECTORY?');
          ProgDir:=ReadStr(20);
          UnWindow;
          GRMessage('UPDATING PROGRAM FILE...',false);
          ChDir(ProgDir);
          Assign(ProgFile,'RADAR.COM');
          ReSet(ProgFile);
          if not IOError then begin
            Seek(ProgFile,Ofs(DirPath)-256);
            for I:=Ofs(DirPath) to Ofs(Clock) do
              Write(ProgFile,Mem[CSeg:I]);
            Close(ProgFile);
          end else GRMessage('PROGRAM FILE NOT FOUND',true);
          GRMessage('',false);
          Key:=#27;
        end;
      end;
    until Key=#27;
    Key:=#0;
    DeInit;
    Initialize;
  end;

{.PA}
{*****************************************************************************}
{* Main Routines                                                             *}
{*****************************************************************************}
procedure ExecCom;
  begin
    case UpCase(Key) of {Process regular key codes}
      'G'  : ToggleGraphics;
      'R'  : begin
               RngMksOn:=not RngMksOn;
               if RngMksOn then WriteRngMks
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if Gfx1On then WriteGfx(Map1);
                 if Gfx2On then WriteGfx(Map2);
               end;
             end;
      'H'  : begin
               HelpOn:=not HelpOn;
               WriteHelp;
             end;
      '1'  : if StationName<>'' then begin
               Gfx1On:=not Gfx1On;
               if Gfx1On then WriteGfx(Map1)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx2On then WriteGfx(Map2);
               end;
             end;
      '2'  : if StationName<>'' then begin
               Gfx2On:=not Gfx2On;
               if Gfx2On then WriteGfx(Map2)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx1On then WriteGfx(Map1);
               end;
             end;
    end;
  end;

procedure RxGraphLoop;
  var
    MapFile : file;
  begin
    BufPtr:=Addr(Map1); BufCount:=1; MapCount:=0;
    SendCom(SendGraph,150);
    if not Response then Exit;
    Mode:=RxGraph;
    GRMessage('ONE MOMENT PLEASE... RECEIVING MAP OVERLAY',false);
    repeat
      if KeyPressed then begin
        ReadKbd;
        if Key=#27 then if Ask('ABORT MAP OVERLAY RECEPTION') then Key:=^Q;
      end;
    until (Key=^Q) or (MapCount>3) or (Mode=Modem);
    If Key=^Q then begin
      Tx('Y'); Tx('Y');
    end;
    GRMessage('SAVING MAP OVERLAY...',false);
    Assign(MapFile,'MAP1.DAT');
    ReWrite(MapFile,1);
    If not IOError then begin
      BlockWrite(MapFile,Map1,Map1Size);
      Close(MapFile);
    end;
    Assign(MapFile,'MAP2.DAT');
    ReWrite(MapFile,1);
    If not IOError then begin
      BlockWrite(MapFile,Map2,Ofs(BufPtr^)-Ofs(Map2)+8);
      Close(MapFile);
    end;
    GRMessage('',false);
    Mode:=Interactive; Key:=#0;
  end;


var
  PictureSaved : boolean;

procedure RxPicLoop;
  var
    AbortPending   : boolean;
    ContWrite      : boolean;
  begin
    WriteHelp;
    SendCom(SendPic,200);
    if not Response then Exit;
    SelectPlane([0,1]); ClearScreen;
    GRMessage('WAITING FOR PICTURE',false);
    DrawScale;
    Mode:=WaitPic; BufPtr:=Addr(GRBuf);
    LastLine:=0; AbortPending:=false;
    repeat
      if KeyPressed then begin
        ReadKbd;
        ExecCom;
        if Key=#27 then if Ask('ABORT PICTURE') then Key:=^Q;
        GRMessage('WAITING FOR PICTURE',false);
      end;
    until (Key=^Q) or (Mode=RxPic);
    if Mode=RxPic then begin
      WriteAt:=-20000; LineAt:=-20001; PicSaveAt:=-20000;
      GRMessage('RECEIVING PICTURE',false);
      repeat
        repeat
          inline($FA); ContWrite:=LineAt>=WriteAt; inline($FB);
          if ContWrite then begin
            DispLine(PicSave[WriteAt]);
            WriteAt:=WriteAt+LineSize;
          end;
        until not ContWrite;
        if KeyPressed then begin
          ReadKbd;
          if AbortPending then
            if UpCase(Key)='Y' then begin
              Tx('Y'); Tx('Y');
              GRMessage('PICTURE ABORTED',true);
              Tx('Y');
              Key:=^Q;
            end else begin
              GRMessage('RECEIVING PICTURE',false);
              AbortPending:=false;
            end
          else begin
            ExecCom;
            if Key in ['1','2','G','R','H'] then
              GRMessage('RECEIVING PICTURE',false);
            if Key=#27 then begin
              AbortPending:=true;
              GRMessage('ABORT PICTURE? (Y/N)',false);
            end;
          end;
        end;
      until (Key=^Q) or (LastLine>=352) or (Mode=Modem);
      if LastLine>=352 then begin
        if Mode<>Modem then begin
          HangUp;
          Delay(500);
          Mode:=Modem;
        end;
        GRMessage('SAVING PICTURE...',false);
        SavePic(PicSaveAt+20000);
        PictureSaved:=true;
      end else begin
        Mode:=Interactive;
        PictureSaved:=false;
      end;
    end;
    GRMessage('',false);
    Key:=#0;
    WriteHelp;
  end;


procedure InterLoop;
  label Abort;
  begin
    WriteHelp;
    MaxPic:=MaxPic+1;
    CurrPic:=MaxPic;
    PictureSaved:=false;
    SelectPlane([0,1]);
    ClearScreen;
    Buf:=''; SendCom('X',150);
    if not Response then SendCom('X',150);
    if not Response then SendCom('X',150);
    if not Response then SendCom('X',150);
    if not Response then begin
      GRMessage('NO RESPONSE. PRESS ANY KEY',true);
      HangUp;
      goto Abort;
    end;
    SelectPlane([3]); GotoXY(73,22); Write('ON LINE');
    SendCom(CheckGraph,150);
    if Response and not GfxMatch then RxGraphLoop
    else GRMessage('',false);
(*  VERSION 2.0 *)
    repeat
      ReadKbd;
      if Escape then
        case Key of              {Process extended key codes}
          #59  : SendCom(TiltUp,150);
          #60  : SendCom(TiltDown,150);
          #61  : begin
                   SendCom(RangeUp,300);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Map1);
                     if Gfx2On then WriteGfx(Map2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #62  : begin
                   SendCom(RangeDown,300);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Map1);
                     if Gfx2On then WriteGfx(Map2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #63  : SendCom(GainUp,150);
          #64  : SendCom(GainDown,150);
          #65  : RxPicLoop;
        end
      else ExecCom;
      if Key=#27 then if Ask('DISCONNECT STATION') then Key:=^Q;
    until (Key=^Q) or (Mode=Modem);
(*  END VERSION 2.0 *)
(*  VERSION 2.1 
    RxPicLoop;
(*  END VERSION 2.1 *)
    Abort:
    if Mode<>Modem then HangUp; Key:=#0;
    if not PictureSaved then begin
      MaxPic:=MaxPic-1;
      CurrPic:=0;
    end;
    SelectPlane([3]); GotoXY(73,22); Write('       ');
    Mode:=Modem;
    WriteHelp;
  end;

procedure ModemLoop;
  begin
    repeat
      ReadKbd;
      if Escape then
        case Key of
          #59 : begin
                  SelectStation;
                  if Mode=Interactive then InterLoop;
                end;
          #60 : begin
                  CallStation;
                  if Mode=Interactive then InterLoop;
                end;
          #61 : Storage;
          ^X  : ConFig;
         end
      else begin
        case Key of
          '+' : if CurrPic<MaxPic then CurrPic:=CurrPic+1;
          '-' : if CurrPic>0 then CurrPic:=CurrPic-1;
          else ExecCom;
        end;
        if Key in ['+','-'] then FetchPic;
      end;
      if Key=#27 then if Ask('QUIT PROGRAM') then Key:=^Q;
    until Key=^Q;
  end;

var
  OldDir : string[40];

begin
  GetDir(0,OldDir);
  Initialize;
  (*$I CUSTOM.PAS *)
  Window(20,15,41,6);
  Write('����������������������������������������ͻ');
  Write('�  ELLASON E300 RADAR TERMINAL, ver 2.1  �');
  Write('�            Revision 1/14/88            �');
  Write('�           Copyright (C) 1987           �');
  Write('�               D. G. Lane               �');
  Write('�           All rights reserved          �');
  Write('����������������������������������������ͼ');
  GRMessage('PRESS ANY KEY',true);
  UnWindow;
  SelectStation;
  ModemLoop;
  DeInit;
  TextMode;
  ChDir(OldDir);
end.

{.L-}
(**********************************)
(* DID YOU JUST CHANGE SOMETHING? *)
(*                                *)
(*    IF SO, CHANGE THE DATE!!!   *)
(*           ---------------      *)
(**********************************)
{.L+}