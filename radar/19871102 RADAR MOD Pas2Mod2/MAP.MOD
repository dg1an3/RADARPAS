IMPLEMENTATION MODULE Map;

(*********************************************************)
(* VERSION : 1/26/86                                     *)
(* CREATED : 1/26/86                                     *)
(*  AUTHOR : Derek Lane                                  *)
(*  SYSTEM : LOGITECH MODULA-2/86                        *)
(*                                                       *)
(*  Downloading and displaying the radar's map overlays. *)
(*  Download procedure assumes that the radar is connect-*)
(*  ed and online.                                       *)
(*                                                       *)
(*********************************************************)

FROM RS232Int IMPORT Read, Write;
FROM SYSTEM IMPORT ADDRESS, ADR, BYTE;
FROM Control IMPORT Delay, ReadParam;
FROM Modem IMPORT Call;
FROM InOut IMPORT WriteCard, WriteString, WriteLn;              
FROM TimeDate IMPORT Time;

CONST
  RadarAck      = 'A';
  RadarNack     = 000c;

CONST
  RadarCheckMap = 020c;

PROCEDURE CheckMap(Map1 : ADDRESS) : BOOLEAN;
(* Calls a map check for the remote radar to see if a new version
   of the map needs to be downloaded. *)
VAR
  Buffer       : ARRAY[0..8] OF CHAR;
  Version      : POINTER TO ARRAY[1..8] OF CHAR;
  Count        : CARDINAL;
  CheckSumCalc,
  CheckSumSent : CHAR;
BEGIN
  WriteString('CHECKING GRAPHICS...');
  Write('Z'); Delay(10);
  Write(RadarCheckMap);
  LOOP
    CheckSumCalc:=000c;
    Read(Buffer[0]);
    FOR Count:=1 TO 8 DO
      Read(Buffer[Count]);
      INC(CheckSumCalc,ORD(Buffer[Count]));
    END; (* FOR *)
    Read(CheckSumSent);
    IF (Buffer[0]='G') AND (CheckSumCalc=CheckSumSent) THEN
      Write(RadarAck);
      Count:=1;
      WHILE (Version^[Count]=Buffer[Count]) AND (Count<8) DO
        INC(Count);
      END; (* WHILE *)
      IF Count=8 THEN 
        WriteString('GRAPHICS OK'); WriteLn;
      ELSE
        WriteString('GRAPHICS NOT OK'); WriteLn;
      END; (* IF *)
      RETURN (Count=8);
    ELSE
      Write(RadarNack);
    END; (* IF *)
  END; (* LOOP *)
END CheckMap;

CONST
  RadarSendMap = 000c;

PROCEDURE Download(Map1, Map2 : ADDRESS);
(* Downloads the radar's two maps into the two buffers indicated. *)
VAR
  Buffer       : POINTER TO ARRAY[0..8] OF CHAR;
  MapCount     : CARDINAL;
  Count        : CARDINAL;
  CheckSumCalc,
  CheckSumSent : CHAR;
  TempAdr      : ADDRESS;
  Tilt, Range, Gain : CARDINAL;
  TimeofPic    : Time;
  RTState      : CARDINAL;
BEGIN
  WriteString('DOWNLOADING MAPS...');
  Write('Z'); Delay(15);
  Write(RadarSendMap);
  FOR Count:=0 TO 9 DO
    Read(CheckSumSent);
    WriteString(CheckSumSent);
  END; (* FOR *)
  WriteCard(1,5);
  Buffer:=Map1; MapCount:=1;
  LOOP
    CheckSumCalc:=000c;
    FOR Count:=0 TO 7 DO
      Read(Buffer^[Count]);
      INC(CheckSumCalc,ORD(Buffer^[Count]));
    END; (* FOR *)
    Read(CheckSumSent);
    Delay(10); WriteString('*');
    IF (* CheckSumCalc=CheckSumSent *) TRUE THEN
      Write(RadarAck);
      TempAdr:=Buffer;
      INC(TempAdr,8);
      Buffer:=TempAdr;
      IF (Buffer^[0]=000c) AND (Buffer^[1]=000c) THEN
        INC(MapCount);
        WriteCard(MapCount,4);
        IF MapCount=3 THEN
          Buffer:=Map2;
        ELSIF MapCount=5 THEN
          WriteString('DONE.'); WriteLn;
          EXIT;
        END; (* IF *)
      END; (* IF *)
    ELSE
      Write(RadarNack);
    END; (* IF *)
  END; (* LOOP *)
END Download;

PROCEDURE ClearScreen;
(* Clears circular area of screen in which maps are located. *)
BEGIN
END ClearScreen;

PROCEDURE Display(AtMap : ADDRESS);
(* Displays the map held at address AtMap. *)
BEGIN
END Display;

VAR
  Map1 : ARRAY[0..8191] OF BYTE;
  Map2 : ARRAY[0..8191] OF BYTE;

BEGIN
END Map.
