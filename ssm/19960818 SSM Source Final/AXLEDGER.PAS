(* AxLedger.pas *)
(* Copyright (C) 1985, 1996  Derek G Lane *)

const   MAX_ACCOUNT  = 100;

type    LedgerRec  = record
            acct  : array [0..MAX_ACCOUNT] of AcctRec;
            numAcct, currAcct  : integer;
            transl  : TransList;    (* for currAcct *)
            numTrans  : integer;
            sumBal, sumgt30, sumgt60  : real;
            fullPath  : LongStr;
        end (* LedgerRec *);

function AcctFileName(acctNum  : integer)  : LongStr;
var     FileName  : ShortStr;
begin   Str(acctNum, FileName);
        FileName := 'acc'+
            Copy('0000'+FileName, Length(FileName)+1, 4)+'.dat';
        AcctFileName := FileName;
end (* AcctFileName *);

procedure InitLedger(var forLedger  : LedgerRec;
            dataPath  : LongStr);
var     fileName  : ShortStr;
        acctFile  : file of AcctRec;
        count, result  : integer;
        key  : char;
        escFlag  : boolean;
        h  : SearchHandle;
begin   with forLedger do begin
            fullPath := dataPath;
            numAcct := 0;
            sumBal := 0;
            sumGT30 := 0;
            sumGT60 := 0;
            result := SetSearch(h, fullPath+'acc?????.dat', $00);
            while (result = 0) do begin
                result := NextFile(h, fileName);
                Assign(acctFile, fullPath+fileName);
                ReSet(acctFile);
                if (numAcct < MAX_ACCOUNT) then begin
                    Read(acctFile, acct[0]);
                    Close(acctFile);
                    count := numAcct;
                    numAcct := numAcct + 1;
                    while (count > 0) and (acct[count].Name >
                            acct[0].Name) do begin
                        acct[count+1] := acct[count];
                        count := count - 1;
                    end (* while *);
                    acct[count+1] := acct[0];
                    (* LoadTrans(fullPath+fileName, transl, numTrans);
                    UpdateAcct(acct[count+1], transl, numTrans);
                    SaveAcct(fullPath+fileName, acct[count+1],
                        transl, numTrans); *)
                    sumBal := sumBal + acct[count+1].balance;
                    sumgt30 := sumgt30 + acct[count+1].gt30;
                    sumgt60 := sumgt60 + acct[count+1].gt60;
                end else if (numAcct >= MAX_ACCOUNT) then begin
                    ErrorMsg('Account limit exceeded.  ' +
                        'Please contact software vendor');
                    result := -1;
                end (* if *);
            end (* while *);
            if (result = 3) then begin
                Message('Data directory does not exist. ' +
                    'Press <+> to create...');
                ReadKbd(key, escFlag);
                if (key = '+') then begin
                    Message('Creating directory ' +
                        Copy(FullPath,1,Length(FullPath)-1));
                    MkDir(Copy(FullPath,1,Length(FullPath)-1));
                end else
                    Quit;
            end (* if *);
        end (* with *);
end (* InitLedger *);

procedure DrawLedger(var forLedger  : LedgerRec);
var     count  : integer;
begin   ChangeWindow(APWindow);
        with forLedger do begin
            GotoXY(51, LYLog+1);    (* write summary *)
            Write(sumBal :8:2);
            if (sumgt30 > 0.0) then
                Write(sumgt30 :9:2)
            else
                Write('       --');
            if (sumgt60 > 0.0) then
                Write(sumgt60 :9:2)
            else
                Write('       --');
            Window(UXLog, UYLog, LXLog, LYLog);
            ClrScr;
            for count := -AboveLog+1 to BelowLog+1 do
                if (count+currAcct > 0) and
                        (count+currAcct <= numAcct) then
                    DrawAcctLine(acct[count+currAcct],
                        count+AboveLog, (count = 0));
        end (* with *);
end (* DrawLedger *);

