MODULE EasterEggs;

FROM MathLib0 IMPORT
  sin, real, entier;
FROM EGALib IMPORT
  SetHiRes, SetPlane, PlaneSet;
FROM Figures IMPORT Point;

PROCEDURE DrawEgg
( Res, Beta1, Beta2, Gamma, Alpha, Modf : INTEGER );
VAR
  X, Y, Z : REAL;
  I, J, C : INTEGER;
  Colors  : PlaneSet;
BEGIN
  FOR I:=1 TO Res DO
    FOR J:=1 TO Res DO
      X:=real(Beta1)+real(Gamma)*real(I);
      Y:=real(Beta2)+real(Gamma)*real(J);
      C:=entier( real(Alpha)*(sin(X/3.1415*180.0)+sin(Y/3.1415*180.0)) );
      Colors:=PlaneSet(C MOD Modf+9);
      SetPlane(Colors);
      Point(J,I); 
    END; (* FOR *)
  END; (* FOR *)
END DrawEgg;

BEGIN
  SetHiRes;
  SetPlane(PlaneSet{0,1,2,3});
  DrawEgg(250,-13,-12,200,5,6);
END EasterEggs.
