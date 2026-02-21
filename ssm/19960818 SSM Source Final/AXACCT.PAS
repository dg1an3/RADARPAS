(* AxAcct.pas *)
(* Copyright (C) 1985,1996 Derek G. Lane *)

type    AcctRec  = record
            number  : integer;
            name  : string[40];
            address  : string[40];
            city  : string[30];
            phone  : string[15];
            balance   : real;
            gt30   : real;
            gt60   : real;
        end (* AcctRec *);

procedure UpdateAcct(var acct  : AcctRec;
            var transl  : TransList; numTrans  : integer);
var     runBal  : real;
        count  : integer;
begin   for count := 1 to numTrans do
            with transl[count] do
                if (count > 1) then
                    balance := transl[count-1].balance + amount
                else
                    balance := amount;
        if (numTrans > 0) then
            acct.balance := transl[numTrans].balance
        else
            acct.balance := 0;
        runBal := acct.balance;
        acct.gt30 := 0.0;
        acct.gt60 := 0.0;
        count := numTrans;
        while (runBal > 0.0) and (count > 0) and (acct.gt60 = 0.0)
                do begin
            if (transl[count].amount > 0) then begin
                if (SubDates(TodaysDate, transl[count].Date) > 30) and
                        (acct.gt30 = 0.0) then
                    acct.GT30 := runBal;
                if (SubDates(TodaysDate, transl[count].Date) > 60) and
                        (acct.gt60 = 0.0) then
                    acct.GT60 := runBal;
                runBal := runBal - transl[count].Amount; (****)
            end (* if *);
            count := count - 1;
        end (* while *);
end (* UpdateAcc *);

procedure SaveAcct(fileName  : LongStr;  acct  : AcctRec;
            var transl  : TransList;  numTrans  : integer);
var     acctFile  : file of AcctRec;
begin   Assign(acctFile, fileName);
        ReSet(acctFile);
        if (IOResult <> 0) then
            ReWrite(acctFile);
        Write(acctFile, acct);
        Close(acctFile);
        SaveTrans(fileName, transl, numTrans);
end (* SaveAcct *);

procedure DrawAcctLine(acct  : AcctRec;  row  : integer;
            hiliteFlag  : boolean);
begin   if hiliteFlag then begin
            TextColor(HILITE_COLOR);
            TextBackground(HILITE_BACKG);
        end (* if *);
        with acct do begin
            GotoXY(1, row);
            ClrEOL;
            (* if (ForAcct < 1) or (ForAcct > lastAcct) then
                Exit; *)
            Write(Number :6, '   ', Name);
            GotoXY(50, WhereY);
            Write(Balance :8:2);
            if (GT30 > 0.0) then
                Write(GT30 :9:2)
            else
                Write('       --');
            if (GT60 > 0.0) then
                Write(GT60 :9:2)
            else
                Write('       --');
        end (* with *);
        if hiliteFlag then begin
            TextColor(NORM_COLOR);
            TextBackground(NORM_BACKG);
        end (* if *);
end (* DrawAcctLine *);

procedure DrawAcct(acct  : AcctRec;
            var transl  : TransList; numTrans  : integer;
            currTrans  : integer);
var     count  : integer;
begin   ChangeWindow(AccountWindow);
        Window(4, 2, 55, 5);
        ClrScr;
        with acct do begin
            Writeln('ACCOUNT NUMBER ', number);
            Writeln(name);
            Writeln(address);
            Write(city);
            GotoXY(36, 4);    (****)
            Write(phone);
        end (* with *);
        Window(3, 9, 77, 22);
        for count := -AboveEntry to BelowEntry do begin
            if (currTrans+count > 0) and (currTrans+count <= numTrans) then
                DrawTrans(transl[currTrans+count],
                    AboveEntry+count, (count = 0));
        end (* for *);
        (* HiLiteEntry; *)
end (* DrawAcct *);

procedure PrintAcct(var acct  : AcctRec;
            var transl  : TransList; numTrans  : integer);
var     count  : integer;
        debit, credit  : real;
