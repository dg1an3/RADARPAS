IMPLEMENTATION MODULE Selector;

(*
========================================================

 Created   : 7/5/87
 Last Edit : 7/5/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Provides a device for selection.  Opens a window with
 a list of possible choices, with a highlight bar.
 User moves bar with arrow keys, and presses any other
 key to make the selection.
========================================================
*)

FROM EGALib IMPORT 
  Window, FillArea, FillAreaFunc, xor, SetPlane, GotoXY,
  ScrollUp, ScrollDown;
FROM KeyDispatch IMPORT 
  KeyPressed, Peek, Read, UArr, DArr, PgUp, PgDn, Home, End;

FROM InOut IMPORT WriteString, WriteCard;

(* FROM DEFINITION -

TYPE
  WriteProc = PROCEDURE(CARDINAL);
  (* This is a procedure to write an item in the selector
     window.  The cursor will already be positioned to the
     necessary place. *)
*)

PROCEDURE Select
( X1,Y1,X2,Y2 : CARDINAL;   (* Dimensions of window (0..639,0..349) *)
  WriteItem   : WriteProc;  (* Writes a selection *)
  MaxPos      : CARDINAL;   (* Number of items to select from *)
  VAR Item    : CARDINAL    (* Gives first item to highlight, 
                               returns item selected *)
); 
(* Returns when any key other than the up or down arrow is pressed.
   The next key can be read by using KeyDispatch.Read. *)
VAR
  Width, Length : CARDINAL;
  Top           : CARDINAL;
  Count         : CARDINAL;
  Key           : CHAR;
BEGIN
  Window(X1,Y1,X2,Y2);
  Width:=(X2-X1) DIV 8;
  Length:=(Y2-Y1) DIV 14-1;
  IF Item>Length DIV 2 THEN 
    Top:=Item-Length DIV 2;
  ELSE
    Top:=0;
  END; (* IF *)
  SetPlane({3});
  FOR Count:=Top TO Top+Length DO
    GotoXY(0,Count*14);
    WriteItem(Count);
  END; (* FOR *)
  LOOP
    FillAreaFunc(X1,Y1+(Item-Top)*14,X2,Y1+(Item-Top+1)*14,255,xor);
    REPEAT UNTIL KeyPressed();
    Peek(Key);
    FillAreaFunc(X1,Y1+(Item-Top)*14,X2,Y1+(Item-Top+1)*14,255,xor);
    IF Key=UArr THEN
      IF Item>0 THEN DEC(Item) END;
    ELSIF Key=DArr THEN
      IF Item<MaxPos THEN INC(Item) END;
    ELSIF Key=PgUp THEN
      IF Item>Length THEN 
        Item:=Item-Length;
      ELSE       
        Item:=0;
      END; (* IF *)
    ELSIF Key=PgDn THEN
      IF Item+Length<MaxPos THEN 
        Item:=Item+Length;
      ELSE
        Item:=MaxPos;
      END; (* IF *)
    ELSIF Key=Home THEN
      Item:=0;
    ELSIF Key=End THEN
      Item:=MaxPos;
    ELSE EXIT END;
    Read(Key);
    WHILE Item>Top+Length DO
      ScrollUp;
      INC(Top);
      GotoXY(0,Length*14);
      WriteItem(Top+Length);
    END;
    WHILE Item<Top DO
      ScrollDown;
      DEC(Top);
      GotoXY(0,0);
      WriteItem(Top);
    END;
  END; (* LOOP *)
END Select;

PROCEDURE WriteLetter(ForLetter : CARDINAL);
BEGIN
  CASE ForLetter OF
    0 : WriteString('Letter A'); |
    1 : WriteString('Letter B'); |
    2 : WriteString('Letter C'); |
    3 : WriteString('Letter D'); |
    4 : WriteString('Letter E'); |
    5 : WriteString('Letter F'); |
    6 : WriteString('Letter G'); |
    7 : WriteString('Letter H'); |
    8 : WriteString('Letter I'); |
    9 : WriteString('Letter J'); |
    10 : WriteString('Letter K'); |
    11 : WriteString('Letter L'); |
    12 : WriteString('Letter M'); |
    13 : WriteString('Letter N'); |
    14 : WriteString('Letter O'); |
    15 : WriteString('Letter P'); |
    16 : WriteString('Letter Q'); |
    17 : WriteString('Letter R'); |
    18 : WriteString('Letter S'); |
    19 : WriteString('Letter T'); |
    20 : WriteString('Letter U'); |
    21 : WriteString('Letter V'); |
    22 : WriteString('Letter W'); |
    23 : WriteString('Letter X'); |
    24 : WriteString('Letter Y'); |
    25 : WriteString('Letter Z'); |
    26 : WriteString('Letter AA'); |
    27 : WriteString('Letter BB'); |
    28 : WriteString('Letter CC'); |
    29 : WriteString('Letter DD'); |
    30 : WriteString('Letter EE'); |
    31 : WriteString('Letter FF'); |
    32 : WriteString('Letter GG'); |
    33 : WriteString('Letter HH'); |
    34 : WriteString('Letter II'); |
    35 : WriteString('Letter JJ'); |
    36 : WriteString('Letter KK'); |
    37 : WriteString('Letter LL'); |
    38 : WriteString('Letter MM'); |
    39 : WriteString('Letter NN'); |
    40 : WriteString('Letter OO');
    ELSE
  END; (* CASE *)
END WriteLetter;                   

VAR
  Item : CARDINAL;
  Key   : CHAR;

BEGIN
  Item:=0;
  Select(280,90,610,230,WriteLetter,40,Item);
  GotoXY(0,0); WriteCard(Item,5);
END Selector.
