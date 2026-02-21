(* DrSum.pas *)
(* Copyright (C) 1985, 91  DG Lane *)

procedure MonthSummary;
var     TotalStore  : real;
begin   ChangeWindow(DRWindow);
        Message('P = Print  ESC = Exit');
        WGoto(20, 2);
        Write(Usr, 'MONTHLY SUMMARY for ');
        WGoto(40, 2);
        Write(Usr, MonthNames[Log[CurrentLog].Date.Month],
            ', as of ', ShortDate(Log[CurrentLog].Date));
        with Data do begin
            Shift := 0;
            Bal1 := 0; Chg1 := 0; ROA1 := 0; Total1 := 0;
            Cash := 0; Chks := 0; SubT := 0; PO := 0;
            Chg2 := 0; ManCC := 0; CC := 0; Total2 := 0;
            CCFee := 0; Bal2 := 0; Over := 0; Short := 0;
            Bal3 := 0;
            Gas := 0; Oil := 0; Acc := 0; Lab := 0; Snacks := 0;
            Emiss := 0; Kero := 0; Wrkr := 0; ROA2 := 0; Tax := 0;
            Total3 := 0;
        end (* with *);
        ReSet(DataFile);
        I := CurrentLog;
        repeat
            if Log[I].DataPtr > 0 then begin
                Seek(DataFile,Log[I].DataPtr-1);
                Read(DataFile,AuxData);
                with Data do begin
                    Bal1 := Bal1 + AuxData.Bal1;
                    Chg1 := Chg1 + AuxData.Chg1;
                    ROA1 := ROA1 + AuxData.ROA1;
                    Total1 := Total1 + AuxData.Total1;
                    Cash := Cash + AuxData.Cash;
                    Chks := Chks + AuxData.Chks;
                    SubT := SubT + AuxData.SubT;
                    PO := PO + AuxData.PO;
                    Chg2 := Chg2 + AuxData.Chg2;
                    ManCC := ManCC + AuxData.ManCC;
                    CC := CC + AuxData.CC;
                    Total2 := Total2 + AuxData.Total2;
                    CCFee := CCFee + AuxData.CCFee;
                    Bal2 := Bal2 + AuxData.Bal2;
                    Over := Over + AuxData.Over;
                    Short := Short + AuxData.Short;
                    Bal3 := Bal3 + AuxData.Bal3;
                    Gas := Gas + AuxData.Gas;
                    Oil := Oil + AuxData.Oil;
                    Acc := Acc + AuxData.Acc;
                    Lab := Lab + AuxData.Lab;
                    Snacks := Snacks + AuxData.Snacks;
                    Emiss := Emiss + AuxData.Emiss;
                    Kero := Kero + AuxData.Kero;
                    Wrkr := Wrkr + AuxData.Wrkr;
                    ROA2 := ROA2 + AuxData.ROA2;
                    Tax := Tax + AuxData.Tax;
                    Total3 := Total3 + AuxData.Total3;
                end (* with *);
            end (* if *);
            I := I - 1;
        until (Log[I].Date.Month <> Log[CurrentLog].Date.Month);
        WriteDIR;
        WGoto(20,2);
        Write(Usr,'MONTHLY SUMMARY for ');
        WGoto(40,2);
        Write(Usr,MonthNames[Log[CurrentLog].Date.Month],
            ', as of ',ShortDate(Log[CurrentLog].Date));
        repeat
            ReadKbd;
            case Key of
                #72  : GotoLine(TopLine - 1);
                #80  : GotoLine(TopLine + 1);
                #71  : GotoLine(1);
                #79  : GotoLine(DIRWindow);
                'p'  : PrintWind;
            end (* case *);
         until (Key = #27);
         WGoto(20, 2);
         Write(Usr, '               DAILY REPORT                 ');
end (* MonthSummary *);

procedure YearSummary;
var     TotalStore  : real;
begin   ChangeWindow(DRWindow);
        Message('P = Print  ESC = Exit');
        WGoto(20, 2);
        Write(Usr, ' YEARLY SUMMARY for ');
        WGoto(40, 2);
        Write(Usr, Log[CurrentLog].Date.Year,
            ', as of ', ShortDate(Log[CurrentLog].Date));
        with Data do begin
            Shift := 0;
            Bal1 := 0; Chg1 := 0; ROA1 := 0; Total1 := 0;
            Cash := 0; Chks := 0; SubT := 0; PO := 0;
            Chg2 := 0; ManCC := 0; CC := 0; Total2 := 0;
            CCFee := 0; Bal2 := 0; Over := 0; Short := 0;
            Bal3 := 0;
            Gas := 0; Oil := 0; Acc := 0; Lab := 0; Snacks := 0;
            Emiss := 0; Kero := 0; Wrkr := 0; ROA2 := 0; Tax := 0;
            Total3 := 0;
        end (* with *);
        ReSet(DataFile);
        I := CurrentLog;
        repeat
            if (Log[I].DataPtr > 0) then begin
                Seek(DataFile, Log[I].DataPtr-1);
                Read(DataFile, AuxData);
                with Data do begin
                    Bal1 := Bal1 + AuxData.Bal1;
                    Chg1 := Chg1 + AuxData.Chg1;
                    ROA1 := ROA1 + AuxData.ROA1;
                    Total1 := Total1 + AuxData.Total1;
                    Cash := Cash + AuxData.Cash;
                    Chks := Chks + AuxData.Chks;
                    SubT := SubT + AuxData.SubT;
                    PO := PO + AuxData.PO;
                    Chg2 := Chg2 + AuxData.Chg2;
                    ManCC := ManCC + AuxData.ManCC;
                    CC := CC + AuxData.CC;
                    Total2 := Total2 + AuxData.Total2;
                    CCFee := CCFee + AuxData.CCFee;
                    Bal2 := Bal2 + AuxData.Bal2;
                    Over := Over + AuxData.Over;
                    Short := Short + AuxData.Short;
                    Bal3 := Bal3 + AuxData.Bal3;
                    Gas := Gas + AuxData.Gas;
                    Oil := Oil + AuxData.Oil;
                    Acc := Acc + AuxData.Acc;
                    Lab := Lab + AuxData.Lab;
                    Snacks := Snacks + AuxData.Snacks;
                    Emiss := Emiss + AuxData.Emiss;
                    Kero := Kero + AuxData.Kero;
                    Wrkr := Wrkr + AuxData.Wrkr;
                    ROA2 := ROA2 + AuxData.ROA2;
                    Tax := Tax + AuxData.Tax;
                    Total3 := Total3 + AuxData.Total3;
                end (* with *);
            end (* if *);
            I := I - 1;
        until (I < 0);
        WriteDIR;
        WGoto(20, 2);
        Write(Usr, ' YEARLY SUMMARY for ');
        WGoto(40, 2);
        Write(Usr, Log[CurrentLog].Date.Year,
            ', as of ', ShortDate(Log[CurrentLog].Date));
        repeat
        ReadKbd;
        case Key of
            #72  : GotoLine(TopLine - 1);
            #80  : GotoLine(TopLine + 1);
            #71  : GotoLine(1);
            #79  : GotoLine(DIRWindow);
            'p'  : PrintWind;
        end (* case *);
        until (Key = #27);
        WGoto(20, 2);
        Write(Usr, '               DAILY REPORT                 ');
end (* YearSummary *);
