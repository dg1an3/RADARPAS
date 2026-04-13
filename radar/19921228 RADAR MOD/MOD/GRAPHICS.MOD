IMPLEMENTATION MODULE Graphics;

(*  C R E A T E D : 6/7/88
 *    E D I T E D : 6/7/88
 *    A U T H O R : Derek Lane
 *    S Y S T E M : Logitech Modula-2/86 version 3.03
 *
 *  General purpose graphics routines, for the EGA card.
 *
 *
 *)

IMPORT ASCII;
FROM IO IMPORT
  WrStrRedirect, WrStr, RdKey, WrLn, WrShtInt, WrCard;
FROM Lib IMPORT
  Intr, Move, Fill, Sound, Delay, NoSound;
FROM SYSTEM IMPORT
  BYTE, WORD, Registers, Out, In;
IMPORT Graph;

(*
CONST
  text40x25bw   = 0;
  text40x25c    = 1;
  text80x25bw   = 2;
  text80x25c    = 3;
  grph320x200c  = 4;
  grph320x200bw = 5;
  grph640x200bw = 6;
  text80x25m    = 7;
  grph640x200c  = 14;
  grph640x350m  = 15;
  grph640x350c  = 16;
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

VAR
  CurrMode : CARDINAL;

PROCEDURE ScreenMode
( ToMode : CARDINAL );
(* Sets the screen mode. *)
VAR
  R : Registers;
BEGIN
  R.AX := ToMode ;
  Intr(R,10H) ;
  CurrMode := ToMode ;
END ScreenMode;

PROCEDURE GetScreenMode
( VAR Mode : CARDINAL );
BEGIN
  Mode := CurrMode;
END GetScreenMode;

(*
TYPE
  PaletteType = ARRAY[0..15] OF BYTE;
*)

PROCEDURE SetPalette
( ToPalette : PaletteType );
(* Sets up the sixteen colors of the palette. *)
VAR
  Dummy,Count : SHORTCARD;
BEGIN
  FOR Count := 0 TO 15 DO
    Dummy := In(3DAH);
    Out(3C0H,BYTE(Count));
    Out(3C0H,ToPalette[CARDINAL(Count)]);
  END;
  Out(3C0H,20H); (* Enable new palette *)
END SetPalette;

VAR
  CurrentPlanes : BITSET;

PROCEDURE SetPlane
( ToPlanes : BITSET );
(* Sets the plane(s) for writing and reading. *)
BEGIN
  Out(3CEH,05H); (* Set read mode 0, write mode 0. *)
  Out(3CFH,(* 08H *) 00H );

  Out( 3CEH, 04H );
  IF 3 IN ToPlanes THEN
      Out( 3CFH, 3 );
  ELSIF 2 IN ToPlanes THEN
      Out( 3CFH, 2 );
  ELSIF 1 IN ToPlanes THEN
      Out( 3CFH, 1 );
  ELSE
      Out( 3CFH, 0 );
  END (* IF *);

(*  Out(3CEH,07H); (* Set color compare to ToPlanes. *)
  Out(3CFH,BYTE(ToPlanes));
  Out(3CEH,02H); (* Set color don't care to unselected
                        planes. *)
  Out(3CFH,BYTE(ToPlanes)); *)

  Out(3C4H,02H); (* Set write maps *)
  Out(3C5H,BYTE(ToPlanes));
  CurrentPlanes := ToPlanes;
END SetPlane;

PROCEDURE GetPlane
( VAR ToPlanes : BITSET );
(* Returns planes set for writing or reading. *)
BEGIN
  ToPlanes := CurrentPlanes;
END GetPlane;

PROCEDURE EnablePlane
( ForPlanes : BITSET );
(* Selects which plane or planes are to be shown on the screen *)
VAR Dummy : BYTE;
BEGIN
  Dummy := In(3DAH);
  Out(3C0H,12H);
  Out(3C0H,BYTE(ForPlanes));
  Out(3C0H,20H);
END EnablePlane;

(*
TYPE
  FuncType    = (clr, and, or, xor);
  RotateRange = [ 0..7 ];
*)

VAR
  CurrentFunc   : FuncType;
  CurrentRotate : RotateRange;

PROCEDURE SetFunc
( ToFunc : FuncType;
  Rotate : RotateRange );
(* Sets the function to use for writing. *)
VAR
  Value : CARDINAL;
BEGIN
  Value := ORD(ToFunc)*8+Rotate;
  Out(3CEH,03H);
  Out(3CFH,BYTE(Value));
  CurrentFunc := ToFunc;
  CurrentRotate := Rotate;
END SetFunc;

PROCEDURE GetFunc
( VAR ToFunc : FuncType;
  VAR Rotate : RotateRange );
(* Returns the current function and rotate set.*)
BEGIN
  ToFunc := CurrentFunc;
  Rotate := CurrentRotate;
END GetFunc;

VAR
  WX1, WY1, WX2, WY2, WXSize, WYSize : INTEGER;

PROCEDURE SetWindow
( X, Y,
  XSize, YSize : INTEGER );
(* Moves the coordinates (0,0) to the (X1,Y1), and prevents any
   plotting beyond absolute coordinates (XSize,YSize). *)
BEGIN
  IF XSize < 640 THEN
    WXSize := XSize;
  ELSE
    WXSize := 639;
  END (* IF *);
  IF X+WXSize < 640 THEN
    WX1 := X;
  ELSE
    WX1 := 639-WXSize;
  END (* IF *);
  WX2 := WX1 + WXSize;
  IF YSize < 350 THEN
    WYSize := YSize;
  ELSE
    WYSize := 349;
  END (* IF *);
  IF Y+WYSize < 350 THEN
    WY1 := Y;
  ELSE
    WY1 := 349-WYSize;
  END (* IF *);
  WY2 := WY1 + WYSize;
END SetWindow;

PROCEDURE GetWindow
( VAR X, Y,
  XSize, YSize : INTEGER );
(* Returns coordinates of currently defined window. *)
BEGIN
  X := WX1;
  Y := WY1;
  XSize := WXSize;
  YSize := WYSize;
END GetWindow;

PROCEDURE Clip
( X,Y : INTEGER ) : BOOLEAN;
(* Returns TRUE if point is in current window, FALSE if not. *)
BEGIN
  RETURN (0<=X) & (X<=WXSize) & (0<=Y) & (Y<=WYSize);
END Clip;

PROCEDURE ClipLine
( VAR X1, Y1, X2, Y2 : INTEGER ) : BOOLEAN;
(* Returns line end points which lie within current window. *)
TYPE
  RELATION = (above,below,right,left);
  RELATIONS = SET OF RELATION;
CONST
  NULL = RELATIONS {};
VAR
  region1,region2 : RELATIONS;
  swap            : BOOLEAN;
  tmp             : INTEGER;

  PROCEDURE Ratio(f,n,d: INTEGER): INTEGER;
  BEGIN
    RETURN f * n DIV d;
  END Ratio;

BEGIN
  LOOP (* clipping against one clipping boundary at a time *)
    region1 := NULL;
    IF X1 < 0 THEN
      INCL(region1,left)
    ELSIF X1 > WXSize THEN
      INCL(region1,right)
    END;
    IF Y1 < 0 THEN
      INCL(region1,above)
    ELSIF Y1 > WYSize THEN
      INCL(region1,below)
    END;

    region2 := NULL;
    IF X2 < 0 THEN
      INCL(region2,left)
    ELSIF X2 > WXSize THEN
      INCL(region2,right)
    END;
    IF Y2 < 0 THEN
      INCL(region2,above)
    ELSIF Y2 > WYSize THEN
      INCL(region2,below)
    END;

    IF (region1 * region2) <> NULL THEN (* reject *)
      RETURN FALSE;
    END;
    IF (region1 + region2) = NULL THEN (* accept *)
      RETURN TRUE;
    END;
    (* so region1 or region2 is non-null, but their intersection

       is empty *)
    IF region1 = NULL THEN (* swap so p1 is OUTSIDE window *)
      swap:= TRUE;
      tmp := X1; X1 := X2; X2 := tmp;
      tmp := Y1; Y1 := Y2; Y2 := tmp;
      region1 := region2; region2 := NULL;
    END;
    (* note, region1 must be non-null *)
    IF above IN region1 THEN
      X1 := X1 + Ratio(X2-X1,WY1-Y1,Y2-Y1);
      Y1 := 0;
    ELSIF below IN region1 THEN  (* Y1 > WY2, Y1 > Y2 *)
      X1 := X1 + Ratio(X2-X1,Y1-WY2,Y1-Y2);
      Y1 := WYSize;
    ELSIF right IN region1 THEN (* X1 > WX2, X1 > X2 *)
      Y1 := Y1 + Ratio(Y2-Y1,X1-WX2,X1-X2);
      X1 := WXSize;
    ELSE (* left IN region1 *)
      Y1 := Y1 + Ratio(Y2-Y1,WX1-X1,X2-X1);
      X1 := 0;
    END;
    IF swap THEN
      tmp := X1; X1 := X2; X2 := tmp;
      tmp := Y1; Y1 := Y2; Y2 := tmp;
      region2 := region1; region1 := NULL;
    END;
  END; (* LOOP *)
END ClipLine;

VAR
  Screen [0A000H:0000H] : ARRAY [0..32767] OF BYTE;

PROCEDURE Point
( X,Y : INTEGER );
(* Plots the specified point. *)
VAR
  AtByte, AtBit : CARDINAL;
  Dummy : BYTE;
BEGIN
  IF Clip(X,Y) THEN
    INC(X,WX1); INC(Y,WY1);
    AtByte := Y*80+(X DIV 8);
    AtBit := X MOD 8;

    Out(3CEH,08H);
    Out(3CFH,BYTE(80H >> AtBit));
    Dummy := Screen[AtByte];
    Screen[AtByte] := BYTE(0FFH);
    Out(3CEH,08H);
    Out(3CFH,0FFH);
  END; (* IF *)
END Point;

PROCEDURE AtPoint
( X,Y : INTEGER ) : CARDINAL;
(* Returns color at point (X,Y). *)
BEGIN
  RETURN 0 ;
END AtPoint;

PROCEDURE Line
( X1,Y1,X2,Y2 : INTEGER );
(* Draws the specified line. *)
VAR
  dX, dY, X, Y, e : INTEGER;
  subVal, addVal  : INTEGER;
  Count           : INTEGER;
BEGIN
  IF ~ClipLine(X1,Y1,X2,Y2) THEN RETURN END;
  dX := ABS(X2-X1); dY := ABS(Y2-Y1);
  IF dY < dX THEN
    IF X2 < X1 THEN (* Switch coordinate pairs. *)
      X := X1; X1 := X2; X2 := X;
      Y := Y1; Y1 := Y2; Y2 := Y;
    END; (* IF *)
    X := X1; Y := Y1;
    e := 2*dY-dX;
    subVal := 2*(dY-dX); addVal := 2*dY;
    FOR Count := 1 TO dX DO
      Point(X,Y);
      IF e > 0 THEN (* Change Y *)
        IF Y1 < Y2 THEN INC(Y) ELSE DEC(Y) END;
        e := e+subVal;
      ELSE
        e := e+addVal;
      END; (* IF *)
      INC(X);
    END; (* FOR *)
  ELSE
    IF Y2 < Y1 THEN (* Switch coordinate pairs. *)
      X := X1; X1 := X2; X2 := X;
      Y := Y1; Y1 := Y2; Y2 := Y;
    END; (* IF *)
    X := X1; Y := Y1;
    e := 2*dX-dY;
    subVal := 2*(dX-dY); addVal := 2*dX;
    FOR Count := 1 TO dY DO
      Point(X,Y);
      IF e > 0 THEN (* Change Y *)
        IF X1 < X2 THEN INC(X) ELSE DEC(X) END;
        e := e+subVal;
      ELSE
        e := e+addVal;
      END; (* IF *)
      INC(Y);
    END; (* FOR *)
  END; (* IF *)
END Line;

PROCEDURE Ellipse
( X,Y        : INTEGER;
  Radius     : CARDINAL;
  Aspect     : REAL ); (* X/Y aspect ratio of ellipse.
                          Use .7292 for circle on EGA. *)
(* Draws the indicated ellipse. *)
VAR
  IX, IY, IE    : INTEGER;
  AdjIX, AdjIY  : INTEGER;
BEGIN
  X := X+WX1; Y := Y+WY1;
  IX := 0;
  IY := Radius;
  IE := 0;
  WHILE IX <= IY DO
    Point(X+IX,Y+IY*35 DIV 48);
    Point(X-IX,Y+IY*35 DIV 48);
    Point(X+IX,Y-IY*35 DIV 48);
    Point(X-IX,Y-IY*35 DIV 48);
    Point(X+IY,Y+IX*35 DIV 48);
    Point(X-IY,Y+IX*35 DIV 48);
    Point(X+IY,Y-IX*35 DIV 48);
    Point(X-IY,Y-IX*35 DIV 48);
    IF IE<0 THEN
      IE := IE+IY+IY-1;
      IY := IY-1;
    END;
    IE := IE-IX-IX-1;
    IX := IX+1;
  END; (* WHILE *)
END Ellipse;

PROCEDURE Arc
( X,Y        : INTEGER;
  Radius     : CARDINAL;
  Aspect     : REAL;
  Start,End  : REAL ); (* Starting and ending angles in radians.

*)
(* Draws the indicated arc. *)
BEGIN
END Arc;

VAR
  FontSize : INTEGER;
  CharTab  : POINTER TO ARRAY [0..3583] OF BYTE;
  Space    : ARRAY [ 040C..176C ],[ 040C..176C ] OF SHORTINT;
  PrevChar : CHAR;
  ILS, Sp  : SHORTINT;


PROCEDURE Write(ForChar : CHAR); FORWARD;


PROCEDURE WriteString(ForStr : ARRAY OF CHAR);
VAR
    Count : CARDINAL ;
BEGIN

  Count := 0;
  WHILE (Count <= HIGH(ForStr)) & (ForStr[Count] # 000C) DO
      Write(ForStr[Count]);
      INC(Count);
  END (* WHILE *);

END WriteString;


PROCEDURE InitPS;

VAR
      Char1,
      Char2 : CHAR;
      Count : CARDINAL;
  LineSpace : SHORTINT;
       I, J : CARDINAL;

BEGIN
  FOR Char1 := 040C TO 176C DO
      FOR Char2 := 040C TO 176C DO
          Space[ Char1, Char2 ] := 8;
          FOR Count := 0 TO FontSize - 1 DO
              I := CARDINAL( CharTab^[ CARDINAL ( Char1 )
                   * CARDINAL( FontSize ) + Count ] ) * 256;
              J := CARDINAL( CharTab^[ CARDINAL ( Char2 )
                   * CARDINAL( FontSize ) + Count ] ) * 2;
              LineSpace := ILS;
              WHILE ( BITSET(I) * BITSET(J) = {} ) & ( LineSpace < Sp ) DO
                  LineSpace := LineSpace + 1;
                  J := J * 2;
              END (* WHILE *);
              IF LineSpace < Space [ Char1, Char2 ] THEN
                  Space[ Char1, Char2 ] := LineSpace;
              END (* IF *);
          END (* FOR *);
      END (* FOR *);
  END (* FOR *);
END InitPS;


PROCEDURE SetFont
( Size : CARDINAL );
(* Currently only supports 8 and 14 sizes. *)
VAR
  done    : BOOLEAN;
  R       : Registers;
BEGIN
  FontSize := INTEGER(Size);
  R.AX := 1130H;
  IF Size=8 THEN
    R.BX := 0300H;
  ELSE
    R.BX := 0200H;
  END (* IF *);
  Intr(R,10H);
  CharTab := [ R.ES : R.BP ];
  WrStrRedirect := WriteString;
END SetFont;

VAR
  BoldOn : BOOLEAN;

PROCEDURE SetBold
( OnOff : BOOLEAN );
(* Sets bold printing on or off. *)
BEGIN
  BoldOn := OnOff;
END SetBold;

VAR
  ItalicOn : BOOLEAN;

PROCEDURE SetItalic
( OnOff : BOOLEAN );
(* Sets italic printing on or off. *)
BEGIN
  ItalicOn := OnOff;
END SetItalic;

VAR
  UnderlineOn : BOOLEAN;

PROCEDURE SetUnderline
( OnOff : BOOLEAN );
(* Sets underline on or off. *)
BEGIN
  UnderlineOn := OnOff;
END SetUnderline;

VAR
  HalftoneOn : BOOLEAN;

PROCEDURE SetHalftone
( OnOff : BOOLEAN );
(* Sets half-tone printing on or off. *)
BEGIN
  HalftoneOn := OnOff;
END SetHalftone;

VAR
  PSOn : BOOLEAN;

PROCEDURE SetPS
( OnOff : BOOLEAN );
(* Sets proportional space on or off. *)
BEGIN
  PSOn := OnOff;
  PrevChar := 000C;
  InitPS;
END SetPS;

VAR
  JustifyOn : BOOLEAN;
  LineBuffer : ARRAY [ 0..100 ] OF CHAR;

PROCEDURE SetJustify
( OnOff : BOOLEAN );
(* Sets justification on or off. *)
BEGIN

  JustifyOn := OnOff;
  LineBuffer := '';

END SetJustify;


VAR
  CursorX, CursorY : INTEGER;

PROCEDURE GotoRowCol
( Row,Col : CARDINAL );
(* Positions cursor at row and column specified in current
window.  X in [0..79], Y in [0..24] or [0..42], depending on
font. *)
BEGIN
  CursorX := INTEGER(Col)*8;
  CursorY := INTEGER(Row)*FontSize;
END GotoRowCol;

PROCEDURE GotoXY
( X,Y : CARDINAL );
(* Positions cursor at X and Y pixel positions in current window.
   X in [0..639], Y in [0..349]. *)
BEGIN
  CursorX := INTEGER(X);
  CursorY := INTEGER(Y);
END GotoXY;

VAR
  State  : ARRAY [ 1..16 ] OF RECORD
    SCurrMode         : CARDINAL;
    SCurrentPlanes    : BITSET;
    SCurrentFunc      : FuncType;
    SCurrentRotate    : RotateRange;
    SWX1, SWY1,
    SWX2, SWY2,
    SWXSize, SWYSize : INTEGER;
    SFontSize        : INTEGER;
    SBoldOn          : BOOLEAN;
    SItalicOn        : BOOLEAN;
    SUnderlineOn     : BOOLEAN;
    SHalftoneOn      : BOOLEAN;
    SCursorX,
    SCursorY         : INTEGER;
  END; (* State *)

  StatePtr : INTEGER;

PROCEDURE PushVideoState;
BEGIN
  IF StatePtr < 16 THEN
    INC(StatePtr);
    WITH State[StatePtr] DO
      SCurrMode := CurrMode;
      SCurrentPlanes := CurrentPlanes;
      SCurrentFunc := CurrentFunc;
      SCurrentRotate := CurrentRotate;
      SWX1 := WX1; SWY1 := WY1;
      SWX2 := WX2; SWY2 := WY2;
      SWXSize := WXSize; SWYSize := WYSize;
      SFontSize := FontSize;
      SBoldOn := BoldOn;
      SItalicOn := ItalicOn;
      SUnderlineOn := UnderlineOn;
      SHalftoneOn := HalftoneOn;
      SCursorX := CursorX;
      SCursorY := CursorY;
    END; (* WITH *)
  END; (* IF *)
END PushVideoState;

PROCEDURE PopVideoState;
BEGIN
  IF StatePtr > 0 THEN
    WITH State[StatePtr] DO
      ScreenMode(SCurrMode);
      SetPlane(SCurrentPlanes);
      SetFunc(SCurrentFunc,SCurrentRotate);
      SetWindow(SWX1,SWY1,SWXSize,SWYSize);
      SetFont(SFontSize);
      SetBold(SBoldOn);
      SetItalic(SItalicOn);
      SetUnderline(SUnderlineOn);
      SetHalftone(SHalftoneOn);
      GotoXY(SCursorX,SCursorY);
    END; (* WITH *)
    DEC(StatePtr);
  END; (* IF *)
END PopVideoState;

PROCEDURE Write(ForChar : CHAR);
(* This replaces standard output of InOut. *)
VAR
  AtByte, AtBit,
  LineCount,
  DotCount       : CARDINAL;
  DotPattern     : CHAR;
  Dummy          : CHAR;
BEGIN

  IF PSOn THEN
      IF ( ForChar > 037C ) & ( ForChar < 177C ) THEN
          IF PrevChar # 000C THEN
              CursorX := CursorX - INTEGER( Space[ PrevChar, ForChar ] );
          END (* IF *);
          PrevChar := ForChar;
      ELSE
          PrevChar := 000C;
      END (* IF *);
  END (* IF *);
  CASE ForChar OF
    ASCII.cr  : CursorX := 0; |
    ASCII.lf  : IF CursorY+FontSize < WYSize THEN
                    INC(CursorY,FontSize);
                ELSE
                    (* Scroll up *)
                END; (* IF *) |
    ASCII.bs  : IF CursorX > 8 THEN
                    DEC(CursorX,8);
                ELSE
                    IF CursorY > FontSize THEN
                        DEC(CursorY,FontSize);
                        CursorX := WXSize-8;
                    ELSE
                        CursorX := 0;
                    END; (* IF *)
                END; (* IF *) |
    ASCII.EOL : Write(ASCII.cr);
                Write(ASCII.lf); |
    ASCII.del : Write(ASCII.bs);
                Write(' ');
                Write(ASCII.bs)
  ELSE
      IF ItalicOn THEN
          CursorX := CursorX+FontSize;
      END (* IF *);
      AtByte := (CursorY+WY1)*80+(CursorX+WX1) DIV 8;
      AtBit := (CursorX+WX1) MOD 8;
      IF ItalicOn THEN
          CursorX := CursorX-FontSize+1;
      END;
      DotCount := ORD(ForChar)*CARDINAL(FontSize);
      FOR LineCount := 1 TO FontSize DO
          DotPattern := CharTab^[DotCount];
          Dummy := Screen[ AtByte ];
          Screen[ AtByte ] := DotPattern >> CHAR(AtBit);
          Dummy := Screen[ AtByte+1 ];
          Screen[ AtByte+1 ] := DotPattern << CHAR(8-AtBit);
          IF ItalicOn (* AND (LineCount MOD 2=0) *) THEN
              IF AtBit > 0 THEN
                  DEC(AtBit);
              ELSE
                  DEC(AtByte);
                  AtBit := 7;
              END;
          END; (* IF *)
          INC(DotCount);
          AtByte := AtByte+80;
      END; (* FOR *)
      IF BoldOn THEN
          BoldOn := FALSE;
          DEC(CursorX,7);
          Write(ForChar);
          IF HalftoneOn & (ForChar # '±') THEN
              PushVideoState;
              SetFunc(and,0);
              Write('±');
              PopVideoState;
          END;
          BoldOn := TRUE;
      ELSIF HalftoneOn & (ForChar # '±') THEN
          PushVideoState;
          SetFunc(and,0);
          Write('±');
          PopVideoState;
      END; (* IF *)
      IF UnderlineOn & (ForChar # '_') THEN
          Write('_');
      END; (* IF *)

      IF ~BoldOn & ~HalftoneOn & ~UnderlineOn THEN
          INC(CursorX,8);
          IF CursorX+8 > WXSize THEN
              Write(ASCII.EOL)
          END; (* IF *)
      END; (* IF *)

  END; (* CASE *)

END Write;

PROCEDURE ReadChar( X, Y  :  CARDINAL ) : CHAR;

VAR
   Pattern  :  ARRAY [ 0..13 ] OF CARDINAL;
   Count, Count2  :  CARDINAL;
   Match  :  BOOLEAN;
   Key  :  CHAR;
   R  :  Registers;

BEGIN

(*  R.AX := 0200H; (* Set cursor position to X, Y *)
  R.BX := 0000H;
  R.DX := X*256+Y;
  Intr( R, 10H );

  R.AX := 0800H; (* Char, attr read at cursor *)
  R.BX := 0000H;
  Intr( R, 10H );

  RETURN CHAR( R.AL ); *)


  FOR Count := 0 TO 13 DO
      Pattern[ Count ] := CARDINAL( Screen[ (Y+Count)*80 + X DIV 8 ] )*256 +
          CARDINAL( Screen[ (Y+Count)*80 + X DIV 8 + 1 ] );
      Pattern[ Count ] := Pattern[ Count ] >> ( 8 - X MOD 8 );
(*      Screen[ (Y+Count-20)*80 + X DIV 8 ] := BYTE( Pattern[ Count ] ); *)
  END (* FOR *);
  Count := 0;
  REPEAT
      Match := TRUE;
      Count2 := 0;
      REPEAT
          Match := Match & ( CharTab^[ Count+Count2 ] =
              BYTE( Pattern[ Count2 ] ) );
          INC( Count2 );
      UNTIL ~Match OR ( Count2 = 14 );
      INC( Count, 14 );
  UNTIL Match OR ( Count >= 3584 );
  IF Match THEN
      RETURN( CHAR( ( Count-14 ) DIV 14 ) );
  ELSE
      RETURN( ASCII.nul );
  END (* IF *);
END ReadChar;


PROCEDURE FillArea
( X1, Y1, XSize, YSize : INTEGER;
  Pattern              : ARRAY OF BYTE );
(* Fills the indicated area with Value. Note that each byte in
the area is read, then Value is written, so the function set in
EGALib will work for the fill. *)
VAR
  Line,
  LineSize,
  Count,
  AtByte        : INTEGER;
  Value, Dummy  : BYTE;
BEGIN
  LineSize := (XSize-1) DIV 8;
  FOR Line := Y1 TO Y1+YSize DO
    Value := Pattern[ CARDINAL(Line) MOD (HIGH(Pattern)+1) ];
    AtByte := Line*80 + X1 DIV 8;
    FOR Count := AtByte TO AtByte + LineSize DO
      Dummy := Screen[Count];
      Screen[Count] := Value;
    END (* FOR *);
  END (* FOR *);
END FillArea;

PROCEDURE MoveArea
( X1, Y1, XSize, YSize : INTEGER;
  ToX, ToY             : INTEGER );
(* Moves the indicated area so that its upper-left corner
   is at (ToX,ToY).  Automatically decides which direction
   to move so that an overlapping area is handled properly.
   Probably won't work right unless EGALib.SetFunc(clr) is
   used previously. *)
VAR
  Source, Destin,
  Line, LineSize  : CARDINAL;
  DSRegister      : CARDINAL;
  ESRegister      : CARDINAL;
BEGIN
  Source:=(Y1*80)+(X1 DIV 8);
  Destin:=(ToY*80)+(ToX DIV 8);
  LineSize:=(XSize-1) DIV 8 + 1;
  IF Source>Destin THEN
    FOR Line:=0 TO YSize*80 BY 80 DO
      Move(ADR(Screen[Line+Source]),ADR(Screen[Line+Destin]),LineSize);
    END; (* FOR *)
  ELSE
    FOR Line:=YSize*80 (* +INTEGER(LineSize)-1 *) TO 0 (* LineSize-1 *) BY -80 DO
      Move(ADR(Screen[Line+Source]),ADR(Screen[Line+Destin]),LineSize);
    END; (* FOR *)
  END; (* IF *)
END MoveArea;

PROCEDURE ScrollUp;
(* Scrolls the current window up one line. *)
BEGIN
(*  PushVideoState; *)
  SetFunc(clr,0);
  MoveArea(WX1,WY1+FontSize,WXSize,WYSize-FontSize,WX1,WY1);
  FillArea(WX1,WY2-FontSize,WXSize,FontSize,0);
(*  PopVideoState; *)
END ScrollUp;

PROCEDURE ScrollDown;
(* Scrolls the current window down one line. *)
BEGIN
(*  PushVideoState; *)
  SetFunc(clr,0);
  MoveArea(WX1,WY1,WXSize,WYSize-FontSize,WX1,WY1+FontSize);
  FillArea(WX1,WY1,WXSize,FontSize,0);
(*  PopVideoState; *)
END ScrollDown;

PROCEDURE GetPicture
( X1, Y1,
  XSize, YSize : CARDINAL;
  VAR ToBuffer : ADDRESS );
(* Stores the area defined by (X1,Y1) to (X1+XSize,Y1+YSize)
   in the buffer ToBuffer.  The variable Size tells how much
   of ToBuffer was used.  If ToBuffer isn't big enough, then
   Size will be zero. *)
BEGIN
END GetPicture;


PROCEDURE PutPicture
( X, Y       : CARDINAL;
  FromBuffer : ADDRESS );
(* Retrieves the picture previously stored in FromBuffer at
   the position (X1,Y1). *)
BEGIN
END PutPicture;


VAR

  Key : CHAR;
  Count  :  CARDINAL;

BEGIN
  WX1 :=   0; WY1 :=   0;
  WX2 := 639; WY2 := 349;
  WXSize := 639; WYSize := 349;
  CursorX := 0; CursorY := 0;
  BoldOn := FALSE;
  ItalicOn := FALSE;
  UnderlineOn := FALSE;
  HalftoneOn := FALSE;
  PSOn := FALSE;
  ILS := -1;
  Sp := 3;

(*  Graph.InitEGA;
  Graph.GraphMode;
  SetFunc( or, 0 );
  SetFont( 14 );

  FOR Count := 14*ORD('0') TO 14*ORD(':') DO
      WrCard( CARDINAL( CharTab^[ Count ] ), 4 );
  END (* FOR *);

  SetPlane( {0,1,2,3} );
  FillArea( 0, 0, 639, 349, CARDINAL(0FFFFH) );
  SetWindow( 0, 0, 219, 349 );
  SetFunc( xor, 0 );
  SetPS( TRUE );
  WrStr( '    ' );
  SetBold( TRUE ); WrStr( ' Today ' ); SetBold( FALSE );
  WrStr(        'in Iran, a group of terrorists suspected to be from ' );
  WrStr( 'the United States bombed the U.S.S.R.`s embassy.  State officials ' );
  WrStr( 'said today in' );
  SetItalic( TRUE ); WrStr( ' Pravda ' ); SetItalic( FALSE );
  WrStr(                        'that it will register a formal complaint ' );
  WrStr( 'at next month`s U.N. Assembly against the recent wave of U.S. orig- ' );
  WrStr( 'inated terrorism.  Led by a small group of Neo-Nazi fanatics, the ' );
  WrStr( 'wave has been centered mostly on countries who themselves have ' );

  Key := RdKey(); *)


END Graphics.

