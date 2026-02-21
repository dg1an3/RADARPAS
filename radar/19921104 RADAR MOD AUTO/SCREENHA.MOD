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

IMPORT Graph, ASCII;
FROM Graphics IMPORT
  SetFunc, clr, or, SetPlane, EnablePlane, FillArea, GotoXY,
  GetWindow, SetWindow, SetFont;
FROM IO IMPORT WrChar, WrStr, WrCard, RdStr, RdKey;
FROM Lib IMPORT
  Move, ScanR, Fill;
FROM Locator IMPORT
  CurrRange, CurrTilt, CursorOn;
FROM SYSTEM IMPORT ADDRESS;
FROM Str IMPORT Length, Concat;
FROM TimeDate IMPORT Time;
FROM E300Interface IMPORT MapEntry, Map;
IMPORT MATHLIB;

PROCEDURE WriteTime(ForTime : Time);
(* Writes time in 7 spaces *)
VAR
  Hour, Minute : CARDINAL;
BEGIN
  Hour:=ForTime.minute DIV 60;
  Minute:=ForTime.minute MOD 60;
  IF ArmyTime OR (Hour<=12) THEN
    WrCard(Hour,2);
  ELSIF (Hour<=23) THEN
    WrCard(Hour-12,2);
  ELSE
    WrCard(24,2);
  END; (* IF *)
  WrChar(':');
  IF Minute<10 THEN WrChar('0'); END;
  WrCard(Minute,0);
  IF ArmyTime THEN
    WrStr('  ');
  ELSIF Hour>11 THEN
    WrStr('pm');
  ELSE
    WrStr('am');
  END; (* IF *)
END WriteTime;

PROCEDURE WriteDate(ForTime : Time);
VAR
  Month, Day, Year : CARDINAL;
BEGIN
  Day := ForTime.day MOD 20H ;
  Month := ForTime.day MOD 200H DIV 20H ;
  Year := ForTime.day DIV 200H ;
  WrCard(Month,0); WrChar('/');
  WrCard(Day,0); WrChar('/');
  IF (Year MOD 100)<10 THEN WrChar('0') END;
  WrCard(Year MOD 100,0);
  IF Month<10 THEN WrChar(' ') END; (* Buffer date with spaces *)
  IF Day<10 THEN WrChar(' '); END;
END WriteDate;

PROCEDURE WriteTilt(Tilt : CARDINAL);
(* Writes tilt in 2 spaces *)
BEGIN
  CASE Tilt OF
    0..6 : WrCard(Tilt,2)|
    7    : WrCard(8,2)|
    8    : WrCard(10,2)|
    9    : WrCard(12,2)|
    10   : WrCard(15,2)|
    11   : WrCard(20,2)
    ELSE WrStr('??');
  END;  (* CASE *)
END WriteTilt;

PROCEDURE WriteRange(Range : CARDINAL);
(* Writes range in 3 spaces *)
BEGIN
  CASE Range OF
    0 : WrCard(10,3)|
    1 : WrCard(25,3)|
    2 : WrCard(50,3)|
    3 : WrCard(100,3)|
    4 : WrCard(200,3)
    ELSE WrStr('???');
  END; (* CASE *)
END WriteRange;

PROCEDURE WriteGain(Gain : CARDINAL);
(* Writes gain in 3 spaces *)
BEGIN
  IF Gain<=16 THEN
    WrCard(Gain,2);
    WrChar( ' ' );
  ELSIF Gain=17 THEN
    WrStr( 'PRE' );
  ELSE
    WrStr( '?? ' );
  END; (* IF *)
END WriteGain;

VAR
  Scale : CARDINAL; (* Stores current range which maps are drawn at *)

PROCEDURE WriteParams(Tilt, Range, Gain : CARDINAL;
                      ForTime : Time;
                      RT      : RTState );
