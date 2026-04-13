IMPLEMENTATION MODULE EGALib;

(*
========================================================

 Created   : 7/6/87
 Last Edit : 7/6/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 This is the 'base' layer for the graphics routines.
 It supplies palette, plane, color, and function 
 defining.
========================================================
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

FROM SYSTEM IMPORT
  BYTE, WORD, SETREG, GETREG, CODE, SWI, INBYTE, OUTBYTE, 
  ADR, AX, BX, CX, DX, SI, DI, DS, ES;

PROCEDURE SetHiRes;
(* Sets high resolution 640x350 mode. *)
BEGIN
  SETREG(AX,0010H); (* Set 640x350 mode 10H *);
  CODE(55H); (* PUSH BP *)
  SWI(10H);  (* INT 10H *)
  CODE(5DH); (* POP BP *)
END SetHiRes;

(*
TYPE
  PaletteType = ARRAY[0..15] OF BYTE;
*)

PROCEDURE SetPalette
( ToPalette : PaletteType );
(* Sets up the sixteen colors of the palette. *)
VAR
  Dummy,Count : CARDINAL;
BEGIN
  FOR Count:=0 TO 15 DO
    INBYTE(3DAH,Dummy);
    OUTBYTE(3C0H,Count);
    OUTBYTE(3C0H,ToPalette[Count]);
  END;
  OUTBYTE(3C0H,20H); (* Enable new palette *)
END SetPalette;

(*
TYPE
   PlaneRange = [0..3];
   PlaneSet   = SET OF PlaneRange;

VAR
  CurrentPlanes : PlaneSet;
*)

PROCEDURE SetPlane
( ToPlanes : PlaneSet );
(* Sets the plane(s) for writing and reading. *)
BEGIN
  OUTBYTE(3CEH,05H); (* Set read mode 0, write mode 1. *)
  OUTBYTE(3CFH,08H);
  OUTBYTE(3CEH,07H); (* Set color compare to ToPlanes. *)
  OUTBYTE(3CFH,CARDINAL(ToPlanes));
  OUTBYTE(3CEH,02H); (* Set color don't care to unselected planes. *)
  OUTBYTE(3CFH,CARDINAL(ToPlanes));
  OUTBYTE(3C4H,02H); (* Set write maps *)
  OUTBYTE(3C5H,CARDINAL(ToPlanes));
  CurrentPlanes:=ToPlanes;
END SetPlane;

(*
VAR
  CurrentPlanesEnabled : PlaneSet;
*)

PROCEDURE EnablePlane
( ForPlanes : PlaneSet );
(* Selects which plane or planes are to be shown on the screen *)
VAR Dummy : BYTE;
BEGIN
  INBYTE(3DAH,Dummy);
  OUTBYTE(3C0H,12H);
  OUTBYTE(3C0H,WORD(ForPlanes));
  OUTBYTE(3C0H,20H);
  CurrentPlanesEnabled:=ForPlanes;
END EnablePlane;

(*
TYPE
  FuncType    = (clr, and, or, xor); 
  RotateRange = [0..7];

VAR
  CurrentFunc   : FuncType;
  CurrentRotate : RotateRange;
*)

PROCEDURE SetFunc
( ToFunc : FuncType;
  Rotate : RotateRange );
(* Sets the function and the bit rotation to use for writing. *)
VAR
  Value : CARDINAL;
BEGIN
  Value:=ORD(ToFunc)*8+Rotate;
  OUTBYTE(3CEH,03H);
  OUTBYTE(3CFH,Value);
  CurrentFunc:=ToFunc;
  CurrentRotate:=Rotate;
END SetFunc;

(*
VAR
  X1, Y1, X2, Y2,
  XSize, YSize    : CARDINAL; (* Dimensions of current window *)
*)

PROCEDURE SetWindow
( ToX, ToY,
  ToXSize, ToYSize : CARDINAL );
(* Moves the coordinates (0,0) to the (X1,Y1), and prevents any
   plotting beyond coordinates (XSize,YSize). *)
BEGIN
  XSize:=ToXSize; IF XSize>639 THEN XSize:=639 END;
  IF ToX+XSize<639 THEN X1:=ToX ELSE X1:=639-XSize END;
  X2:=X1+XSize;
  YSize:=ToYSize; IF YSize>349 THEN YSize:=349 END;
  IF ToY+YSize<349 THEN Y1:=ToY ELSE Y1:=349-YSize END;
  Y2:=Y1+YSize;
END SetWindow;

BEGIN
  SetPlane(PlaneSet{0,1,2,3});
  EnablePlane(PlaneSet{0,1,2,3});
  SetFunc(clr,0);
  SetWindow(0,0,639,349);
END EGALib.
