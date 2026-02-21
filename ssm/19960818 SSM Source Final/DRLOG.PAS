(* DrLog.pas *)
(* Copyright (C) 1985, 1996  Derek G Lane *)

procedure WriteLog(LogNumber  : integer);
begin   if (LogNumber >= 0) and (LogNumber <= LastLog) then begin
            GotoXY(1, LogNumber-CurrentLog+AboveLog+1);
            ClrEol;
            FillChar(Line, SizeOf(Line), 32);
            with Log[LogNumber] do begin
                Line := '  ' + Copy(FindDay(Date),1,3) +
                    ' ' + ShortDate(Date) +
                    '                              ';
                Str(Total:8:2, StrA);
                Insert(StrA, Line, 25);
                for I:= 1 to 36 do
                    Screen[LogNumber-CurrentLog+AboveLog+UYLog,
                        I+UXLog-1, 1] := Line[I];
            end (* with *);
        end else begin
            GotoXY(1, LogNumber-CurrentLog+AboveLog+1);
            ClrEol;
        end (* if *);
        Window(UXLog, UYLog, LXLog, LYLog);
end (* WriteLog *);

procedure HiLiteLog;
begin   TextColor(HILITE_COLOR);
        TextBackground(HILITE_BACKG);
        GotoXY(1, AboveLog+1);
        ClrEol;
        WriteLog(CurrentLog);
        TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
end (* HiLiteLog *);

procedure LoLiteLog;
begin   GotoXY(1, AboveLog+1);
        ClrEol;
        WriteLog(CurrentLog);
end (* LoLiteLog *);

procedure DrawLog;
var     KeyLine  : LongStr;
begin   ChangeWindow(IAWindow);
        KeyLine := 'G = Goto date  I = Insert date  C = Change date  ' +
            'D = Delete date  ESC = Exit';
        Message(KeyLine);
        Window(UXLog, UYLog, LXLog, LYLog);
        for J := CurrentLog-AboveLog to CurrentLog+BelowLog+1 do
            WriteLog(J);
        HiLiteLog;
end (* DrawLog *);

procedure SetSavetoLog(ToLog  : integer);
begin   if (SaveToLog > ToLog) then
            SaveToLog := ToLog;
end (* SetSavetoLog *);

function MatchLog(ForDay  : DateRec)  : integer;
begin   I := LastLog;
        while (CompareDates(Log[I].Date, ForDay) > 0) and (I >= 0) do
            I := I - 1;
        Match := true;
        if (CompareDates(Log[I].Date, ForDay) = 0) then
            Match := true
        else
            Match := false;
        MatchLog := I;
end (* MatchLog *);

procedure MakeLog(ForDay  : DateRec);
begin   CurrentLog := MatchLog(ForDay);
        if not Match then begin
            LastLog := LastLog + 1;
            CurrentLog := CurrentLog + 1;
            SetSavetoLog(CurrentLog);
            Move(Log[CurrentLog], Log[CurrentLog+1],
                SizeOf(LogRec) * (LastLog-CurrentLog+1));
            with Log[CurrentLog] do begin
                Move(ForDay, Date, SizeOf(ForDay));
                DataPtr := 0;
                Total := 0;
            end (* with *);
        end (* if *);
end (* MakeLog *);

procedure LoadLog;
begin   (* CheckFile('LOG.DAT'); *)
        ReSet(LogFile);
        Seek(LogFile, 0);
        LastLog := FileSize(LogFile)-1;
        if (LastLog >= 0) then
            for I := 0 to LastLog do
                Read(LogFile, Log[I]);
        Close(LogFile);
end (* LoadLog *);

procedure SaveLog;
begin   if (ForLog < SavetoLog) then begin
            (* CheckFile('LOG.DAT'); *)
            ReSet(LogFile);
            Seek(LogFile, ForLog);
            if (IOResult = $91) then
                Exit;
            Write(LogFile, Log[ForLog]);
            Close(LogFile);
        end (* if *);
end (* SaveLog *);

procedure CloseLog;
begin   (* CheckFile('LOG.DAT'); *)
        ReSet(LogFile);
        Seek(LogFile, 0);
        for I := 0 to LastLog do
        Write(LogFile, Log[I]);
        Truncate(LogFile);
        Close(LogFile);
