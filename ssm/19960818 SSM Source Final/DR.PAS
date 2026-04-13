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
(*$I Dateutil.pas *)
(*$I Diskutil.pas *)
(*$I UiUtil.pas *)

(*$I DrCustom.pas *)
(*$I DrForm.pas *)
(*$I DrSum.pas *)
(*$I DrLog.pas *)

var     OldDir  : LongStr;

procedure Quit;
begin   CloseLog;
        ChDir(OldDir);
        Assign(MenuProg,'MENU.COM');
        Execute(MenuProg);
end (* Quit *);

procedure ChangeDirectory(ToYear  : integer);
var     key  : char;
        escFlag  : boolean;
begin   Str(ToYear, StrA);
        GetDir(DefaultDrive, OldDir);
        OldDir := Chr(64+DefaultDrive)+':\';
        ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
        if (IOResult = $01) then begin
            Message('No data directory.  Press <+> to create directory');
            ReadKbd(key, escFlag);
            if (key = '+') then begin
                MkDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
                ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
                ReWrite(LogFile);
                ReWrite(DataFile);
            end (* if *);
            ChDir(DATA_PATH+StrA+Abbreviation+'.'+SERIAL_NUMBER);
            if (IOResult = $01) then
                Quit;
        end (* if *);
end (* ChangeDirectory *);

begin   TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
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