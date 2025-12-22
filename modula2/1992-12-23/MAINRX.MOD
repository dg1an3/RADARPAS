MODULE MainRx;

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
IMPORT Lib;

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
  WritePic, Redraw, DrawScale, FullPic;

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
     Options  :  RECORD
         Baud     :  CARDINAL;
         ComPort  :  CARDINAL;
         Update   :  CARDINAL;
         ArmyTime :  BOOLEAN;
         Maps     :  BOOLEAN;
         Banner   :  ARRAY [ 0..40 ] OF CHAR;
     END (* RECORD *);

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
        WrStr( ' B ๚ Baud rate       : ' );
        WrCard( Options.Baud, 5 ); WrLn;
        WrStr( ' P ๚ Com Port        : COM' );
        WrCard( Options.ComPort, 1 ); WrLn;
        IF Options.ArmyTime THEN
            WrStr( ' C ๚ Clock format    : 24 hour' ); WrLn;
        ELSE
            WrStr( ' C ๚ Clock format    : 12 hour' ); WrLn;
        END (* IF *);
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
            "C" : Options.ArmyTime := ~ Options.ArmyTime |
        END (* CASE *);
    UNTIL Key = ASCII.esc;

    Concat( OptName, MainDir, '\E300DB.DAT' );
    OptFile := Open( OptName );
    IF OptFile = MAX( CARDINAL ) THEN
        OptFile := Create( OptName );
    END (* IF *);
    WrBin( OptFile, Options, SIZE( Options ) );
    Close( OptFile );

    ArmyTime := Options.ArmyTime;
(*    rs.Install( Options.ComPort ); *)
    rs.Init( Options.Baud, 8, rs.None, TRUE, FALSE );

    SetPlane( {2,3} );
    SetFunc( clr, 0 );
    FillArea( 184, 28, 264, 294, 0 );
    SetWindow( 0, 0, 639, 349 );
    Redraw;

END OptionMenu;


VAR
    FileID  :  ARRAY [ 0..9 ] OF BYTE;

PROCEDURE ModemLoop;

VAR

  CurrTime : Time;
       Key : CHAR;
    Escape : BOOLEAN;
    PicFileName : ARRAY [ 0..11 ] OF CHAR;
    FileID : ARRAY [ 0..9 ] OF BYTE;
    NewPicture : PictureRec;
    PermSize, SizeTime : CARDINAL;

