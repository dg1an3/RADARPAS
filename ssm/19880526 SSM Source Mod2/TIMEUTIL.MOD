IMPLEMENTATION MODULE TimeUtilities;

(*
========================================================

 Created   : 8/3/87
 Last Edit : 8/3/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Provides various formatting options for date and time.
 Two formats for time and three for date.  Time and date
 are passed as the Time record imported from TimeDate.
 Also provides addition and subtraction of dates.
========================================================
*)

IMPORT ASCII;
FROM MathLib0 IMPORT
FROM NumberConversion IMPORT
  CardToString;
FROM Strings IMPORT
  Assign, Concat;
FROM SYSTEM IMPORT
  BYTE, WORD, DOSCALL;
FROM TimeDate IMPORT
  Time;

VAR
  DaysinYear : ARRAY[1..12] OF CARDINAL;
(* Holds values for number of days in year up to corresponding month.
   For instance, DaysinYear[3] holds the number of days up to the 
   beginning of March (the days in January plus the days in February). *)

  DayName : ARRAY[0..6],[0..8] OF CHAR;
(* Holds the names of the days of the week. *)

  MonthName : ARRAY[1..12],[0..8] OF CHAR;
(* Holds the names of the months of the year. *)

PROCEDURE Time12Hour(ForTime  : Time;
                 VAR ToString : ARRAY OF CHAR);
(* Provides time in format like 11:59pm.  All times returned
   take seven spaces. *)
VAR
  Hour, Minute : CARDINAL;
  AM           : BOOLEAN;
  TempString   : ARRAY[0..2] OF CHAR;
BEGIN
  Hour:=ForTime.minute DIV 60;
  Minute:=ForTime.minute MOD 60;
  IF (HIGH(ToString)>=7) AND (Hour<=23) AND (Minute<=59) THEN
    AM:=Hour<12;
    IF Hour=0 THEN 
      Hour:=12
    ELSIF Hour>12 THEN 
      Hour:=Hour-12 
    END; (* IF *)
    CardToString(Hour,ToString,2);
    Concat(ToString,':',ToString);
    CardToString(Minute,TempString,2);
    IF TempString[0]=' ' THEN TempString[0]:='0' END;
    Concat(ToString,TempString,ToString);
    IF AM THEN
      Concat(ToString,'am',ToString);
    ELSE
      Concat(ToString,'pm',ToString);
    END; (* IF *)
  ELSE
    ToString[0]:=ASCII.nul;
  END; (* IF *)
END Time12Hour;

PROCEDURE Time24Hour(ForTime  : Time;
                 VAR ToString : ARRAY OF CHAR);
(* Provides time in format like 23:59.  For hours less than
   ten, a zero is added to the beginning.  All times returned
   take five spaces. *)
VAR
  Hour, Minute : CARDINAL;
  TempString   : ARRAY[0..2] OF CHAR;
BEGIN
  Hour:=ForTime.minute DIV 60;
  Minute:=ForTime.minute MOD 60;
  IF (HIGH(ToString)>=5) AND (Hour<=23) AND (Minute<=59) THEN
    CardToString(Hour,ToString,2);
    IF ToString[0]=' ' THEN ToString[0]:='0' END;
    Concat(ToString,':',ToString);
    CardToString(Minute,TempString,2);
    IF TempString[0]=' ' THEN TempString[0]:='0' END;
    Concat(ToString,TempString,ToString);
  ELSE
    ToString[0]:=ASCII.nul;
  END; (* IF *)
END Time24Hour;

PROCEDURE ShortDate(ForDate  : Time;
                VAR ToString : ARRAY OF CHAR);
(* Provides date in form 12/20/87.  If less than two digits
   are used for month or day, they are padded with zeroes (for
   instance, 01/01/87).  All dates in this format are eight 
   characters long. *)
VAR
  Year, Month, Day : CARDINAL;
  TempString       : ARRAY[0..2] OF CHAR;
