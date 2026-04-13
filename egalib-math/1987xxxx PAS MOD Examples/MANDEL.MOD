MODULE Mandelbrot;

IMPORT EGALib;
IMPORT Figures;
IMPORT Keyboard;
IMPORT MathLib0;

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

CONST
  ScreenWidth  = 640;
  ScreenHeight = 350;

PROCEDURE PlotSet
( FirstLambdaX,
  FirstLambdaY,
  Size       : REAL;
  Iterations : CARDINAL );
VAR
  LambdaX, LambdaY,
  ZX, ZY, ZXY,
  Step, AbsZ  : REAL;
  Count, X, Y : CARDINAL;
BEGIN
  Step:=Size/FLOAT(ScreenHeight);
  LambdaY:=FirstLambdaY;
  FOR Y:=ScreenHeight-1 TO 0 BY -1 DO
    LambdaX:=FirstLambdaX;
    FOR X:=0 TO ScreenWidth-1 DO
      ZX:=0.0; ZY:=0.0;
      Count:=0; AbsZ:=0.0;
      WHILE (Count<Iterations) AND (AbsZ<2.0) DO
        ZXY:=2.0*ZX*ZY;
        ZX:=ZX*ZX-ZY*ZY+LambdaX;
        ZY:=ZXY+LambdaY;
        INC(Count);
        AbsZ:=((ZX*ZX+ZY*ZY)/4.0);
      END; (* WHILE *)
      IF AbsZ<15.0 THEN
        EGALib.SetPlane(EGALib.PlaneSet(TRUNC(AbsZ)));
      ELSE
        EGALib.SetPlane(EGALib.PlaneSet{0,1,2,3});
      END; (* IF *)
      Figures.Point(X,Y);
      LambdaX:=LambdaX+Step;
    END; (* FOR *)
    LambdaY:=LambdaY+Step;
  END; (* FOR *)
END PlotSet;

VAR Key : CHAR;

BEGIN
  EGALib.SetHiRes;
  PlotSet(-2.0,-1.5,2.5,100);
  Keyboard.Read(Key);
END Mandelbrot.
