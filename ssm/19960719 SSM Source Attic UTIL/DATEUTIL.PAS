(* DateUtil.pas  Date handling routines *)
(* Copyright (C) 1985,1996 Derek G. Lane *)

type    DateRec  = record
            Month  : byte;
            Day  : byte;
            Year  : integer;
            Hour  : byte;
            Minute  : byte;
        end (* DateRec *);

(* These types are provided by other files * )
        ShortStr  = string[12];
        LongStr  = string[80]; *)

const   DaysinMonth  : array [1..12] of byte =
            (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

        DaysinYear  : array [1..12] of integer =
            (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);

        DayNames  : array [0..6] of string[9] =
            ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

        MonthNames  : array [1..12] of string[9] =
            ('January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December');

        DefaultTime  : DateRec = (Month:0; Day:0; Year:0;
            Hour:23; Minute:59);    (* 11:59pm *)

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

procedure ParseDate(DateInput, TimeInput  : ShortStr;
                    var ForDay  : DateRec;
                    var valid  : boolean);
var      num, nextChar  : integer;
begin    with ForDay do begin
             Val(DateInput, num, nextChar);
             Month := num;
             Dateinput := Copy(DateInput, nextChar+1, Length(Dateinput));
             Val(DateInput, num, nextChar);
             Day := num;
             DateInput := Copy(DateInput, nextChar+1, Length(Dateinput));
             Val(DateInput, num, nextChar);
             Year := num;
             if (Year < 100) then
                 if (Year > 80) then
                     Year := Year + 1900
                 else
                     Year := Year + 2000;
             if (Length(TimeInput) >= 4) then begin
                 Val(TimeInput, num, nextChar);
                 Hour := num;
                 if ((Pos('p', TimeInput) <> 0) or
                     (Pos('P', TimeInput) <> 0)) and (Hour < 12) then
                     Hour := Hour + 12;
                 TimeInput := Copy(TimeInput, nextChar+1, Length(Timeinput));
                 Val(TimeInput, num, nextChar);
                 Minute := num;
             end else begin
                 Hour := DefaultTime.Hour;
                 Minute := DefaultTime.Minute;
             end (* if *);
             valid := (Year >= 1984) and (Month in [1..12]) and
                 (Day in [1..31]) and (Hour in [1..24]) and
                 (Minute in [0..59]);
         end (* if *);
end (* ParseDate *);

function FindDay(ForDay  : DateRec)  : ShortStr;
var     numOfYears  : integer;
        numOfDays  : real;
begin   with ForDay do begin
            numOfYears := Year - 1984;
            numOfDays := numOfYears*365 + ((numOfYears-1) div 4);
            if ((numOfYears mod 4) = 0) then
                if (Month >= 3) then
                    numOfDays := numOfDays+1;
            numOfDays := numOfDays + DaysinYear[Month] + Day;
            FindDay := DayNames[Trunc((numOfDays-Int(numOfDays/7)*7))];
        end (* with *);
end (* FindDay *);

function ShortDate(ForDay  : DateRec)  : ShortStr;
var      dateStr, numStr  : ShortStr;
begin    FillChar(dateStr, SizeOf(dateStr), 32);
         with ForDay do begin
             Str(Month, dateStr);
             Str(Day, numStr);
             dateStr := dateStr+'/'+numStr+'/';
             Str(Year, numStr);
             dateStr := dateStr+Copy(numStr,3,2);
         end (* with *);
         dateStr[0] := #8;
         ShortDate := dateStr;
end (* ShortDate *);

function ShortTime(ForDay  : DateRec)  : ShortStr;
var     timeStr, numStr  : ShortStr;
begin   FillChar(timeStr, SizeOf(timeStr), 32);
        with ForDay do begin
            if ((Hour mod 12) <> 0) then
                Str(Hour mod 12, timeStr)
            else
                timeStr := '12';
            Str(Minute, numStr);
            if (Minute < 10) then
                timeStr := timeStr+':0'+numStr
            else
                timeStr := timeStr+':'+numStr;
            if (Hour < 12) then
                timeStr := timeStr+' am'
            else
                timeStr := timeStr+' pm';
        end (* with *);
        timeStr[0] := #8;
        ShortTime := timeStr;
end (* ShortTime *);

procedure DateString(ForDay  : DateRec);
begin   with ForDay do begin
            Write('  ', FindDay(ForDay), ', ');
            Write(MonthNames[Month], ' ', Day, ', ', Year);
            Write('  ', ShortTime(ForDay));
        end (* with *);
end (* DateString *);

procedure GetSysDate(var currDate  : DateRec);
type    RegType  = record
            case integer of
                1 : (ax, bx, cx, dx, bp, si, di, ds, es, Flags  : integer);
                2 : (al, ah, bl, bh, cl, ch, dl, dh  : byte);
        end (* RegType *);
var     regs  : RegType;    (* record for MsDos call *)
begin   with regs do begin
            ah := $2a;
            MSDOS(regs);
            currDate.year := cx;
            currDate.month := dx shr 8;
            currDate.day := dx mod 256;
            ax := $2c shl 8;
            MSDOS(regs);
            currDate.hour := cx shr 8;
            currDate.minute := cx mod 256;
        end (* with *);
end (* GetSysDate *);

(* Testing socket for dateutil.pas
begin
end ( * DateUtil *)