IMPLEMENTATION MODULE CDScrn;

(*********************************************************)
(* Created   : 11/14/90                                  *)
(* Last Edit :                                           *)
(* Author    : D. Lane                                   *)
(* System    : TopSpeed Modula-2                         *)
(*                                                       *)
(* Screen handler for radar terminal.  Controls most     *)
(* elements of the screen.                               *)
(*********************************************************)

IMPORT Graph, ASCII;
FROM Graphics IMPORT
  SetFunc, clr, or, xor, SetPlane, EnablePlane, FillArea, GotoXY,
  GetWindow, SetWindow, SetFont, ReadChar;
FROM IO IMPORT WrChar, WrStr, WrCard, WrLngReal, RdStr, RdKey;
FROM Lib IMPORT
  Move, ScanR, Fill;
FROM SYSTEM IMPORT ADDRESS;
FROM Str IMPORT Length, Concat, Slice, Copy;
IMPORT MATHLIB;


CONST
  Pi = 3.14159265358;

TYPE
    SinCosTable  =  ARRAY [ 0..360 ] OF INTEGER;


VAR
    Sin, Cos : SinCosTable;


PROCEDURE WriteRngMks;
BEGIN
      SetFunc( clr, 0 );
      SetPlane( {3} );
      Graph.Ellipse(320,175, 51, 37,8,FALSE);
      Graph.Ellipse(320,175,102, 75,8,FALSE);
      Graph.Ellipse(320,175,154,112,8,FALSE);
      Graph.Ellipse(320,175,205,149,8,FALSE);
      Graph.Ellipse(320,175,256,186,8,FALSE);
END WriteRngMks;



PROCEDURE WriteGrid;

BEGIN

    Graph.Line( 474,  26, 166,  26, 8 );
    Graph.Line( 474, 324, 166, 324, 8 );
    Graph.Line( 525,  63, 115,  63, 8 );
    Graph.Line( 525, 287, 115, 287, 8 );
    Graph.Line( 555, 100, 85, 100, 8 );
    Graph.Line( 555, 250, 85, 250, 8 );
    Graph.Line( 571, 138, 69, 138, 8 );
    Graph.Line( 571, 212, 69, 212, 8 );
    Graph.Line( 576, 175, 64, 175, 8 );

    Graph.Line( 320,   0, 320, 350, 8 );
    Graph.Line( 371,   0, 371, 350, 8 );
    Graph.Line( 269,   0, 269, 350, 8 );
    Graph.Line( 422,   4, 422, 346, 8 );
    Graph.Line( 218,   4, 218, 346, 8 );
    Graph.Line( 474,  26, 474, 324, 8 );
    Graph.Line( 166,  26, 166, 324, 8 );
    Graph.Line( 525,  63, 525, 287, 8 );
    Graph.Line( 115,  63, 115, 287, 8 );

END WriteGrid;


PROCEDURE WriteMap( Num : CARDINAL );

VAR

  Count, ZCount  : CARDINAL;
  X, Y,
  X2, Y2 : INTEGER;
  Key    : CHAR;

