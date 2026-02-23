IMPLEMENTATION MODULE Auto;

IMPORT ASCII;

FROM E300Interface IMPORT
    TiltType, RangeType, GainType, SetParam, GetParam,
    MakePic, PicReady, GetLine, RTState, AbortPic;

FROM ExtendKey IMPORT
    ExtRead, F1, F2;

IMPORT FIO;

FROM Graphics IMPORT
    SetFunc, SetPlane, FillArea, SetWindow, GotoXY, SetFont,
    or, clr;

IMPORT Graph;

FROM IO IMPORT
    WrStr, WrStrAdj, WrCard, KeyPressed;

FROM Lib IMPORT
    Move, Delay;

IMPORT Modem;

IMPORT Options;

FROM Pictures IMPORT
    PictureRec, SavePicture, AddPicture;

IMPORT rs;

FROM ScreenHandler IMPORT
    WriteTime, WriteTilt, WriteRange, WriteGain, Message,
    ClearScreen, Redraw, DrawScale, ComprLine, WriteParams,
    Prompt, Pause;

FROM Selector IMPORT
    Select;

FROM Storage IMPORT
    ALLOCATE;

FROM Stations IMPORT
    StationPtr;

IMPORT Str;

FROM TimeDate IMPORT
    Time, CompareTime, GetTime;


TYPE
  AutoRec   = RECORD
       Station : ARRAY [ 0..7 ] OF CHAR;
         Phone : ARRAY [ 0..63 ] OF CHAR;
          Tilt : TiltType;
         Range : RangeType;
          Gain : GainType;
    NextUpdate : Time;
      Interval : CARDINAL;
         State : ( Idle, Dialing, ParamSet, WaitPic, RxPic );
  END (* AutoRec *);

VAR
  Programs      : ARRAY [ 1..10 ] OF AutoRec;
  NumofPrograms : CARDINAL;
  NextProg      : CARDINAL;

PROCEDURE SetNextProg;
VAR
  Count : CARDINAL;
BEGIN
  IF NumofPrograms > 0 THEN
      NextProg := 1;
      FOR Count := 2 TO NumofPrograms DO
          IF CompareTime( Programs[Count].NextUpdate,
              Programs[NextProg].NextUpdate ) < 0 THEN
              NextProg := Count;
          END (* IF *);
      END (* FOR *);
  ELSE
      NextProg := 0;
  END (* IF *);
END SetNextProg;

(*
PROCEDURE SetParamKey() : CHAR;
BEGIN
  IF KeyPressed THEN

      Key := RdKey();
      IF Key IN {'M','1','2','G','L'} THEN
          RETURN( Key );
      END (* IF *);

      IF Key = ASCII.esc THEN
          Key := Pause( ' Abort program (Y/N) ? ' );
          IF Key = 'Y' THEN
          END (* IF *);
      END (* IF *);

  ELSE

      IF SetParams THEN
          (* Compare current params with ToParams. *)
          (* If different, send proper key code. *)
          (* If same, SetParams := TRUE *)
      END (* IF *);

  END (* IF *);

END SetParamKey;
*)


PROCEDURE DoAuto( CurrentStation : StationPtr );

VAR

    CurrTime : Time;
  NewPicture : PictureRec;
      Result : Modem.ResultCode;
         Key : CHAR;
      Escape : BOOLEAN;
          RT : RTState;
AbortPending : BOOLEAN;
      Number : CARDINAL;
          At : CARDINAL;
    Red, Grn : ARRAY [ 0..159 ] OF BYTE;

