(*****************************************************************************)
(*     General purpose routines                                              *)
(*****************************************************************************)

VAR
  Key    : CHAR;
  Escape : BOOLEAN;

PROCEDURE ReadKbd;

  BEGIN
    Read(Kbd,Key);
    IF KeyPressed THEN BEGIN
      Read(Kbd,Key);
      Escape:=TRUE;
    END
    ELSE Escape:=FALSE;
  END;


PROCEDURE Quit; FORWARD;


(*****************************************************************************)
(*     Date handling routines                                                *)
(*****************************************************************************)

CONST
  DaysinMonth  : ARRAY[1..12] of BYTE =
  (31,28,31,30,31,30,31,31,30,31,30,31);

  DaysinYear   : ARRAY[1..12] of INTEGER =
  (0,31,59,90,120,151,181,212,243,273,304,334);

  DayNames     : ARRAY[0..6] of STRING[9] =
  ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

  MonthNames   : ARRAY[1..12] of STRING[9] =
  ('January','February','March','April','May','June',
   'July','August','September','October','November','December');


VAR
  ADate        : DateRec;

FUNCTION SubDates(Date1,Date2 : DateRec) : INTEGER;
VAR
  Days : integer;
BEGIN
  Days:=DaysinYear[Date1.Month]+Date1.Day-DaysinYear[Date2.Month]-Date2.Day;
  if Date2.Year<>Date1.Year then Days:=Days+365*(Date1.Year-Date2.Year);
  SubDates:=Days;
END; (* SubDates *)

FUNCTION CompareDates(Date1,Date2 : DateRec) : INTEGER;

  BEGIN
    IF Date1.Year=Date2.Year THEN
      IF Date1.Month=Date2.Month THEN
        IF Date1.Day=Date2.Day THEN
          IF Date1.Hour=Date2.Hour THEN CompareDates:=Date1.Minute-Date2.Minute
            ELSE CompareDates:=Date1.Hour-Date2.Hour
          ELSE CompareDates:=Date1.Day-Date2.Day
        ELSE CompareDates:=Date1.Month-Date2.Month
      ELSE CompareDates:=Date1.Year-Date2.Year;
  END;


PROCEDURE ParseDate(DateInput,TimeInput : String10; VAR ForDay : DateRec);

  BEGIN
    Right:=TRUE;
    WITH ForDay DO BEGIN
      VAL(Dateinput,I,J); Month:=I;
      IF NOT(Month in [1..12]) THEN Right:=FALSE;
      Dateinput:=Copy(Dateinput,J+1,Length(Dateinput));
      VAL(Dateinput,I,J);Day:=I;
      IF NOT(Day in [1..31]) THEN Right:=FALSE;
      Dateinput:=Copy(Dateinput,J+1,Length(Dateinput));
      VAL(Dateinput,Year,J);
      IF Year<100 THEN
        IF Year>80 THEN Year:=Year+1900
          ELSE Year:=Year+2000;
      IF Year<1984 THEN Right:=FALSE;
      IF Length(Timeinput)<4 THEN Timeinput:='11:59p';
      VAL(Timeinput,I,J);Hour:=I;
      IF NOT(Hour in [1..24]) THEN Right:=FALSE;
      IF (Pos('p',Timeinput)<>0) OR (Pos('P',Timeinput)<>0) THEN
        IF Hour<12 THEN Hour:=Hour+12;
      Timeinput:=Copy(Timeinput,J+1,Length(Timeinput));
      VAL(Timeinput,I,J);Minute:=I;
        IF NOT(Minute in [0..59]) THEN Right:=FALSE;
    END;
  END;


FUNCTION FindDay(ForDay : DateRec) : String10;

  BEGIN
    WITH ForDay DO BEGIN
      K:=Year-1984;
      X:=K*365+((K-1) div 4);
      IF (K mod 4)=0 THEN
        IF Month>=3 THEN X:=X+1;
      X:=X+DaysinYear[Month]+Day;
      FindDay:=DayNames[Trunc((X-Int(X/7)*7))];
    END;
  END;


FUNCTION ShortDate(ForDay : DateRec) : String10;

  BEGIN
    FillChar(StrA,SizeOf(StrA),32);
    WITH ForDay DO BEGIN
      Str(Month,StrA);
      Str(Day,StrB);StrA:=StrA+'/'+StrB+'/';
      Str(Year,StrB);StrA:=StrA+Copy(StrB,3,2);
    END;
    StrA[0]:=#8;
    ShortDate:=StrA;
  END;


