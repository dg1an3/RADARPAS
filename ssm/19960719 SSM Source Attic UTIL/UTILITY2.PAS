(* utility2.pas Copyright (C) 1986, 1996 DG Lane *)
(* Common utilities for SSM *)

(* General purpose routines *)

procedure Quit; forward;    (* must be supplied by calling program *)


(* Date handling routines *)

const   DaysinMonth  : array [1..12] of byte =
            (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

        DaysinYear  : array [1..12] of integer =
            (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);

        DayNames  : array [0..6] of string[9] =
            ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

        MonthNames  : array [1..12] of string[9] =
            ('January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December');


var     ADate  : DateRec;

function SubDates(Date1, Date2  : DateRec)  : integer;
var     Days :   integer;
begin   Days := DaysinYear[Date1.Month] + Date1.Day - DaysinYear[Date2.Month] - Date2.Day;
        if (Date2.Year <> Date1.Year) then
            Days := Days + 365*(Date1.Year - Date2.Year);
        SubDates := Days;
end (* SubDates *);

function CompareDates(Date1, Date2  : DateRec)  : integer;
begin   if (Date1.Year = Date2.Year) then
            if (Date1.Month = Date2.Month) then
                if (Date1.Day = Date2.Day) then
                    if (Date1.Hour = Date2.Hour) then
                        CompareDates := Date1.Minute - Date2.Minute
                    else
                        CompareDates := Date1.Hour - Date2.Hour
                else
                    CompareDates := Date1.Day - Date2.Day
            else
                CompareDates := Date1.Month - Date2.Month
        else
            CompareDates := Date1.Year - Date2.Year;
end (* CompareDates *);

procedure ParseDate(DateInput, TimeInput  : String10;
                    var ForDay  : DateRec);
begin    Right := true;
         with ForDay do begin
             Val(Dateinput,I,J);
             Month := I;
             Right := Month in [1..12];
             Dateinput := Copy(Dateinput, J+1, Length(Dateinput));
             Val(Dateinput, I, J);
             Day := I;
             Right := Day in [1..31];
             Dateinput := Copy(Dateinput, J+1, Length(Dateinput));
             Val(Dateinput, Year, J);
             if (Year < 100) then
                 if (Year > 80) then
                     Year := Year+1900
                 else
                     Year := Year+2000;
             Right := (Year >= 1984);
             if (Length(Timeinput) < 4) then
                 Timeinput := '11:59p';
             Val(Timeinput, I, J);
             Hour := I;
             Right := Hour in [1..24];
             if ((Pos('p', Timeinput) <> 0) or (Pos('P', Timeinput) <> 0)) and
                 (Hour < 12) then
                     Hour := Hour+12;
             Timeinput := Copy(Timeinput, J+1, Length(Timeinput));
             Val(Timeinput, I, J);
             Minute := I;
             Right := Minute in [0..59];
         end (* if *);
end (* ParseDate *);

function FindDay(ForDay  : DateRec)  : String10;
begin   with ForDay do begin
            K := Year-1984;
            X := K*365 + ((K-1) div 4);
            if ((K mod 4) = 0) then
                if (Month >= 3) then
                    X := X+1;
            X := X + DaysinYear[Month] + Day;
            FindDay := DayNames[ Trunc((X-Int(X/7)*7)) ];
        end (* with *);
end (* FindDay *);

function ShortDate(ForDay  : DateRec)  : String10;
begin    FillChar(StrA, SizeOf(StrA), 32);
         with ForDay do begin
             Str(Month, StrA);
             Str(Day, StrB);
             StrA := StrA+'/'+StrB+'/';
             Str(Year, StrB);
             StrA := StrA+Copy(StrB,3,2);
         end (* with *);
         StrA[0] := #8;
         ShortDate := StrA;
end (* ShortDate *);

function ShortTime(ForDay  : DateRec)  : String10;
begin   FillChar(StrA, SizeOf(StrA), 32);
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
                StrA := StrA+' pm';
        end (* with *);
        StrA[0] := #8;
        ShortTime := StrA;
end (* ShortDate *);

procedure DateString(ForDay  : DateRec);
begin   with ForDay do begin
            Write('  ', FindDay(ForDay), ', ');
            Write(MonthNames[Month], ' ', Day, ', ', Year);
            Write('  ', ShortTime(ForDay));
        end (* with *);
end (* with *);