BEGIN
  SetPlane({2});
  SetFunc(clr,0);

  GotoXY(0,0);
  WrStr('TILT  : ');
  WriteTilt(Tilt);

  CASE Tilt OF
    0..6 : CurrTilt := Tilt |
    7    : CurrTilt := 8 |
    8    : CurrTilt := 10 |
    9    : CurrTilt := 12 |
    10   : CurrTilt := 15 |
    11   : CurrTilt := 20 |
    ELSE CurrTilt := 0;
  END;  (* CASE *)

  GotoXY(0,336);
  WrStr('RANGE : ');
  WriteRange(Range);

  CASE Range OF
  0 : Scale := 100 |
  1 : Scale := 250 |
  2 : Scale := 500 |
  3 : Scale := 1000 |
  4 : Scale := 2000
  ELSE
    Scale := 2000;
  END (* CASE *);
  CurrRange := Scale DIV 10;

  GotoXY(520,336);
  WrStr('GAIN : ');
  WriteGain( Gain );

  GotoXY(512,0);
  WrStr('TIME : ');
  WriteTime(ForTime);

  GotoXY(512,14);
  WrStr('DATE : ');
  WriteDate(ForTime);

  SetPlane( {0} );
  GotoXY(288,0);
  IF RT = RTOff THEN

      WrStr(' RT OFF ')

  ELSIF RT = RTOn THEN

      WrStr(' RT ON  ')

  ELSIF RT = RTFault THEN

      WrStr('RT FAULT')

  END (* IF *);

END WriteParams;

PROCEDURE WriteRngMks( On : BOOLEAN );
BEGIN
  IF ~ RngMksOn & On THEN
      RngMksOn := TRUE;
      SetFunc( clr, 0 );
      SetPlane( {2} );
      Graph.Ellipse(320,175, 51, 37,4,FALSE);
      Graph.Ellipse(320,175,102, 75,4,FALSE);
      Graph.Ellipse(320,175,154,112,4,FALSE);
      Graph.Ellipse(320,175,205,149,4,FALSE);
      Graph.Ellipse(320,175,256,186,4,FALSE);
  ELSIF RngMksOn & ~ On THEN
      ClearScreen;
      RngMksOn := FALSE;
      Redraw;
  END (* IF *);
END WriteRngMks;

VAR
  Sin : ARRAY [ 0..359 ] OF INTEGER;
  Cos : ARRAY [ 0..359 ] OF INTEGER;

PROCEDURE WriteMap( Num : CARDINAL; On : BOOLEAN );

VAR

  Count  : CARDINAL;
  X, Y,
  X2, Y2 : CARDINAL;
  Key    : CHAR;

