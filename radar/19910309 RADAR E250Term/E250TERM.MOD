MODULE E250Term; (* E250 PC terminal version 3.0 *)

(*  E250 PC Terminal, 1.0
 *
 *  Copyright (C) 1990, Derek Graham Lane
 *  All rights reserved.
 *
 *  This terminal program is designed to operate with
 *  the ScrnSend TSR program, which transmits the contents
 *  of the host system's screen buffer.  This terminal
 *  program dials into the host system, downloads the
 *  screen buffer from ScrnSend, and saves each of the
 *  pictures with a time stamp indicating the time and
 *  date of downloading.
 *
 *)

IMPORT
    ASCII,
    CRC,
    ExtendKey,
    FIO,
    Graph,
    Graphics,
    IO,
    Lib,
    Modem,
    rs,
    E250Scrn,
    Str,
    TimeDate;


CONST

    BlockSize = 128;

    ScrnHeight = 350;

    PicMax = 100;


TYPE

    Rect = ARRAY [ 0..3 ] OF CARDINAL;


VAR

    SrcAt, DestAt, P  :  CARDINAL;    (* State of WritePic *)
    Count  :  CARDINAL;


(*
PROCEDURE WritePic( VAR Buffer : ARRAY OF BYTE; BufSize : CARDINAL;
                    VAR SrcAt, DestAt, P : CARDINAL );

VAR
    Count  :  CARDINAL;

BEGIN

    Graphics.SetPlane( {P} );
    Graphics.SetFunc( Graphics.clr, 0 );

    WHILE ( SrcAt+2 <= BufSize ) & ( DestAt <= HIGH( Scrn ) ) DO

        IF ( Buffer[SrcAt] = BYTE(00H) ) OR ( Buffer[SrcAt] = BYTE(0FFH) ) THEN

            (* Write fill to next 28000 byte boundary *)
            Count := CARDINAL(Buffer[SrcAt+1]);

            Lib.Fill( ADR(Scrn[DestAt]), Count, Buffer[SrcAt] );
            INC( DestAt, Count );
            INC( SrcAt, 2 );

        ELSE

            Scrn[DestAt] := Buffer[SrcAt];
            INC( DestAt );
            INC( SrcAt );

        END (* IF *);

        IF ( DestAt >= HIGH(Scrn) ) & ( P < 3 ) THEN

            DestAt := 0;
            P := P+1;
            Graphics.SetPlane({P});

        END (* IF *);

    END (* WHILE *);

    FullScreen := ( DestAt >= HIGH( Scrn ) - 80 ) & ( P = 3 );

END WritePic;
*)


VAR

    Picture  :  ARRAY [ 0..PicMax ], [ 0..15 ] OF CHAR;
    CurrPic  :  INTEGER;
    MaxPic  :  INTEGER;

    PicBuf  :  ARRAY [ 0..32767 ] OF BYTE;
    PicSize  :  CARDINAL;

    OptionRec  :  RECORD
        Phone  :    ARRAY [ 0..34 ] OF CHAR;
        Comm   :    CARDINAL;
        Baud   :    CARDINAL;
        AutoInt  :    CARDINAL;
    END (* RECORD *);

    F  :  FIO.File;

    CurrTime, UpdateTime  :  TimeDate.Time;

    Key  :  CHAR;

    Map0On, Map1On, Map2On, RngMksOn  :  BOOLEAN;


PROCEDURE Redraw;
BEGIN
  Graphics.SetWindow( 0, 0, 639, 349 );
  IF Map0On THEN
      SrcAt := 0;
      DestAt := 0;
      P := 0;
      E250Scrn.WritePic( PicBuf, PicSize, SrcAt, DestAt, P );
  ELSE
      E250Scrn.ClearScreen;
  END (* IF *);
  IF Map1On THEN
      E250Scrn.WriteMap( 1 );
  END (* IF *);
  IF RngMksOn THEN
      E250Scrn.WriteRngMks;
  END (* IF *);
(*  GotoXY( 0, 114 );
  IF MapOn[2] THEN
      MapOn[2] := FALSE;
      WriteMap( 2, TRUE );
  END (* IF *);
  GotoXY( 0, 128 );
  IF RngMksOn THEN
      RngMksOn := FALSE;
      WriteRngMks( TRUE );
  END (* IF *); *)
END Redraw;


PROCEDURE ShowPic( Rel : INTEGER );

(*  Shows the picture relative to the current picture by Rel
 *  steps.  For instance, to show the next picture, use
 *
 *      ShowPic( 1 );
 *
 *  To show the previous picture, use
 *
 *      ShowPic( -1 );
 *)

