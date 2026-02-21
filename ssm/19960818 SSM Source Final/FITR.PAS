(*****************************************************************************)
(*    Pump Totalizer Reading routines                                        *)
(*****************************************************************************)

TYPE
  TRRec        = RECORD
    Shift      :   integer;
    Readings   :   ARRAY[1..10] of REAL;

    Sales      :   ARRAY[1..10] of REAL;
                 END;

  TRSRec       = RECORD
    Shift      :   integer;
    Readings   :   ARRAY[1..10] of REAL;
                 END;

CONST
  TRColumnSt = 9;
  TRTotals   = 18;
  TRMeters   = 19;
  TRSales    = 22;
  TRPump     = 9;

VAR
  TR           : TRRec;
  TRS          : TRSRec ABSOLUTE TR;
  TRFile       : FILE of TRSRec;
  TRChanged    : BOOLEAN;
  LastTR       : INTEGER;
  AuxTR        : TRRec;
  AuxTRS       : TRSRec ABSOLUTE AuxTR;
  fuelcount    : fuel;


PROCEDURE WriteTRRow(ForPump : integer);

  BEGIN
    WITH TR DO BEGIN
      WGoto(20,9+ForPump);
      Write(Usr,AuxTR.Readings[ForPump]:15:0);
      WGoto(41,9+ForPump);
      Write(Usr,Readings[ForPump]:15:0);
      WGoto(62,9+ForPump);
      Write(Usr,Sales[ForPump]:15:0);
    END;
  END;


PROCEDURE WriteTR;

  BEGIN
    WGoto(68,4);
    Write(Usr,ShortDate(Log[CurrentLog].Date));
    WGoto(68,5);
    Write(Usr,ShortTime(Log[CurrentLog].Date));
    WGoto(69,6);
    Write(Usr,TR.Shift:6);
    FOR I:= 1 to 10 DO BEGIN
      WriteTRRow(I);
    END;
  END;


PROCEDURE SetReading(PumpNumber : INTEGER;Value : REAL);
  BEGIN
    TRChanged:=TRUE;
    WITH TR DO BEGIN
      Readings[PumpNumber]:=Value;
      Sales[PumpNumber]:=Readings[PumpNumber]-AuxTR.Readings[PumpNumber];
    END;
    IF TR.Readings[PumpNumber]<AuxTR.Readings[PumpNumber] THEN BEGIN
      ErrorMsg('That reading was less than the previous one.  Please check it');
      WriteEditLine(TRt);
      Key:=#0;
    END;
  END;


PROCEDURE CalcTR;

  VAR PumpCount : integer;

  BEGIN
    FOR PumpCount:=1 TO 10 DO
      SetReading(PumpCount,TR.Readings[PumpCount]);
  END;


PROCEDURE LoadTR(PrevTRPointer : INTEGER);

  BEGIN
    (* CheckFile('TR.DAT'); *)
    ReSet(TRFile);
    IF Log[CurrentLog].Pointer[TRt]>0 THEN BEGIN
      Seek(TRFile,Log[CurrentLog].Pointer[TRt]-1);
      Read(TRFile,TRS);
    END
    ELSE FillChar(TR,SizeOf(TR),0);
    IF PrevTRPointer>=0 THEN BEGIN
      Seek(TRFile,Log[PrevTRPointer].Pointer[TRt]-1);
      Read(TRFile,AuxTRS);
{      FOR J:=PrevTRPointer+1 to CurrentLog-1 DO BEGIN
        IF Log[J].Pointer[TRt]>0 THEN BEGIN
          Seek(TRFile,Log[J].Pointer[TRt]-1);
          Read(TRFile,AuxTRS);
          FOR fuelcount:=Regular to All DO
            TR.MeterAdj[fuelcount]:=TR.MeterAdj[fuelcount]
              +AuxTR.MeterAdj[fuelcount];
        END;
      END;}
    END
    ELSE FillChar(AuxTR,SizeOf(AuxTR),0);
    IF Log[CurrentLog].Pointer[TRt]>0 THEN BEGIN
      Seek(TRFile,Log[CurrentLog].Pointer[TRt]-1);
      Read(TRFile,TRS);
      CalcTR;
    END
    ELSE FillChar(TR,SizeOf(TR),0);
    Close(TRFile);
  END;


