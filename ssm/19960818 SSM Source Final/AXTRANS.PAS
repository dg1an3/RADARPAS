(* AxTrans.pas *)
(* Copyright (C) 1985,1996 Derek G. Lane *)

const   FIRST_VALID_ENTRY  = 3;   (* after the account header *)
        MAX_TRANS  = 650;

type    TransRec  = record
            date   : DateRec;
            description   : string[40];
            amount   : real;
            balance   : real;
        end (* TransRec *);

        TransList  = array [0..MAX_TRANS] of TransRec;

procedure AddTrans(var toList  : TransList;  var numTrans  : integer;
            theTrans  : TransRec; var newTransNdx  : integer);
var     count  : integer;
begin   if (numTrans < MAX_TRANS) then begin
            count := numTrans;
            numTrans := numTrans + 1;
            if (numTrans > 1) then
                while (CompareDates(toList[count].Date, theTrans.Date) > 0)
                        and (count > 0) do begin
                    toList[count+1] := toList[count];
                    count := count - 1;
                end (* while *);
            newTransNdx := count+1;
            toList[newTransNdx] := theTrans;
        end else
            ErrorMsg('Transaction limit exceeded.  ' +
                'Please contact software vendor for update.');
end (* AddTrans *);

procedure DelTrans(var fromList  : TransList; var numTrans  : integer;
            var transNumToDelete  : integer);
var     count  : integer;
begin   if (numTrans > 0) and (transNumToDelete > 0) and
                (transNumToDelete <= numTrans) then begin
            for count := transNumToDelete to numTrans - 1 do
                fromList[count] := fromList[count+1];
        end (* if *);
        numTrans := numTrans - 1;
        if (transNumToDelete > numTrans) then
            transNumToDelete := numTrans;
end (* DelTrans *);

procedure LoadTrans(fileName  : LongStr;
            var intoList  : TransList; var numTrans  : integer);
var     transFile  : file;
begin   numTrans := 0;
        Assign(transFile, fileName);
        ReSet(transFile, SizeOf(TransRec));
        if (IOResult = 0) then begin
            if ((FileSize(transFile) - FIRST_VALID_ENTRY) > MAX_TRANS)
                    then begin
                numTrans := MAX_TRANS;
                ErrorMsg('Transaction limit exceeded.  ' +
                    'Please contact vendor.');
            end else
                numTrans := trunc(FileSize(transFile) - FIRST_VALID_ENTRY);
            Seek(transFile, FIRST_VALID_ENTRY);
            BlockRead(transFile, intoList[1], numTrans, numTrans);
            Close(transFile);
        end (* if *);
end (* LoadTrans *);

procedure SaveTrans(fileName  : LongStr;
            var fromList  : TransList; numTrans  : integer);
var     transFile  : file;
begin   Assign(transFile, fileName);
        ReSet(transFile, SizeOf(TransRec));
        if (IOResult = 0) then begin
            Seek(transFile, FIRST_VALID_ENTRY);
            BlockWrite(transFile, fromList[1], numTrans);
            Truncate(transFile);
            Close(transFile);
        end (* if *);
end (* SaveTrans *);

procedure DrawTrans(trans  : TransRec; row  : integer; hiliteFlag  : boolean);
begin   if hiliteFlag then begin
            TextColor(HILITE_COLOR);
            TextBackground(HILITE_BACKG);
        end (* if *);
        with trans do begin
            GotoXY(1, row);
            ClrEOL;
            Write(ShortDate(Date));
            Write(' ³ ');
            Write(Description);
            GotoXY(43, WhereY);
            if (Amount >= 0) then
                Write('³ ', Amount :8:2, ' ³          ³ ')
            else
                Write('³          ³ ', -Amount :8:2, ' ³ ');
            Write(Balance :8:2);
        end (* with *);
        if hiliteFlag then begin
            TextColor(NORM_COLOR);
            TextBackground(NORM_BACKG);
        end (* if *);
end (* DrawTrans *);

procedure EditTrans(var trans  : TransRec; row  : integer);
var     key  : char;
        escFlag, decPoint, valid  : boolean;
        DateStr, value  : ShortStr;
        atField, nextChar, count  : integer;
        oldTrans  : TransRec;
begin   DrawTrans(trans, row, false);
        oldTrans := trans;
        atField := 1;
        with trans do begin
            repeat
                case atField of
                    1  : HiLiteCell(1, row, 8);
                    2  : HiLiteCell(12, row, 30);
                    3  : HiLiteCell(45, row, 8);
                    4  : HiLiteCell(56, row, 8);
                end (* case *);
                ReadKbd(key, escFlag);
                case atField of
                    1  : LoLiteCell(1, row, 8);
                    2  : LoLiteCell(12, row, 30);
                    3  : LoLiteCell(45, row, 8);
                    4  : LoLiteCell(56, row, 8);
                end (* case *);
                if escFlag then
                    case key of
                        KEY_RT, KEY_DN  : if (atField < 4) then
                            atField := atField + 1;
                        KEY_LT, KEY_UP, KEY_BACKTAB  : if (atField > 1) then
                            atField := atField - 1;
                    end (* case *)
                else
                    case key of
                        KEY_ENTER  : if (atField < 5) then
                            atField := atField + 1;
                        KEY_TAB  : if (atField < 4) then
                            atField := atField + 1;
                        ' '..'~'  : begin
                            case atField of
                                1  : begin
                                    value := EnterCell(1, WhereY, 8,
                                        ['0'..'9','/','-','.'],
                                        key, decPoint);
                                    ParseDate(value, '', Date, valid);
                                    if not valid then
                                        Date := TodaysDate;
                                end (* 1 *);
                                2  : Description := EnterCell(12, WhereY, 30,
                                        [' '..'~'], key, decPoint);
                                3  : begin
                                    value := EnterCell(45, WhereY, 8,
                                        ['0'..'9','.'], key, decPoint);
                                    Val(value, Amount, nextChar);
                                    if not decPoint then
                                        Amount := Amount/100;
                                    atField := 4;
                                end (* 3 *);
                                4  : begin
                                    value := EnterCell(56, WhereY, 8,
                                        ['0'..'9','.'], key, decPoint);
                                    Val(value, Amount, nextChar);
                                    Amount := -Amount;
                                    if not decPoint then
                                        Amount := Amount/100;
                                end (* 4 *);
                            end (* case *);
                            DrawTrans(trans, row, false);
                            atField := atField + 1;
                        end (* ' ',,'~' *);
                    end; (* case *)
            until (atField > 4) or (key = KEY_ESC);
        end (* with *);
        if (key = KEY_ESC) then    (* restore transaction *)
            trans := oldTrans;
end (* EditTrans *);
