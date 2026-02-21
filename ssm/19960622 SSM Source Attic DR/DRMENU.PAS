 {PROCEDURE EnterIA; FORWARD;}

{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     Main Menu routines                                                       }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}


PROCEDURE WriteLog(LogNumber : INTEGER);

  BEGIN
    IF (LogNumber>=0) AND (LogNumber<=LastLog) THEN BEGIN
      GotoXY(1,LogNumber-CurrentLog+AboveLog+1);ClrEol;
      FillChar(Line,SizeOf(Line),32);
      WITH Log[LogNumber] DO BEGIN
        Line:='  '+Copy(FindDay(Date),1,3)
          +' '+ShortDate(Date)+'                              ';
        Str(Total:8:2,StrA);
        Insert(StrA,Line,25);
        FOR I:= 1 to 36 DO
          Screen[LogNumber-CurrentLog+AboveLog+UYLog,I+UXLog-1,1]:=Line[I];
      END;
    END
    ELSE BEGIN
      GotoXY(1,LogNumber-CurrentLog+AboveLog+1);ClrEol;
    END;
    Window(UXLog,UYLog,LXLog,LYLog);
  END;


PROCEDURE HiLiteLog;

  BEGIN
    TextColor(HiColor);TextBackground(HiBack);
    GotoXY(1,AboveLog+1);ClrEol;
    WriteLog(CurrentLog);
    TextColor(NormColor);TextBackground(NormBack);
  END;


PROCEDURE LoLiteLog;

  BEGIN
    GotoXY(1,AboveLog+1);ClrEol;WriteLog(CurrentLog);
  END;


PROCEDURE DrawLog;

  BEGIN
    ChangeWindow(IAWindow);
    KeyLine:='G = Goto date  ESC = Exit';
    IF ChangeStatus THEN
      Insert('I = Insert date  C = Change date  D = Delete date  ',KeyLine,1);
    Message(KeyLine);
    Window(UXLog,UYLog,LXLog,LYLog);
    FOR J:=CurrentLog-AboveLog to CurrentLog+BelowLog+1 DO WriteLog(J);
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
    Match:=TRUE;
    IF CompareDates(Log[I].Date,ForDay)=0 THEN Match:=TRUE ELSE Match:=FALSE;
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
        DataPtr:=0;
        Total:=0;
      END;
    END;
  END;


PROCEDURE LoadLog;

  BEGIN
    CheckFile('LOG.DAT');
    ReSet(LogFile);
    Seek(LogFile,0);
    LastLog:=FileSize(LogFile)-1;
    IF LastLog>=0 THEN
      FOR I:=0 to LastLog DO Read(LogFile,Log[I]);
    Close(LogFile);
  END;


PROCEDURE SaveLog;

  BEGIN
    IF ForLog<SavetoLog THEN BEGIN
      CheckFile('LOG.DAT');
      ReSet(LogFile);
      Seek(LogFile,ForLog); IF IOError=$91 THEN Exit;
      Write(LogFile,Log[ForLog]);
      Close(LogFile);
    END;
  END;


PROCEDURE CloseLog;

  BEGIN
    CheckFile('LOG.DAT');
    ReSet(LogFile);
    Seek(LogFile,0);
    FOR I:=0 to LastLog DO
    Write(LogFile,Log[I]);
    Truncate(LogFile);
    Close(LogFile);
  END;


PROCEDURE MainMenu;

  BEGIN
    CreateDIRWindow;
    DrawLog;
    Cursor(16,0);
    REPEAT
      ReadKbd;
      CASE Key of
        ';'  :  BEGIN
                  Edit;
                  DrawLog;
                END;
        '<'  :  BEGIN
                  MonthSummary;
                  DrawLog;
                END;
        '='  :  BEGIN
                  YearSummary;
                  DrawLog;
                END;
        'd'  :  IF ChangeStatus THEN BEGIN
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  WITH Log[currentLog] DO BEGIN
                    Write(' DELETE LOG: ');
                    Write('Are you sure?'); ReadKbd;
                    IF Key='y' THEN BEGIN
                      SetSavetoLog(CurrentLog);
                      Move(Log[CurrentLog+1],Log[CurrentLog],SizeOf(LogRec)*(LastLog-CurrentLog+1));
                      LastLog:=LastLog-1;
                    END;
                  END;
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'g'  :  BEGIN
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  Write(' GOTO LOG: ');
                  ReadDate;
                  IF Right THEN BEGIN
                    CurrentLog:=MatchLog(ADate);
                  END;
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'i'  :  IF ChangeStatus THEN BEGIN
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  Write(' INSERT LOG: ');
                  ReadDate;
                  IF Right THEN BEGIN
                    MakeLog(ADate);
                    SetSavetoLog(CurrentLog);
                  END;
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
                  DrawLog;
                END;
        'c'  :  IF ChangeStatus THEN BEGIN
                  SetSavetoLog(CurrentLog);
                  Window(2,21,40,22);GotoXY(1,1);ClrEol;
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
                  WriteLog(CurrentLog+BelowLog+1);
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