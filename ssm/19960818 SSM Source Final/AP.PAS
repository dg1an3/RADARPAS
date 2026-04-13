(* Ap.pas *)
(* Copyright (C) 1985, 1996 Derek G. Lane *)

program AccountsPayable;

(*$I-   Reset doesn't work in SaveAcct with I+ *)
(*$U-   Escape codes don't work without this option off *)
(*$V-   Check this *)
(*$R-   ParseDate doesn't work right with R+ *)

const   MODULE_NAME = 'Accounts Payable';
        ABBREVIATION = 'AP';

(*$I Include.pas *)
(*$I DateUtil.pas *)
(*$I DiskUtil.pas *)

(*$I ApCustom.pas *)

(*$I UiUtil.pas *)

(*$I AxTrans.pas *)
(*$I AxAcct.pas *)
(*$I ApCheck.pas *)

procedure Quit; forward;

(*$I AxLedger.pas *)

function FullPath  : LongStr;
var     yearStr  : ShortStr;
begin   Str(TodaysDate.year, yearStr);
        FullPath := DATA_PATH+yearStr+ABBREVIATION+'.'+SERIAL_NUMBER+'\';
end (* FullPath *);

procedure Quit;
var     menuCom  : file;
begin   Assign(menuCom, 'menu.com');
        Execute(menuCom);
end (* Quit *);

var     myLedger  : LedgerRec;

begin   if (DateEntered <> 147) then
            GetSysDate(TodaysDate);
        TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
        UsrOutPtr := Ofs(ScreenOut);
        Window(1, 1, 80, 25);
        ClrScr;
        InfoLine;
        InitLedger(myLedger, FullPath);
        Cursor(16, 0);
        ViewLedger(myLedger);
        Cursor(0, 7);
        Quit;
end (* AccountsPayable *).
