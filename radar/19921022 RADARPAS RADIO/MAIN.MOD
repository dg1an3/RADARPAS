MODULE Main;

IMPORT ASCII;

(*
FROM Auto IMPORT
  ProgramMenu, DoAuto;
*)

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
  AddAddr, Sound, Delay, NoSound, Dos, Fill;

FROM Locator IMPORT
  CX, CY, CursorOn, DrawCursor, WriteRangeBear;

(*
FROM MemCompress IMPORT
  Compress;
*)

FROM Modem IMPORT
  ResultCode, Call;

FROM Pictures IMPORT
  PicFlag, PicFlagSet, PictureRec, FileParam, SavePicture,
  ReserveMem, SelectPicture, AddPicture, DeletePicture,
  PictureMenu, FileName;

(* FROM RadarTx IMPORT
  TransmitPic; *)

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


PROCEDURE ExecCom( Key : CHAR );

BEGIN

  CASE CAP(Key) OF (* Process regular key codes *)

 'G': ToggleGraphics |

 'R': WriteRngMks( ~ RngMksOn ) |

 'H': WriteHelp( ~ HelpOn ) |

 'L': CursorOn := ~ CursorOn |

 '1': WriteMap( 1, ~ MapOn[1] ) |

 '2': WriteMap( 2, ~ MapOn[2] ) |

  END (* CASE *);

END ExecCom;


VAR
    NextUpdate  :  Time;
    Interval  :  CARDINAL;

PROCEDURE DoAuto;

VAR
  NewPicture  :  PictureRec;
  Key         :  CHAR;
  Escape      :  BOOLEAN;
  Tilt  :  TiltType;
  Range :  RangeType;
  Gain  :  GainType;
  RT    : RTState;
  CurrTime : Time;
  AbortPending : BOOLEAN;
        Number : CARDINAL;
            At : CARDINAL;
     ComprSize : CARDINAL;
       ComprAt : ADDRESS;
    PictureNum : CARDINAL;
        Length : CARDINAL;
      Red, Grn : ARRAY [ 0..159 ] OF BYTE;


BEGIN
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

            Message( ' No Response. ' );
            RETURN;

        ELSE

            WriteParams( Tilt, Range, Gain, TimeofPic, RT );

        END (* IF *);

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
    WHILE ( Number <= 476 ) & ( Key # ASCII.esc ) DO

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
        END (* IF *);

    END (* WHILE *);

    NewPicture.Size := At;
    SavePicture( NewPicture, Escape );
    AddPicture( CurrentStation^.Picture,
        CurrentStation^.NumofPictures, NewPicture,
        CurrentStation^.CurrentPicture );
    INC( CurrentStation^.CurrentPicture );
    NewPicture.Size := 54000;

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

          Message( ' No Response. ' );
          RETURN;

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

      ExtRead( Key, Escape );

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
              WHILE ( Number <= 476 ) & ( Key # ASCII.esc ) DO

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
                  END (* IF *);

              END (* WHILE *);

              NewPicture.Size := At;
              SavePicture( NewPicture, Escape );
              AddPicture( CurrentStation^.Picture,
                  CurrentStation^.NumofPictures, NewPicture,
                  CurrentStation^.CurrentPicture );
              INC( CurrentStation^.CurrentPicture );
              NewPicture.Size := 54000;

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
BEGIN
END AutoMenu;

PROCEDURE ModemLoop;

VAR

  CurrTime : Time;
       Key : CHAR;
    Escape : BOOLEAN;
    PicFileName : ARRAY [ 0..11 ] OF CHAR;

BEGIN

  SetHelpMode( 1 );

  DrawCursor;
  WriteRangeBear( CX, CY );
  REPEAT

      IF KeyPressed() THEN

          DrawCursor;
          ExtRead( Key, Escape );

          IF ~ Escape THEN

              CASE Key OF

            '+' : WITH CurrentStation^ DO

                      IF CurrentPicture < NumofPictures THEN

                          INC( CurrentPicture );
                          SelectPicture( Picture[CurrentPicture] );

                      END (* IF *);

                  END (* WITH *); |

            '-' : WITH CurrentStation^ DO

                      IF CurrentPicture > 1 THEN

                          DEC( CurrentPicture );
                          SelectPicture( Picture[CurrentPicture] );

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

(*             F4 : ProgramMenu | *)
               F4 : AutoMenu |

(*             F5 : WITH CurrentStation^ DO
                      WITH Picture[CurrentPicture] DO
                          FileName( Picture[CurrentPicture], PicFileName );
                          IF Data # NIL THEN
                              TransmitPic( PicFileName, Data^, Size );
                          END (* IF *);
                      END (* WITH *);
                  END (* WITH *) | *)


           larr : IF CX > 0 THEN
                      DEC( CX, 2 );
                  END (* IF *) |

           rarr : IF CX < 639 THEN
                      INC( CX, 2 );
                  END (* IF *) |

           uarr : IF CY > 0 THEN
                      DEC( CY, 2 );
                  END (* IF *) |

           darr : IF CY < 349 THEN
                      INC( CY, 2 );
                  END (* IF *) |

(*           030C : ConFig (* Alt-O *) *)

              END (* CASE *)

          END (* IF *);

          IF Key = ASCII.esc THEN

              IF CAP(Pause( ' Exit program ( Y/N ) ? ' )) # 'Y' THEN

                  Key := ASCII.nul;

              END (* IF *);

          END (* IF *);
          DrawCursor;
          WriteRangeBear( CX, CY );

      END (* IF *);

      DoAuto;

  UNTIL Key = ASCII.esc;

END ModemLoop;


TYPE
  Rect = ARRAY [ 0..3 ] OF CARDINAL;

VAR

  Key    : CHAR;

BEGIN
  GetDir( 0, MainDir );
  Concat( MainDir, '\', MainDir );

  rs.Install( 1 );
  rs.Init( 9600, 8, rs.None, TRUE, FALSE );
  rs.Send( 'AT E0 V0 ', 9 );
  rs.Send( ASCII.cr, 1 );
  rs.Send( ASCII.lf, 1 );
  InitEGA;
  GraphMode;
  SetFont(14);
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
  Ellipse(320,175,256,187,0,FALSE);
  IOcheck := FALSE;
  ArmyTime := FALSE;
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
  WrStr( 'บ           Revision 10/12/92            บ' );
  WrStr( 'บ        Copyright (C) 1987,88,92        บ' );
  WrStr( 'บ               D. G. Lane               บ' );
  WrStr( 'บ           All rights reserved          บ' );
  WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );

  InitStationDir( FirstStation, NumofStations );

  Delay( 5000 );
(*  Message( ' Press any key ' );
  Key := RdKey();
  Message( '' ); *)

  SetWindow( 0, 0, 639, 349 );
  SetFunc( clr, 0 );
  SetPlane( {2,3} );
  Polygon( 4, Rect(160,160,496,496), Rect(210,322,322,210), 0 );

  IF NumofStations = 1 THEN

      SelectStation( FirstStation^ );
      CurrentStation := FirstStation;

  ELSE

      StationMenu( FirstStation, NumofStations, CurrentStation );

  END (* IF *);

  Interval := 15;
  GetTime( NextUpdate );

  ModemLoop;

(*  DeInit; *)

  TextMode;

  ChDir( MainDir );

END Main.
