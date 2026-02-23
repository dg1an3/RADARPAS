MODULE Main;

IMPORT ASCII;

FROM Auto IMPORT
  ProgramMenu, DoAuto, UpdateTimes;

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

FROM MemCompress IMPORT
  Compress;

FROM Modem IMPORT
  ResultCode, Call, HangUp;

FROM Options IMPORT
  OptionMenu, ModemPort, ModemBaud, ClockType, OptFileName,
  LoadOptions, Programs;

FROM PicAnal IMPORT
  Analyze;

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
  FirstStation, CurrentStation, NumofStations, StationPtr,
  StationRec, CallStation, SelectStation, AddStation,
  DelStation, StationMenu, InitStationDir;

FROM Storage IMPORT
  ALLOCATE, DEALLOCATE, Available;

FROM Str IMPORT
  Slice, Copy, Concat, Pos, StrToCard, CardToStr, Length,
  Compare;

FROM SYSTEM IMPORT
  BYTE, ADR, ADDRESS, Registers;

FROM TimeDate IMPORT
  GetTime, Time;


TYPE

  ModeType = ( Modem, Interactive, RxPic, RxMap );


VAR

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



PROCEDURE InterLoop;

VAR

    NewPicture : PictureRec;
       Map1Len,
       Map2Len : CARDINAL;
       MapFile : File;
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
        Result : ResultCode;

BEGIN

  SetPlane( {0,1} );
  ClearScreen;

  IF ~ CallStation( CurrentStation^ ) THEN

      RETURN;

  END (* IF *);

  Message( '' );
  WriteHelp( FALSE );
  SetHelpMode( 2 );
  WriteHelp( ~ HelpOn );
  Delay( 2000 );

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
  Mode := Interactive;

  IF ~ CheckMaps( ScrnMap[1] ) THEN

      Message( ' One moment, please.  Receiving new maps... ' );
      Mode := RxMap;
      GetMaps( ScrnMap[1], ScrnMap[2], Map1Len, Map2Len );
      Mode := Interactive;

      MapFile := Create( 'MAP1.DAT' );
      WrBin( MapFile, ScrnMap[1], Map1Len * SIZE(ScrnMap[1][0]) );
      Close( MapFile );

      MapFile := Create( 'MAP2.DAT' );
      WrBin( MapFile, ScrnMap[2], Map2Len * SIZE(ScrnMap[2][0]) );
      Close( MapFile );

      Message( '' );

  END (* IF *);

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
              Mode := RxPic;
              DrawScale;
              ALLOCATE( NewPicture.Data, 54000 );
              NewPicture.Size := 54000;
              AbortPending := FALSE;
              Key := ASCII.nul;

              REPEAT

                  IF KeyPressed() THEN
                      ExtRead( Key, Escape );
                      IF ( Key = ASCII.esc ) & ~ AbortPending THEN

                          Message( ' Abort Picture ( Y/N ) ? ' );
                          AbortPending := TRUE;
                          Key := ASCII.nul;

                      ELSIF ( CAP(Key) = 'Y' ) & AbortPending THEN

                          Message( ' Picture Aborted. ' );
                          AbortPic;
                          Key := ASCII.esc;

                      ELSE

                          Message( ' Waiting for picture... ' );
                          AbortPending := FALSE;

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
                      IF ( Key = ASCII.esc ) & ~ AbortPending THEN

                          Message( ' Abort Picture ( Y/N ) ? ' );
                          AbortPending := TRUE;
                          Key := ASCII.nul;

                      ELSIF ( CAP(Key) = 'Y' ) & AbortPending THEN

                          Message( ' Picture Aborted. ' );
                          AbortPic;
                          Key := ASCII.esc;

                      ELSE

                          ExecCom( Key );
                          Message( ' Receiving Picture, ESC to abort... ' );
                          AbortPending := FALSE;

                      END (* IF *);

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
              HangUp( Result );
              Mode := Modem;
              Key := ASCII.nul;

          END (* CASE *);

      END (* IF *);

      IF Key = ASCII.esc THEN

          Message( ' Disconnect Station ( Y/N ) ? ' );
          ExtRead( Key, Escape );
          Message( '' );
          IF CAP(Key) = 'Y' THEN

              HangUp( Result );
              Mode := Modem;

          END (* IF *);

      END (* IF *);

  UNTIL Mode = Modem;

  Key := ASCII.nul;

  SetPlane( {3} );
  SetFunc( clr, 0 );
  GotoXY( 576, 294 );
  WrStr( '       ' );

  Mode := Modem;
  WriteHelp( FALSE );
  SetHelpMode( 1 );
  WriteHelp( ~ HelpOn );

