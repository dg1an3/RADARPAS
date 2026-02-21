(* Menu.pas  Copyright (C) 1985, 91 DG Lane *)

program MainMenu;

(*$I- *)
(*$C- *)
(*$V- *)
(*$K- *)

const   MODULE_NAME = 'Service Station Manager 1.6HD';
        ABBREVIATION = 'SSM';

(*$I Include.pas *)
(*$I DateUtil.pas *)
(*$I DiskUtil.pas *)

const   MainMenu  : byte = 23;
        MainMenuScr  : array [1..23, 1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                                                                            บ',
'บ                          SERVICE STATION MANAGER                           บ',
'บ                                                                            บ',
'บ                               VERSION 1.6HD                                บ',
'บ                                                                            บ',
'ฬออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ                        St. Andrew`s Texaco                                 บ',
'บ                        2000 Campus Drive                                   บ',
'บ                        St. Charles, MO  63301                              บ',
'ฬอออออออออออออออออัอออออออออออออออออออออออออออออออออออออัออออออออออออออออออออน',
'บ            PRESSณ MAIN FUNCTIONS                 PRESSณ UTILITIES          บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ              F1 ณ Fuel Inventory Manager           F7 ณ Backup data        บ',
'บ              F2 ณ Income Account                   F8 ณ Restore data       บ',
'บ              F3 ณ Accounts Payable                    ณ                    บ',
'บ              F4 ณ Accounts Receivable                 ณ                    บ',
'บ              F5 ณ Mailing Label Printing            D ณ Change Date        บ',
'บ              F6 ณ Daily Report                    ESC ณ Exit               บ',
'บ                 ณ                                     ณ                    บ',
'ฬอออออออออออออออออฯอออออออออออออออออออออออออออออออออออออฯออออออออออออออออออออน',
'บ Copyright (C) 1985-96  DG Lane                                       SN102 บ',
'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');

(*$I UiUtil.pas *)
(*$I Backup.pas *)

procedure SetDate(var ForDay : DateRec);
var     Dateinput  : string[8];
        Timeinput  : string[8];
        Right      : boolean;
        Number     : integer;
        NextChar   : integer;
begin   Frame(30, 12, 50, 15);
        ClrScr;
        Cursor(0,7);
        GotoXY(1,1);
        Write('DATE: ');
        Readln(StrA);
        GotoXY(1,2);
        Write('TIME: ');
        Readln(StrB);
        ParseDate(StrA, StrB, TodaysDate, Right);
        Cursor(16,0);
end (* SetDate *);

procedure Quit;
begin   Password := '';
        Cursor(6,7);
        ClrScr;
end (* Quit *);

var     key  : char;
        escFlag  : boolean;
        NxtProg  : file;
begin   TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
        Cursor(16, 0);
        Window(1,1,80,25);
        ClrScr;
        ChangeStatus := true;
        ChangeWindow(MainMenu);
        if (DateEntered <> 147) then begin
            GetSysDate(TodaysDate);
            if (TodaysDate.year < 1984) then
                SetDate(TodaysDate);
            DateEntered := 147;
            Infoline;
            if IsNewYear then
                NewYear;
            (* else
                CheckForOldData; *)
        end else
            Infoline;
        GotoXY(1, 24);
        repeat
            ReadKbd(key, escFlag);
            case key of
                KEY_F1  : Assign(NxtProg, 'FIM.CHN');
                KEY_F2  : Assign(NxtProg, 'IA.CHN');
                KEY_F3  : Assign(NxtProg, 'AP.CHN');
                KEY_F4  : Assign(NxtProg, 'AR.CHN');
                KEY_F5  : Assign(NxtProg, 'MAIL.CHN');
                KEY_F6  : Assign(NxtProg, 'DR.CHN');
                KEY_F7  : Backup;
                KEY_F8  : Restore;
                'd'  : begin
                           SetDate(TodaysDate);
                           ChangeWindow(MainMenu);
                           InfoLine;
                           GotoXY(1, 24);
                           ClrEol;
                       end;
            end (* case *);
            if key in [KEY_F1..KEY_F6] then begin
                Chain(NxtProg);
                if (IOResult = $01) then begin
                    ErrorMsg('Program file not found.  ' +
                        'Please contact software vendor');
                    ChangeWindow(MainMenu);
                end (* if *);
            end (* if *);
        until (Key = KEY_ESC);
        Quit;
end (* Menu *).