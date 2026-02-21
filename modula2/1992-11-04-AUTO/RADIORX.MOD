IMPLEMENTATION MODULE RadioRx;

(*  Copyright (C) 1988 - D. G. Lane
 *
 *  Implements radio-wave reception.
 *
 *  CREATED : 7/1/88
 *   EDITED : 8/10/88
 *   AUTHOR : D. G. Lane
 *   SYSTEM : TopSpeed Modula-2
 *
 *)

(*$Z+ *)

IMPORT rs, Lib, IO;
FROM Process IMPORT
  StartScheduler, StopScheduler, StartProcess, Lock, Unlock,
  Delay;
FROM CRC IMPORT CalcCRC;

CONST
  BlockSize   = 256;
(*  MaxFile     = 16; *)

TYPE
(*  DirEntryRec = RECORD
        Class : CARDINAL;
         Name : ARRAY [ 0..10 ] OF CHAR;
         Time : CARDINAL;
         Date : CARDINAL;
         Size : LONGCARD;
     PrefixAt : LONGCARD;
       Prefix : ARRAY [ 0..6 ] OF BYTE;
  END (* DirEntry *); *)

  DirUtilRec   = RECORD
     BufferPtr : POINTER TO ARRAY [ 0..250 ],
                     [ 0..BlockSize-1 ] OF BYTE;
    BufferSize : LONGCARD;
     BufferPos : CARDINAL;
  END (* DirUtilRec *);

VAR
  (* Directory variables *)
(*  Directory  : ARRAY [ 1..MaxFile ] OF DirEntryRec; *)
  DirUtil    : ARRAY [ 0..MaxFile ] OF DirUtilRec;
(*  LastFile   : CARDINAL; *)

  CRCCheck   : CARDINAL;
  DummyBuf   : ARRAY [ 0..BlockSize*4 ] OF CHAR;
  FileNum    : CARDINAL;

  (* Error counters *)
  CheckError : CARDINAL;
  PosError   : CARDINAL;
  FrameError : CARDINAL;

PROCEDURE ReceiveProc;
BEGIN

  LOOP

(*      IO.WrStr( 'SYNCHING...' ); *)
      WHILE ~ rs.BreakTest() DO

          rs.Receive( DummyBuf, 1 );

      END (* WHILE *);
(*      IO.WrStr( 'DONE.' );
      IO.WrLn; *)

      LOOP

(*          FileNum := 0;
          Delay( 0 ); *)
          rs.Receive( FileNum, 1 );
(*          IO.WrCard( FileNum, 5 ); *)

          IF CARDINAL(FileNum) > LastFile THEN

(*              INC( PosError );
              EXIT; *)
              LastFile := FileNum;

          END (* IF *);

          WITH DirUtil[FileNum] DO

              rs.Receive( BufferPos, 2 );
(*              IO.WrCard( BufferPos, 5 );
              IO.WrLn; *)
              IF LONGCARD(BufferPos)*BlockSize < BufferSize THEN

                  rs.Receive( BufferPtr^[BufferPos],
                      BlockSize );
                  rs.Receive( CRCCheck, 2);
                  rs.Receive( DummyBuf, 1 ); (* Extra character
                      caused by break. *)

                  IF CRCCheck # CalcCRC( ADR(BufferPtr^[BufferPos]),
                      BlockSize ) THEN

                      INC( CheckError );

                  END (* IF *);

                  IF ~ rs.BreakTest() THEN (* Check for framing
                      error *)

                      INC( FrameError );
                      EXIT;

                  END (* IF *);

              ELSE

                  INC( PosError );
                  EXIT;

              END (* IF *);

          END (* WITH *);

      END (* LOOP *);

  END (* LOOP *);

END ReceiveProc;


PROCEDURE Receive
( VAR Buffer : ARRAY OF BYTE;
  Size       : LONGCARD );
BEGIN

  Lock;
  LastFile := 1;
  DirUtil[1].BufferPtr := ADR(Buffer);
  DirUtil[1].BufferSize := Size;
  Unlock;

(*  LOOP
      GotoXY( 0, 0 );
      IO.WrCard( CheckError, 5 );
      IO.WrCard( PosError, 5 );
      IO.WrCard( FrameError, 5 );

  END (* LOOP *); *)

END Receive;


PROCEDURE FileAt( ForFile : CARDINAL ) : LONGCARD;
BEGIN

  IF ForFile <= LastFile THEN
      RETURN( LONGCARD(DirUtil[ForFile].BufferPos)*BlockSize );
  ELSE
      RETURN( 0 );
  END (* IF *);

END FileAt;


PROCEDURE ErrorCount() : CARDINAL;
BEGIN
  RETURN( CheckError*100+PosError*10+FrameError );
END ErrorCount;

(*
VAR
  Buffer : ARRAY [ 0..4351 ] OF CHAR;
  BufEnd : ARRAY [ 0..511 ] OF BYTE;
  Count  : CARDINAL;
  MainWin : Window.WinType;
  Key : CHAR;
*)

BEGIN
  CheckError := 0;
  PosError := 0;
  FrameError := 0;

  DirUtil[0].BufferPtr := ADR( Directory );
  DirUtil[0].BufferSize := SIZE( Directory );
  LastFile := 0;

  StartScheduler;
  StartProcess( ReceiveProc, 2048, 1 );

(*
  rs.Install( 2 );
  rs.Init( 9600, 8, rs.None, TRUE, FALSE );
  MainWin := Window.Open(
    Window.WinDef(0,0,79,24,Window.Yellow,Window.Blue,
      FALSE,TRUE,FALSE,TRUE,Window.SingleFrame,
      Window.White,Window.Blue) );
  Window.SetTitle(MainWin,"MAIN WINDOW",Window.LeftUpperTitle);

  Receive( Buffer, 4352 );

  Window.Use(MainWin);
  Count := 0;
  LOOP
    Window.GotoXY(1,1);
    IO.WrStr( 'ERROR COUNT: ' );
    IO.WrCard( CheckError, 5 );
    IO.WrCard( PosError, 5 );
    IO.WrCard( FrameError, 5 );
    IO.WrLn;
    IO.WrStr( '   FILE NAME : ' );
    IO.WrStr( Directory[1].Name );
    IO.WrLngCard( Directory[1].PrefixAt, 6 );
    IO.WrCard( FileNum, 5 );
(*    Window.GotoXY(1,Count+2);
    IO.WrStr('->');
    IO.WrCard(Count,5);
    IO.WrStr(' : ');
    IO.WrStr(Buffer[Count]);
    Window.GotoXY(1,Count+2);
    IO.WrStr('  ');
    Count := (Count+1) MOD 22; *)
    IF IO.KeyPressed() THEN
      Key := IO.RdKey();
      IF Key = 'C' THEN
        StartScheduler;
      ELSIF Key = 'S' THEN
        StopScheduler;
      ELSE
        EXIT
      END (* IF *);
    END (* IF *);
  END (* LOOP *);
*)

END RadioRx.
