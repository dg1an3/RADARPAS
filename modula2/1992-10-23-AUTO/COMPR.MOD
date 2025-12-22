VAR

  Screen [ 0A000H:0000H ] : ARRAY [ 0..28000 ] OF BYTE;


PROCEDURE ComprLine( Number        : CARDINAL;
                     VAR Red, Grn  : ARRAY OF BYTE;
                     VAR Buffer    : ARRAY OF BYTE;
                     VAR DestAt    : CARDINAL );
VAR

   SrcAt,
   Count : CARDINAL;

BEGIN

  SetPlane( {0} );
  Move( ADR(Red), ADR(Screen[ Number*80 ]), 160 );

  SetPlane( {1} );
  Move( ADR(Grn), ADR(Screen[ Number*80 ]), 160 );

  SrcAt := 0;
  REPEAT

      IF Red[SrcAt] = BYTE(00H) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Red) ) & ( Red[SrcAt] = BYTE(00H) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 00H;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSIF Red[SrcAt] = BYTE(0FFH) THEN

          Count := 0;

          WHILE ( SrcAt <= HIGH(Red) ) & ( Red[SrcAt] = BYTE(0FFH) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 377C;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSE

          Buffer[DestAt] := Red[SrcAt];
          INC( DestAt );
          INC( SrcAt );

      END (* IF *);

  UNTIL SrcAt > HIGH(Red);


  SrcAt := 0;
  REPEAT

      IF Grn[SrcAt] = BYTE(00H) THEN

          Count := 0;

          WHILE ( SrcAt <= HIGH(Grn) ) & ( Grn[SrcAt] = BYTE(00H) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 00H;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSIF Grn[SrcAt] = BYTE(0FFH) THEN

          Count := 0;

          WHILE ( SrcAt <= HIGH(Grn) ) & ( Grn[SrcAt] = BYTE(0FFH) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[DestAt] := 377C;
          Buffer[DestAt+1] := BYTE(Count);
          INC( DestAt, 2 );

      ELSE

          Buffer[DestAt] := Grn[SrcAt];
          INC( DestAt );
          INC( SrcAt );

      END (* IF *);

  UNTIL SrcAt > HIGH(Grn);


END ComprLine;



PROCEDURE WritePic( VAR Buffer : ARRAY OF BYTE; BufSize : CARDINAL );

VAR

   SrcAt,
  DestAt,
  LineAt,
   Count : CARDINAL;
  RedMap : BOOLEAN;

BEGIN

  SrcAt := 0;
  DestAt := 0;
  LineAt := 0;
  RedMap := TRUE;
  Count := 0;
  SetPlane( {0} );

  WHILE ( SrcAt <= BufSize ) & ( DestAt <= 28000 ) DO

      IF ( Buffer[SrcAt] = BYTE(00H) ) OR ( Buffer[SrcAt] = BYTE(0FFH) ) THEN

          (* Write fill to next 80 byte boundary *)
          IF Count = 0 THEN
              Count := CARDINAL(Buffer[SrcAt+1]);
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

END WritePic;