BEGIN

      SetFunc( or, 0 );
      SetPlane( {3} );
      SetFont( 14 );
      Count := 1;
      WHILE (ScrnMap[Num,Count].Range # 0) OR (ScrnMap[Num,Count].Bear # 0) DO
        WITH ScrnMap[Num,Count] DO
          IF ( Range <= CurrRange*10 ) & ( Range >= CurrRange*3 DIV 2 ) THEN
            X := 308+INTEGER(LONGINT(Cos[Bear MOD 360])*LONGINT(Range)
                DIV LONGINT( CurrRange*10 ));
            Y := 168-INTEGER(LONGINT(Sin[Bear MOD 360])*LONGINT(Range)
                DIV LONGINT( CurrRange*10 ));
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
      ZCount := 0;
      WHILE ZCount < 3 DO (* (ScrnMap[Num,Count].Range1 # 0) OR
          (ScrnMap[Num,Count].Range2 # 0) DO *)
        IF ScrnMap[Num,Count].EndFlag = 0 THEN
            INC( ZCount );
        END (* IF *);
            WITH ScrnMap[Num,Count] DO
                IF ( Range1 <= CurrRange*10 ) & ( Range2 <=
                    CurrRange*10 ) THEN

                    X  :=  320+INTEGER(
                    MATHLIB.Sin( LONGREAL( Bear1 ) * Pi / 180.0 ) *
                    LONGREAL( Range1 ) / LONGREAL( CurrRange*10 ) *
                    258.0 );
                    Y  :=  175-INTEGER(
                    MATHLIB.Cos( LONGREAL( Bear1 ) * Pi / 180.0 ) *
                    LONGREAL( Range1 ) / LONGREAL( CurrRange*10 ) *
                    258.0 * 350.0 / 480.0 );
                    X2  :=  320+INTEGER(
                    MATHLIB.Sin( LONGREAL( Bear2 ) * Pi / 180.0 ) *
                    LONGREAL( Range2 ) / LONGREAL( CurrRange*10 ) *
                    258.0 );
                    Y2  :=  175-INTEGER(
                    MATHLIB.Cos( LONGREAL( Bear2 ) * Pi / 180.0 ) *
                    LONGREAL( Range2 ) / LONGREAL( CurrRange*10 ) *
                    258.0 * 350.0 / 480.0 );

(*                    X  := 319+INTEGER(LONGINT(Cos[Bear1 MOD 360])*
                        LONGINT(Range1) DIV LONGINT( CurrRange*10 ));
                    Y  := 175-INTEGER(LONGINT(Sin[Bear1 MOD 360])*
                        LONGINT(Range1) DIV LONGINT( CurrRange*10 ));
                    X2 := 319+INTEGER(LONGINT(Cos[Bear2 MOD 360])*
                        LONGINT(Range2) DIV LONGINT( CurrRange*10 ));
                    Y2 := 175-INTEGER(LONGINT(Sin[Bear2 MOD 360])*
                        LONGINT(Range2) DIV LONGINT( CurrRange*10 )); *)
                    IF X<0 THEN X := 0 END (* IF *);
                    IF Y<0 THEN Y := 0 END (* IF *);
                    IF X2<0 THEN X2 := 0 END (* IF *);
                    IF Y2<0 THEN Y2 := 0 END (* IF *);

                    Graph.Line(CARDINAL(X),CARDINAL(Y),
                        CARDINAL(X2),CARDINAL(Y2),8);
                END (* IF *);
            END (* WITH *);
        INC(Count);
        IF Count > HIGH(ScrnMap[Num]) THEN
          RETURN;
        END (* IF *);
      END (* WHILE *);

END WriteMap;


PROCEDURE WriteRangeBear( X, Y : INTEGER );

CONST
  ER = 3956.56;
  Pi = 3.141592654;

VAR

  RX, RY,
   Range,
    Bear,
  Height : LONGREAL;

BEGIN

      RX := LONGREAL(X) - 320.0;
      RY := ( 175.0 - LONGREAL(Y) ) * 48.0 / 35.0; (* adjusted for EGA screen *)
      Range := MATHLIB.Sqrt( RX*RX + RY*RY ) * LONGREAL(CurrRange) / 256.0;

      IF RY # 0.0 THEN

          Bear := MATHLIB.ATan2( RY, RX ) * 180.0 / Pi

      ELSIF RX > 0.0 THEN

          Bear := 90.0

      ELSIF RX < 0.0 THEN

          Bear := 270.0

      ELSE

          Bear := 0.0

      END (* IF *);

      IF Bear < 0.0 THEN

          Bear := Bear + 360.0;

      END (* IF *);

      Height := ( LONGREAL(CurrTilt+90) * Pi / 180.0 );
      Height := ( MATHLIB.Sqrt( ER*ER + Range*Range - 2.0*ER*Range*
          MATHLIB.Cos( Height ) ) - ER ) * 52.80;

      SetPlane( {3} );
      SetFunc( clr, 0 );
      SetWindow( 0, 0, 639, 349 );

      GotoXY( 568, 238 );
      WrCard( TRUNC(Range), 3 );
      WrStr( '.' );
      WrCard( TRUNC(Range * 10.0) MOD 10, 1 );
      WrStr( ' mi' );

      GotoXY( 584, 252 );
      WrCard( TRUNC(Bear), 3 );
      WrStr( 'ø' );

      GotoXY( 544, 266 );
      WrLngReal( LONGREAL( TRUNC( Height ) ), 0, 6 );
      WrStr( '00 ft' );

END WriteRangeBear;



PROCEDURE DrawCursor;

BEGIN

(*      SetPlane( {3} ); *)
      SetFunc( xor, 0 );
      Graph.Line( CX-5, CY, CX+5, CY, 3 );
      Graph.Line( CX, CY-5, CX, CY+5, 3 );

END DrawCursor;


VAR

  Screen [ 0A000H:0000H ] : ARRAY [ 0..28000 ] OF BYTE;


PROCEDURE ReadRange;

VAR
    Char : CHAR;
    X, Y  : CARDINAL;

CONST
    RangeAt = 320*80+9;


BEGIN

    SetFont( 14 );
    SetPlane({3});
    Char := ReadChar( 72, 320 );
    IF Char = '1' THEN
        CurrRange := 10;
    ELSIF Char = '2' THEN
        CurrRange := 25;
    ELSIF Char = '5' THEN
        CurrRange := 50;
    ELSE
        Char := ReadChar( 64, 320 );
        IF Char = '1' THEN
            CurrRange := 100;
        ELSE
            CurrRange := 200;
        END (* IF *);
    END (* IF *);

(*    IF Char = ASCII.nul THEN
        Message( ' RANGE NOT READ ' );
    ELSE
        Message( ' RANGE = ' );
        WrChar( Char );
    END (* IF *); *)

    Char := ReadChar( 60, 15 );
    IF Char = '1' THEN
        CurrTilt := 10;
    ELSIF Char = '2' THEN
        CurrTilt := 20;
    ELSE
        CurrTilt := 0;
    END (* IF *);
    Char := ReadChar( 68, 15 );
    IF ( Char >= '0' ) & ( Char <= '9' ) THEN
        CurrTilt := CurrTilt+ORD(Char)-48;
    ELSE
        CurrTilt := 0;
    END (* IF *);

(*    Message( ' RANGE, TILT = ' );
    WrCard( CurrRange, 5 );
    WrCard( CurrTilt, 5 );
    FOR Y := 10 TO 30 DO
        FOR X := 50 TO 80 DO
            Char := ReadChar( X, Y );
            IF Char # ASCII.nul THEN
                Message( ' TILT = ' );
                WrChar( Char );
                WrCard( X, 5 );
                WrCard( Y, 5 );
            END (* IF *);
           END; END; *)

END ReadRange;


PROCEDURE DrawScale;

VAR
  Count : CARDINAL;

BEGIN

  FOR Count := 0 TO 349 DO
      IF ( Count MOD 100 ) = 0 THEN
          Graph.HLine( 0, Count, 8, 3 );
      ELSIF ( Count MOD 50 ) = 0 THEN
          Graph.HLine( 0, Count, 6, 3 );
      ELSIF ( Count MOD 10 ) = 0 THEN
          Graph.HLine( 0, Count, 4, 3 );
      ELSE
          Graph.HLine( 0, Count, 2, 3 );
      END (* IF *);
  END (* FOR *);

END DrawScale;


PROCEDURE ClearScreen;
VAR Y  :  CARDINAL;
BEGIN
  SetPlane( {2,3} );
  SetFunc( clr, 0 );
(*  Graph.Ellipse(320,175,260,190,0,TRUE); *)

  FOR Y := 0 TO 40 DO
      Fill( ADR( Screen[ Y*80+14 ] ), 52, 0 );
  END (* FOR *);
  FOR Y := 41 TO 309 DO
      Fill( ADR( Screen[ Y*80+1 ]), 78, 0 );
  END (* FOR *);
  FOR Y := 310 TO 349 DO
      Fill( ADR( Screen[ Y*80+14 ] ), 52, 0 );
  END (* FOR *);

(*  SetFunc( clr, 0 );
  Graph.Line( 639, 0, 639, 349, 4 );
  Graph.Line( 0, 349, 0, 0, 4 ); *)


END ClearScreen;


PROCEDURE WritePic( VAR Buffer : ARRAY OF BYTE; BufSize : CARDINAL;
                    VAR SrcAt, DestAt, P : CARDINAL );

VAR
    Count  :  CARDINAL;

BEGIN

    SetPlane( {P} );
    SetFunc( clr, 0 );

    WHILE ( SrcAt+2 <= BufSize ) & ( DestAt <= HIGH( Screen ) ) DO

        IF ( Buffer[SrcAt] = BYTE(00H) ) OR ( Buffer[SrcAt] = BYTE(0FFH) ) THEN

            (* Write fill to next 28000 byte boundary *)
            Count := CARDINAL(Buffer[SrcAt+1]);

            Fill( ADR(Screen[DestAt]), Count, Buffer[SrcAt] );
            INC( DestAt, Count );
            INC( SrcAt, 2 );

        ELSE

            Screen[DestAt] := Buffer[SrcAt];
            INC( DestAt );
            INC( SrcAt );

        END (* IF *);

        IF ( DestAt >= HIGH(Screen) ) & ( P < 3 ) THEN

            DestAt := 0;
            P := P+1;
            SetPlane({P});

        END (* IF *);

    END (* WHILE *);

    SetFunc( clr, 0 );
(*    Graph.Ellipse( 320,175,256,186, 4, FALSE ); *)
    Graph.Line( 0, 0, 639, 0, 4 );
    Graph.Line( 639, 0, 639, 349, 4 );
    Graph.Line( 639, 349, 0, 349, 4 );
    Graph.Line( 0, 349, 0, 0, 4 );

    FullScreen := ( DestAt >= HIGH( Screen ) - 80 ) & ( P = 3 );

    ReadRange;

END WritePic;


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
  SetWindow( 0, 1, 639, 349 );
  IF MessLength # 0 THEN
    SetPlane({2,3});
    SetFunc(clr,0);
    FillArea(320-MessLength*4,(*336*)1,MessLength*8,15,CARDINAL(0));
  END (* IF *);
  IF Length(String) = 0 THEN
    MessLength := 0;
    RETURN;
  END (* IF *);
  MessLength := Length(String);
  SetFunc( clr, 0 );
  SetPlane({2});
  FillArea(320-MessLength*4,(*336*)1,MessLength*8,15,CARDINAL(0FFFFH));
  SetPlane({3});
  FillArea(320-MessLength*4,(*336*)1,MessLength*8,15,CARDINAL(0));
  SetFunc(or,0);
  GotoXY(320-MessLength*4,(*336*)1);
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
  SetWindow( 0, 1, 639, 349 );
  Concat(MessString,String,'                              ');
  MessString[ Length(String)+HIGH(Response) ] := 000C;
  Message( MessString );
  SetFunc( clr, 0 );
  Copy( Response, '' );
  REPEAT
    GotoXY(320-MessLength*4+Length(String)*8,(*336*)1);
    WrStr( Response );
    WrStr( 'Û ' );
    Key := RdKey();
    IF ( Key >= ' ' ) & ( Key <= '~' ) &
        ( Length(Response) < HIGH( Response ) ) THEN

        Concat( Response, Response, Key );

    ELSIF ( Key = ASCII.bs ) & ( Length(Response) > 0 ) THEN

        Slice( Response, Response, 0, Length(Response)-1 );

    END (* IF *);

  UNTIL ( Key = ASCII.cr );
  Message( '' );
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

  Count, Count2 : INTEGER;


BEGIN
  MessLength:=0;
  CurrRange := 25;
  CurrTilt := 0;
  CX := 320;
  CY := 175;
  FOR Count := 0 TO 90 DO
      Sin[ Count ] := INTEGER( 189.16666667*MATHLIB.Cos(
          LONGREAL( Count )*Pi/180.0 ) );
      Cos[ Count ] := INTEGER( 258.5*MATHLIB.Sin(
          LONGREAL( Count )*Pi/180.0 ) );
      Sin[ 180-Count ] := -Sin[ Count ];
      Cos[ 180-Count ] := Cos[ Count ];
      Sin[ 180+Count ] := -Sin[ Count ];
      Cos[ 180+Count ] := -Cos[ Count ];
      Sin[ 360-Count ] := Sin[ Count ];
      Cos[ 360-Count ] := -Cos[ Count ];
  END (* FOR *);


END CDScrn.