BEGIN
  Year:=ForDate.day DIV 512;
  Month:=ForDate.day MOD 512 DIV 32;
  Day:=ForDate.day MOD 32;
  IF (HIGH(ToString)>=8) AND (0<Month) AND (Month<=12) AND 
    (0<Day) AND (Day<=31) THEN
    CardToString(Month,ToString,2);
    IF ToString[0]=' ' THEN ToString[0]:='0' END;
    Concat(ToString,'/',ToString);
    CardToString(Day,TempString,2);
    IF TempString[0]=' ' THEN TempString[0]:='0' END;
    Concat(ToString,TempString,ToString);
    Concat(ToString,'/',ToString);
    IF Year>99 THEN Year:=Year-100 END;
    CardToString(Year,TempString,2);
    Concat(ToString,TempString,ToString);
  ELSE
    ToString[0]:=ASCII.nul;
  END; (* IF *)
END ShortDate;

PROCEDURE DayofWeek(ForDate  : Time;
                VAR ToString : ARRAY OF CHAR);
(* Returns the day of week for the indicated date.  The
   returned string is the full name of the day of week, and
   no padding is done, so the string is of variable length. *)
VAR
  Year, Month, Day : CARDINAL;
  DayCount         : REAL;
BEGIN
  Year:=ForDate.day DIV 512;
  Month:=ForDate.day MOD 512 DIV 32;
  Day:=ForDate.day MOD 32;
  IF (HIGH(ToString)>=9) AND (0<Month) AND (Month<=12) AND 
    (0<Day) AND (Day<=31) THEN
    DayCount:=Year*365.0+(Year-1) DIV 4;
    IF ((Year MOD 4)=0) AND (Month>2) THEN DayCount:=DayCount+1 END;
    DayCount:=DayCount+real(DaysinYear[Month])+real(Day);
    Assign(DayName[DayCount MOD 7],ToString);
  ELSE
    ToString[0]:=ASCII.nul;
  END; (* IF *)
END DayofWeek;

PROCEDURE DayPlusDate(ForDate  : Time;
                  VAR ToString : ARRAY OF CHAR);
(* Returns the date in the form Wed 12/20/87.  All day of week
   names are the first three letters only.  Padding is done on
   date similar to MonthDayYear format.  All dates returned are
   twelve characters long. *)
VAR
  TempString : ARRAY[0..7] OF CHAR;
BEGIN
  IF HIGH(ToString)>=12 THEN
    DayofWeek(ForDate,ToString);
    ToString[3]:=' ';
    ToString[4]:=ASCII.nul;
    ShortDate(ForDate,TempString);
    Concat(ToString,TempString,ToString);
  END; (* IF *)
END DayPlusDate;

PROCEDURE LongDate(ForDate  : Time;
               VAR ToString : ARRAY OF CHAR);
(* Returns the date in the form Wednesday, December 20, 1987.
   No padding is performed, so strings may be of variable 
   length. *)
VAR
  Year, Month, Day : CARDINAL;
  TempString       : ARRAY[0..5] OF CHAR;
BEGIN
  Year:=ForDate.day DIV 512;
  Month:=ForDate.day MOD 512 DIV 32;
  Day:=ForDate.day MOD 32;
  IF HIGH(ToString)>=29 THEN
    DayofWeek(ForDate,ToString);
    CASE Month OF
       1 : Concat(ToString,', January ',ToString); |
       2 : Concat(ToString,', February ',ToString); |
       3 : Concat(ToString,', March ',ToString); |
       4 : Concat(ToString,', April ',ToString); |
       5 : Concat(ToString,', May ',ToString); |
       6 : Concat(ToString,', June ',ToString); |
       7 : Concat(ToString,', July ',ToString); |
       8 : Concat(ToString,', August ',ToString); |
       9 : Concat(ToString,', September ',ToString); |
      10 : Concat(ToString,', October ',ToString); |
      11 : Concat(ToString,', November ',ToString); |
      12 : Concat(ToString,', December ',ToString);
      ELSE
    END; (* CASE *)
    CardToString(Day,TempString,0);
    Concat(ToString,TempString,ToString);
    Concat(ToString,', ',ToString);
    CardToString(Year+1900,TempString,0);
    Concat(ToString,TempString,ToString);
  END; (* IF *)
END LongDate;

PROCEDURE StringToTime(FromString : ARRAY OF CHAR;
                   VAR ToTime     : Time;
                   VAR OK         : BOOLEAN);
(* Converts the time in FromString and stores it in the time record of
   ToTime.  Searches for 'a' or 'p' at the end to indicate am or pm; if
   none is found, assumes time is 24 hour time. *)
VAR
  Hour, Minute, Pos : CARDINAL;