{PROCEDURE LoadDLMFI; FORWARD;

PROCEDURE SaveDLMFI; FORWARD;}

PROCEDURE SaveTR;

  BEGIN
    (* CheckFile('TR.DAT'); *)
    ReSet(TRFile);
    IF Log[CurrentLog].Pointer[TRt]=0 THEN Log[CurrentLog].Pointer[TRt]:=FileSize(TRFile)+1;
    IF Log[CurrentLog].Pointer[TRt]<0 THEN Log[CurrentLog].Pointer[TRt]:=-Log[CurrentLog].Pointer[TRt];
    Seek(TRFile,Log[CurrentLog].Pointer[TRt]-1);
    Write(TRFile,TRS);
    Close(TRFile);
    IF Log[CurrentLog].Pointer[DLMFIt]>0 THEN BEGIN
{      LoadDLMFI;
      SaveDLMFI;}
    END;
    SaveLog(CurrentLog);
  END;


PROCEDURE EditTR;
  VAR  YPos  : integer;
  BEGIN
    WriteEditLine(TRt);
    REPEAT
      IF K=1 THEN HiLiteCell(68,6,6) ELSE HiLiteCell(40,K+8,15);
      ReadKbd;
      IF K=1 THEN LoLiteCell(68,6,6) ELSE LoLiteCell(40,K+8,15);
      CASE Key of
        #72      : IF K>1 THEN K:=K-1;
        #80      : IF K<11 THEN K:=K+1;
        'r'      : IF Log[CurrentLog].Pointer[TRt]<0 THEN BEGIN
                     Log[CurrentLog].Pointer[TRt]:=-Log[CurrentLog].Pointer[TRt];
                     I:=CurrentLog-1;
                     WHILE (Log[I].Pointer[TRt]<=0) AND (I>=0) DO I:=I-1;
                     LoadTR(I);
                     WriteTR;
                     WriteEditLine(TRt);
                     SaveLog(CurrentLog);
                     K:=1; fuelcount:=Regular;
                   END;
        'd'      : IF Log[CurrentLog].Pointer[TRt]>0 THEN BEGIN
                     Log[CurrentLog].Pointer[TRt]:=-Log[CurrentLog].Pointer[TRt];
                     SaveLog(CurrentLog);
                     Key:=#27;
                     Exit;
                   END;
        '0'..'9' : IF K=1 THEN
                     Val(EnterCell(68,6,6,['0'..'9']),TR.Shift,I)
                   ELSE BEGIN
                     Val(EnterCell(40,K+8,15,['0'..'9']),X,I);
                     SetReading(K-1,X);
                     WriteTRRow(K-1);
                   END;
      END;
      IF Key=#13 THEN
        IF K<11 THEN K:=K+1 ELSE Key:=#27;
    UNTIL Key=#27;
    Key:=#0;
    WriteKeyLine;
  END;


PROCEDURE EnterTR;
  BEGIN
    OneMoment;
    IF Log[CurrentLog].Pointer[TRt]<=0 THEN IF NOT ChangeStatus THEN Exit;
    TRChanged:=FALSE;
    I:=CurrentLog-1;
    WHILE (Log[I].Pointer[TRt]<=0) AND (I>=0) DO I:=I-1;
    LoadTR(I);
    ChangeWindow(TRWindow);
    WriteTR;
    WriteKeyLine;
    fuelcount:=Regular;K:=1;
    IF Log[CurrentLog].Pointer[TRt]<=0 THEN EditTR;
    WriteKeyLine;
    REPEAT
      ReadKbd;
      CASE Key of
        'e' : IF ChangeStatus THEN BEGIN
                EditTR;
                WriteKeyLine;
              END;
        'p' : BEGIN
                PrintWind;
                WriteKeyLine;
              END;
      END;
    UNTIL Key=#27;
    IF TRChanged THEN SaveTR;
    DrawLog;
  END;