FUNCTION ShortTime(ForDay : DateRec) : String10;

  BEGIN
    FillChar(StrA,SizeOf(StrA),32);
    WITH ForDay DO BEGIN
      IF (Hour mod 12)<>0 THEN Str(Hour mod 12,StrA) ELSE StrA:='12';
      Str(Minute,StrB);
      IF Minute<10 THEN StrA:=StrA+':0'+StrB ELSE StrA:=StrA+':'+StrB;
      IF (Hour<12) THEN StrA:=StrA+' am' ELSE StrA:=StrA+' pm';
    END;
    StrA[0]:=#8;
    ShortTime:=StrA;
  END;


PROCEDURE DateString(ForDay : DateRec);

  BEGIN
    WITH ForDay DO BEGIN
      Write('  ',FindDay(ForDay),', ');
      Write(MonthNames[Month],' ',Day,', ',Year);
      Write('  ',ShortTime(ForDay));
    END;
  END;



(*****************************************************************************)
(*    Screen handling routines                                               *)
(*****************************************************************************)

CONST
  HiLite       = Black;
  HiLiteBack   = White;
  NormVid      = White;
  NormBack     = Black;
  FIMDiskMsg   : LineType =
    'Please put the Fuel Inventory Manager Data Disk in drive B';

TYPE
  RegisterType  = RECORD
    CASE INTEGER of
      1 : (AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : INTEGER);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH : BYTE);
              END;

  CharSet      = SET of CHAR;

  CurrentWinRec= RECORD
    YSize      :   BYTE;
    Data       :   ARRAY[1..60,1..78] of CHAR;
                 END;

VAR
  CurWind      : ^CurrentWinRec;
  Screen       : ARRAY[1..25,1..80,1..2] of CHAR ABSOLUTE $B000:$8000;
  CurrX        : BYTE;
  CurrY        : BYTE;
  TopLine      : BYTE;
  KeyLine      : LineType;
  EditLine     : LineType;
  Registers    : RegisterType;


PROCEDURE Frame(UpperX, UpperY, LowerX, LowerY: INTEGER);

  VAR
    I : INTEGER;

  BEGIN
    GotoXY(UpperX, UpperY);
    Write(chr(201));
    FOR I := (UpperX + 1) to (LowerX - 1) DO Write(chr(205));
    Write(chr(187));
    FOR I := (UpperY + 1) to (LowerY - 1) DO
    BEGIN
      GotoXY(UpperX , I);  Write(chr(186));
      GotoXY(LowerX, I);  Write(chr(186));
    END;
    GotoXY(UpperX, LowerY);
    Write(chr(200));
    FOR I := (UpperX + 1) to (LowerX - 1) DO Write(chr(205));
    Write(chr(188));
    Window(UpperX+1,UpperY+1,LowerX-1,LowerY-1);
  END;


PROCEDURE OneMoment;

  BEGIN
    Window(1,1,80,24);
    ClrScr;
    Frame(28,11,52,15);ClrScr;
    Writeln; Write(' One moment, please... ');
  END;


PROCEDURE Cursor(Startline,Endline : BYTE);

  BEGIN
    WITH Registers DO BEGIN
      AH:=$01;
      CH:=Startline;
      CL:=Endline;
      Intr($10,Registers);
    END;
  END;


PROCEDURE InfoLine;

  BEGIN
    Window(1,1,80,25);
    GotoXY(1,25);
    ClrEol;
    Write(MODULE_NAME, ' ');
    DateString(TodaysDate);
{    IF NOT ChangeStatus THEN BEGIN
      TextColor(LightGray+Blink); Write('  READ-ONLY');
      TextColor(NormVid);
    END;}
  END;


PROCEDURE Message(Line : LineType);

  VAR
    R,C : BYTE;

  BEGIN
    C:=WhereX;R:=WhereY;
    Window(1,1,80,24);
    GotoXY(1,24);
    ClrEol;Write(Line);
    Window(1,1,80,23);
    GotoXY(C,R);
  END;


