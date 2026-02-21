IMPLEMENTATION MODULE Serial;

(*********************************************************)
(* Created   : 2/18/87                                   *)
(* Last Edit : 2/18/87                                   *)
(* Author    : Derek Lane                                *)
(* System    : LOGITECH MODULA-2/86                      *)
(*                                                       *)
(* Process-driven serial port reading and writing.       *)
(*********************************************************)


VAR
  ComPort     : ARRAY[1..8] OF RECORD
    Address   :   CARDINAL;
    Interrupt :   CARDINAL;
  END; (* RECORD *)

PROCEDURE Init(Port      : CARDINAL;
               Baud      : CARDINAL;
               Parity    : BOOLEAN;
               Even      : BOOLEAN;
               NumofBits : CARDINAL;
           VAR Done      : BOOLEAN);
(* Initializes port Port to the specified parameters *)
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

PROCEDURE Write(Port : CARDINAL; Ch : CHAR);
(* Writes a character to port Port *)
VAR
  LineStatus : BITSET;
BEGIN
  INBYTE(ComPort[Port].Address+3,LineStatus);
  IF NOT(5 IN LineStatus) THEN

  ELSE
    IOTRANSFER(
  END; (* IF *)

PROCEDURE Read(Port : CARDINAL; VAR Ch : CHAR);
(* Reads a character from port Port *)

PROCEDURE TimeRead(Port    : CARDINAL;
               VAR Ch      : CARDINAL;
                   TimeOut : CARDINAL);
(* Reads a character from port Port, timing out if none are received
   in TimeOut milliseconds *)

PROCEDURE InstallPort(Number    : CARDINAL;
                      Address   : CARDINAL;
                      Interrupt : CARDINAL);
(* Sets up port numbered Number at IO address Address and with interrupt
   number Interrupt *)
BEGIN
  ComPort[Number].Address:=Address;
  ComPort[Number].Interrupt:=Interrupt;
END InstallPort;

END Serial.