BEGIN
  Mode := Modem;
  SetFunc( clr, 0 );
  SetPlane( {0} );
  GotoXY( 560, 294 );
  WrStr( 'NO SIGNAL' );

  SetHelpMode( 1 );

  DrawCursor;
  WriteRangeBear( CX, CY );
  REPEAT

      IF KeyPressed() THEN

          DrawCursor;
          ExtRead( Key, Escape );

          IF ~ Escape THEN

              CASE Key OF

            '+' : IF Mode # RxPic THEN WITH CurrentStation^ DO

                      IF CurrentPicture < NumofPictures THEN

                          IF ( CurrentPicture > 0 ) THEN
                              DEALLOCATE( Picture[CurrentPicture].Data,
                                  Picture[CurrentPicture].Size );
                              Picture[CurrentPicture].Data := NIL;
                          END (* IF *);
                          INC( CurrentPicture );
                          SelectPicture( Picture[CurrentPicture] );
                          IF ( ( MapOn[ 1 ] ) OR ( MapOn[ 2 ] ) ) &
                              ( Picture[ CurrentPicture-1 ].Range #
                              Picture[ CurrentPicture ].Range ) THEN
                              SetPlane( {2,3} );
                              ClearScreen;
                              Redraw;
                          END (* IF *);

                      END (* IF *);

                  END (* WITH *); END |

            '-' : IF Mode # RxPic THEN WITH CurrentStation^ DO

                      IF CurrentPicture > 1 THEN

                          DEALLOCATE( Picture[CurrentPicture].Data,
                              Picture[CurrentPicture].Size );
                          Picture[CurrentPicture].Data := NIL;
                          DEC( CurrentPicture );
                          SelectPicture( Picture[CurrentPicture] );
                          IF ( ( MapOn[ 1 ] ) OR ( MapOn[ 2 ] ) ) &
                              ( Picture[ CurrentPicture+1 ].Range #
                              Picture[ CurrentPicture ].Range ) THEN
                              SetPlane( {2,3} );
                              ClearScreen;
                              Redraw;
                          END (* IF *);

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

                  END (* WITH *); END |

              ELSE

                  ExecCom( Key );

              END;

          ELSE

              CASE Key OF

             F1 : IF CurrentStation # NIL THEN
                      PictureMenu( CurrentStation^.Picture,
                          CurrentStation^.NumofPictures,
                          CurrentStation^.CurrentPicture );
                  END (* IF *) |

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

           030C : OptionMenu (* Alt-O *)

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

      IF DB.NewFile THEN (* New data *)
          DrawCursor;
          Mode := RxPic;
          SetFunc( clr, 0 );
          SetPlane( {0} );
          GotoXY( 560, 294 );
          WrStr( '         ' );
          SetPlane( {3} );
          GotoXY( 584, 294 );
          WrStr( 'SIGNAL' );

          Process.Lock;
          DB.NewFile := FALSE;
          IF ( DB.At > 9 ) & ( Lib.Compare( ADR( DB.Buffer ),
              ADR( FileID ), 9 ) = 9 ) THEN (* NOT new file *)
              NewPicture.Size := DB.Size-9;
              Move( ADR(DB.Buffer[ 9 ]), NewPicture.Data, DB.Size-9 );
              Process.Unlock;
              WritePic( NewPicture.Data^, NewPicture.Size );
              IF FullPic THEN
                  Message( ' Saving picture... ' );
                  NewPicture.Size := DB.Size;
                  SavePicture( NewPicture, Escape );
                  AddPicture( CurrentStation^.Picture,
                      CurrentStation^.NumofPictures, NewPicture,
                      CurrentStation^.CurrentPicture );
                  INC( CurrentStation^.CurrentPicture );
                  NewPicture.Size := 54000;
                  DEALLOCATE( NewPicture.Data, 54000 );
                  NewPicture.Data := NIL;
                  Message( '' );
                  Mode := Interactive;
              END (* IF *);
          ELSIF DB.At > 9 THEN (* New file *)
              Move( ADR( DB.Buffer ), ADR( FileID ), 9 );
              Process.Unlock;
              Move( ADR( FileID ), ADR( NewPicture.TimeofPic), 6 );
              NewPicture.Range := RangeType( FileID[ 6 ] );
              NewPicture.Gain := GainType( FileID[ 7 ] );
              NewPicture.Tilt := TiltType( FileID[ 8 ] );
              WriteParams( NewPicture.Tilt, NewPicture.Range, NewPicture.Gain,
                           NewPicture.TimeofPic, RTState( 0 ) );

              SetPlane( {0,1} );
              SetFunc( clr, 0 );
              ClearScreen;
              SetPlane( {0,1} );
              SetFunc( or, 0 );
              DrawScale;
              Message( ' Receiving new picture... ' );
              Mode := RxPic;
              PermSize := 0;
              ALLOCATE( NewPicture.Data, 54000 );
              Process.Lock;
              NewPicture.Size := DB.Size-9;
              Move( ADR(DB.Buffer[ 9 ]), NewPicture.Data, DB.Size-9 );
              Process.Unlock;
              WritePic( NewPicture.Data^, NewPicture.Size );

          ELSE
              Process.Unlock;
          END (* IF *);
          DrawCursor;
          WriteRangeBear( CX, CY );
      ELSIF ~ DB.Signal THEN
          IF Mode # Modem THEN
              Mode := Modem;
              SetFunc( clr, 0 );
              SetPlane( {3} );
              GotoXY( 584, 294 );
              WrStr( '      ' );
              SetPlane( {0} );
              GotoXY( 560, 294 );
              WrStr( 'NO SIGNAL' );
          END (* IF *)
      END (* IF *);

      WHILE ( CurrentStation^.NumofPictures >= 99 ) DO
          (* See if oldest needs to be deleted *)
          DeletePicture( CurrentStation^.Picture,
                         CurrentStation^.NumofPictures,
                         CurrentStation^.NumofPictures );
      END (* WHILE *);

  UNTIL Key = ASCII.esc;

END ModemLoop;


TYPE
  Rect = ARRAY [ 0..3 ] OF CARDINAL;

VAR

  Key    : CHAR;
  OptFile : File;

BEGIN
  GetDir( 0, MainDir );
  Concat( MainDir, '\', MainDir );

  InitEGA;
  GraphMode;
  SetFont(14);
  SetPalette(PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
  Ellipse(320,175,256,187,0,FALSE);
  IOcheck := FALSE;
  OptFile := Open( 'E300DB.DAT' );
  IF OptFile < MAX( CARDINAL ) THEN
      Key := CHAR( RdBin( OptFile, Options, SIZE( Options ) ) );
      Close( OptFile );
  ELSE
      Key := Pause( ' E300DB.DAT--File not found ' );
      HALT;
(*      Options.Baud := 9600;
      Options.ComPort := 1;
      Options.ArmyTime := FALSE;
      Options.Banner := '      Murray Ohio, Lawrenceburg TN    ' *)
  END (* IF *);
  ArmyTime := Options.ArmyTime;
  rs.Install( Options.ComPort );
  rs.Init( Options.Baud, 8, rs.None, TRUE, FALSE );
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
  WrStr( 'บ        E300SCA TERMINAL, ver 1.0       บ' );
  WrStr( 'บ' );
  WrStr( Options.Banner );
  WrStr( 'บ' );
  WrStr( 'บ           Revision 11/30/92            บ' );
  WrStr( 'บ           Copyright (C) 1992           บ' );
  WrStr( 'บ               D. G. Lane               บ' );
  WrStr( 'บ           All rights reserved          บ' );
  WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' );

  InitStationDir( FirstStation, NumofStations );

  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);
  IF ~ KeyPressed() THEN Delay( 1000 ) END (* WHILE *);

  SetWindow( 0, 0, 639, 349 );
  SetFunc( clr, 0 );
  SetPlane( {2,3} );
  Polygon( 4, Rect(160,160,496,496), Rect(210,322,322,210), 0 );

  SelectStation( FirstStation^ );
  CurrentStation := FirstStation;

  DB.InstallRx; (* Install SCA receiver *)

  ModemLoop;

(*  DeInit; *)

  TextMode;

  ChDir( MainDir );

END MainRx.
