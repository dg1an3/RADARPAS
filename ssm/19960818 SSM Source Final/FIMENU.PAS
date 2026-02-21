PROCEDURE EnterTR; FORWARD;

PROCEDURE EnterMMP; FORWARD;

PROCEDURE EditPrice; FORWARD;

(*****************************************************************************)
(*     Main Menu routines                                                    *)
(*****************************************************************************)

TYPE
  SheetTypes   = (TRt,Deliveryt,DLMFIt,MMPt,Pricet);

  LogRec       = RECORD
    Date       :   DateRec;
    Pointer   :   ARRAY[SheetTypes] of INTEGER;
                 END;

VAR
  Log          : ARRAY[0..1024] of LogRec;
  LastLog      : INTEGER;
  CurrentLog   : INTEGER;
  SavetoLog    : INTEGER;
  OldLog       : INTEGER;
  LogFile      : FILE of LogRec;
  AuxLog       : LogRec;
  (* Match        : BOOLEAN; *)


PROCEDURE WriteLog(LogNumber : INTEGER);

  BEGIN
    IF (LogNumber>=0) AND (LogNumber<=LastLog) THEN BEGIN
      FillChar(Line,SizeOf(Line),32);
      Line:='º ';
      WITH Log[LogNumber] DO BEGIN
        Line:=Line
          +Copy(FindDay(Date),1,3)
          +' '+ShortDate(Date)
          +' '+ShortTime(Date);
        Line[0]:=#78;
        IF Pointer[TRt]>0 THEN Insert('Meter Readings',Line,TRColumn);
{       IF Pointer[Deliveryt]>0 THEN Insert('Delivery',Line,DelivColumn);
        IF Pointer[DLMFIt]>0 THEN Insert('Fuel Inventory',Line,DLMFIColumn);}
        IF Pointer[MMPt]>0 THEN Insert('Fuel Income',Line,MMPColumn);
        IF Pointer[Pricet]>0 THEN  Insert('Price Change',Line,PriceColumn);
        Line[78]:='º';
        DrawLine(Line[1],UYLog+LogNumber-CurrentLog+AboveLog);
      END;
    END
    ELSE BEGIN
      GotoXY(1,LogNumber-CurrentLog+AboveLog+1);ClrEol;
    END;
  END;


FUNCTION NullLog(LogNumber : INTEGER) : BOOLEAN;

  BEGIN
    WITH Log[LogNumber] DO
      NullLog:=
        (Pointer[TRt]<=0) AND
        (Pointer[Deliveryt]<=0) AND
        (Pointer[DLMFIt]<=0) AND
        (Pointer[MMPt]<=0) AND
        (Pointer[Pricet]<=0);
  END;


FUNCTION NewLog(LogNumber : INTEGER) : BOOLEAN;

  BEGIN
    WITH Log[LogNumber] DO
      NewLog:=
        (Pointer[TRt]=0) AND
        (Pointer[Deliveryt]=0) AND
        (Pointer[DLMFIt]=0) AND
        (Pointer[MMPt]=0) AND
        (Pointer[Pricet]=0);
  END;


PROCEDURE HiLiteLog;

  BEGIN
    TextColor(HILITE_COLOR);
    TextBackground(HILITE_BACKG);
    GotoXY(1,AboveLog+1);
    ClrEol;
    WriteLog(CurrentLog);
    TextColor(NORM_COLOR);
    TextBackground(NORM_BACKG);
  END;


PROCEDURE LoLiteLog;

  BEGIN
    GotoXY(1,AboveLog+1);ClrEol;WriteLog(CurrentLog);
  END;


PROCEDURE DrawLog;
  VAR KeyLine  : LineType;
  BEGIN
    ChangeWindow(FIMWindow);
    KeyLine:='G = Goto date  ESC = Exit';
    IF ChangeStatus THEN
      Insert('I = Insert date  C = Change date  D = Delete date  ',KeyLine,1);
    Message(KeyLine);
    Window(UXLog,UYLog,LXLog,LYLog);
    FOR J:=CurrentLog-AboveLog to CurrentLog+BelowLog DO WriteLog(J);
    HiLiteLog;
  END;


