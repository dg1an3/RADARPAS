MODULE Radio;

IMPORT rs, Lib, IO;
FROM Process IMPORT StartScheduler, StopScheduler, StartProcess;
FROM CRC IMPORT CalcCRC;

CONST
  BlockSize   = 256;
  SpaceSignal = 6;

VAR
  BufferPtr  : POINTER TO ARRAY [ 0..8 ],[ 0..BlockSize-1 ] OF BYTE;
  BufferSize : CARDINAL;
  BufferPos  : CARDINAL;

PROCEDURE TransmitProc;
BEGIN
  LOOP
    IF BufferPos>BufferSize THEN
      BufferPos := 0;
    END (* IF *);
    rs.Send( BufferPos, 2 );
    rs.Send( BufferPtr^[BufferPos], BlockSize );
    rs.Send( CalcCRC(ADR(BufferPtr^[BufferPos]),BlockSize), 2 );
    REPEAT UNTIL rs.TxCount() = 0;
(*    rs.Break( SpaceSignal ); *)
    Lib.Delay( 50 );
    INC( BufferPos, 1 );
  END (* LOOP *);
END TransmitProc;

PROCEDURE Transmit
( VAR Buffer : ARRAY OF BYTE;
  Size       : CARDINAL );
BEGIN
  StopScheduler;
  BufferPtr := ADR(Buffer);
  BufferSize := Size DIV BlockSize;
  BufferPos := 0;
  StartScheduler;
  StartProcess(TransmitProc,2048,1);
END Transmit;

VAR
  Buffer    : ARRAY [ 0..32 ],[ 0..63 ] OF CHAR;
  OldBufPos : CARDINAL;

BEGIN
  rs.Install( 2 );
  rs.Init( 9600, 8, rs.None, TRUE, FALSE );
  Buffer[0] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[0,63] := 015C;
  Buffer[1] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[1,63] := 015C;
  Buffer[2] := 'then it should print what you are reading now.                  ';
  Buffer[2,63] := 015C;
  Buffer[3] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[3,63] := 015C;
  Buffer[4] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[4,63] := 015C;
  Buffer[5] := 'then it should print what you are reading now.                  ';
  Buffer[5,63] := 015C;
  Buffer[6] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[6,63] := 015C;
  Buffer[7] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[7,63] := 015C;
  Buffer[8] := 'then it should print what you are reading now.                  ';
  Buffer[8,63] := 015C;
  Buffer[9] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[9,63] := 015C;
  Buffer[10] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[10,63] := 015C;
  Buffer[11] := 'then it should print what you are reading now.                  ';
  Buffer[11,63] := 015C;
  Buffer[12] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[12,63] := 015C;
  Buffer[13] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[13,63] := 015C;
  Buffer[14] := 'then it should print what you are reading now.                  ';
  Buffer[14,63] := 015C;
  Buffer[15] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[15,63] := 015C;
  Buffer[16] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[16,63] := 015C;
  Buffer[17] := 'then it should print what you are reading now.                  ';
  Buffer[17,63] := 015C;
  Buffer[18] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[18,63] := 015C;
  Buffer[19] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[19,63] := 015C;
  Buffer[20] := 'then it should print what you are reading now.                  ';
  Buffer[20,63] := 015C;
  Buffer[21] := 'This is a test of the transmitting capabilities of the Radio    ';
  Buffer[21,63] := 015C;
  Buffer[22] := 'module.  If the receiving end receives this message correctly,  ';
  Buffer[22,63] := 015C;
  Buffer[23] := 'then it should print what you are reading now.                  ';
  Buffer[23,63] := 015C;
  Transmit( Buffer, SIZE(Buffer) );
  LOOP
    IF OldBufPos<>BufferPos THEN
      OldBufPos := BufferPos;
      IO.WrStr('BLOCK#');
      IO.WrCard(BufferPos,1);
      IO.WrStr('SENT');
      IO.WrLn;
    END (* IF *);
    IF IO.KeyPressed() THEN EXIT END;
  END;
END Radio.
