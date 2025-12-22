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

FROM Graphics IMPORT
  SetWindow, FillArea, SetFunc, xor, or, SetPlane,
  GotoXY, ScrollUp, ScrollDown, Line;
FROM ExtendKey IMPORT
  ExtRead, uarr, darr, PgUp, PgDn, Home, End;
FROM IO IMPORT
  KeyPressed, WrChar, WrCard;

(* FROM DEFINITION -

TYPE
  WriteProc = PROCEDURE(CARDINAL,VAR BOOLEAN);
  (* This is a procedure to write an item in the selector
     window.  The cursor will already be positioned to the
     necessary place.  If the item selected is not select-
     able, the procedure should return FALSE.  *)
*)

PROCEDURE Select
( X1,Y1,X2,Y2 : CARDINAL;   (* Dimensions of window (0..639,0..349) *)
  WriteItem   : WriteProc;  (* Writes a selection *)
  MaxPos      : CARDINAL;   (* Number of items to select from *)
  VAR Item    : CARDINAL;   (* Gives first item to highlight,
                               returns item selected *)
  VAR Key     : CHAR;       (* Returns exit key. *)
  VAR Escape  : BOOLEAN     (* TRUE if exit key is extended code. *)
);
(* Returns when any key other than the up or down arrow is pressed *)
VAR
  Width, Length : CARDINAL;
  Top           : CARDINAL;
  Count         : CARDINAL;
  OK            : BOOLEAN;
BEGIN
  SetWindow(X1,Y1,X2-X1,Y2-Y1);
  Width := (X2-X1) DIV 8;
  Length := (Y2-Y1) DIV 14 - 1;
  IF Item>Length DIV 2 THEN
    Top := Item-Length DIV 2;
  ELSE
    Top := 1;
  END; (* IF *)
  SetPlane({3});
  FOR Count := 0 TO Length DO
    GotoXY(8,Count*14);
    SetFunc(or,0);
    IF Count+Top <= MaxPos THEN
      WriteItem(Count+Top);
    END (* IF *);
  END (* FOR *);
  LOOP
    IF Top>1 THEN
      SetFunc(xor,0);
      GotoXY(0,0);
      WrChar('')
    END;
    IF Top+Length<MaxPos THEN
      SetFunc(xor,0);
      GotoXY(0,Length*14);
      WrChar('');
    END;
    IF Item>0 THEN
      SetFunc(xor,0);
      SetPlane({3});
      FillArea(X1,Y1+(Item-Top)*14-1,X2-X1,14,CARDINAL(0FFFFH));
    END; (* IF Item... *)
    REPEAT UNTIL KeyPressed();
    ExtRead(Key,Escape);
    IF Item>0 THEN
      SetFunc(xor,0);
      SetPlane({3});
      FillArea(X1,Y1+(Item-Top)*14-1,X2-X1,14,CARDINAL(0FFFFH));
    END; (* IF Item... *)
    IF Top>1 THEN
      SetFunc(xor,0);
      GotoXY(0,0);
      WrChar('')
    END;
    IF Top+Length<MaxPos THEN
      SetFunc(xor,0);
      GotoXY(0,Length*14);
      WrChar('');
    END;
    IF Escape & ( Key = uarr ) THEN
      IF Item>0 THEN DEC(Item) END;
    ELSIF Escape & ( Key = darr ) THEN
      IF Item<MaxPos THEN INC(Item) END;
    ELSIF Escape & ( Key = PgUp ) THEN
      IF Item>Length THEN
        Item:=Item-Length;
      ELSE
        Item:=0;
      END; (* IF *)
    ELSIF Escape & ( Key = PgDn ) THEN
      IF Item+Length<MaxPos THEN
        Item:=Item+Length;
      ELSE
        Item:=MaxPos;
      END; (* IF *)
    ELSIF Escape & ( Key = Home ) THEN
      Item:=0;
    ELSIF Escape & ( Key = End ) THEN
      Item:=MaxPos;
    ELSE
      EXIT;
    END (* IF *);
    WHILE Item>Top+Length DO
      ScrollUp;
      INC(Top);
      GotoXY(8,Length*14);
      SetFunc(or,0);
      WriteItem(Top+Length);
    END;
    WHILE (Item<Top) AND (Top>1) DO
      ScrollDown;
      DEC(Top);
      GotoXY(8,0);
      SetFunc(or,0);
      WriteItem(Top);
    END;
  END; (* LOOP *)
END Select;

END Selector.