PROCEDURE SetSavetoLog(ToLog : INTEGER);

  BEGIN
    IF SaveToLog>ToLog THEN SaveToLog:=ToLog;
  END;


FUNCTION MatchLog(ForDay : DateRec) : INTEGER;

  BEGIN
    I:=LastLog;
    WHILE (CompareDates(Log[I].Date,ForDay)>0) AND (I>=0) DO I:=I-1;
    IF CompareDates(Log[I].Date,ForDay)=0 THEN Match:=TRUE
      ELSE Match:=FALSE;
    MatchLog:=I;
  END;


PROCEDURE MakeLog(ForDay : DateRec);

  BEGIN
    CurrentLog:=MatchLog(ForDay);
    IF NOT Match THEN BEGIN
      LastLog:=LastLog+1;
      CurrentLog:=CurrentLog+1;
      SetSavetoLog(CurrentLog);
      Move(Log[CurrentLog],Log[CurrentLog+1],SizeOf(LogRec)*(LastLog-CurrentLog+1));
      WITH Log[CurrentLog] DO BEGIN
        Move(ForDay,Date,SizeOf(ForDay));
        Pointer[TRt]:=0;
        Pointer[Deliveryt]:=0;
        Pointer[DLMFIt]:=0;
        Pointer[MMPt]:=0;
        Pointer[Pricet]:=0;
      END;
    END;
  END;


PROCEDURE LoadLog;

  BEGIN
    ReSet(LogFile);
    IF (IOResult = $01) THEN
      ErrorMsg('FIM Data not found');
    Seek(LogFile,0);
    LastLog:=FileSize(LogFile)-1;
    IF LastLog>=0 THEN
      FOR I:=0 to LastLog DO Read(LogFile,Log[I]);
    SavetoLog:=LastLog+1;
    Close(LogFile);
    IF (IOResult = $FF) THEN
      ErrorMsg('FIM Data not found');
  END;


PROCEDURE SaveLog(ForLog : INTEGER);

  BEGIN
    IF ForLog<SavetoLog THEN BEGIN
      ReSet(LogFile);
      IF (IOResult = $01) THEN
        ErrorMsg('FIM Data not found');
      Seek(LogFile,ForLog); IF (IOResult = $91) THEN Exit;
      Write(LogFile,Log[ForLog]);
      Close(LogFile);
      IF (IOResult = $FF) THEN
        ErrorMsg('FIM Data not found');
    END;
  END;


PROCEDURE CloseLog;

  BEGIN
    IF SavetoLog<0 THEN SavetoLog:=0;
    IF SavetoLog<=LastLog THEN BEGIN
      ReSet(LogFile);IF IOResult=$01 THEN
        ErrorMsg('FIM Data not found');
      Seek(LogFile,SavetoLog); IF IOResult=$91 THEN Exit;
      FOR I:=SavetoLog to LastLog DO
        IF NOT(NewLog(I)) THEN Write(LogFile,Log[I]);
      Truncate(LogFile);
      Close(LogFile);IF IOResult=$FF THEN
        ErrorMsg('FIM Data not found');
    END;
  END;


PROCEDURE WriteKeyLine;
var     KeyLine  : LongStr;
  BEGIN
    KeyLine:='P = Print  ESC = Exit to main menu';
    IF ChangeStatus THEN Insert('E = Edit  ',KeyLine,1);
    Message(KeyLine);
  END;


PROCEDURE WriteEditLine(Sheet : SheetTypes);
  BEGIN
    KeyLine:='EDIT MODE: ESC = Exit';
    IF Log[CurrentLog].Pointer[Sheet]<0 THEN Insert('R = Restore  ',KeyLine,12);
    IF Log[CurrentLog].Pointer[Sheet]>0 THEN Insert('D = Delete  ',KeyLine,12);
    Message(KeyLine);
  END;