BEGIN

    CurrPic := ( CurrPic+Rel ) MOD MaxPic;
    IF CurrPic < 0 THEN CurrPic := MaxPic-1 END;

    IF CurrPic > 0 THEN

        F := FIO.Open( Picture[ CurrPic ] );

        IF F < MAX( CARDINAL ) THEN

            PicSize := FIO.RdBin( F, PicBuf, SIZE( PicBuf ) );
            FIO.Close( F );

            SrcAt := 0;
            DestAt := 0;
            P := 0;

            IF Map0On THEN
                Redraw;
            ELSE
                E250Scrn.WritePic( PicBuf, PicSize, SrcAt, DestAt, P );
                Redraw;
            END (* IF *);

        END (* IF *);

    ELSE

        Graphics.SetFunc( Graphics.clr, 0 );
        Graphics.SetPlane( {2,3} );
        Graph.Polygon( 4, Rect(80,80,568,568), Rect(84,154,154,84), 15 );
        Graphics.SetWindow( 80, 84, 488, 225 );
        Graphics.SetFunc( Graphics.xor, 0 );
        Graphics.SetPlane( {3} );
        Graphics.GotoXY( 0, 0 );
        IO.WrStr( 'ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป' );
        IO.WrStr( 'บ                    K S N P   R A D I O                    บ' );
        IO.WrStr( 'บ-----------------------------------------------------------บ' );
        IO.WrStr( 'บ              E250 PC RADAR TERMINAL, ver 1.1              บ' );
        IO.WrStr( 'บ                     Revision 11/27/90                     บ' );
        Graphics.SetFunc( Graphics.clr, 0 );
        Graphics.SetPlane( {2,3} );
        Graph.Polygon( 4, Rect(80,80,568,568), Rect(154,272,272,154), 4 );
        Graphics.SetFunc( Graphics.or, 0 );
        Graphics.SetPlane( {3} );
        IO.WrStr( 'บ                                                           บ' );
        IO.WrStr( 'บ  D  to Dial radar station    |  M  to toggle Map          บ' );
        IO.WrStr( 'บ  +  to view next picture     |  R  to toggle Range marks  บ' );
        IO.WrStr( 'บ  -  to view previous picture |  O  to change Options      บ' );
        IO.WrStr( 'บ  E  to Erase current pictire |  Home centers cursor       บ' );
        IO.WrStr( 'บ  ESC  to exit this program   |  Arrow keys move cursor    บ' );
        IO.WrStr( 'บ-----------------------------------------------------------บ' );
        IO.WrStr( 'บ             Copyright (C) 1990 by D. G. Lane              บ' );
        IO.WrStr( 'ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ' );

        Graphics.SetFunc( Graphics.clr, 0 );

        WHILE IO.KeyPressed() DO
            Key := IO.RdKey();
        END (* WHILE *);

    END (* IF *);

END ShowPic;


PROCEDURE AddPic( Name  :  ARRAY OF CHAR );
(*  Adds the picture file name Name to array Picture
 *  in its proper (alphabetical) spot.
 *
 *)
VAR

    Count  :  INTEGER;

BEGIN

    Count := MaxPic-1;
    WHILE ( Str.Compare( Picture[ Count ], Name ) = 1 ) &
        ( Count > 0 ) DO

        Str.Copy( Picture[ Count+1 ], Picture[ Count ] );
        DEC( Count );

    END (* WHILE *);

    INC( MaxPic );

    Str.Copy( Picture[ Count+1 ], Name );

    CurrPic := Count+1;

END AddPic;


PROCEDURE ErasePic( Num  :  CARDINAL );
(*  Erases picture number Num in Picture and closes
 *  the gap (also erases file)
 *)
VAR

    Count  :  INTEGER;

BEGIN

    FIO.Erase( Picture[ Num ] );

    FOR Count := Num TO MaxPic-1 DO

        Str.Copy( Picture[ Count ], Picture[ Count+1 ] );

    END (* FOR *);
    DEC( MaxPic );

    ShowPic( 0 );

END ErasePic;


PROCEDURE RxPic;

VAR
    SentCRC  :  CARDINAL;
    Key  :  CHAR;

