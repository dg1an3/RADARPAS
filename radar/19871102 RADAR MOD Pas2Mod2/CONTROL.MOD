IMPLEMENTATION MODULE Control;

(*********************************************************)
(* VERSION : 1/26/86                                     *)
(* CREATED : 1/26/86                                     *)
(*  AUTHOR : Derek Lane                                  *)
(*  SYSTEM : LOGITECH MODULA-2/86                        *)
(*                                                       *)
(*  Reading and setting the remote radar's parameters.   *)
(*  All of these procedures assume that the radar is     *)
(*  connected and online.                                *)
(*                                                       *)
(*********************************************************)

FROM RS232Int IMPORT BusyRead, Write;
FROM SYSTEM IMPORT AX, SETREG, GETREG, CODE, ADR;
FROM TimeDate IMPORT Time, GetTime;

PROCEDURE Delay(Milli : CARDINAL);
(* Milli must be between 0 and 60000!!! *)
VAR
  StartTime, CurrTime : Time;
BEGIN
  GetTime(StartTime);
  LOOP
    GetTime(CurrTime);
    IF CurrTime.millisec>=StartTime.millisec THEN
      IF CurrTime.millisec-StartTime.millisec>=Milli THEN EXIT END;
    ELSIF 60000-StartTime.millisec+CurrTime.millisec>=Milli THEN
      EXIT
    END; (* IF *)
  END; (* LOOP *)
END Delay;

PROCEDURE TimeRead(VAR ForChar : CHAR; Milli : CARDINAL);
(* Milli must be between 0 and 60000!!! *)
VAR
  OK : BOOLEAN;
  StartTime, CurrTime : Time;
BEGIN
  GetTime(StartTime);
  LOOP
    BusyRead(ForChar,OK);
    IF OK THEN EXIT; END;
    GetTime(CurrTime);
    IF CurrTime.millisec>=StartTime.millisec THEN
      IF CurrTime.millisec-StartTime.millisec>=Milli THEN EXIT END;
    ELSIF 60000-StartTime.millisec+CurrTime.millisec>=Milli THEN
      EXIT
    END; (* IF *)
  END; (* LOOP *)
END TimeRead;

CONST
  RadarAck      = 'A';
  RadarNack     = 000c;

PROCEDURE ReadParam(VAR Tilt, Range, Gain : CARDINAL;
                    VAR TimeofPic         : Time;
                    VAR RTState           : CARDINAL);
VAR
  Buffer       : ARRAY[0..8] OF CHAR;
  Count        : CARDINAL;
  CheckSumCalc,
  CheckSumSent : CHAR;
  Hour,Minute  : CARDINAL;
BEGIN
  LOOP
    CheckSumCalc:=000c;
    TimeRead(Buffer[0],100);
    FOR Count:=1 TO 8 DO
      TimeRead(Buffer[Count],100);
      INC(CheckSumCalc,ORD(Buffer[Count]));
    END; (* FOR *)
    TimeRead(CheckSumSent,100);
    IF (Buffer[0]='Q') AND (CheckSumCalc=CheckSumSent) THEN
      Write(RadarAck);
      IF 5 IN BITSET(ORD(Buffer[2])) THEN
        Gain:=17;
      ELSE
        Gain:=ORD(Buffer[1]) DIV 16+1;
      END; (* IF *)
      Tilt:=12-(ORD(Buffer[2]) MOD 16);
      SETREG(AX,Buffer[3]);
      CODE(24H,38H); (* AND AL,38H *)
      GETREG(AX,Buffer[3]);
      CASE ORD(Buffer[3]) OF
        28H : Range:=0
|       08H : Range:=1
|       30H : Range:=2
|       00H : Range:=3
|       20H : Range:=4
        ELSE
      END; (* CASE *)
      Hour:=(ORD(Buffer[5])-48)*10+(ORD(Buffer[6])-48);
      Minute:=(ORD(Buffer[7])-48)*10+(ORD(Buffer[8])-48);
      TimeofPic.minute:=Hour*60+Minute;
      EXIT;
    ELSE
      Write(RadarNack);
    END; (* IF *)
  END; (* LOOP *)
END ReadParam;

CONST
  RadarSendParam = 'X';
  RadarTiltUp    = 002c;
  RadarTiltDown  = 005c;
  RadarRangeUp   = 003c;
  RadarRangeDown = 006c;
  RadarGainUp    = 015c;
  RadarGainDown  = 016c;

PROCEDURE GetParam(VAR Tilt, Range, Gain : CARDINAL;
                   VAR TimeofPic         : Time;
                   VAR RTState           : CARDINAL);
(* Sets the parameters in CurrParam^ to match the radar *)
VAR
  Count : CARDINAL;
BEGIN
  Write('Z');  Delay(15);
  Write(RadarSendParam);
  ReadParam(Tilt,Range,Gain,TimeofPic,RTState);
END GetParam;

PROCEDURE SetParam(Tilt, Range, Gain : CARDINAL;
               VAR TimeofPic : Time;
               VAR RTState   : CARDINAL);
(* Sets the radar to match the parameters in CurrParam^ *)
VAR
  CurrTilt,
  CurrRange,
  CurrGain  : CARDINAL;
BEGIN
  GetParam(CurrTilt,CurrRange,CurrGain,TimeofPic,RTState);
  LOOP
    IF Tilt>CurrTilt THEN
      Write('Z'); Delay(10); Write(RadarTiltUp);
    ELSIF Tilt<CurrTilt THEN
      Write('Z'); Delay(10); Write(RadarTiltDown);
    ELSIF Range>CurrRange THEN
      Write('Z'); Delay(10); Write(RadarRangeUp);
    ELSIF Range<CurrRange THEN
      Write('Z'); Delay(10); Write(RadarRangeDown);
    ELSIF Gain>CurrGain THEN
      Write('Z'); Delay(10); Write(RadarGainUp);
    ELSIF Gain<CurrGain THEN
      Write('Z'); Delay(10); Write(RadarGainDown);
    ELSE
      EXIT;
    END; (* IF *)
    ReadParam(CurrTilt,CurrRange,CurrGain,TimeofPic,RTState);
  END; (* LOOP *)
END SetParam;

END Control.