begin   Message('Printing account...');
        with acct do begin
            Writeln(lst, MODULE_NAME);
            Writeln(lst, 'ACCOUNT NUMBER ', number);
            Writeln(lst, name);
            Writeln(lst, address);
            Writeln(lst, city, Copy('                               ',
                1, 31-Length(city)), phone);
        end (* with *);
        Writeln(lst, '--------------------------------------------------' +
            '------------------------------');
        Writeln(lst, 'DATE     DESCRIPTION                              ' +
            '   DEBIT   CREDIT  BALANCE');
        debit := 0;
        credit := 0;
        for count := 1 to numTrans do
            with transl[count] do begin
                Write(lst, ShortDate(date), ' ');
                Write(lst, description);
                Write(lst, Copy('                                        ',
                    1, 40-Length(description)));
                if (amount >= 0) then begin
                    Write(lst, ' ', amount :8:2, '          ');
                    debit := debit + amount;
                end else begin
                    Write(lst, '          ', -Amount :8:2, ' ');
                    credit := credit + -amount;
                end (* if *);
                Writeln(lst, balance :8:2);
            end (* with *);
        Writeln(lst, '--------------------------------------------------' +
            '------------------------------');
        Write(lst, '         ');
        Write(lst, '                                        ');
        Writeln(lst, ' ', debit:8:2, ' ', credit:8:2, ' ',
            acct.balance:8:2);
        Writeln(lst, '--------------------------------------------------' +
            '------------------------------');
        Writeln(lst, ^L);
end (* PrintAcct *);

procedure ViewAcct(var acct  : AcctRec;
            var transl  : TransList; var numTrans  : integer);
var     currTrans, prevTrans  : integer;
        key  : char;
        escFlag  : boolean;
        newTrans  : TransRec;
begin   currTrans := numTrans;
        DrawAcct(acct, transl, numTrans, currTrans);
        repeat
            ReadKbd(key, escFlag);
            prevTrans := currTrans;
            case Key of
                KEY_F1  : if (numTrans < MAX_TRANS) then begin
                    newTrans.date := TodaysDate;
                    newTrans.description := '';
                    newTrans.amount := 0.0;
                    newTrans.balance := acct.balance;
                    AddTrans(transl, numTrans, newTrans, currTrans);
                    DrawAcct(acct, transl, numTrans, currTrans);
                    EditTrans(newTrans, AboveEntry);
                    DelTrans(transl, numTrans, currTrans);
                    if (newTrans.amount <> 0.0) then
                        AddTrans(transl, numTrans, newTrans, currTrans)
                    else
                        currTrans := numTrans;
                    UpdateAcct(acct, transl, numTrans);
                    DrawAcct(acct, transl, numTrans, currTrans);
                    prevTrans := currTrans;
                end else begin
                    ErrorMsg('Transaction limit exceeded. ' +
                        'Please contact software vendor.');
                    DrawAcct(acct, transl, numTrans, currTrans);
                end (* KEY_F1 *);
                KEY_F2  :  if (numTrans > 0) then begin
                    Message('Delete this transaction (Y/N)?');
                    ReadKbd(key, escFlag);
                    Message('');
                    if (key = 'y') or (key = 'Y') then
                        DelTrans(transl, numTrans, currTrans);
                    UpdateAcct(acct, transl, numTrans);
                    DrawAcct(acct, transl, numTrans, currTrans);
                    prevTrans := currTrans;
                end (* KEY_F2 *);
                KEY_F3  : if (numTrans > 0) then begin
                    EditTrans(transl[currTrans], AboveEntry);
                    newTrans := transl[currTrans];
                    DelTrans(transl, numTrans, currTrans);
                    if (newTrans.amount <> 0.0) then
                        AddTrans(transl, numTrans, newTrans, currTrans)
                    else
                        currTrans := numTrans;
                    UpdateAcct(acct, transl, numTrans);
                    DrawAcct(acct, transl, numTrans, currTrans);
                    prevTrans := currTrans;
                end (* KEY_F3 *);
                KEY_F4  : if (numTrans > 0) then begin
                    PrintAcct(acct, transl, numTrans);
                    DrawAcct(acct, transl, numTrans, currTrans);
                end (* KEY_F4 *);
                KEY_UP  : if (currTrans > 1) then
                    currTrans := currTrans - 1;
                KEY_DN  : if (currTrans < numTrans) then
                    currTrans := currTrans + 1;
                KEY_HOME  : currTrans := 1;
                KEY_END  : currTrans := numTrans;
                KEY_PGUP  : if (currTrans - (AboveEntry+BelowEntry) >= 0) then
                    currTrans := currTrans - (AboveEntry+BelowEntry)
                else
                    currTrans := 1;
                KEY_PGDN  : if (currTrans + (AboveEntry+BelowEntry) <=
                        numTrans) then
                    currTrans := currTrans + (AboveEntry+BelowEntry)
                else
                    currTrans := numTrans;
            end (* case *);
            if (numTrans > 0) then begin
                DrawTrans(transl[prevTrans], AboveEntry, false);
                while (prevTrans > currTrans) do begin
                    GotoXY(1, 0);
                    InsLine;
                    if (prevTrans-AboveEntry-1 > 0) then
                        DrawTrans(transl[prevTrans-AboveEntry-1], 0, false)
                    else begin
                        Write('         ³                                ³');
                        Write('          ³          ³         ');
                    end (* if *);
                    prevTrans := prevTrans - 1;
                end (* while *);
                while (prevTrans < currTrans) do begin
                    GotoXY(1, 0);
                    DelLine;
                    if (prevTrans+BelowEntry+1 <= numTrans) then
                        DrawTrans(transl[prevTrans+BelowEntry+1],
                            AboveEntry+BelowEntry, false)
                    else begin
                        GotoXY(1, AboveEntry+BelowEntry);
                        Write('         ³                                ³');
                        Write('          ³          ³         ');
                    end (* if *);
                    prevTrans := prevTrans + 1;
                end (* while *);
                DrawTrans(transl[currTrans], AboveEntry, true);
            end (* if *);
        until (key = KEY_ESC);
