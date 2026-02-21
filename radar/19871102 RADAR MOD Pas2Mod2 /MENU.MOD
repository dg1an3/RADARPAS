IMPLEMENTATION MODULE Menu;

(*********************************************************)
(* Created   : 4/1/87                                    *)
(* Last Edit : 4/6/87                                    *)
(* Author    : Derek Lane                                *)
(* System    : LOGITECH MODULA-2/86                      *)
(*                                                       *)
(* Provides a system for modules to install themselves   *)
(* and be called by a certain key.  Also provides help   *)
(* text installation.                                    *)
(*********************************************************)

IMPORT ASCII;
FROM EGALib IMPORT GotoXY;
FROM InOut IMPORT WriteString;
IMPORT Keyboard;
FROM Strings IMPORT Assign, Copy, Length;

PROCEDURE CompareKey(FirstKey,SecondKey : Key) : BOOLEAN;
(* Compares two key strokes for equality. *)
BEGIN
  IF FirstKey[1]=SecondKey[1] THEN
    IF FirstKey[1]=ASCII.nul THEN
      RETURN FirstKey[2]=SecondKey[2];
    ELSE
      RETURN TRUE;
    END; (* IF *)
  END; (* IF *)
END CompareKey;

VAR
  MaxSelect  : CARDINAL;
  SelectList : ARRAY[1..32] OF RECORD
    When     :   Key;
    Do       :   PROC;
  END; (* RECORD *)

PROCEDURE InstallSelection(ForKey : Key; DoProc : PROC);
(* Installs DoProc to be called when ForKey is pressed. *)
VAR
  Count : CARDINAL;
BEGIN
  Count:=1;
  WHILE NOT CompareKey(SelectList[Count].When,ForKey) AND (Count<=MaxSelect) DO
    INC(Count);
  END;
  IF Count<=32 THEN
    IF Count>MaxSelect THEN
      INC(MaxSelect);
      Count:=MaxSelect;
      SelectList[Count].When:=ForKey;
    END; (* IF *)
    SelectList[Count].Do:=DoProc;
  END; (* IF *)
END InstallSelection;

VAR
  MaxHelp  : CARDINAL;
  HelpList : ARRAY[1..32] OF RECORD
    Text   :   ARRAY[1..20] OF CHAR;
    X,Y    :   CARDINAL;
  END; (* RECORD *)

PROCEDURE InstallHelp(Text : ARRAY OF CHAR; X,Y : CARDINAL);
(* Installs help text to be displayed at X,Y. *)
BEGIN
  IF MaxHelp<32 THEN
    INC(MaxHelp);
    Assign(Text,HelpList[MaxHelp].Text);
    HelpList[MaxHelp].X:=X;
    HelpList[MaxHelp].Y:=Y;
  END; (* IF *)
END InstallHelp;

PROCEDURE Save;
(* Saves the current keystrokes and help text and clears the keystroke 
   and help text buffers. *)
BEGIN
END Save;

PROCEDURE Restore;
(* Restores keystroke and help information that was previously saved. *)
BEGIN
END Restore;

VAR
  HelpOn : BOOLEAN;

PROCEDURE SetHelp(State : BOOLEAN);
(* Sets help text either on or off, depending on State. *)
VAR
  BlankStr : ARRAY[0..20] OF CHAR;
  Count    : CARDINAL;
BEGIN
  HelpOn:=State;
  FOR Count:=1 TO MaxHelp DO
    WITH HelpList[Count] DO
      GotoXY(X,Y);
      IF HelpOn THEN
        WriteString(Text);
      ELSE
        Copy('                     ',1,Length(Text),BlankStr);
        WriteString(BlankStr);
      END; (* IF *)
    END; (* WITH *)
  END; (* FOR *)
END SetHelp;

PROCEDURE ToggleHelp;
(* Toggles the help screen on and off. *)
BEGIN
  SetHelp(NOT HelpOn);
END ToggleHelp;

PROCEDURE Do(Return : Key);
(* Begins reading keys, performing selected menu operations. Exits when 
   the Return keystroke is detected. *)
VAR
  KeyStroke : Key;
  Count     : CARDINAL;
BEGIN
  LOOP
    Keyboard.Read(KeyStroke[1]);
    IF Keyboard.KeyPressed() THEN
      Keyboard.Read(KeyStroke[2]);
    END;
    IF CompareKey(KeyStroke,Return) THEN EXIT END;
    Count:=1;
    WHILE NOT CompareKey(SelectList[Count].When,KeyStroke) AND 
    (Count<=MaxSelect) DO INC(Count) END;
    IF Count<=MaxSelect THEN SelectList[Count].Do END;
  END; (* LOOP *)
END Do;

END Menu.
