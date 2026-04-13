(* iasummry.pas *)
(* Copyright (C) 1985, 1996 Derek G Lane *)
(* Included by ia.pas *)
(* Part of the SSM 1.5 Package *)

procedure MonthSummary;
var     TotalStore :   real;
begin   ChangeWindow(DIRWindow);
        Message('P = Print  ESC = Exit');
        for J := 1 to NumberofAccounts do
            Data[J] := 0;
        ReSet(DataFile);
        I := CurrentLog;
        repeat
            if Log[I].DataPtr>0 then begin
                Seek(DataFile,Log[I].DataPtr-1);
                Read(DataFile,AuxData);
                for J:=1 to NumberofAccounts do
                    Data[J]:=Data[J]+AuxData[J];
            end;
            I:=I-1;
        until Log[I].Date.Month<>Log[CurrentLog].Date.Month;
        TotalStore:=Log[CurrentLog].Total; Log[CurrentLog].Total:=0;
        for I:=1 to NumberofAccounts do
            Log[CurrentLog].Total:=Log[CurrentLog].Total+Data[I];
        WriteDIR;
        WGoto(3, 2);
        Write(Usr, 'MONTHLY SUMMARY       ');
        WGoto(42, 2);
        Write(Usr, 'MONTH: ', MonthNames[Log[CurrentLog].Date.Month],
            ', as of ', ShortDate(Log[CurrentLog].Date));
        repeat
            ReadKbd;
            case Key of
                KEY_UP :   GotoLine(TopLine-1);
                KEY_DN :   GotoLine(TopLine+1);
                KEY_HOME :   GotoLine(1);
                KEY_END :   GotoLine(DIRWindow);
                'p' :   PrintWind;
            end (* case *);
        until (Key = KEY_ESC);
        WGoto(3, 2);
        Write(Usr, 'DAILY INCOME REPORT');
        WGoto(42, 2);
        Write(Usr, 'DATE:                             ');
        Log[CurrentLog].Total := TotalStore;
end (* MonthSummary *);


procedure YearSummary;
var     TotalStore   : real;
begin   ChangeWindow(DIRWindow);
        Message('P = Print  ESC = Exit');
        for J := 1 to NumberofAccounts do
            Data[J] := 0;
        ReSet(DataFile);
        I := CurrentLog;
        repeat
            if (Log[I].DataPtr > 0) then begin
                Seek(DataFile, Log[I].DataPtr-1);
                Read(DataFile, AuxData);
                for J := 1 to NumberofAccounts do
                    Data[J] := Data[J]+AuxData[J];
            end (* if *);
            I := I-1;
        until (I < 0);
        TotalStore := Log[CurrentLog].Total;
        Log[CurrentLog].Total := 0;
        for I:=1 to NumberofAccounts do
            Log[CurrentLog].Total := Log[CurrentLog].Total+Data[I];
        WriteDIR;
        WGoto(3,2);
        Write(Usr,'YEARLY SUMMARY       ');
        WGoto(42,2);
        Write(Usr,'YEAR: ',Log[CurrentLog].Date.Year,
            ', as of ',ShortDate(Log[CurrentLog].Date));
        repeat
            ReadKbd;
            case Key of
                KEY_UP :   GotoLine(TopLine-1);
                KEY_DN :   GotoLine(TopLine+1);
                KEY_HOME :   GotoLine(1);
                KEY_END :   GotoLine(DIRWindow);
                'p' :   PrintWind;
            end (* case *);
        until (Key = KEY_ESC);
        WGoto(3, 2);
        Write(Usr, 'DAILY INCOME REPORT');
        WGoto(42, 2);
        Write(Usr, 'DATE:                             ');
        Log[CurrentLog].Total := TotalStore;
end (* YearlySummary *);