BEGIN
  IF NextProg = 0 THEN RETURN END;
  WITH Programs[NextProg] DO
      GetTime( CurrTime );
      IF CompareTime( CurrTime, Programs[NextProg].NextUpdate ) < 0 THEN
          RETURN;
      END (* IF *);

      WITH NewPicture DO

          Message( ' Performing Program... ' );
          Modem.Call( Phone, Result );
          Delay( 1000 );

          IF Result = Modem.Connect2400 THEN

              Message( ' Setting parameters... ' );
              GetParam( Tilt, Range, Gain, TimeofPic, RT );
              IF Programs[NextProg].Tilt <= MAX(TiltType) THEN
                  Tilt := Programs[NextProg].Tilt;
              END (* IF *);
              IF Programs[NextProg].Range <= MAX(RangeType) THEN
                  Range := Programs[NextProg].Range;
              END (* IF *);
              IF Programs[NextProg].Gain <= MAX(GainType) THEN
                  Gain := Programs[NextProg].Gain;
              END (* IF *);
              SetParam( Tilt, Range, Gain, TimeofPic, RT );
              WriteParams( Tilt, Range, Gain, TimeofPic, RT );

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

                          END (* IF *);
                          AbortPending := FALSE;
                          Message( ' Receiving Picture, ESC to abort... ' );

                      ELSE

                          IF Key = ASCII.esc THEN

                              Message( ' Abort Picture ( Y/N ) ? ' );
                              AbortPending := TRUE;
                              Key := ASCII.nul;

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

              Key := ASCII.nul;

          END (* IF *);

      END (* WITH *);
      Message( '' );

      IF Result = Modem.Connect2400 THEN
          WITH NextUpdate DO

              day := day + ( minute + Interval ) DIV 1440;
              minute := ( minute + Interval ) MOD 1440;
          END (* WITH *);

      END (* IF *);

  END (* WITH *);

  SetNextProg;

END DoAuto;


PROCEDURE AddProgram( CurrentStation : StationPtr );
VAR
  PromptStr : ARRAY [ 0..39 ] OF CHAR;
  Response  : ARRAY [ 0..7 ] OF CHAR;
  TempStr   : ARRAY [ 0..7 ] OF CHAR;
  OK        : BOOLEAN;
BEGIN
  IF NumofPrograms >= HIGH( Programs ) THEN
    Message( ' Program list full. ' );
    RETURN;
  END (* IF *);
  IF CurrentStation = NIL THEN
    Message( ' Must select a station.  Press F1. ' );
    RETURN;
  END (* IF *);
  INC( NumofPrograms );
  WITH Programs[NumofPrograms] DO
    Str.Slice( Station, CurrentStation^.StationName, 0,
        Str.Pos( CurrentStation^.StationName, '.' ) );
    Str.Copy( Phone, CurrentStation^.Phone );
    GetTime( NextUpdate );
    Interval := 30;
    Tilt := MAX(CARDINAL);
    Range := MAX(CARDINAL);
    Gain := MAX(CARDINAL);

    LOOP
        Response[0] := 000C;
        Prompt( ' Starting Time : ', Response );
        IF Response[0] # 000C THEN
            Str.Slice( TempStr, Response, 0, Str.Pos( Response, ':' ) );
            NextUpdate.minute := CARDINAL(Str.StrToCard(
                TempStr, 10, OK ))*60;
            IF CAP(Response[Str.Length(Response)-1]) = 'P' THEN
                INC( NextUpdate.minute, 12*60 );
                Str.Slice( Response, Response, 0, Str.Length(Response)-1 );
            ELSIF ( CAP(Response[Str.Length(Response)-1]) = 'A' ) &
                ( NextUpdate.minute DIV 60 = 12 ) THEN
                NextUpdate.minute := NextUpdate.minute MOD 60;
                Str.Slice( Response, Response, 0, Str.Length(Response)-1 );
            END (* IF *);

            Str.Slice( Response,
                Response, Str.Pos( Response, ':' )+1, 255 );
            INC( NextUpdate.minute, CARDINAL(Str.StrToCard(
                Response, 10, OK )) );
            EXIT;
        ELSE
            EXIT;
        END (* IF *);

    END (* LOOP *);

    Response[0] := 000C;
    Prompt( ' Interval  : ', Response );
    IF Response[0] # 000C THEN
        Interval := CARDINAL(Str.StrToCard( Response, 10, OK ));
    END (* IF *);

    Response[0] := 000C;
    Prompt( ' Tilt  : ', Response );
    IF Response[0] # 000C THEN

        Tilt := CARDINAL(Str.StrToCard( Response, 10, OK ));
        CASE Tilt OF
            7,8    : Tilt := 7; |
            9,10   : Tilt := 8; |
            11,12  : Tilt := 9; |
            13..15 : Tilt := 10; |
            16..20 : Tilt := 11
        ELSE
        END;  (* CASE *)

    END (* IF *);

    Response[0] := 000C;
    Prompt( ' Range : ', Response );
    IF Response[0] # 000C THEN

        Range := CARDINAL(Str.StrToCard( Response, 10, OK ));
        CASE Range DIV 10 OF
            1      : Range := 0; |
            2      : Range := 1; |
            3..5   : Range := 2; |
            6..10  : Range := 3; |
            11..20 : Range := 4
        ELSE
        END; (* CASE *)

    END (* IF *);

    Response[0] := 000C;
    Prompt( ' Gain  : ', Response );
    IF Response[0] # 000C THEN

        IF CAP(Response[0]) # 'P' THEN

            Gain := CARDINAL(Str.StrToCard( Response, 10, OK ));
            IF Gain = 0 THEN Gain := 17 END;

        ELSE

            Gain := 17;

        END (* IF *);

    END (* IF *);

  END (* WITH *);
