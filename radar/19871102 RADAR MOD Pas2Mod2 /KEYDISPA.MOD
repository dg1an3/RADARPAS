IMPLEMENTATION MODULE KeyDispatch;
(*$S+ Stack test on *)
(*$R- Range/overflow test off *)
(*$T- Index/NIL test off *)

(*
========================================================

 Created   : 6/30/87
 Last Edit : 7/5/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86


KeyDispatch provides a way to assign a task to be performed
when a key is pressed.  Though not as fast as a CASE 
statement, it is more flexible, because a procedure can
be linked to a keystroke in the initialization code of
a module, and the main module will never need to be
aware of that modules interface at all.

KeyDispatch also provides uses extended key codes by the Read
procedure, which indicates an extended key sequence by
returning CHR(128+code), rather than returning a NUL or
ESC before the code.  This is a more efficient system,
but prevents entering extended characters.  Certain
extended strokes have codes higher than 127; these are
simply returned without adding 128.

Notice that the key interpretation procedure, GoKey,
requires a list of keys to be interpreted.  For use with
the self-assigned keystrokes, use GoKey(MainKeys).  You
can also use GoKey with custom keystroke assignments.      
========================================================
*)

(* FROM DEFINITION MODULE -

TYPE
  KeyAssignment = RECORD
    WhenKey     :   CHAR;
    DoProc      :   PROC;
  END; (* RECORD *)

VAR
  Main : ARRAY[0..63] OF KeyAssignment;
  (* This is the main keystroke list, assigned by AssignKey.
     Begin main key interpretation by GoKey(Main). *)

*)

IMPORT ASCII;
IMPORT Keyboard;
FROM SYSTEM IMPORT ADDRESS;

FROM InOut IMPORT WriteString, WriteLn;

VAR
  PeekedKey : CHAR; (* Set to key peeked at, ASCII.nul if none. *)

PROCEDURE KeyPressed() : BOOLEAN;
(* TRUE if a key is ready. *)
BEGIN
  RETURN Keyboard.KeyPressed() OR (PeekedKey<>ASCII.nul);
END KeyPressed;

PROCEDURE Read
( VAR Key : CHAR
);
(* Reads a regular or extended code, returns as Key. *)
BEGIN
  IF PeekedKey<>ASCII.nul THEN
    Key:=PeekedKey;
    PeekedKey:=ASCII.nul;
  ELSE
    Keyboard.Read(Key);
    IF Key=ASCII.nul THEN
      Keyboard.Read(Key);
      IF Key<200c THEN INC(Key,128) END;
    END; (* IF *)
  END; (* IF *)
END Read;

PROCEDURE Peek
( VAR Key : CHAR
);
(* 'Peeks' at the next keystroke, if one is ready.  If no
   keystrokes are in the buffer, returns ASCII.nul.  
   Consecutive callings of Peek will return the same key 
   over and over.  If your procedure decides to use the key
   read, be sure to call Read to clear it. *)
BEGIN
  IF (PeekedKey=ASCII.nul) AND Keyboard.KeyPressed() THEN
    Read(PeekedKey);
  END; (* IF *)
  Key:=PeekedKey;
END Peek;

VAR
  KeyCount : CARDINAL;

PROCEDURE AssignKey
( WhenKey  : CHAR;    (* Key stroke *)
  DoProc   : PROC;    (* Procedure to be called *)
  Priority : BOOLEAN; (* Priority of keystroke *)
  VAR OK   : BOOLEAN  (* TRUE if installation successful *)
);
(* Assigns the procedure Do to be called when Key is pressed. 
   Set Priority to true for speed-intensive keys, such as 
   cursor controls.  Priority simply has the procedure install
   the key at the beginning of the list, rather than the end. *)
VAR
  Count : CARDINAL;
BEGIN
  OK:=KeyCount<63;
  FOR Count:=KeyCount TO 1 BY -1 DO
    IF MainKeys[Count].WhenKey=WhenKey THEN OK:=FALSE END;
    IF Priority THEN MainKeys[Count+1]:=MainKeys[Count] END;
  END; (* FOR *)
  IF OK THEN
    IF Priority THEN
      MainKeys[1].WhenKey:=WhenKey;
      MainKeys[1].DoProc:=DoProc;
    ELSE
      MainKeys[KeyCount+1].WhenKey:=WhenKey;
      MainKeys[KeyCount+1].DoProc:=DoProc;
    END; (* IF *)
    INC(KeyCount);
  END; (* IF *)
END AssignKey;
   
PROCEDURE GoKey
( ForKeys : ARRAY OF KeyAssignment
);
(* Begins reading keys and calling the assigned procedure.
   Returns when it reads a key which is assigned to a NIL
   procedure. *)
VAR
  Key   : CHAR;
  Count : CARDINAL;
BEGIN
  LOOP
    Read(Key);
    Count:=1;
    WHILE (ForKeys[Count].WhenKey<>Key) AND (Count<=KeyCount) DO
      INC(Count);
    END; (* WHILE *)
    IF Count<=KeyCount THEN
      IF ADDRESS(ForKeys[Count].DoProc)=NIL THEN EXIT END;
      ForKeys[Count].DoProc;
    END; (* IF *)
  END; (* LOOP *)
END GoKey;
 
BEGIN
  PeekedKey:=ASCII.nul;
  KeyCount:=0;
END KeyDispatch.
