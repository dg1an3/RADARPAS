(* uiUtil.pas  User interface routines *)
(* Copyright (C) 1985,1996 Derek G. Lane *)

(* Keyboard handling routines *)


const   KEY_ENTER  = ^M;    (* Non-escape codes *)
        KEY_BS  = #8;
        KEY_TAB  = #9;
        KEY_ESC  = #27;

        KEY_BACKTAB  = #15;    (* Escape codes *)
        KEY_F1  = ';';
        KEY_F2  = '<';
        KEY_F3  = '=';
        KEY_F4  = '>';
        KEY_F5  = '?';
        KEY_F6  = '@';
        KEY_F7  = 'A';
        KEY_F8  = 'B';
        KEY_UP  = 'H';
        KEY_DN  = 'P';
        KEY_RT  = 'M';
        KEY_LT  = 'K';
        KEY_HOME  = 'G';
        KEY_END  = 'O';
        KEY_PGUP  = 'I';
        KEY_PGDN  = 'Q';

(* var     Key  : char;
        Escape  : boolean; *)

procedure ReadKbd(var Key  : char; var EscFlag  : boolean);
begin   Read(Kbd, Key);
        if KeyPressed then begin
            Read(Kbd, Key);
            EscFlag := true;
        end else
            EscFlag := false;
end (* ReadKbd *);

(* Screen handling routines *)

type    CharSet  = set of char;

        CurrentWinRec  = record
            YSize :   byte;
            Data :   array [1..60, 1..78] of char;
        end (* CurrentWinRec *);

var     CurWind  : ^CurrentWinRec;
        Screen  : array[1..25, 1..80, 1..2] of char absolute $B000:$8000;
        CurrX  : byte;
        CurrY  : byte;
        TopLine  : byte;
        (* KeyLine  : LineType;
        EditLine  : LineType; *)

procedure Frame(UpperX, UpperY, LowerX, LowerY  : integer);
var     I :   integer;
begin   GotoXY(UpperX, UpperY);
        Write(chr(201));
        for I := (UpperX + 1) to (LowerX - 1) do
            Write(chr(205));
        Write(chr(187));
        for I := (UpperY + 1) to (LowerY - 1) do begin
            GotoXY(UpperX , I);
            Write(chr(186));
            GotoXY(LowerX, I);
            Write(chr(186));
        end (* for *);
        GotoXY(UpperX, LowerY);
        Write(chr(200));
        for I := (UpperX + 1) to (LowerX - 1) do
            Write(chr(205));
        Write(chr(188));
        Window(UpperX+1, UpperY+1, LowerX-1, LowerY-1);
end (* Frame *);

procedure OneMoment;
begin   Window(1, 1, 80, 24);
        ClrScr;
        Frame(28, 11, 52, 15);
        ClrScr;
        Writeln;
        Write(' One moment, please... ');
end (* OneMoment *);

procedure Cursor(Startline, Endline  : byte);
var     regs  : regType;
begin   with regs do begin
            AH := $01;
            CH := Startline;
            CL := Endline;
            Intr($10, regs);
        end (* with *);
end (* Cursor *);

procedure InfoLine;
var     Today  : DateRec;
begin   Window(1, 1, 80, 25);
        GotoXY(1,25);
        ClrEol;
        Write(MODULE_NAME,' ');
        (* GetSysDate(Today); *)
        DateString(TodaysDate);
end (* InfoLine *);

procedure Message(Line  : LongStr);
var     R, C :   byte;
begin   C := WhereX;
        R := WhereY;
        Window(1, 1, 80, 24);
        GotoXY(1, 24);
        ClrEol;
        Write(Line);
        Window(1, 1, 80, 23);
        GotoXY(C, R);
end (* Message *);

procedure ErrorMsg(Line  : LongStr);
var     Key  : char;
        EscFlag  : boolean;
begin   TextColor(Black);
        TextBackground(White);
        Message(^G + Line + '. Press any key.');
        TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
        ReadKbd(Key, EscFlag);
end (* ErrorMsg *);

procedure ReadDate(var storeToDate  : DateRec);
var     dateStr, timeStr  : ShortStr;
        valid  : boolean;
begin   Cursor(0,7);
        Write('Date : ');
        Read(dateStr);
        Write('    Time : ');
        Read(timeStr);
        ParseDate(dateStr, timeStr, storeToDate, valid);
        Cursor(16, 0);
end (* ReadDate *);

procedure DrawLine(var Where; AtLine  : byte);
var     Line  : array [1..78] of char absolute Where;
        col  : integer;
begin   for col := 1 to 78 do
            Screen[AtLine, col, 1] := Line[col];
end (* DrawLine *);

procedure ChangeWindow(var WindPtr);
var     numRows, row, col  : integer;
begin   Window(1, 1, 80, 24);
        ClrScr;
        CurWind := Addr(WindPtr);
        with CurWind^ do begin
            if (YSize <= 23) then
                numRows := YSize
            else
                numRows := 23;
            for row := 1 to numRows do
                for col := 1 to 78 do
                    Screen[row, col, 1] := Data[row, col];
            Window(1, 1, 80, 23);
            TopLine := 1;
        end;
        GotoXY(0,0);
