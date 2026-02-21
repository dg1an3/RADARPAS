(* Copyright (C) 1987 Jensen & Partners International *)

(*$V-,S-,R-,I-*)
IMPLEMENTATION MODULE Storage;

FROM SYSTEM IMPORT Seg,Ofs,Registers,HeapBase,EI,DI,GetFlags,SetFlags;
IMPORT Lib;

CONST
  EndMarker = 0FFFFH;
  ErrorMsg1 = 'Storage, Fatal error : Heap overflow';
  ErrorMsg2 = 'Storage, Fatal error : Corrupt heap';
  ErrorMsg3 = 'Storage, Fatal error : Invalid dispose';



PROCEDURE MakeHeap( Source : CARDINAL;     (* base segment of heap *)
                    Size   : CARDINAL      (* size in paragraphs *)
                    ) : HeapRecPtr;
VAR
  storage,first,last : HeapRecPtr;
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  storage := [Source:0];
  first   := [Source+1:0];
  last    := [Source+Size-1:0];
  storage^.next := first;
  storage^.size := 0;
  first^.next := last;
  last^.next  := storage;
  first^.size := Size-2;
  last^.size  := EndMarker;
  SetFlags(ie);
  RETURN storage;
END MakeHeap;


PROCEDURE HeapAllocate(Source : HeapRecPtr; (* source heap                *)
                       VAR A  : ADDRESS;    (* result                     *)
                       Size   : CARDINAL);  (* request size in paragraphs *)

VAR
  res,prev,split : HeapRecPtr;
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF Size=0 THEN INC(Size) END ;
  prev := Source;
  WHILE prev^.next^.size < Size DO
    prev := prev^.next;
  END;
  res := prev^.next;
  IF res^.size = EndMarker THEN (* heap run out of space *)
    EI ;
    Lib.FatalError(ErrorMsg1);
  END;
  IF res^.size = Size THEN (* block correct size *)
    prev^.next := res^.next;
  ELSE (* split block, bottom half returned, top half linked to free chain *)
    split := [Seg(res^)+Size:0];
    prev^.next := split;
    split^.next := res^.next;
    split^.size := res^.size - Size;
  END;
  SetFlags( ie );
  A := ADR(res^);
END HeapAllocate;


PROCEDURE HeapAvail(Source: HeapRecPtr) : CARDINAL;
(* returns the largest block size available for allocation in paragraphs *)
VAR
  size : CARDINAL;
  p    : HeapRecPtr;
  ie   : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  p  := Source^.next;
  size := 0;
  WHILE p^.size <> EndMarker DO
    IF p^.size>size THEN size := p^.size END;
    p := p^.next;
  END;
  SetFlags(ie);
  RETURN size;
END HeapAvail;


PROCEDURE HeapTotalAvail(Source: HeapRecPtr) : CARDINAL;
(* returns the total block size available for allocation in paragraphs *)
VAR
  size : CARDINAL;
  p    : HeapRecPtr;
  ie   : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  p  := Source^.next;
  size := 0;
  WHILE p^.size <> EndMarker DO
    INC(size,p^.size);
    p := p^.next;
  END;
  SetFlags(ie);
  RETURN size;
END HeapTotalAvail;


PROCEDURE HeapDeallocate(Source : HeapRecPtr;  (* source heap         *)
                         VAR A  : ADDRESS;     (* block to deallocate *)
                         Size   : CARDINAL );  (* size of block
                                                  in paragraphs       *)
VAR
  target,prev,split : HeapRecPtr;
  tseg : CARDINAL;
  ie   : CARDINAL;
BEGIN
  IF (Seg(A^)=0)OR(Ofs(A^)<>0) THEN Lib.FatalError(ErrorMsg3) END;
  ie := GetFlags(); DI;
  IF Size=0 THEN INC(Size) END ;
  target := A;
  prev   := Source;
  tseg   := Seg(target^);
  WHILE Seg(prev^.next^) < tseg DO
    prev := prev^.next;
  END;
  IF Seg(prev^)+prev^.size = tseg THEN (* amalgamate with prev *)
    prev^.size := prev^.size + Size;
    target := prev;
  ELSIF Seg(prev^)+prev^.size > tseg THEN (* Heap corrupt *)
    EI ;
    Lib.FatalError(ErrorMsg2);
  ELSE
    (* link after prev *)
    target^.next := prev^.next;
    prev^.next := target;
    target^.size := Size;
  END;
  IF (target^.next^.size <> EndMarker)
     AND (Seg(target^.next^) = Seg(target^)+target^.size) THEN
    (* amalgamate with next block *)
    target^.size := target^.size+target^.next^.size;
    target^.next := target^.next^.next;
  END;
  A := NIL;
  SetFlags(ie);
