IMPLEMENTATION MODULE Figures;

(*
========================================================

 Created   : 9/7/87
 Last Edit : 9/8/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Provides basic geometric shape-drawing routines. Is not
 as of yet complete.
========================================================
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

IMPORT EGALib;
FROM SYSTEM IMPORT
  BYTE, SETREG, CODE, GETREG, AX, CX, OUTBYTE;

VAR
  Screen [0A000H:0000H] : ARRAY [0..32767] OF BYTE;

PROCEDURE Point
( X,Y : INTEGER );
(* Plots the specified point. *)
VAR
  AtByte, AtBit : CARDINAL;
  Dummy : BYTE;
BEGIN
  IF (X<=INTEGER(EGALib.XSize)) AND (Y<=INTEGER(EGALib.YSize)) THEN
    X:=X+INTEGER(EGALib.X1); Y:=Y+INTEGER(EGALib.Y1);
    AtByte:=Y*80+(X DIV 8);
    AtBit:=X MOD 8;
    SETREG(AX,80H);
    SETREG(CX,AtBit);
    CODE(0D2H,0E8H); (* SHR AX,CL *);
    GETREG(AX,AtBit);
    OUTBYTE(3CEH,08H);
    OUTBYTE(3CFH,AtBit);
    Dummy:=Screen[AtByte];
    Screen[AtByte]:=BYTE(0FFH);
    OUTBYTE(3CEH,08H);
    OUTBYTE(3CFH,0FFH);
  END; (* IF *)
END Point;

PROCEDURE AtPoint
( X,Y : INTEGER ) : CARDINAL;
(* Returns color at point (X,Y). *)
BEGIN
END AtPoint;

PROCEDURE Line
( X1,Y1,X2,Y2 : INTEGER );
(* Draws the specified line. *)
VAR
  dX, dY, X, Y, e : INTEGER;
  subVal, addVal  : INTEGER;
  Count           : INTEGER;
BEGIN
  dX:=ABS(X2-X1); dY:=ABS(Y2-Y1);
  IF dY<dX THEN
    IF X2<X1 THEN (* Switch coordinate pairs. *)
      X:=X1; X1:=X2; X2:=X;
      Y:=Y1; Y1:=Y2; Y2:=Y;
    END; (* IF *)
    X:=X1; Y:=Y1;
    e:=2*dY-dX;
    subVal:=2*(dY-dX); addVal:=2*dY;
    FOR Count:=1 TO dX DO
      Point(X,Y);
      IF e>0 THEN (* Change Y *)
        IF Y1<Y2 THEN INC(Y) ELSE DEC(Y) END;
        e:=e+subVal;
      ELSE
        e:=e+addVal;
      END; (* IF *)
      INC(X);
    END; (* FOR *)
  ELSE
    IF Y2<Y1 THEN (* Switch coordinate pairs. *)
      X:=X1; X1:=X2; X2:=X;
      Y:=Y1; Y1:=Y2; Y2:=Y;
    END; (* IF *)
    X:=X1; Y:=Y1;
    e:=2*dX-dY;
    subVal:=2*(dX-dY); addVal:=2*dX;
    FOR Count:=1 TO dY DO
      Point(X,Y);
      IF e>0 THEN (* Change Y *)
        IF X1<X2 THEN INC(X) ELSE DEC(X) END;
        e:=e+subVal;
      ELSE
        e:=e+addVal;
      END; (* IF *)
      INC(Y);
    END; (* FOR *)
  END; (* IF *)
END Line;

PROCEDURE Ellipse
( X,Y        : INTEGER;
  Radius     : CARDINAL; (* Radius for major axis. *)
  Aspect     : REAL );   (* X/Y aspect ratio of ellipse.
                            Use .7292 for circle on EGA. *)
(* Draws the indicated ellipse. *)
VAR
  IX, IY, IE    : INTEGER;
  AdjIX, AdjIY  : INTEGER;
BEGIN
  X:=X+INTEGER(EGALib.X1); Y:=Y+INTEGER(EGALib.Y1);
  IX:=0;
  IY:=Radius;
  IE:=0;
  WHILE IX<=IY DO
    Point(X+IX,Y+IY*35 DIV 48);
    Point(X-IX,Y+IY*35 DIV 48);
    Point(X+IX,Y-IY*35 DIV 48);
    Point(X-IX,Y-IY*35 DIV 48);
    Point(X+IY,Y+IX*35 DIV 48);
    Point(X-IY,Y+IX*35 DIV 48);
    Point(X+IY,Y-IX*35 DIV 48);
    Point(X-IY,Y-IX*35 DIV 48);
    IF IE<0 THEN
      IE:=IE+IY+IY-1;
      IY:=IY-1;
    END;
    IE:=IE-IX-IX-1;
    IX:=IX+1;
  END; (* WHILE *)
END Ellipse;

PROCEDURE Arc
( X,Y        : INTEGER;
  Radius     : CARDINAL;
  Aspect     : REAL;
  Start,End  : REAL ); (* Starting and ending angles in radians. *)
(* Draws the indicated arc. *)
BEGIN
END Arc;

END Figures.
