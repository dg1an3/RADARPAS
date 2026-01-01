PROGRAM RADIOTX;

PROCEDURE TxBlock_with_Check(VAR BlockAt; Size : INTEGER);
VAR
  Block : ARRAY[1..1000] OF BYTE ABSOLUTE BlockAt;
  Count : INTEGER;
  Check : BYTE;
BEGIN
  Check:=0;
  FOR Count:=1 TO Size DO BEGIN
    Tx(Block[Count]);
    Check:=Check+Block[Count];
  END;
  Tx(Check);
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

PROCEDURE RadioTx(FileName : STRING[80]);
VAR
  F     : FILE;
  Count : INTEGER;
BEGIN
  Assign(F,FileName);
  ReSet(F);
  WITH BlockTemplate DO BEGIN
    Name:=FileName;
    Size:=FileSize(F);
    BlockNum:=1;
    Valid:=128;
    LastSend:=false;
    WHILE BlockNum<=FileSize(F) DO BEGIN
      BlockRead(F,Data,1);
      TxBlock_with_Check(BlockTemplate,SIZEOF(BlockTemplate));
      BlockNum:=BlockNum+1;
    END;
  END;
END RadioTx;

VAR
  FileName : STRING[80];

BEGIN
  Write('Name of file to transmit?');
  ReadLn(FileName);
  RadioTx(FileName);
END.