END AddProgram;


PROCEDURE DelProgram( Number : CARDINAL );
BEGIN

    IF ( Number > 0 ) & ( CAP(Pause(' Delete this program (Y/N) ? ' ))
        = 'Y' ) THEN
        Programs[ Number ] := Programs[ NumofPrograms ];
        DEC( NumofPrograms );
    END (* IF *);

END DelProgram;


PROCEDURE WriteProgramEntry
    ( Number : CARDINAL );

BEGIN

  WITH Programs[Number] DO
      WrStr( ' ' );
      WrStrAdj( Station, -9 );
      WriteTime( NextUpdate );
      WrCard( Interval, 5 );
      WrStr( ' min   ' );
      WriteTilt( Tilt );
      WrStr( '   ' );
      WriteRange( Range );
      WrStr( '   ' );
      WriteGain( Gain );
   END (* WITH *);

END WriteProgramEntry;


PROCEDURE ProgramMenu( CurrentStation : StationPtr );

VAR

  ProgramSelect : CARDINAL;
  Key           : CHAR;
  Escape        : BOOLEAN;

BEGIN
(*  REPEAT *)
    SetPlane( {2} );
    SetFunc( or, 0 );
    FillArea( 136, 42, 368, 228, CARDINAL(0FFFFH) );
    SetPlane( {3} );
    SetWindow( 136, 42, 368, 224 );

    GotoXY( 0, 0 );
    WrStr( 'อออออออออออออออออ PROGRAMS อออออออออออออออออออ' );
    WrStr( ' Station ๚Next Call๚Interval๚Tilt๚Range๚Gain  ' );

    GotoXY( 0, 196 );
    WrStr( 'ออออออออออออออออออออออออออออออออออออออออออออออ' );
    WrStr( ' F1 ๚ Add       F2 ๚ Delete        ESC ๚ Exit ' );

    REPEAT
        ProgramSelect := 0;
        Select( 136, 70, 504, 262, WriteProgramEntry,
            NumofPrograms, ProgramSelect, Key, Escape );

        IF Escape THEN
          CASE Key OF
            F1 : AddProgram( CurrentStation ) |
            F2 : DelProgram( ProgramSelect )
          END (* CASE *);
        END (* IF *);

        SetPlane( {3} );
        SetFunc( clr, 0 );
        FillArea( 136, 70, 368, 172, CARDINAL(0) );

    UNTIL ( Key = ASCII.esc );

    SetPlane( {2,3} );
    SetFunc( clr, 0 );
    FillArea( 136, 42, 368, 228, CARDINAL(0) );

    SetPlane( {0,1,2,3} );
    ClearScreen;
    Redraw;

    SetWindow( 0, 0, 639, 349 );

  Move( ADR( Programs ), ADR( Options.Programs ), 882 );
  Options.SaveOptions;

  SetNextProg;
END ProgramMenu;


PROCEDURE UpdateTimes( VAR At : ARRAY OF BYTE );

VAR
  Count : CARDINAL;
  CurrTime : Time;

BEGIN

  Move( ADR( At ), ADR( Programs ), 882 );
  IF NumofPrograms > 0 THEN

      GetTime( CurrTime );
      FOR Count := 1 TO NumofPrograms DO

          WITH Programs[ Count ] DO

              NextUpdate.day := CurrTime.day;
              WHILE NextUpdate.minute < CurrTime.minute DO

                  WITH NextUpdate DO

                      day := day + ( minute + Interval ) DIV 1440;
                      minute := ( minute + Interval ) MOD 1440;

                  END (* WITH *);

              END (* WHILE *);

          END (* WITH *);

      END (* FOR *);
  END (* IF *);

END UpdateTimes;

END Auto.