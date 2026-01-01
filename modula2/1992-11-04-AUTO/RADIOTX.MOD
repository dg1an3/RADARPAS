IMPLEMENTATION MODULE RadioTx;

IMPORT rs2, Lib, IO;
FROM Process IMPORT StartScheduler, StopScheduler, StartProcess,
    Delay, Lock, Unlock;
FROM CRC IMPORT CalcCRC;

CONST
  BlockSize   = 256;
  SpaceSignal = 6;
(*  MaxFile     = 16; *)

TYPE

(*  PrefixRec      = RECORD

        PrefixAt : LONGCARD;
      PrefixData : ARRAY [ 0..6 ] OF BYTE;

  END (* PrefixRec *);

  PrefixTabPtr = POINTER TO ARRAY [ 0..250 ] OF PrefixRec;


  DirEntryRec = RECORD

        Class : CARDINAL;
         Name : ARRAY [ 0..10 ] OF CHAR;
         Time : CARDINAL;
         Date : CARDINAL;
         Size : LONGCARD;
       Prefix : PrefixRec;

  END (* DirEntry *);

*)
  DirUtilRec     = RECORD

       BufferPtr : POINTER TO ARRAY [ 0..250 ],
                     [ 0..BlockSize-1 ] OF BYTE;
      BufferSize : LONGCARD;
       BufferPos : CARDINAL;
       PrefixTab : PrefixTabPtr;

  END (* DirUtilRec *);

VAR

  (* Directory variables *)
(*  Directory : ARRAY [ 1..MaxFile ] OF DirEntryRec; *)
  DirUtil   : ARRAY [ 0..MaxFile ] OF DirUtilRec;
(*  LastFile  : CARDINAL; *)


  TmpCount : CARDINAL;

PROCEDURE SetNextPrefix( FileNum : CARDINAL );

VAR
  Count : CARDINAL;

BEGIN

  WITH DirUtil[FileNum] DO

      Count := 0;
      WHILE ( LONGCARD(BufferPos)*BlockSize >=
          PrefixTab^[Count].PrefixAt ) &
          ( Count < CARDINAL(BufferSize DIV 256) ) DO

          INC( Count );

      END (* WHILE *);
      Directory[FileNum].Prefix := PrefixTab^[Count];

  END (* WITH *);

END SetNextPrefix;


PROCEDURE SetNextFile( VAR FileNum : CARDINAL );

BEGIN

  IF ( TmpCount MOD 8 ) = 0 THEN

      SetNextPrefix( 1 );
      FileNum := 0;

  ELSE

      FileNum := LastFile;

  END (* IF *);

  INC( TmpCount );

END SetNextFile;


VAR
  FileNum    : CARDINAL;


PROCEDURE TransmitProc;

BEGIN

  LOOP

      SetNextFile( FileNum );

      WITH DirUtil[FileNum] DO

          Delay( 1 );
          WHILE rs2.TxCount() > 0 DO Delay( 0 ) END;

          rs2.Break( SpaceSignal );

          rs2.Send( SHORTCARD(FileNum), 1 );
          rs2.Send( BufferPos, 2 );
          rs2.Send( BufferPtr^[BufferPos], BlockSize );
          rs2.Send( CalcCRC(ADR(BufferPtr^[BufferPos]),BlockSize), 2 );

          INC( BufferPos, 1 );
          IF LONGCARD(BufferPos)*BlockSize >= BufferSize THEN

              BufferPos := 0;

          END (* IF *);

      END (* WITH *);

  END (* LOOP *);

END TransmitProc;


PROCEDURE Transmit
( VAR FileNum : CARDINAL;
   VAR Buffer : ARRAY OF BYTE;
         Size : LONGCARD;
    PrefixTab : PrefixTabPtr );

BEGIN

  Lock;
  DirUtil[1].BufferPtr := ADR(Buffer);
  DirUtil[1].BufferSize := Size;
  DirUtil[1].BufferPos := 0;
  DirUtil[1].PrefixTab := PrefixTab;
  FileNum := 1;
  TmpCount := 0;
  LastFile := 1;
  Unlock;

END Transmit;


PROCEDURE FileAt( ForFile : CARDINAL ) : LONGCARD;
BEGIN
  RETURN( LONGCARD(DirUtil[ForFile].BufferPos)*BlockSize );
END FileAt;

(*
VAR
  CurrPicData : POINTER TO ARRAY [ 0..65535 ] OF BYTE;

PROCEDURE SendPic( ForPic : PictureRec );
BEGIN

    CurrPicSize := ForPic.Size + ForPic.Size DIV 2048 * 4;
    ALLOCATE( CurrPicData, CurrPicSize );
    AtPos := 0;
    FOR Count := 0 TO ForPic.Size DIV 2048 DO
        Move( ForPic.Data^[Count*2048], CurrPicData^[Count*2052+2],
            2048 );
    END (* FOR *);

    Transmit( CurrPicData^, CurrPicSize );

END SendPic;


PROCEDURE SendText( ForText : ARRAY OF CHAR );
BEGIN

    ConvertText( ForText, CurrTextData, CurrTextSize );
    Transmit( CurrTextData^, CurrTextSize );

END SendText;


TYPE
  BigBuffer = ARRAY [ 0..31 ],[ 0..63 ] OF CHAR;

(*$H+ Treat aggregates as variables *)

CONST
  Buffer = BigBuffer(
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@',
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@' );

VAR
  FNum : CARDINAL;
*)

BEGIN

  LastFile := 0;
  TmpCount := 0;

  DirUtil[0].BufferPtr := ADR( Directory );
  DirUtil[0].BufferSize := 64;
  DirUtil[0].BufferPos := 0;

  StartScheduler;
  StartProcess( TransmitProc, 2048, 1 );

(*
  rs2.Install( 2 );
  rs2.Init( 9600, 8, rs2.None, TRUE, FALSE );

  Transmit( FNum, Buffer, SIZE( Buffer ), PrefixTabPtr(NIL) );

  LOOP
      IO.WrStr( 'SENDING BLOCK ' );
      IO.WrCard( DirUtil[1].BufferPos, 5 );
      IO.WrChar( 015C );
  END (* LOOP *);
*)

END RadioTx.