BEGIN

    (* Clear tx and rx buffer *)
    WHILE rs.TxCount() > 0 DO
    END (* WHILE *);
    WHILE rs.RxCount() > 0 DO

        rs.Receive( PicBuf, rs.RxCount() );

    END (* WHILE *);

    (* Initiate download *)
    rs.Send( 'X', 1 );

    (* Now download picture *)
    PicSize := 0;
    E250Scrn.FullScreen := FALSE;
    SrcAt := 0;
    DestAt := 0;
    P := 0;

    Graphics.SetFunc( Graphics.clr, 0 );
    Graphics.SetPlane( {0,1,2,3} );
    Graph.Polygon( 4, Rect(0,0,639,639),
        Rect(0,ScrnHeight,ScrnHeight,0), 0 );

    E250Scrn.DrawScale;
    E250Scrn.Message( ' Receiving picture... ' );

    WHILE ~ E250Scrn.FullScreen DO

        WHILE rs.RxCount() < BlockSize+4 DO

        END (* WHILE *);
        rs.Receive( PicSize, 2 );
        rs.Receive( PicBuf[ PicSize ], BlockSize );
        rs.Receive( SentCRC, 2 );

        IF SentCRC = CRC.CalcCRC( ADR( PicBuf[ PicSize ] ),
            BlockSize ) THEN

            rs.Send( 'A', 1 );

            E250Scrn.WritePic( PicBuf, PicSize, SrcAt, DestAt, P );

        ELSE

            Lib.Sound( 440 );
            Lib.Delay( 500 );
            Lib.NoSound;
            WHILE rs.RxCount() > 0 DO

                rs.Receive( SentCRC, 1 );

            END (* WHILE *);
            rs.Send( 'N', 1 );

        END (* IF *);

    END (* WHILE *);

END RxPic;


PROCEDURE DialRadar;

VAR
    Result  :  Modem.ResultCode;
    SentCRC  :  CARDINAL;
    TimeStr  :  ARRAY [ 0..16 ] OF CHAR;
    Key  :  CHAR;

BEGIN
    LOOP
        Graphics.SetFunc( Graphics.clr, 0 );
        Graphics.SetPlane( {2,3} );
        Graph.Polygon( 4, Rect(160,160,496,496), Rect(62,184,184,62), 4 );
        Graphics.SetWindow( 160, 62, 343, 140 );
        Graphics.SetFunc( Graphics.or, 0 );
        Graphics.SetPlane( {3} );
        Graphics.GotoXY( 0, 0 );
        IO.WrStr( 'ษออออออออออออออออออออออออออออออออออออออออป' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'บ         DIALING RADAR SYSTEM...        บ' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'บ                                        บ' );
        IO.WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );
        IF OptionRec.Phone[ 0 ] # 000C THEN
            Modem.Call( OptionRec.Phone, Result );
        ELSE
            Result := Modem.Connect2400;
        END (* IF *);
        Graphics.GotoXY( 14, 4*14 );
        CASE Result OF
            Modem.Busy  :
                IO.WrStr( '           BUSY! REDIALING...           ' );
                Lib.Delay( 1000 );  |
            Modem.NoCarrier  :
                IO.WrStr( '      NO CARRIER.  ABORTING CALL.       ' );
                Lib.Delay( 1000 );
                EXIT;  |
            Modem.NoDialtone  :
                IO.WrStr( '      NO DIALTONE.  ABORTING CALL.      ' );
                Lib.Delay( 1000 );
                EXIT;  |
            Modem.NoAnswer  :
                IO.WrStr( '       NO ANSWER.  ABORTING CALL.       ' );
                Lib.Delay( 1000 );
                EXIT;  |
            Modem.NoResponse  :
                IO.WrStr( '  MODEM NOT RESPONDING.  ABORTING CALL. ' );
                Lib.Delay( 1000 );
                EXIT;  |
            Modem.Connect2400  :
                IO.WrStr( '         CONNECTED AT 2400 BAUD         ' );
                Lib.Delay( 1000 );
                RxPic;
                (* Assign a file name to the picture *)
                TimeDate.GetTime( CurrTime );
                TimeDate.TimeToString( CurrTime, TimeStr );
                Str.Slice( TimeStr, TimeStr, 6, 8 );
                TimeStr[ 2 ] := '-';
                TimeStr[ 5 ] := '-';
                Str.Concat( TimeStr, TimeStr, '.SCR' );
                (* Save picture *)
                F := FIO.Create( TimeStr );
                FIO.WrBin( F, PicBuf, PicSize );
                FIO.Close( F );
                AddPic( TimeStr );
                EXIT;
        END (* CASE *);
    END (* LOOP *);
    IF OptionRec.Phone[ 0 ] # 000C THEN
        Modem.HangUp( Result );
    END (* IF *);
END DialRadar;


VAR

    Entry  :  FIO.DirEntry;
    OK  :  BOOLEAN;

PROCEDURE InitE250Term;

