IMPLEMENTATION MODULE Area;

(*
========================================================

 Created   : 8/4/87
 Last Edit : 8/4/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 This is a set of routines for moving and filling areas
 on the EGA screen.  Note that it doesn't use the
 windows set up by EGALib.
========================================================
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

FROM SYSTEM IMPORT
  BYTE, GETREG, SETREG, CODE, AX, BX, CX, DX, SI, DI, DS, ES;
 
PROCEDURE FillArea
( X1, Y1, XSize, YSize : INTEGER;
  Value                : BYTE );
(* Fills the indicated area with Value. Note that each 
   byte in the area is read, then Value is written, so
   the function set in EGALib will work for the fill. *)
VAR
  Line,LineSize : CARDINAL;
  DSRegister    : CARDINAL;
BEGIN
  GETREG(DS,DSRegister);
  LineSize:=(XSize-1) DIV 8 + 1;
  SETREG(DS,0A000H);
  FOR Line:=Y1*80+(X1 DIV 8) TO (Y1+YSize)*80+(X1 DIV 8) BY 80 DO
    SETREG(BX,Line);       (* MOV BX,OFFSET Line *)
    SETREG(CX,LineSize);   (* MOV CX,LineSize *)
    SETREG(AX,Value);      (* MOV AL,Value *)
    CODE(8AH,17H);         (* MOV DL,[BX] ; Read memory into graphics register *)
    CODE(88H,07H);         (* MOV [BX],AL ; Write back out into memory *)
    CODE(43H);             (* INC BX *)
    CODE(0E2H,0F9H);       (* LOOP $-7    ; Loop until CX=0 *)
  END; (* FOR *)
  SETREG(DS,DSRegister);
END FillArea;

PROCEDURE MoveArea
( X1, Y1, XSize, YSize : INTEGER;
  ToX, ToY             : INTEGER );
(* Moves the indicated area so that its upper-left corner
   as at (ToX,ToY).  Automatically decides which direction
   to move so that an overlapping area is handled properly.
   Probably won't work right unless EGALib.SetFunc(clr) is
   used previously. *)
VAR
  Source, Destin, 
  Line, LineSize  : CARDINAL;
  DSRegister      : CARDINAL;
  ESRegister      : CARDINAL;
BEGIN
  GETREG(DS,DSRegister);
  GETREG(ES,ESRegister);
  Source:=(Y1*80)+(X1 DIV 8);
  Destin:=(ToY*80)+(ToX DIV 8);
  LineSize:=(XSize-1) DIV 8 + 1;
  SETREG(DS,0A000H);
  SETREG(ES,0A000H);
  IF Source>Destin THEN 
    FOR Line:=0 TO YSize*80 BY 80 DO
      SETREG(SI,Line+Source);
      SETREG(DI,Line+Destin);
      SETREG(CX,LineSize);
      CODE(0FCH);       (* CLD *)
      CODE(0F3H,0A4H);  (* REP MOVSB *)
    END; (* FOR *)
  ELSE
    FOR Line:=YSize*80+INTEGER(LineSize)-1 TO LineSize-1 BY -80 DO
      SETREG(SI,Line+Source);
      SETREG(DI,Line+Destin);
      SETREG(CX,LineSize);
      CODE(0FDH);       (* STD *)
      CODE(0F3H,0A4H);  (* REP MOVSB *)
    END; (* FOR *)
  END; (* IF *)
  SETREG(DS,DSRegister);
  SETREG(ES,ESRegister);
  CODE(0FCH);       (* CLD *)
END MoveArea;

END Area.
