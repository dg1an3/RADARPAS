MODULE Main (* E300PC version 3.1SCA *);


FROM Analysis IMPORT
    LastMarker, Trail, DrawMarkers;

IMPORT ASCII;

IMPORT DB;

FROM ExtendKey IMPORT
  F1, F2, F3, F4, F5, F6, F7, larr, rarr, uarr, darr, ExtRead;

FROM E300Interface IMPORT
  TiltType, RangeType, GainType, RTState, GetParam, SetParam,
  Map, CheckMaps, GetMaps, MakePic, AbortPic, PicReady, GetLine;

FROM FIO IMPORT
  File, IOcheck, Open, Create, Close, RdBin, WrBin, Erase,
  FileAttr, directory, ChDir, GetDir, MkDir, RmDir, DirEntry,
  ReadFirstEntry, ReadNextEntry;
IMPORT FIO;

FROM Graph IMPORT
  InitEGA, GraphMode, TextMode, Polygon, Ellipse;

FROM Graphics IMPORT
  SetPlane, SetFunc, xor, clr, or, FillArea, SetWindow,
  ScrollUp, ScrollDown, Line, SetFont, SetHalftone, GotoXY,
  PaletteType, SetPalette;

FROM IO IMPORT
  WrChar, RdKey, WrStr, WrStrAdj, WrLn, WrCard, WrLngCard,
  KeyPressed;

FROM Lib IMPORT
  AddAddr, Sound, Delay, NoSound, Dos, Fill, Move;

FROM Locator IMPORT
  CX, CY, CursorOn, DrawCursor, WriteRangeBear;

FROM Modem IMPORT
  ResultCode, Call;

FROM Pictures IMPORT
  PicFlag, PicFlagSet, PictureRec, FileParam, SavePicture,
  ReserveMem, SelectPicture, AddPicture, DeletePicture,
  PictureMenu, FileName;

IMPORT Process;

IMPORT rs;

FROM ScreenHandler IMPORT
  ArmyTime, WriteTime, WriteDate, WriteTilt, WriteRange,
  WriteGain, WriteParams, RngMksOn, WriteRngMks, Message,
  Prompt, Pause, ToggleGraphics, ClearScreen, ScrnMap,
  MapOn, WriteMap, SetHelpMode, HelpOn, WriteHelp, ComprLine,
  WritePic, Redraw, DrawScale;

FROM Selector IMPORT
  Select;

FROM Stations IMPORT
  StationPtr, StationRec, CallStation, SelectStation,
  AddStation, DelStation, StationMenu, InitStationDir;

FROM Storage IMPORT
  ALLOCATE, DEALLOCATE, Available;

FROM Str IMPORT
  Slice, Copy, Concat, Pos, StrToCard, CardToStr, Length,
  Compare;

FROM SYSTEM IMPORT
  BYTE, ADR, ADDRESS, Registers;

FROM TimeDate IMPORT
  GetTime, CompareTime, Time;


TYPE

  ModeType = ( Modem, Interactive, RxPic, RxGraph );


VAR

  FirstStation,
  CurrentStation : StationPtr;
   NumofStations : CARDINAL;
     CurrentTime : Time;
             Com : CHAR;
            TPtr : ADDRESS;
     CursX,CursY : CARDINAL;
              OK : BOOLEAN;
            Mode : ModeType;
         MainDir : ARRAY [ 0..39 ] OF CHAR;
      MarkersOn  :  BOOLEAN;


PROCEDURE ExecCom( Key : CHAR );

BEGIN

  CASE CAP(Key) OF (* Process regular key codes *)

 'G': ToggleGraphics |

 'R': WriteRngMks( ~ RngMksOn ) |

 'H': WriteHelp( ~ HelpOn ); |

 'L': CursorOn := ~ CursorOn |

 '1': WriteMap( 1, ~ MapOn[1] ) |

 '2': WriteMap( 2, ~ MapOn[2] ) |

  END (* CASE *);

