(* ApCheck.pas *)
(* Copyright (C) 1985, 1996 Derek G. Lane *)

const   NumNameOnes  : array[0..19] of string[10] =
            ('zero ', 'one ', 'two ', 'three ', 'four ', 'five ',
            'six ', 'seven ', 'eight ', 'nine ', 'ten ',
            'eleven ', 'twelve ', 'thirteen ', 'fourteen ', 'fifteen ',
            'sixteen ', 'seventeen ', 'eighteen ', 'nineteen ');
        NumNameTens  : array[2..9] of string[10] =
            ('twenty ', 'thirty ', 'forty ', 'fifty ',
            'sixty ', 'seventy ', 'eighty ', 'ninety ');

function NumberText(ForNum  : real)  : LongStr;
var     Text, FracStr  : LongStr;
begin   Text := '';
        if (ForNum >= 1000) then begin
            FracStr := NumberText(Trunc(ForNum / 1000 + 0.01));
            FracStr := Copy(FracStr, 1, Length(FracStr)-10);
            Text := FracStr + 'thousand ';
            ForNum := ForNum - (Trunc(ForNum/1000 + 0.01)*1000);
                (* had to jerryrig the Trunc function *)
        end (* if *);
        if (ForNum >= 100) then begin
            Text := Text +
                NumNameOnes[Trunc(ForNum/100 + 0.01)] + 'hundred ';
             ForNum := ForNum - ((Trunc(ForNum/100 + 0.01))*100);
        end (* if *);
        if (ForNum >= 20) then begin
             Text := Text + NumNameTens[Trunc(ForNum/10 + 0.01)];
             ForNum := ForNum - ((Trunc(ForNum/10 + 0.01))*10);
        end (* if *);

        if ((Text = '') or ((Trunc(ForNum + 0.01)) > 0)) then
            Text := Text + NumNameOnes[Trunc(ForNum + 0.01)];

        Str(Abs(-0.01+Frac(ForNum + 0.01))*100:0:0, FracStr);
            (* had to jerryrig the Frac function *)
        if (Length(FracStr) = 1) then
            FracStr := '0' + FracStr;

        Text := Text + 'and ' + FracStr + '/100';
        NumberText := Text;
end (* NumberText *);

procedure PrintCheckOrBill(var acct  : AcctRec;
        var transl  : TransList; var numTrans  : integer);
var     AmountText  : LongStr;
        newTrans  : TransRec;
        currTrans  : integer;
begin   if (numTrans >= MAX_TRANS) then begin
            ErrorMsg('Transaction limit exceeded. ' +
                'Please contact software vendor');
            Exit;
        end (* if *);
        with acct do begin
            if (transl[numTrans].balance = 0.0) then    (* nothing to do *)
                Exit;
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            AmountText := NumberText( transl[numTrans].Balance );
            AmountText[ 1 ] := UpCase( AmountText[ 1 ] );
            WriteLn(Lst, '       ', AmountText,
                Copy('                                                     ',
                    1, 53 - Length( AmountText )),
                ShortDate( TodaysDate ),
                '     ',
                transl[numTrans].Balance :7:2);
            WriteLn(Lst); WriteLn(Lst);
            (* WriteLn(Lst,'       Account #', number);  (* Line 8 *)
            WriteLn(Lst,'       ', name);
            WriteLn(Lst,'       ', address);
            WriteLn(Lst,'       ', city);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst); WriteLn(Lst);
            WriteLn(Lst); WriteLn(Lst);   (* Line 46 *)
        end; (* with *)
        (* Create the payment entry *)
        newTrans.date := TodaysDate;
        newTrans.description := 'PAYMENT';
        newTrans.amount := -transl[numTrans].balance;
        newTrans.balance := 0.0;
        AddTrans(transl, numTrans, newTrans, currTrans);
        UpdateAcct(acct, transl, numTrans);
end (* PrintCheckOrBill *);
