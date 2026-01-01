IMPLEMENTATION MODULE E300Interface;

(* CREATED : 5/17/88
 *  EDITED : 5/18/88
 *  AUTHOR : Derek Lane
 *  SYSTEM : Logitech Modula-2/86, version 3.03
 *
 *  Consolidates all information of the communications interface
 *  with an E300 Weather Radar.
 *
 *  GetParam and SetParam are for getting and setting the radar's
 *  parameters.  The three parameters Range, Gain, and Tilt may
 *  be set with SetParam, are read with GetParam.  Both return
 *  the TimeofPic and the RT state.
 *
 *  MakePic and GetLine are for downloading the weather picture.
 *  Once the parameters are set satisfactorily, a call to MakePic
 *  will initiate
 *)

IMPORT ASCII;
IMPORT IO;
(* FROM ScreenHandler IMPORT Message; *)
FROM Lib IMPORT
  Fill;
FROM rs IMPORT
  Send, Receive, TxCount, RxCount;
FROM SYSTEM IMPORT
  WORD, BYTE, ADR, SIZE;
FROM TimeDate IMPORT
  Time, GetTime;

(* EXPORT QUALIFIED
 *   TiltType, RangeType, GainType, RTState,
 *   GetParam, SetParam,
 *
 *   MakePic, GetLine,
 *
 *   Map, CheckMaps;
 *)

(* TYPE
 *   TiltType  = [ 0..11 ];
 *   RangeType = [ 0..4 ];
 *   GainType  = [ 1..17 ];
 *   RTState   = ( RTOn, RTOff, RTFault );
 *)

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
    END (* IF CurrTime.millisec... *);
  END (* LOOP *);
END Delay;

PROCEDURE TimeRead(VAR ForChar : CHAR; Milli : CARDINAL);
(* Milli must be between 0 and 60000!!! *)
VAR
  OK         : BOOLEAN;
  StartTime,
  CurrTime   : Time;
  Key        : CHAR;
BEGIN
  GetTime(StartTime);
  LOOP
    IF RxCount() > 0 THEN
      Receive(ForChar,1);
      EXIT;
    END (* IF *);
    GetTime(CurrTime);
    IF CurrTime.millisec>=StartTime.millisec THEN
      IF CurrTime.millisec-StartTime.millisec>=Milli THEN EXIT END;
    ELSIF 60000-StartTime.millisec+CurrTime.millisec>=Milli THEN
      ForChar := 000C;
(*D   IO.WrStr( 'TIME-OUT' ); *)
      EXIT;
    END (* IF *);
  END (* LOOP *);
END TimeRead;

CONST (* Radar command codes *)
  Ack       = 101C;
  Nack      = 000C;
  XON       = 117C;
  SendParam = 130C;
  TiltUp    = 002C;
  TiltDown  = 005C;
  RangeUp   = 003C;
  RangeDown = 006C;
  GainUp    = 015C;
  GainDown  = 016C;
  SendPic   = 004C;

PROCEDURE ReadParam
 ( VAR Tilt      : TiltType;
   VAR Range     : RangeType;
   VAR Gain      : GainType;
   VAR TimeofPic : Time;
   VAR RT        : RTState );
VAR
  Buffer       : ARRAY[0..8] OF CHAR;
  Count        : CARDINAL;
  NumTries     : CARDINAL;
  CheckSumCalc,
  CheckSumSent : CHAR;
  Hour,Minute  : CARDINAL;
BEGIN
  NumTries := 0;
  LOOP
    IF IO.KeyPressed() THEN
      RETURN;
    END (* IF *);
    CheckSumCalc:=000C;
    TimeRead(Buffer[0],1000);
    IF Buffer[0] # 'Q' THEN
        EXIT;
    END (* IF *);
    FOR Count:=1 TO 8 DO
      TimeRead(Buffer[Count],1000);
      INC(CheckSumCalc,ORD(Buffer[Count]));
    END (* FOR *);
    TimeRead(CheckSumSent,100);
    IF (Buffer[0]='Q') (* AND (CheckSumCalc=CheckSumSent) *) THEN
      Send(Ack,1);
      IF 5 IN BITSET(ORD(Buffer[2])) THEN
        Gain := 17;
      ELSE
        Gain := 1 + ORD(Buffer[1]) DIV 16;
      END (* IF *);
      Tilt:=12-(ORD(Buffer[2]) MOD 16);
      CASE CARDINAL(BITSET(Buffer[3]) * BITSET(38H)) OF
        28H : Range:=0; |
        08H : Range:=1; |
        30H : Range:=2; |
        00H : Range:=3; |
        20H : Range:=4;
        ELSE
      END (* CASE *);
      Hour:=(ORD(Buffer[5])-48)*10+(ORD(Buffer[6])-48);
      Minute:=(ORD(Buffer[7])-48)*10+(ORD(Buffer[8])-48);
      TimeofPic.minute:=Hour*60+Minute;
      EXIT;
    ELSIF NumTries < 20 THEN
      Send(Nack,1);
      INC( NumTries );
    ELSE
      Tilt := 255;
      Range := 255;
      Gain := 255;
      EXIT;
    END (* IF *);
  END (* LOOP *);