BEGIN

    FIO.IOcheck := FALSE;

    F := FIO.Open( 'CITIES.GFX' );
    IF F < MAX(CARDINAL) THEN

        Count := FIO.RdBin( F, E250Scrn.ScrnMap[1],
            SIZE( E250Scrn.ScrnMap[1] ) );
        FIO.Close( F );
        Count := 0;
        WHILE E250Scrn.ScrnMap[1,Count].EndFlag # 0 DO
            INC( Count );
        END (* WHILE *);

    ELSE

        E250Scrn.ScrnMap[1,0].EndFlag := 0;
        Count := 1;

    END (* IF *);

    F := FIO.Open( 'LINES.GFX' );
    IF F < MAX(CARDINAL) THEN

        Count := FIO.RdBin( F, E250Scrn.ScrnMap[1,Count],
            SIZE( E250Scrn.ScrnMap[1] ) );
        FIO.Close( F );

    END (* IF *);


    (* Read the options from E250TERM.OPT *)
    F := FIO.Open( 'E250TERM.OPT' );
    IF F < MAX( CARDINAL ) THEN

        Count := FIO.RdBin( F, OptionRec, SIZE( OptionRec ) );
        FIO.Close( F );

    ELSE

        OptionRec.Phone := '102880,3163642731,,,31432746217555';
        OptionRec.Comm := 1;
        OptionRec.Baud := 2400;
        OptionRec.AutoInt := 0;

    END (* IF *);

    rs.Install( OptionRec.Comm );
    rs.Init( 2400, 8, rs.None, TRUE, FALSE );
    IF OptionRec.Phone[ 0 ] # 000C THEN
        rs.Send( 'AT E0 V0 ', 9 );
        rs.Send( ASCII.cr, 1 );
        rs.Send( ASCII.lf, 1 );
    END (* IF *);

    Graph.InitEGA;
    Graph.GraphMode;
    Graphics.SetFont( 14 );
    Graphics.SetPalette( Graphics.PaletteType( 0,50,36,54,9,9,9,9,
        63,63,63,63,63,63,63,63 ) );

    MaxPic := 1;
    CurrPic := 0;

    (* Search for picture files *)
    IF FIO.ReadFirstEntry( '????????.SCR', FIO.FileAttr{},
        Entry ) THEN

        REPEAT

            AddPic( Entry.Name );

        UNTIL ~ FIO.ReadNextEntry( Entry );

    END (* IF *);
    CurrPic := 0;

    TimeDate.TimeToZero( UpdateTime );

END InitE250Term;


PROCEDURE Options;
BEGIN

    Graphics.SetFunc( Graphics.clr, 0 );
    Graphics.SetPlane( {2,3} );
    Graph.Polygon( 4, Rect(160,160,496,496), Rect(62,198,198,62), 4 );
    Graphics.SetWindow( 160, 62, 343, 140 );
    Graphics.SetFunc( Graphics.or, 0 );
    Graphics.SetPlane( {3} );
    Graphics.GotoXY( 0, 0 );
    IO.WrStr( 'ษออออออออออออออออออออออออออออออออออออออออป' );
    IO.WrStr( 'บ       * * * O P T I O N S  * * *       บ' );
    IO.WrStr( 'บ  [R] adar phone number=                บ' );
    IO.WrStr( 'บ                                        บ' );
    IO.WrStr( 'บ  [M] odem COM port= COM                บ' );
    IO.WrStr( 'บ  [B] aud rate=                         บ' );
    IO.WrStr( 'บ  [A] uto update interval=              บ' );
    IO.WrStr( 'บ - Press letter in brackets to change - บ' );
    IO.WrStr( 'บ             - ESC to exit -            บ' );
    IO.WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );

    REPEAT

        Graphics.SetFunc( Graphics.clr, 0 );
        Graphics.SetPlane( {3} );
        Graphics.GotoXY( 3*8, 3*14 );
        IO.WrStr( '                                ' );
        Graphics.GotoXY( 3*8, 3*14 );
        IO.WrStr( OptionRec.Phone );
        Graphics.GotoXY( 25*8, 4*14 );
        IO.WrCard( OptionRec.Comm, 1 );
        Graphics.GotoXY( 17*8, 5*14 );
        IO.WrCard( OptionRec.Baud, 5 );
        Graphics.GotoXY( 28*8, 6*14 );
        IF OptionRec.AutoInt > 0 THEN
            IO.WrCard( OptionRec.AutoInt, 2 );
            IO.WrStr( ' minutes' );
        ELSE
            IO.WrStr( 'off       ' );
        END (* IF *);
        Key := IO.RdKey();
        CASE CAP( Key ) OF
            'R'  :  E250Scrn.Prompt( ' Radar phone number : ',
                        OptionRec.Phone );    |
            'M'  :  IF OptionRec.Comm = 1 THEN
                        OptionRec.Comm := 2;
                    ELSE
                        OptionRec.Comm := 1;
                    END (* IF *);    |
            'B'  :  IF OptionRec.Baud < 1200 THEN
                        OptionRec.Baud := 1200;
                    ELSIF OptionRec.Baud < 2400 THEN
                        OptionRec.Baud := 2400;
                    ELSIF OptionRec.Baud < 9600 THEN
                        OptionRec.Baud := 9600;
                    ELSIF OptionRec.Baud < 19200 THEN
                        OptionRec.Baud := 19200;
                    ELSE
                        OptionRec.Baud := 300;
                    END (* IF *);  |
            'A'  :  IF OptionRec.AutoInt < 60 THEN
                        INC( OptionRec.AutoInt, 15 );
                    ELSE
                        OptionRec.AutoInt := 0;
                    END (* IF *);
        END (* CASE *);

    UNTIL Key = ASCII.esc;
    Key := ASCII.nul;

    (* Write the options to E250TERM.OPT *)
    F := FIO.Create( 'E250TERM.OPT' );
    FIO.WrBin( F, OptionRec, SIZE( OptionRec ) );
    FIO.Close( F );

