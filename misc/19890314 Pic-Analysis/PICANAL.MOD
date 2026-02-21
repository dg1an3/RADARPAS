IMPLEMENTATION MODULE PicAnal;


FROM Graph IMPORT Line, Plot, Point;
FROM Graphics IMPORT SetFunc, xor, clr, GotoXY;
FROM IO IMPORT WrCard, RdKey;


CONST
  MaxCent = 100;


TYPE
  CentroidRec = RECORD
       X, Y       : CARDINAL;
       VarX, VarY : LONGCARD;
       N          : CARDINAL;
  END (* RECORD *);

VAR
  Cent : ARRAY [ 0..MaxCent ] OF CentroidRec;
  NumCent : CARDINAL;


PROCEDURE AddPoint( X, Y : CARDINAL;
                    Weight : CARDINAL;
                    VAR ToCent : CentroidRec );

BEGIN
END AddPoint;


PROCEDURE Analyze;

VAR
  X, Y : CARDINAL;
  P : CARDINAL;
  Key : CHAR;
  TempCent : Centroid;
  VarChange : LONGINT;
   LocCent : Centroid;
  CurrCent : CARDINAL;

BEGIN

  SetFunc( xor, 0 );

  FOR X := 320 TO 576 BY 4 DO

      FOR Y := 0 TO 349 BY 4 DO

          P := Point( X, Y ) MOD 4;
          Plot( X, Y, 7 );

          SetFunc( clr, 0 );
          GotoXY( 0, 175 );
          WrCard( P, 5 );

          IF P > 0 THEN

              LocVarChange
              FOR CurrCent := 0 TO NumCent DO
                  TempCent := Cent[CurrCent];
                  AddPoint( X, Y, P, TempCent );
                  VarChange :=
                    ( TempCent.VarX - Cent[CurrCent].VarX +
                      TempCent.VarY - Cent[CurrCent].VarY ) DIV 2;
                  IF VarChange < LocVarChange THEN
                      LocVarChange := VarChange;
                      LocCent := CurrCent;
                  END (* IF *);
              END (* FOR *);

          END (* IF *);

          SetFunc( xor, 0 );
(*        Plot( X, Y, 7 ); *)

      END (* FOR *);
  END (* FOR *);

END Analyze;

END PicAnal.