(*  IO.WrStr( ' TILT : ' );
  IO.WrCard( Tilt, 1 );
  IO.WrLn;
  IO.WrStr( 'RANGE : ' );
  IO.WrCard( Range, 1 );
  IO.WrLn;
  IO.WrStr( ' GAIN : ' );
  IO.WrCard( Gain, 1 );
  IO.WrLn; *)

END ReadParam;

VAR
  CurrTilt  : TiltType;
  CurrRange : RangeType;
  CurrGain  : GainType;

PROCEDURE GetParam
 ( VAR Tilt      : TiltType;
   VAR Range     : RangeType;
   VAR Gain      : GainType;
   VAR TimeofPic : Time;
   VAR RT        : RTState );
VAR
  Count : CARDINAL;
BEGIN
  Send('Z',1);
  Delay(15);
  Send(SendParam,1);
  ReadParam(Tilt,Range,Gain,TimeofPic,RT);
  CurrTilt := Tilt;
  CurrRange := Range;
  CurrGain := Gain;
END GetParam;

PROCEDURE SetParam
 (     Tilt      : TiltType;
       Range     : RangeType;
       Gain      : GainType;
   VAR TimeofPic : Time;
   VAR RT        : RTState );
BEGIN
  LOOP
    IF IO.KeyPressed() THEN
      RETURN;
    END (* IF *);
    IF Tilt>CurrTilt THEN
