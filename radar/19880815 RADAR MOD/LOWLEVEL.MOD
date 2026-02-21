IMPLEMENTATION MODULE LowLevel;
(*
 *  REPERTOIRE
 *  Release 1.5
 *  (c) Copyright 1986, 1987 PMI
 *  Portland, Oregon
 *  All rights reserved
 *  Compuserve:  74706,262
 *  MCI Mail:  PMI
 *)

(* JPI version *)

IMPORT Lib, SYSTEM;


  PROCEDURE AddAddr( TheAdr: SYSTEM.ADDRESS; bytes: CARDINAL ):
      SYSTEM.ADDRESS;
    VAR
      tmp : Address8086;
    BEGIN
      RETURN Lib.AddAddr( TheAdr, bytes );
(*
      tmp.a := TheAdr;
      INC( tmp.off, bytes );
      RETURN tmp.a;
*)
    END AddAddr;


  PROCEDURE DecAddr( VAR TheAdr: SYSTEM.ADDRESS; bytes: CARDINAL );
    VAR
      tmp : Address8086;
    BEGIN
      Lib.DecAddr( TheAdr, bytes );
(*
      tmp.a := TheAdr;
      DEC( tmp.off, bytes );
      TheAdr := tmp.a;
*)
    END DecAddr;


  PROCEDURE EMInterrupt( VAR TheRegs : regpack; Function: CARDINAL );
    BEGIN
      TheRegs.a.h := CHR(Function);
      Interrupt( 67H, TheRegs );
    END EMInterrupt;


  PROCEDURE Fill(dest : SYSTEM.ADDRESS; size : CARDINAL; thefill
      : SYSTEM.BYTE);
  (* Starting at source address fill with size bytes of thefill *)
    BEGIN
      Lib.Fill( dest, size, thefill );
    END Fill;

  PROCEDURE FillWord(dest : SYSTEM.ADDRESS; size : CARDINAL;
      thefill : SYSTEM.WORD);
    BEGIN
      Lib.WordFill( dest, size, thefill );
    END FillWord;


  PROCEDURE FlaggedError(TheFlags : BITSET) : BOOLEAN;
    (*Detects the PC/MS-DOS error signal in the carry flag.*)
    BEGIN
      RETURN 0 IN TheFlags;
    END FlaggedError;


  PROCEDURE InByte( port: CARDINAL; VAR value: SYSTEM.BYTE );
    BEGIN
      value := SYSTEM.In( port );
    END InByte;


  PROCEDURE IncAddr( VAR TheAdr: SYSTEM.ADDRESS; bytes: CARDINAL );
    VAR
      tmp : Address8086;
    BEGIN
      Lib.IncAddr( TheAdr, bytes );
(*
      tmp.a := TheAdr;
      INC( tmp.off, bytes );
      TheAdr := tmp.a;
*)
    END IncAddr;


  PROCEDURE Interrupt( InterruptNumber: CARDINAL; VAR
      TheRegs : regpack );
    BEGIN
      Lib.Intr( SYSTEM.Registers(TheRegs), InterruptNumber );
    END Interrupt;



  PROCEDURE InWord( port: CARDINAL; VAR value: SYSTEM.WORD );
    VAR
      tmp: DataRegister;
    BEGIN
      tmp.h := CHAR(SYSTEM.In( port ));
      tmp.l := CHAR(SYSTEM.In( port ));
      value := tmp.x;
    END InWord;


  PROCEDURE Move(source, dest : SYSTEM.ADDRESS; size : CARDINAL);
    (* Copy size bytes from source address to dest address *)
    BEGIN
      Lib.Move( source, dest, size );
    END Move;


  PROCEDURE msdos(VAR TheRegs : regpack);
    VAR
      R : SYSTEM.Registers ;
    BEGIN
      R := SYSTEM.Registers(TheRegs) ;
      Lib.Dos(R);
      TheRegs.a.x := R.AX ;
      IF (*OutputStatus=Output*) TRUE THEN
        TheRegs := regpack(R) ;
      END;
      TheRegs.flags := BITSET(CARDINAL(R.Flags * {0..7}));
    END msdos;

  PROCEDURE ofs(TheAddr : SYSTEM.ADDRESS) : CARDINAL;
    VAR
      bufaddr : Address8086;
    BEGIN
      RETURN (SYSTEM.Ofs(TheAddr^));
    END ofs;

  PROCEDURE OutByte( port: CARDINAL; value: SYSTEM.BYTE );
    BEGIN
      SYSTEM.Out( port, value );
    END OutByte;


  PROCEDURE OutWord( port: CARDINAL; value: SYSTEM.WORD );
    VAR
      tmp: DataRegister;
    BEGIN
      tmp.x := value;
      SYSTEM.Out( port, SHORTCARD(tmp.l) );
      SYSTEM.Out( port, SHORTCARD(tmp.h) );
    END OutWord;


  PROCEDURE PeekByte(segm, offs : CARDINAL) : CHAR;
    VAR
      TmpPtr : Address8086;
    BEGIN
      RETURN CHAR([segm:offs]^) ;
    END PeekByte;

  PROCEDURE PeekWord(segm, offs : CARDINAL) : CARDINAL;
    BEGIN
      RETURN CARDINAL([segm:offs]^) ;
    END PeekWord;

  PROCEDURE PokeByte(TheByte : CHAR; segm, offs : CARDINAL);
    TYPE CP = POINTER TO CHAR ;
    BEGIN
      [segm:offs CP]^ := TheByte ;
    END PokeByte;

  PROCEDURE PokeWord(TheWord : CARDINAL; segm, offs : CARDINAL);
    BEGIN
      [segm:offs]^ := WORD(TheWord) ;
    END PokeWord;


  PROCEDURE Ptr( segment, offset: CARDINAL ): SYSTEM.ADDRESS;
    VAR
      tmp: Address8086;
    BEGIN
