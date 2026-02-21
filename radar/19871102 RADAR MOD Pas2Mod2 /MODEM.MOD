IMPLEMENTATION MODULE Modem;

(*            C R E A T E D  : 12/11/86
 *        L A S T   E D I T  : 9/29/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *
 *  Interface to a Hayes-compatible modem.  Dialing and
 *  and response as to how the call is progressing.
 *)

 (*$S- Stack check off *)
 (*$R- Range check off *)
 (*$T- Index check off *)

IMPORT ASCII;
IMPORT RS232Int;
FROM Strings IMPORT CompareStr, Concat, Length;

PROCEDURE ClearBuffer; 
VAR
  AChar : CHAR;
  More  : BOOLEAN;
BEGIN
  REPEAT
    RS232Int.BusyRead(AChar,More);
  UNTIL NOT(More);
END ClearBuffer;

PROCEDURE Call
( Number     : ARRAY OF CHAR;
  VAR Result : ResultCode );
(* Dials the number Number (which may contain Hayes dial modifiers) and
   sets Result accordingly. *)
VAR
  CallCommand : ARRAY[0..60] OF CHAR;
BEGIN
  Concat('ATDT',Number,CallCommand);
  ModemCommand(CallCommand,Result);
END Call;

PROCEDURE HangUp
( VAR Result : ResultCode );
(* Disconnects line if connected; otherwise, does nothing. *)
VAR
  Delay : CARDINAL;
BEGIN
  FOR Delay:=0 TO 1000 DO END;                             
  RS232Int.Write('+');
  RS232Int.Write('+');
  RS232Int.Write('+');
  FOR Delay:=0 TO 1000 DO END;
  ModemCommand('ATH',Result);
END HangUp;

PROCEDURE ModemCommand
( Command    : ARRAY OF CHAR;
  VAR Result : ResultCode );
(* Sends AT Command to modem, sets result accordingly. *)
VAR
  Count    : CARDINAL;
  Response : ARRAY[0..5] OF CHAR;
BEGIN
  FOR Count:=0 TO Length(Command)-1 DO
    RS232Int.Write(Command[Count]);
  END; (* FOR *)
  RS232Int.Write(ASCII.cr);
  ClearBuffer;
  Count:=0;
  REPEAT
    RS232Int.Read(Response[Count]);
    INC(Count);
  UNTIL Response[Count-1]=ASCII.cr;
  Count:=0;
  REPEAT
    RS232Int.Read(Response[Count]);
    INC(Count);
  UNTIL Response[Count-1]=ASCII.cr;
  Response[Count-1]:=ASCII.nul;
  IF CompareStr(Response,'0')=0 THEN
    Result:=Ok;
  ELSIF CompareStr(Response,'1')=0 THEN
    Result:=Connect300;
  ELSIF CompareStr(Response,'2')=0 THEN
    Result:=Ring;
  ELSIF CompareStr(Response,'3')=0 THEN
    Result:=NoCarrier;
  ELSIF CompareStr(Response,'4')=0 THEN
    Result:=ModemError;
  ELSIF CompareStr(Response,'5')=0 THEN
    Result:=Connect1200;
  ELSIF CompareStr(Response,'6')=0 THEN
    Result:=NoDialtone;
  ELSIF CompareStr(Response,'7')=0 THEN
    Result:=Busy;
  ELSIF CompareStr(Response,'8')=0 THEN
    Result:=NoAnswer;
  ELSIF CompareStr(Response,'10')=0 THEN
    Result:=Connect2400;
  ELSE
    Result:=NoResponse;
  END; (* IF *)
END ModemCommand;

END Modem.
