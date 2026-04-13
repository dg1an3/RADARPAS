IMPLEMENTATION MODULE RadarTx;

IMPORT FIO, rs2, IO, Str;
FROM Lib IMPORT
    Move, Fill;
FROM RadioTx IMPORT
    PrefixRec, PrefixTabPtr, Transmit, FileAt, Directory;
FROM Storage IMPORT
    ALLOCATE;

PROCEDURE GenPrefixData( VAR ForPicture : ARRAY OF BYTE;
                                PicSize : CARDINAL;
                          VAR PrefixTab : PrefixTabPtr );

VAR
  PrefixCount : CARDINAL;

PROCEDURE SetPrefix( At : LONGCARD; Info : ARRAY OF BYTE );
BEGIN

    PrefixTab^[PrefixCount].PrefixAt := At;
    Fill( ADR(PrefixTab^[PrefixCount].PrefixData), 7, 0 );
    Move( ADR(Info), ADR(PrefixTab^[PrefixCount].PrefixData), HIGH(Info)+1 );
    INC( PrefixCount );

END SetPrefix;


VAR
  Count, DestAt : LONGCARD;

BEGIN
  ALLOCATE( PrefixTab, ( PicSize DIV 256 + 1 )* SIZE(PrefixRec) );

  PrefixCount := 0;
  Count := 0;
  DestAt := 0;
  WHILE Count <= LONGCARD(PicSize) DO

      IF ( ForPicture[CARDINAL(Count)] = BYTE(0) ) OR
          ( ForPicture[CARDINAL(Count)] = BYTE(255) ) THEN

          INC( DestAt, LONGCARD(ForPicture[CARDINAL(Count)+1]) );
          INC( Count );
          IF Count MOD 256 = 0 THEN
              SetPrefix( Count+1, DestAt );
          END (* IF *);
          INC( Count );

      ELSE

          INC( DestAt );
          INC( Count );

      END (* IF *);

      IF Count MOD 256 = 0 THEN
          SetPrefix( Count, DestAt );
      END (* IF *);

  END (* WHILE *);
  SetPrefix( LONGCARD(0), LONGCARD(0) );

END GenPrefixData;


PROCEDURE TransmitPic(    PicName : ARRAY OF CHAR;
                       VAR ForPic : ARRAY OF BYTE;
                          PicSize : CARDINAL );

VAR
  Prefix : PrefixTabPtr;
  FNum : CARDINAL;
  TmpSize : LONGCARD;

BEGIN

  GenPrefixData( ForPic, PicSize, Prefix );

  Str.Copy( Directory[1].Name, PicName );

  TmpSize := 0;
  TmpSize := LONGCARD(PicSize);
  Transmit( FNum, ForPic, TmpSize, Prefix );

END TransmitPic;

VAR
  Count   : CARDINAL;
  FNum    : CARDINAL;
  BufSize : CARDINAL;
  F       : FIO.File;
  Buffer  : ARRAY [ 0..16383 ] OF BYTE;
   Prefix  : PrefixTabPtr;

BEGIN

  rs2.Install( 2 );
  rs2.Init( 8200, 8, rs2.None, TRUE, FALSE );

(*  F := FIO.Open( 'DEMO.STA\1426AAP.WX' );
  IF F < MAX(CARDINAL) THEN
      BufSize := FIO.RdBin( F, Buffer, MAX(CARDINAL) );
      FIO.Close( F );
  END (* IF *);

  IO.WrStr( ' GENERATING... ' );
  GenPrefixData( Buffer, BufSize, Prefix );
  IO.WrStr( ' PREFIX TABLE: ' );
  FOR Count := 0 TO BufSize DIV 256 DO
      IO.WrLngCard( Prefix^[Count].PrefixAt, 8 );
      IO.WrLngCard( LONGCARD(Prefix^[Count].PrefixData), 10 );
      IO.WrLn;
  END (* FOR *);

  Transmit( FNum, Buffer, LONGCARD(BufSize), Prefix );

  LOOP
      IO.WrStr( ' SENDING BLOCK ' );
      IO.WrLngCard( FileAt(1), 1 );
      IO.WrLngCard( Directory[1].Prefix.PrefixAt, 20 );
      IO.WrLngCard( LONGCARD(Directory[1].Prefix.PrefixData), 20 );
      IO.WrLn;
  END (* LOOP *); *)

END RadarTx.