PROCEDURE ErrorMsg(Line : LineType);

  BEGIN
    TextColor(Black);TextBackground(White);
    Message(''+Line+'. Press any key.');
    TextColor(NormVid);TextBackground(NormBack);
    ReadKbd;
    Message(KeyLine);
  END;


(* PROCEDURE ReadDate;

  BEGIN
    Cursor(0,7);
    Write('Date : ');Read(StrA);
    Write('    Time : ');Read(StrB);
    ParseDate(StrA,StrB,ADate);
    Cursor(16,0);
  END; *)


PROCEDURE DrawLine(VAR Where;AtLine : BYTE);

  VAR
    Line : ARRAY[1..78] of CHAR ABSOLUTE Where;

  BEGIN
    FOR I:= 1 to 78 DO Screen[AtLine,I,1]:=Line[I];
  END;


PROCEDURE ChangeWindow(VAR WindPtr);

  BEGIN
    Window(1,1,80,24);ClrScr;
    CurWind:=Addr(WindPtr);
    WITH CurWind^ DO BEGIN
      IF YSize<=23 THEN K:=YSize ELSE K:=23;
      FOR J:= 1 to K DO
        FOR I:= 1 to 78 DO
          Screen[J,I,1]:=Data[J,I];
      Window(1,1,80,23);
      TopLine:=1;
    END;
    GotoXY(0,0);
  END;


PROCEDURE ReDrawWindow;

  BEGIN
    WITH CurWind^ DO BEGIN
      FOR J:= TopLine to TopLine+22 DO
        FOR I:= 1 to 78 DO
          Screen[J,I,1]:=Data[J,I];
      Window(1,1,80,23);
    END;
  END;


PROCEDURE GotoLine(ToLine : BYTE);

  VAR N : BYTE;

  BEGIN
    N:=ToLine;
    IF N<1 THEN N:=1;
    IF N>CurWind^.YSize-22 THEN N:=CurWind^.YSize-22;
    IF N>=TopLine THEN BEGIN
      GotoXY(1,1);
      WHILE TopLine<>N DO BEGIN
        DelLine;
        TopLine:=TopLine+1;
        DrawLine(CurWind^.Data[TopLine+22],23);
      END;
    END
    ELSE BEGIN
      GotoXY(1,1);
      WHILE TopLine<>N DO BEGIN
        InsLine;
        TopLine:=TopLine-1;
        DrawLine(CurWind^.Data[TopLine],1);
      END;
    END;
  END;


PROCEDURE WGoto(X,Y : BYTE);

  BEGIN
    CurrX:=X;
    CurrY:=Y;
  END;


PROCEDURE ScreenOut(Out : CHAR);

  BEGIN
    CurWind^.Data[CurrY,CurrX]:=Out;
    IF CurrY in [TopLine..TopLine+22] THEN
      Screen[CurrY-TopLine+1,CurrX,1]:=Out;
    CurrX:=CurrX+1;
    IF CurrX>78 THEN BEGIN
      CurrX:=1;
      CurrY:=CurrY+1;
    END;
  END;


FUNCTION ReadScreen(X,Y,Size : BYTE) : LineType;
var
  Count : integer;
  StrA : LineType;
  OX, OY : integer;
BEGIN
  OX:=WhereX; OY:=WhereY;
  with Registers do begin
    StrA:='';
    for Count:=0 to Size do begin
      GotoXY(X+Count,Y);
      AH:=$08;
      BH:=$00;
      Intr($10,Registers);
      StrA:=StrA+CHR(AL);
    end;
  end; (* with *)
  ReadScreen:=StrA;
  GotoXY(OX,OY);
END; (* ReadChar *)

PROCEDURE HiLiteCell(X,Y,Size : BYTE);

  BEGIN
    TextColor(HiLite);TextBackground(HiLiteBack);
    GotoXY(X,Y); Write(ReadScreen(X,Y,Size));
  END;


PROCEDURE LoLiteCell(X,Y,Size : BYTE);

  BEGIN
    TextColor(NormVid);TextBackground(NormBack);
    GotoXY(X,Y); Write(ReadScreen(X,Y,Size));
  END;


VAR
  DecPoint : BOOLEAN;

