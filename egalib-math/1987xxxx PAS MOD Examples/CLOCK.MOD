MODULE Clock;

FROM MathLib0 IMPORT 
  sin, cos, real, entier;
IMPORT EGALib;
IMPORT Figures;
IMPORT Fonts;
IMPORT InOut;
FROM TimeDate IMPORT Time, GetTime;

CONST
  CentX  = 320;
  CentY  = 175;
  PerimX = 230;
  PerimY = 168;

PROCEDURE DrawSecondHand(Seconds : CARDINAL);
VAR
  X, Y : INTEGER;
BEGIN
  Seconds:=Seconds+15;
  X:=CentX-entier(cos(real(Seconds)/30.0*3.141592654)*real(PerimX));
  Y:=CentY-entier(sin(real(Seconds)/30.0*3.141592654)*real(PerimY));
  Figures.Line(CentX,CentY,X,Y);
END DrawSecondHand;

PROCEDURE DrawMinuteHand(Seconds : INTEGER);
VAR
  X1, Y1,
  X2, Y2,
  X3, Y3  : INTEGER;
BEGIN
  Seconds:=Seconds+15;
  X1:=CentX-entier(cos(real(Seconds-1)/30.0*3.141592654)*real(PerimX))*2 DIV 3;
  Y1:=CentY-entier(sin(real(Seconds-1)/30.0*3.141592654)*real(PerimY))*2 DIV 3;
  X2:=CentX-entier(cos(real(Seconds)/30.0*3.141592654)*real(PerimX));
  Y2:=CentY-entier(sin(real(Seconds)/30.0*3.141592654)*real(PerimY));
  X3:=CentX-entier(cos(real(Seconds+1)/30.0*3.141592654)*real(PerimX))*2 DIV 3;
  Y3:=CentY-entier(sin(real(Seconds+1)/30.0*3.141592654)*real(PerimY))*2 DIV 3;
  Figures.Line(CentX,CentY,X1,Y1);
  Figures.Line(X1,Y1,X2,Y2);
  Figures.Line(X2,Y2,X3,Y3);
  Figures.Line(X3,Y3,CentX,CentY);
END DrawMinuteHand;

PROCEDURE DrawHourHand(Seconds : INTEGER);
VAR
  X1, Y1,
  X2, Y2,
  X3, Y3  : INTEGER;
BEGIN
  Seconds:=Seconds*2+6;
  X1:=CentX-entier(cos(real(Seconds-1)/12.0*3.141592654)*real(PerimX)) DIV 2;
  Y1:=CentY-entier(sin(real(Seconds-1)/12.0*3.141592654)*real(PerimY)) DIV 2;
  X2:=CentX-entier(cos(real(Seconds)/12.0*3.141592654)*real(PerimX))*2 DIV 3;
  Y2:=CentY-entier(sin(real(Seconds)/12.0*3.141592654)*real(PerimY))*2 DIV 3;
  X3:=CentX-entier(cos(real(Seconds+1)/12.0*3.141592654)*real(PerimX)) DIV 2;
  Y3:=CentY-entier(sin(real(Seconds+1)/12.0*3.141592654)*real(PerimY)) DIV 2;
  Figures.Line(CentX,CentY,X1,Y1);
  Figures.Line(X1,Y1,X2,Y2);
  Figures.Line(X2,Y2,X3,Y3);
  Figures.Line(X3,Y3,CentX,CentY);
END DrawHourHand;


VAR
  Seconds,
  Minutes     : INTEGER;
  PrevHour,
  PrevMinute,
  PrevSec     : INTEGER;
  CurrTime    : Time;
  Count       : CARDINAL;
  X, Y : INTEGER;

BEGIN
  EGALib.SetHiRes;
  EGALib.SetFunc(EGALib.xor,0);
  EGALib.SetPlane(EGALib.PlaneSet{0,1,2,3});
  Figures.Ellipse(320,175,PerimX+10,0.0);
  Figures.Ellipse(320,175,PerimX+9,0.0);
  Figures.Ellipse(320,175,PerimX+8,0.0);
  Figures.Ellipse(320,175,PerimX+7,0.0);
  Figures.Ellipse(320,175,PerimX+6,0.0);
  Figures.Ellipse(320,175,PerimX+5,0.0);
  EGALib.SetPlane(EGALib.PlaneSet{1,2,3});
  Fonts.SetFont(14);
  FOR Count:=1 TO 12 DO
    DrawHourHand(Count);
    X:=CentX-entier(cos(real(Count+3)/6.0*3.141592654)*real(PerimX-8));
    Y:=CentY-entier(sin(real(Count+3)/6.0*3.141592654)*real(PerimY-10));
    IF Count<10 THEN
      Fonts.GotoXY(X-4,Y-7);
      Fonts.Write(CHR(Count+48));
    ELSE
      Fonts.GotoXY(X-8,Y-7);
      Fonts.Write('1');
      Fonts.Write(CHR(Count+38));
    END; (* END *)
    DrawHourHand(Count);
  END; (* FOR *)
  PrevSec:=-1;
  PrevMinute:=-1;
  PrevHour:=-1;
  LOOP
    GetTime(CurrTime);
    IF (CurrTime.millisec DIV 1000)<>CARDINAL(PrevSec) THEN
      EGALib.SetPlane(EGALib.PlaneSet{0,3});
      IF PrevSec>=0 THEN DrawSecondHand(PrevSec) END;
      PrevSec:=CurrTime.millisec DIV 1000;
      DrawSecondHand(PrevSec);
    END; (* IF *)
    IF (CurrTime.minute MOD 60)<>CARDINAL(PrevMinute) THEN
      EGALib.SetPlane(EGALib.PlaneSet{1,3});
      IF PrevMinute>=0 THEN DrawMinuteHand(PrevMinute) END;
      PrevMinute:=CurrTime.minute MOD 60;
      DrawMinuteHand(PrevMinute);
    END; (* IF *)
    IF (CurrTime.minute DIV 60)<>CARDINAL(PrevHour) THEN
      EGALib.SetPlane(EGALib.PlaneSet{2,3});
      IF PrevHour>=0 THEN DrawHourHand(PrevHour) END;
      PrevHour:=CurrTime.minute DIV 60;
      DrawHourHand(PrevHour);
    END; (* IF *)
  END; (* FOR *)
END Clock.
