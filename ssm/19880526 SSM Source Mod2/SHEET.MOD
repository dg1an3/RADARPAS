IMPLEMENTATION MODULE Sheet;

(*
========================================================

 Created   : 5/4/87
 Last Edit : 5/4/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Data entry library.  Allows installation of "demon"
 procedures to be called when a cells value is changed.
========================================================
*)

IMPORT ASCII;
FROM ExtendKey IMPORT
  ExtRead;
IMPORT ExtendKey;
FROM Keyboard IMPORT
  Read;
FROM NumberConversion IMPORT
  CardToString, IntToString, StringToCard, StringToInt;
FROM RealConversions IMPORT
  RealToString, StringToReal;
FROM Strings IMPORT
  Length, Copy, Concat, Assign;
FROM SYSTEM IMPORT
  ADR, BYTE, SIZE;
IMPORT WM;

VAR
  WMResult   : CARDINAL;

PROCEDURE WriteCell(ForCell : CellRec);
(* Writes the current value associated with the cell ForCell. *)
VAR
  ValString : ARRAY[0..39] OF CHAR;
  OK        : BOOLEAN;
BEGIN
  WITH ForCell DO
    CASE CellType OF
      Boolean  :
        IF BoolVal^ THEN
          ValString:='*';
        ELSE
          ValString:=' ';
        END; (* IF *) |
      Integer  : IntToString(IntVal^,ValString,Size); |
      Cardinal : CardToString(CardVal^,ValString,Size); |
      Real     : 
        RealToString(RealVal^,2,Size,ValString,OK);
        IF NOT OK THEN
          ValString:='???';
        END; (* IF *) |
      String   : Assign(StrVal^,ValString);
    END; (* CASE *)
    WMResult:=WM.SetScreenCursor(0,Row,Col);
    WMResult:=WM.Propagate(0,' ',1,Size,4);
    WMResult:=WM.Write(0,ValString);
  END; (* WITH *)
END WriteCell;

PROCEDURE ReadCell(ForCell : CellRec; Key : CHAR);
(* Reads the cell ForCell, storing its value and calling the WhenChanged
   demon.  Key contains a preliminary key to be processed. *)
VAR
  ValString : ARRAY[0..39] OF CHAR;
  OK        : BOOLEAN;
BEGIN
  WITH ForCell DO
    WMResult:=WM.Propagate(0,' ',2,Size,4);
    WMResult:=WM.SetDefaultAttribute(0,2);
    WMResult:=WM.SetCursorType(0,2);
    ValString:=''; 
    OK:=TRUE;
    LOOP
      IF Key=ASCII.EOL THEN 
        EXIT;
      ELSIF (Key=ASCII.bs) AND (Length(ValString)>0) THEN 
        Copy(ValString,0,Length(ValString)-1,ValString);
        WMResult:=WM.Write(0,ASCII.bs);
      ELSE
        CASE CellType OF
          Integer  : OK:=(Key='-') OR (Key>='0') AND (Key<='9'); |
          Cardinal : OK:=(Key>='0') AND (Key<='9'); |
          Real     : OK:=(Key>='0') AND (Key<='9') OR (Key='-') OR (Key='.');
          ELSE OK:=(Key>=' ') AND (Key<='~');
        END; (* CASE *)
        IF OK AND (Length(ValString)<Size) THEN
          Concat(ValString,Key,ValString);
          WMResult:=WM.Write(0,Key);
        END;
      END; (* IF *)
      Read(Key);
    END; (* LOOP *)
    IF ValString[0]<>ASCII.nul THEN
      CASE CellType OF
        Boolean  : BoolVal^:=(ValString[1]<>' '); |
        Integer  : StringToInt(ValString,IntVal^,OK); |
        Cardinal : StringToCard(ValString,CardVal^,OK); |
        Real     : StringToReal(ValString,RealVal^,OK); |
        String   : Assign(ValString,StrVal^);
      END; (* CASE *)
    END; (* IF *)
    WMResult:=WM.SetDefaultAttribute(0,1);
    WMResult:=WM.SetCursorType(0,0);
    WriteCell(ForCell);
  END; (* WITH *)
END ReadCell;

PROCEDURE RefreshSheet(ForSheet : ARRAY OF CellRec);
(* Rewrites entire sheet. *)
VAR
  AtCell : CARDINAL;
BEGIN
  FOR AtCell:=0 TO HIGH(ForSheet) DO
    WriteCell(ForSheet[AtCell]);
  END; (* FOR *)
END RefreshSheet;

PROCEDURE EditSheet(ForSheet : ARRAY OF CellRec);
(* Allows editing of an entire sheet, using cursor keys for movement. *)
VAR
  AtCell    : CARDINAL;
  Key       : CHAR;
  Extend    : BOOLEAN;

