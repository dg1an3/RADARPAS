(* ArBill.pas *)
(* Copyright (C) 1985, 1996 Derek G. Lane *)

procedure PrintCheckOrBill(var acct  : AcctRec;
        var transl  : TransList; var numTrans  : integer);
var     currTrans  : integer;
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
                ShortDate(transl[numTrans].Date));
            WriteLn(Lst, '      ', name);
            WriteLn(Lst, '      ', address);
            WriteLn(Lst, '      ', city);
            WriteLn(Lst);
        end (* with *);
        currTrans := numTrans;
        while (transl[currTrans].date.month = transl[numTrans].date.month) and
                (currTrans >= 1) do
            currTrans := currTrans - 1;
        WriteLn(Lst, '                                        ',
            '---------------------------');
        WriteLn(Lst, '                                        ',
            'PREVIOUS BALANCE : ', transl[currTrans].Balance:8:2);
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