procedure PrintLedger(var forLedger  : LedgerRec);
var     count  : integer;
begin   Message('Printing ledger...');
        Writeln(lst, MODULE_NAME, ' Summary');
        Writeln(lst);
        Writeln(lst, ' ', COMP_NAME);
        Writeln(lst, ' ', COMP_ADDR);
        Writeln(lst, ' ', COMP_CITY);
        Writeln(lst, '--------------------------------------------------' +
            '------------------------------');
        Writeln(lst, ' NUMBER  NAME                              ' +
            '          BALANCE   30 DAY   60 DAY');
        with forLedger do begin
            for count := 1 to numAcct do
                with acct[count] do begin
                    Write(lst, '  ', number:4, '   ');
                    Write(lst, name);
                    Write(lst, Copy('                                           ',
                        1, 43-Length(name)));
                    Write(lst, balance:8:2);
                    if (gt30 > 0.0) then
                        Write(lst, gt30:9:2)
                    else
                        Write(lst, '       --');
                    if (gt60 > 0.0) then
                        Writeln(lst, gt60:9:2)
                    else
                        Writeln(lst, '       --');
                end (* with *);
            Writeln(lst, '--------------------------------------------------' +
                '------------------------------');
            Write(lst, '                                            SUMMARY ',
                sumBal:8:2);
            if (sumgt30 > 0.0) then
                Write(lst, sumgt30:9:2)
            else
                Write(lst, '       --');
            if (sumgt60 > 0.0) then
                Writeln(lst, sumgt60:9:2)
            else
                Writeln(lst, '       --');
        end (* with *);
        Writeln(lst, '--------------------------------------------------' +
            '------------------------------');
        Writeln(lst, ^L);
end (* PrintAcct *);

procedure ViewLedger(var forLedger  : LedgerRec);
var     key  : char;
        escFlag  : boolean;
        prevAcct  : integer;
        testFile  : file;
