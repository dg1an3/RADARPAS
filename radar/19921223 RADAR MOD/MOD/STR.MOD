(* Copyright (C) 1987 Jensen & Partners International *)
(*$R-,S-,I-,V-,O-*)
IMPLEMENTATION MODULE Str;


IMPORT Lib;

FROM MATHLIB IMPORT PackedBcd,Log10,Pow,LongToBcd;

CONST
  StrictRealConv = FALSE ;

PROCEDURE Delete(VAR S: ARRAY OF CHAR; P,L: CARDINAL);
VAR
  Le,I : CARDINAL;
BEGIN
  Le := Length(S);
  I  := P+L;
  WHILE (I < Le) DO
    S[P] := S[I];
    INC(P);
    INC(I);
  END;
  IF P <= HIGH(S) THEN S[P] := CHR(0); END;
END Delete;

PROCEDURE Insert(VAR S1: ARRAY OF CHAR; S2: ARRAY OF CHAR; P: CARDINAL);
VAR
  I,J,C,L : CARDINAL;
BEGIN
  L := Length(S1);
  I := Length(S2);
  C := L;
  IF C < P THEN P := C END;
  DEC(C,P);
  FOR J := C TO 0 BY -1 DO
    IF (J+P+I <= HIGH(S1)) THEN S1[J+P+I] := S1[J+P]; END;
  END;
  J := 0;
  WHILE (J<I) AND (P+J <= HIGH(S1)) DO
    S1[P+J] := S2[J];
    INC(J);
  END;
END Insert;

PROCEDURE Item(VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR; T: CHARSET; N: CARDINAL);
VAR
  I,J  : CARDINAL;
  HR,L : CARDINAL;
BEGIN
  I := 0;
  L := Length(S);
  LOOP
    WHILE (I < L) AND (S[I] IN T) DO INC(I); END; (* Skip separators *)
    IF (N = 0) OR (I = L) THEN EXIT END;
    DEC(N);
    WHILE (I < L) AND NOT (S[I] IN T) DO INC(I); END; (* Skip item *)
  END;
  J  := 0;
  HR := HIGH(R);
  WHILE (I < L) AND NOT (S[I] IN T) AND (J <= HR) DO
    R[J] := S[I];
    INC(I);
    INC(J);
  END;
  IF (J <= HR) THEN R[J] := CHR(0); END;
END Item;

PROCEDURE ItemS(VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR;
                    T: ARRAY OF CHAR; N: CARDINAL);
VAR
  CS : CHARSET;
  I  : CARDINAL;
BEGIN
  I  := Length(T);
  CS := CHARSET{};
  WHILE I>0 DO
    DEC(I);
    INCL(CS,T[I]);
  END;
  Item(R,S,CS,N);
END ItemS;


PROCEDURE Match(Source,Pattern: ARRAY OF CHAR) : BOOLEAN;
(*
  returns TRUE if the string in Source matches the string in Pattern
  The pattern may contain any number of the wild characters '*' and '?'
  '?' matches any single character
  '*' matches any sequence of charcters (including a zero length sequence)
  EG '*m?t*i*' will match 'Automatic'
*)

   PROCEDURE Rmatch(VAR s: ARRAY OF CHAR; i: CARDINAL;
                    VAR p: ARRAY OF CHAR; j: CARDINAL) : BOOLEAN;

   (* s = to be tested ,    i = position in s *)
   (* p = pattern to match ,j = position in p *)

   VAR
     matched: BOOLEAN;
     k      : CARDINAL;
   BEGIN
     IF p[0]=CHR(0) THEN RETURN TRUE END;
     LOOP
       IF ((i > HIGH(s)) OR (s[i] = CHR(0))) AND
          ((j > HIGH(p)) OR (p[j] = CHR(0))) THEN
         RETURN TRUE
       ELSIF ((j > HIGH(p)) OR (p[j] = CHR(0))) THEN
         RETURN FALSE
       ELSIF (p[j] = '*') THEN
         k :=i;
         IF ((j = HIGH(p)) OR (p[j+1] = CHR(0))) THEN
           RETURN TRUE
         ELSE
           REPEAT
             matched := Rmatch(s,k,p,j+1);
             INC(k);
           UNTIL matched OR (k > HIGH(s)) OR (s[k] = CHR(0));
           RETURN matched;
         END
       ELSIF (p[j] <> '?') AND (CAP(p[j]) <> CAP(s[i])) THEN
         RETURN FALSE
       ELSE
         INC(i);
         INC(j);
       END;
     END;
   END Rmatch;