BEGIN
  AtCell:=0;
  LOOP
    WITH ForSheet[AtCell] DO
      WMResult:=WM.SetScreenCursor(0,Row,Col+Size-1);
      WMResult:=WM.SetScreenCursor(0,Row,Col);
      WMResult:=WM.Propagate(0,0C,2,Size,0);
      ExtRead(Key,Extend);
      WMResult:=WM.Propagate(0,0C,1,Size,0);
      IF Extend THEN
        CASE Key OF
          ExtendKey.rarr : (* AtCell:=CellRight(ForSheet[AtCell]); *) |
          ExtendKey.larr : (* AtCell:=CellLeft(ForSheet[AtCell]);  *) |
          ExtendKey.uarr : (* AtCell:=CellUp(ForSheet[AtCell]);    *) |
          ExtendKey.darr : (* AtCell:=CellDown(ForSheet[AtCell]);  *) |
          ExtendKey.Home : AtCell:=0; |
          ExtendKey.End  : AtCell:=HIGH(ForSheet);
          ELSE
        END; (* CASE *)
      ELSE
        CASE Key OF
          ASCII.EOL, ASCII.ht :
            IF AtCell<HIGH(ForSheet) THEN INC(AtCell) END; |
          ASCII.bs :
            IF AtCell>0 THEN DEC(AtCell) END; |
          ASCII.esc :
            EXIT; |
          ' '..'~' :
            ReadCell(ForSheet[AtCell],Key);
            IF AtCell<HIGH(ForSheet) THEN INC(AtCell) END;
          ELSE
        END; (* CASE *)
      END; (* IF *)
    END; (* WITH *)
  END; (* LOOP *)
END EditSheet;  

TYPE
  SetProc = PROCEDURE(INTEGER);
  (* SetProc is a type of procedure called by List to set the indicated
     cell value.  The parameter passed is the relative offset from the
     current cell to move. *)

PROCEDURE List(VAR ForSheet : ARRAY OF CellRec;
                   SetCell  : SetProc);
(* Displays a list of values using ForSheet as a template to write the
   values. *)
VAR
  Count,
  srows,scols,
  crow,ccol,
  flags      : CARDINAL;
  CurrEntry  : INTEGER; (* The current entry, as a row number *)
  Key        : CHAR;
  Extend     : BOOLEAN;
BEGIN
  WMResult:=WM.GetScreenStatus(0,srows,scols,crow,ccol,flags);
  LOOP
    IF (CurrEntry<1) OR (CurrEntry>INT(srows)) THEN
      SetCell(1-srows DIV 2);
      FOR CurrEntry:=1 TO srows DO
        FOR Count:=0 TO HIGH(ForSheet) DO 
          ForSheet[Count].Row:=CurrEntry;
        END; (* FOR *)
        RefreshSheet(ForSheet);
        SetCell(1);
      END; (* FOR *)
      CurrEntry:=srows DIV 2;
      SetCell(srows-CurrEntry);
    END; (* IF *)
    WMResult:=WM.SetScreenCursor(0,CurrEntry,1);
    WMResult:=WM.Propagate(0,0C,2,0,6);
    ExtRead(Key,Extend);
    WMResult:=WM.Propagate(0,0C,1,0,6);
    IF Extend THEN
      CASE Key OF
        ExtendKey.uarr : DEC(CurrEntry); |
        ExtendKey.darr : INC(CurrEntry); |
        ExtendKey.PgUp : CurrEntry:=CurrEntry-srows; |
        ExtendKey.PgDn : CurrEntry:=CurrEntry+srows; |
        ExtendKey.Home : CurrEntry:=1; |
        ExtendKey.End  : CurrEntry:=srows;
        ELSE EXIT;
      END; (* CASE *)
    END; (* IF *)
  END; (* LOOP *)
END List;

VAR
  WMBuffer : ARRAY[0..16384] OF BYTE;
  TestCell : ARRAY[0..3] OF CellRec;
  TestStr  : ARRAY[0..10] OF CHAR;
  TestCard : CARDINAL;
  TestInt  : INTEGER;
  TestReal : REAL;
  Key      : CHAR;
  CurrScreen : WM.Screen;


BEGIN
  WMResult:=WM.InitWM(ADR(WMBuffer),SIZE(WMBuffer));
  WMResult:=WM.CreateScreenWithWindow(CurrScreen,20,70,5,5,10,25);
  WMResult:=WM.DefineAttribute(CurrScreen,1,1FH);
  WMResult:=WM.DefineAttribute(CurrScreen,2,4FH);
  WMResult:=WM.SetBorderType(CurrScreen,2);
  WMResult:=WM.SetDefaultAttribute(CurrScreen,1);
  WMResult:=WM.FillScreenAttributes(CurrScreen,1);
  WMResult:=WM.OpenWindow(CurrScreen);
  WITH TestCell[0] DO
    Row:=8; Col:=20; Size:=10;
    CellType:=Integer;
    IntVal:=ADR(TestInt);
    TestInt:=-273;
  END;
  WITH TestCell[1] DO
    Row:=8; Col:=5; Size:=5;
    CellType:=Cardinal;
    CardVal:=ADR(TestCard);
    TestCard:=69;
  END;
  WITH TestCell[2] DO
    Row:=5; Col:=2; Size:=10;
    CellType:=String;
    StrVal:=ADR(TestStr);
    TestStr:='Hello';
  END;
  WITH TestCell[3] DO
    Row:=1; Col:=20; Size:=10;
    CellType:=Real;
    RealVal:=ADR(TestReal);
    TestReal:=3.1415;
  END;
  RefreshSheet(TestCell);
  EditSheet(TestCell);
  WMResult:=WM.SetPhysicalCursor(10,10,2);
END Sheet.
