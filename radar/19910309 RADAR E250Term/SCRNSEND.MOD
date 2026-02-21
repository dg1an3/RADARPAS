(*$S 6000,B-,I-,O-,R-,S-,V-,W-*)
MODULE ScrnSend;

IMPORT
    CRC,
    FIO,
    IO,
    Lib,
    Process,
    rs,
    SYSTEM,
    Storage,
    Str,
    TimeDate;

CONST
   BlockSize  =  128;
   ScrnHeight  =  350;

VAR
   (*$W+*) (* Make these variables volatile *)
   Buffer  :  ARRAY [ 0..32767 ] OF BYTE;
   RealScrn [ 0A000H:0000H ]  :  ARRAY [ 0..ScrnHeight*80 ] OF BYTE;
   Scrn  :  ARRAY [ 0..ScrnHeight*80 ] OF BYTE;
   SrcAt, DestAt  :  CARDINAL;
   BufAt  :  CARDINAL;
   Debug  :  BOOLEAN;
   ExitFlag  :  BOOLEAN;
   (*$W-*)


PROCEDURE SetPlane( ToPlanes : BITSET );
(* Sets the plane(s) for writing and reading. *)
BEGIN
  SYSTEM.Out(3CEH,05H); (* Set read mode 0, write mode 1. *)
  SYSTEM.Out(3CFH,08H);
  SYSTEM.Out(3CEH,07H); (* Set color compare to ToPlanes. *)
  SYSTEM.Out(3CFH,BYTE(ToPlanes));
  SYSTEM.Out(3CEH,02H); (* Set color don't care to unselected
                        planes. *)
  SYSTEM.Out(3CFH,BYTE(ToPlanes));
END SetPlane;


PROCEDURE Compr;

VAR

   SrcAt,
   Count : CARDINAL;