BEGIN

  IF ~ MapOn[Num] & On THEN
      SetFunc( or, 0 );
      SetPlane( {2} );
      SetFont( 8 );
      Count := 1;
      WHILE (ScrnMap[Num,Count].Range # 0) OR (ScrnMap[Num,Count].Bear # 0) DO
        WITH ScrnMap[Num,Count] DO
          IF ( Range <= Scale ) & ( Range >= Scale DIV 10 ) THEN
            X := 308+INTEGER(LONGINT(Cos[Bear])*LONGINT(Range) DIV LONGINT(Scale));
            Y := 171-INTEGER(LONGINT(Sin[Bear])*LONGINT(Range) DIV LONGINT(Scale));
            GotoXY(X,Y);
            WrStr(Ident);
          END (* IF *);
          INC(Count);
          IF Count > HIGH(ScrnMap[Num]) THEN
            SetFont( 14 );
            RETURN;
          END (* IF *);
        END (* WITH *);
      END (* WHILE *);
      SetFunc( clr, 0 );
      SetFont( 14 );
      INC(Count);
      WHILE (ScrnMap[Num,Count].Range1 # 0) OR
          (ScrnMap[Num,Count].Range2 # 0) DO
        WITH ScrnMap[Num,Count] DO
          IF ( Range1 <= Scale ) & ( Range2 <= Scale ) THEN
            X  := 320-INTEGER(LONGINT(Cos[Bear1])*
                  LONGINT(Range1) DIV LONGINT(Scale));
            Y  := 175-INTEGER(LONGINT(Sin[Bear1])*
                  LONGINT(Range1) DIV LONGINT(Scale));
            X2 := 320-INTEGER(LONGINT(Cos[Bear2])*
                  LONGINT(Range2) DIV LONGINT(Scale));
            Y2 := 175-INTEGER(LONGINT(Sin[Bear2])*
                  LONGINT(Range2) DIV LONGINT(Scale));
            Graph.Line(X,Y,X2,Y2,4);
(*            IF ABS(Y2-Y)>ABS(X2-X) THEN
              Graph.Line(X+1,Y,X2+1,Y2,4);
            ELSE
              Graph.Line(X,Y+1,X2,Y2+1,4);
            END (* IF *); *)
          END (* IF *);
        END (* WITH *);
        INC(Count);
        IF Count > HIGH(ScrnMap[Num]) THEN
          MapOn[Num] := On;
          RETURN;
        END (* IF *);
      END (* WHILE *);
  ELSIF MapOn[Num] & ~ On THEN
      ClearScreen;
      MapOn[Num] := FALSE;
      Redraw;
  END (* IF *);
  MapOn[Num] := On;

END WriteMap;

VAR
  HelpMode : CARDINAL;

PROCEDURE SetHelpMode( Mode : CARDINAL );
BEGIN
  HelpMode := Mode;
END SetHelpMode;

PROCEDURE WriteHelp( On : BOOLEAN );
BEGIN
  IF ~ HelpOn & On THEN
      SetPlane( {2} );
      GotoXY( 528, 42 );
      WrStr( 'RúRange marks' );
      GotoXY( 560, 84 );
      WrStr(     'LúLocator' );
      GotoXY( 560, 98 );
      WrStr(     'GúAll gfx' );
      GotoXY( 576, 56 );
      WrStr(       '1úMap 1' );
      GotoXY( 576, 70 );
      WrStr(       '2úMap 2' );
      GotoXY( 584, 112 );
      WrStr(        'HúHelp' );

      CASE HelpMode OF
       1: GotoXY( 0, 42 );
          WrStr( 'F1úStations' );
          GotoXY( 0, 56 );
          WrStr( 'F2úDial' );
          GotoXY( 0, 70 );
          WrStr( 'F3úStorage' );
          GotoXY( 0, 84 );
          WrStr( 'F4úProgram' );

          GotoXY( 0, 280 );
          WrStr( '-úNext Pic' );
          GotoXY( 0, 294 );
          WrStr( '+úPrev Pic' );
          GotoXY( 0, 308 );
          WrStr( 'ESCúExit' ); |

       2: GotoXY( 0, 14 );
          WrStr( 'F1ú F2ú' );
          GotoXY( 0, 322 );
          WrStr( 'F3ú F4ú' );
          GotoXY( 536, 322 );
          WrStr( 'F5ú F6ú' );
          GotoXY( 0, 42 );
          WrStr( 'F7úGet Picture' );

          GotoXY( 0, 308 );
          WrStr( 'ESCúExit' );

      END (* CASE *);
  ELSIF HelpOn & ~ On THEN
      SetPlane( {2} );
      GotoXY( 528, 42 );
      WrStr( '             ' );
      GotoXY( 560, 84 );
      WrStr(     '         ' );
      GotoXY( 560, 98 );
      WrStr(     '         ' );
      GotoXY( 576, 56 );
      WrStr(       '       ' );
      GotoXY( 576, 70 );
      WrStr(       '       ' );
      GotoXY( 584, 112 );
      WrStr(        '      ' );

      CASE HelpMode OF
       1: GotoXY( 0, 42 );
          WrStr( '           ' );
          GotoXY( 0, 56 );
          WrStr( '       ' );
          GotoXY( 0, 70 );
          WrStr( '          ' );
          GotoXY( 0, 84 );
          WrStr( '          ' );

          GotoXY( 0, 280 );
          WrStr( '          ' );
          GotoXY( 0, 294 );
          WrStr( '          ' );
          GotoXY( 0, 308 );
          WrStr( '        ' ); |

       2: GotoXY( 0, 14 );
          WrStr( '         ' );
          GotoXY( 0, 322 );
          WrStr( '         ' );
          GotoXY( 536, 322 );
          WrStr( '         ' );
          GotoXY( 0, 42 );
          WrStr( '              ' );

          GotoXY( 0, 308 );
          WrStr( '        ' );

      END (* CASE *);

  END (* IF *);
  HelpOn := On;

END WriteHelp;


VAR

  Screen [ 0A000H:0000H ] : ARRAY [ 0..28000 ] OF BYTE;


PROCEDURE DrawScale;

VAR
  Count : CARDINAL;

BEGIN

  FOR Count := 0 TO 349 DO
      IF ( Count MOD 100 ) = 0 THEN
          Graph.HLine( 0, Count, 10, 3 );
      ELSIF ( Count MOD 50 ) = 0 THEN
          Graph.HLine( 0, Count, 8, 3 );
      ELSIF ( Count MOD 10 ) = 0 THEN
          Graph.HLine( 0, Count, 6, 3 );
      ELSE
          Graph.HLine( 0, Count, 4, 3 );
      END (* IF *);
  END (* FOR *);

END DrawScale;


PROCEDURE ComprLine( Number        : CARDINAL;
                     VAR Red, Grn  : ARRAY OF BYTE;
                     VAR Buffer    : ARRAY OF BYTE;
                     VAR DestAt    : CARDINAL );
VAR

   SrcAt,
   Count : CARDINAL;

BEGIN

  SetPlane( {0} );
  Move( ADR(Red), ADR(Screen[ Number * 35 DIV 48 * 80 ]), 160 );

  SetPlane( {1} );
  Move( ADR(Grn), ADR(Screen[ Number * 35 DIV 48 * 80 ]), 160 );

  SrcAt := 0;
  REPEAT

      IF Red[SrcAt] = BYTE(00H) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Red) ) & ( Red[SrcAt] = BYTE(00H) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );
(*              GotoXY( 50, 0 );
              WrCard( Count, 5 );
              WrCard( SrcAt, 5 );
              WrCard( DestAt, 5 ); *)

          END (* WHILE *);

          Buffer[DestAt] := 00H;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );
