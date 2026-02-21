TYPE
  LogRec           = RECORD
    Date           :   DateRec;
    Total          :   REAL;
    DataPtr        :   INTEGER;
    DescriptorPtr  :   INTEGER;
                     END;

  DataRec          = RECORD
    Shift          :   INTEGER;
    Bal1, Chg1, ROA1, Total1  :  REAL;
    Cash, Chks, SubT, PO, Chg2, ManCC, CC, Total2, CCFee,
        Bal2, Over, Short, Bal3  :  REAL;
    Gas, Oil, Acc, Lab, Snacks, Emiss, Kero, Wrkr, ROA2,
        Tax, Total3  :  REAL;
  END (* RECORD *);

VAR
  Log              : ARRAY[0..731] of LogRec;
  AuxLog           : LogRec;
  LogFile          : FILE of LogRec;
  CurrentLog       : INTEGER;
  LastLog          : INTEGER;
  SaveToLog        : INTEGER;

  DIRWindow        : BYTE;
  DIRScreen        : ARRAY[1..52,1..78] of CHAR;
  Data             : DataRec;
  AuxData          : DataRec;
  DataFile         : FILE of DataRec;
  DIRChanged       : BOOLEAN;
  CurrentDescriptor: INTEGER;


PROCEDURE CreateDIRWindow;

  VAR
    Count          : INTEGER;

  BEGIN
(*    Move(DIRHeader,DIRScreen,SizeOf(DirHeader));
    FOR Count:=1 to NumberofAccounts DO
      Move(DIRExpand,DIRScreen[Count*2+8],SizeOf(DIRExpand));
    Move(DIREnd,DIRScreen[Count*2+10],SizeOf(DIREnd));
    DIRWindow:=NumberofAccounts*2+11;
    ChangeWindow(DIRWindow);
    FOR Count:=1 to NumberofAccounts DO BEGIN
      WGoto(4,Count*2+8);
      Write(Usr,Descriptor[Count].Number:8);
      WGoto(15,Count*2+8);
      Write(Usr,Descriptor[Count].Name);
    END; *)
  END;


PROCEDURE WriteDIR;

  BEGIN
    (* Write date *)
    WGoto(Col1,3); Write(Usr,ShortDate(Log[CurrentLog].Date),'    ');
    (* Write shift *)
    WGoto(Col3,3); Write(Usr,Data.Shift:8);
    (* Write first column *)
    WGoto(Col1,11); Write(Usr,Data.Bal1:8:2);
    WGoto(Col1,12); Write(Usr,Data.Chg1:8:2 );
    WGoto(Col1,13); Write(Usr,Data.ROA1:8:2 );
    WGoto(Col1,15); Write(Usr,Data.Total1:8:2);
    (* Write second column *)
    WGoto(Col2,7); Write(Usr,Data.Cash:8:2 );
    WGoto(Col2,8); Write(Usr,Data.Chks:8:2 );
    WGoto(Col2,9); Write(Usr,Data.SubT:8:2 );
    WGoto(Col2,11); Write(Usr,Data.PO:8:2   );
    WGoto(Col2,12); Write(Usr,Data.Chg2:8:2);
    WGoto(Col2,13); Write(Usr,Data.ManCC:8:2);
    WGoto(Col2,14); Write(Usr,Data.CC:8:2   );
    WGoto(Col2,15); Write(Usr,Data.Total2:8:2);
    WGoto(Col2,17); Write(Usr,Data.CCFee:8:2);
    WGoto(Col2,18); Write(Usr,Data.Bal2:8:2 );
    WGoto(Col2,19); Write(Usr,Data.Over:8:2 );
    WGoto(Col2,20); Write(Usr,Data.Short:8:2);
    WGoto(Col2,21); Write(Usr,Data.Bal3:8:2 );
    (* Write third column *)
    WGoto(Col3,7); Write(Usr,Data.Gas:8:2  );
    WGoto(Col3,8); Write(Usr,Data.Oil:8:2  );
    WGoto(Col3,9); Write(Usr,Data.Acc:8:2  );
    WGoto(Col3,10); Write(Usr,Data.Lab:8:2  );
    WGoto(Col3,11); Write(Usr,Data.Snacks:8:2);
    WGoto(Col3,12); Write(Usr,Data.Emiss:8:2);
    WGoto(Col3,13); Write(Usr,Data.Kero:8:2 );
    WGoto(Col3,14); Write(Usr,Data.Wrkr:8:2 );
    WGoto(Col3,15); Write(Usr,Data.ROA2:8:2 );
    WGoto(Col3,16); Write(Usr,Data.Tax:8:2  );
    WGoto(Col3,17); Write(Usr,Data.Total3:8:2);