BEGIN
  RETURN Rmatch(Source,0,Pattern,0);
END Match;



(*$V+*)

(*$R-,S-,I-*)

TYPE
  ConvIntType = ARRAY ['0'..'F'] OF SHORTCARD;
  BA          = ARRAY[0..1] OF SHORTCARD;

CONST
  ConvStr = '0123456789ABCDEF';
  ConvInt = ConvIntType( 0,1,2,3,4,5,6,7,8,9,255,255,255,255,255,255,255,10,11,12,13,14,15 );
  Div     = BA(0,4);


VAR FloatUse : BOOLEAN;


PROCEDURE FixRealToStr(V: LONGREAL; Precision: CARDINAL;
                       VAR S: ARRAY OF CHAR; VAR OK: BOOLEAN);
VAR
  j,i,l    : CARDINAL;
  X        : PackedBcd;
  c        : CHAR;
  NoDigits : BOOLEAN;
BEGIN
  OK := TRUE;
  IF Precision > 17 THEN Precision := 17; END;
  l := HIGH( S );
  j := 0;
  NoDigits := TRUE;
  V := V * Pow ( 10.0,VAL( LONGREAL,Precision ) );
  IF ABS( V )  >= 1.0E18 THEN
    S[0] := '?';
    INC( j );
    OK := FALSE;
  ELSE
    X := LongToBcd( V );
    IF X[9]=80H THEN
      S[0] := '-';
      INC(j);
    END;

    FOR i := 17 TO 0 BY -1 DO
      c := CHAR( SHORTCARD('0') + (X[i DIV 2] >> Div[i MOD 2 ] ) MOD 16 );
      IF (c # '0') OR (i = Precision) OR NOT NoDigits THEN
        NoDigits := FALSE;
        IF j > l THEN OK := FALSE; RETURN; END;
        S[j] := c;
        INC( j );
      END;
      IF (i = Precision) AND (i # 0) THEN
        IF j > l THEN OK := FALSE; RETURN; END;
        S[j] := '.';
        INC(j);
      END;
    END;
  END;

  IF HIGH( S ) >= l THEN S[j] := CHR(0); END;
END FixRealToStr;


PROCEDURE CheckBase(VAR b: CARDINAL);
BEGIN
  IF b < 2  THEN b := 2; END;
  IF b > 16 THEN b := 16; END;
END CheckBase;

PROCEDURE Reverse(VAR s: ARRAY OF CHAR; l,h: CARDINAL);
VAR T : CHAR;
BEGIN
  WHILE l < h DO
    T := s[l];
    s[l] := s[h];
    s[h] := T;
    INC(l);
    DEC(h);
  END;
END Reverse;


PROCEDURE IntToStr(V: LONGINT;VAR S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN);
VAR
  i,l : CARDINAL;
  b   : LONGCARD;
BEGIN
  OK := TRUE;
  l  := HIGH(S);
  CheckBase( Base );
  b := VAL( LONGCARD,Base );
  IF V < 0 THEN
    S[0] := '-';
    i := 1;
    V := -V;
  ELSIF FloatUse THEN
    S[0] := '+';
    i := 1;
  ELSE
    i := 0;
  END;

  LOOP
    IF i > l THEN OK := FALSE; EXIT; END;
    S[i] := ConvStr[CARDINAL( LONGCARD(V) MOD b )];
    INC(i);
    V := LONGCARD(V) DIV b;
    IF V = 0 THEN EXIT END;
  END;
  IF i <= l THEN S[i] := CHR(0); END;
  IF S[0] < '0' THEN
    Reverse( S,1,i-1 );
  ELSE
    Reverse( S,0,i-1 );
  END;
END IntToStr;


PROCEDURE CardToStr(V: LONGCARD; VAR S: ARRAY OF CHAR;
                    Base: CARDINAL; VAR OK: BOOLEAN);
VAR
  i,l : CARDINAL;
  b   : LONGCARD;
BEGIN
  OK := TRUE;
  l  := HIGH(S);
  CheckBase( Base );
  b := VAL( LONGCARD,Base );
  i := 0;
  LOOP
    IF i > l THEN OK := FALSE; EXIT END;
    S[i] := ConvStr[CARDINAL( V MOD b )];
    INC(i);
    V := V DIV b;
    IF V = 0 THEN EXIT END;
  END;
  IF i <= l THEN S[i] := CHR(0); END;
  Reverse( S,0,i-1 );
END CardToStr;


(*$V-*)
PROCEDURE StrToCI(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGCARD;
VAR
  i,l   : CARDINAL;
  b,t,y : LONGCARD;
  c     : CHAR;
  x     : SHORTCARD;
BEGIN
  CheckBase( Base );
  b := VAL( LONGCARD,Base);
  i := 0;
  l := HIGH( S );
  IF (S[0] = '-') OR (S[0] = '+') THEN
    i := 1;
  END;
  t := 0;
  IF S[i] = CHR(0) THEN OK := FALSE; END;
  WHILE (i <= l) AND (S[i] # CHR(0)) DO
    c := S[i];
    IF (c < '0') OR (c > 'F') THEN OK := FALSE; END;
    x := ConvInt[c];
    IF (x > SHORTCARD(b)-1 ) OR (t > t*b+VAL( LONGCARD,x )) THEN OK := FALSE; END;
    t := t*b+VAL( LONGCARD,x );
    INC( i );
  END;
  RETURN t;
END StrToCI;


PROCEDURE StrToInt(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGINT;
VAR t : LONGCARD;
BEGIN
  OK := TRUE;
  t  := StrToCI( S,Base,OK);
  IF t > 7FFFFFFFH THEN OK := FALSE; END;
  IF S[0] = '-' THEN
    RETURN -LONGINT(t)
  ELSE
    RETURN LONGINT(t);
  END;
END StrToInt;


PROCEDURE StrToCard(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGCARD;
VAR t : LONGCARD;
BEGIN
  OK := TRUE;
  t  := StrToCI( S,Base,OK);
  IF S[0] = '-' THEN OK := FALSE; END;
  RETURN t;
END StrToCard;


PROCEDURE StrToReal(S: ARRAY OF CHAR; VAR OK: BOOLEAN) : LONGREAL;
VAR
  c,expsign : CHAR;
  exp,after : INTEGER;
  i         : CARDINAL;
  res,p10   : LONGREAL;
  Neg       : BOOLEAN;
CONST
  Zero = 0.0;
BEGIN
  OK  := TRUE;
  c   := S[0];
  Neg := FALSE;
  IF c = '+' THEN
    i := 1;
  ELSIF c = '-' THEN
    i := 1; Neg := TRUE;
  ELSE
    i := 0;
  END;
  res := 0.0;
  c := S[i];
  WHILE c <> '.' DO
    IF (c > '9') OR (c < '0') THEN
      IF StrictRealConv THEN
        OK := FALSE; RETURN Zero;
      ELSE
        c := '.' ; DEC(i) ;
      END ;
    ELSE
      res := res * 10.0 + VAL( LONGREAL, ORD(c) - ORD('0') );
      INC(i);
      c := S[i];
    END ;
  END;
  after := 0;
  INC(i);
  c := S[i];
  WHILE ( c <> CHAR(0) ) AND ( c <> 'E' ) DO
    IF ( c > '9' ) OR ( c < '0' ) THEN OK := FALSE; RETURN Zero; END;
    res := res * 10.0 + VAL( LONGREAL, SHORTCARD(c) - SHORTCARD('0') );
    INC(i);
    INC(after);
    c := S[i];
  END;
  IF c = 'E' THEN
    INC(i);
    expsign := S[i];
    IF expsign = '+' THEN
      INC(i)
    ELSIF expsign = '-' THEN
      INC(i)
    END;
    c := S[i];
    exp := 0;
    WHILE c <> CHAR(0) DO
      IF ( c > '9' ) OR ( c < '0' ) THEN OK := FALSE; RETURN Zero; END;
      exp := exp*8 + exp*2 + INTEGER( SHORTCARD(c) - SHORTCARD('0') );
      INC(i);
      c := S[i];
    END;
    IF expsign = '-' THEN exp := -exp END;
  ELSE
    exp := 0;
  END;
  exp := exp - after;
  p10 := 1.0;
  FOR i := 1 TO ABS(exp) DO
    p10 := p10 * 10.0;
  END;
  IF Neg THEN res := - res END;
  IF exp < 0 THEN
    RETURN res / p10
  ELSE
    RETURN res * p10;
  END;
END StrToReal;


PROCEDURE RealToStr(V: LONGREAL; Precision: CARDINAL; Eng: BOOLEAN;
                    VAR S: ARRAY OF CHAR; VAR OK: BOOLEAN);
VAR
  X        : PackedBcd;
  i,j,l    : CARDINAL;
  r,t      : LONGREAL;
  Exp,m    : INTEGER;
  Str      : ARRAY[0..7] OF CHAR;
  tb,
  FirstTime: BOOLEAN;

BEGIN
  OK := TRUE;
  l  := HIGH( S );
  IF Precision = 0 THEN
    Precision := 1;
  ELSIF Precision > 17 THEN
    Precision := 17;
  END;
  FirstTime := TRUE;

  IF V # 0.0 THEN
    t := Log10( ABS( V ) );
  ELSE
    t := 1.0;
  END;

  Exp := TRUNC( t );
  LOOP
    m := 1;
    IF Eng THEN
      IF (ABS(V) < 1.0) THEN
        DEC(m,ABS(Exp) MOD 3 );
        IF m < 1 THEN INC(m,3); END;
      ELSE
        INC(m,Exp MOD 3 );
      END;
    END;

    X := LongToBcd( V*Pow( 10.0,VAL( LONGREAL,INTEGER(Precision)-Exp-1)) );
    j := 0;
    IF NOT FirstTime THEN
      EXIT;
    ELSIF (X[Precision DIV 2] >> Div[Precision MOD 2 ] ) MOD 16 # 0 THEN
      INC( Exp );
      FirstTime := FALSE;
    ELSIF (X[(Precision-1) DIV 2] >> Div[(Precision-1) MOD 2 ] ) MOD 16 = 0 THEN
      DEC( Exp );
      FirstTime := FALSE;
    ELSE
      EXIT;
    END;

  END;
  IF X[9]=80H THEN
    S[0] := '-';
  ELSE
    S[0] := ' ';
  END;
  INC(j);

  FOR i := Precision-1 TO 0 BY -1 DO
    IF j > l THEN OK := FALSE; RETURN; END;

    S[j] := CHAR( SHORTCARD('0') + (X[i DIV 2] >> Div[i MOD 2 ] ) MOD 16 );
    INC( j );
    IF i = Precision-CARDINAL(m) THEN
      IF j > l THEN OK := FALSE; RETURN; END;
      S[j] := '.';
      INC(j);
    END;
  END;

  IF j > l THEN OK := FALSE; RETURN; END;
  S[j] := 'E';
  INC( j );
  IF j <= l THEN S[j] := CHR(0); END;

  tb := FloatUse;
  FloatUse := TRUE;

  IntToStr( VAL( LONGINT,Exp-m+1 ),Str,10,OK );

  FloatUse := tb;

  IF ( Length( Str ) + j )-1 > l THEN OK := FALSE; END;
  Append( S,Str );
END RealToStr;


(* The following are Implemented in AsmLib

PROCEDURE CapS(VAR S: ARRAY OF CHAR);
VAR I : CARDINAL;
BEGIN
  FOR I := 0 TO HIGH(S) DO S[I] := CAP(S[I]); END;
END CapS;


PROCEDURE Compare(S1,S2: ARRAY OF CHAR) : INTEGER;
VAR
  L1,L2,L,Index : CARDINAL;
BEGIN
  L1 := Length(S1);
  L2 := Length(S2);
  IF L1<L2 THEN L := L1 ELSE L := L2 END;
  Index := Lib.Compare(ADR(S1),ADR(S2),L);
  IF (Index<L) THEN
    IF S1[Index] < S2[Index] THEN
      RETURN -1
    ELSE
      RETURN 1;
    END;
  ELSIF (L1=L2) THEN
    RETURN 0
  ELSIF (L1<L2) THEN
    RETURN -1
  ELSE
    RETURN 1;
  END;
END Compare;


PROCEDURE Length(S1: ARRAY OF CHAR) : CARDINAL;
VAR I : CARDINAL;
BEGIN
  RETURN Lib.ScanR(ADR(S1),HIGH(S1)+1,0);
END Length;


PROCEDURE Append(VAR Ns: ARRAY OF CHAR; S: ARRAY OF CHAR);
VAR
  I,J : CARDINAL;
  c : CHAR;
BEGIN
  I := Length(Ns);
  J := 0;
  WHILE (I <= HIGH(Ns)) AND (J <= HIGH(S))  AND (S[J] <> CHR(0)) DO
    Ns[I] := S[J];
    INC(I);
    INC(J);
  END;
  IF I<=HIGH(Ns) THEN Ns[I] := CHR(0) END;
END Append;


PROCEDURE Copy(VAR Ns: ARRAY OF CHAR; S: ARRAY OF CHAR);
VAR
  H,L : CARDINAL;
BEGIN
  H := HIGH(Ns)+1;
  L := Length(S);
  IF L > H THEN L := H END;
  Lib.Move(ADR(S),ADR(Ns),L);
  IF L < H THEN Ns[L] := CHR(0) END;
END Copy;


PROCEDURE Concat(VAR Ns: ARRAY OF CHAR; S1,S2: ARRAY OF CHAR);
VAR
  I,J : CARDINAL;
BEGIN
  J := 0;
  WHILE (J <= HIGH(Ns)) AND (J <= HIGH(S1)) AND (S1[J] <> CHAR(0)) DO
    Ns[J] := S1[J];
    INC(J);
  END;

  I := 0;
  LOOP
    IF (J > HIGH(Ns)) THEN EXIT; END;
    IF (I > HIGH(S2)) THEN Ns[J] := CHR(0); EXIT; END;
    Ns[J] := S2[I];
    IF S2[I] = CHR(0) THEN EXIT; END;
    INC(I);
    INC(J);
  END;
END Concat;


PROCEDURE Pos(S,P: ARRAY OF CHAR) : CARDINAL;
VAR
  I,J,K,HP,HS : CARDINAL;
BEGIN
  HP := HIGH(P);
  HS := HIGH(S);
  I  := 0;
  LOOP
    IF (I > HS) OR (S[I] = CHR(0)) THEN RETURN MAX(CARDINAL) END;
    J := 0;
    K := I;
    LOOP
      IF (J > HP) OR (P[J] = CHR(0)) THEN RETURN I END;
      IF K > HS THEN RETURN MAX( CARDINAL ); END;
      IF S[K] # P[J] THEN EXIT END;
      INC(J);
      INC(K);
    END;
    INC(I);
  END;
END Pos;

*)


BEGIN
  FloatUse := FALSE;
END Str.