END InterLoop;


PROCEDURE ModemLoop;

VAR

  CurrTime : Time;
       Key : CHAR;
    Escape : BOOLEAN;
    PicFileName : ARRAY [ 0..11 ] OF CHAR;
    Horiz, Vertic : INTEGER;

BEGIN

  SetHelpMode( 1 );
  WriteHelp( ~ HelpOn );

  DrawCursor;
  WriteRangeBear( CX, CY );
  Key := 'D';
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

             F4 : ProgramMenu( CurrentStation ) |

(*             F5 : WITH CurrentStation^ DO
                      WITH Picture[CurrentPicture] DO
                          FileName( Picture[CurrentPicture], PicFileName );
                          IF Data # NIL THEN
                              TransmitPic( PicFileName, Data^, Size );
                              Message( ' Transmitting picture... ' );
                          END (* IF *);
                      END (* WITH *);
                  END (* WITH *) | *)

             F6 : Analyze |

           larr : IF CX > 0 THEN
                      DEC( CX );
                  END (* IF *) |

           rarr : IF CX < 639 THEN
                      INC( CX );
                  END (* IF *) |

           uarr : IF CY > 0 THEN
                      DEC( CY );
                  END (* IF *) |

           darr : IF CY < 349 THEN
                      INC( CY );
                  END (* IF *) |

           030C : OptionMenu (* Alt-O *)

              END (* CASE *)

          END (* IF *);

          IF Key = ASCII.esc THEN

              IF CAP(Pause( ' Exit program ( Y/N ) ? ' )) = 'Y' THEN

                  Key := ASCII.nul;

              END (* IF *);

          END (* IF *);
          DrawCursor;
          WriteRangeBear( CX, CY );

      END (* IF *);

      DoAuto( CurrentStation );

  UNTIL Key = ASCII.nul;

END ModemLoop;


TYPE
  Rect = ARRAY [ 0..3 ] OF CARDINAL;

VAR

  Key    : CHAR;

BEGIN
  GetDir( 0, MainDir );
  Concat( MainDir, '\', MainDir );

  IF Length(MainDir) > 1 THEN
      Copy( OptFileName, MainDir );
      Concat( OptFileName, OptFileName, '\OPTIONS.DAT' );
  ELSE
      Copy( OptFileName, '\OPTIONS.DAT' );
  END (* IF *);

  IOcheck := FALSE;
  LoadOptions;
  UpdateTimes( Programs );

  rs.Install( ModemPort );
  rs.Init( ModemBaud, 8, rs.None, TRUE, FALSE );
  rs.Send( 'AT E0 V0 ', 9 );
  rs.Send( ASCII.cr, 1 );
  rs.Send( ASCII.lf, 1 );
  InitEGA;
  GraphMode;
  SetFont(14);
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
  Ellipse(320,175,256,187,0,FALSE);
  ArmyTime := ( ClockType = 2 );
  GetTime(CurrentTime);
  WriteParams( 255, 255, 255, CurrentTime, NoRT );

(* Other initialization *)

  SetPlane( {2} );
  Polygon( 4, Rect(160,160,496,496), Rect(210,308,308,210), 4 );
  SetWindow( 160, 210, 343, 98 );
  SetFunc( or, 0 );
  SetPlane( {3} );
  GotoXY( 0, 0 );
  WrStr( 'ษออออออออออออออออออออออออออออออออออออออออป' );
  WrStr( 'บ  ELLASON E300 RADAR TERMINAL, ver 3.0  บ' );
  WrStr( 'บ            Revision 12/28/88           บ' );
  WrStr( 'บ          Copyright (C) 1987,88         บ' );
  WrStr( 'บ               D. G. Lane               บ' );
  WrStr( 'บ           All rights reserved          บ' );
  WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );

  InitStationDir( FirstStation, NumofStations );

  Message( ' Press any key ' );
  Key := RdKey();
  Message( '' );

  SetWindow( 0, 0, 639, 349 );
  SetFunc( clr, 0 );
  Polygon( 4, Rect(160,160,496,496), Rect(210,308,308,210), 0 );

  IF NumofStations = 1 THEN

      SelectStation( FirstStation^ );
      CurrentStation := FirstStation;

  ELSE

      StationMenu( FirstStation, NumofStations, CurrentStation );

  END (* IF *);

  ModemLoop;

(*  DeInit; *)

  TextMode;

  ChDir( MainDir );

END Main.
