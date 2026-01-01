(* Copyright (C) 1987 Jensen & Partners International *)

(*$S-,R-,I-*)
IMPLEMENTATION MODULE IO;

FROM Str    IMPORT Length,Compare,IntToStr,CardToStr,RealToStr,StrToInt,
                   StrToCard,StrToReal,FixRealToStr;
FROM SYSTEM IMPORT Registers,Seg,Ofs;

IMPORT Lib,Str;


CONST
  TrueStr = 'TRUE';

VAR
  LWW     : BOOLEAN;
  Buffer  : ARRAY[0..MaxRdLength-1] OF CHAR;
  s,e     : CARDINAL;


(*$V-*)

PROCEDURE KeyPressed (): BOOLEAN;
VAR R : Registers;
BEGIN
  WITH R DO
    AH := 0BH;
    Lib.Dos(R);
    RETURN AL=0FFH;
  END;
END KeyPressed;

PROCEDURE TerminalRdStr(VAR string: ARRAY OF CHAR);
VAR
  R : Registers;
  H : CARDINAL;
  I : CARDINAL;
  InputBuffer : RECORD
                  LenBuf : CHAR;
                  Len    : CHAR;
                  Buf    : ARRAY[0..81] OF CHAR;
                END;
BEGIN
  IF Prompt AND NOT LWW THEN WrStr('?'); END;
  LWW := FALSE;
  H := HIGH(string);
  IF H > 80 THEN
    InputBuffer.LenBuf := CHR(82);
  ELSE
    InputBuffer.LenBuf := CHR(H+2);
  END;
  InputBuffer.Len := CHR(0);
  WITH R DO
    DS := Seg(InputBuffer);
    DX := Ofs(InputBuffer);
    AH := 0AH;
    Lib.Dos(R);
  END;
  I := ORD(InputBuffer.Len);
  IF I <= H  THEN
    string[I] := CHR(0);
  END;
  WHILE (I>0) DO
    DEC(I);
    string[I] := InputBuffer.Buf[I];
  END;
  WrLn;
END TerminalRdStr;


PROCEDURE WrStr(s: ARRAY OF CHAR);
BEGIN
  WrStrRedirect(s);
END WrStr;

PROCEDURE RdStr ( VAR s : ARRAY OF CHAR );
BEGIN
  RdStrRedirect(s);
END RdStr;


PROCEDURE RdBuff;
VAR
  p,h : CARDINAL;
BEGIN
  RdStrRedirect(Buffer);
  p := Length(Buffer);
  h := SIZE(Buffer)-1;
  IF p>h-1 THEN p := h-1; END;
  Buffer[p] := CHR(13); INC(p);
  Buffer[p] := CHR(10); INC(p);
  IF p<=h THEN Buffer[p] := CHR(0) END;
  e := p; s := 0;
END RdBuff;



PROCEDURE TerminalWrStr(string: ARRAY OF CHAR);
VAR R : Registers;
BEGIN
  LWW := TRUE;
  WITH R DO
    BX := 1;
    AH := 40H;
    DS := Seg( string );
    DX := Ofs( string );
    CX := Str.Length(string);
    Lib.Dos( R );
  END;
END TerminalWrStr;

PROCEDURE RdKey() : CHAR;
VAR R : Registers;
BEGIN
  WITH R DO
    AH := 8;
    Lib.Dos(R);
    RETURN CHR(AL);
  END;
END RdKey;

(*$V+*)

PROCEDURE WrStrAdj( S : ARRAY OF CHAR; Length : INTEGER );
VAR
  L : CARDINAL;
  a : INTEGER;
BEGIN
  OK := TRUE;
  IF RdLnOnWr  THEN RdLn; END;
  L := Str.Length( S );
  a := ABS( Length ) - INTEGER( L );
  IF (a < 0) AND ChopOff THEN
    L := CARDINAL(ABS(Length));
    IF L<=HIGH(S) THEN S[L] := CHR(0); END;
    WHILE (L>0) DO DEC(L); S[L] := '?'; END;
    OK := FALSE;
    a  := 0;
  END;
  IF (Length > 0) AND (a > 0) THEN WrCharRep( ' ',a ); END;
  WrStr( S );
  IF (Length < 0) AND (a > 0) THEN WrCharRep( ' ',a ); END;
