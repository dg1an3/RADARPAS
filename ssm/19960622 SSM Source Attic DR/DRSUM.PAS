(*  DataRec          = RECORD
    Shift          :   INTEGER;
    Bal1, Chg1, ROA1, Total1  :  REAL;
    Cash, Chks, SubT, PO, Chg2, ManCC, CC, Total2, CCFee,
        Bal2, Over, Short, Bal3  :  REAL;
    Gas, Oil, Acc, Lab, Snacks, Emiss, Kero, Wrkr, ROA2,
        Tax, Total3  :  REAL;
  END; *)


PROCEDURE MonthSummary;

  VAR TotalStore   : REAL;

  BEGIN
    ChangeWindow(DRWindow);
    Message('P = Print  ESC = Exit');
    WGoto(20,2);Write(Usr,'MONTHLY SUMMARY for ');
    WGoto(40,2);Write(Usr,MonthNames[Log[CurrentLog].Date.Month],
      ', as of ',ShortDate(Log[CurrentLog].Date));
    WITH Data DO BEGIN
        Shift := 0;
        Bal1 := 0; Chg1 := 0; ROA1 := 0; Total1 := 0;
        Cash := 0; Chks := 0; SubT := 0; PO := 0;
        Chg2 := 0; ManCC := 0; CC := 0; Total2 := 0;
        CCFee := 0; Bal2 := 0; Over := 0; Short := 0;
        Bal3 := 0;
        Gas := 0; Oil := 0; Acc := 0; Lab := 0; Snacks := 0;
        Emiss := 0; Kero := 0; Wrkr := 0; ROA2 := 0; Tax := 0;
        Total3 := 0;
    END (* WITH *);
    ReSet(DataFile);
    I:=CurrentLog;
    REPEAT
      IF Log[I].DataPtr > 0 THEN BEGIN
        Seek(DataFile,Log[I].DataPtr-1);
        Read(DataFile,AuxData);
        WITH Data DO BEGIN
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
        END (* WITH *);
      END;
      I:=I-1;
    UNTIL Log[I].Date.Month<>Log[CurrentLog].Date.Month;
    WriteDIR;
    WGoto(20,2);Write(Usr,'MONTHLY SUMMARY for ');
    WGoto(40,2);Write(Usr,MonthNames[Log[CurrentLog].Date.Month],
      ', as of ',ShortDate(Log[CurrentLog].Date));
    REPEAT
      ReadKbd;
      CASE Key of
        #72        : GotoLine(TopLine-1);
        #80        : GotoLine(TopLine+1);
        #71        : GotoLine(1);
        #79        : GotoLine(DIRWindow);
        'p'        : PrintWind;
      END;
    UNTIL Key=#27;
    WGoto(20,2);Write(Usr,'               DAILY REPORT                 ');
  END;


PROCEDURE YearSummary;

  VAR TotalStore   : REAL;

  BEGIN
    ChangeWindow(DRWindow);
    Message('P = Print  ESC = Exit');
    WGoto(20,2);Write(Usr,' YEARLY SUMMARY for ');
    WGoto(40,2);Write(Usr,Log[CurrentLog].Date.Year,
      ', as of ',ShortDate(Log[CurrentLog].Date));
    WITH Data DO BEGIN
        Shift := 0;
        Bal1 := 0; Chg1 := 0; ROA1 := 0; Total1 := 0;
        Cash := 0; Chks := 0; SubT := 0; PO := 0;
        Chg2 := 0; ManCC := 0; CC := 0; Total2 := 0;
        CCFee := 0; Bal2 := 0; Over := 0; Short := 0;
        Bal3 := 0;
        Gas := 0; Oil := 0; Acc := 0; Lab := 0; Snacks := 0;
        Emiss := 0; Kero := 0; Wrkr := 0; ROA2 := 0; Tax := 0;
        Total3 := 0;
    END (* WITH *);
    ReSet(DataFile);
    I:=CurrentLog;
    REPEAT
      IF Log[I].DataPtr > 0 THEN BEGIN
        Seek(DataFile,Log[I].DataPtr-1);
        Read(DataFile,AuxData);
        WITH Data DO BEGIN
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
        END (* WITH *);
      END;
      I:=I-1;
    UNTIL I<0;
    WriteDIR;
    WGoto(20,2);Write(Usr,' YEARLY SUMMARY for ');
    WGoto(40,2);Write(Usr,Log[CurrentLog].Date.Year,
      ', as of ',ShortDate(Log[CurrentLog].Date));
    REPEAT
      ReadKbd;
      CASE Key of
        #72        : GotoLine(TopLine-1);
        #80        : GotoLine(TopLine+1);
        #71        : GotoLine(1);
        #79        : GotoLine(DIRWindow);
        'p'        : PrintWind;
      END;
    UNTIL Key=#27;
    WGoto(20,2);Write(Usr,'               DAILY REPORT                 ');
  END;