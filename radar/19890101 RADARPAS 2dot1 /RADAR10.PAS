{.HE%F - %D update}
{.FOpage %#}
{.LW79}
{.N+}
{$C+,V-,I-,R-,U-,K-}

Program E300_Radar_Terminal; {version 1.0}

{
  Copyright (C) 1985 by Derek Lane.

  This program allows an IBM PC to be used as a remote
  terminal to an Ellason 300 Color Weather Radar system.
  It allows the user to dial up the radar, change the
  parameters which the radar makes the picture at,
  and then download the picture onto the IBM's screen.
  It also automatically downloads a map overlay from
  the radar, which the user can turn on or off.

  Version 1.1 is a minor modification which disables
  the function to change the radar's parameters, so
  that the remote operate can not alter the radar's
  state in any way.  The specific change to create
  version 1.1 is to comment lines in procedure InterLoop
  marked 1.0 and uncomment lines marked 1.1.

}

const
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

  TiltX            = 9; TiltY          = 1;
  TimeX            = 74; TimeY         = 1;
  RangeX           = 9; RangeY         = 25;
  GainX            = 74; GainY         = 25;

  MinRange         = 0; MaxRange       = 4;
  MinGain          = 1; MaxGain        = 17;
  MinTilt          = 0; MaxTilt        = 11;

  RangeVal         : array[MinRange..MaxRange] of byte =
                       (10,25,50,100,200);
  TiltVal          : array[MinTilt..MaxTilt] of byte =
                       (0,1,2,3,4,5,6,8,10,12,15,20);

{Messages}
  WaitMessage      : string[19] = 'WAITING FOR PICTURE';
  RxMessage        : string[17] = 'RECEIVING PICTURE';
  RxGrMessage      : string[42] = 'ONE MOMENT PLEASE... RECEIVING IDENTIFIERS';
  AskAbort         : string[13] = 'ABORT PICTURE';
  AbortMessage     : string[15] = 'PICTURE ABORTED';
  AskGrAbort       : string[26] = 'ABORT IDENTIFIER RECEPTION';
  GrAbortMessage   : string[28] = 'IDENTIFIER RECEPTION ABORTED';
  NotOnMessage     : string[24] = 'NOT ON-LINE WITH STATION';

type
  LineType         = string[80];

  Gen8Type         = array[1..8] of byte;

  Gen8Array        = array[1..500] of Gen8Type;

  ModeType         = (Modem,Interactive,WaitPic,RxPic,RxGraph);

  BufType          = array[1..2000] of byte;

  TimeRec          = record
    Hour           :   0..23;
    Minute         :   0..59;
                     end;

  RadarParams      = record
    Station        :   integer;
    Time           :   TimeRec;
    Range          :   MinRange..MaxRange;
    Tilt           :   MinTilt..MaxTilt;
    Gain           :   MinGain..MaxGain;
    RT             :   byte;
                     end;

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

var
  CurrentParams    : RadarParams;
  OldDir           : string[24];
  StatName         : string[12];
  StatFile         : file of Gen8Type;
  Mode             : ModeType;
  Land1            : array[1..73] of LandMarkRec;
  Seg1             : array[1..500] of SegmentRec;
  Land2            : array[1..73] of LandMarkRec;
  Seg2             : array[1..500] of SegmentRec;
  GPtr             : ^Gen8Array;


{Mode Flags}
  AutoOn           : boolean;
  ViewSequence     : boolean;
  ErrorFlag        : boolean;
  GraphicsOn       : boolean;
  OldCon           : integer;

{Miscellaneous Variables}
  Registers        : RegisterType;
  Key              : char;
  DTA              : array[0..127] of byte;
  Mask             : LineType;
  Escape           : boolean;
  I,J              : integer;


{.PA}
{*****************************************************************************}
{* Miscellaneous Routines                                                    *}
{*****************************************************************************}

function IOError : integer;
  var
    IOTemp         : integer;
    IOPerm         : integer;
  begin
    IOTemp:=IOResult;
    if IOTemp<>0 then IOPerm:=IOTemp;
    IOError:=IOPerm;
  end;


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


procedure SetDir;
  begin
    SetDTA(DTA);
    with Registers do begin
      AH:=$4E;
      DS:=Seg(Mask);
      DX:=Ofs(Mask)+1;
      CX:=22;
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


function ReadStr(Len : byte) : LineType;
  var
    Line           : LineType;
  begin
    Line:=''; Write('Û');
    repeat
      ReadKbd; Key:=UpCase(Key);
      if Length(Line)>=Len then begin
        Sound(440); Delay(50); NoSound;
        if Key<>^M then Key:=#0;
      end;
      case Key of
        #32..#126 : begin
          Line:=Line+Key;
          Write(^H,Key,'Û');
        end;
        ^H : if Length(Line)>0 then begin
          Write(^H,^H,'Û ',^H);
          Line:=Copy(Line,1,Length(Line)-1);
        end;
      end;
    until Key=#13;
    Write(^H,' '); ReadStr:=Line;
  end;


{.PA}
{*****************************************************************************}
{* Graphics Routines                                                         *}
{*****************************************************************************}

type
  CharTab14Type    = array[0..255,0..13] of byte;
  CharTab8Type     = array[0..255,0..7] of byte;
  PlaneSet         = set of 0..3;
  StringType       = string[80];
  FuncType         = (Rot1,Rot2,Rot3,Rot4,Rot5,Rot6,Rot7,_Clr,_And,_Or,_Xor);
  ListType         = array[1..640] of byte;

var
  CharTab14        : ^CharTab14Type;
  CharTab8         : ^CharTab8Type;
  CharSize         : byte;

const
  Colors           : array[0..15] of byte =
    ($00,36,50,54,$3F,$3F,$3F,$3F,$09,$09,$09,$09,$09,$09,$09,$09);


var
  CurrPlane        : PlaneSet;

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


var
  CurrFunc         : FuncType;

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
  CharPos          : integer;
  P                : array[1..4] of byte;
  PCount           : byte;
  FPlane,BPlane    : PlaneSet;
  GetCom           : boolean;
  BlankOn          : boolean;
  BackOn           : boolean;

procedure GotoXY(X,Y : integer);
  begin
    CharPos:=Y*(CharSize*80)+X;
  end;

procedure ConOut(ForChar : char);
  var
    I,Q            : byte;
    Pos            : integer;
    UsePlane       : PlaneSet;
  begin
    if GetCom then begin
      case ForChar of
        ';' : begin PCount:=PCount+1; P[PCount]:=0; end;
        '0'..'9' : P[PCount]:=P[PCount]*10+Ord(ForChar)-48;
        'f' : if PCount>=2 then CharPos:=P[1]*1120+P[2];
        'b' : BlankOn:=P[1]=0;
        'v' : begin BackOn:=P[1]=1; SelectPlane([3]); end;
        't' : CharPos:=CharPos div 80 * 80 + P[1];
        'u' : CharPos:=CharPos-1120;
        'p' : begin
                UsePlane:=[];
                for I:=1 to PCount do UsePlane:=UsePlane+[P[I]];
                SelectPlane(UsePlane);
              end;
      end;
      if ForChar in ['A'..'Z','a'..'z'] then GetCom:=false;
    end else
      case ForChar of
        #27 : begin GetCom:=true; PCount:=1; P[1]:=0; end;
        #8  : CharPos:=CharPos-1;
        #10 : CharPos:=CharPos+(CharSize*80);
        #13 : CharPos:=CharPos div 80 * 80;
        else begin
          if BlankOn then ForChar:=#32;
          SelectPlane(FPlane);
          for I:=0 to CharSize-1 do
            case CharSize of
              8  : Mem[$A000:CharPos+I*80]:=CharTab8^[Ord(ForChar),I];
              14 : Mem[$A000:CharPos+I*80]:=CharTab14^[Ord(ForChar),I];
            end;
          if BPlane<>[] then begin
            SelectPlane(BPlane);
            for I:=0 to CharSize-1 do Mem[$A000:CharPos+I*80]:=$FF;
          end;
          CharPos:=CharPos+1;
          if CharPos mod 80 = 0 then CharPos:=CharPos+CharSize*80;
        end;
      end;
  end;


procedure GRWrite(ForStr : stringtype;X,Y : integer);
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

var
  LastMess         : stringtype;

procedure GRMessage(ForStr : stringtype; WaitKey : boolean);
  var
    I,J,Left       : integer;
  const
    Space : string[50] = '                                                  ';
  begin
    SelectFunc(_Clr);
    if (Length(ForStr)=0) or (Length(LastMess)>0) then begin
      FPlane:=[2,3]; BPlane:=[]; GotoXY(40-Length(LastMess) shr 1,24);
      Write(Copy(Space,1,Length(LastMess)));
    end;
    LastMess:=ForStr;
    if Length(LastMess)>0 then begin
      FPlane:=[3]; BPlane:=[2]; GotoXY(40-Length(ForStr) shr 1,24);
      Write(ForStr);
      if WaitKey then begin
        repeat until KeyPressed;
        GRMessage('',false);
      end;
    end;
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


function Ask(ForStr : stringtype) : boolean;
  begin
    GRMessage(ForStr+' (Y/N)?',true);
    ReadKbd;
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
    Line           : array[-1..1280] of byte absolute LinePtr;
    count,rept     : integer;
    AtByte         : integer;
    AtBit          : byte;
    ROn,GOn        : boolean;
    RByte,GByte    : byte;
    Size           : integer;
  begin
    AtByte:=LineNum*80; AtBit:=0;
    RByte:=$00; GByte:=$00;
    Count:=1;
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
    until (Line[Count]=$18);
    LineSize:=Count+3;
    SelectPlane([0]); Mem[$A000:AtByte]:=RByte;
    if ROn then RByte:=$FF else RByte:=$00;
    FillChar(Mem[$A000:AtByte+1],(LineNum+2)*80-AtByte,RByte);
    SelectPlane([1]); Mem[$A000:AtByte]:=GByte;
    if GOn then GByte:=$FF else GByte:=$00;
    FillChar(Mem[$A000:AtByte+1],(LineNum+2)*80-AtByte,GByte);
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



{.PA}
{*****************************************************************************}
{* Screen Format Routines                                                    *}
{*****************************************************************************}

var {Screen Format Flags}
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


procedure WriteGfx( var AtLand,AtSeg);
  var
    LandMark       : array[1..73] of LandMarkRec absolute AtLand;
    Segment        : array[1..73] of SegmentRec absolute AtSeg;
    Count          : integer;
    Min,Max        : integer;
    Adj            : integer;
  begin
    Count:=1; SelectPlane([2]); SelectFunc(_OR);
    Max:=RangeVal[CurrentParams.Range]*10;
    Min:=Max div 7; Adj:=RangeVal[CurrentParams.Range];
    while (Landmark[Count].Range)<>0 do with Landmark[Count] do begin
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
    Count:=1; SelectPlane([2]); SelectFunc(_OR);
    Max:=RangeVal[CurrentParams.Range]*10;
    Adj:=RangeVal[CurrentParams.Range];
    while (Segment[Count].Range1)<>0 do with Segment[Count] do begin
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
  end;


const
  ModemHelp         : array[1..82] of char =
    '1;0f          23;0f          23;65f          2;0fF1 CALL STATION3;0fF2 REDIAL';
  InterHelp         : array[1..82] of char =
    '1;0f F1   F223;0f F3   F423;65f F5   F62;0fF7 SEND        3;0f         ';
  AllHelp           : array[1..96] of char =
    '2p2;63f* TOGGLE ON/OFF *3;71fALL GFX G4;67fRANGE MARKS R5;73fGFX 1 16;73fGFX 2 221;1fESC ';


procedure WriteHelp;
  begin
    FPlane:=[2]; BPlane:=[];
    case Mode of
      Modem        : Write(AllHelp,'QUIT   ',ModemHelp);
      Interactive  : Write(AllHelp,'HANG-UP',InterHelp);
      WaitPic      : Write(AllHelp,'ABORT  0b',InterHelp);
      RxPic        : Write('0b',AllHelp,InterHelp,'1b21;1fESC ABORT  ');
      RxGraph      : Write(AllHelp,'HANG-UP0b',InterHelp);
    end;
    Write('1b');
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


procedure WriteParams(ForParams : RadarParams);
  begin
    SelectFunc(_Clr); FPlane:=[2]; BPlane:=[];
    with ForParams do begin
      GotoXY(0,0); Write('TILT  : ',TiltVal[Tilt]:2);
      GotoXY(65,0); Write('TIME : ');
      case Clock of
        0 : if Time.Hour<13 then Write(Time.Hour:2,':')
               else Write((Time.Hour-12):2,':');
        1 : Write(Time.Hour:2,':');
      end;
      if Time.Minute<10 then Write('0');
      Write(Time.Minute);
      if Clock=0 then if Time.Hour>12 then Write('pm') else Write('am')
        else Write('  ');
      GotoXY(0,24); Write('RANGE : ',RangeVal[Range]:3);
      GotoXY(65,24); Write('GAIN  : ');
      if Gain<MaxGain then Write(Gain:3) else Write('PRE');
      if Mode=Interactive then begin
        FPlane:=[0]; BPlane:=[]; GotoXY(36,0);
        case RT of
          0 : Write(' RT OFF ');
          1 : Write(' RT ON  ');
          2 : Write('RT FAULT');
        end;
      end;
      if RngChng and (Gfx1On or Gfx2On) then begin
        SelectPlane([2]);
        ClearScreen;
        if Gfx1On then WriteGfx(Land1,Seg1);
        if Gfx2On then WriteGfx(Land2,Seg2);
        if RngMksOn then WriteRngMks;
      end;
    end;
  end;


procedure InitEGA;
  var
    I,Q            : byte;
  begin
    with Registers do begin  {Set 640 x 350 Hi-Res mode}
      AH:=$00;
      AL:=$10;
      Intr($10,Registers);
      AX:=$1130;             {Set address for character table pointer - size 14}
      BH:=$02;
      Intr($10,Registers);
      CharTab14:=Ptr(ES,BP);
      AX:=$1130;             {Set address for character table pointer - size 8}
      BH:=$03;
      Intr($10,Registers);
      CharTab8:=Ptr(ES,BP);
    end;
    for I:=0 to 15 do begin   {Initialize palette registers}
      Q:=port[$3DA];
      port[$3C0]:=I;
      port[$3C0]:=Colors[I];
    end;
    port[$3C0]:=$20;         {Enable palette registers}
    CharSize:=14;
    WriteParams(CurrentParams);
    GotoXY(1,22); Write('* H = HELP *');
  end;


{.PA}
{*****************************************************************************}
{* RS232 Routines                                                            *}
{*****************************************************************************}

var
  Buf              : string[255];
  BufBeg, BufEnd   : Integer;
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
      if (CurrentParams.RT=0) and not(Command=SendGraph) then Delay(1000);
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
      if Response then WriteParams(CurrentParams)
      else begin
        Sound(440); Delay(10); NoSound;
      end;
    end;
  end;

procedure SetParams(var ForBuf; var Params : RadarParams);
  var
    Buf            : string[10] absolute ForBuf;
    Comp           : Gen8Type absolute Land1;
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
           $8E/$D8{/$FB});  {MOV DS,AX}
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
            SetParams(Buf,CurrentParams);
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
        RxPic :
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
            if LineNum>=352 then Mode:=Modem;
          end;
        end;
        RxGraph :
        begin
          BufPtr^[BufCount]:=data; BufCount:=BufCount+1;
          if BufCount=10 then begin
            CheckSum:=0;
            for RI:=1 to 8 do CheckSum:=CheckSum+BufPtr^[RI];
            if (* CheckSum=BufPtr^[BufCount-1] *) true then begin
              if (BufPtr^[1]=0) and (BufPtr^[2]=0) and
                (BufPtr^[3]=0) and (BufPtr^[4]=0) then
              begin
                Sound(440); Delay(100); NoSound;
                MapCount:=MapCount+1;
                if MapCount = 1 then BufPtr := Addr(Seg1);
                if MapCount = 2 then BufPtr := Addr(Land2);
                if MapCount = 3 then BufPtr := Addr(Seg2);
              end else BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+8);
              BufCount:=1;
              Tx('A');
            end else Tx(#0);
            BufCount:=1;
          end;
        end;
      end; (* case *)
    end (* if *)
    else begin
      if port[ComPort+2]=$00 then
        if (port[ComPort+6] and $88)=$88 then begin end;
      port[$20]:=$20; {EOI for 8529}
    end;
    inline($07/       {POP ES}
           $5E/       {POP SI}
           $5F/       {POP DI}
           $5A/       {POP DX}
           $59/       {POP CX}
           $5B/       {POP BX}
           $58/       {POP AX}
           $1F/       {POP DS}
           $FB);
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
    for I := ComPort to ComPort+6 do J := port[I];
    Port[ComPort+3] := $80; {Set baud rate access bit}
    Port[ComPort] := 48; {Set baud rate (2400 = 48)}
    Port[ComPort+1] := $00;
    Port[ComPort+3] := $03; {Set Line Control Data (8 data,1 stop,0 parity)}
    Port[ComPort+1] := $09;
    Port[ComPort+4] := $0B; {Set DTR & RTS high}
    UsrOutPtr := Ofs(Tx);
  end;

{.PA}
{*****************************************************************************}
{* Call Station                                                              *}
{*****************************************************************************}
procedure LoadStation;
  begin
    Assign(StatFile,DirPath+StatName+'.STA');
    Reset(StatFile); if IOResult<>0 then Exit;
    FPlane:=[2]; BPlane:=[];
    GotoXY(72,21); Write(StatName:8);
    Read(StatFile,POver[1],POver[2],POver[3],POver[4]);
    for J:=0 to 3 do begin
      case J of
        0 : GPtr:=Addr(Land1);
        1 : GPtr:=Addr(Seg1);
        2 : GPtr:=Addr(Land2);
        3 : GPtr:=Addr(Seg2);
      end;
      I:=0;
      repeat
        I:=I+1;
        Read(StatFile,GPtr^[I]);
      until ((GPtr^[I,1]=0) and (GPtr^[I,2]=0)) or EOF(StatFile);
    end;
    Close(StatFile);
  end;

procedure SaveStation;
  begin
    Assign(StatFile,DirPath+StatName+'.STA');
    Rewrite(StatFile); if IOResult<>0 then Exit;
    Write(StatFile,POver[1],POver[2],POver[3],POver[4]);
    for J:=0 to 3 do begin
      case J of
        0 : GPtr:=Addr(Land1);
        1 : GPtr:=Addr(Seg1);
        2 : GPtr:=Addr(Land2);
        3 : GPtr:=Addr(Seg2);
      end;
      I:=0;
      repeat
        I:=I+1;
        Write(StatFile,GPtr^[I]);
      until (GPtr^[I,1]=0) and (GPtr^[I,2]=0);
    end;
    Close(StatFile);
  end;

procedure CallStation;
  var
    ModemMess : char;
  begin
    if PhoneNum='' then Exit;
    case ModemType of
      0 : begin
            GRMessage('DIALING - '+PhoneNum,false);
            Mode:=Modem;
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
  CallFlag : boolean;

procedure SelectStation;
  var
    Stat           : array[0..9] of string[12];
    StatCount      : byte;
  begin
    CallFlag:=false;
    SelectFunc(_Clr);
    FPlane:=[3]; BPlane:=[2];
    Mask:=DirPath+'????????.STA'+#0; SetDir; StatCount:=0;
    repeat
      StatCount:=0;
      GotoXY(30,1);
      Writeln('ษออออSTATIONSอออป');
      repeat
        Stat[StatCount]:=DirEntry;
        Stat[StatCount]:=Copy(Stat[StatCount],1,Pos('.',Stat[StatCount])-1);
        CharPos:=CharPos+30;
        Writeln('บ ',StatCount,' : ',Stat[StatCount]:9,' บ');
        StatCount:=StatCount+1;
      until (Registers.AX<>0) or (StatCount>9);
      CharPos:=CharPos+30;
      Writeln('บA=Add D=Delete บ');
      if Registers.AX=0 then begin
        CharPos:=CharPos+30; Writeln('บ <SPC>=More    บ');
      end;
      CharPos:=CharPos+30; Writeln('ศอออออออออออออออผ');
      ReadKbd;
      case UpCase(Key) of
        'A'     : begin
                    GotoXY(30,1);
                    Writeln('ษออADDอSTATIONออป');
                    GotoXY(31,2); Write('NAME:         ');
                    GotoXY(37,2); StatName:=ReadStr(8);
                    if Length(StatName)>1 then begin
                      GotoXY(31,3); Write(' PHONE :       ');
                      GotoXY(31,4); Write('               ');
                      GotoXY(31,4); PhoneNum:=ReadStr(31);
                      Land1[1].Range:=0; Seg1[1].Range1:=0;
                      Land2[1].Range:=0; Seg2[1].Range1:=0;
                      SaveStation;
                      SetDir;
                    end;
                  end;
        'D'     : begin
                    GRMessage('STATION NUMBER TO DELETE?',false);
                    ReadKbd;
                    GRMessage('Erasing '+Stat[Ord(Key)-48],false);
                    Assign(StatFile,DirPath+Stat[Ord(Key)-48]+'.STA');
                    Erase(StatFile);
                    SetDir;
                  end;
        ^[      : Registers.AX:=1;
        '0'..'9': begin
                    StatName:=Stat[Ord(Key)-48];
                    LoadStation;
                    Registers.AX:=1;
                    CallFlag:=true;
                  end;
      end;
      SelectPlane([0..3]); ClearScreen;
    until Registers.AX<>0;
    Key:=#0;
    Gfx1On:=false; Gfx2On:=false;
    RngMksOn:=false;
  end;


{.PA}
{*****************************************************************************}
{* Initialization and Configuration                                          *}
{*****************************************************************************}
procedure Initialize;
  begin
    FillChar(CurrentParams,Ofs(data)+20-Ofs(CurrentParams),0);
    OldCon:=ConOutPtr;
    GraphicsOn:=true;
    InitRS232;
    if ComPort=$3F8 then port[$21]:=port[$21] and not(1 shl 4)
    else port[$21]:=port[$21] and not(1 shl 3);
    Port[ComPort+1]:=$09;
    case ModemType of
      0 : Write(Usr,'AT &F &C1 &D2 L M1 E V X4',^M);
      1 : begin
            Write(Usr,^E,^M,^E,^M); Delay(100);
            Write(Usr,'O21122111211111112112',^M);
          end;
    end;
    ConOutPtr:=Ofs(ConOut);
    InitEGA;
  end;

procedure DeInit;
  begin
    Write(Usr,'ATZ',^M);
    port[ComPort+4]:=$08;        {DTR & RTS off}
    port[ComPort+1]:=$00;        {Disable any interrupts}
    port[$21]:= port[$21] or (1 shl 4);
  end;

procedure Config;
  var
    ProgFile         : file of byte;
  begin
    SelectFunc(_Clr); FPlane:=[3]; BPlane:=[2];
    GotoXY(24,1); Write('ษอออออออออออOPTIONSอออออออออออป');
    GotoXY(24,2); Write('บ F1: Modem   =               บ');
    GotoXY(24,3); Write('บ F2: Serial  =               บ');
    GotoXY(24,4); Write('บ F3: Clock   =               บ');
    GotoXY(24,5); Write('บ F10: Update disk            บ');
    GotoXY(24,6); Write('บ ESC: Exit option menu       บ');
    GotoXY(24,7); Write('ศอออออออออออออออออออออออออออออผ');
    repeat
      GotoXY(41,2);
      if ModemType=0 then Write('Hayes Compat') else Write('Racal-Vadic ');
      GotoXY(41,3); if ComPort=$3F8 then Write('COM1:') else Write('COM2:');
      GotoXY(41,4); if Clock=0 then Write('12 hour') else Write('24 hour');
      ReadKbd;
      case Key of
        ';' : ModemType:=(ModemType+1) mod 2;
        '=' : Clock:=(Clock+1) mod 2;
        '<' : if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
        'D' : begin
          GRMessage('UPDATING PROGRAM FILE...',false);
          Assign(ProgFile,'RADAR.COM');
          ReSet(ProgFile); Seek(ProgFile,Ofs(DirPath)-256);
          for I:=Ofs(DirPath) to Ofs(Clock) do
            Write(ProgFile,Mem[CSeg:I]);
          Close(ProgFile);
          GRMessage('',false);
          FPlane:=[3]; BPlane:=[2];
        end;
      end;
    until Key=#27;
    Key:=#0; DeInit; Initialize;
  end;

{.PA}
{*****************************************************************************}
{* Main Routines                                                             *}
{*****************************************************************************}
procedure ExecCom;
  begin
    case UpCase(Key) of {Process regular key codes}
      'G'  : ToggleGraphics;
      'R'  : if Mode<>RxPic then begin
               RngMksOn:=not RngMksOn;
               if RngMksOn then WriteRngMks
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if Gfx1On then WriteGfx(Land1,Seg1);
                 if Gfx2On then WriteGfx(Land2,Seg2);
               end;
             end;
      'H'  : if Mode<>RxPic then begin
               HelpOn:=not HelpOn;
               if HelpOn then WriteHelp
               else Write('0b',AllHelp,'       ',InterHelp,'1b');
             end;
      '1'  : if Mode<>RxPic then if StatName<>'' then begin
               Gfx1On:=not Gfx1On;
               if Gfx1On then WriteGfx(Land1,Seg1)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx2On then WriteGfx(Land2,Seg2);
               end;
             end;
      '2'  : if Mode<>RxPic then if StatName<>'' then begin
               Gfx2On:=not Gfx2On;
               if Gfx2On then WriteGfx(Land2,Seg2)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx1On then WriteGfx(Land1,Seg1);
               end;
             end;
    end;
  end;

procedure RxGraphLoop;
  begin
    BufPtr:=Addr(Land1); BufCount:=1; MapCount:=0;
    SendCom(SendGraph,800);
    if not Response then Exit;
    Mode:=RxGraph;
    GRMessage('ONE MOMENT PLEASE... RECEIVING MAP OVERLAY',false);
    repeat
      if KeyPressed then begin
        ReadKbd;
        if Key=#27 then if Ask('ABORT MAP OVERLAY RECEPTION') then Key:=^Q;
      end;
    until (Key=^Q) or (MapCount>3);
    if Key=^Q then LoadStation else SaveStation;
    GRMessage('',false);
    Mode:=Interactive; Key:=#0;
  end;


procedure RxPicLoop;
  var
    LinePtr        : integer;
  begin
    WriteHelp;
    SendCom(SendPic,400);
    if not Response then Exit;
    GRMessage('WAITING FOR PICTURE',false);
    DrawScale;
    Mode:=WaitPic; BufPtr:=Addr(GRBuf);
    repeat
      if KeyPressed then begin
        ReadKbd;
        ExecCom;
        if Key=#27 then if Ask('ABORT PICTURE') then Key:=^Q;
      end;
    until (Key=^Q) or (Mode=RxPic);
    if Mode=RxPic then begin
      WriteAt:=-20000; LineAt:=-20001; PicSaveAt:=-20000;
      GRMessage('RECEIVING PICTURE',false);
      repeat
        while LineAt>WriteAt do begin
          DispLine(PicSave[WriteAt]);
          WriteAt:=WriteAt+LineSize;
        end;
        if KeyPressed then begin
          ReadKbd;
          ExecCom;
          if Key=#27 then if Ask('ABORT PICTURE') then begin
            Tx('Y'); Tx('Y'); GRMessage('PICTURE ABORTED',true); Tx('Y');
            Key:=^Q;
          end;
        end;
      until (Key=^Q) or (Mode=Modem);
    end;
    GRMessage('',false);
    Key:=#0; if Mode<>Modem then Mode:=Interactive;
    WriteHelp;
  end;

procedure InterLoop;
  label ExitInter;
  begin
    SendCom('X',200);
    if not Response then SendCom('X',200);
    if not Response then SendCom('X',200);
    if not Response then begin
      GRMessage('NO RESPONSE. PRESS ANY KEY',true);
      Goto ExitInter;
    end;
    FPlane:=[3]; BPlane:=[2]; GotoXY(73,22); Write('ON LINE');
    WriteHelp;
    SendCom(CheckGraph,600);
    if Response and not GfxMatch then RxGraphLoop;
    GRMessage('',false);
    if Gfx1On or Gfx2On then begin
      SelectPlane([2]);
      ClearScreen;
      if Gfx1On then WriteGfx(Land1,Seg1);
      if Gfx2On then WriteGfx(Land2,Seg2);
      if RngMksOn then WriteRngMks;
    end;
    (* VERSION 1.0 *)
    repeat
      ReadKbd;
      if Escape then
        case Key of              {Process extended key codes}
          #59  : SendCom(TiltUp,200);
          #60  : SendCom(TiltDown,200);
          #61  : begin
                   SendCom(RangeUp,500);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Land1,Seg1);
                     if Gfx2On then WriteGfx(Land2,Seg2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #62  : begin
                   SendCom(RangeDown,500);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Land1,Seg1);
                     if Gfx2On then WriteGfx(Land2,Seg2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #63  : SendCom(GainUp,200);
          #64  : SendCom(GainDown,200);
          #65  : RxPicLoop;
          #66  : RxGraphLoop;
        end
      else ExecCom;
      if Key=#27 then if Ask('DISCONNECT STATION') then Key:=^Q;
    until (Key=^Q) or (Mode=Modem);
    (* VERSION 1.1
    RxPicLoop; *)
    ExitInter:
    HangUp; Key:=#0;
    FPlane:=[2,3]; BPlane:=[]; GotoXY(73,22); Write('       ');
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
                  if CallFlag then CallStation;
                  if Mode=Interactive then InterLoop
                  else GRMessage('NOT CONNECTED',true);
                end;
          #60 : begin
                  CallStation;
                  if Mode=Interactive then InterLoop
                  else GRMessage('NOT CONNECTED',true);
                end;
          ^X  : ConFig;
         end
      else ExecCom;
      if Key=#27 then if Ask('QUIT PROGRAM') then Key:=^Q;
    until Key=^Q;
  end;

begin
  Initialize;
  GotoXY(24,20); Write('E300 RADAR TERMINAL, ver. 1.0');
  GotoXY(24,21); Write('      Revision 6/13/88       ');
  GotoXY(24,22); Write('  Copyright (C) 1986,87,88   ');
  GotoXY(24,23); Write('         D. G. Lane          ');
  GotoXY(24,24); Write('     All Rights Reserved     ');
  SelectStation; CallStation;
  if Mode=Interactive then InterLoop;
  ModemLoop;
  DeInit;
  TextMode;
end.
