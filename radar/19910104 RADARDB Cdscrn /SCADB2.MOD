MODULE SCADB;

(* SCA Digital Broadcasting Protocol, version B.2
 *
 * Terminate-and-Stay-Resident kernel for SCADB broadcasting.  All
 * controls for this are done through DOS environments and control
 * files.
 *
 *)


IMPORT FIO, SYSTEM, Lib;


CONST Com1        = 3F8H;
      Com1INr     = 4;
      Com2        = 2F8H;
      Com2INr     = 3;

VAR IOBase,ComINr : CARDINAL;

CONST
      TXBuffer    ::= IOBase;
      RXBuffer    ::= IOBase;
      DivisorLsb  ::= IOBase;


      BufferSize  = 1024;
      BrBufSize   = 128;
      TRMax       = BufferSize-16;
      Noise       = FALSE;

TYPE pt = (None,Even,Odd,Mark,Space);
     wl = SHORTCARD[5..8];

VAR WorkSpace             : ARRAY[0..7FFH] OF CHAR;
    MainProc              : ADDRESS;
    IP                    : ADDRESS;
    OldC                  : PROC;
    Term                  : PROC;
(*$W+*)
    TXReady,CTS,CTSH     : BOOLEAN;
    DTR                  : BOOLEAN;
    TXCount,TXI,TXO      : CARDINAL;
    RXCount,RXI,RXO      : CARDINAL;
    BrCount,BrI,BrO      : CARDINAL;
    IBuf,OBuf            : ARRAY[0..BufferSize-1] OF SHORTCARD;
    BrBuf                : ARRAY [ 0..BrBufSize-1 ] OF CARDINAL;
(*$W-*)

PROCEDURE TX;
BEGIN
  IF CTS OR NOT CTSH THEN
     TXReady := FALSE;
     SYSTEM.Out( TXBuffer,OBuf[TXO] );
     TXO := (TXO+1) MOD BufferSize;
     DEC(TXCount);
  END;
END TX;

PROCEDURE RX;
TYPE b = SET OF SHORTCARD[0..7];
BEGIN
  IF RXCount >= TRMax THEN
     SYSTEM.Out( IOBase+4 (*ModemCont*), SHORTCARD( b(SYSTEM.In(IOBase+4 (*ModemCont*)))-b{0,1} ) );
     (* DTR,RTS := FALSE *)
     DTR := FALSE;
     RXCount := 0;
     RXO := RXI;
  END;
  IBuf[RXI] := SYSTEM.In( RXBuffer );
  IF Noise AND (Lib.RANDOM(500)=0) THEN
     IBuf[RXI] := SHORTCARD(Lib.RANDOM(256));
  END;
  RXI := (RXI+1) MOD BufferSize;
  INC(RXCount);
END RX;

PROCEDURE ReportBreak;
BEGIN
  BrBuf[BrI] := ( RXI + 1 ) MOD BufferSize;
  BrI := ( BrI + 1 ) MOD BrBufSize;
  INC( BrCount );
END ReportBreak;

(*$C FF,J+*)
PROCEDURE Int;
TYPE b = SET OF SHORTCARD[0..7];
VAR i  : SHORTCARD;
    s  : b;
BEGIN
(*  SYSTEM.EI; *)
  LOOP
    i := SYSTEM.In( IOBase+2 (*IntId*) );
    IF i=1 THEN EXIT; END;
    CASE i DIV 2 OF
    |  0 : (* Modem status *)

           s := b(SYSTEM.In( IOBase+6 (*ModemStatus*) ));

           IF 0 IN s THEN (* CTS changed *)
              CTS :=4 IN s;
              IF CTS AND (TXCount >0) AND TXReady THEN TX END;
           END;


    |  1 : (* TXEmpty      *)
           TXReady := TRUE;
           IF TXCount > 0 THEN TX; END;

    |  2 : (* RXReady      *)

           RX;

(*    |  3 : (* LineStatus   *)

           s := b(SYSTEM.In( IOBase+5 (*LineStatus*) ));
           IF (4 IN s) THEN
               ReportBreak;
           END (* IF *); *)
(*
           IF 1 IN s THEN IO.WrStr('OR-Error'); END;
           IF 2 IN s THEN IO.WrStr('PE-Error'); END;
           IF 4 IN s THEN IO.WrStr('Break');
           ELSIF 3 IN s THEN IO.WrStr('FE-Error'); END;

           SYSTEM.Out(20H,20H);
           HALT;*)
      ELSE (*IO.WrStr('Unknown Int'); HALT; *)
    END;
  END;
  SYSTEM.Out(20H,20H);
END Int;

(*$C F0,J-*)

PROCEDURE Init( Baud       : CARDINAL;
                WordLength : CARDINAL;
                Parity     : pt;
                OneStopBit : BOOLEAN;
                HandShake  : BOOLEAN);

VAR d, lc  : CARDINAL;
BEGIN
  CTSH := HandShake;
  lc := (WordLength-5) MOD 4;
  IF NOT OneStopBit THEN lc := lc+4; END;
  CASE Parity OF
  | None  :;
  | Even  : lc := lc+18H;
  | Odd   : lc := lc+ 8H;
  | Mark  : lc := lc+38H;
  | Space : lc := lc+28H;
  END;
  SYSTEM.Out( IOBase+3 (*LineCont*),80H );
  d := CARDINAL( 115200 DIV LONGCARD( Baud ) );
  SYSTEM.Out( DivisorLsb, SHORTCARD(d));
  SYSTEM.Out( IOBase+1 (*DivisorMsb*), SHORTCARD(d DIV 100H));
  SYSTEM.Out( IOBase+3 (*LineCont*), SHORTCARD(lc) );
END Init;

TYPE dp=POINTER TO PROC;

PROCEDURE CloseDown;
BEGIN
(*  IO.WrShtHex( SYSTEM.In( IOBase+5 (*LineStatus*) ),4 ); *)
  [0:4*(8+ComINr) dp]^ := OldC;
  SYSTEM.Out( IOBase+1 (*IntEnable*),00H );
  Term;
END CloseDown;

PROCEDURE Install2( Port,Intr : CARDINAL);
TYPE bs = SET OF SHORTCARD[0..7];
VAR  s  : SHORTCARD; i : CARDINAL;
BEGIN
  IOBase := Port;
  ComINr := Intr;
  SYSTEM.Out( IOBase+1 (*IntEnable*),00H );
  SYSTEM.Out( IOBase+5 (*LineStatus*),0 );
  TXI     := 0;
  TXO     := 0;
  RXI     := 0;
  RXO     := 0;
  BrI     := 0;
  BrO     := 0;
  RXCount := 0;
  TXCount := 0;
  BrCount := 0;
  OldC    := [0:4*(8+ComINr) dp]^;
  [0:4*(8+ComINr) dp]^    := PROC(ADR(Int));
  Lib.Terminate( CloseDown,Term );
  SYSTEM.NewPriority( CARDINAL(BITSET( SYSTEM.CurrentPriority() )-{ComINr} ) );
  FOR i := 1 TO 10 DO
      s := SYSTEM.In( RXBuffer );
      s := SYSTEM.In( IOBase+5 (*LineStatus*) );
      Lib.Delay(10);
  END;
  TXReady := TRUE;
  CTS     := 4 IN bs(SYSTEM.In( IOBase+6 (*ModemStatus*) ));
  DTR     := TRUE;
  SYSTEM.Out( IOBase+1 (*IntEnable*),07H );
  SYSTEM.Out( IOBase+4 (*ModemCont*),0BH );
END Install2;



END SCADB.
