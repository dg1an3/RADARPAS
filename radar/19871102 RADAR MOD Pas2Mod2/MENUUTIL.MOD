IMPLEMENTATION MODULE MenuUtility;

(*
========================================================

 Created   : 6/18/87
 Last Edit : 6/18/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 System to implement menus and scrolling selectors.
========================================================
*)

(* 
========== DEFINITION MODULE HIGHLIGHTS ==========

EXPORT QUALIFIED
  Item,       (* RECORD TYPE*)
  Menu,       (* RECORD TYPE*)
  DoMenu,     (* PROCEDURE(Menu,BOOLEAN,CARDINAL,CARDINAL,CARDINAL) *)
  SelectProc, (* ARRAY TYPE *)
  DoSelect;   (* PROCEDURE(SelectProc,CARDINAL,CARDINAL,CARDINAL,CARDINAL) *)

TYPE
  Item          = RECORD
    Name        :   ARRAY[0..15] OF CHAR; (* Name to appear on menu *)
    Pos         :   CARDINAL;             (* Position of name in menu *)
    Key         :   CHAR;                 (* Key to activate selection *)
    Escape      :   BOOLEAN;              (* Extended key sequence? *)
    WhenSelect  :   PROC;                 (* Procedure to call when selected *)
  END; (* RECORD *)

  Menu          = ARRAY OF Item; (* Enunciate the obvious
                                    Note that the keystroke to exit
                                    has a NIL value for WhenSelect *)

  SelectProc = PROCEDURE(CARDINAL); (* Procedure to write a selection *)

==================================================
*)

CONST
  ScreenWidth  = 80;
  ScreenHeight = 25;

PROCEDURE DoMenu
( ForMenu : Menu;     (* List of items to use *)
  Bar     : BOOLEAN;  (* True to indicate bar-type menu *)
  Width   : CARDINAL; (* Width of menu window 
                         Set to 0 to have set to minimum *)
  X,Y     : CARDINAL; (* X,Y position of menu window
                         Set to 0 to have set to center *) 
);
VAR
  Count, Max, 
  CurrPos     : CARDINAL;
  Key         : CHAR;
  Escape      : BOOLEAN;
BEGIN
  IF Bar THEN
    Max:=0;
    FOR Count:=1 TO HIGH(ForMenu) DO
      Max:=Max+Length(ForMenu[Count].Name)+2;
    END; (* FOR *)
    IF Width=0 THEN Width:=Max;
    IF X=0 THEN X:=(80-Width) DIV 2;
    Frame(X*8,Y*14,(X+Width)*8,(Y+1)*8);
    CurrPos:=0;
    FOR Count:=1 TO HIGH(ForMenu) DO
      ForMenu[Count].Pos:=CurrPos;
      WriteString(' ');
      WriteString(ForMenu[Count].Name);
      WriteString(' ');
      CurrPos:=CurrPos+Length(ForMenu[Count].Name)+2;
    END; (* FOR *)
  ELSE
    IF Width=0 THEN
      FOR Count:=1 TO HIGH(ForMenu) DO
        IF Length(ForMenu[Count]).Name>Max THEN 
          Max:=Length(ForMenu[Count].Name);
        END; (* IF *)
      END; (* FOR *)
    END (* IF *);
    IF X=0 THEN X:=(ScreenWidth-Width) DIV 2;
    IF Y=0 THEN Y:=(ScreenHeight-HIGH(ForMenu)+1) DIV 2;
    Frame(X*8,Y*14,(X+Width-1)*8,(Y+HIGH(ForMenu))*14);
  END; (* IF *)
  LOOP
    ExtendRead(Key,Escape);
    Count:=0;
    WHILE (Key<>ForMenu[Count].Key) AND (Escape<>ForMenu[Count].Escape)
        AND (Count<=HIGH(ForMenu)) DO
      INC(Count);
    END; (* WHILE *)
    IF Count<=HIGH(ForMenu) THEN
      WITH ForMenu[Count] DO
        OldX:=X; OldY:=Y; 
        OldCount:=Count; OldWidth:=Width;
        HiliteMenu;
        IF WhenSelect<>NIL THEN
          WhenSelect;
        ELSE
          EXIT;
        END; (* IF *)
        HiliteMenu;
      END; (* WIDTH *)
    END; (* IF *)
  END; (* LOOP *)
END DoMenu;

VAR
  ToggleOn, OldX, OldY, OldCount, OldWidth : CARDINAL;
  

PROCEDURE HiliteMenu;
BEGIN
  IF OldWidth>0 THEN
    FillAreaFunc(X*8,(Y+Count)*14,(X+Width)*8,(Y+Count)*14+13,255,xor);
    IF ToggleOn THEN 
      OldWidth:=0;
      ToggleOn:=FALSE;
    ELSE 
      ToggleOn:=TRUE;
    END; (* IF *)
  END; (* IF *)
END HiliteMenu;

PROCEDURE DoSelector
( ForSelector  : SelectProc; (* Procedure to write each selection *)
  X,Y          : CARDINAL;   (* X,Y position of menu window
                                Set to 0 to have set to center *)
  Width,Length : CARDINAL;    (* Width and length of window
                                Set to 0 to have set to minimum/average *)
);
BEGIN
END DoSelector;

END MenuUtility.
