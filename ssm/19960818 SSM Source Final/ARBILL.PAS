(* ArBill.pas *)
(* Copyright (C) 1985, 1996 Derek G. Lane *)

procedure PrintCheckOrBill(var acct  : AcctRec;
        var transl  : TransList; var numTrans  : integer);
var     currTrans  : integer;
        sinceDay  : integer;
begin   (* LoadEntries; *)
        with acct do begin
            WriteLn(Lst,'                               S T A T E M E N T');
            WriteLn(Lst);
            WriteLn(Lst, '------------------------------------------------',
                '------------------------------');
            WriteLn(Lst, '  ', COMP_NAME);
            WriteLn(Lst, '  ', COMP_ADDR);
            WriteLn(Lst, '  ', COMP_CITY);
            WriteLn(Lst, '------------------------------------------------',
                '------------------------------');
            WriteLn(Lst);
            WriteLn(Lst,'                           ',
                '**** DUE BY THE 10th ****');
            WriteLn(Lst);
            WriteLn(Lst,'      ACCOUNT #', Number,
                '                           DATE : ',
                ShortDate(TodaysDate));
            WriteLn(Lst, '      ', name);
            WriteLn(Lst, '      ', address);
            WriteLn(Lst, '      ', city);
            WriteLn(Lst);
        end (* with *);
        currTrans := numTrans;
        if (TodaysDate.month > 2) then
            sinceDay := DaysinMonth[TodaysDate.month-1]
        else if (TodaysDate.month = 1) then
            sinceDay := 31    (* December *)
        else if (TodaysDate.year mod 4 = 0) then
            sinceDay := 29    (* Leap year *)
        else
            sinceDay := 28;
        while (SubDates(TodaysDate, transl[currTrans].date) <= sinceDay) and
                (currTrans > 1) do
            currTrans := currTrans - 1;
        WriteLn(Lst, '                                        ',
            '---------------------------');
        Write(Lst, '                                        ',
            'PREVIOUS BALANCE : ');
        if (SubDates(TodaysDate, transl[currTrans].date) <= sinceDay) then
                begin
            Writeln(Lst, 0.0:8:2);
            currTrans := 0;
        end else
            Writeln(Lst, transl[currTrans].Balance:8:2);
        WriteLn(Lst, '                                        ',
            '---------------------------');
        WriteLn(Lst);
        WriteLn(Lst,'          DATE     DESCRIPTION                       ',
            'DEBIT   CREDIT');
        WriteLn(Lst,'          -------------------------------------------',
            '--------------');
        while (currTrans < numTrans) do begin
            currTrans := currTrans + 1;
            with transl[currTrans] do begin
                Write(Lst, '          ', ShortDate(date), ' ');
                Write(Lst, description);
                Write(Lst, Copy('                               ',
                    1, 31-Length(description)));
                if (amount >= 0) then
                    Writeln(Lst, amount:8:2, ' ')
                else
                    Writeln(Lst, '         ', -amount:8:2);
            end (* with *);
        end (* while *);
        WriteLn(Lst, '          -------------------------------------',
            '--------------------');
        Write(Lst, '                                                 ',
            'BALANCE : ');
        WriteLn(Lst, transl[currTrans].balance:8:2);
        Write(Lst, ^L);
end (* PrintCheckOrBill *);


