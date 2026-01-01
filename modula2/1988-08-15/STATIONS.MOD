IMPLEMENTATION MODULE Stations;

IMPORT ASCII;

FROM E300Interface IMPORT
    RTState;

IMPORT ExtendKey;

FROM FIO IMPORT
    File, Open, Close, Create, WrBin, RdBin, Erase,
    ChDir, MkDir, RmDir, DirEntry, ReadFirstEntry,
    ReadNextEntry, FileAttr, directory, IOresult;

IMPORT FIO;

FROM Graphics IMPORT
    SetPlane, SetFunc, or, clr, SetWindow, GotoXY,
    FillArea;

FROM IO IMPORT
    WrStr, WrStrAdj, WrCard, WrChar, WrLngCard, WrLn,
    KeyPressed, RdKey;

FROM Lib IMPORT
    Dos, Fill;

FROM Modem IMPORT
    Call, ResultCode;

FROM Pictures IMPORT
    FileParam, AddPicture;

FROM ScreenHandler IMPORT
    WriteDate, WriteTime, WriteTilt, WriteRange,
    WriteGain, WriteParams, Redraw, WritePic, Pause,
    Message, ScrnMap, Prompt, ClearScreen;

FROM Selector IMPORT
    Select;

FROM Storage IMPORT
    Available, ALLOCATE, DEALLOCATE;

FROM Str IMPORT
    CardToStr, Concat, Length, Slice, StrToCard, Compare,
    Pos, Copy;

FROM SYSTEM IMPORT
    Registers;

FROM TimeDate IMPORT
    Time, GetTime;


VAR

(*    StationList,
  CurrentStation : StationPtr;
   NumofStations : CARDINAL; *)


PROCEDURE CallStation( VAR ForStation : StationRec ) : BOOLEAN;

VAR

  DialMess : ARRAY [ 0..63 ] OF CHAR;
    Result : ResultCode;
       Key : CHAR;

