IMPLEMENTATION MODULE Picture;

(*********************************************************)
(* VERSION : 1/26/87                                     *)
(* CREATED : 1/26/87                                     *)
(*  AUTHOR : Derek Lane                                  *)
(*  SYSTEM : LOGITECH MODULA-2/86                        *)
(*                                                       *)
(*  Downloading and displaying the radar's picture.      *)
(*  All of these procedures assume that the radar is     *)
(*  connected and online.                                *)
(*                                                       *)
(*********************************************************)

FROM EGALib IMPORT 
  SetPlane;
FROM RS232Int IMPORT 
  Read, Write;
FROM SYSTEM IMPORT 
  ADDRESS, BYTE, ADR, GETREG, SETREG, CODE, AX, BX, CX, DX, DI, ES;
FROM Control IMPORT 
  Delay, TimeRead;
FROM TimeDate IMPORT 
  Time;

CONST
  RadarAck     = 'A';
  RadarNack    = 000c;
  RadarXON     = 'O';
  RadarSendPic = 004c;

PROCEDURE Wait;
(* Wait for a picture to be ready to send.  Must call Download immediately
   or picture data may be lost. *)
VAR
  WaitCode     : ARRAY[0..26] OF CHAR;
  Count        : CARDINAL;
BEGIN
  Write('Z'); Delay(15);
  Write(RadarSendPic);
  Count:=0;
  REPEAT
    Read(WaitCode[Count]);
    INC(Count);
  UNTIL (Count>=3) AND (WaitCode[Count-1]=375c) AND
    (WaitCode[Count-2]=376c) AND (WaitCode[Count-3]=377c);
END Wait;

PROCEDURE Download(ToBuffer : ADDRESS;
               VAR Size     : CARDINAL);
(* Downloads the current radar picture into ToBuffer.  Size returns
   how many bytes the picture took. *)
VAR
  Count        : CARDINAL;
  Buffer       : POINTER TO ARRAY[0..5000] OF CHAR;
  CheckSumCalc,
  CheckSumSent : CHAR;
  EndAddress   : ADDRESS;
  LineNum      : POINTER TO INTEGER;
BEGIN
  Buffer:=ToBuffer;
  LOOP
    Count:=0;
    CheckSumCalc:=000c;
    REPEAT
      Read(Buffer^[Count]);
      INC(CheckSumCalc,ORD(Buffer^[Count]));
      INC(Count);
    UNTIL (Count>=2) AND (Count MOD 2=0) AND (Buffer^[Count-2]=030c);
    Read(CheckSumSent);
    IF CheckSumCalc=CheckSumSent THEN
      Write(RadarAck);
      LineNum:=ADR(Buffer^);
      LineNum^:=LineNum^ DIV 54;
      Decompress(Buffer);
      EndAddress:=Buffer;
      INC(EndAddress,Count);
      Buffer:=EndAddress;
      Write(RadarXON);
      IF LineNum^>351 THEN
        Size:=EndAddress.OFFSET-ToBuffer.OFFSET;
        EXIT;
      END;
    ELSE
      Write(RadarNack);
    END; (* IF *)
  END; (* LOOP *)
END Download;

VAR
  Screen [0A000H:0000H] : ARRAY [0..32767] OF BYTE;
  LineSize              : CARDINAL;

PROCEDURE Decompress(ForLine : ADDRESS);
VAR
  LineData     : POINTER TO ARRAY[1..640] OF CARDINAL;
  Count,Rep,
  AtByte,AtBit,
  Size,Color    : CARDINAL;
  RedOn,GrnOn   : BOOLEAN;
  RedVal,GrnVal : BYTE;
BEGIN
  LineData:=ForLine;
  SetPlane({2});
  AtByte:=LineData^[1]*80; AtBit:=0;
  RedVal:=BYTE(0); GrnVal:=BYTE(0);
  Count:=2;
  REPEAT
    Size:=LineData^[Count];
    SETREG(BX,Size);
    CODE(86H,0DFH);          (* XCHG BH,BL *)
    CODE(89H,0D8H);          (* MOV AX,BX *)
    CODE(81H,0E3H,0FFH,07H); (* AND BX,07FFH *)
    GETREG(BX,Size);
    CODE(0B1H,0DH);           (* MOV CL,13 *)
    CODE(0D3H,0E8H);         (* SHR AX,CL *)
    CODE(24H,03H);           (* AND AL,03H *)
    GETREG(AX,Color);
    CASE Color OF
      0 : RedOn:=FALSE; GrnOn:=FALSE|
      1 : RedOn:=TRUE;  GrnOn:=FALSE|
      2 : RedOn:=FALSE; GrnOn:=TRUE|
      3 : RedOn:=TRUE;  GrnOn:=TRUE
    END; (* CASE *)
    IF Size+AtBit<=8 THEN
      IF RedOn THEN
        SETREG(CX,8);
        SETREG(DX,Size);
        CODE(28H,0D1H);      (* SUB CL,DL *)
        SETREG(AX,00FFH);
        CODE(0D2H,0E8H);     (* SHR AL,CL *)
        SETREG(CX,AtBit);
        CODE(0D2H,0E0H);     (* SHL AL,CL *)
        SETREG(BX,RedVal);
        CODE(08H,0C3H);      (* OR BL,AL *)
        GETREG(BX,RedVal);
      END; (* IF *)
      IF GrnOn THEN
        SETREG(CX,8);
        SETREG(DX,Size);
        CODE(28H,0D1H);      (* SUB CL,DL *)
        SETREG(AX,00FFH);
        CODE(0D2H,0E8H);     (* SHR AL,CL *)
        SETREG(CX,AtBit);
        CODE(0D2H,0E0H);     (* SHL AL,CL *)
        SETREG(BX,GrnVal);
        CODE(08H,0C3H);      (* OR BL,AL *)
        GETREG(BX,GrnVal);
      END; (* IF *)
      AtBit:=AtBit+Size;
    ELSE
      IF RedOn THEN
        SETREG(CX,AtBit);
        SETREG(BX,00FFH);
        SETREG(AX,RedVal);
        CODE(0D3H,0E3H);     (* SHL BX,CL *)
        CODE(09H,0D8H);      (* OR AX,BX *)
        GETREG(AX,RedVal);
      END; (* IF *)
      IF GrnOn THEN
        SETREG(CX,AtBit);
        SETREG(BX,00FFH);
        SETREG(AX,GrnVal);
        CODE(0D3H,0E3H);     (* SHL BX,CL *)
        CODE(09H,0D8H);      (* OR AX,BX *)
        GETREG(AX,GrnVal);
      END; (* IF *)   
      SetPlane({0}); Screen[AtByte]:=RedVal;
      SetPlane({1}); Screen[AtByte]:=GrnVal;
      Size:=Size+AtBit-8;
      AtBit:=0; AtByte:=AtByte+1;
      IF Size+AtBit>8 THEN
        SETREG(AX,Size);
        CODE(25H,07H,00H);   (* AND AX,0007H *)
        GETREG(AX,AtBit);
        SETREG(AX,Size);
        SETREG(CX,03H);
        CODE(0D3H,0E8H);     (* SHR AX,CL *)
        GETREG(AX,Size);
        SetPlane({0});
        SETREG(DI,AtByte);
        SETREG(ES,0A000H);
        SETREG(CX,Size);
        IF RedOn THEN SETREG(AX,0FFH) ELSE SETREG(AX,00H) END;
        CODE(0F3H,0AAH);     (* REP STOB *)
        SetPlane({1});
        SETREG(DI,AtByte);
        SETREG(ES,0A000H);
        SETREG(CX,Size);
        IF GrnOn THEN SETREG(AX,0FFH) ELSE SETREG(AX,00H) END;
        CODE(0F3H,0AAH);     (* REP STOB *)
        AtByte:=AtByte+Size;
      ELSE
        AtBit:=Size;
      END; (* IF *)
      IF RedOn THEN
        SETREG(CX,8);
        SETREG(DX,AtBit);
        CODE(028H,0D1H);     (* SUB CL,DL *)
        SETREG(AX,0FFH);
        CODE(0D2H,0E8H);     (* SHR AL,CL *)
        GETREG(AX,RedVal);
      ELSE
        RedVal:=BYTE(0);
      END; (* IF *)
      IF GrnOn THEN
        SETREG(CX,8);
        SETREG(DX,AtBit);
        CODE(028H,0D1H);     (* SUB CL,DL *)
        SETREG(AX,0FFH);
        CODE(0D2H,0E8H);     (* SHR AL,CL *)
        GETREG(AX,GrnVal);
      ELSE
        GrnVal:=BYTE(0);
      END; (* IF *)
      IF AtBit=8 THEN
        SetPlane({0}); Screen[AtByte]:=RedVal;
        SetPlane({1}); Screen[AtByte]:=GrnVal;
        AtByte:=AtByte+1; AtBit:=0;
        RedVal:=BYTE(0); GrnVal:=BYTE(0);
      END;
    END; (* IF *)
    Count:=Count+1;
  UNTIL LineData^[Count]=1818H;
  LineSize:=Count*2;
END Decompress;

PROCEDURE Display(Start, End : ADDRESS);
(* Decompresses the picture at Start, until address count is greater
   than End. *)
BEGIN
  REPEAT
    Decompress(Start);
    INC(Start,LineSize);
  UNTIL Start.OFFSET>End.OFFSET;
END Display;

END Picture.
