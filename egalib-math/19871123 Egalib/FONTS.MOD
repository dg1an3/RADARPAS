IMPLEMENTATION MODULE Fonts;

(*
========================================================

 Created   : 7/7/87
 Last Edit : 7/7/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Text writing for EGA HiRes mode.  Uses EGALib.  Can
 italicize, bold, and underline.
========================================================
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

IMPORT ASCII;
IMPORT EGALib;
IMPORT InOut;
FROM SYSTEM IMPORT
  BYTE, WORD, ADDRESS, SETREG, GETREG, CODE, SWI, 
  AX, BX, CX, DX, BP, ES;
  
VAR
  FontSize : CARDINAL;
  CharTab  : POINTER TO ARRAY [0..3583] OF BYTE;
  TempPtr  : ADDRESS;

PROCEDURE SetFont
( Size : CARDINAL );
(* Currently only supports 8 and 14 sizes. *)
VAR
  done    : BOOLEAN;
BEGIN
  FontSize:=Size;
  IF Size=8 THEN
    SETREG(AX,1130H); (* Get address of character table *)
    SETREG(BX,0300H); (* 8x8 characters *)
    CODE(55H);        (* PUSH BP *)
    SWI(10H);         (* INT 10H *)
    GETREG(ES,TempPtr.SEGMENT);
    GETREG(BP,TempPtr.OFFSET);
    CODE(5DH);        (* POP BP *)
  ELSE
    SETREG(AX,1130H); (* Get address of character table *)
    SETREG(BX,0200H); (* 8x14 characters *) 
    CODE(55H);        (* PUSH BP *)
    SWI(10H);         (* INT 10H *)
    GETREG(ES,TempPtr.SEGMENT);
    GETREG(BP,TempPtr.OFFSET);
    CODE(5DH);        (* POP BP *)
  END; (* IF *)
  CharTab:=TempPtr;   (* Store in CharTab *)
  InOut.AssignWrite(Write,done);
END SetFont;

VAR
  BoldOn : BOOLEAN;

PROCEDURE SetBold
( OnOff : BOOLEAN );
(* Sets bold printing on or off. *)
BEGIN
  BoldOn:=OnOff;
END SetBold;

VAR
  ItalicOn : BOOLEAN;

PROCEDURE SetItalic
( OnOff : BOOLEAN );
(* Sets italic printing on or off. *)
BEGIN
  ItalicOn:=OnOff;
END SetItalic;

VAR
  UnderlineOn : BOOLEAN;

PROCEDURE SetUnderline
( OnOff : BOOLEAN );
(* Sets underline on or off. *)
BEGIN
  UnderlineOn:=OnOff;
END SetUnderline;

VAR
  CursorX, CursorY : CARDINAL;

PROCEDURE GotoRowCol
( Row,Col : CARDINAL );
(* Positions cursor at row and column specified in current
   window.  X in [0..79], Y in [0..24] or [0..42], depending 
   on font. *)
BEGIN
  CursorX:=Col*8;
  CursorY:=Row*FontSize;
END GotoRowCol;

PROCEDURE GotoXY
( X,Y : CARDINAL );
(* Positions cursor at X and Y pixel positions in current
   window.  X in [0..639], Y in [0..349]. *)
BEGIN
  CursorX:=X;
  CursorY:=Y;
END GotoXY;

PROCEDURE Write(ForChar : CHAR);
(* This replaces standard output of InOut. *)
VAR
  AtByte, AtBit, 
  LineCount,  
  DotCount       : CARDINAL;
  DotPattern     : BYTE;
BEGIN
  CASE ForChar OF
    ASCII.cr  : CursorX:=0; |
    ASCII.lf  : IF CursorY+FontSize<EGALib.YSize THEN
                  INC(CursorY,FontSize); 
                ELSE
                  (* Scroll up *)
                END; (* IF *) |
    ASCII.bs  : IF CursorX>8 THEN
                  DEC(CursorX,8);
                ELSE
                  IF CursorY>FontSize THEN
                    DEC(CursorY,FontSize);
                    CursorX:=EGALib.XSize-8;
                  ELSE
                    CursorX:=0;
                  END; (* IF *)
                END; (* IF *) |
    ASCII.EOL : Write(ASCII.cr);
                Write(ASCII.lf); |
    ASCII.del : Write(ASCII.bs);
                Write(' ');
                Write(ASCII.bs)
    ELSE
      IF ItalicOn THEN CursorX:=CursorX+FontSize END;
      AtByte:=(CursorY+EGALib.Y1)*80+(CursorX+EGALib.X1) DIV 8;
      AtBit:=(CursorX+EGALib.X1) MOD 8;
      IF ItalicOn THEN CursorX:=CursorX-FontSize+1 END;
      DotCount:=ORD(ForChar)*FontSize;
      FOR LineCount:=1 TO FontSize DO
        DotPattern:=CharTab^[DotCount];
        SETREG(ES,0A000H); (* A000H = Video segment *)
        SETREG(AX,0000H);
        SETREG(AX,DotPattern);
        SETREG(BX,AtByte);
        SETREG(CX,AtBit);
        CODE(0D3H,0C8H);   (* ROR AX,CL *)
        CODE(26H,8AH,17H); (* MOV DL,ES:[BX] *)
        CODE(26H,88H,07H); (* MOV ES:[BX],AL *)
        CODE(43H);         (* INC BX *)
        CODE(26H,8AH,17H); (* MOV DL,ES:[BX] *)
        CODE(26H,88H,27H); (* MOV ES:[BX],AH *)
        IF ItalicOn (*AND (LineCount MOD 2=0)*) THEN 
          IF AtBit>0 THEN DEC(AtBit) ELSE DEC(AtByte); AtBit:=7; END;
        END; (* IF *)
        INC(DotCount);
        AtByte:=AtByte+80;
      END; (* FOR *)
      IF BoldOn THEN
        BoldOn:=FALSE;                   
        INC(CursorX);
        Write(ForChar);
        BoldOn:=TRUE;
      END; (* IF *)
      IF UnderlineOn AND (ForChar<>'_') THEN
        Write('_')
      ELSIF NOT BoldOn THEN
        INC(CursorX,8);
      END; (* IF *)
      IF CursorX+8>EGALib.XSize THEN Write(ASCII.EOL) END;
  END; (* CASE *)
END Write;

BEGIN
  CursorX:=0; CursorY:=0;
  BoldOn:=FALSE;
  ItalicOn:=FALSE;
  UnderlineOn:=FALSE;
END Fonts.