(*
      tmp.off := offset;
      tmp.seg := segment;
      RETURN tmp.a;
*)
      RETURN [segment:offset];
    END Ptr;


  PROCEDURE ScanEQ(size : INTEGER; lookfor : SYSTEM.BYTE; start :
      SYSTEM.ADDRESS) : INTEGER;
  (* Starting at the address start, scan size bytes at most,
     looking for lookfor.  If size is negative, look backwards
     from start.  Result is number of bytes skipped to get to
     lookfor, or size if not found *)
    BEGIN
      IF size>=0 THEN
        RETURN INTEGER(Lib.ScanR(start,CARDINAL(size),lookfor));
      ELSE
        RETURN -INTEGER(Lib.ScanL(start,CARDINAL(-size),lookfor));
      END;
    END ScanEQ;

  PROCEDURE ScanNE(size : INTEGER; lookfor : SYSTEM.BYTE; start :
      SYSTEM.ADDRESS) : INTEGER;
  (* Starting at the address start, scan size bytes at most,
     until find a BYTE unequal to lookfor.  If size is negative,
     look backwards from start.  Result is number of bytes
     skipped to get to lookfor, or size if not found *)
    BEGIN
      IF size>=0 THEN
        RETURN INTEGER(Lib.ScanNeR(start,CARDINAL(size),lookfor));
      ELSE
        RETURN -INTEGER(Lib.ScanNeL(start,CARDINAL(-size),lookfor));
      END;
    END ScanNE;

  PROCEDURE seg(TheAddr : SYSTEM.ADDRESS) : CARDINAL;
    VAR
      bufaddr : Address8086;
    BEGIN
      RETURN (SYSTEM.Seg(TheAddr^));
    END seg;

  PROCEDURE ShiftArrayLeft( TheAdr: SYSTEM.ADDRESS; TheSize,
      distance: CARDINAL );
    BEGIN
      IF distance < TheSize THEN
        Move( SYSTEM.ADDRESS(LONGCARD(TheAdr) +
            LONGCARD(distance)), TheAdr, TheSize - distance );
      END;
    END ShiftArrayLeft;

  PROCEDURE ShiftArrayRight( TheAdr: SYSTEM.ADDRESS; TheSize,
      distance: CARDINAL );
    BEGIN
      (*JPI M2 can use Move when copying even in this direction.*)
      IF distance < TheSize THEN
        Move( TheAdr, SYSTEM.ADDRESS(LONGCARD(TheAdr) + LONGCARD(distance)),
            TheSize - distance );
      END;
    END ShiftArrayRight;


  PROCEDURE ShiftLeft(VAR TheWord : SYSTEM.WORD; HowMany : CARDINAL);
    BEGIN
      TheWord := CARDINAL(TheWord) << HowMany;
    END ShiftLeft;

  PROCEDURE ShiftRight(VAR TheWord : SYSTEM.WORD; HowMany : CARDINAL);
    BEGIN
      TheWord := CARDINAL(TheWord) >> HowMany;
    END ShiftRight;


  PROCEDURE SubAddr( TheAdr: SYSTEM.ADDRESS; bytes: CARDINAL ): SYSTEM.ADDRESS;
    VAR
      tmp : Address8086;
    BEGIN
      RETURN Lib.SubAddr( TheAdr, bytes );