end (* CloseLog *);

procedure MainMenu;
var     key  : char;
        escFlag  : boolean;
        toDate  : DateRec;
begin   (* CreateDIRWindow; *)
        DrawLog;
        Cursor(16, 0);
        repeat
            ReadKbd(key, escFlag);
            case key of
                KEY_F1, KEY_ENTER  : begin
                    Edit;
                    DrawLog;
                end (* KEY_F1 *);
                KEY_F2  : begin
                    MonthSummary;
                    DrawLog;
                end (* KEY_F2 *);
                KEY_F3  : begin
                    YearSummary;
                    DrawLog;
                end (* KEY_F3 *);
                'd'  : begin
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    with Log[currentLog] do begin
                        Write(' DELETE LOG: ');
                        Write('Are you sure?');
                        ReadKbd(key, escFlag);
                        if (Key = 'y') then begin
                            SetSavetoLog(CurrentLog);
                            Move(Log[CurrentLog+1],
                                Log[CurrentLog],
                                SizeOf(LogRec) * (LastLog-CurrentLog+1));
                            LastLog := LastLog-1;
                        end (* if *);
                    end (* with *);
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    DrawLog;
                end (* d *);
                'g'  : begin
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    Write(' GOTO LOG: ');
                    ReadDate(toDate, Right);
                    if Right then begin
                        CurrentLog := MatchLog(toDate);
                    end (* if *);
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    DrawLog;
                end (* g *);
                'i'  : begin
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    Write(' INSERT LOG: ');
                    ReadDate(toDate, Right);
                    if Right then begin
                        MakeLog(toDate);
                        SetSavetoLog(CurrentLog);
                    end (* if *);
                    Window(2, 21, 40, 22);
                    GotoXY(1,1);
                    ClrEol;
                    DrawLog;
                end (* i *);
                'c'  : begin
                    SetSavetoLog(CurrentLog);
                    Window(2, 21, 40, 22);
                    GotoXY(1, 1);
                    ClrEol;
                    Write('  NEW DATE: ');
                    ReadDate(toDate, Right);
                    if Right then begin
                        SetSavetoLog(CurrentLog);
                        Move(Log[CurrentLog], AuxLog,
                            SizeOf(Log[CurrentLog]));
                        Move(toDate, AuxLog.Date, SizeOf(toDate));
                        Move(Log[CurrentLog+1], Log[CurrentLog],
                            SizeOf(LogRec) * (LastLog-CurrentLog+1));
                        LastLog := LastLog-1;
                        MakeLog(AuxLog.Date);
                        Move(AuxLog, Log[CurrentLog],
                            SizeOf(Log[CurrentLog]));
                    end (* if *);
                    GotoXY(1, 1);
                    ClrEol;
                    DrawLog;
                end (* c *);
                KEY_UP  : if (CurrentLog > 0) then begin
                    LoLiteLog;
                    GotoXY(1, 1);
                    CurrentLog := CurrentLog - 1;
                    InsLine;
                    WriteLog(CurrentLog - AboveLog);
                    HiLiteLog;
                end (* KEY_UP *);
                KEY_DN  : if (CurrentLog < LastLog) then begin
                    LoLiteLog;
                    CurrentLog := CurrentLog + 1;
                    GotoXY(1, 1);
                    DelLine;
                    WriteLog(CurrentLog + BelowLog + 1);
                    HiLiteLog;
                end (* KEY_DN *);
                KEY_HOME  : begin
                    CurrentLog := 0;
                    DrawLog;
                end (* KEY_HOME *);
                KEY_END  : begin
                    CurrentLog := LastLog;
                    DrawLog;
                end (* KEY_END *);
                KEY_PGUP  : if (CurrentLog-AboveLog-BelowLog >= 0) then begin
                    CurrentLog := CurrentLog-AboveLog-BelowLog;
                    DrawLog;
                end (* KEY_PGUP *);
                KEY_PGDN  : if (CurrentLog+AboveLog+BelowLog <= LastLog) then begin
                    CurrentLog := CurrentLog+AboveLog+BelowLog;
                    DrawLog;
                end (* KEY_PGDN *);
            end (* case *);
        until (key = KEY_ESC);
 end (* MainMenu *);