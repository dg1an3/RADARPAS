PROGRAM RADIOTX;

PROCEDURE RxBlock_with_Check(VAR BlockAt; Size : INTEGER; OK : BOOLEAN);
VAR
  Block : ARRAY[1..1000] OF BYTE ABSOLUTE BlockAt;
  Count : INTEGER;
  CheckRx,
  Check : BYTE;
BEGIN
  Check:=0;
  FOR Count:=1 TO Size DO BEGIN
    Rx(Block[Count]);
    Check:=Check+Block[Count];
  END;
  Rx(CheckRx);
  OK:=CheckRx=Check;
END;

VAR
  BlockTemplate : RECORD
    Name        :   ARRAY[0..23] OF CHAR;
    Date,Time   :   INTEGER;
    Size        :   INTEGER; (* Size in blocks *)
    BlockNum    :   INTEGER;
    Valid       :   BYTE;    (* Amount of valid data in block
    LastSend    :   BOOLEAN;
    Data        :   ARRAY[1..128] OF BYTE;
  END; (* RECORD *)

PROCEDURE RadioRx;
VAR
  F     : FILE;
  Open  : BOOLEAN;
  OK    : BOOLEAN;
BEGIN
  Open:=FALSE;
  WITH BlockTemplate DO BEGIN
    REPEAT
      RxBlock_with_Check(BlockTemplate,SIZEOF(BlockTemplate),OK);
      IF NOT Open THEN BEGIN
        Assign(F,Name);
        ReWrite(F);
        Open:=TRUE;
      END;
      BlockWrite(F,Data,1);
    UNTIL BlockNum=Size;
  END;
END;

VAR
  FileName : STRING[80];

BEGIN
  Write('Name of file to transmit?');
  ReadLn(FileName);
  RadioTx(FileName);
END.