end (* ChangeWindow *);

procedure ReDrawWindow;
var     row, col  : integer;
begin   with CurWind^ do begin
            for row := TopLine to TopLine+22 do
                for col := 1 to 78 do
                    Screen[row, col, 1] := Data[row, col];
            Window(1, 1, 80, 23);
        end (* with *);
end (* ReDrawWindow *);

procedure GotoLine(ToLine  : byte);
var     N :   byte;
begin   N := ToLine;
        if (N < 1) then
            N := 1;
        if (N > CurWind^.YSize-22) then
            N := CurWind^.YSize-22;
        if (N >= TopLine) then begin
            GotoXY(1,1);
            while (TopLine <> N) do begin
                DelLine;
                TopLine := TopLine+1;
                DrawLine(CurWind^.Data[TopLine+22], 23);
            end (* while *);
        end else begin
            GotoXY(1, 1);
            while (TopLine <> N) do begin
                InsLine;
                TopLine := TopLine-1;
                DrawLine(CurWind^.Data[TopLine], 1);
            end (* while *);
        end (* if *);
end (* GotoLine *);

procedure WGoto(X, Y  : byte);
begin   CurrX := X;
        CurrY := Y;
end (* WGoto *);

procedure ScreenOut(Out  : char);
begin    CurWind^.Data[CurrY, CurrX] := Out;
         if (CurrY in [TopLine..TopLine+22]) then
             Screen[CurrY-TopLine+1, CurrX, 1] := Out;
         CurrX := CurrX+1;
         if (CurrX > 78) then begin
             CurrX := 1;
             CurrY := CurrY+1;
         end (* if *);
end (* ScreenOut *);

function ReadScreen(X, Y, Size  : byte)  : LongStr;
var     Count  : integer;
        StrA  : LongStr;
        OX, OY  : integer;
        regs  : regType;
begin   OX := WhereX;
        OY := WhereY;
        with regs do begin
            StrA := '';
            for Count := 0 to Size do begin
                GotoXY(X+Count, Y);
                AH:=$08;
                BH:=$00;
                Intr($10, regs);
                StrA := StrA + chr(AL);
            end (* for *);
        end (* with *);
        ReadScreen := StrA;
        GotoXY(OX, OY);
end (* ReadScreen *);

procedure HiLiteCell(X, Y, Size  : byte);
begin   TextColor(HILITE_COLOR);
        TextBackground(HILITE_BACKG);
        GotoXY(X, Y);
        Write(ReadScreen(X, Y, Size));
end (* HiLiteCell *);

procedure LoLiteCell(X, Y, Size  : byte);
begin   TextColor(NORM_COLOR);
        TextBackground(NORM_BACKG);
        GotoXY(X,Y);
        Write(ReadScreen(X, Y, Size));
end (* LoLiteCell *);

function EnterCell(X, Y, Size  : byte;
            Accept  : CharSet;
            initKey  : char;
            var decPoint  : boolean)  : LongStr;
var     key  : char;
        escFlag  : boolean;
        value  : LongStr;
begin   decPoint := false;
        HiLiteCell(X, Y, Size);
        GotoXY(X, Y);
        Write(Copy('                         ', 1, Size));
        value := '';
        Key := initKey;
        escFlag := false;
        while not escFlag and (key <> KEY_ENTER) and
            (key <> KEY_TAB) and (key <> KEY_ESC) do begin
            if (key = KEY_BS) then
                value := Copy(value, 1, Length(value)-1)
            else if (key in Accept) then
                value := Copy(value+key, 1, Size);
            if (key = '.') then
                decPoint := true;
            GotoXY(X, Y);
            Write(value: Size + 1);
            ReadKbd(key, escFlag);
        end (* while *);
        LoLiteCell(X, Y, Size);
        EnterCell := value;
end (* EnterCell *);

procedure PrintWind;
var     numCopies, count, key  : char;
        escFlag  : boolean;
        CopyNumber, LineNumber  : integer;
begin   Message('How many copies?');
        ReadKbd(numCopies, escFlag);
        if (numCopies in ['1'..'9']) then begin
            for count := '1' to numCopies do begin
                Message('Printing ' + numCopies +
                    ' copies - copy number ' + count + '...');
                LineNumber := 1;
                repeat
                    Writeln(Lst, CurWind^.Data[LineNumber]);
                    LineNumber := LineNumber+1;
                    if KeyPressed then begin
                        ReadKbd(key, escFlag);
                        Message('Printing ' + numCopies +
                            ' copies - copy number ' +
                            count + '... Stop printing (Y/N)?');
                        ReadKbd(key, escFlag);
                        Message('Printing ' + numCopies +
                            ' copies - copy number ' + count + '...');
                    end (* if *);
                until (LineNumber > CurWind^.YSize) or (key = 'y') or
                    (key = 'Y');
                Write(Lst, #12);
            end (* for *);
        end (* if *);
end (* PrintWind *);