PROCEDURE MainMenu;
  BEGIN
    DrawLog;
    Cursor(16,0);
    REPEAT
      ReadKbd;
      CASE Key of
        ';'  :  EnterTR;
        '<'  :  EnterMMP;
        '='  :  EditPrice;
        'd'  :  IF ChangeStatus THEN BEGIN
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  WITH Log[currentLog] DO BEGIN
                    Write(' DELETE LOG: ');
                    IF (NullLog(CurrentLog)) OR (Date.Year<>TodaysDate.Year) THEN BEGIN
                        Write('Are you sure?'); ReadKbd;
                        IF Key='y' THEN BEGIN
                          SetSavetoLog(CurrentLog);
                          Move(Log[CurrentLog+1],Log[CurrentLog],SizeOf(LogRec)*(LastLog-CurrentLog+1));
                          LastLog:=LastLog-1;
                        END;
                      END
                    ELSE ErrorMsg('That log still has entries');
                  END;
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'g'  :  BEGIN
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  Write(' GOTO LOG: ');
                  ReadDate;
                  IF Right THEN BEGIN
                    CurrentLog:=MatchLog(ADate);
                    IF NOT Match THEN
                      ErrorMsg('There is no entry with that date');
                  END;
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'i'  :  IF ChangeStatus THEN BEGIN
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  Write(' INSERT LOG: ');
                  ReadDate;
                  IF Right THEN BEGIN
                    MakeLog(ADate);
                    SetSavetoLog(CurrentLog);
                    IF Match THEN
                      ErrorMsg('There is already an entry with that date');
                  END;
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'c'  :  IF ChangeStatus THEN BEGIN
                  SetSavetoLog(CurrentLog);
                  Window(UXLog,LYLog+2,LXLog,LYLog+4);GotoXY(1,1);ClrEol;
                  Write('  NEW DATE: ');
                  ReadDate;
                  IF Right THEN BEGIN
                    SetSavetoLog(CurrentLog);
                    Move(Log[CurrentLog],AuxLog,SizeOf(Log[CurrentLog]));
                    Move(ADate,AuxLog.Date,SizeOf(ADate));
                    Move(Log[CurrentLog+1],Log[CurrentLog],SizeOf(LogRec)*(LastLog-CurrentLog+1));
                    LastLog:=LastLog-1;
                    MakeLog(AuxLog.Date);
                    Move(AuxLog,Log[CurrentLog],SizeOf(Log[CurrentLog]));
                  END;
                  GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'H'  :  IF CurrentLog>0 THEN BEGIN
                  LoLiteLog;
                  GotoXY(1,1);
                  CurrentLog:=CurrentLog-1;
                  InsLine;
                  WriteLog(CurrentLog-AboveLog);
                  HiLiteLog;
                END;
        'P'  :  IF CurrentLog<LastLog THEN BEGIN
                  LoLiteLog;
                  CurrentLog:=CurrentLog+1;
                  GotoXY(1,1);DelLine;
                  GotoXY(1,AboveLog+BelowLog+1);WriteLog(CurrentLog+BelowLog);
                  HiLiteLog;
                END;
        'G'  :  BEGIN
                  CurrentLog:=0;
                  DrawLog;
                END;
        'O'  :  BEGIN
                  CurrentLog:=LastLog;
                  DrawLog;
                END;
        'I'  :  IF CurrentLog-AboveLog-BelowLog>=0 THEN BEGIN
                    CurrentLog:=CurrentLog-AboveLog-BelowLog;
                    DrawLog;
                END;
        'Q'  :  IF CurrentLog+AboveLog+BelowLog<=LastLog THEN BEGIN
                  CurrentLog:=CurrentLog+AboveLog+BelowLog;
                  DrawLog;
                END;
        #27  :  Exit;
      END;
    UNTIL FALSE;
  END;