BEGIN
  Pos:=0;
  Hour:=ORD(FromString[Pos])-48; INC(Pos);
  IF ('0'<=FromString[Pos]) AND (FromString[Pos]<='9') THEN
    Hour:=Hour*10+ORD(FromString[1])-48;
    INC(Pos);
  END; (* IF *)
  OK:=(0<=Hour) AND (Hour<=23) AND (Pos<HIGH(FromString));
  Minute:=(ORD(FromString[Pos])-48)*10+ORD(FromString[Pos+1])-48;
  INC(Pos); INC(Pos);
  IF (Pos<HIGH(FromString)) THEN
    IF CAP(FromString[Pos])='A' THEN OK:=OK AND (1<=Hour) AND (Hour<=12) END;
    IF CAP(FromString[Pos])='P' THEN
      OK:=OK AND (1<=Hour) AND (Hour<=12);
      Hour:=Hour+12;
      IF Hour=24 THEN Hour:=0 END;
    END; (* IF *)
  END; (* IF *)
  IF OK THEN ToTime.minute:=Hour*60+Minute END;
END StringToTime;

PROCEDURE StringToDate(FromString : ARRAY OF CHAR;
                   VAR ToDate     : Time;
                   VAR OK         : BOOLEAN);
(* Converts the date in FromString and stores it in the date record of
   ToDate.  Month, day, and year can be separated by any non-numeric
   character, such as '/','-', or even a space. *)
VAR
  Month, Day, Year, Pos : CARDINAL;
BEGIN
  Pos:=0;
  Month:=ORD(FromString[Pos])-48; INC(Pos);
  IF ('0'<=FromString[Pos]) AND (FromString[Pos]<='9') THEN
    Month:=Month*10+ORD(FromString[Pos])-48;
    INC(Pos);
  END; (* IF *)
  INC(Pos);
  OK:=(1<=Month) AND (Month<=12) AND (Pos<HIGH(FromString));
  Day:=ORD(FromString[Pos])-48; INC(Pos);
  IF ('0'<=FromString[Pos]) AND (FromString[Pos]<='9') THEN
    Day:=Day*10+ORD(FromString[Pos])-48;
    INC(Pos);
  END; (* IF *)
  INC(Pos);
  OK:=(1<=Day) AND (Day<=31) AND (Pos<HIGH(FromString));
  Year:=(ORD(FromString[Pos])-48)*10+ORD(FromString[Pos+1])-48;
  OK:=(0<=Year) AND (Year<=99);
  IF Year<28 THEN Year:=Year+100 END;
  IF OK THEN ToDate.day:=Year*512+Month*32+Day END;
END StringToDate;

PROCEDURE AddDays(ToDate : Time;
                  Days   : INTEGER;
              VAR Result : Time);
(* Adds Days number of days to ToDate, returning the resulting date.
   Days can be positive or negative. *)
VAR

BEGIN
END AddDays;

PROCEDURE SubDates(Date1,Date2 : Time;
               VAR Difference  : INTEGER);
(* Subtracts the two dates, returning the number of days difference
   between the two.  If Date1 is earlier, Difference is positive,
   otherwise it will be negative. *)
BEGIN
END SubDates;

BEGIN
  DaysinYear[1]:=0;
  DaysinYear[2]:=31;
  DaysinYear[3]:=59;
  DaysinYear[4]:=90;
  DaysinYear[5]:=120;
  DaysinYear[6]:=151;
  DaysinYear[7]:=181;
  DaysinYear[8]:=212;
  DaysinYear[9]:=243;
  DaysinYear[10]:=273;
  DaysinYear[11]:=304;
  DaysinYear[12]:=334;
  DayName[0]:='Sunday';
  DayName[1]:='Monday';
  DayName[2]:='Tuesday';
  DayName[3]:='Wednesday';
  DayName[4]:='Thursday';
  DayName[5]:='Friday';
  DayName[6]:='Saturday';
  MonthName[1]:='January';
  MonthName[2]:='February';
  MonthName[3]:='March';
  MonthName[4]:='April';
  MonthName[5]:='May';
  MonthName[6]:='June';
  MonthName[7]:='July';
  MonthName[8]:='August';
  MonthName[9]:='September';
  MonthName[10]:='October';
  MonthName[11]:='November';
  MonthName[12]:='December';
END TimeUtilities.