end (* ViewAcct *);

procedure EditAcct(var acct  : AcctRec;
            var transl  : TransList;  numTrans  : integer);
var     atField, nextChar  : integer;
        key  : char;
        escFlag, decPoint  : boolean;
        value  : ShortStr;
        oldAcct  : AcctRec;
begin   DrawAcct(acct, transl, numTrans, numTrans);
        Window(1, 1, 80, 25);
        oldAcct := acct;
        atField := 1;
        with acct do
            repeat
                case atField of
                    1  : HiLiteCell(19, 2, 4);
                    2  : HiLiteCell(4, 3, 40);
                    3  : HiLiteCell(4, 4, 40);
                    4  : HiLiteCell(4, 5, 30);
                    5  : HiLiteCell(39, 5, 15);
                end (* case *);
                ReadKbd(key, escFlag);
                case atField of
                    1  : LoLiteCell(19, 2, 4);
                    2  : LoLiteCell(4, 3, 40);
                    3  : LoLiteCell(4, 4, 40);
                    4  : LoLiteCell(4, 5, 30);
                    5  : LoLiteCell(39, 5, 15);
                end (* case *);
                if escFlag then begin
                    case key of
                        KEY_RT, KEY_DN  : if (atField < 5) then
                            atField := atField+1;
                        KEY_LT, KEY_UP, KEY_BACKTAB  : if (atField > 1) then
                            atField := atField-1;
                    end (* case *);
                end else begin
                    case key of
                        KEY_ENTER  : if (atField < 6) then
                            atField := atField + 1;
                        KEY_TAB  : if (atField < 5) then
                            atField := atField + 1;
                        ' '..'~'  : begin
                            case atField of
                                1  : if (key in ['0'..'9']) then begin
                                    value := EnterCell(19, 2, 4,
                                        ['0'..'9'], key, decPoint);
                                    Val(value, number, nextChar);
                                end else
                                    atField := 0;
                                2  : name := EnterCell(4, 3, 40,
                                        [' '..'~'], key, decPoint);
                                3  : address := EnterCell(4, 4, 40,
                                        [' '..'~'], key, decPoint);
                                4  : city := EnterCell(4, 5, 30,
                                        [' '..'~'], key, decPoint);
                                5  : phone := EnterCell(39, 5, 15,
                                        [' '..'~'], key, decPoint);
                            end (* case *);
                            DrawAcct(acct, transl, numTrans, numTrans);
                            Window(1, 1, 80, 25);
                            atField := atField+1;
                        end (* ' '..'~' *);
                    end (* case *);
                end (* if *);
            until (atField > 5) or (key = KEY_ESC);
        if (key = KEY_ESC) then
            acct := oldAcct;
end (* EditAcct *);

