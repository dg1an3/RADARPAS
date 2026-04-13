MODULE TestDB;

(* Tests the Digital Broadcast Kernel as a transient program.
 *)

IMPORT ASCII, AsmLib, CRC, DurationOps, FIO, IO,
    Lib, Str, rs, Process, SYSTEM;

VAR
  HostFilePre,
  HostFileSpec  : ARRAY [ 0..63 ] OF CHAR;

VAR
  D : FIO.DirEntry;
  F : FIO.File;
  N : ARRAY [ 0..75 ] OF CHAR;
  B, BN : CARDINAL;
  Block : ARRAY [ 0..255 ] OF BYTE;
  DOSbusy : POINTER TO BOOLEAN;
  R : SYSTEM.Registers;
  CycleTime : DurationOps.Duration;
  Key       : CHAR;
  Count     : INTEGER;


CONST
  BlockSize   = 128;
  HeaderBlock = HIGH( CARDINAL );


TYPE
  BlockRec       = RECORD
      ChannelNum :     SHORTCARD;
      BlockNum   :     CARDINAL;
      BlockData  :     ARRAY [ 0..BlockSize-1 ] OF BYTE;
      ErrorCode  :     CARDINAL;
  END (* BlockRec *);


PROCEDURE CheckDOS;

BEGIN

  WHILE DOSbusy^ OR ~ AsmLib.GetInProgramFlag() DO

      Process.Delay( 0 );

  END (* WHILE *);

END CheckDOS;


PROCEDURE HostKernel;

(*  The Host data pre-processing is divided into six stages.
 *  Not all of the stages are currently implemented.
 *
 *  Stage   Name         Description
 *    1     File         Uses file specifications to read
 *                       data from matching files
 *    2     Frame        Add block information
 *    3     Encrypt      (not implemented)
 *    4     Error-codes  Add error-correction codes
 *    5     Loop-check   Record data for loop-check
 *    6     RS-232       Send data out through channel
 *
 *)

    VAR
        FileName : ARRAY [ 0..63 ] OF CHAR;
        DataFile : FIO.File;
        Sync     : BOOLEAN;


    PROCEDURE GetBlockData( VAR ForBlock : BlockRec );
    (* Stage 1. Fetch block of data from files indicated by
                file specification from command line. *)
    BEGIN

        IF FileName = '' THEN

            CheckDOS;
            Process.Lock;

            IF FIO.ReadNextEntry( D ) THEN

                FIO.Close( DataFile );

                Str.Concat( FileName, HostFilePre, D.Name );
                DataFile := FIO.Open( FileName );
                ForBlock.BlockNum := HeaderBlock;

            ELSIF FIO.ReadFirstEntry( HostFileSpec,
                FIO.FileAttr{}, D ) THEN

            END (* IF *);

            Str.Concat( FileName, HostFilePre, D.Name );
            DataFile := FIO.Open( FileName );
            ForBlock.BlockNum := HeaderBlock;
            (* Complete header block *)

            Process.Unlock;

            Sync := TRUE;

        ELSE

            BlockCount := FIO.RdBin( DataFile, ForBlock.BlockData,
                BlockSize );

            IF FIO.EOF THEN

                FileName := '';

            END (* IF *);

        END (* IF *);

    END GetBlockData;


    PROCEDURE GetErrorCodes( VAR ForBlock : BlockRec );
    (* Stage 4: Error Codes. *)
    BEGIN

        ForBlock.ErrorCode := CRC.CalcCRC( SYSTEM.ADR( ForBlock ),
            SIZE( ForBlock ) - SIZE( ForBlock.ErrorCode ) );

    END GetErrorCodes;


    PROCEDURE Send( VAR ForBlock : BlockRec );
    (* Stage 5 and 6: Sends block data over RS-232 channel,
           and saves it so Receive in the terminal end can
           check the contents. *)
    BEGIN

        (* Stage 5: Loop check *)

        (* Check for synchronize flag *)
        IF Sync THEN

            rs.Break( 10 );
            Sync := FALSE;

        END (* IF *);

        (* Stage 6: Send block *)
        rs.Send( Block, SIZE( Block ) );

    END Send;



VAR
    Block : BlockRec;

BEGIN

  FileName := '';
  Block.ChannelNum := 2;

  LOOP

      (* Stage 1: File and Stage 2: Frame *)
      GetBlockData( Block );

      (* Stage 3: Encrypt. NOT IMPLEMENTED *)

      (* Stage 4: Error codes *)
      GetErrorCodes( Block );

      (* Stage 5 and 6: Loop-check and RS-232*)
      Send( Block );

  END (* LOOP *);

END HostKernel;



VAR
  CRCError : CARDINAL;
  CRCCalc  : CARDINAL;
  SynchBuf1,
  SynchBuf2 : ARRAY [ 0..BlockSize DIV 2 ] OF CHAR;

PROCEDURE Synch;

BEGIN
(*
  rs.Receive( SynchBuf2, SIZE( SynchBuf2 ) );

  LOOP

      SynchBuf1 := SynchBuf2;
      rs.Receive( SynchBuf2, SIZE( SynchBuf2 ) );

      FlagPos := Str.Pos( SynchBuf, SynchFlag );
      IF FlagPos < MAX(CARDINAL) THEN

      ELSE
      END (* IF *);

  END (* LOOP *);
*)
END Synch;


PROCEDURE ReceiveData( VAR ForData  : ARRAY OF BYTE;
                       VAR BlockNum : CARDINAL );

BEGIN

  rs.Receive( BlockNum, 2 );

  rs.Receive( ForData, BlockSize );

  rs.Receive( CRCCalc, 2 );

  Process.Lock;
  Count := Count - (BlockSize+4);
  Process.Unlock;

  IF CRCCalc # CRC.CalcCRC( SYSTEM.ADR(ForData), BlockSize ) THEN

      INC( CRCError );

  END (* IF *);

END ReceiveData;


VAR
  RxData : ARRAY [ 0..BlockSize ] OF BYTE;
  RxBN : CARDINAL;

PROCEDURE TermKernel;

BEGIN

  (* Synchronize with sync flag. *)

  LOOP

      (* Read file block header. *)

      ReceiveData( RxData, RxBN );

  END (* LOOP *);

END TermKernel;


BEGIN

  rs.Install( 2 );
  rs.Init( 9600, 8, rs.None, TRUE, FALSE );

(*  rs.Send( '$$$   ATE1', 4 );
  rs.Send( ASCII.cr, 1 );
  rs.Send( ASCII.lf, 1 ); *)

  (* Get address of DOS busy flag. *)
  R.AH := 34H;
  Lib.Dos( R );
  DOSbusy := [ R.ES : R.BX ];

  HostFileSpec := 'C:\BATCH\*.*';
  HostFilePre := 'C:\BATCH\';

  CRCError := 0;
  Count := 0;

  Process.StartScheduler;

  Process.StartProcess( TermKernel, 4096, 1 );
  Process.StartProcess( HostKernel, 4096, 1 );

  LOOP

      IO.WrCard( rs.TxCount(), 5 );

      IO.WrStr( '  BLOCK#: ' );
      IO.WrCard( BN, 4 );
      IO.WrInt( Count, 6 );

      IO.WrStr( '  FILE: ' );

      IO.WrStr( N );

      IO.WrChar( ASCII.cr );

      Lib.Delay( 300 );

      IF IO.KeyPressed() THEN

          Lib.Delay( 1000 );
          Key := IO.RdKey();
          Key := IO.RdKey();

      END (* IF *);

  END (* LOOP *);

END TestDB.