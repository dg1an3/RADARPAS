MODULE LineTrace;

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

FROM SYSTEM IMPORT
  PROCESS, NEWPROCESS, TRANSFER, ADDRESS;
FROM Storage IMPORT
  ALLOCATE;
IMPORT EGALib;
IMPORT Figures;
IMPORT Keyboard;
IMPORT InOut;

CONST
  NumLines  = 30;
  MaxThread = 6;

TYPE
  TraceRec  = RECORD
    X1, dX1,
    X2, dX2,
    Y1, dY1,
    Y2, dY2 :   INTEGER;
    OldX1,
    OldY1,
    OldX2,
    OldY2   :   ARRAY [1..NumLines] OF INTEGER;
    Count   :   CARDINAL;
    Colors  :   EGALib.PlaneSet;
  END; (* RECORD *)

VAR
  GlobalLine   : TraceRec;
  Thread       : ARRAY [0..MaxThread] OF PROCESS;
  (* Thread[0] is the main thread *)
  CurrThread   : CARDINAL;
  ReverseCount : CARDINAL;
  (* Set this to MaxThread to reverse the trace *)

PROCEDURE LineTraceThread;
VAR
  CurrLine : TraceRec;

PROCEDURE UpDate
( VAR Coor, Delta : INTEGER;
  Min, Max        : INTEGER );
BEGIN
  Coor:=Coor+Delta;
  IF (Coor<Min) THEN
    Coor:=Min;
    Delta:=-Delta;
  ELSIF (Coor>Max) THEN
    Coor:=Max;
    Delta:=-Delta;
  END;
END UpDate;

BEGIN
  CurrLine:=GlobalLine;
  LOOP
    TRANSFER(Thread[CurrThread],Thread[0]);
    WITH CurrLine DO
      UpDate(X1,dX1,0,639);
      UpDate(Y1,dY1,0,349);
      UpDate(X2,dX2,0,639);
      UpDate(Y2,dY2,0,349);
      EGALib.SetPlane(Colors);
      Figures.Line(X1,Y1,X2,Y2);
      IF ReverseCount>0 THEN
        DEC(ReverseCount);
        dX1:=-dX1;
        dY1:=-dY1;
        dX2:=-dX2;
        dY2:=-dY2;
      END; (* IF *)
    END; (* WITH *)
  END; (* LOOP *)
END LineTraceThread;


VAR
  WorkSpace : ADDRESS;
  CountDown : CARDINAL;
  Key       : CHAR;

BEGIN
  EGALib.SetHiRes;
  EGALib.SetFunc(EGALib.xor,0);
  WITH GlobalLine DO
(* Trace 1 *)
    X1:=10; Y1:=40;
    dX1:=2; dY1:=4;
    X2:=150; Y2:=110;
    dX2:=4; dY2:=6;
    Colors:=EGALib.PlaneSet{0,3};
    CurrThread:=1;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
    CurrThread:=2;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
(* Trace 2 *)
    X1:=50; Y1:=10;
    dX1:=4; dY1:=6;
    X2:=200; Y2:=200;
    dX2:=2; dY2:=3;
    Colors:=EGALib.PlaneSet{1,3};
    CurrThread:=3;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
    CurrThread:=4;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
(* Trace 3 *)
    X1:=100; Y1:=100;
    dX1:=2; dY1:=3;
    X2:=200; Y2:=250;
    dX2:=4; dY2:=6;
    Colors:=EGALib.PlaneSet{2,3};
    CurrThread:=5;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
    CurrThread:=6;
    ALLOCATE(WorkSpace,2000);
    NEWPROCESS(LineTraceThread,WorkSpace,2000,Thread[CurrThread]);
    TRANSFER(Thread[0],Thread[CurrThread]);
  END; (* WITH *)
  CountDown:=NumLines;
  CurrThread:=1;
  ReverseCount:=0;
  LOOP
    TRANSFER(Thread[0],Thread[CurrThread]);
    INC(CurrThread);
    IF CountDown>0 THEN INC(CurrThread) END;
    IF CurrThread>MaxThread THEN
      CurrThread:=1;
      IF CountDown>0 THEN DEC(CountDown) END;
    END;
    IF Keyboard.KeyPressed() THEN
      ReverseCount:=MaxThread;
      WHILE Keyboard.KeyPressed() DO Keyboard.Read(Key) END;
    END; (* IF *)
  END; (* LOOP *)
END LineTrace.
