(* Copyright (C) 1987 Jensen & Partners International *)
IMPLEMENTATION MODULE Lib;

(* Change Log: *)


FROM SYSTEM IMPORT Seg,Ofs,Registers,CarryFlag;
FROM AsmLib IMPORT DosExec,Copy,Concat,Append,Length;

(*$S-,R-,I-,V-,O-*)


PROCEDURE HSort(N: CARDINAL; Less: CompareProc; Swap: SwapProc);
VAR
  i,j,k : CARDINAL;
BEGIN
  IF N > 1 THEN
    i := N DIV 2;
    REPEAT
      j := i;
      LOOP (* Note that total repeats <= N/4 * 1 + N/8 * 2 + N/16 * 3 + .... *)
        k := j * 2;
        IF k > N THEN EXIT END;
        IF (k < N) AND Less(k,k+1) THEN INC(k) END;
        IF Less(j,k) THEN Swap(j,k) ELSE EXIT END;
        j := k;
      END;
      DEC(i);
    UNTIL i = 0;

    i := N;
    REPEAT
      j := 1;
      Swap(j,i);
      DEC(i);
      LOOP
        k := j * 2;
        IF k > i THEN EXIT END;
        IF ( k < i ) AND Less(k,k+1) THEN INC(k) END;
        Swap(j,k);
        j := k;
      END;
      LOOP
        k := j DIV 2;
        IF (k > 0) AND Less(k,j) THEN Swap(j,k); j := k ELSE EXIT END;
      END;
    UNTIL i = 0;
  END;
END HSort;


PROCEDURE QSort(N: CARDINAL; Less: CompareProc; Swap: SwapProc);

  PROCEDURE Sort(l,r: CARDINAL);
  VAR
    i,j:CARDINAL;
  BEGIN
    WHILE r > l DO
      i := l+1;
      j := r;
      WHILE i <= j DO
        WHILE (i <= j) AND NOT Less(l,i) DO INC(i) END;
        WHILE (i <= j) AND Less(l,j) DO DEC(j) END;
        IF i <= j THEN Swap(i,j); INC(i); DEC(j) END;
      END;
      IF j # l THEN Swap(j,l) END;
      IF j+j > r+l THEN (* small one recursively *)
        Sort(j+1,r);
        r := j-1;
      ELSE
        Sort(l,j-1);
        l := j+1;
      END;
    END;
  END Sort;

BEGIN
  Sort(1,N);
END QSort;



PROCEDURE Execute ( Name        : ARRAY OF CHAR;
                    CommandLine : ARRAY OF CHAR;
                    StoreAddr   : ADDRESS;   (* storage to execute in *)
                    StoreLen    : CARDINAL   (* length of store paragraphs *)
                  ) : CARDINAL;

CONST
  MinHeapNeeded = 4;

VAR
  fullpath    : ARRAY[0..80] OF CHAR;
  cline       : RECORD
                  len : SHORTCARD;
                  txt : ARRAY[0..255] OF CHAR;
                END;
  reply       : CARDINAL;
  LoadRec     : RECORD
                  envseg  : CARDINAL;
                  comline : ADDRESS;
                  FCB1    : ADDRESS;
                  FCB2    : ADDRESS;
                END;
  Progbase    : CARDINAL;
  MaxProgSize : CARDINAL;
  residue     : CARDINAL;


  PROCEDURE GiveBackHeap ( StoreAddr : ADDRESS; (* storage to execute in *)
                           StoreLen  : CARDINAL (* length of store paragraphs *)
                         );
  VAR
    R    : Registers;
    temp : CARDINAL;
  BEGIN
    Progbase := Seg(StoreAddr^);
    R.AH := 4AH;
    R.ES := PSP;
    R.BX := Seg(StoreAddr^)-PSP;
    Dos(R);                (* modify so all after seg free *)
    R.BX := StoreLen-2;
    R.AH := 48H;
    Dos(R);                (* allocate the seg we want *)
    temp := R.AX;
    R.BX := 0FFFFH;        (* allocate all the rest *)
    R.AH := 48H;
    Dos(R);                (* returns allocated in BX *)
    R.AH := 48H;
    Dos(R);                (* do allocation *)
    residue := R.AX;
    R.AH := 49H;
    R.ES := temp;
    Dos(R);                (* now free the bit we want *)
  END GiveBackHeap;

  PROCEDURE RetrieveHeap;
  VAR
    R  : Registers;
  BEGIN
    R.AH := 49H;
    R.ES := residue;
    Dos(R);                (* now free the residue *)
    R.BX := 0FFFFH;        (* now modify PSP back to full size *)
    R.AH := 4AH;
    R.ES := PSP;
    Dos(R);                (* returns allocated in BX *)
    R.AH := 4AH;
    Dos(R);                (* do modify *)
  END RetrieveHeap;