END WrStrAdj;

(*$V+*)

PROCEDURE WrChar( V: CHAR );
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WrStr( V );
END WrChar;

PROCEDURE WrCharRep(V: CHAR; count: CARDINAL);
VAR
  s   : ARRAY[0..80] OF CHAR;
  i,j : CARDINAL;
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WHILE count>0 DO
    i := SIZE(s)-2;
    IF i>count THEN i := count END;
    DEC(count,i);
    j := 0;
    WHILE (j<i) DO s[j] := V; INC(j) END;
    s[j] := CHR(0);
    WrStr(s);
  END;
END WrCharRep;

PROCEDURE WrBool(V: BOOLEAN; Length: INTEGER);
BEGIN
  IF V THEN
    WrStrAdj(TrueStr,Length);
  ELSE
    WrStrAdj('FALSE',Length);
  END;
END WrBool;

PROCEDURE WrShtInt(V: SHORTINT; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  IntToStr( VAL( LONGINT,V ),s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrShtInt;

PROCEDURE WrInt(V: INTEGER; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  IntToStr( VAL( LONGINT,V ),s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrInt;

PROCEDURE WrLngInt(V: LONGINT; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  IntToStr( V,s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrLngInt;

PROCEDURE WrShtCard(V: SHORTCARD; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( VAL( LONGCARD,V ),s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrShtCard;

PROCEDURE WrCard(V: CARDINAL; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( VAL( LONGCARD,V ),s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrCard;

PROCEDURE WrLngCard(V: LONGCARD; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( V,s,10,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrLngCard;

PROCEDURE WrShtHex(V: SHORTCARD; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( VAL( LONGCARD,V ),s,16,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrShtHex;

PROCEDURE WrHex(V: CARDINAL; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( VAL( LONGCARD,V ),s,16,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrHex;

PROCEDURE WrLngHex(V: LONGCARD; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  CardToStr( V,s,16,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrLngHex;

PROCEDURE WrReal(V: REAL; Precision: CARDINAL; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RealToStr( VAL( LONGREAL,V ),Precision,Eng,s,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrReal;

PROCEDURE WrLngReal(V : LONGREAL; Precision: CARDINAL; Length: INTEGER);
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  FixRealToStr( V,Precision,(* Eng, *)s,OK );
  IF OK THEN WrStrAdj( s,Length ); END;
END WrLngReal;

PROCEDURE WrLn;
TYPE
  a3 = ARRAY [0..1] OF CHAR;
CONST
  crlf = a3(CHR(13),CHR(10));
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WrStr( crlf );
  LWW := FALSE;
END WrLn;

PROCEDURE RdBool() : BOOLEAN;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RdItem( s );
  RETURN Compare( s,TrueStr )=0;
END RdBool;

PROCEDURE RdShtInt() : SHORTINT;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGINT;
BEGIN
  RdItem( s );
  i  := StrToInt( s,10,OK );
  OK := OK AND (i >= -80H) AND (i <= 7FH);
  RETURN SHORTINT( i );
END RdShtInt;

PROCEDURE RdInt() : INTEGER;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGINT;
BEGIN
  RdItem( s );
  i  := StrToInt( s,10,OK );
  OK := OK AND (i >= -8000H) AND (i <= 7FFFH);
  RETURN INTEGER(i);
END RdInt;

PROCEDURE RdLngInt() : LONGINT;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RdItem( s );
  RETURN StrToInt( s,10,OK );
END RdLngInt;

PROCEDURE RdShtCard() : SHORTCARD;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGCARD;
BEGIN
  RdItem( s );
  i  := StrToCard( s,10,OK );
  OK := OK AND (i < 0FFH);
  RETURN SHORTINT( i );
END RdShtCard;

PROCEDURE RdShtHex() : SHORTCARD;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGCARD;
BEGIN
  RdItem( s );
  i  := StrToCard( s,16,OK );
  OK := OK AND (i < 0FFH);
  RETURN SHORTINT( i );
END RdShtHex;

PROCEDURE RdCard() : CARDINAL;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGCARD;
BEGIN
  RdItem( s );
  i  := StrToCard( s,10,OK );
  OK := OK AND (i < 10000H);
  RETURN INTEGER( i );
END RdCard;

PROCEDURE RdHex() : CARDINAL;
VAR
  s : ARRAY[0..80] OF CHAR;
  i : LONGCARD;
BEGIN
  RdItem( s );
  i  := StrToCard( s,16,OK );
  OK := OK AND (i < 10000H);
  RETURN INTEGER( i );
END RdHex;

PROCEDURE RdLngCard() : LONGCARD;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RdItem( s );
  RETURN StrToCard( s,10,OK );
END RdLngCard;

PROCEDURE RdLngHex() : LONGCARD;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RdItem( s );
  RETURN StrToCard( s,16,OK );
END RdLngHex;

PROCEDURE RdReal() : REAL;
VAR
  s   : ARRAY[0..80] OF CHAR;
  r,a : LONGREAL;
BEGIN
  RdItem( s );
  r := StrToReal( s,OK );
  a := ABS( r );
  OK := OK AND (a >= 1.2E-38 ) AND (a <= 3.4E38 );
  RETURN VAL( REAL,r );
END RdReal;

PROCEDURE RdLngReal() : LONGREAL;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  RdItem( s );
  RETURN StrToReal( s,OK );
END RdLngReal;


PROCEDURE RdLn;
BEGIN
  s:=e;
END RdLn;

PROCEDURE EndOfRd(Skip: BOOLEAN) : BOOLEAN;
BEGIN
  IF Skip THEN
     WHILE (s < e) AND (Buffer[s] IN Separators) DO INC(s) END;
  END;
  RETURN s = e;
END EndOfRd;

PROCEDURE RdItem(VAR V: ARRAY OF CHAR);
VAR L,i : CARDINAL;
BEGIN
  OK := TRUE;
  L := HIGH(V);
  REPEAT
    IF s=e THEN RdBuff(); END;

    WHILE (s<e) AND ( Buffer[s] IN Separators ) DO INC(s); END;
    i := 0;
    WHILE (s<e) AND (i<=L) AND NOT ( Buffer[s] IN Separators )  DO
      V[i] := Buffer[s];
      INC(s);
      INC(i);
    END;
    IF i <= L THEN V[i] := CHR(0); END;
  UNTIL V[0] # CHR(0);
END RdItem;

PROCEDURE RdChar() : CHAR;
VAR
  c : CHAR;
  t : BOOLEAN;
BEGIN
  IF s >= e THEN RdBuff; END;
  INC (s);
  RETURN Buffer[s-1];
END RdChar;

PROCEDURE RedirectInput(FileName: ARRAY OF CHAR);
VAR c : CARDINAL;
  r : Registers;
BEGIN
  WITH r DO
    BX := 0;
    AH := 3EH; (* close file *)
    Lib.Dos(r);
    DS := Seg(FileName);
    DX := Ofs(FileName);
    CX := 0;
    AX := 3D00H;   (* open for read *)
    Lib.Dos(r);
  END;
END RedirectInput;

PROCEDURE RedirectOutput(FileName: ARRAY OF CHAR);
VAR c : CARDINAL;
    r : Registers;
BEGIN
  WITH r DO
    BX := 1;
    AH := 3EH; (* close file *)
    Lib.Dos(r);
    DS := Seg(FileName);
    DX := Ofs(FileName);
    CX := 0;
    AX := 3C00H;   (* Create *)
    Lib.Dos(r);
  END ;
END RedirectOutput;


BEGIN
  Prompt        := TRUE;
  RdLnOnWr      := FALSE;
  WrStrRedirect := TerminalWrStr;
  RdStrRedirect := TerminalRdStr;
  s             := e;
  OK            := TRUE;
  ChopOff       := FALSE;
  Separators    := CHARSET{CHR(9),CHR(10),CHR(13),CHR(26),' '};
  Eng           := FALSE;
  LWW           := FALSE;
END IO.
