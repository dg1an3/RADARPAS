(* Copyright (C) 1987 Jensen & Partners International *)

(*$V-,S-,R-,I-*)
IMPLEMENTATION MODULE Process;

FROM SYSTEM  IMPORT PROCESS,NEWPROCESS,TRANSFER,IOTRANSFER,EI,DI,
                    GetFlags,SetFlags,CurrentProcess,Out;
FROM Storage IMPORT ALLOCATE;
FROM Lib     IMPORT Terminate;

TYPE

  Task = POINTER TO TaskDescriptor;

  SIGNAL = POINTER TO SigRec;

  SigRec = RECORD
             count   : INTEGER;
             waiting : Task;
           END;


  TaskDescriptor = RECORD
                     next     : Task; (* queue of waiting Process *)
                     priority : CARDINAL;
                     cor      : PROCESS;
                     due      : CARDINAL;
                     nextdue  : Task;
                   END;

  VAR
    cp : Task;  (* currently active task + ready queue *)
    dq : Task;  (* queue of delayed tasks *)
    wq : Task;  (* queue of tasks that have reached thier delay time
                   but haven't been placed on the ready queue *)

    SchedProc  : PROCESS;
    SchedStack : ADDRESS;
    Started    : BOOLEAN;


(*$W+*)  (* Volatile variables *)
VAR
  Stop       : BOOLEAN;
  LockNest   : CARDINAL;   (* No of nested locks *)
                           (* only safe to slice if zero *)
  SchedTime  : CARDINAL;
(*$W-*)



PROCEDURE QInsert(T: Task; VAR Q: Task);
(* inserts task after last task in Q with greater or equal priority *)
VAR
  q,qb : Task;
BEGIN
  q  := Q;
  qb := NIL;
  WHILE (q<>NIL)AND(T^.priority<=q^.priority) DO
    qb := q;
    q := q^.next;
  END;
  IF qb=NIL THEN
    Q := T;
  ELSE
    qb^.next := T;
  END;
  T^.next := q;
END QInsert;


PROCEDURE AddReadyProcess(T: Task);
(* adds new process to ready list
   NB gets added ahead of current process if at same priority
*)
VAR
  mp    : PROCESS;
  oldcp : Task;
  ie    : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF cp=NIL THEN
    QInsert(T,cp);          (* add new process *)
  ELSE
    oldcp := cp;            (* remove current process *)
    cp := cp^.next;
    QInsert(T,cp);          (* add new process *)
    QInsert(oldcp,cp);      (* add current process *)
  END;
  mp := cp^.cor;
  TRANSFER (mp,mp);
  SetFlags(ie);
END AddReadyProcess;


PROCEDURE StartProcess(P: PROC; N: CARDINAL; Pr: CARDINAL);
VAR
  t0 : Task; wsp: ADDRESS;
  np : Task;
BEGIN
  t0 := cp;
  ALLOCATE (wsp, N);
  ALLOCATE (np, SIZE(TaskDescriptor));
  np^.priority := Pr;
  NEWPROCESS (P, wsp, N , np^.cor);
  AddReadyProcess(np);
END StartProcess;


PROCEDURE SEND(s: SIGNAL);
VAR
  t0 : Task;
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF s^.count <> MAX(INTEGER) THEN
    INC(s^.count);
    IF s^.count <= 0 THEN (* somebody waiting *)
      t0 := s^.waiting;
      s^.waiting := t0^.next;
      AddReadyProcess(t0);
    END;
  END;
  SetFlags(ie);
END SEND;


PROCEDURE Notify(s: SIGNAL);
VAR
  t0 : Task;
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF s^.count < 0 THEN (* somebody waiting *)
    INC(s^.count);
    t0 := s^.waiting;
    s^.waiting := t0^.next;
    (* add to waiting q *)
    t0^.nextdue := wq;
    wq := t0;
  END;
  SetFlags(ie);
END Notify;


PROCEDURE WAIT (s: SIGNAL);
VAR
  t0 : Task;
  mp : PROCESS;
  ie : CARDINAL;
BEGIN (* insert cp in queue s *)
  ie := GetFlags(); DI;
  DEC(s^.count);
  IF s^.count < 0 THEN (* wait *)
    t0 := cp;
    cp := cp^.next;
    QInsert(t0,s^.waiting);
    mp := cp^.cor;
    TRANSFER (mp,mp);
  END;
  SetFlags(ie);
END WAIT;

PROCEDURE Awaited(s: SIGNAL) : BOOLEAN;
BEGIN
  RETURN (s^.count<0);
END Awaited;


PROCEDURE Init(VAR s: SIGNAL);
BEGIN
  NEW(s);
  s^.waiting := NIL;
  s^.count := 0;
END Init;


PROCEDURE CheckTimeQ;
VAR
  ta,tb,tn : Task;
BEGIN
  ta := dq;
  tb := NIL;
  WHILE ta <> NIL DO
    tn := ta^.nextdue;
    IF ta^.due = SchedTime THEN
      IF tb = NIL THEN dq := tn ELSE tb^.nextdue := tn END;
      ta^.nextdue := wq;
      wq := ta;
    ELSE
      tb := ta;
    END;
    ta := tn;
  END;
END CheckTimeQ;

PROCEDURE Slice;
(* Clears waiting queue *)
(* Then schedules next ready process if it is of equal priority *)
VAR
  nextt,oldt,ta : Task;
BEGIN
  IF LockNest = 0 THEN
    (* move waiting queue to the ready queue *)
    (* set up by CheckTimeQueue *)
    WHILE wq <> NIL DO
      ta := wq; wq := wq^.nextdue;
      QInsert(ta,cp);
    END;
    (* now do slice *)
    nextt := cp^.next;
    IF (nextt <> NIL) AND (nextt^.priority = cp^.priority) THEN (* slice *)
      oldt := cp; cp := nextt;
      QInsert(oldt,cp); (* insert old cp at end of processes *)
    END;
  END;
END Slice;


MODULE SS[1]; (* IRQ 1: timer interrupt *)

 IMPORT Stop,Task,PROCESS,IOTRANSFER,TRANSFER,SchedTime,cp,DI,
        Slice,CheckTimeQ;
 EXPORT Scheduler;


PROCEDURE Scheduler;
VAR
  nextt,
  oldt  : Task;
  op,np : PROCESS;
  Int8  : PROC;

TYPE
  code  = ARRAY[0..2] OF SHORTCARD;

CONST
  Int8code = code(0CDH,08H,0CBH); (* INT 08H / RETF *)

BEGIN
  DI;
  Int8 := PROC(ADR(Int8code));
  Stop := FALSE;
  SchedTime := 0;
  LOOP
    np := cp^.cor;
    LOOP
      IOTRANSFER(op,np,8);
      Int8;
      INC(SchedTime);
      IF Stop THEN EXIT END;
      CheckTimeQ;
      Slice;
      np := cp^.cor;
    END;
    Stop := FALSE;
    TRANSFER(op,np); (* no return until restarted *)
  END;
END Scheduler;


END SS;


PROCEDURE Idler; (* always on cp chain *)
VAR
  i : CARDINAL;
BEGIN
  LOOP INC(i);
  END;
END Idler;

PROCEDURE StartScheduler;
VAR
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF NOT Started THEN
    Started := TRUE;
    IF SchedStack = NIL THEN (* first time *)
      ALLOCATE( SchedStack, 512 );
      NEWPROCESS( Scheduler, SchedStack, 512, SchedProc );
    END;
    TRANSFER( cp^.cor, SchedProc );
  END;
  SetFlags(ie);
END StartScheduler;

PROCEDURE StopScheduler;
VAR
  ie : CARDINAL;
BEGIN
  ie := GetFlags();
  IF Started THEN
    EI ;
    Started := FALSE;
    Stop := TRUE;
    WHILE Stop DO END;
  END;
  SetFlags(ie);
END StopScheduler;

PROCEDURE Delay(T: CARDINAL);
(* Waits T time slices *)
(* 0 will swap to next process of equal priority, without delaying *)
VAR
  mp : PROCESS;
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF T = 0 THEN
    mp := cp^.cor;
    Slice;
    IF mp = cp^.cor THEN
      SetFlags(ie);
      RETURN
    END; (* no other processes ready *)
  ELSE
    cp^.due := SchedTime + T;
    cp^.nextdue := dq;
    dq := cp;
    cp := cp^.next;
  END;
  mp := cp^.cor;
  TRANSFER(mp,mp);
  SetFlags(ie);
END Delay;


PROCEDURE Lock;
(* Critical region lock - prevents timeslicing *)
(* may be nested *)
BEGIN
  INC(LockNest);
END Lock;

PROCEDURE Unlock;
(* Unlock procedure, always paired with a call to Lock.
   Will de-schedule current process if there are ready processes
   of equal priority *)

VAR
  ie : CARDINAL;
BEGIN
  ie := GetFlags(); DI;
  IF LockNest <= 1 THEN
    LockNest := 0; Delay(0);
  ELSE
    DEC(LockNest);
  END;
  SetFlags(ie);
END Unlock;



VAR
  Continue : PROC;

PROCEDURE CloseDown;
BEGIN
  StopScheduler;
  Continue;
END CloseDown;


BEGIN
  dq := NIL;
  wq := NIL;
  NEW(cp);
  cp^.next := NIL;
  cp^.priority := 1;
  cp^.cor  := CurrentProcess();
  StartProcess( Idler, 512 , 0 );
  SchedStack := NIL;
  Started  := FALSE;
  LockNest := 0;
  Terminate(CloseDown,Continue);
END Process.
