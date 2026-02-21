MODULE Sweep;

FROM Graph IMPORT
  InitEGA, GraphMode, TextMode, Polygon, Ellipse, Plot;

FROM Graphics IMPORT
  SetFont, SetPalette, PaletteType, Line, GotoXY, SetPlane,
  SetFunc, clr;

IMPORT MATHLIB, IO, FIO;


CONST
  Pi   = 3.1415;
  DeltaTheta  = Pi/400.0;

VAR
  Rho,
  Theta : LONGREAL;
  X, Y  : CARDINAL;

TYPE
  RadialTableEntry = ARRAY [ 0..2 ] OF SHORTCARD;
  (* Every 3 bytes contains 8 decision entries *)

  RadialTable = ARRAY [ 0..31 ] OF RadialTableEntry;

VAR
  ScreenTable : ARRAY [ 0..399 ] OF RadialTable;


PROCEDURE CalcTable;

VAR
  Rho,
  Theta,
  SinTheta, CosTheta : LONGREAL;
  X, Y  : CARDINAL;
  X2, Y2 : CARDINAL;
  IncX, IncY, IncByte : BOOLEAN;

  CurrRadial,
  CurrEntry, ZeroCount : CARDINAL;
  Entry : LONGCARD;
  TabFile : FIO.File;

BEGIN

  ZeroCount := 0;
  SetFont( 14 );
(*  TabFile := FIO.Create( 'TABLE.DAT' ); *)
  Theta := 0.0;
  CurrRadial := 0;
  REPEAT

(*      IO.WrCard( CurrRadial, 0 );
      IO.WrLn; *)

      Rho := 0.0;
      X := 0;
      Y := 0;
      CurrEntry := 0;
      Entry := 0;
      SinTheta := MATHLIB.Sin(Theta);
      CosTheta := MATHLIB.Cos(Theta);
      REPEAT

          X2 := CARDINAL( SinTheta * Rho/256.0*240.0 );
(*          IncX := X2 > X; *)

          Y2 := CARDINAL( CosTheta * Rho/256.0*240.0 * 0.725 );
(*          IncY := Y2 > Y;
          IncByte := IncY & ( Y MOD 8 = 7 );

          Entry := LONGCARD( IncX ) << 2 + LONGCARD( IncY ) << 1 +
              LONGCARD( IncByte ); *)

          IF ( X2 = X ) & ( Y2 = Y ) & ( Rho > 128.0 ) THEN
              INC( ZeroCount )
          END;
          X := X2; Y := Y2;

          Plot( 320+X2, 175-Y2, 3 );
          Rho := Rho + 1.0;
(*          IF CARDINAL( Rho ) MOD 24 = 0 THEN

              ScreenTable[ CurrRadial, CurrEntry ] :=
                  RadialTableEntry( Entry );
              Entry := 0;
              INC( CurrEntry );

          END (* IF *); *)

      UNTIL Rho >= 255.0;
      GotoXY( 0, 0 );
      SetPlane( {2} );
      SetFunc( clr, 0 );
      IO.WrCard( ZeroCount, 0 );

(*      FIO.WrBin( TabFile, ScreenTable[ CurrRadial ], SIZE(RadialTable) );
 *)
      Theta := Theta + DeltaTheta;
      INC( CurrRadial );

  UNTIL Theta > Pi/2.0;
(*  FIO.Close( TabFile ); *)

END CalcTable;


PROCEDURE LoadTable;

VAR
  TabFile : FIO.File;
  Count : CARDINAL;

BEGIN

  TabFile := FIO.Open( 'TABLE.DAT' );
  Count := FIO.RdBin( TabFile, ScreenTable, SIZE( ScreenTable ) );
  FIO.Close( TabFile );

END LoadTable;


PROCEDURE DrawSweep;

VAR
  CurrRadial, CurrEntry, X, Y, Decision : CARDINAL;

BEGIN
  CurrRadial := 0;
  CurrEntry := 0;
  X := 0; Y := 0;
  REPEAT
      Decision := CARDINAL( LONGCARD( ScreenTable[ CurrRadial, CurrEntry DIV 8 ] )
          >> LONGCARD(CurrEntry MOD 8 * 3) MOD 7 );
      INC( CurrEntry );
      IF CurrEntry = 256 THEN
          INC( CurrRadial );
          CurrEntry := 0;
          X := 0; Y := 0;
      END (* IF *);
      CASE Decision OF
        000B, 001B : Plot( 320+X, 175-Y, 4 ) (* Do nothing *) |
        010B, 011B : (* Inc X *)
            Plot( 320+X, 175-Y, 3 );
            INC( X ); |
        100B, 101B : (* Inc Y *)
            Plot( 320+X, 175-Y, 3 );
            INC( Y ); |
        110B, 111B : (* Inc X & Y *)
            Plot( 320+X, 175-Y, 3 );
            INC( X );
            INC( Y );
      END (* CASE *);
  UNTIL CurrRadial = 200;

END DrawSweep;


BEGIN

  InitEGA;
  GraphMode;
  SetFont(14);
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
  Ellipse(320,175,240,174,15,FALSE);

  CalcTable;

END Sweep.