END HeapDeallocate;


PROCEDURE HeapChangeAlloc(Source  : HeapRecPtr;  (* source heap       *)
                          A       : ADDRESS;     (* block to change   *)
                          OldSize,               (* old size of block *)
                          NewSize : CARDINAL)    (* new size of block *)
                                                 (* in paragraphs     *)
                          : BOOLEAN;             (* if sucessful      *)

(* This procedure attempts to change the size of an allocated block
   It returns TRUE if succeeded (only expansion can fail)
*)

VAR
  target,prev,
  split      : HeapRecPtr;
  tseg       : CARDINAL;
  result     : BOOLEAN;
  extendsize : CARDINAL;
  ie         : CARDINAL;
BEGIN
  IF (Seg(A^)=0)OR(Ofs(A^)<>0) THEN Lib.FatalError(ErrorMsg3) END;
  IF OldSize = NewSize THEN RETURN TRUE END;
  IF OldSize > NewSize THEN
    target := [Seg(A^)+NewSize:0];
    HeapDeallocate(Source,target,OldSize-NewSize);
    RETURN TRUE;
  END;
  extendsize := NewSize-OldSize;
  ie := GetFlags(); DI;
  target := A;
  prev := Source;
  tseg := Seg(target^);
  WHILE Seg(prev^.next^) < tseg DO
    prev := prev^.next;
  END;
  IF (prev^.next^.size <> EndMarker) AND
     (Seg(prev^.next^) = Seg(target^)+OldSize) AND
     (extendsize <= prev^.next^.size) THEN
    IF (extendsize = prev^.next^.size) THEN
      prev^.next := prev^.next^.next
    ELSE
      split := [Seg(target^)+NewSize:0];
      split^.next := prev^.next^.next;
      split^.size := prev^.next^.size - extendsize;
      prev^.next  := split;
    END;
    result := TRUE;
  ELSE
    result := FALSE;
  END;
  SetFlags(ie);
  RETURN result;
END HeapChangeAlloc;



PROCEDURE HeapChangeSize(Source  : HeapRecPtr;   (* source heap       *)
                         VAR A   : ADDRESS;      (* block to change   *)
                         OldSize,                (* old size of block *)
                         NewSize : CARDINAL );   (* new size of block
                                                       in paragraphs  *)

(*
   This procedure will change the size of an allocated block
   avoiding any copy of data if possible
   calls HeapChangeAlloc
*)

VAR
  na : ADDRESS;
BEGIN
  IF NOT HeapChangeAlloc ( Source, A, OldSize, NewSize ) THEN
    HeapAllocate(Source,na,NewSize);
    Lib.WordMove(A,na,OldSize*8);
    A := na;
  END;
END HeapChangeSize;


PROCEDURE ALLOCATE(VAR a: ADDRESS; size: CARDINAL);
VAR ps : CARDINAL;
BEGIN
  IF size>0FFF0H THEN ps := 1000H
  ELSE                ps := (size+15) DIV 16;
  END ;
  HeapAllocate(MainHeap,a,ps);
  IF ClearOnAllocate THEN Lib.WordFill( a,ps*8,0); END;
END ALLOCATE;


PROCEDURE DEALLOCATE(VAR a: ADDRESS; size: CARDINAL);
VAR
  ps : CARDINAL ;
BEGIN
  IF size>0FFF0H THEN ps := 1000H
  ELSE                ps := (size+15) DIV 16;
  END ;
  HeapDeallocate(MainHeap,a,ps);
END DEALLOCATE;


PROCEDURE Available(size: CARDINAL) : BOOLEAN;
VAR
  ps : CARDINAL ;
BEGIN
  IF size=0 THEN          ps := 1
  ELSIF size>0FFF0H THEN  ps := 1000H
  ELSE                    ps := (size+15) DIV 16;
  END ;
  RETURN ps <= Storage.HeapAvail(Storage.MainHeap);
END Available;


PROCEDURE HEAPINIT();
VAR
  sseg   : CARDINAL;
BEGIN
  ClearOnAllocate := FALSE;
  MainHeap := MakeHeap(HeapBase,CARDINAL([Lib.PSP:2]^)-HeapBase);
END HEAPINIT;


BEGIN
  HEAPINIT;
END Storage.

