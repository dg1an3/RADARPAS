MODULE RadarRx;

IMPORT rs, Graph, IO, ASCII, Str;
FROM Graphics IMPORT
  SetPlane, SetFont, GotoXY, SetPalette, PaletteType, SetFunc, clr;
FROM Lib IMPORT
  Move, Fill, Delay;
FROM RadioRx IMPORT
  Directory, Receive, FileAt, ErrorCount;
(* FROM ScreenHandler IMPORT
  Message, ClearScreen, Pause; *)


VAR
  Screen [ 0A000H:0000H ] : ARRAY [ 0..27999 ] OF BYTE;

PROCEDURE WritePic( VAR StartAt : LONGCARD;
                     VAR Buffer : ARRAY OF BYTE;
                      VAR SrcAt,
                         BufEnd : CARDINAL );

VAR
  TCount,
(*   SrcAt, *)
  DestAt,
  LineAt,
   Count : CARDINAL;
  RedMap : BOOLEAN;

BEGIN

(*  SrcAt := BufStart; *)
  LineAt := ( CARDINAL( StartAt DIV 320 ) * 2 ) +
      ( CARDINAL(StartAt DIV 80) MOD 2 );
  DestAt := LineAt * 35 DIV 48 * 80 + CARDINAL(StartAt MOD 80);
  RedMap := ~ BOOLEAN( StartAt DIV 160 MOD 2 );
  IF RedMap THEN
      SetPlane( {0} );
  ELSE
      SetPlane( {1} );
  END (* IF *);
  Count := 0;
  TCount := 0;

  WHILE ( SrcAt <= BufEnd ) & ( DestAt <= 28000 ) DO

      IF ( Buffer[SrcAt] = BYTE(00H) ) OR ( Buffer[SrcAt] = BYTE(0FFH) ) THEN

          (* Write fill to next 80 byte boundary *)
          IF Count = 0 THEN
              Count := CARDINAL(Buffer[SrcAt+1]);
              TCount := TCount + Count;
          END (* IF *);

          IF Count <= 80 - ( DestAt MOD 80 ) THEN

              Fill( ADR(Screen[DestAt]), Count, Buffer[SrcAt] );
              INC( DestAt, Count );
              Count := 0;
              INC( SrcAt, 2 );

          ELSE

              Fill( ADR(Screen[DestAt]), 80 - ( DestAt MOD 80 ),
                  Buffer[SrcAt] );
              Count := Count + ( DestAt MOD 80 ) - 80;
              DestAt := DestAt + 80 - ( DestAt MOD 80 );

          END (* IF *);

      ELSE

          Screen[DestAt] := Buffer[SrcAt];
          INC( DestAt );
          INC( SrcAt );
          INC( TCount );

      END (* IF *);

      IF ( DestAt MOD 80 ) = 0 THEN

          INC( LineAt );

          IF ~ ODD(LineAt) THEN

              RedMap := ~ RedMap;

              IF RedMap THEN

                  SetPlane( {0} );
                  DestAt := LineAt * 35 DIV 48 * 80;

              ELSE

                  DEC( LineAt, 2 );
                  SetPlane( {1} );
                  DestAt := LineAt * 35 DIV 48 * 80;

              END (* IF *);

          END (* IF *);

      END (* IF *);

  END (* WHILE *);

  StartAt := LONGCARD(LineAt DIV 2) * 320 +
      LONGCARD(LineAt MOD 2 * 80) + LONGCARD(~ RedMap)*160
      + LONGCARD(DestAt MOD 80);

END WritePic;


VAR
  DumByte  : CARDINAL;
  Buffer   : ARRAY [ 0..16383 ] OF BYTE;
  ScreenAt : LONGCARD;
  Start,
  End      : CARDINAL;
  Count    : CARDINAL;
  Key      : CHAR;
  CurrPicName : ARRAY [ 0..11 ] OF CHAR;

BEGIN

  Graph.InitEGA;
  Graph.GraphMode;
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,
      9,9,9,9,9,9,9,9));
  SetFont( 14 );
  rs.Install( 1 );
  rs.Init( 8200, 8, rs.None, TRUE, FALSE );

  Receive( Buffer, 16384 );

  GotoXY( 0, 0 );
  IO.WrStr( ' SYNCHING...' );
(*  Message( ' SYNCHING... ' ); *)
  WITH Directory[1].Prefix DO
      PrefixAt := 65536;
      WHILE PrefixAt > 65535 DO
(*          GotoXY( 0, 0 );
          IO.WrLngCard( PrefixAt, 8 ); *)
      END;
      Start := CARDINAL(PrefixAt);
      ScreenAt := LONGCARD(PrefixData);
(*      GotoXY( 0, 14 );
      IO.WrCard( Start, 10 );
      IO.WrLngCard( ScreenAt, 20 ); *)
  END (* WITH *);
(*  Message( '' ); *)
  GotoXY( 0, 0 );
  IO.WrStr( '            ' );

  Str.Copy( CurrPicName, Directory[1].Name );

  Delay( 500 );
  WHILE CARDINAL(FileAt(1)) <= Start DO END;

  LOOP
      End := CARDINAL(FileAt(1));