(*    FOR I:=1 to NumberofAccounts DO BEGIN
      WGoto(49,8+I*2);
      Write(Usr,Data[Descriptor[I].Number]:16:2);
      IF I<NumberofAccounts THEN BEGIN
        WGoto(66,8+I*2);
        IF Log[CurrentLog].Total<>0 THEN
          Write(Usr,Data[Descriptor[I].Number]/(Log[CurrentLog].Total-Data[NumberofAccounts])*100:9:2)
        ELSE Write(Usr,'         ');
      END;
    END;
    WGoto(49,10+NumberofAccounts*2);
    Write(Usr,Log[CurrentLog].Total:16:2); *)
  END;


PROCEDURE ReTotal (* (AccountNum : INTEGER;Value : REAL) *) ;

  BEGIN
(*    WITH Log[CurrentLog] DO BEGIN
      Total:=Total-Data[AccountNum];
      Data[AccountNum]:=Value;
      Total:=Total+Data[AccountNum];
      WriteDIR;
    END; *)
    WITH Data DO BEGIN
        Total1 := Bal1+Chg1+ROA1;
        SubT := Cash+Chks;
        Total2 := SubT+PO+Chg2+ManCC+CC;
        Bal2 := Total2-CCFee;
        (* Over *)
        (* Short *)
        (* Bal2 *)
        Total3 := Gas+Oil+Acc+Lab+Snacks+Emiss+Kero+Wrkr+ROA2+Tax;
    END (* WITH *);
    Log[CurrentLog].Total := (* 6/24/96 DGL: Data.Total1; *)
                          Data.Total2;
  END;


PROCEDURE EditEdit;

  VAR
    Place          : INTEGER;
    XPos, YPos     : INTEGER;

  BEGIN
    Message('EDIT MODE: ESC = Exit');
    Place:=1;
    REPEAT
      (* Store value in proper variable *)
      CASE Place OF
          1  :  BEGIN XPos:=Col3; YPos:=3; END;
          2  :  BEGIN XPos:=Col1; YPos:=11; END;
          3  :  BEGIN XPos:=Col1; YPos:=12; END;
          4  :  BEGIN XPos:=Col1; YPos:=13; END;
          5  :  BEGIN XPos:=Col2; YPos:=7; END;
          6  :  BEGIN XPos:=Col2; YPos:=8; END;
          7  :  BEGIN XPos:=Col2; YPos:=11; END;
          8  :  BEGIN XPos:=Col2; YPos:=12; END;
          9  :  BEGIN XPos:=Col2; YPos:=13; END;
          10 :  BEGIN XPos:=Col2; YPos:=14; END;
          11 :  BEGIN XPos:=Col2; YPos:=17; END;
          12 :  BEGIN XPos:=Col2; YPos:=18; END;
          13 :  BEGIN XPos:=Col2; YPos:=19; END;
          14 :  BEGIN XPos:=Col2; YPos:=20; END;
          15 :  BEGIN XPos:=Col3; YPos:=7; END;
          16 :  BEGIN XPos:=Col3; YPos:=8; END;
          17 :  BEGIN XPos:=Col3; YPos:=9; END;
          18 :  BEGIN XPos:=Col3; YPos:=10; END;
          19 :  BEGIN XPos:=Col3; YPos:=11; END;
          20 :  BEGIN XPos:=Col3; YPos:=12; END;
          21 :  BEGIN XPos:=Col3; YPos:=13; END;
          22 :  BEGIN XPos:=Col3; YPos:=14; END;
          23 :  BEGIN XPos:=Col3; YPos:=15; END;
          24 :  BEGIN XPos:=Col3; YPos:=16; END;
      END (* CASE *);