(*          GotoXY( 300, 0 );
          WrStr('OUT OF LOOP'); *)

      ELSIF Red[SrcAt] = BYTE(0FFH) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Red) ) & ( Red[SrcAt] = BYTE(0FFH) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 377C;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSE

          Buffer[DestAt] := Red[SrcAt];
          INC( DestAt );
          INC( SrcAt );

      END (* IF *);

  UNTIL SrcAt >= HIGH(Red);


  SrcAt := 0;
  REPEAT

      IF Grn[SrcAt] = BYTE(00H) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Grn) ) & ( Grn[SrcAt] = BYTE(00H) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 00H;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSIF Grn[SrcAt] = BYTE(0FFH) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Grn) ) & ( Grn[SrcAt] = BYTE(0FFH) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 377C;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSE

          Buffer[DestAt] := Grn[SrcAt];
          INC( DestAt );
          INC( SrcAt );

      END (* IF *);

  UNTIL SrcAt >= HIGH(Grn);


END ComprLine;



PROCEDURE WritePic( VAR Buffer : ARRAY OF BYTE; BufSize : CARDINAL );

VAR
  TCount,
   SrcAt,
  DestAt,
  LineAt,
   Count : CARDINAL;
  RedMap : BOOLEAN;

BEGIN

  SrcAt := 0;
  DestAt := 0;
  LineAt := 0;
  RedMap := TRUE;
  Count := 0;
  TCount := 0;
  SetPlane( {0} );

  WHILE ( SrcAt <= BufSize ) & ( DestAt <= 28000 ) DO

      IF ( Buffer[SrcAt] = BYTE(00H) ) OR ( Buffer[SrcAt] = BYTE(0FFH) ) THEN

          (* Write fill to next 80 byte boundary *)
          IF Count = 0 THEN
              Count := CARDINAL(Buffer[SrcAt+1]);
              TCount := TCount + Count;
          END (* IF *);

          IF Count <= 80 - ( DestAt MOD 80 ) THEN

              Fill( ADR(Screen[DestAt]), Count, Buffer[SrcAt] );
              INC( DestAt, Count );
              Count := 0;
              INC( SrcAt, 2 );

          ELSE

              Fill( ADR(Screen[DestAt]), 80 - ( DestAt MOD 80 ),
                  Buffer[SrcAt] );
              Count := Count + ( DestAt MOD 80 ) - 80;
              DestAt := DestAt + 80 - ( DestAt MOD 80 );

          END (* IF *);

      ELSE

          Screen[DestAt] := Buffer[SrcAt];
          INC( DestAt );
          INC( SrcAt );
          INC( TCount );

      END (* IF *);

      IF ( DestAt MOD 80 ) = 0 THEN

          INC( LineAt );

          IF ~ ODD(LineAt) THEN

              RedMap := ~ RedMap;

              IF RedMap THEN

                  SetPlane( {0} );
                  DestAt := LineAt * 35 DIV 48 * 80;

              ELSE

                  DEC( LineAt, 2 );
                  SetPlane( {1} );
                  DestAt := LineAt * 35 DIV 48 * 80;

              END (* IF *);

          END (* IF *);

      END (* IF *);

  END (* WHILE *);
(*  Message( 'TOTAL:     ' );
  WrChar( ASCII.bs );
  WrChar( ASCII.bs );
  WrChar( ASCII.bs );
  WrChar( ASCII.bs );
  WrChar( ASCII.bs );
  WrCard( TCount, 1 ); *)

END WritePic;

PROCEDURE ClearScreen;
BEGIN
  SetPlane( {2,3} );
  SetFunc( clr, 0 );
  Graph.Ellipse(320,175,256,186,0,TRUE);
END ClearScreen;

PROCEDURE Redraw;
BEGIN
  IF MapOn[1] THEN
      MapOn[1] := FALSE;
      WriteMap( 1, TRUE );
  END (* IF *);
  GotoXY( 0, 114 );
  IF MapOn[2] THEN
      MapOn[2] := FALSE;
      WriteMap( 2, TRUE );
  END (* IF *);
  GotoXY( 0, 128 );
  IF RngMksOn THEN
      RngMksOn := FALSE;
      WriteRngMks( TRUE );
  END (* IF *);
END Redraw;

VAR

  GraphOn : BOOLEAN;

PROCEDURE ToggleGraphics;
BEGIN
  GraphOn := ~ GraphOn;
  IF GraphOn THEN
      EnablePlane( {0,1,2,3} );
  ELSE
      EnablePlane( {0,1} );
  END (* IF *);
END ToggleGraphics;

VAR
  MessLength : CARDINAL;

PROCEDURE Message(String : ARRAY OF CHAR);
VAR
  X1, Y1, XS, YS : INTEGER;
BEGIN
  GetWindow( X1, Y1, XS, YS );
  SetWindow( 0, 0, 639, 349 );
  IF MessLength # 0 THEN
    SetPlane({2,3});
    SetFunc(clr,0);
    FillArea(320-MessLength*4,336,MessLength*8,14,CARDINAL(0));
  END (* IF *);
  IF Length(String) = 0 THEN
    MessLength := 0;
    RETURN;
  END (* IF *);
  MessLength := Length(String);
  SetPlane({2});
  FillArea(320-MessLength*4,336,MessLength*8,14,CARDINAL(0FFFFH));
  SetPlane({3});
  SetFunc(or,0);
  GotoXY(320-MessLength*4,336);
  WrStr(String);
  SetWindow( X1, Y1, XS, YS );
END Message;

PROCEDURE Prompt(String : ARRAY OF CHAR; VAR Response : ARRAY OF CHAR);
VAR
  MessString : ARRAY [ 0..79 ] OF CHAR;
  X1, Y1, XS, YS : INTEGER;
  Key : CHAR;
BEGIN
  GetWindow( X1, Y1, XS, YS );
  SetWindow( 0, 0, 639, 349 );
  Concat(MessString,String,'                                                  ');
  MessString[ Length(String)+HIGH(Response) ] := 000C;
  Message(MessString);
  GotoXY(320-MessLength*4+Length(String)*8,336);
  Response[ 0 ] := 000C;
  REPEAT
    SetFunc(clr,0);
    WrChar( 'Û' );
    WrChar( ASCII.bs );
    Key := RdKey();
    WrChar( ' ' );
    WrChar( ASCII.bs );
    SetFunc(or,0);
    IF (Key >= ' ') & ( Key <= '~' ) THEN
        WrChar( Key );
        Concat( Response, Response, Key );
    ELSIF Key = ASCII.bs THEN
        Response[ Length(Response)-1 ] := 000C;
        WrChar( ' ');
        WrChar( ASCII.bs );
        WrChar( ASCII.bs );
    END (* IF *);
  UNTIL ( Key = ASCII.cr );
  SetWindow( X1, Y1, XS, YS );
END Prompt;

PROCEDURE Pause(String : ARRAY OF CHAR) : CHAR;
VAR
  Key : CHAR;
BEGIN
  Message(String);
  Key := RdKey();
  Message('');
  RETURN Key;
END Pause;

VAR

  Count : INTEGER;

BEGIN
  ArmyTime:=FALSE;
  MessLength:=0;
  HelpOn := FALSE;
  RngMksOn := FALSE;
  MapOn[1] := FALSE;
  MapOn[2] := FALSE;
  FOR Count := 0 TO 359 DO
    Sin[Count] := INTEGER(MATHLIB.Sin(LONGREAL(Count+90)*3.141592654/180.0)*187.0);
    Cos[Count] := INTEGER(MATHLIB.Cos(LONGREAL(Count-90)*3.141592654/180.0)*256.0);
  END (* FOR *);
END ScreenHandler.