(*      IO.WrStr(' TILT UP...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(TiltUp,1);
    ELSIF Tilt<CurrTilt THEN
(*      IO.WrStr(' TILT DOWN...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(TiltDown,1);
    ELSIF Range>CurrRange THEN
(*      IO.WrStr(' RANGE UP...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(RangeUp,1);
    ELSIF Range<CurrRange THEN
(*      IO.WrStr(' RANGE DOWN...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(RangeDown,1);
    ELSIF Gain>CurrGain THEN
(*      IO.WrStr(' GAIN UP...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(GainUp,1);
    ELSIF Gain<CurrGain THEN
(*      IO.WrStr(' GAIN DOWN...' );
      IO.WrLn; *)
      Send('Z',1);
      Delay(10);
      Send(GainDown,1);
    ELSE
      EXIT;
    END (* IF Tilt... *);
    ReadParam(CurrTilt,CurrRange,CurrGain,TimeofPic,RT);
    IF CurrTilt > MAX( TiltType ) THEN EXIT END;
    Delay( 100 );
  END (* LOOP *);
END SetParam;

VAR
  WaitCode    : ARRAY [ 0..26 ] OF CHAR;
  Count       : CARDINAL;

PROCEDURE MakePic;

VAR
  TimeofPic : Time;
  RT        : RTState;

BEGIN
  Send('Z',1); Delay(15);
  Send(SendPic,1);
  ReadParam( CurrTilt, CurrRange, CurrGain, TimeofPic, RT );
  Count := 0;
END MakePic;

PROCEDURE PicReady() : BOOLEAN;
BEGIN
  WHILE RxCount()>0 DO
    Receive( WaitCode[Count], 1 );
(*    IO.WrCard( ORD(WaitCode[Count]), 5 );
    IO.WrCard( ORD(WaitCode[Count-1]), 5 );
    IO.WrCard( ORD(WaitCode[Count-2]), 5 );
    IO.WrLn; *)
    IF (Count>1) & (WaitCode[Count] = 375C) & (WaitCode[Count-1] = 376C) &
      (WaitCode[Count-2] = 377C) THEN
      RETURN( TRUE );
    END (* IF *);
    INC(Count);
  END (* WHILE *);
  RETURN( FALSE );
END PicReady;

PROCEDURE GetLine
 ( VAR LineNum   : CARDINAL;
   VAR RedBitMap : ARRAY OF BYTE;
   VAR GrnBitMap : ARRAY OF BYTE );
(* Returns FALSE in PicReady until the picture is
 * being transmitted.  After that, successive calls
 * return the picture one line at a time as red and
 * green bit maps.  LineNum tells the line number,
 * ranging from 0 to 479 by 2 (since each line sent
 * is actually two screen lines).  Currently, the
 * bit maps are each 1280 pixels wide, which means
 * 160 bytes or 80 words for each bit map.
 *)
VAR
  Count        : CARDINAL;
  Buffer       : RECORD
    CASE : CARDINAL OF
      1 : LineNum : CARDINAL; |
      2 : ChrData : ARRAY [ 0..2561 ] OF CHAR; |
      3 : Data    : ARRAY [ 0..1280 ] OF CARDINAL; |
    END; (* CASE : CARDINAL *)
  END; (* RECORD *)
  CheckSumCalc,
  CheckSumSent : CHAR;
  Rep,
  AtByte, AtBit,
  Size          : CARDINAL;
  Value         : BYTE;
  Color         : BITSET;
BEGIN
  LOOP
    Count := 0;
    CheckSumCalc := 000C;
    REPEAT
      Receive(Buffer.ChrData[Count],1);
      INC(CheckSumCalc,ORD(Buffer.ChrData[Count]));
      INC(Count);
    UNTIL (Count>=2) AND (Count MOD 2=0)
    AND (Buffer.ChrData[Count-2]=030C);
    Receive(CheckSumSent,1);
    IF CheckSumCalc=CheckSumSent THEN
      Send(Ack,1);
      EXIT;
    END (* IF CheckSumCalc... *);
    Send(Nack,1);
  END (* LOOP *);
  WITH Buffer DO
    IF LineNum<38400 THEN
      AtByte := 0;
      AtBit := 0;
      Count := 1;
      Fill(ADR(RedBitMap),SIZE(RedBitMap),0);
      Fill(ADR(GrnBitMap),SIZE(GrnBitMap),0);
      REPEAT
        Size:=Data[Count] DIV 256 + Data[Count] MOD 32 * 256;
        Color := BITSET(Data[Count] >> 5) * BITSET(03H);
        IF Size+AtBit<=8 THEN
          Value := BYTE(0FFH) >> BYTE(8-Size) << BYTE(AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF 0 IN Color... *)
          IF 1 IN Color THEN (* 1 = Green *)
            INC(GrnBitMap[AtByte],Value);
          END; (* IF 1 IN Color... *)
          AtBit:=AtBit+Size;
        ELSIF Size+AtBit<=1288 THEN
          Value := BYTE(0FFH) << BYTE(AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF *)
          IF 1 IN Color THEN
            INC(GrnBitMap[AtByte],Value);
          END;(* IF *)
          Size := Size+AtBit-8;
          AtBit := 0;
          AtByte := AtByte+1;
          IF Size+AtBit>8 THEN
            AtBit := Size MOD 8;
            Size := Size DIV 8;
            Value := BYTE(0FFH);
            IF 0 IN Color THEN (* 0 = Red *)
              Fill(ADR(RedBitMap[AtByte]),Size,Value);
            END (* IF 0 IN Color *);
            IF 1 IN Color THEN (* 1 = Green *)
              Fill(ADR(GrnBitMap[AtByte]),Size,Value);
            END (* IF 1 IN Color *);
            AtByte:=AtByte+Size;
          ELSE
            AtBit:=Size;
          END; (* IF *)
          Value := BYTE(0FFH) >> BYTE(8-AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF *)
          IF 1 IN Color THEN (* 1 = Green *)
            INC(GrnBitMap[AtByte],Value);
          END; (* IF *)
        ELSE
          Count := 641; (* Size>1280, so abort *)
        END (* IF Size+AtBit... *);
        Count := Count+1;
      UNTIL (Count>640) OR (Data[Count]=1818H);
    END (* IF LineNum... *)
  END (* WITH *);
  Send(XON,1);
  LineNum := Buffer.LineNum DIV 40;
END GetLine;

PROCEDURE AbortPic;
(* Aborts picture reception.  Call only if downloading a picture. *)
BEGIN
END AbortPic;

(* TYPE
 *   Map = RECORD
 *     Landmarks = ARRAY [ 0..72 ] OF RECORD
 *       Ident   :   ARRAY [ 0..2 ] OF CHAR;
 *       Range   :   CARDINAL; (* 10ths of miles *)
 *       Bearing :   CARDINAL; (* degrees *)
 *     END; (* RECORD Landmarks *)
 *     Segments  = ARRAY [ 0..500 ] OF RECORD
 *       Range1  :   CARDINAL; (* 10ths of miles *)
 *       Bear1   :   CARDINAL; (* degrees *)
 *       Range2  :   CARDINAL; (* 10ths of miles *)
 *       Bear2   :   CARDINAL; (* degrees *)
 *     END; (* RECORD Segments *)
 *   END; (* RECORD Map *)
 *)

PROCEDURE CheckMaps( Map1 : Map ) : BOOLEAN;
(* Calls a map check for the remote radar to see if a new version
 * of the map needs to be downloaded.  If so, the new version is
 * downloaded and stored in Map1 and Map2, and New is returned
 * TRUE.
 *)
BEGIN
(*  Send('Z',1000);
  Delay(10);
  Send(RadarMapCheck,1);
  GetParam(Tilt,Range,Gain,TimeofPic,RT);
  Receive(Char,1);
  Receive(Landmark,SIZE(Landmark);
  IF Map1.Landmarks[0] # TestLandmark THEN
  END (* IF *); *)
  RETURN( TRUE );
END CheckMaps;

PROCEDURE GetMaps( VAR Map1, Map2 : Map );
(* Downloads new maps. *)
BEGIN
END GetMaps;

END E300Interface.