(*      GotoLine(YPos-10); *)
      HiLiteCell(XPos,YPos,8);
      ReadKbd;
      LoLiteCell(XPos,YPos,8);
      CASE Key of
        #72      : IF Place>1 THEN Place:=Place-1 ELSE Place := 24;
        #80      : IF Place<24 THEN Place:=Place+1 ELSE Place := 1;
        '0'..'9','.' : BEGIN
                         Val(EnterCell(XPos,YPos,8,['0'..'9','.']),X,I);
                         IF (Place>1) AND NOT DecPoint THEN X:=X/100;
                         (* Store value in proper variable *)
                         CASE Place OF
                             1  :  Data.Shift := TRUNC(X);
                             2  :  Data.Bal1  := X;
                             3  :  Data.Chg1  := X;
                             4  :  Data.ROA1  := X;
                             5  :  Data.Cash  := X;
                             6  :  Data.Chks  := X;
                             7  :  Data.PO    := X;
                             8  :  Data.Chg2  := X;
                             9  :  Data.ManCC := X;
                             10 :  Data.CC    := X;
                             11 :  Data.CCFee := X;
                             12 :  Data.Bal2  := X;
                             13 :  Data.Over  := X;
                             14 :  Data.Short := X;
                             15 :  Data.Gas   := X;
                             16 :  Data.Oil   := X;
                             17 :  Data.Acc   := X;
                             18 :  Data.Lab   := X;
                             19 :  Data.Snacks:= X;
                             20 :  Data.Emiss := X;
                             21 :  Data.Kero  := X;
                             22 :  Data.Wrkr  := X;
                             23 :  Data.ROA2  := X;
                             24 :  Data.Tax   := X;
                         END (* CASE *);
                         ReTotal;
                         WriteDIR;
                         DIRChanged:=TRUE;
                       END;
      END;
      IF Key=#13 THEN Place:=Place+1;
    UNTIL (Key=#27) OR (Place>24);
    Key:=#0;
    Message('E = Edit  P = Print  ESC = Exit');
  END;


PROCEDURE LoadDIR;

  BEGIN
    WITH Log[CurrentLog] DO BEGIN
      IF DataPtr>0 THEN BEGIN
        ReSet(DataFile);
        Seek(DataFile,DataPtr-1);
        Read(DataFile,Data);
        Close(DataFile);
        Total := Data.Total1; (* **** *)
(*        Total:=0;
        FOR I:=1 to NumberofAccounts DO BEGIN
          Total:=Total+Data[I];
        END; *)
      END ELSE BEGIN
        FillChar(Data,SizeOf(Data),0);
        WriteDIR;
        EditEdit;
      END;
    END;
  END;


PROCEDURE SaveLog(ForLog : INTEGER); FORWARD;


PROCEDURE SaveDIR;

  BEGIN
    WITH Log[CurrentLog] DO BEGIN
      ReSet(DataFile);
      IF DataPtr<0 THEN DataPtr:=-DataPtr;
      IF DataPtr=0 THEN DataPtr:=FileSize(DataFile)+1;
      Seek(DataFile,DataPtr-1);
      Write(DataFile,Data);
      Close(DataFile);
      SaveLog(CurrentLog);
    END;
  END;


PROCEDURE Edit;

  BEGIN
    DIRChanged:=FALSE;
    ChangeWindow(DRWindow);
    Message('E = Edit  P = Print  ESC = Exit');
    LoadDIR;
    WriteDIR;
    REPEAT
      ReadKbd;
      CASE Key of
        'e'        : EditEdit;
        'p'        : PrintWind;
      END;
    UNTIL Key=#27;
    IF DIRChanged THEN SaveDIR;
  END;
