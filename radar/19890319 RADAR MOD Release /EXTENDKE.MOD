IMPLEMENTATION MODULE ExtendKey;

(*********************************************************)
(* Created   : 2/22/87                                   *)
(* Last Edit : 2/22/87                                   *)
(* Author    : Derek Lane                                *)
(* System    : LOGITECH MODULA-2/86                      *)
(*                                                       *)
(* Extended ASCII support for IBM keyboard, including    *)
(* function and cursor key codes.                        *)
(*                                                       *)
(*********************************************************)

IMPORT ASCII;
FROM IO IMPORT RdKey, KeyPressed;

PROCEDURE ExtRead(VAR Code : CHAR; VAR Extended : BOOLEAN);
(* Read a key from the keyboard, checking to see if it is an extended
   key code *)
BEGIN
  Code := RdKey();
  IF (Code=ASCII.nul) AND KeyPressed() THEN
    Code := RdKey();
    Extended:=TRUE;
  ELSE
    Extended:=FALSE;
  END; (* IF *)
END ExtRead;

END ExtendKey.