BEGIN

  IF Compare( ForStation.Phone, '--' ) # 0 THEN

      Key := 000C;
      REPEAT

          DialMess := ' Dialing ';
          Concat( DialMess, DialMess, ForStation.Phone );
          Concat( DialMess, DialMess, ', ESC to abort... ' );
          Message( DialMess );
          Call( ForStation.Phone, Result );

          IF ( CAP(Key) # 'Y' ) THEN

              CASE Result OF

     Connect2400,
     Connect1200,
     Connect300 : Message( ' Connected. ' );
                  RETURN( TRUE ); |

      NoCarrier : Key := Pause( ' No carrier. Repeat ( Y/N ) ? ' ) |

     ModemError : Key := Pause( ' Modem error. Repeat ( Y/N ) ? ' ) |

     NoDialtone : Key := Pause( ' No dial-tone. Repeat ( Y/N ) ? ' ) |

           Busy : Key := Pause( ' Busy. Repeat ( Y/N ) ? ' ) |

       NoAnswer : Key := Pause( ' No answer. Repeat ( Y/N ) ? ' ) |

     NoResponse : Key := Pause( ' Modem not responding. Repeat ( Y/N ) ? ' ) |

             Ok : Key := Pause( ' Invalid number. Repeat ( Y/N ) ? ');

              ELSE

                  Key := Pause( ' Unknown Error. Repeat ( Y/N ) ? ' );

              END (* CASE *);

          ELSE

              IF Result = Connect2400 THEN RETURN( TRUE ) END;

          END (* IF *);

          IF KeyPressed() THEN

              Key := RdKey();

          END (* IF *);

      UNTIL ( CAP(Key) # 'Y' ) OR ( Key = ASCII.esc );

      RETURN( FALSE );

  ELSE

      RETURN( TRUE );

  END (* IF *);

END CallStation;



PROCEDURE SelectStation( VAR ForStation : StationRec );

(* Changes the current directory to the station's directory.  Loads the
   map files *)

VAR

  ShortName : ARRAY[0..7] OF CHAR;
  OK        : BOOLEAN;
  MapFile   : File;
  Count     : CARDINAL;
  Key       : CHAR;

BEGIN

  WITH ForStation DO

      (* Change to station directory *)
      ChDir( StationName );
      IF IOresult() = 0 THEN

          (* Read Map 1. *)
          Fill( ADR(ScrnMap[1]), SIZE(ScrnMap[1]), 0 );

          MapFile := Open( 'MAP1.DAT' );
          IF MapFile < MAX(CARDINAL) THEN

              Count := RdBin( MapFile, ScrnMap[1], MAX(CARDINAL) );
              Close( MapFile );

          END (* IF *);

          (* Read Map 2. *)
          Fill( ADR(ScrnMap[2]), SIZE(ScrnMap[2]), 0 );

          MapFile := Open( 'MAP2.DAT' );
          IF MapFile < MAX(CARDINAL) THEN

              Count := RdBin( MapFile, ScrnMap[2], MAX(CARDINAL) );
              Close( MapFile );

          END (* IF *);

          (* Write current station in lower right-hand corner of screen *)
          Slice( ShortName, StationName, 0, Pos(StationName,'.') );
          SetPlane( {2} );
          GotoXY( 568, 308 );
          WrStrAdj( ShortName, 8 );

          (* Reset Current Picture *)
          CurrentPicture := 0;

      END (* IF *);

  END (* WITH *);

END SelectStation;



PROCEDURE AddStation(   VAR StationList : StationPtr;
                      VAR NumofStations : CARDINAL );

VAR

  NewStation : StationPtr;
   PhoneFile : File;

BEGIN

  IF StationList = NIL THEN

      NEW( NewStation );
      StationList := NewStation;

  ELSE

      NewStation := StationList;

      WHILE NewStation^.Next # NIL DO

          NewStation := NewStation^.Next;

      END (* WHILE *);

      NEW( NewStation^.Next );
      NewStation := NewStation^.Next;

  END (* IF *);

  INC( NumofStations );

  WITH NewStation^ DO

      StationNumber := NumofStations;

      Prompt( 'Station name - ', StationName );
      Prompt( 'Phone number - ', Phone );

      IF Pos( StationName, '.' ) < MAX( CARDINAL ) THEN

          Slice( StationName, StationName, 1, Pos( StationName, '.' ) );

      END (* IF *);

      Concat( StationName, StationName, '.STA' );

      MkDir( StationName );

      ChDir( StationName );
      IF IOresult() = 0 THEN

          PhoneFile := Create( 'PHONENUM.TXT' );
          FIO.WrStr( PhoneFile, Phone );
          Close( PhoneFile );

          ChDir( '..' );

      END (* IF *);

  END (* WITH *);

END AddStation;



PROCEDURE DelStation(   VAR StationList : StationPtr;
                             StationNum : CARDINAL;
                      VAR NumofStations : CARDINAL );
VAR
         Entry : DirEntry;
         Count : CARDINAL;
    OldStation,
       TempPtr : StationPtr;

BEGIN
  IF CAP(Pause( 'Delete this station?' )) = 'Y' THEN

      WITH OldStation^ DO

          ChDir( StationName );
          IF IOresult() = 0 THEN

              IF ReadFirstEntry( '????????.???', FileAttr{}, Entry ) THEN

                  Erase( Entry.Name );

                  WHILE ReadNextEntry( Entry ) DO

                      Erase( Entry.Name );

                  END (* WHILE *);

              END (* IF *);
              ChDir( '..' );

          END (* IF *);

          RmDir( StationName );
          TempPtr := StationList;
          FOR Count := 0 TO StationNum-1 DO
              TempPtr := TempPtr^.Next;
          END (* FOR *);
          OldStation := TempPtr^.Next;

          WITH OldStation^ DO

              FOR Count := 0 TO NumofPictures DO
                  IF Picture[Count].Data = NIL THEN
                      DEALLOCATE( Picture[Count].Data,
                          Picture[Count].Size );
                  END (* IF *);
              END (* FOR *);
              TempPtr^.Next := Next;

          END (* WITH *);

          DISPOSE( OldStation );

      END (* WITH *);

      DEC( NumofStations );

  END (* IF *);

END DelStation;



VAR

    FirstStation : StationPtr;
  CurrentStation : StationPtr;


PROCEDURE WriteStationEntry( StationNum : CARDINAL );

VAR

  StationCount : CARDINAL;
     AtStation : StationPtr;
     ShortName : ARRAY [ 0..15 ] OF CHAR;

BEGIN

  AtStation := FirstStation;
  StationCount := 1;

  WHILE ( AtStation # NIL ) & ( StationCount < StationNum ) DO

      AtStation := AtStation^.Next;
      StationCount := StationCount + 1;

  END (* WHILE *);

  IF AtStation # NIL THEN

      WITH AtStation^ DO

          Slice( ShortName, StationName, 0, Pos(StationName,'.') );
          Concat( ShortName, ShortName, '        ' );
          ShortName[9] := 000C;
          WrStr( ShortName );
          Slice( ShortName, Phone, 0, 15 );
          WrStr( ShortName );

      END (* WITH  *);

  END (* IF *);

END WriteStationEntry;



PROCEDURE StationMenu(   VAR StationList : StationPtr;
                       VAR NumofStations : CARDINAL;
                      VAR CurrentStation : StationPtr );

(* Menu-driven station management.  Calls SelectStation *)

VAR

  AtStation     : StationPtr;
  StationCount,
  StationSelect : CARDINAL;
  Key           : CHAR;
  Escape        : BOOLEAN;

BEGIN

  (* Draw the window *)
  SetPlane( {2} );
  SetFunc( or, 0 );
  FillArea( 216, 28, 208, 228, CARDINAL(0FFFFH) );
  SetPlane( {3} );
  SetWindow( 216, 28, 208, 224 );

  GotoXY( 0, 0 );
  WrStr( 'ÍÍÍÍÍÍÍÍ STATIONS ÍÍÍÍÍÍÍÍ' );
  WrStr( 'NAME     PHONE            ' );
  GotoXY( 0, 182 );
  WrStr( 'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ' );
  WrStr( '   ENTERúSelect Station   ' );
  WrStr( '    F1úAdd   F2úDelete    ' );

  FirstStation := StationList;
  LOOP

      SetWindow( 216, 56, 208, 140);
      SetPlane( {3} );
      SetFunc( clr, 0 );
      GotoXY( 8, 140 );
      IF NumofStations = 0 THEN

          WrStr( 'No Stations. ' );

      ELSIF NumofStations = 1 THEN

          WrStr( '1 Station. ' );

      ELSE

          WrCard( NumofStations,1 );
          WrStr( ' Stations. ' );

      END (* IF *);

      StationSelect := 0;
      Select( 216, 56, 424, 196, WriteStationEntry,
          NumofStations, StationSelect, Key, Escape );

      IF Escape & ( Key = ExtendKey.F1 ) THEN

          AddStation( StationList, NumofStations );

      ELSIF Escape & ( Key = ExtendKey.F2 ) THEN

          DelStation( StationList, StationSelect, NumofStations );

      ELSIF ~ Escape & ( Key = ASCII.esc ) THEN

          StationSelect := NumofStations + 1;
          EXIT;

      ELSIF ~ Escape & ( Key = ASCII.cr ) THEN

          EXIT;

      END (* IF *);

  END (* LOOP *);

  AtStation := StationList;
  StationCount := 1;

  WHILE ( AtStation # NIL ) & ( StationCount < StationSelect ) DO

      AtStation := AtStation^.Next;
      INC( StationCount );

  END (* WHILE *);


  SetPlane( {2,3} );
  SetFunc( clr, 0 );
  FillArea( 216, 28, 208, 228, CARDINAL(0) );
  SetWindow( 0, 0, 639, 349 );

  IF AtStation # NIL THEN

      SelectStation( AtStation^ );
      CurrentStation := AtStation;

  END (* IF *);

  SetPlane( {0,1,2,3} );
  ClearScreen;
  Redraw;

END StationMenu;



PROCEDURE InitStationDir(   VAR StationList : StationPtr;
                          VAR NumofStations : CARDINAL );

(* Sets up the picture storage system *)

VAR

  Entry     : DirEntry;
  OK        : BOOLEAN;
  PhoneFile : File;
  AtStation : CARDINAL;
  TempPic   : PictureRec;

BEGIN

  (* Searches for station subdirectories, and creates station
     headers for each one it finds *)
  IF ReadFirstEntry( '????????.STA', FileAttr{directory}, Entry ) THEN

      NEW( StationList );
      (* Set the name and station number *)
      Copy( StationList^.StationName, Entry.Name );
      StationList^.StationNumber := 1;
      CurrentStation := StationList;
      (* Set the number of stations *)
      NumofStations := 1;
      WHILE ReadNextEntry(Entry) DO

          INC( NumofStations );
          (* Create a new station header, linked into the list *)
          NEW( CurrentStation^.Next );
          CurrentStation := CurrentStation^.Next;
          (* Set the name and station number *)
          Copy( CurrentStation^.StationName, Entry.Name );
          CurrentStation^.StationNumber := NumofStations;

      END (* WHILE *);
      CurrentStation^.Next := NIL;

  ELSE

      StationList := NIL;
      NumofStations := 0;

  END (* IF *);

  (* Now, read the picture lists for each station found *)
  CurrentStation := StationList;
  WHILE CurrentStation<>NIL DO

      (* Go into the station's subdirectory *)
      ChDir( CurrentStation^.StationName );
      WITH CurrentStation^ DO

          (* Read the phone number from PHONENUM.TXT *)
          PhoneFile := Open( 'PHONENUM.TXT' );
          IF PhoneFile < MAX(CARDINAL) THEN
              Phone[ RdBin( PhoneFile, Phone, 50000) ] := 000C;
              Close( PhoneFile );
          ELSE
              Phone := '--';
          END (* IF *);

          NumofPictures := 0;
          CurrentPicture := 0;
          (* Search for picture files *)
          IF ReadFirstEntry( '????????.WX', FileAttr{}, Entry ) THEN

              REPEAT

                  (* Set picture's time, range, tilt and gain *)
                  FileParam( TempPic, Entry.Name, OK );
                  (* Set the picture's date by date of file creation,
                     adding 80 to the year to adjust for the Modula-2
                     format used by TimeDate. *)
                  TempPic.TimeofPic.day := Entry.date + ( 80 << 9 );
                  TempPic.Size := CARDINAL(Entry.size);
                  IF OK THEN

                      (* Insert the picture into the picture list *)
                      AddPicture( Picture, NumofPictures, TempPic,
                          CurrentPicture );

                  END (* IF *);

              UNTIL ~ ReadNextEntry(Entry);

          END (* IF *);

          CurrentPicture := 0;

      END; (* WITH *)
      ChDir( '..' );
      CurrentStation := CurrentStation^.Next;

  END (* WHILE *);

  CurrentStation := NIL;

END InitStationDir;



END Stations.