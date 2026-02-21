MODULE Serial;

(*
   VERSION : 1.0, 12/12/86
   CREATED : 12/12/86
    AUTHOR : Derek Lane
  COMPILER : LOGITECH MODULA-2/86

  Provides a powerful interface to the standard serial cards of
  an IBM PC.  Has facilities for interupts, buffering, and timeouts.
  Imports Devices (251 code bytes, 0 data bytes).

*)

FROM SYSTEM IMPORT
  PROCESS, NEWPROCESS, TRANSFER, IOTRANSFER, ADDRESS,
  ADR, OUTBYTE, OUTWORD, INBYTE, BYTE;
FROM Storage IMPORT
  ALLOCATE;
IMPORT Devices;

TYPE
  EventCode = (dataReady,
               overrunError,
               parityError,
               framingError,
               breakInterrupt,
               bufferEmpty,
               deltaCTS,
               deltaDSR,
               deltaRI,
               deltaCD,
               timeout);

CONST
  NumberOfComPorts = 2; (* COM1: and COM2: *)
  WorkSpaceSize    = 400; (* bytes *)

VAR
  Com            : ARRAY[1..NumberOfComPorts] OF RECORD
    IOAddress    : CARDINAL;
    IOProcess    : PROCESS;
    IntMask      : BITSET;
    WorkSpace    : ARRAY[1..WorkSpaceSize] OF BYTE;
    EventHandler : ARRAY EventCode OF PROC;
  END; (* RECORD *)

  MainProcess    : PROCESS;

PROCEDURE Init(PortNum : CARDINAL; (* COM1: or COM2: *)
               Baud    : CARDINAL; (* Baud rate *)
               Data    : CARDINAL; (* 5, 6, 7, or 8 data bits *)
               Stop    : CARDINAL; (* 1 or 2 data bits *)
               Parity  : BOOLEAN;  (* TRUE=Parity Enabled *)
               Even    : BOOLEAN); (* TRUE=Parity even, if Parity=TRUE *)
(* Initializes the specified serial port to the parameters indicated. *)
VAR
  WorkSpace : ADDRESS;
  PortParam : BITSET;
BEGIN
  OUTBYTE(Com[PortNum].IOAddress+3,80H); (* Set Baud rate access bit *)
  OUTWORD(Com[PortNum].IOAddress,57600 DIV Baud*2); (* Set Baud rate divisor *)
  IF Data=5 THEN
    PortParam:={};
  ELSIF Data=6 THEN
    PortParam:={0};
  ELSIF Data=7 THEN
    PortParam:={1};
  ELSIF Data=8 THEN
    PortParam:={0,1};
  END; (* IF *)
  IF Stop=2 THEN
    INCL(PortParam,2);
  END; (* IF *)
  IF Parity THEN
    INCL(PortParam,3);
  END; (* IF *)
  IF Even THEN
    INCL(PortParam,4);
  END; (* IF *)
  OUTBYTE(Com[PortNum].IOAddress+3,PortParam);
END Init;

PROCEDURE IdentifyEvent(AtPort : CARDINAL) : EventCode;
(* Identifies the type of interrupt that occured *)
VAR
  InterruptID : CARDINAL;
  Status      : BITSET;
BEGIN
  INBYTE(AtPort+2,InterruptID);
  CASE InterruptID OF
    0 : (* Modem Status Interrupt : deltaCTS, deltaDSR, deltaRI, deltaCD *)
        INBYTE(AtPort+6,Status);
        IF 0 IN Status THEN RETURN deltaCTS;
        ELSIF 1 IN Status THEN RETURN deltaDSR;
        ELSIF 2 IN Status THEN RETURN deltaRI;
        ELSIF 3 IN Status THEN RETURN deltaCD;
        END| (* IF *)
    2 : (* Buffer Empty interrupt *)
        RETURN bufferEmpty|
    4 : (* Data ready interrupt *)
        RETURN dataReady|
    6 : (* Line status interrupt *)
        INBYTE(AtPort+5,Status);
        IF 1 IN Status THEN RETURN overrunError;
        ELSIF 2 IN Status THEN RETURN parityError;
        ELSIF 3 IN Status THEN RETURN framingError;
        ELSIF 4 IN Status THEN RETURN breakInterrupt;
        END
  END; (* CASE *)