END Options;


BEGIN

    InitE250Term;

    ShowPic( 0 );
    Map0On := TRUE;
    Map1On := FALSE;
    RngMksOn := FALSE;

    (* Main loop *)
    LOOP
        (* Has a key been pressed? *)
        IF IO.KeyPressed() THEN
            Key := IO.RdKey();
            E250Scrn.DrawCursor;
            CASE CAP( Key ) OF
                '+'  :  (* Next picture on disk *)
                    ShowPic( +1 );  |
                '-'  :  (* Previous picture on disk *)
                    ShowPic( -1 );  |
                'D'  :  (* Dial into radar *)
                    DialRadar;
                    ShowPic( 0 );  |
                'E'  :  (* Erase picture *)
                    IF ( CurrPic > 0 ) & ( CAP( E250Scrn.Pause(
                        ' Erase this picture ( Y/N ) ? ' ) ) = 'Y' ) THEN
                        ErasePic( CurrPic );
                    END (* IF *);  |
                'O'  :  (* Options menu *)
                    Options;
                    InitE250Term;
                    ShowPic( 0 );  |
                'R'  :  (* Range marks on/off *)
                    RngMksOn := ~RngMksOn;
                    Redraw;  |
                '1'  :  (* Toggle map 1 *)
                    Map1On := ~Map1On;
                    Redraw;  |
(*              '2'  :  (* Toggle map 2 *)
                    Map0On := ~Map0On;
                    Redraw;  | *)
                ASCII.esc  :  (* Exit program *)
                    IF CAP( E250Scrn.Pause(
                        ' Exit this program ( Y/N ) ? ' ) ) = 'Y' THEN
                        EXIT;
                    END (* IF *);  |
                ASCII.nul  :  (* Extended key code *)
                    IF IO.KeyPressed() THEN
                        Key := IO.RdKey();
                        CASE Key OF
                            ExtendKey.larr  :
                                IF E250Scrn.CX > 4 THEN
                                    DEC( E250Scrn.CX, 4 );
                                END (* IF *);  |
                            ExtendKey.rarr  :
                                IF E250Scrn.CX < 635 THEN
                                    INC( E250Scrn.CX, 4 );
                                END (* IF *);  |
                            ExtendKey.uarr  :
                                IF E250Scrn.CY > 4 THEN
                                    DEC( E250Scrn.CY, 4 );
                                END (* IF *);  |
                            ExtendKey.darr  :
                                IF E250Scrn.CY < 345 THEN
                                    INC( E250Scrn.CY, 4 );
                                END (* IF *);  |
                            ExtendKey.Home  :
                                E250Scrn.CX := 320;
                                E250Scrn.CY := 175;  |
                        END (* CASE *);
                    END (* IF *);

            END (* CASE *);
            E250Scrn.DrawCursor;
            E250Scrn.WriteRangeBear( E250Scrn.CX, E250Scrn.CY );
        END (* IF *);

        (* Check for auto update *)
        TimeDate.GetTime( CurrTime );
        IF ( OptionRec.AutoInt > 0 ) & ( TimeDate.CompareTime(
            CurrTime, UpdateTime ) = 1 ) THEN

            INC( CurrTime.minute, OptionRec.AutoInt );
            UpdateTime := CurrTime;

            DialRadar;
            ShowPic( 0 );

        END (* IF *);

    END (* LOOP *);

    Graph.TextMode;

END E250Term.
