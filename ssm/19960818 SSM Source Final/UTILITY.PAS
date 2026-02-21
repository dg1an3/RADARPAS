(* utility.pas *)
(* Copyright (C) 1985, 1996 Derek G Lane *)
(* Included by fi.pas ia.pas ap.pas ar.pas dr.pas mail.pas *)
(* Part of the SSM 1.5 Package *)

(* General purpose routines *)

var
  Key    : char;
  Escape : boolean;

procedure ReadKbd;
begin   Read(Kbd,Key);
        if KeyPressed then begin
            Read(Kbd, Key);
            Escape := true;
        end else
            Escape := false;
end (* ReadKbd *);

procedure Quit; forward;


(* Date handling routines *)

const   DaysinMonth :   array [1..12] of byte =
            (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

        DaysinYear :   array [1..12] of integer =
            (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);

        DayNames :   array [0..6] of string[9] =
            ('Sunday', 'Monday', 'Tuesday', 'Wednesday',
             'Thursday', 'Friday', 'Saturday');

        MonthNames :   array [1..12] of string[9] =
            ('January','February','March','April','May','June',
             'July','August','September','October','November','December');

var     ADate :   DateRec;

function CompareDates(Date1, Date2 :   DateRec) :   integer;
begin   if (Date1.Year = Date2.Year) then
            if (Date1.Month = Date2.Month) then
                if (Date1.Day = Date2.Day) then
                    if (Date1.Hour = Date2.Hour) then
                        CompareDates := Date1.Minute-Date2.Minute
                    else
                        CompareDates := Date1.Hour-Date2.Hour
                else
                    CompareDates := Date1.Day-Date2.Day
            else
                CompareDates := Date1.Month-Date2.Month
        else
            CompareDates := Date1.Year-Date2.Year;
end (* CompareDates *);

procedure ParseDate(var DateInput, TimeInput :   String10;
        var ForDay : DateRec);
begin   Right := true;
        with ForDay do begin
            val(Dateinput, I, J);
            Month := I;
            if not(Month in [1..12]) then
                Right := false;
            Dateinput := Copy(Dateinput, J+1, Length(Dateinput));
            val(Dateinput, I, J);
            Day := I;
            if not(Day in [1..31]) then
                Right := false;
            Dateinput := Copy(Dateinput, J+1, Length(Dateinput));
            val(Dateinput, Year, J);
            if (Year < 100) then
                if (Year > 80) then
                    Year := Year+1900
                else
                    Year := Year+2000;
            if (Year < 1984) then
                Right := false;
            if (Length(Timeinput) < 4) then
                Timeinput := '11:59p';
            val(Timeinput, I, J);
            Hour := I;
            if not(Hour in [1..24]) then
                Right := false;
            if (Pos('p',Timeinput) <> 0) or (Pos('P',Timeinput) <> 0) then
                if (Hour < 12) then
                    Hour := Hour+12;
            Timeinput := Copy(Timeinput, J+1, Length(Timeinput));
            val(Timeinput, I, J);
            Minute := I;
            if not(Minute in [0..59]) then
                Right := false;
        end (* with *);
end (* ParseDate *);

function FindDay(ForDay :   DateRec) :   String10;
begin   with ForDay do begin
            K := Year-1984;
            X := K*365+((K-1) div 4);
            if ((K mod 4) = 0) then
                if (Month >= 3) then
                    X := X+1;
            X := X + DaysinYear[Month] + Day;
            FindDay := DayNames[Trunc((X-Int(X/7)*7))];
        end;
end (* FindDay *);

function ShortDate(ForDay :   DateRec) :   String10;
begin   FillChar(StrA, SizeOf(StrA), 32);
        with ForDay do begin
            Str(Month, StrA);
            Str(Day, StrB);
            StrA := StrA+'/'+StrB+'/';
            Str(Year, StrB);
            StrA := StrA+Copy(StrB,3,2);
        end (* with *);
        StrA[0] := #8;    (* set length *)
        ShortDate := StrA;
end (* ShortDate *);

function ShortTime(ForDay :   DateRec) :   String10;
begin   FillChar(StrA,SizeOf(StrA),32);
        with ForDay do begin
           if ((Hour mod 12) <> 0) then
               Str(Hour mod 12, StrA)
           else
               StrA := '12';
           Str(Minute, StrB);
           if (Minute < 10) then
               StrA := StrA+':0'+StrB
           else
               StrA := StrA+':'+StrB;
           if (Hour < 12) then
               StrA := StrA+' am'
           else
               StrA:=StrA+' pm';
        end (* with *);
        StrA[0] := #8;
        ShortTime := StrA;
end (* ShortTime *);

procedure DateString(ForDay : DateRec);
begin   with ForDay do begin
            Write('  ', FindDay(ForDay), ', ');
            Write(MonthNames[Month], ' ', Day, ', ', Year);
            Write('  ', ShortTime(ForDay));
        end (* with *);
end (* DateString *);



(* Screen handling routines *)

const   FIMDiskMsg :   LineType =
            'Please put the Fuel Inventory Manager Data Disk in drive B';

        NormColor =   White;
        NormBack =   Black;
        HiColor =   Black;
        HiBack =   LightGray;
        ErrColor =   Black;
        ErrBack =   LightGray;

type    RegisterType =   record
            case integer of
                1 : (AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags :   integer);
                2 : (AL,AH,BL,BH,CL,CH,DL,DH :   byte);
        end (* RegisterType *);

        CharSet =   set of char;

        CurrentWinRec =   record
            YSize :   byte;
            Data :   array [1..60, 1..78] of char;
        end (* CurrentWinRec *);

var     CurWind :   ^CurrentWinRec;
        Screen :   array[1..25, 1..80, 1..2] of char absolute $B000:$8000;
        CurrX :   byte;
        CurrY :   byte;
        TopLine :   byte;
        KeyLine :   LineType;
        EditLine :   LineType;
        Registers :   RegisterType;

procedure Frame(UpperX, UpperY, LowerX, LowerY: integer);
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
begin   Window(1,1,80,24);
        ClrScr;
        Frame(28,11,52,15);
        ClrScr;
        Writeln;
        Write(' One moment, please... ');
end (* OneMoment *);

procedure Cursor(Startline, Endline :   byte);
begin   with Registers do begin
            AH := $01;
            CH := Startline;
            CL := Endline;
            Intr($10, Registers);
        end (* with *);
end (* Cursor *);

procedure InfoLine;
begin   Window(1, 1, 80, 25);
        GotoXY(1, 25);
        ClrEol;
        Write(MODULE_NAME, ' ');
        DateString(TodaysDate);
        if not ChangeStatus then begin
            TextColor(White+Blink);
            Write('  READ-ONLY');
            TextColor(NormColor);
        end (* if *);
end (* InfoLine *);

procedure Message(Line :   LineType);
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

procedure ErrorMsg(Line : LineType);
begin   TextColor(ErrColor);
        TextBackground(ErrBack);
        Message(''+Line+'. Press any key.');
        TextColor(NormColor);
        TextBackground(NormBack);
        ReadKbd;
        Message(KeyLine);
end (* ErrorMsg *);

procedure ReadDate;
begin   Cursor(0,7);
        Write('Date : ');
        Read(StrA);
        Write('    Time : ');
        Read(StrB);
        ParseDate(StrA, StrB, ADate);
        Cursor(16, 0);
end (* ReadDate *);

procedure DrawLine(var Where; AtLine :   byte);
var     Line : array[1..78] of char absolute Where;
begin   for I := 1 to 78 do
            Screen[AtLine, I, 1] := Line[I];
end (* DrawLine *);

procedure ChangeWindow(var WindPtr);
begin   Window(1, 1, 80, 24);
        ClrScr;
        CurWind := Addr(WindPtr);
        with CurWind^ do begin
            if YSize<=23 then
                K := YSize
            else
                K := 23;
            for J := 1 to K do
                for I := 1 to 78 do
                    Screen[J,I,1] := Data[J,I];
            Window(1, 1, 80, 23);
            TopLine := 1;
        end (* with *);
end (* ChangeWindow *);

procedure ReDrawWindow;
begin   with CurWind^ do begin
            for J:= TopLine to TopLine+22 do
                for I:= 1 to 78 do
                    Screen[J,I,1] := Data[J,I];
            Window(1, 1, 80, 23);
        end (* with *)
end (* ReDrawWindow *);

procedure GotoLine(ToLine :  byte);
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

procedure WGoto(X, Y :   byte);
begin   CurrX :=   X;
        CurrY :=   Y;
end (* WGoto *);

procedure ScreenOut(Out :   char);
begin   CurWind^.Data[CurrY,CurrX] := Out;
        if CurrY in [TopLine..TopLine+22] then
            Screen[CurrY-TopLine+1, CurrX, 1] := Out;
        CurrX := CurrX+1;
        if (CurrX > 78) then begin
            CurrX := 1;
            CurrY := CurrY+1;
        end (* if *);
end (* ScreenOut *);

procedure HiLiteCell(X, Y, Size :   byte);
begin   TextColor(HiColor);
        TextBackground(HiBack);
        GotoXY(X, Y-TopLine+1);
        Write(Copy(CurWind^.Data[Y], X, Size));
end (* HiLiteCell *);

procedure LoLiteCell(X, Y, Size :   byte);
begin   TextColor(NormColor);
        TextBackground(NormBack);
        GotoXY(X, Y-TopLine+1);
        Write(Copy(CurWind^.Data[Y], X, Size));
end (* LoLiteCell *);

var    DecPoint :   boolean;

function EnterCell(X, Y, Size :   byte; Accept :   CharSet) :   LineType;
begin   DecPoint := false;
        HiLiteCell(X,Y,Size);
        WGoto(X,Y);
        Write(Usr,Copy('                         ', 1, Size));
        Line := '';
        while not Escape and (Key <> #13) do begin
            if (Key = '.') then
                DecPoint := true;
            if (Key = #8) then
                Line := Copy(Line, 1, Length(Line)-1)
            else if Key in Accept then
                Line := Copy(Line+Key, 1, Size);
            WGoto(X,Y);
            Write(Usr, Line :Size);
            ReadKbd;
        end (* while *);
        LoLiteCell(X, Y, Size);
        EnterCell := Line;
end (* EnterCell *);

procedure PrintWind;
var     C :   char;
        CopyNumber, LineNumber :   integer;
begin   Message('How many copies?');
        ReadKbd;
        C := Key;
        if C in ['1'..'9'] then begin
            for I := 1 to (Ord(C)-48) do begin
                Message('Printing '+C+' copies - copy number '+
                    Chr(I+48)+'...');
                Right := false;
                LineNumber := 1;
                repeat
                    Writeln(Lst, CurWind^.Data[LineNumber]);
                    LineNumber := LineNumber+1;
                    if KeyPressed then begin
                        ReadKbd;
                        Message('Printing '+C+' copies - copy number '+
                            Chr(I+48)+'... Stop printing (Y/N)?');
                        ReadKbd;
                        if (Key = 'y') then begin
                            Exit;
                        end (* if *);
                        Message('Printing '+C+' copies - copy number '+
                            Chr(I+48)+'...');
                    end (* if *);
                until (LineNumber > CurWind^.YSize) or Right;
                Write(Lst,#12);
            end (* for *);
        end (* if *);
end (* PrintWind *);


(* Disk handling routines *)

var     DTA :   array [0..127] of byte;
        EntrySize :   real;
        Mask :   LineType;
        Option :   integer;
        ThisProg :   file of byte;

function IOError :   integer;
var     IOTemp :   integer;
        IOPerm :   integer;
begin   IOTemp := Ioresult;
        if (IOTemp <> 0) then
            IOPerm := IOTemp;
        IOError := IOPerm;
end (* IOError *);

procedure SaveChange(var From; ForLength :   integer; InProg :   LineType);
var    Dum :   array [0..255] of byte absolute From;
begin  Assign(ThisProg, InProg);
       ReSet(ThisProg);
       Seek(ThisProg, Ofs(From)-$0100);
       for I := 0 to ForLength do
           Write(ThisProg,Dum[I]);
       Close(ThisProg);
end (* SaveChange *);

procedure SetDTA(var DTA);
begin   with Registers do begin
            AH := $1A;
            DS := Seg(DTA);
            DX := Ofs(DTA);
            MSDos(Registers);
            ErrorFlag := ((Flags and $01) <> 0);
            if ErrorFlag then
                ErrorNumber := AL;
        end (* with *);
end (* SetDTA *);

procedure SetDir(OptionSelect : integer);
begin   Option := OptionSelect;
        with Registers do begin
            AH := $4E;
            DS := Seg(Mask);
            DX := Ofs(Mask)+1;
            CX := Option;
            MsDos(Registers);
            ErrorFlag := ((Flags and $01) <> 0);
            if ErrorFlag then
                ErrorNumber := AL;
        end;
end (* SetDir *);

function DirEntry :   LineType;
begin   Line := '';
        I := 29;
        repeat
            Line := Line+Chr(DTA[I]);
            I := I+1;
        until (DTA[I] = 0);
        DirEntry := Line;
        EntrySize := (DTA[26]+DTA[27]*$FF)+
            (DTA[28]+DTA[29]*$FF)*$FFFF;
        with Registers do begin
            AH := $4F;
            CX := Option;
            MSDos(Registers);
            ErrorFlag := ((Flags and $01) <> 0);
            if ErrorFlag then
                ErrorNumber := AL;
        end (* with *);
end (* DirEntry *);

{
procedure SetBlock(Size :   integer);
begin   with Registers do begin
            AH := $4A;
            ES := CSeg;
            BX := Size;
            MsDos(Registers);
            ErrorFlag:=(Flags and $01)<>0;
            if ErrorFlag then ErrorNumber:= AL;
        end;
end (* SetBlock *);

procedure Exec(Name, ComLine :   LineType);
var    ParamBlock :   RECorD
           Environ :   integer;
           ComPtr :   ^LineType;
           FCB1 :   ^byte;
           FCB2 :   ^byte;
       end;
begin  Name := Name+Chr(0);
       ComLine := ComLine+Chr(0);
       with ParamBlock do begin
           Environ := $0000;
           ComPtr := Ptr(Seg(ComLine), Ofs(ComLine)+1);
           FCB1 := Ptr($0000, $0000);
           FCB2 := Ptr($0000, $0000);
       end (* with *);
       with Registers do begin
           AX := $4B00;
           DX := Ofs(Name)+1;
           DS := Seg(Name);
           BX := Ofs(ParamBlock);
           Es := Seg(ParamBlock);
           MsDos(Registers);
           ErrorFlag := ((Flags and $01)<>0);
           if ErrorFlag then
               ErrorNumber := AL;
       end (* with *);
end (* Exec *);
}

procedure SetAttribute(Name :   LineType; Attribute :   byte);
begin   with Registers do begin
            AX := $4301;
            Name := Name+Chr(0);
            CX := Attribute;
            DX := Ofs(Name)+1;
            DS := Seg(Name);
            MsDos(Registers);
            ErrorFlag := ((Flags and $01) <> 0);
            if ErrorFlag then
                ErrorNumber := AL;
        end (* with *)
end (* SetAttribute *);

function DefaultDrive :   byte;
begin   with Registers do begin
            AH := $19;
            MSDos(Registers);
            DefaultDrive := AL+1
        end;
end (* DefaultDrive *);


function DiskMemory(Drive : byte) : REAL;
begin   with Registers do begin
            AH:= $36;
            DL:= Drive;
            MSDos(Registers);
            DiskMemory:=((AX*CX*1.0)*BX);
        end;
end;

procedure CheckFile(Name : LineType);
begin   SetAttribute(Name,$00);
        if (IOError = $01) then begin
            (* ErrorMsg('Please put the '+Abbreviation+' Data Disk in drive '+
                DataDrive); *)
            SetAttribute(Name, $00);
            if (IOError = $01) then
                Quit;
        end (* if *);
end (* CheckFile *);