BEGIN
  GiveBackHeap( StoreAddr, StoreLen );
  cline.len := SHORTCARD( Length(CommandLine) );
  Concat(cline.txt,CommandLine,CHR(13));
  Copy(fullpath,Name);
  LoadRec.envseg := [PSP:2CH]^;
  LoadRec.comline := ADR(cline);
  LoadRec.FCB1 := [PSP:5CH];
  LoadRec.FCB2 := [PSP:6CH];
  reply := DosExec( fullpath, ADR(LoadRec) );
  RetrieveHeap;
  RETURN reply;
END Execute;


CONST
  HistoryMax = 54;


VAR
  HistoryPtr : CARDINAL;
  LowerPtr   : CARDINAL;
VAR
  History    : ARRAY [0..HistoryMax] OF CARDINAL;

PROCEDURE SetUpHistory(Seed: CARDINAL);
VAR
  x : LONGCARD;
  i : CARDINAL;
BEGIN
  HistoryPtr := HistoryMax;
  LowerPtr := 23;
  x := LONGCARD(Seed);
  i := 0;
  REPEAT
    x := (x*3141592621+17);
    History[i] := CARDINAL(x DIV 10000H);
    INC(i);
  UNTIL i>HistoryMax;
END SetUpHistory;

PROCEDURE RANDOM(Range: CARDINAL) : CARDINAL;
VAR res:CARDINAL;
BEGIN
  IF HistoryPtr = 0 THEN
    IF LowerPtr = 0 THEN
      SetUpHistory(12345);
    ELSE
      HistoryPtr := HistoryMax;
      LowerPtr   := LowerPtr-1;
    END;
  ELSE
    HistoryPtr := HistoryPtr-1;
    IF LowerPtr = 0 THEN
      LowerPtr := HistoryMax;
    ELSE
      LowerPtr := LowerPtr-1;
    END;
  END;
  res := History[HistoryPtr]+History[LowerPtr];
  History[HistoryPtr] := res;
  IF Range = 0 THEN
    RETURN res;
  ELSE
    RETURN res MOD Range;
  END;
END RANDOM;

PROCEDURE RANDOMIZE;
VAR R : Registers;
BEGIN
  WITH R DO
    AH := 2CH;
    Dos(R);
    SetUpHistory(DX+CX);
  END;
END RANDOMIZE;

PROCEDURE RAND(): REAL;
VAR
  x:RECORD low,high:CARDINAL END;
BEGIN
  x.low := RANDOM(0);
  x.high := RANDOM(0);
  RETURN REAL(LONGCARD(x))/(REAL(MAX(LONGCARD))+1.0);
END RAND;



CONST
  MErr = 'Math Error : ';

PROCEDURE MathError(R: LONGREAL; STR: ARRAY OF CHAR);
VAR str : ARRAY[0..40] OF CHAR;
BEGIN
  Concat ( str,MErr,STR );
(*  FatalError( str ); *)
END MathError;

PROCEDURE MathError2(R1,R2: LONGREAL; STR: ARRAY OF CHAR);
VAR str : ARRAY[0..40] OF CHAR;
BEGIN
  Concat ( str,MErr,STR );
  FatalError( str );
END MathError2;


BEGIN
  HistoryPtr := 0;
  LowerPtr := 0;
END Lib.

