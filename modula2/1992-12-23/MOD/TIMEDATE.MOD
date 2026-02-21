(******************************************************************************)
(*                                                                            *)
(*       MODULA-2    Library                                                  *)
(*                                                                            *)
(*              LOGITECH SA,   CH-1111 Romanel    (Switzerland)               *)
(*              LOGITECH Inc,  Fremont, CA 94555  (USA)                       *)
(*                                                                            *)
(*       Module:  TimeDate                                        	      *)
(*          Module 'TimeDate' provides routines for reading and 	      *)
(*          writing the system's date and time.                 	      *)
(*                                                                            *)
(*       Release :    3.0 - July 87                                           *)
(*                                                                            *)
(*       Copyright (C)  1987 Logitech, All rights reserved                    *)
(*                                                                            *)
(*       Permission is hereby granted to registered users to use or abstract  *)
(*       the following program in the implementation of customized versions.  *)
(*       This permission does not include the right to redistribute the       *)
(*       source code of this program.                                         *)
(*                                                                            *)
(******************************************************************************)
(*$T-*)
(*$R-*)
IMPLEMENTATION MODULE TimeDate;         (* WS, McL *)
  FROM SYSTEM IMPORT Registers;
  FROM Lib IMPORT Dos;

  PROCEDURE GetTime (VAR curTime: Time);
  VAR R : Registers;
  BEGIN
    R.AX := 2A00H;
    Dos(R); (* CX = year, DH = month, DL = day *)
    curTime.day := (R.CX-1900)*512 + CARDINAL(R.DH)*32 + CARDINAL(R.DL);
    R.AX := 2C00H;
    Dos(R); (* CH = hour, CL = min, DH = sec, DL = hund *)
    curTime.minute := CARDINAL(R.CH)*60 + CARDINAL(R.CL);
    curTime.millisec := CARDINAL(R.DH)*1000 + CARDINAL(R.DL)*10;
  END GetTime;


  PROCEDURE SetTime (newTime: Time);
  VAR R : Registers;
  BEGIN
    R.AX := 2B00H;
    R.CX := (newTime.day DIV 512) +1900;
    R.DX := (newTime.day MOD 32) + 256*((newTime.day DIV 32) MOD 16);
    Dos(R);
    R.AX := 2D00H;
    R.CX := 256*(newTime.minute DIV 60) + (newTime.minute MOD 60);
    R.DX := (newTime.millisec DIV 1000)*256 +
            ((newTime.millisec MOD 1000) DIV 10);
    Dos(R);
  END SetTime;

  PROCEDURE CompareTime(t1, t2: Time): INTEGER;
  BEGIN
    IF t1.day < t2.day THEN
      RETURN -1;
    ELSIF t1.day > t2.day THEN
      RETURN 1;
    ELSIF t1.minute < t2.minute THEN
      RETURN -1;
    ELSIF t1.minute > t2.minute THEN
      RETURN 1;
    ELSIF t1.millisec < t2.millisec THEN
      RETURN -1;
    ELSIF t1.millisec > t2.millisec THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END;
  END CompareTime;

  PROCEDURE TimeToZero(VAR t: Time);
  BEGIN
    t.day      := 0;
    t.minute   := 0;
    t.millisec := 0;
  END TimeToZero;

  PROCEDURE TimeToString(t: Time; VAR s: ARRAY OF CHAR);
    VAR
      year, month, day, hour, minute, second: CARDINAL;
  BEGIN
    day := t.day MOD 32;
    t.day := t.day DIV 32;
    month := t.day MOD 16;
    year := t.day DIV 16;
    second := t.millisec DIV 1000;
    minute := t.minute MOD 60;
    hour := t.minute DIV 60;

    s[16] := CHR(second MOD 10 + ORD('0'));
    s[15] := CHR(second DIV 10 + ORD('0'));
    s[14] := ':';

    s[13] := CHR(minute MOD 10 + ORD('0'));
    s[12] := CHR(minute DIV 10 + ORD('0'));
    s[11] := ':';

    s[10] := CHR(hour MOD 10 + ORD('0'));
    s[ 9] := CHR(hour DIV 10 + ORD('0'));
    s[ 8] := ' ';

    s[ 7] := CHR(day MOD 10 + ORD('0'));
    s[ 6] := CHR(day DIV 10 + ORD('0'));
    s[ 5] := '-';

    s[ 4] := CHR(month MOD 10 + ORD('0'));
    s[ 3] := CHR(month DIV 10 + ORD('0'));
    s[ 2] := '-';

    s[ 1] := CHR(year MOD 10 + ORD('0'));
    s[ 0] := CHR(year DIV 10 + ORD('0'));

    IF HIGH(s) >= 17 THEN s[17] := 0C END; (* string terminator *)

  END TimeToString;

END TimeDate.