BEGIN

  SrcAt := 0;
  REPEAT

      IF Scrn[SrcAt] = BYTE(00H) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Scrn) ) & ( Scrn[SrcAt] = BYTE(00H) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[ DestAt ] := 00H;
          Buffer[ DestAt+1 ]
              := BYTE(Count);
          INC( DestAt, 2 );

      ELSIF Scrn[SrcAt] = BYTE(0FFH) THEN

          Count := 0;
          WHILE ( SrcAt <= HIGH(Scrn) ) & ( Scrn[SrcAt] = BYTE(0FFH) )
              & ( Count < 255 ) DO

              INC( SrcAt );
              INC( Count );

          END (* WHILE *);

          Buffer[ DestAt ] := 377C;
          Buffer[ DestAt+1 ] := BYTE(Count);
          INC( DestAt, 2 );

      ELSE

          Buffer[ DestAt ] := Scrn[SrcAt];
          INC( DestAt );
          INC( SrcAt );

      END (* IF *);

  UNTIL SrcAt >= HIGH(Scrn);

END Compr;


PROCEDURE TxProcess;

VAR
    P, Y  :  CARDINAL;
    AckChar  :  CHAR;

BEGIN

    WHILE rs.RxCount() > 0 DO

        rs.Receive( AckChar, 1 );

    END (* WHILE *);

    LOOP

        IF ~ Debug THEN

            DestAt := 0;
            FOR P := 0 TO 3 DO
                IF P # 2 THEN
                    SYSTEM.DI;
                    SetPlane( {P} );
                    Lib.Move( ADR( RealScrn ), ADR( Scrn ), SIZE( Scrn ) );
                    SetPlane( {} );
                    SYSTEM.EI;
                    IF P = 3 THEN

                        FOR Y := 0 TO 40 DO
                            Lib.Fill( ADR( Scrn[ Y*80+14 ] ), 52, 0 );
                        END (* FOR *);
                        Lib.Fill( ADR( Scrn[ Y*80+14 ]), 21600, 0 );
                        FOR Y := 310 TO 350 DO
                            Lib.Fill( ADR( Scrn[ Y*80+14 ] ), 52, 0 );
                        END (* FOR *);

                        (* Blank map areas of screen *)
                    END (* IF *);
                ELSE
                    Lib.Fill( ADR( Scrn ), SIZE( Scrn ), 0 );
                END (* IF *);

                Compr;

            END (* FOR *);

        END (* IF *);

        BufAt := 0;
        REPEAT

            IF Debug THEN
                IO.WrStr( ' Sending block ' );
                IO.WrCard( BufAt DIV BlockSize, 1 );
                IO.WrStr( '...' );
                ExitFlag := IO.KeyPressed();
            END (* IF *);

            (* Send block and checksum *)
            rs.Send( BufAt, 2 );
            rs.Send( Buffer[ BufAt ], BlockSize );
            rs.Send( CRC.CalcCRC( ADR( Buffer[ BufAt ] ),
                BlockSize ), 2 );

            (* Wait for tx buffer to clear *)
            WHILE rs.TxCount() > 0 DO

                Process.Delay( 1 );

            END (* WHILE *);

            IF Debug THEN
                IO.WrStr( "waiting for Ack...'" );
                ExitFlag := IO.KeyPressed();
            END (* IF *);

            (* Receive Acknowledge char *)
            WHILE rs.RxCount() = 0 DO

                Process.Delay( 1 );
                ExitFlag := ( Debug & IO.KeyPressed() );

            END (* WHILE *);
            rs.Receive( AckChar, 1 );

            IF Debug THEN
                IO.WrChar( AckChar ); IO.WrStr( "' received." ); IO.WrLn;
            END (* IF *);

            IF AckChar = 'A' THEN

                INC( BufAt, BlockSize );

            END (* IF *);

        UNTIL ( AckChar = 'X') OR ( BufAt > DestAt+BlockSize );

        Process.Delay( 18 );

    END (* LOOP *);

END TxProcess;


VAR

           R  :  SYSTEM.Registers;
     hp, nhp  :  Storage.HeapRecPtr;
    HeapSize  :  CARDINAL;

    CurrentTime  :  TimeDate.Time;
          Key    : CHAR;
          Count  : CARDINAL;
          PicFile : FIO.File;
          Param  :  ARRAY [ 0..9 ] OF CHAR;
          BaudRate  :  CARDINAL;


BEGIN

    Lib.ParamStr( Param, 2 );
    BaudRate := CARDINAL( Str.StrToCard( Param, 10, ExitFlag ) );
    IF BaudRate < 300 THEN
        BaudRate := 2400;
    END (* IF *);
    (* Initialize the RS-232 port *)
    rs.Init( BaudRate, 8, rs.None, TRUE, FALSE );

    Lib.ParamStr( Param, 3 );
    Debug := ( CAP( Param[ 0 ] ) = 'D' );

    Lib.ParamStr( Param, 1 );
    IF Param[ 0 ] = '2' THEN
        rs.Install( 2 );
    ELSE
        rs.Install( 1 );
    END (* IF *);

    (* Write the title banner and exit *)
    IO.WrStr( '-------------------------------------------------' );  IO.WrLn;
    IO.WrStr( ' ScrnSend 1.1');  IO.WrLn;
    IO.WrStr( ' Background Screen Grabber/Communication Program');  IO.WrLn;
    IO.WrStr( '-------------------------------------------------');  IO.WrLn;
    IO.WrLn;
    IO.WrStr( ' Copyright (C) 1990, Derek Graham Lane');  IO.WrLn;
    IO.WrStr( ' All rights reserved');  IO.WrLn;
    IO.WrStr( ' Revision 11/20/90' ); IO.WrLn;
    IO.WrLn;
    IO.WrStr( ' ScrnSend installed on ');
    IF Param[ 0 ] = '2' THEN
        IO.WrStr( 'COM2: at ' );
    ELSE
        IO.WrStr( 'COM1: at ' );
    END (* IF *);
    IO.WrCard( BaudRate, 1 );
    IO.WrStr( ' baud.' );
    IO.WrLn;

    IF Debug THEN

        IO.WrStr( ' **** DEBUGGING MODE ACTIVE **** ' ); IO.WrLn;
        IO.WrStr( ' **** Press any key to exit **** ' ); IO.WrLn;

        (* Read in test data *)
        PicFile := FIO.Open( 'TEST.SCR' );
        DestAt := FIO.RdBin( PicFile, Buffer, 32767 );
        FIO.Close( PicFile );

        (* Start the comm process *)
        Process.StartScheduler;
        Process.StartProcess( TxProcess, 4096, 1 );

        ExitFlag := FALSE;
        WHILE ~ ExitFlag DO
        END (* WHILE *);

    ELSE

        (* Start the comm process *)
        Process.StartScheduler;
        Process.StartProcess( TxProcess, 4096, 1 );

        (* TERMINATE-AND-STAY-RESIDENT *)
        hp := Storage.MainHeap;
        HeapSize := 1024;

        (* Truncate Main Heap *)
        LOOP

            nhp := hp^.next;
            IF nhp^.size = 0FFFFH THEN
                nhp := [ SYSTEM.HeapBase + HeapSize-1 : 0 ] ;
                IF ( SYSTEM.Seg( hp^ ) + hp^.size <> SYSTEM.Seg( nhp ) )
                    AND ( SYSTEM.Seg( nhp^ ) > SYSTEM.Seg( hp^ ) ) THEN
                    hp^.next := nhp;
                    hp^.size := SYSTEM.Seg( nhp^ ) - SYSTEM.Seg( hp^ );
                    nhp^.next := [ SYSTEM.HeapBase : 0 ];
                    nhp^.size := 0FFFFH;
                ELSE
                    Lib.FatalError( 'Not enough storage' );
                END;
                EXIT;
            END;
            hp := nhp;
        END;

        (* Release Environment *)
        R.ES := CARDINAL( [ Lib.PSP : 2CH ]^ );
        R.AX := 04900H;
        Lib.Dos( R );

        R.AX := 03100H;    (*Terminate and stay resident*)
        R.DX := SYSTEM.HeapBase + HeapSize - Lib.PSP;
        Lib.Intr( R, 21H ); (* Use Intr, so as not to trigger the
                            Dos re-entry run-time check  *)

        (* No return *)

    END (* IF *);

END ScrnSend.
