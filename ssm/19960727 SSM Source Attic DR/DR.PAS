(* Dr.pas *)
(* Copyright (C) 1985, 1996 Derek G. Lane *)

program DailyReport;

(*$I-   Reset doesn't work in SaveAcct with I+ *)
(*$U-   Escape codes don't work without this option off *)
(*$V-   Check this *)
(*$R-   MatchLog doesn't work right with R+ *)

const   MODULE_NAME = 'Daily Report';
        ABBREVIATION = 'DR';

(*$I Include.pas *)
(*$I Utility.pas *)

(*$I DrCustom.pas *)

(*$I DrForm.pas *)
(*$I DrSum.pas *)
(*$I DrLog.pas *)

var     OldDir  : LongStr;

procedure ChangeDirectory(ToYear  : integer);
begin   Str(ToYear, StrA);
        GetDir(DefaultDrive, OldDir);
        OldDir := Chr(64+DefaultDrive)+':\';
        ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
        if (IOError = $01) then begin
            ErrorMsg('No data directory.  Press <+> to create directory');
            if (Key = '+') then begin
                MkDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
                ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
                ReWrite(LogFile);
                ReWrite(DataFile);
            end (* if *);
            ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
            if (IOError = $01) then
                Quit;
        end (* if *);
end (* ChangeDirectory *);

procedure Quit;
begin   CloseLog;
        ChDir(OldDir);
        Assign(MenuProg,'MENU.COM');
        Execute(MenuProg);
end (* Quit *);

begin   TextColor(NormColor);
        TextBackground(NormBack);
        UsrOutPtr := Ofs(ScreenOut);
        Assign(LogFile, 'log.dat');
        Assign(DataFile, 'data.dat');
        ChangeDirectory(TodaysDate.Year);
        LoadLog;
        MakeLog(TodaysDate);
        Window(1,1,80,25);
        ClrScr;
        InfoLine;
        MainMenu;
        Quit;
end (* DailyReport *).