FUNCTION EnterCell(X,Y,Size : BYTE; Accept : CharSet) : LineType;

  BEGIN
    DecPoint:=FALSE;
    HiLiteCell(X,Y,Size);
    GotoXY(X,Y);Write(Copy('                         ',1,Size));
    Line:='';
    WHILE NOT Escape AND (Key<>#13) DO BEGIN
      IF Key=#8 THEN Line:=Copy(Line,1,Length(Line)-1)
        ELSE IF Key in Accept THEN Line:=Copy(Line+Key,1,Size);
      IF Key='.' THEN DecPoint:=TRUE;
      GotoXY(X,Y);Write(Line:Size+1);
      ReadKbd;
    END;
    LoLiteCell(X,Y,Size);
    EnterCell:=Line;
  END;


PROCEDURE PrintWind;

  VAR C : CHAR;CopyNumber,LineNumber : INTEGER;

  BEGIN
    Message('How many copies?');
    ReadKbd;C:=Key;
    IF C in ['1'..'9'] THEN BEGIN
      FOR I:=1 to (Ord(C)-48) DO BEGIN
        Message('Printing '+C+' copies - copy number '+Chr(I+48)+'...');
        Right:=FALSE;
        LineNumber:=1;
        REPEAT
          Writeln(Lst,CurWind^.Data[LineNumber]);
          LineNumber:=LineNumber+1;
          IF KeyPressed THEN BEGIN
            ReadKbd;
            Message('Printing '+C+' copies - copy number '+Chr(I+48)+'... Stop printing (Y/N)?');
            ReadKbd;
            IF Key='y' THEN BEGIN
              Exit;
            END;
            Message('Printing '+C+' copies - copy number '+Chr(I+48)+'...');
          END;
        UNTIL (LineNumber>CurWind^.YSize) OR Right;
        Write(Lst,#12);
      END;
    END;
  END;



VAR
  DTA           : ARRAY[0..127] of BYTE;
  EntrySize     : REAL;
  Mask          : LineType;
  Option        : INTEGER;


FUNCTION IOError : INTEGER;

  VAR
    IOTemp : INTEGER;
    IOPerm : INTEGER;

  BEGIN
    IOTemp:=IOResult;
    IF IOTemp<>0 THEN IOPerm:=IOTemp;
    IOError:=IOPerm;
  END;


PROCEDURE SetDTA(VAR DTA);

  BEGIN
    WITH Registers DO BEGIN
      AH:= $1A;
      DS:= Seg(DTA);
      DX:= Ofs(DTA);
      MSDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


PROCEDURE SetDir(OptionSelect : INTEGER);

  BEGIN
    SetDTA(DTA);
    Option:=OptionSelect;
    WITH Registers DO BEGIN
      AH:= $4E;
      DS:= Seg(Mask);
      DX:= Ofs(Mask)+1;
      CX:= Option;
      MsDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


FUNCTION DirEntry : LineType;

  BEGIN
    SetDTA(DTA);
    Line:='';I:=30;
    REPEAT
      Line:=Line+Chr(DTA[I]);
      I:=I+1;
    UNTIL DTA[I]=0;
    DirEntry:=Line;
    EntrySize:=(DTA[26]+DTA[27]*$FF)+(DTA[28]+DTA[29]*$FF)*$FFFF;
    WITH Registers DO BEGIN
      AH:= $4F;
      CX:= Option;
      MSDos( Registers );
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


PROCEDURE SetAttribute(Name : LineType;Attribute : BYTE);

  BEGIN
    WITH Registers DO BEGIN
      AX:=$4301;
      Name:=Name+Chr(0);
      CX:=Attribute;
      DX:=Ofs(Name)+1;
      DS:=Seg(Name);
      MsDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


FUNCTION DefaultDrive : BYTE;

  BEGIN
    WITH Registers DO BEGIN
      AH:= $19;
      MSDos(Registers);
      DefaultDrive := AL+1
    END;
  END;


FUNCTION DiskMemory(Drive : BYTE) : REAL;

  BEGIN
    WITH Registers DO BEGIN
      AH:= $36;
      DL:= Drive;
      MSDos(Registers);
      DiskMemory:=((AX*CX*1.0)*BX);
    END;
  END;


PROCEDURE CheckFile(Name : LineType);

  BEGIN
    SetAttribute(Name,$00);
    IF IOError=$01 THEN BEGIN
      (* ErrorMsg('Please put the '+Abbreviation+' Data Disk in drive '+DataDrive); *)
      SetAttribute(Name,$00);
      IF IOError=$01 THEN Quit;
    END;
  END;
