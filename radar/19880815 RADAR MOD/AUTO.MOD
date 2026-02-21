IMPLEMENTATION MODULE Auto;

FROM E300Interface IMPORT
    TiltType, RangeType, GainType;
FROM Graphics IMPORT
    SetFunc, SetPlane, FillArea, SetWindow, GotoXY, SetFont,
    or, clr;
IMPORT Graph;
FROM IO IMPORT
    WrStr, WrStrAdj, WrCard;
FROM ScreenHandler IMPORT
    WriteTime, WriteTilt, WriteRange, WriteGain, Message,
    ClearScreen, Redraw;
FROM Selector IMPORT
    Select;
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
  END (* IF *);
END SetNextProg;


PROCEDURE DoAuto;

VAR

  CurrTime : Time;

BEGIN
  IF NextProg = 0 THEN RETURN END;
  WITH Programs[NextProg] DO
      GetTime( CurrTime );
      IF CompareTime( CurrTime, Programs[NextProg].NextUpdate ) < 0 THEN
          RETURN;
      END (* IF *);
(*      Message( ' DOING PROGRAM ' );
      WrCard( NextProg, 1 ); *)
      WITH NextUpdate DO
          day := day + ( minute + Interval ) DIV 1440;
          minute := ( minute + Interval ) MOD 1440;
      END (* WITH *);
      SetNextProg;
  END (* WITH *);
(*  LOOP
    SleepUntil(NextUpdate);
    WAIT(rs.Available);
    WITH Auto DO
      Dial(Phone);
      IF Result=connect2400 THEN
        SetParams(Tilt,Range,Gain);
        MakePic();
        DownloadPic;
      END (* IF *);
    END (* WITH *);
    AddTime(NextUpDate,Interval);
    SEND(rs.Available);
  END (* LOOP *); *)
END DoAuto;

  PROCEDURE AddProgram;
    VAR
      PromptStr : ARRAY [ 0..39 ] OF CHAR;
      Response  : ARRAY [ 0..7 ] OF CHAR;
    BEGIN
