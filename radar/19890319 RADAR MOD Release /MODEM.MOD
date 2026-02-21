IMPLEMENTATION MODULE Modem;

(*            C R E A T E D  : 12/11/86
 *        L A S T   E D I T  : 9/29/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *
 *  Interface to a Hayes-compatible modem.  Dialing and
 *  and response as to how the call is progressing.
 *)

IMPORT ASCII, rs, IO;
FROM Str IMPORT Compare, Concat, Length;
FROM Lib IMPORT Delay;

PROCEDURE ClearBuffer;
VAR
  AChar : CHAR;
  More  : BOOLEAN;
BEGIN
  WHILE rs.RxCount()>0 DO
    rs.Receive(AChar,1);
  END (* WHILE *) ;
END ClearBuffer;

PROCEDURE Call
( Number     : ARRAY OF CHAR;
  VAR Result : ResultCode );
(* Dials the number Number (which may contain Hayes dial modifiers) and
   sets Result accordingly. *)
VAR
  CallCommand : ARRAY[0..60] OF CHAR;
BEGIN
  Concat(CallCommand,'ATDT',Number);
  ModemCommand(CallCommand,Result);
END Call;

PROCEDURE HangUp
( VAR Result : ResultCode );
(* Disconnects line if connected; otherwise, does nothing. *)
BEGIN
  Delay(1500);
  rs.Send('+++',3);
  Delay(1500);
  ModemCommand('ATH',Result);
END HangUp;

PROCEDURE ModemCommand
( Command    : ARRAY OF CHAR;
  VAR Result : ResultCode );
(* Sends AT Command to modem, sets result accordingly. *)
VAR
  Count    : CARDINAL;
  Response : ARRAY[0..5] OF CHAR;
  Key      : CHAR;
BEGIN
  rs.Send(Command,Length(Command));
  rs.Send(ASCII.cr,1);
  ClearBuffer;
  Count := 0;
  Key := 000C;
  REPEAT
    IF rs.RxCount()>0 THEN
      rs.Receive(Response[Count],1);
      INC(Count);
    END (* IF *);
    IF IO.KeyPressed() THEN
        Result := NoResponse;
(*        Key := IO.RdKey(); *)
        RETURN;
    END (* IF *);
  UNTIL ( Response[ Count-1 ] = ASCII.cr );
  Response[ Count-1 ] := ASCII.nul;
  IF Compare( Response, '0' ) = 0 THEN
    Result := Ok;
  ELSIF Compare(Response,'1') = 0 THEN
    Result:=Connect300;
  ELSIF Compare(Response,'2') = 0 THEN
    Result:=Ring;
  ELSIF Compare(Response,'3') = 0 THEN
    Result:=NoCarrier;
  ELSIF Compare(Response,'4') = 0 THEN
    Result:=ModemError;
  ELSIF Compare(Response,'5') = 0 THEN
    Result:=Connect1200;
  ELSIF Compare(Response,'6') = 0 THEN
    Result:=NoDialtone;
  ELSIF Compare(Response,'7') = 0 THEN
    Result:=Busy;
  ELSIF Compare(Response,'8') = 0 THEN
    Result:=NoAnswer;
  ELSIF Compare(Response,'10') = 0 THEN
    Result:=Connect2400;
  ELSE
    Result:=NoResponse;
  END; (* IF *)
END ModemCommand;

END Modem.
