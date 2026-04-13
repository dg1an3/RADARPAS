(* ia.pas *)
(* Copyright (C) 1985, 1996 Derek G Lane *)
(* Part of the SSM 1.5 Package *)

program IncomeAccount;

(*$I- *)
(*$V- *)

const   ModuleName =   'Income Account';
        Abbreviation =   'IA';

(*$I include.pas *)
(*$I utility.pas *)

(*$I iacustom.pas *)

(*$I iaedit.pas *)
(*$I iasummry.pas *)
(*$I iamenu.pas *)


var     OldDir :   LineType;

procedure ChangeDirectory(ToYear :   integer);
var     ToDir :   LineType;
begin   Str(ToYear, StrA);
        GetDir(DefaultDrive, OldDir);
        OldDir := Chr(64+DefaultDrive)+':\'+OldDir;
        ToDir := Data_Path+':\'+StrA+Abbreviation+'.'+SerialNumber;
        ChDir(ToDir);
        if (IOError = $01) then begin
            ErrorMsg('No data directory.  Press <+> to create directory');
            if (Key = '+') then begin
                MkDir(ToDir);
                ChDir(ToDir);
                ReWrite(LogFile);
                ReWrite(DataFile);
            end (* if *);
            ChDir(ToDir);
            if (IOError = $01) then begin
                ErrorMsg('Error creating the data directory');
                Quit;
            end (* if *);
        end (* if *);
end (* ChangeDirectory *);

procedure Quit;
begin   CloseLog;
        ChDir(OldDir);
        Assign(MenuProg, 'MENU.COM');
        Execute(MenuProg);
end (* Quit *);

begin   TextColor(NormColor);
        TextBackground(NormBack);
        UsrOutPtr := Ofs(ScreenOut);
        Assign(LogFile, 'LOG.DAT');
        Assign(DataFile, 'DATA.DAT');
        ChangeDirectory(TodaysDate.Year);
        LoadLog;
        MakeLog(TodaysDate);
        Window(1,1,80,25);
        ClrScr;
        InfoLine;
        MainMenu;
        Quit;
end (* IncomeAccount *).