(*      SetPlane( {2} );
      SetFunc( clr, 0 );
      GotoXY( 200, 0 );
      IO.WrStr( CurrPicName );
      IO.WrCard( Start, 5 );
      IO.WrCard( End, 5 );
      IO.WrCard( ErrorCount(), 5 );
      IO.WrCard( CARDINAL(Directory[1].Size), 10 );
      IO.WrStr( ' AT : ' );
      IO.WrLngCard( FileAt(1), 5 );
      IO.WrCard( Start, 6 );
      IO.WrLngCard( ScreenAt, 10 );
      IO.WrCard( End, 6 );
      IO.WrCard( ErrorCount(), 6 ); *)
      IF End > Start THEN
          IF ( Buffer[End] = BYTE(0) ) OR
              ( Buffer[End] = BYTE(255) ) THEN
              DEC( End );
          END (* IF *);
          WritePic( ScreenAt, Buffer, Start, End );
          Start := End+1;
      ELSIF INTEGER(End) < INTEGER(Start-255) THEN
          End := 65535;
          WritePic( ScreenAt, Buffer, Start, End );
          Start := 0;
          ScreenAt := 0;
      END (* IF *);
      IF Str.Compare( Directory[1].Name, CurrPicName ) # 0 THEN
          Str.Copy( CurrPicName, Directory[1].Name );
          Start := 0;
          End := 0;
          ScreenAt := 0;
(*          ClearScreen; *)
      END (* IF *);
      IF IO.KeyPressed() THEN
          Key := IO.RdKey();
          IF Key = ASCII.esc THEN
(*              Key := Pause( ' Quit program ( Y/N )? ' );
              IF CAP(Key) = 'Y' THEN *)
                  EXIT;
(*              END (* IF *); *)
          END (* IF *);
      END (* IF *);
  END (* LOOP *);

(*  Delay( 1000 );

  Start := CARDINAL(FileAt(1));
  WHILE CARDINAL(FileAt(1)) = Start DO END;
  WHILE CARDINAL(FileAt(1)) # Start DO
      SetPlane( {0,1,2,3} );
      GotoXY( 0, 0 );
      IO.WrStr( ' AT : ' );
      IO.WrCard( CARDINAL(FileAt(1)), 10 );
      IO.WrCard( Start, 5 );
      IO.WrLngCard( LONGCARD(Directory[1].Prefix.PrefixData), 10 );
      End := CARDINAL( FileAt(1) );

      IF End > Start THEN
          ScreenAt := LONGCARD(Directory[1].Prefix.PrefixData);
          Count := CARDINAL(Directory[1].Prefix.PrefixAt);
          End := CARDINAL( FileAt(1) );
          WritePic( ScreenAt, Buffer, Count, End );

      ELSE

          ScreenAt := LONGCARD(Directory[1].Prefix.PrefixData);
          Count := CARDINAL(Directory[1].Prefix.PrefixAt);
          End := 65535;
          WritePic( ScreenAt, Buffer, Count, End );

      END (* IF *);

  END (* WHILE *);

  ScreenAt := 57081;
  Start := 6144;
  End := 16384;
  WritePic( ScreenAt, Buffer, Start, End );

  ScreenAt := 43805;
  Start := 3840;
  End := 6144;
  WritePic( ScreenAt, Buffer, Start, End );

  ScreenAt := 31520;
  Start := 2304;
  End := 3840;
  WritePic( ScreenAt, Buffer, Start, End );

  ScreenAt := 23474;
  Start := 1281;
  End := 2304;
  WritePic( ScreenAt, Buffer, Start, End );

  ScreenAt := 14673;
  Start := 512;
  End := 1281;
  WritePic( ScreenAt, Buffer, Start, End );

  ScreenAt := 0;
  Start := 0;
  End := 512;
  WritePic( ScreenAt, Buffer, Start, End );

  (*
  ScreenAt := 0;
  Start := 0;
  End := 16384;
  WritePic( ScreenAt, Buffer, Start, CARDINAL(Directory[1].Size) );

  ScreenAt := 0;
  WritePic( ScreenAt, Buffer, 0, 8191 );
  ScreenAt := 0;
  WritePic( ScreenAt, Buffer, 0, 8191 );
  ScreenAt := 0;
  FOR Count := 0 TO 4097 BY 256 DO

      IF ( Count > 0 ) & (( Buffer[Count-1] = BYTE(0) ) OR
          ( Buffer[Count-1] = BYTE(255) )) THEN
          Start := Count-1;
      ELSE
          Start := Count;
      END (* IF *);
      IF ( Buffer[Count+255] = BYTE(0) ) OR ( Buffer[Count+255] =
          BYTE(255) ) THEN
          End := Count+254;
      ELSE
          End := Count+255;
      END (* IF *);
      WritePic( ScreenAt, Buffer, Start,
          End (* CARDINAL(Directory[1].Size) *) );
  END (* FOR *); *)

  Key := IO.RdKey(); *)

END RadarRx.