begin   with forLedger do begin
            currAcct := 1;
            DrawLedger(forLedger);
            repeat
                ReadKbd(key, escFlag);
                prevAcct := currAcct;
                case key of
                    KEY_F1, KEY_ENTER  : if (numAcct > 0) then begin
                        sumBal := sumBal - acct[currAcct].balance;
                        sumgt30 := sumgt30 - acct[currAcct].gt30;
                        sumgt60 := sumgt60 - acct[currAcct].gt60;
                        LoadTrans(fullPath+
                            AcctFileName(acct[currAcct].number),
                            transl, numTrans);
                        UpdateAcct(acct[currAcct], transl, numTrans);
                        ViewAcct(acct[currAcct], transl, numTrans);
                        SaveAcct(fullPath+
                            AcctFileName(acct[currAcct].number),
                            acct[currAcct], transl, numTrans);
                        sumBal := sumBal + acct[currAcct].balance;
                        sumgt30 := sumgt30 + acct[currAcct].gt30;
                        sumgt60 := sumgt60 + acct[currAcct].gt60;
                        DrawLedger(forLedger);
                    end (* KEY_F1, KEY_ENTER *);
                    KEY_F2  : if (numAcct < MAX_ACCOUNT) then begin
                        with acct[0] do begin
                            number := 0;
                            name := '';
                            address := '';
                            city := '';
                            phone := '';
                            balance := 0.0;
                            gt30 := 0.0;
                            gt60 := 0.0;
                        end (* with *);
                        numTrans := 0;
                        EditAcct(acct[0], transl, numTrans);
                        if (acct[0].number <> 0) then begin
                            Assign(testFile,    (* ensure number not in use *)
                                fullPath+AcctFileName(acct[0].number));
                            Reset(testFile);
                            if (IOResult <> 1) then begin
                                close(testFile);
                                ErrorMsg('Account number in use. ' +
                                    'Please delete existing account first')
                            end else begin
                                SaveAcct(fullPath+
                                    AcctFileName(acct[0].number),
                                    acct[0], transl, numTrans);
                                InitLedger(forLedger, fullPath);
                                currAcct := numAcct;
                                while (acct[currAcct].number <>
                                        acct[0].number) and
                                        (currAcct > 1) do
                                    currAcct := currAcct - 1;
                            end (* if *);
                        end (* if *);
                        DrawLedger(forLedger);
                        prevAcct := currAcct;
                    end else begin
                        ErrorMsg('Account limit exceeded: ' +
                            'Please contact software vendor.');
                        DrawLedger(forLedger);
                    end (* KEY_F2 *);
                    KEY_F3  : begin
                        acct[0] := acct[currAcct];
                        LoadTrans(fullPath+
                            AcctFileName(acct[0].number),
                            transl, numTrans);
                        EditAcct(acct[0], transl, numTrans);
                        if (acct[0].number <> 0) then begin
                            Assign(testFile,    (* ensure number not in use *)
                                fullPath+AcctFileName(acct[0].number));
                            Reset(testFile);
                            if (IOResult <> 1) and (acct[0].number <>
                                    acct[currAcct].number)then begin
                                close(testFile);
                                ErrorMsg('Account number in use. ' +
                                    'Please delete existing account first');
                            end else begin
                                close(testFile);
                                SaveAcct(fullPath+
                                    AcctFileName(acct[0].number),
                                    acct[0], transl, numTrans);
                                InitLedger(forLedger, fullPath);
                                currAcct := numAcct;
                                while (acct[currAcct].number <>
                                    acct[0].number) and
                                    (currAcct > 1) do
                                currAcct := currAcct - 1;
                            end (* if *);
                        end (* if *);
                        DrawLedger(forLedger);
                        prevAcct := currAcct;
                    end (* KEY_F3 *);
                    KEY_F4  : begin    (* Print check *)
                        sumBal := sumBal - acct[currAcct].balance;
                        sumgt30 := sumgt30 - acct[currAcct].gt30;
                        sumgt60 := sumgt60 - acct[currAcct].gt60;
                        LoadTrans(fullPath+
                            AcctFileName(acct[currAcct].number),
                            transl, numTrans);
                        PrintCheckOrBill(acct[currAcct], transl, numTrans);
                        SaveAcct(fullPath+
                            AcctFileName(acct[currAcct].number),
                            acct[currAcct], transl, numTrans);
                        sumBal := sumBal + acct[currAcct].balance;
                        sumgt30 := sumgt30 + acct[currAcct].gt30;
                        sumgt60 := sumgt60 + acct[currAcct].gt60;
                        DrawLedger(forLedger);
                        prevAcct := currAcct;
                    end (* KEY_F4 *);
                    KEY_F5  : begin
                        PrintLedger(forLedger);
                        DrawLedger(forLedger);
                    end (* KEY_F5 *);
                    KEY_F6  : begin
                        Message('Delete this account?');
                        ReadKbd(key, escFlag);
                        if (key = 'y') or (key = 'Y') then begin
                            Assign(testFile, fullPath+
                                AcctFileName(acct[currAcct].number));
                            Erase(testFile);
                            InitLedger(forLedger, fullPath);
                            if (prevAcct > numAcct) then begin
                                currAcct := numAcct;
                                prevAcct := currAcct;
                            end else
                                currAcct := prevAcct;
                        end (* if *);
                        DrawLedger(forLedger);
                    end (* KEY_F6 *);
                    KEY_UP  : if (currAcct > 1) then
                        currAcct := currAcct - 1;
                    KEY_DN  : if (currAcct < numAcct) then
                        currAcct := currAcct + 1;
                    KEY_HOME  : currAcct := 1;
                    KEY_END  : currAcct := numAcct;
                    KEY_PGUP  : if (currAcct - (AboveLog+BelowLog) >= 1) then
                        currAcct := currAcct - (AboveLog+BelowLog)
                    else
                        currAcct := 1;
                    KEY_PGDN  : if (currAcct + (AboveLog+BelowLog) <=
                            numAcct) then
                        currAcct := currAcct + (AboveLog+BelowLog)
                    else
                        currAcct := numAcct;
                end (* case *);
                if (numAcct > 0) then begin
                    DrawAcctLine(acct[prevAcct], AboveLog, false);
                    while (prevAcct > currAcct) do begin
                        GotoXY(1, 1);
                        InsLine;
                        if (prevAcct-AboveLog > 0) then
                            DrawAcctLine(acct[prevAcct-AboveLog], 1, false);
                        prevAcct := prevAcct - 1;
                    end (* while *);
                    while (prevAcct < currAcct) do begin
                        GotoXY(1, 1);
                        DelLine;
                        if (prevAcct+BelowLog+2 <= numAcct) then
                            DrawAcctLine(acct[prevAcct+BelowLog+2],
                                AboveLog+BelowLog+1, false);
                        prevAcct := prevAcct + 1;
                    end (* while *);
                    DrawAcctLine(acct[currAcct], AboveLog, true);
                end (* if *)
            until (key = KEY_ESC);
        end (* with *);
end (* ViewLedger *);
