{$MODE TP}
{$H-}
(**********************************)
(* DID YOU JUST CHANGE SOMETHING? *)
(*                                *)
(*    IF SO, CHANGE THE DATE!!!   *)
(*           ---------------      *)
(**********************************)

(* FreePascal Compatible Version *)
(* Original: 19880114 RADAR.PAS  *)

{$ASMMODE INTEL}
{$C-,V-,I-,R-}

Program Radar_Terminal;

uses
  Dos;

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
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : word);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;


const
  DirPath          : string[24] = '';
  ModemType        : byte = 0;
  ComPort          : word = $3F8;
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
  OldCon           : word;

{Miscellaneous Variables}
  Registers        : RegisterType;
  Key              : char;
  DTA              : array[0..127] of byte;
  Escape           : boolean;
  I,J              : integer;
  Map1             : array[1..512,1..8] of byte;
  Map2             : array[1..512,1..8] of byte;
  Map1Size         : integer;

{*****************************************************************************}
{* Miscellaneous Routines - Stubs for FreePascal                            *}
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
    Key:=ReadKey;
    if KeyPressed then begin
      Key:=ReadKey;
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


{*****************************************************************************}
{* Graphics Routines - Stubs for FreePascal                                 *}
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
    Data           : byte;
  begin
    Data := Byte(ForPlanes);
    { Port access disabled in FreePascal/modern systems }
    { port[$3C4]:=$02; }
    { port[$3C5]:=Data; }
    CurrPlane:=ForPlanes;
  end;

procedure ShowPlane(ForPlanes : PlaneSet);
  var
    Data           : byte;
    Q              : byte;
  begin
    Data := Byte(ForPlanes);
    { Port access disabled }
    { Q:=port[$3DA]; }
    { port[$3C0]:=$12; }
    { port[$3C0]:=Data; }
    { port[$3C0]:=$20; }
  end;

var CurrFunc       : FuncType;
procedure SelectFunc(ForFunc : FuncType);
  begin
    { Port access disabled }
    { port[$3CE]:=$03; }
    { if ForFunc in [Rot1..Rot7] then port[$3CF]:=Ord(ForFunc)+1 }
    {   else port[$3CF]:=(Ord(ForFunc)-7) shl 3; }
    CurrFunc:=ForFunc;
  end;

var CurrMask       : byte;
procedure SetMask(ToMask : byte);
  begin
    { Port access disabled }
    { port[$3CE]:=$08; }
    { port[$3CF]:=ToMask; }
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

{ Most graphics routines are stubs since we don't have EGA hardware }
procedure InitEGA;
  begin
    WriteLn('RADARPAS - Ellason E300 Radar Terminal');
    WriteLn('FreePascal Build - Graphics Disabled');
    WriteLn('Original: Copyright (C) 1987 D. G. Lane');
    WriteLn('Build Date: ', DateToStr(Date));
    CharSize:=14; XMax:=79; YMax:=24;
  end;

procedure ClearScreen;
  begin
    { Stub }
  end;

procedure FetchPic;
  begin
    WriteLn('FetchPic called (stub)');
  end;

procedure Storage;
  begin
    WriteLn('Storage called (stub)');
  end;

procedure SelectStation;
  begin
    WriteLn('SelectStation called (stub)');
  end;

procedure ToggleGraphics;
  begin
    WriteLn('ToggleGraphics called (stub)');
  end;

function Ask(ForStr : LineType) : boolean;
  var
    Response: char;
  begin
    WriteLn(ForStr, ' (Y/N)?');
    ReadLn(Response);
    Ask := UpCase(Response) = 'Y';
  end;

{*****************************************************************************}
{* RS232 Routines - Stubs                                                    *}
{*****************************************************************************}
procedure InitRS232;
  begin
    WriteLn('RS232 Interface: Not available in this build');
  end;

procedure HangUp;
  begin
    { Stub }
  end;

{*****************************************************************************}
{* Initialization and Configuration                                          *}
{*****************************************************************************}
procedure Initialize;
  begin
    Mode := Modem;
    ErrorFlag := false;
    GraphicsOn := true;
    InitEGA;
    InitRS232;
    StationName := '';
    MaxPic := 0;
    CurrPic := 0;
  end;

procedure DeInit;
  begin
    WriteLn('Shutting down...');
  end;

{*****************************************************************************}
{* Main Program                                                              *}
{*****************************************************************************}
var
  OldDir : string;
  Choice : char;

begin
  GetDir(0, OldDir);
  Initialize;

  WriteLn;
  WriteLn('====================================================');
  WriteLn('  ELLASON E300 RADAR TERMINAL, ver 2.1');
  WriteLn('            Revision 1/14/88');
  WriteLn('           Copyright (C) 1987');
  WriteLn('               D. G. Lane');
  WriteLn('           All rights reserved');
  WriteLn('====================================================');
  WriteLn;
  WriteLn('FreePascal Compatible Build');
  WriteLn('Note: Hardware-specific features disabled');
  WriteLn;
  WriteLn('This is a historical compilation demonstration.');
  WriteLn('Original software controlled radar systems via');
  WriteLn('EGA graphics and RS232 modem connections.');
  WriteLn;
  WriteLn('Press Q to quit, any other key to continue...');

  Choice := ReadKey;
  if UpCase(Choice) <> 'Q' then begin
    WriteLn;
    WriteLn('In the original program, you would now:');
    WriteLn('- Select a radar station');
    WriteLn('- Dial via modem');
    WriteLn('- Receive and display radar images');
    WriteLn('- Store pictures to disk');
    WriteLn;
  end;

  DeInit;
  ChDir(OldDir);
  WriteLn('Program terminated.');
end.