END ExecCom;


VAR
     Options  :  RECORD
         Baud     :  CARDINAL;
         ComPort  :  CARDINAL;
         Update   :  CARDINAL;
         ArmyTime :  BOOLEAN;
         Maps     :  BOOLEAN;
         Banner   :  ARRAY [ 0..40 ] OF CHAR;
     END (* RECORD *);

VAR
    NextUpdate  :  Time;
    Interval  :  CARDINAL;


PROCEDURE OptionMenu;
VAR
    Key  :  CHAR;
    OptFile  :  File;
    OptName  :  ARRAY [ 0..63 ] OF CHAR;

BEGIN
    (* Draw the window *)
    SetPlane( {2} );
    SetFunc( clr, 0 );
    FillArea( 184, 28, 264, 294, CARDINAL(0FFFFH) );
    SetPlane( {3} );
    SetFunc( clr, 0 );
    SetWindow( 184, 28, 264, 294 );
    REPEAT
        (* Write options *)
        GotoXY( 0, 0 );
        WrStr( 'อออออออออออ OPTIONS ออออออออออออ' ); WrLn; WrLn;
        WrStr( ' B ๚ Radar baud      : ' );
        WrCard( Options.Baud, 5 ); WrLn;
        WrStr( ' P ๚ Radar port      : COM' );
        WrCard( Options.ComPort, 1 ); WrLn;
        WrStr( ' U ๚ Update interval : ' );
        IF Options.Update > 0 THEN
            WrCard( Options.Update, 3 ); WrLn;
        ELSE
            WrStr( 'Off' ); WrLn;
        END (* IF *);
        IF Options.ArmyTime THEN
            WrStr( ' C ๚ Clock format    : 24 hour' ); WrLn;
        ELSE
            WrStr( ' C ๚ Clock format    : 12 hour' ); WrLn;
        END (* IF *);
(*        IF Options.Maps THEN
            WrStr( ' M ๚ Draw maps       : In front' ); WrLn;
        ELSE
            WrStr( ' M ๚ Draw maps       : Behind' ); WrLn;
        END (* IF *); *)
        GotoXY( 0, 266 );
        WrStr( 'อออออออออออออออออออออออออออออออออ' );
        WrStr( '       <ESC>๚Exit and save       ');
        Key := RdKey();
        CASE CAP(Key) OF
            "B" : CASE Options.Baud OF
                    300 : Options.Baud := 1200 |
                    1200 : Options.Baud := 2400 |
                    2400 : Options.Baud := 9600 |
                    9600 : Options.Baud := 19200
                  ELSE
                    Options.Baud := 300
                  END (* CASE *) |
            "P" : IF Options.ComPort = 1 THEN
                      Options.ComPort := 2
                  ELSE
                      Options.ComPort := 1
                  END (* IF *) |
            "U" : CASE Options.Update OF
                    0 : Options.Update := 1 |
                    1 : Options.Update := 5 |
                    5 : Options.Update := 10 |
                    10 : Options.Update := 15 |
                    15 : Options.Update := 30 |
                    30 : Options.Update := 60
                  ELSE
                    Options.Update := 0;
                  END (* CASE *) |
            "C" : Options.ArmyTime := ~ Options.ArmyTime |
(*            "M" : Options.Maps := ~ Options.Maps *)
        END (* CASE *);
    UNTIL Key = ASCII.esc;

    Concat( OptName, MainDir, '\E300PC.DAT' );
    OptFile := Open( OptName );
    IF OptFile = MAX( CARDINAL ) THEN
        OptFile := Create( OptName );
    END (* IF *);
    WrBin( OptFile, Options, SIZE( Options ) );
    Close( OptFile );

    ArmyTime := Options.ArmyTime;
