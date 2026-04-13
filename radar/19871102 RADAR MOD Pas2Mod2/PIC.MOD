IMPLEMENTATION MODULE Picture;

(*********************************************************)
(* VERSION : 1/26/86                                     *)
(* CREATED : 1/26/86                                     *)
(*  AUTHOR : Derek Lane                                  *)
(*  SYSTEM : LOGITECH MODULA-2/86                        *)
(*                                                       *)
(*  Downloading and displaying the radar's picture.      *)
(*  All of these procedures assume that the radar is     *)
(*  connected and online.                                *)
(*                                                       *)
(*********************************************************)

FROM EGALib IMPORT Decompress, LineSize;
FROM RS232Code IMPORT Read, Write;
FROM SYSTEM IMPORT ADDRESS, BYTE;

CONST
  RadarAck     = 'A';
  RadarNack    = 000c;
  RadarSendPic = 004c;

PROCEDURE Download(ToBuffer : ADDRESS;
               VAR Size     : CARDINAL);
(* Downloads the current radar picture into ToBuffer.  Size returns
   how many bytes the picture took. *)
VAR
  WaitCode     : ARRAY[0..26] OF CHAR;
  Count        : CARDINAL;
  Buffer       : POINTER TO ARRAY[0..1279] OF CHAR;
  CheckSumCalc,
  CheckSumSent : CHAR;
  EndAddress   : ADDRESS;
BEGIN
  Write('Z');
  Write(RadarSendPic);
  Count:=0;
  REPEAT
    Read(WaitCode[Count]);
    INC(Count);
  UNTIL (Count>=3) AND (WaitCode[Count-1]=CHR(255)) AND
    (WaitCode[Count-2]=CHR(254)) AND (WaitCode[Count-3]=CHR(253));
  LOOP
    Count:=0;
    CheckSumCalc:=000c;
    REPEAT
      Read(Buffer^[Count]);
      INC(CheckSumCalc,ORD(Buffer^[Count]));
      INC(Count);
    UNTIL (Count>=2) AND (Buffer^[Count-1]=030c) AND (Buffer^[Count-2]=030c);
    Read(CheckSumSent);
    IF CheckSumCalc=CheckSumSent THEN
      Write(RadarAck);
      EndAddress:=Buffer;
      INC(EndAddress,Count);
      Buffer:=EndAddress;
      IF Count=2 THEN
        Size:=EndAddress.OFFSET-ToBuffer.OFFSET;
        EXIT;
      END;
    ELSE
      Write(RadarNack);
    END; (* IF *)
  END; (* LOOP *)
END Download;

PROCEDURE Display(Start, End : ADDRESS);
(* Decompresses the picture at Start, until address count is greater
   than End. *)
BEGIN
  REPEAT
    Decompress(Start);
    INC(Start,LineSize);
  UNTIL Start.OFFSET>End.OFFSET;
END Display;

END Picture.
