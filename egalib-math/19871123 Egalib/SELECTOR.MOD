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
  Window, SetFunc, xor, or, X1, Y1, X2, Y2;
FROM Area IMPORT
  FillArea, MoveArea;
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
( WriteItem   : WriteProc;  (* Writes a selection *)
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

END Selector.