(*    rs.Install( Options.ComPort ); *)
    rs.Init( Options.Baud, 8, rs.None, TRUE, FALSE );
    Interval := Options.Update;
    GetTime( NextUpdate );

    SetPlane( {2,3} );
    SetFunc( clr, 0 );
    FillArea( 184, 28, 264, 294, 0 );
    SetWindow( 0, 0, 639, 349 );
    Redraw;

END OptionMenu;


VAR
  CurrTime : Time;

PROCEDURE DoAuto;

VAR
  NewPicture  :  PictureRec;
  Key         :  CHAR;
  Escape      :  BOOLEAN;
(*  Tilt  :  TiltType;
  Range :  RangeType;
  Gain  :  GainType; *)
  RT    : RTState;
  AbortPending : BOOLEAN;
        Number : CARDINAL;
            At : CARDINAL;
     ComprSize : CARDINAL;
       ComprAt : ADDRESS;
    PictureNum : CARDINAL;
        Length : CARDINAL;
      Red, Grn : ARRAY [ 0..159 ] OF BYTE;


BEGIN
    IF Interval = 0 THEN
        RETURN;
    END;
    GetTime( CurrTime );
    IF CompareTime( CurrTime, NextUpdate ) < 0 THEN
         RETURN;
    END (* IF *);
    WITH NextUpdate DO
        day := day + ( minute + Interval ) DIV 1440;
        minute := ( minute + Interval ) MOD 1440;
    END (* WITH *);
    Message( ' PERFORMING AUTO PROGRAM... ' );

    IF ~ CallStation( CurrentStation^ ) THEN

        RETURN;

    END (* IF *);

    WITH NewPicture DO

        GetTime( TimeofPic );
        GetParam( Tilt, Range, Gain, TimeofPic, RT );
        IF Tilt>MAX(TiltType) THEN

            GetParam( Tilt, Range, Gain, TimeofPic, RT );
            IF Tilt > MAX( TiltType ) THEN
                Message( ' No Response. ' );
                RETURN;
            END (* IF *);

        END (* IF *);
        WriteParams( Tilt, Range, Gain, TimeofPic, RT );
        WITH CurrentStation^ DO
            IF Picture[ 1 ].TimeofPic = TimeofPic THEN
                Message( '' );
                RETURN;
            END (* IF *);
        END (* WITH *);

    END (* WITH *);

    SetPlane( {3} );
    SetFunc( clr, 0 );
    GotoXY( 576, 294 );
    WrStr( 'ON LINE' );
    Message( ' Waiting for picture... ' );
    MakePic;
    DrawScale;
    ALLOCATE( NewPicture.Data, 54000 );
    NewPicture.Size := 54000;
    Key := ASCII.nul;

    Process.Lock; (* Set xmit *)
    Fill( ADR( DB.Buffer ), 54000, 0 );
    Move( ADR(NewPicture.TimeofPic), ADR(DB.Buffer), 6 );
    DB.Buffer[ 6 ] := BYTE(NewPicture.Range);
    DB.Buffer[ 7 ] := BYTE(NewPicture.Gain);
    DB.Buffer[ 8 ] := BYTE(NewPicture.Tilt);
    DB.Size := 9;
    Process.Unlock;

    REPEAT

        IF KeyPressed() THEN
            ExtRead( Key, Escape );
            IF ( Key = ASCII.esc ) & ~ AbortPending THEN

                Message( ' Abort Picture ( Y/N ) ? ' );
                Key := ASCII.nul;

            ELSIF ( Key = 'Y' ) & AbortPending THEN


                Message( ' Picture Aborted. ' );
                AbortPic;
                Key := ASCII.esc;

            ELSE

                Message( ' Waiting for picture... ' );

            END (* IF *);

        END (* IF *);

    UNTIL PicReady() OR ( Key = ASCII.esc );

    Number := 0;
    At := 0;
    Escape := FALSE;
    Message( ' Receiving Picture, ESC to abort... ' );
    WHILE ( Number < 476 ) & ( Key # ASCII.esc ) DO

        IF KeyPressed() THEN
            ExtRead( Key, Escape );
        END (* IF *);

        IF ( Key # ASCII.nul ) & ~ Escape THEN

            IF AbortPending THEN

                IF ( CAP(Key) = 'Y' ) THEN

                    Message( ' Picture Aborted. ' );
                    AbortPic;
                    Key := ASCII.esc;

                ELSE

                    ExecCom( Key );

                END (* IF *);
                AbortPending := FALSE;
                Message( ' Receiving Picture, ESC to abort... ' );

            ELSE

                IF Key = ASCII.esc THEN

                    Message( ' Abort Picture ( Y/N ) ? ' );
                    AbortPending := TRUE;
                    Key := ASCII.nul;

                ELSE

                    ExecCom( Key );

                END (* IF *);

            END (* IF *);
            Key := ASCII.nul;

        END (* IF *);

        IF rs.RxCount() > 0 THEN
            GetLine( Number, Red, Grn );
            ComprLine( Number, Red, Grn,
                NewPicture.Data^, At );
            Process.Lock;
            Move( NewPicture.Data, ADR( DB.Buffer[ 9 ]), At );
            DB.Size := At+9;
            Process.Unlock;
        END (* IF *);

    END (* WHILE *);

    WHILE rs.RxCount() > 0 DO
        rs.Receive( Key, 1 );
    END (* WHILE *);

    Message( ' Saving picture... ' );
    NewPicture.Size := At;
    SavePicture( NewPicture, Escape );
    AddPicture( CurrentStation^.Picture,
        CurrentStation^.NumofPictures, NewPicture,
        CurrentStation^.CurrentPicture );
    INC( CurrentStation^.CurrentPicture );

    NewPicture.Size := 54000;
    DEALLOCATE( NewPicture.Data, 54000 );
    NewPicture.Data := NIL;
    NewPicture.Size := 0;

    Message( '' );
    Mode := Modem;
    SetPlane( {3} );
    SetFunc( clr, 0 );
    GotoXY( 576, 294 );
    WrStr( '       ' );

END DoAuto;


PROCEDURE InterLoop;

VAR

    NewPicture : PictureRec;
           Key : CHAR;
        Escape : BOOLEAN;
            RT : RTState;
  AbortPending : BOOLEAN;
        Number : CARDINAL;
            At : CARDINAL;
     ComprSize : CARDINAL;
       ComprAt : ADDRESS;
    PictureNum : CARDINAL;
        Length : CARDINAL;
      Red, Grn : ARRAY [ 0..159 ] OF BYTE;

BEGIN

  SetHelpMode( 2 );

  SetPlane( {0,1} );
  ClearScreen;

  IF ~ CallStation( CurrentStation^ ) THEN

      RETURN;

  END (* IF *);
  Message( '' );

  WITH NewPicture DO

      GetTime( TimeofPic );
      GetParam( Tilt, Range, Gain, TimeofPic, RT );
      IF Tilt>MAX(TiltType) THEN

          GetParam( Tilt, Range, Gain, TimeofPic, RT );
          IF Tilt > MAX( TiltType ) THEN
              Message( ' No Response. ' );
              RETURN;
          END (* IF *);

      ELSE

          WriteParams( Tilt, Range, Gain, TimeofPic, RT );

      END (* IF *);

  END (* WITH *);

  SetPlane( {3} );
  SetFunc( clr, 0 );
  GotoXY( 576, 294 );
  WrStr( 'ON LINE' );

(*  IF ~ CheckMaps( ScrnMap[1] ) THEN

      Message( ' One moment, please.  Receiving new maps... ' );
      GetMaps( ScrnMap[1], ScrnMap[2] );

  END (* IF *); *)

  REPEAT

(*      ExtRead( Key, Escape ); *)
      (* Set for auto download of picture *)
      Escape := TRUE;
      Key := F7;

      IF ~ Escape THEN

          ExecCom( Key );

      ELSE


          CASE Key OF              (* Process extended key codes *)

         F1 : IF NewPicture.Tilt < MAX(TiltType) THEN

                  WITH NewPicture DO

                      INC( Tilt );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );

                  END (* WITH *);

              END (* IF *); |

         F2 : IF NewPicture.Tilt > MIN(TiltType) THEN

                  WITH NewPicture DO

                      DEC( Tilt );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );

                  END (* WITH *);

              END (* IF *); |

         F3 : IF NewPicture.Range < MAX(RangeType) THEN

                  WITH NewPicture DO

                      INC( Range );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );
                      SetPlane( {2,3} );
                      ClearScreen;
                      Redraw;

                  END (* WITH *);

              END (* IF *); |

         F4 : IF NewPicture.Range > MIN(RangeType) THEN

                  WITH NewPicture DO

                      DEC( Range );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );
                      SetPlane( {2,3} );
                      ClearScreen;
                      Redraw;

                  END (* WITH *);

              END (* IF *); |

         F5 : IF NewPicture.Gain < MAX(GainType) THEN

                  WITH NewPicture DO

                      INC( Gain );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );

                  END (* WITH *);

              END (* IF *); |

         F6 : IF NewPicture.Gain > MIN(GainType) THEN

                  WITH NewPicture DO

                      DEC( Gain );
                      SetParam( Tilt, Range, Gain, TimeofPic, RT );
                      WriteParams( Tilt, Range, Gain, TimeofPic, RT );

                  END (* WITH *);

              END (* IF *); |

         F7 : Message( ' Waiting for picture... ' );
              MakePic;
              DrawScale;
              ALLOCATE( NewPicture.Data, 54000 );
              NewPicture.Size := 54000;
              Key := ASCII.nul;

              Process.Lock; (* Set xmit *)
              DB.Size := 0;
              Fill( ADR( DB.Buffer ), 54000, 0 );
              Move( ADR(NewPicture.TimeofPic), ADR(DB.Buffer), 6 );
              DB.Buffer[ 6 ] := BYTE(NewPicture.Range);
              DB.Buffer[ 7 ] := BYTE(NewPicture.Gain);
              DB.Buffer[ 8 ] := BYTE(NewPicture.Tilt);
              DB.Size := 9;
              Process.Unlock;

              REPEAT

                  IF KeyPressed() THEN
                      ExtRead( Key, Escape );
                      IF ( Key = ASCII.esc ) & ~ AbortPending THEN

                          Message( ' Abort Picture ( Y/N ) ? ' );
                          Key := ASCII.nul;

                      ELSIF ( Key = 'Y' ) & AbortPending THEN


                          Message( ' Picture Aborted. ' );
                          AbortPic;
                          Key := ASCII.esc;

                      ELSE

                          Message( ' Waiting for picture... ' );

                      END (* IF *);

                  END (* IF *);

              UNTIL PicReady() OR ( Key = ASCII.esc );

              Number := 0;
              At := 0;
              Escape := FALSE;
              Message( ' Receiving Picture, ESC to abort... ' );
              WHILE ( Number < 476 ) & ( Key # ASCII.esc ) DO

                  IF KeyPressed() THEN
                      ExtRead( Key, Escape );
                  END (* IF *);

                  IF ( Key # ASCII.nul ) & ~ Escape THEN

                      IF AbortPending THEN

                          IF ( CAP(Key) = 'Y' ) THEN

                              Message( ' Picture Aborted. ' );
                              AbortPic;
                              Key := ASCII.esc;

                          ELSE

                              ExecCom( Key );

                          END (* IF *);
                          AbortPending := FALSE;
                          Message( ' Receiving Picture, ESC to abort... ' );

                      ELSE

                          IF Key = ASCII.esc THEN

                              Message( ' Abort Picture ( Y/N ) ? ' );
                              AbortPending := TRUE;
                              Key := ASCII.nul;

                          ELSE

                              ExecCom( Key );

                          END (* IF *);

                      END (* IF *);
                      Key := ASCII.nul;

                  END (* IF *);

                  IF rs.RxCount() > 0 THEN
                      GetLine( Number, Red, Grn );
                      ComprLine( Number, Red, Grn,
                          NewPicture.Data^, At );
                      Process.Lock;
                      Move( NewPicture.Data, ADR( DB.Buffer[ 9 ]), At );
                      DB.Size := At+9;
                      Process.Unlock;
                  END (* IF *);

              END (* WHILE *);

              WHILE rs.RxCount() > 0 DO
                  rs.Receive( Key, 1 );
              END (* WHILE *);
              Message( ' Saving picture... ' );
              NewPicture.Size := At;
              SavePicture( NewPicture, Escape );
              AddPicture( CurrentStation^.Picture,
                  CurrentStation^.NumofPictures, NewPicture,
                  CurrentStation^.CurrentPicture );
              INC( CurrentStation^.CurrentPicture );

              NewPicture.Size := 54000;
              DEALLOCATE( NewPicture.Data, 54000 );
              NewPicture.Data := NIL;
              NewPicture.Size := 0;

              Message( '' );
              Mode := Modem;
              Key := ASCII.nul;

          END (* CASE *);

      END (* IF *);

      IF Key = ASCII.esc THEN

          Message( ' Disconnect Station ( Y/N ) ? ' );
          ExtRead( Key, Escape );
          IF CAP(Key) = 'Y' THEN

              Key := ASCII.esc;

          END (* IF *);
          Message( '' );

      END (* IF *);

  UNTIL ( Key = ASCII.esc ) OR ( Mode = Modem );

  IF Mode # Modem THEN

(*      HangUp *)

  END (* IF *);

  Key := ASCII.nul;

  SetPlane( {3} );
  SetFunc( clr, 0 );
  GotoXY( 576, 294 );
  WrStr( '       ' );

  Mode := Modem;
  SetHelpMode( 1 );

END InterLoop;


PROCEDURE AutoMenu;
VAR
    IntStr  :  ARRAY [ 0..5 ] OF CHAR;
    OK      :  BOOLEAN;
BEGIN
    Prompt( 'Update interval (blank to turn OFF): ', IntStr );
    Interval := CARDINAL( StrToCard( IntStr, 10, OK ));
    IF ~ OK THEN Interval := 0;
    END;
    Message( '' );
END AutoMenu;


PROCEDURE ModemLoop;

VAR

  ThisTime : Time;
       Key : CHAR;
    Escape, done : BOOLEAN;
    PicFileName : ARRAY [ 0..11 ] OF CHAR;

BEGIN

  SetHelpMode( 1 );

  DrawCursor;
  WriteRangeBear( CX, CY );
(*  LastMarker := 0; *)
  REPEAT

      IF KeyPressed() THEN

          DrawCursor;
          ExtRead( Key, Escape );

          IF ~ Escape THEN

              CASE CAP( Key ) OF

(*            'M' : (* Set marker *)
                  Trail[ LastMarker ].X := CX;
                  Trail[ LastMarker ].Y := CY;
                  LastMarker := LastMarker+1;
                  SetFunc( or, 0 );
                  DrawMarkers;  | *)

            '+' : WITH CurrentStation^ DO

                      IF CurrentPicture < NumofPictures THEN

                          IF ( CurrentPicture > 0 ) THEN
                              DEALLOCATE( Picture[CurrentPicture].Data,
                                  Picture[CurrentPicture].Size );
                              Picture[CurrentPicture].Data := NIL;
                          END (* IF *);
                          INC( CurrentPicture );
(*                        ReserveMem( Picture[CurrentPicture].Data,
                              54000, Picture, NumofPictures, done );
                          IF done THEN *)
                              SelectPicture( Picture[CurrentPicture] );
                              IF ( ( MapOn[ 1 ] ) OR ( MapOn[ 2 ] ) ) &
                                  ( Picture[ CurrentPicture-1 ].Range #
                                  Picture[ CurrentPicture ].Range ) THEN
                                  SetPlane( {2,3} );
                                  ClearScreen;
                                  Redraw;
                              END (* IF *);
(*                        ELSE
                              Message( ' Internal Error #4 ' );
                          END (* IF *); *)

                      END (* IF *);

                  END (* WITH *); |

            '-' : WITH CurrentStation^ DO

                      IF CurrentPicture > 1 THEN

                          DEALLOCATE( Picture[CurrentPicture].Data,
                              Picture[CurrentPicture].Size );
                          DEC( CurrentPicture );
(*                        ReserveMem( Picture[CurrentPicture].Data,
                              54000, Picture, NumofPictures, done );
                          IF done THEN *)
                              SelectPicture( Picture[CurrentPicture] );
                              IF ( ( MapOn[ 1 ] ) OR ( MapOn[ 2 ] ) ) &
                                  ( Picture[ CurrentPicture+1 ].Range #
                                  Picture[ CurrentPicture ].Range ) THEN
                                  SetPlane( {2,3} );
                                  ClearScreen;
                                  Redraw;
                              END (* IF *);
(*                        ELSE
                              Message( ' Internal Error #4 ' );
                          END (* IF *); *)

                      ELSE

                          CurrentPicture := 0;
                          SetFunc( clr, 0 );
                          SetPlane( {0,1} );
                          FillArea( 0, 0, 639, 349, CARDINAL(0) );
                          WriteParams( 255, 255, 255, CurrentTime, NoRT );
                          SetPlane( {2,3} );
                          ClearScreen;
                          Redraw;

                      END (* IF *);

                  END (* WITH *); |

              ELSE

                  ExecCom( Key );

              END;

          ELSE

              CASE Key OF

             F1 : ChDir( MainDir );
                  StationMenu( FirstStation,
                      NumofStations, CurrentStation ) |

             F2 : IF CurrentStation # NIL THEN
                      InterLoop;
                  END (* IF *) |

             F3 : IF CurrentStation # NIL THEN
                      PictureMenu( CurrentStation^.Picture,
                          CurrentStation^.NumofPictures,
                          CurrentStation^.CurrentPicture );
                  END (* IF *) |

             F4 : (* Manually transmit picture *)
                  Process.Lock;
                  IF CurrentStation^.CurrentPicture > 0 THEN
                      WITH CurrentStation^.Picture[
                          CurrentStation^.CurrentPicture ] DO
                          Fill( ADR( DB.Buffer ), 54000, 0 );
                          Move( ADR(TimeofPic),
                              ADR(DB.Buffer), 6 );
                          DB.Buffer[ 6 ] := BYTE(Range);
                          DB.Buffer[ 7 ] := BYTE(Gain);
                          DB.Buffer[ 8 ] := BYTE(Tilt);
                          Move( Data, ADR( DB.Buffer[ 9 ]), Size );
                          DB.Size := Size+9;
                      END (* WITH *);
                  END (* IF *);
                  Process.Unlock |

           larr : IF CX > 0 THEN
                      DEC( CX, 2 );
                  END (* IF *) |

           rarr : IF CX < 639 THEN
                      INC( CX, 3 );
                  END (* IF *) |

           uarr : IF CY > 0 THEN
                      DEC( CY, 2 );
                  END (* IF *) |

           darr : IF CY < 349 THEN
                      INC( CY, 2 );
                  END (* IF *) |

           030C : OptionMenu (* Alt-O *)

              END (* CASE *)

          END (* IF *);

          IF Key = ASCII.esc THEN

              IF CAP(Pause( ' Exit program ( Y/N ) ? ' )) # 'Y' THEN

                  Key := ASCII.nul;

              END (* IF *);

          END (* IF *);
          DrawCursor;
          IF ~ KeyPressed() THEN
              WriteRangeBear( CX, CY );
          END (* IF *);

      END (* IF *);

      DoAuto;
      WHILE ( CurrentStation^.NumofPictures >= 99 ) DO
          (* See if oldest needs to be deleted *)
          DeletePicture( CurrentStation^.Picture,
                         CurrentStation^.NumofPictures,
                         CurrentStation^.NumofPictures );
      END (* WHILE *);

      IF ( CurrentStation^.CurrentPicture = 0 ) &
          ( ThisTime.minute # CurrTime.minute ) THEN
          GetTime( ThisTime );
          GetTime( CurrTime );
          WriteParams( 255, 255, 255, ThisTime, NoRT );
      END (* IF *);

  UNTIL Key = ASCII.esc;

END ModemLoop;


TYPE
  Rect = ARRAY [ 0..3 ] OF CARDINAL;

VAR

  Key    : CHAR;
  OptFile  :  File;

BEGIN
  GetDir( 0, MainDir );
  Concat( MainDir, '\', MainDir );

  InitEGA;
  GraphMode;
  SetFont(14);
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
  Ellipse(320,175,256,187,0,FALSE);
  IOcheck := FALSE;
  OptFile := Open( 'E300PC.DAT' );
  IF OptFile < MAX( CARDINAL ) THEN
      Key := CHAR( RdBin( OptFile, Options, SIZE( Options ) ) );
      Close( OptFile );
  ELSE
      Options.Baud := 9600;
      Options.ComPort := 1;
      Options.Update := 0;
      Options.ArmyTime := FALSE;
      Options.Maps := TRUE;
  END (* IF *);
  ArmyTime := Options.ArmyTime;
  rs.Install( Options.ComPort );
  rs.Init( Options.Baud, 8, rs.None, TRUE, FALSE );
(*  rs.Send( 'AT E0 V0 ', 9 );
  rs.Send( ASCII.cr, 1 );
  rs.Send( ASCII.lf, 1 ); *)

  GetTime(CurrentTime);
  WriteParams( 255, 255, 255, CurrentTime, NoRT );

(* Other initialization *)

  SetPlane( {2} );
  Polygon( 4, Rect(160,160,496,496), Rect(210,322,322,210), 4 );
  SetWindow( 160, 210, 343, 112 );
  SetFunc( or, 0 );
  SetPlane( {3} );
  GotoXY( 0, 0 );
  WrStr( 'ษออออออออออออออออออออออออออออออออออออออออป' );
  WrStr( 'บ  ELLASON E300 RADAR TERMINAL, ver 3.1  บ' );
  WrStr( 'บ      WLLX RADIO, Lawrenceburg TN       บ' );
  WrStr( 'บ           Revision 11/30/92            บ' );
  WrStr( 'บ        Copyright (C) 1987,88,92        บ' );
  WrStr( 'บ               D. G. Lane               บ' );
  WrStr( 'บ Modified for SCA Data Transmission %%% บ' );
  WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );

  InitStationDir( FirstStation, NumofStations );

  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);

(*  Message( ' Press any key ' );
  Key := RdKey();
  Message( '' ); *)

  SetWindow( 0, 0, 639, 349 );
  SetFunc( clr, 0 );
  SetPlane( {2,3} );
  Polygon( 4, Rect(160,160,496,496), Rect(210,322,322,210), 0 );

(*  IF NumofStations = 1 THEN *)

      SelectStation( FirstStation^ );
      CurrentStation := FirstStation;

(*  ELSE

      StationMenu( FirstStation, NumofStations, CurrentStation );

  END (* IF *); *)

  Interval := Options.Update;
  GetTime( NextUpdate );

  DB.InstallTx; (* Install SCA transmitter *)

  ModemLoop;

(*  DeInit; *)

  TextMode;

  ChDir( MainDir );

END Main.