(*
      tmp.a := TheAdr;
      DEC( tmp.off, bytes );
      RETURN tmp.a;
*)
    END SubAddr;


  PROCEDURE VideoInterrupt(VAR TheRegs : regpack);
    BEGIN
      Interrupt(10H, TheRegs);
    END VideoInterrupt;

(*
  TYPE  CODE = ARRAY[0..60] OF SHORTCARD;
  CONST CodeArray = CODE(
          055H,                (* PUSH   BP                                 *)
          089H,0E5H,           (* MOV    BP,SP                              *)
          056H,                (* PUSH   SI                                 *)
          057H,                (* PUSH   DI                                 *)
          01EH,                (* PUSH   DS                                 *)
          006H,                (* PUSH   ES                                 *)
          08BH,04EH,006H,      (* MOV    CX,[BP+06]                         *)
          0C4H,07EH,008H,      (* LES    DI,[BP+08]                         *)
          0C5H,076H,00CH,      (* LDS    SI,[BP+0C]                         *)
          0BAH,0DAH,003H,      (* MOV    DX,03DA                            *)
(*Top1:*) 0ECH,                (* IN     AL,DX   ; wait until Vert retrace  *)
          0A8H,008H,           (* TEST   AL,08   ; not in progress          *)
          075H,0FBH,           (* JNZ    Top1                               *)
          0F7H,0C1H,0FFH,0FFH, (* TEST   CX,FFFF                            *)
(*CHKH:*) 074H,017H,           (* JZ     END1  ; exit if nothing to write   *)
(*TOP2:*) 0ECH,                (* IN     AL,DX ; wait until Horiz. retrace  *)
          0A8H,001H,           (* TEST   AL,01 ; not in progress            *)
          074H,0FBH,           (* JZ     Top2                               *)
          0ECH,                (* IN     AL,DX   ; IF in Vertical retrace   *)
          0A8H,008H,           (* TEST   AL,08   ; goto block move          *)
          075H,00BH,           (* JNZ    TopV                               *)
          0FAH,                (* CLI                                       *)
(*TOPH:*) 0ECH,                (* IN     AL,DX   ; wait until Horiz. retrace*)
          0A8H,001H,           (* TEST   AL,01    ; in progress             *)
          074H,0FBH,           (* JZ     TopH                               *)
          0A4H,                (* MOVSB             ; write one byte        *)
          0FBH,                (* STI                                       *)
          049H,                (* DEC    CX       ec count and go to top    *)
          0EBH,0E9H,           (* JMP    ChkH                               *)
(*TOPV:*) 0F3H,                (* REPZ              ; then move line        *)
          0A4H,                (* MOVSB                                     *)
(*END1:*) 007H,                (* POP    ES                                 *)
          01FH,                (* POP    DS                                 *)
          05FH,                (* POP    DI                                 *)
          05EH,                (* POP    SI                                 *)
          05DH,                (* POP    BP                                 *)
          0CAH,00AH,000H);     (* RETF   000A                               *)


  TYPE
    MoveDMAProc = PROCEDURE( SYSTEM.ADDRESS, SYSTEM.ADDRESS, CARDINAL);
  VAR
    MoveDMA : MoveDMAProc;
*)

  PROCEDURE WriteDMANoSnow( FromAddr, ToAddr: SYSTEM.ADDRESS; size: CARDINAL);
    BEGIN
      (* JPI users will have to put up with snow on CGA monitors
         until we figure out why the CodeArray approach above
         doesn't work, or until we figure out a decent way to
         connect this compiler with MASM.*)
      Move( FromAddr, ToAddr, size );
    END WriteDMANoSnow;

BEGIN
(*
  MoveDMA := MoveDMAProc(ADR(CodeArray));
*)
END LowLevel.
