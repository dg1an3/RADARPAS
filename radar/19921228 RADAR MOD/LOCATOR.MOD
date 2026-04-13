IMPLEMENTATION MODULE Locator;

FROM MATHLIB IMPORT
  Sqrt, ATan2, Cos;
FROM Graphics IMPORT
  SetPlane, SetFunc, clr, xor, GotoXY;
FROM Graph IMPORT
  Line;
FROM IO IMPORT
  WrCard, WrStr;

(*
VAR

  CurrRange,
   CurrTilt : CARDINAL;
   CursorOn : BOOLEAN;
     CX, CY : CARDINAL;
*)

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

  IF CursorOn THEN
      RX := LONGREAL(X) - 320.0;
      RY := ( 175.0 - LONGREAL(Y) ) * 48.0 / 35.0; (* adjusted for EGA screen *)
      Range := Sqrt( RX*RX + RY*RY ) * LONGREAL(CurrRange) / 256.0;

      IF RY # 0.0 THEN

          Bear := ATan2( RY, RX ) * 180.0 / Pi
    
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
      Height := ( Sqrt( ER*ER + Range*Range - 2.0*ER*Range*
          Cos( Height ) ) - ER ) * 5280.0;
    
      SetPlane( {3} );
      SetFunc( clr, 0 );

      GotoXY( 568, 238 );
      WrCard( TRUNC(Range), 3 );
      WrStr( '.' );
      WrCard( TRUNC(Range * 10.0) MOD 10, 1 );
      WrStr( ' mi' );

      GotoXY( 584, 252 );
      WrCard( TRUNC(Bear), 3 );
      WrStr( 'ø' );

      GotoXY( 560, 266 );
      WrCard( TRUNC(Height), 6 );
      WrStr( ' ft' );

  ELSE

      SetPlane( {3} );
      SetFunc( clr, 0 );

      GotoXY( 568, 238 );
      WrStr( '        ' );

      GotoXY( 584, 252 );
      WrStr( '    ' );

      GotoXY( 560, 266 );
      WrStr( '         ' );

  END (* IF *);

END WriteRangeBear;



PROCEDURE DrawCursor;

BEGIN

  IF CursorOn THEN

      SetPlane( {3} );
      SetFunc( xor, 0 );
      Line( CX-5, CY, CX+5, CY, 8 );
      Line( CX, CY-5, CX, CY+5, 8 );
(*      WriteRangeBear( CX, CY ); *)

  END (* IF *);

END DrawCursor;


BEGIN

  CursorOn := TRUE;
  CX := 320;
  CY := 175;

END Locator.
