IMPLEMENTATION MODULE ScreenHandler;

(*********************************************************)
(* Created   : 1/26/87                                   *)
(* Last Edit : 2/9/87                                    *)
(* Author    : D. Lane                                   *)
(* System    : LOGITECH MODULA-2/86                      *)
(*                                                       *)
(* Screen handler for radar terminal.  Controls most     *)
(* elements of the screen.                               *)
(*********************************************************)

FROM EGALib IMPORT SetFunc, clr, SetPlane, FillArea, GotoXY;
FROM InOut IMPORT Write, WriteString, WriteCard, ReadString;
IMPORT Keyboard;
IMPORT Map;
FROM SYSTEM IMPORT ADDRESS, SETREG, GETREG, CODE, AX, BX;
FROM TimeDate IMPORT Time;

PROCEDURE WriteTime(ForTime : Time);
(* Writes time in 7 spaces *)
VAR
  Hour, Minute : CARDINAL;
BEGIN
  Hour:=ForTime.minute DIV 60;
  Minute:=ForTime.minute MOD 60;
  IF ArmyTime OR (Hour<=12) THEN
    WriteCard(Hour,2);
  ELSIF (Hour<=23) THEN
    WriteCard(Hour-12,2);
  ELSE
    WriteCard(24,2);
  END; (* IF *)
  Write(':');
  IF Minute<10 THEN Write('0'); END;
  WriteCard(Minute,0);
  IF ArmyTime THEN
    WriteString('  ');
  ELSIF Hour>11 THEN
    WriteString('pm');
  ELSE
    WriteString('am');
  END; (* IF *)
END WriteTime;

PROCEDURE WriteDate(ForTime : Time);
VAR
  Month, Day, Year : CARDINAL;
BEGIN
  SETREG(AX,ForTime.day);
  CODE(0BBH,1FH,00H); (* MOV BX,001FH *)
  CODE(21H,0C3H);     (* AND BX,AX *)
  GETREG(BX,Day);
  CODE(0B1H,05H);     (* MOV CL,5 *)
  CODE(0D3H,0E8H);    (* SHR AX,CL *)
  CODE(0BBH,0FH,00H); (* MOV BX,000FH *)
  CODE(21H,0C3H);     (* AND BX,AX *)
  GETREG(BX,Month);
  CODE(0B1H,04H);     (* MOV CL,4 *)
  CODE(0D3H,0E8H);    (* SHR AX,CL *)
  CODE(0BBH,7FH,00H); (* MOV BX,007FH *)
  CODE(21H,0C3H);     (* AND BX,AX *)
  GETREG(BX,Year);
  WriteCard(Month,2); Write('/');
  WriteCard(Day,2); Write('/');
  WriteCard(Year MOD 100,2);
END WriteDate;

PROCEDURE WriteTilt(Tilt : CARDINAL);
(* Writes tilt in 2 spaces *)
BEGIN
  CASE Tilt OF
    0..6 : WriteCard(Tilt,2)|
    7    : WriteCard(8,2)|
    8    : WriteCard(10,2)|
    9    : WriteCard(12,2)|
    10   : WriteCard(15,2)|
    11   : WriteCard(18,2)|
    12   : WriteCard(20,2)
    ELSE WriteString('??');
  END;  (* CASE *)
END WriteTilt;

VAR
  CurrRange : CARDINAL; (* Stores current range which maps are drawn at *)

PROCEDURE WriteRange(Range : CARDINAL);
(* Writes range in 3 spaces *)
BEGIN
  CASE Range OF
    0 : WriteCard(10,3)|
    1 : WriteCard(25,3)|
    2 : WriteCard(50,3)|
    3 : WriteCard(100,3)|
    4 : WriteCard(200,3)
    ELSE WriteString('???');
  END; (* CASE *)
  IF CurrRange<>Range THEN
    CurrRange:=Range;
    Redraw;
  END; (* IF *)
END WriteRange;

PROCEDURE WriteGain(Gain : CARDINAL);
(* Writes gain in 3 spaces *)
BEGIN
  IF Gain<=16 THEN
    WriteCard(Gain,3);
  ELSIF Gain=17 THEN
    WriteString('PRE');
  ELSE
    WriteString('???');
  END; (* IF *)
END WriteGain;

PROCEDURE WriteParams(Tilt, Range, Gain : CARDINAL; ForTime : Time);
BEGIN
  SetPlane({2});
  GotoXY(0,0);     WriteString('TILT  : '); WriteTilt(Tilt);
  GotoXY(0,336);   WriteString('RANGE : '); WriteRange(Range);
  GotoXY(520,336); WriteString('GAIN : '); WriteGain(Gain);
  GotoXY(520,0);   WriteString('TIME : '); WriteTime(ForTime);
  GotoXY(520,14);  WriteString('DATE : '); WriteDate(ForTime);
END WriteParams;

VAR
  RangeMarksOn : BOOLEAN;
  MapOn        : ARRAY[1..10] OF BOOLEAN;
  MapAt        : ARRAY[1..10] OF ADDRESS;

PROCEDURE SetMap(Number : CARDINAL; At : ADDRESS);
BEGIN
  MapAt[Number]:=At;
  MapOn[Number]:=FALSE;
END SetMap;

PROCEDURE DrawRangeMarks;
BEGIN
END DrawRangeMarks;

PROCEDURE ToggleRangeMarks;
BEGIN
  IF RangeMarksOn THEN
    RangeMarksOn:=FALSE;
    Redraw;
  ELSE
    RangeMarksOn:=TRUE;
    DrawRangeMarks;
  END; (* IF *)
END ToggleRangeMarks;

PROCEDURE ToggleMap(Number : CARDINAL);
BEGIN
  IF MapOn[Number] THEN
    MapOn[Number]:=FALSE;
    Redraw;
  ELSE
    MapOn[Number]:=TRUE;
    Map.Display(MapAt[Number]);
  END; (* IF *)
END ToggleMap;

PROCEDURE Redraw;
VAR
  Count : CARDINAL;
BEGIN
  Map.ClearScreen;
  FOR Count:=1 TO 10 DO
    IF MapOn[Count] THEN Map.Display(MapAt[Count]) END;
  END; (* FOR *)
  IF RangeMarksOn THEN DrawRangeMarks END;
END Redraw;

VAR
  Length : CARDINAL;

PROCEDURE Message(String : ARRAY OF CHAR);
BEGIN
  IF Length<>0 THEN
    SetPlane({2,3}); SetFunc(clr);
    FillArea(Length,336,640-Length,349,0);
  END; (* IF *)
  Length:=320-(HIGH(String)+1)*4;
  SetPlane({2}); FillArea(Length,336,640-Length,349,255);
  SetPlane({3}); 
  GotoXY(Length,336);
  WriteString(String);
END Message;

PROCEDURE Prompt(String : ARRAY OF CHAR; VAR Response : ARRAY OF CHAR);
BEGIN
  IF Length<>0 THEN
    SetPlane({2,3});
    FillArea(Length,336,640-Length,349,0);
  END; (* IF *)
  Length:=320-(HIGH(String)+1+HIGH(Response)+1)*4;
  SetPlane({2}); FillArea(Length,336,640-Length,349,255);
  SetPlane({3}); 
  GotoXY(Length,336);
  WriteString(String);
  ReadString(Response);
END Prompt;

PROCEDURE Pause(String : ARRAY OF CHAR) : CHAR;
VAR
  Key : CHAR;
BEGIN
  Message(String);
  Keyboard.Read(Key);
  RETURN Key;
END Pause;

BEGIN
  ArmyTime:=TRUE;
  Length:=0;
END ScreenHandler.
