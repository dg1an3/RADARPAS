(* Fim.pas  Copyright (C) 1986, 96  DG Lane *)

program FuelInventoryManager;

(*$I- *)
(*$V- *)
(*$U- *)

const   MODULE_NAME  = 'Fuel Inventory Manager';
        ABBREVIATION  = 'FIM';

(*$I Include.pas *)

(*$I Utility.pas *)

(* $I DateUtil.pas *)
(* $I DiskUtil.pas *)
(* $I UiUtil.pas *)

(*$I FiCustom.pas *)
(*$I FiMenu.pas *)
(*$I FiTR.pas *)
(*$I FiMMP.pas *)

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
        ChDir(DATA_PATH+StrA+ABBREVIATION+'.'+SERIAL_NUMBER);
        if (IOResult <> $00) then begin
            Message('No data directory.  Press <+> to create directory');
            ReadKbd;
            if (key = '+') THEN BEGIN
                Message('CREATING NEW ACCOUNT FILE');
                Writeln(DATA_PATH+StrA+ABBREVIATION+'.'+SERIAL_NUMBER);
                ReadKbd;
                MkDir(DATA_PATH+StrA+ABBREVIATION+'.'+SERIAL_NUMBER);
                ChDir(DATA_PATH+StrA+ABBREVIATION+'.'+SERIAL_NUMBER);
                ReWrite(LogFile);
                ReWrite(TRFile);
                ReWrite(PriceFile);
                ReWrite(MMPFile);
            end;
            ChDir(DATA_PATH+StrA+ABBREVIATION+'.'+SERIAL_NUMBER);
            if (IOResult <> $00) then Quit;
        end (* if *);
end (* ChangeDirectory *);

procedure AssignFiles;
begin   Line:='Be sure the program disk is in drive B';CaseErr:=$0101;
        Assign(LogFile,'LOG.DAT');
        Assign(TRFile,'TR.DAT');
        Assign(PriceFile,'PRICE.DAT');
        Assign(MMPFile,'MMP.DAT');
end (* AssignFiles *);

begin   (* if (DateEntered <> 147) then
            GetSysDate(TodaysDate); *)
        ChangeStatus := true;
        TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
        OneMoment;
        Cursor(0,7);
        UsrOutPtr:=Ofs(ScreenOut);
        AssignFiles;
        ChangeDirectory(TodaysDate.Year);
        LoadLog;
        MakeLog(TodaysDate);
        Window(1,1,80,25);
        ClrScr;
        InfoLine;
        MainMenu;
        Cursor(0,7);
        Quit;
end (* FuelInventoryManager *).
