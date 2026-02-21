MODULE RadarVersion2point0;

(*            C R E A T E D  : 1/3/87
 *        L A S T   E D I T  : 9/30/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *     
 *)

FROM Control IMPORT 
  GetParam, SetParam;
FROM EGALib IMPORT
  GotoXY;
FROM ExtendKey IMPORT 
  F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, ExtRead;
FROM InOut IMPORT
  WriteString;
FROM Modem IMPORT 
  Call, HangUp, State, StateCode, Result, ResultCode;
IMPORT Picture;
FROM SYSTEM IMPORT 
  BYTE, ADR;
FROM ScreenHandler IMPORT
  WriteParams, Message, ToggleRangeMarks, ToggleMap;
FROM TimeDate IMPORT Time;

PROCEDURE StationMenu;
BEGIN
END StationMenu;

VAR
  Map1   : ARRAY[0..8191] OF BYTE;
  Map2   : ARRAY[0..8191] OF BYTE;
  Buffer : ARRAY[0..32767] OF BYTE;
   
PROCEDURE Interact;
VAR
  Tilt, Range, Gain : CARDINAL;
  TimeofPic         : Time;
  RTState           : CARDINAL;
  Key               : CHAR;
  Extend            : BOOLEAN;
  Size              : CARDINAL;
BEGIN
  GetParam(Tilt,Range,Gain,TimeofPic,RTState);
(*  IF Map.CheckMaps(ADR(Map1),ADR(Map2)) THEN
    Message('ONE MOMENT, PLEASE.  DOWNLOADING MAPS...');
    Map.Download(ADR(Map1),ADR(Map2));
    Message('');
  END; (* IF *) *)
  LOOP
    ExtRead(Key,Extend);
    IF Extend THEN (* Process extended keys *)
      CASE Key OF
        F1 : INC(Tilt);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F2 : DEC(Tilt);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F3 : INC(Range);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F4 : DEC(Range);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F5 : INC(Gain);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F6 : DEC(Gain);
             SetParam(Tilt,Range,Gain,TimeofPic,RTState);
             WriteParams(Tilt,Range,Gain,TimeofPic);
|       F7 : Message('WAITING FOR PICTURE');
(*             DrawScale; 
             Picture.Wait;
             Message('RECEIVING PICTURE');
             Picture.Download(ADR(Buffer),Size); *)
        ELSE
      END; (* CASE *)
    ELSE
      CASE Key OF (* Process regular keys *)
(*        'H','h'  : Help.Toggle;
|*)       'R','r'  : ToggleRangeMarks;
|       '1'      : ToggleMap(1);
|       '2'      : ToggleMap(2);
(* |       'G'      : ScreenHandler.ToggleWhite; *)
        ELSE
      END; (* CASE *)
    END; (* IF *)
  END; (* LOOP *)
END Interact;

VAR
  Key    : CHAR;
  Extend : BOOLEAN;
BEGIN
  SelectPlane({2});
  GotoXY(192,294); WriteString('E300 IBM Terminal Software');
  GotoXY(240,308); WriteString('version 2.0');
  GotoXY(264,322); WriteString('Copyright (C) 1987, by D. Lane');
  StationMenu;
  LOOP
    ExtRead(Key,Extend);
    IF Extend THEN
      CASE Key OF (* Process extended key *)
        F1 : StationMenu;
|       F2 : Call('1 532 3414');
             IF State=onLine THEN
               Interact;
             ELSE
               CASE Result OF
                 noCarrier  : Message('NO CARRIER');
|                noDialtone : Message('NO DIALTONE');
|                busy       : Message('BUSY');
|                noAnswer   : Message('NO ANSWER');
                 ELSE Message('MODEM ERROR');
               END; (* CASE *)
             END; (* IF *)
(*|       F3 : PictureMenu; *)
        ELSE
      END; (* CASE *)
    ELSE
      CASE Key OF (* Process regular keys *)
(*        'H','h'  : Help.Toggle;
|*)       'R','r'  : ToggleRangeMarks;
|       '1'      : ToggleMap(1);
|       '2'      : ToggleMap(2);
(* |       'G'      : ToggleWhite; *)
        ELSE
      END; (* CASE *)
    END; (* IF *)
  END; (* LOOP *)
END RadarVersion2point0.