(*      IF LastProg = 'J' THEN
        Message( 'ALL PROGRAMS FILLED.' );
        RETURN;
      END (* IF *);
      IF StationName = '' THEN
        Message( 'NO STATION SELECTED.' );
        RETURN;
      END;
      LastProg := SUCC(LastProg);
      WITH Programs[LastProg] DO
        ForStat := Copy( StationName, 1, Pos( '.', StationName )-1 );
        GetTime( NextCall );
        Interval := 30;
        Tilt := MAX(CARDINAL);
        Range := MAX(CARDINAL);
        Gain := MAX(CARDINAL);

        LOOP
            PromptStr := ' PROGRAM  : Starting time         ';
            PromptStr[9] := LastProg;
            Hour := NextCall.minute DIV 60;
            Minute := NextCall.minute MOD 60;
            IF Hour < 10 THEN
                Response[0] := '0';
                Response[1] := Hour
            CardToStr( LONGCARD(Hour), Response+
            Prompt( PromptStr, Response );
            Hour := CARDINAL(StrToCard( Response, 10, OK ));
            IF OK THEN
                Slice( Response, Response, Pos( Response, ':' )+1, 255 );
                Minute := CARDINAL(StrToCard( Response, 10, OK ));
                IF CAP(Response[2]) = 'P' THEN
                    Hour := Hour+12;
                ELSIF ( CAP(Response[2]) = 'A' ) & ( Hour = 12 ) THEN
                    Hour := 0;
                END (* IF *);
                IF OK THEN EXIT END;
            END (* IF *);
        END (* LOOP *);

          Val(StrA,I,J);
          NextCall.Hour := I;
          Val(Copy(StrA,J+1,255),I,J);
          NextCall.Minute := I;
          IF J<=Length(StrA) then begin
            IF UpCase(StrA[J])='P' THEN
              NextCall.Hour := NextCall.Hour+12;
              NextCall.Hour := 0;
          end; (* if *)
        end; (* if *)
        GRMessage('PROGRAM '+LastProg+': Interval     min    ',false);
        GotoXY(45,24);
        Write(Interval);
        GotoXY(45,24);
        StrA := ReadStr(3);
        if StrA<>'' then
          Val(StrA,Interval,I);
        GRMessage('PROGRAM '+LastProg+': Tilt                ',false);
        GotoXY(41,24);
        Write('--');
        GotoXY(41,24);
        StrA := ReadStr(2);
        if StrA<>'' then begin
          Val(StrA,Tilt,I);
        end; (* if *)
        GRMessage('PROGRAM '+LastProg+': Range               ',false);
        GotoXY(42,24);
        Write('---');
        GotoXY(42,24);
        StrA := ReadStr(3);
        if StrA<>'' then begin
          Val(StrA,Range,I);
        end; (* if *)
        GRMessage('PROGRAM '+LastProg+': Gain                ',false);
        GotoXY(41,24);
        Write('--');
        GotoXY(41,24);
        StrA := ReadStr(3);
        if StrA<>'' then begin
          Val(StrA,Gain,I);
        end; (* if *)
        GRMessage('',false);
      end;
      ReadStrBlank := true; *)
    END AddProgram;

  PROCEDURE DelProgram;
  BEGIN
(*      GRMessage('PROGRAM TO DELETE?',true);
      Key := UpCase(Key);
      if (Key>='A') and (Key<=LastProg) then begin
        while Key<LastProg do begin
          Move(Programs[Succ(Key)],Programs[Key],SizeOf(Programs[Key]));
          Key := Succ(Key);
        end; (* while *)
        LastProg := Pred(LastProg);
      end; *)

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


PROCEDURE ProgramMenu;

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

(*
    IF LastProg >= 'A' THEN
      FOR Key := 'A' TO LastProg DO
        WITH Programs[Key] DO begin
          Write(' ',Key,'๚ ');
          Write(Copy(ForStat+'        ',1,8),'  ');
          WriteTime(NextCall);
          Write(Interval:5);
          Write(' min');
          if Tilt>=0 then Write(TiltVal[Tilt]:5) else Write('   --');
          if Range>=0 then Write(RangeVal[Range]:6) else Write('   ---');
          if Gain>=0 then
            if Gain=17 then Write('   PRE')
            else Write(Gain:5)
          else Write('   --');
          WriteLn;
        end;
*)
    GotoXY( 0, 196 );
    WrStr( 'ออออออออออออออออออออออออออออออออออออออออออออออ' );
    WrStr( ' F1 ๚ Add       F2 ๚ Delete        ESC ๚ Exit ' );

    ProgramSelect := 0;
    Select( 136, 70, 504, 262, WriteProgramEntry,
        NumofPrograms, ProgramSelect, Key, Escape );

    SetPlane( {2,3} );
    SetFunc( clr, 0 );
    FillArea( 136, 42, 368, 228, CARDINAL(0) );

    SetPlane( {0,1,2,3} );
    ClearScreen;
    Redraw;

    SetWindow( 0, 0, 639, 349 );

(*    if Escape then begin
      case Key of
        ';' : AddProgram;
        '<' : DelProgram;
      end;
      ProgramMenu;
      Key := ^[;
    end;
  until Key=^[;
  UnWindow;
  Key:=#0;
  SetNextProg; *)

END ProgramMenu;

BEGIN
(*  Graph.InitEGA;
  Graph.GraphMode;
  SetFont( 14 ); *)
  WITH Programs[1] DO
      Station := 'SIU';
      GetTime( NextUpdate );
      NextUpdate.minute := 950; (* 4:30pm *)
      Interval := 30;
      Tilt := 2;
      Range := 4;
      Gain := 17;
  END (* WITH *);
  WITH Programs[2] DO
      Station := 'ELLASON';
      GetTime( NextUpdate );
      NextUpdate.minute := 952; (* 4:40pm *)
      Interval := 30;
      Tilt := 4;
      Range := 3;
      Gain := 17;
  END (* WITH *);
  WITH Programs[3] DO
      Station := 'WAUKESHA';
      GetTime( NextUpdate );
      NextUpdate.minute := 954; (* 5:15pm *)
      Interval := 60;
      Tilt := 2;
      Range := 4;
      Gain := 17;
  END (* WITH *);
  WITH Programs[4] DO
      Station := 'SHELL';
      GetTime( NextUpdate );
      NextUpdate.minute := 957; (* 4:05pm *)
      Interval := 30;
      Tilt := 2;
      Range := 4;
      Gain := 17;
  END (* WITH *);
  NumofPrograms := 4;
  SetNextProg;
(*  ProgramMenu; *)
END Auto.