END IdentifyEvent;

PROCEDURE OnEvent(ComPort   : CARDINAL;
                  Event     : EventCode;
                  DoProc    : PROC);
BEGIN
  WITH Com[ComPort] DO
    CASE Event OF
      dataReady      : INCL(IntMask,0)
|     overrunError,
      parityError,
      framingError,
      breakInterrupt : INCL(IntMask,1)
|     bufferEmpty    : INCL(IntMask,2)
|     deltaCTS,
      deltaDSR,
      deltaRI,
      deltaCD        : INCL(IntMask,3)
    END; (* CASE *)
    OUTBYTE(IOAddress+1,CARDINAL(IntMask));
    EventHandler[Event]:=DoProc;
  END; (* WITH *)
END OnEvent;

PROCEDURE Com1Interrupt;
BEGIN
  (* Install as interrupt 4 handler *)
  Devices.InstallHandler(Com[1].IOProcess,0CH);
  LOOP
    IOTRANSFER(Com[1].IOProcess,MainProcess,0CH);
    Com[1].EventHandler[IdentifyEvent(Com[1].IOAddress)];
  END; (* LOOP *)
END Com1Interrupt;

PROCEDURE Com2Interrupt;
BEGIN
  (* Install as interrupt 4 handler *)
  Devices.InstallHandler(Com[2].IOProcess,0CH);
  LOOP
    IOTRANSFER(Com[2].IOProcess,MainProcess,0CH);
    Com[2].EventHandler[IdentifyEvent(Com[2].IOAddress)];
  END; (* LOOP *)
END Com2Interrupt;

TYPE
  CheckProcedure = PROCEDURE(ADDRESS,CARDINAL,CARDINAL) : BOOLEAN;

PROCEDURE ReadToBuffer(Buffer     : ADDRESS;
                       BufferSize : CARDINAL;
                       Check      : CheckProcedure);
(* Stores data in Buffer, until BufferSize is reached. Calls procedure
   Check every time a character is stored, unless Check is NIL.  Takes
   over DataReady event. *)
BEGIN
END ReadToBuffer;

PROCEDURE WriteFromBuffer(Buffer     : ADDRESS;
                          BufferSize : CARDINAL;
                          Check      : CheckProcedure);
(* Transmits data in Buffer.  Calls Check after every byte sent, unless
   Check is NIL.  Takes over BufferEmpty event. *)
BEGIN
END WriteFromBuffer;

PROCEDURE CheckString(Buffer    : ADDRESS;
                      Length    : CARDINAL;
                      MaxLength : CARDINAL) : BOOLEAN;
VAR
  StringPtr : POINTER TO ARRAY[0..255] OF CHAR;
BEGIN
  StringPtr:=Buffer;
  RETURN StringPtr^[Length]>=CHR(32);
END CheckString;

PROCEDURE Break(Time : CARDINAL);
(* Sets Break condition (Spacing on output line) for Time. *)
BEGIN
END Break;

PROCEDURE WaitBreak(Call : PROC);
(* If Call is not NIL, sets interrupt to call Call on Break interrupt.
   If Call is NIL, waits until Break and then returns. *)
BEGIN
END WaitBreak;

PROCEDURE NilProcedure;
BEGIN
END NilProcedure;

VAR
  Count : CARDINAL;
BEGIN
  FOR Count:=0 TO 10 DO
    Com[1].EventHandler[EventCode(ORD(Count))]:=NilProcedure;
    Com[2].EventHandler[EventCode(ORD(Count))]:=NilProcedure;
  END; (* FOR *)
  Com[1].IntMask:={};
  Com[2].IntMask:={};
  NEWPROCESS(Com1Interrupt,ADR(Com[1].WorkSpace),
             WorkSpaceSize,Com[1].IOProcess);
  TRANSFER(MainProcess,Com[1].IOProcess);
  NEWPROCESS(Com2Interrupt,ADR(Com[2].WorkSpace),
             WorkSpaceSize,Com[2].IOProcess);
  TRANSFER(MainProcess,Com[2].IOProcess);
END Serial.
