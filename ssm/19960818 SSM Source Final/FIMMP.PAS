{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     MMP Report routines                                                      }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

TYPE
  PriceTblRec  = RECORD
    Estab      :   ARRAY[1..6] of REAL;
    Disc       :   ARRAY[1..6] of REAL;
    Net        :   ARRAY[1..6] of REAL;
    FedTaxes   :   ARRAY[1..6] of REAL;
    StateTaxes :   ARRAY[1..6] of REAL;
    Total      :   ARRAY[1..6] of REAL;
    CardFee    :   REAL;
                 END;

  MMPRec       = RECORD
    CreditCard :   REAL;
    CheckNum   :   STRING[20];

    SubTotal   :   ARRAY[1..6] of REAL;
    Previous   :   ARRAY[1..6] of REAL;
    WithDrawn  :   ARRAY[1..6] of REAL;
    Amount     :   ARRAY[1..6] of REAL;
    TotalAmount,
    CCFee,
    SubTotalFee,
    Total      :   REAL;
                 END;

  MMPSRec      = RECORD
    CreditCard :   REAL;
    CheckNum   :   STRING[10];
                 END;

  PostRec      = RECORD
    Date       :   DateRec;
    Amount     :   Real;
                 END;

VAR
  Price        : PriceTblRec;
  MMP          : MMPRec;
  PriceChanged : BOOLEAN;
  MMPChanged   : BOOLEAN;
  PriceFile    : FILE of PriceTblRec;
  MMPFile      : FILE of MMPSRec;
  MMPS         : MMPSRec ABSOLUTE MMP;
  LastMMP      : INTEGER;
  AuxMMP       : MMPRec;
    AuxCCNum   : STRING[6];
  AuxMMPS      : MMPSRec ABSOLUTE AuxMMP;
  Post         : PostRec;
  PostFile     : FILE OF PostRec;

PROCEDURE WritePrices(ForFuel : integer);

  VAR Pos : INTEGER;

  BEGIN
    WITH Price DO BEGIN
      CASE ForFuel OF
        1 : Pos:=31;
        2 : Pos:=33;
        3 : Pos:=35;
        4 : Pos:=38;
        5 : Pos:=40;
        6 : Pos:=42;
      END;
      WGoto(MMPEstab,Pos);
      Write(Usr,Estab[ForFuel]*100:MMPEstabW:2);
      WGoto(MMPLess,Pos);
      Write(Usr,Disc[ForFuel]*100:MMPLessW:2);
      WGoto(MMPNet,Pos);
      Write(Usr,Net[ForFuel]*100:MMPNetW:2);
      WGoto(MMPFed,Pos);
      Write(Usr,FedTaxes[ForFuel]*100:MMPFedW:2);
      WGoto(MMPState,Pos);
      Write(Usr,StateTaxes[ForFuel]*100:MMPStateW:2);
      WGoto(MMPTotalGal,Pos);
      Write(Usr,Total[ForFuel]*100:MMPTotalGalW:2);
      WGoto(MMPCCPerX,46);
      Write(Usr,Price.CardFee*100:MMPCCPerW:1);
      WGoto(MMPAmount,Pos);
      Write(Usr,MMP.Amount[ForFuel]:MMPAmountW:2);
      WGoto(MMPGallons,Pos);
      Write(Usr,MMP.Withdrawn[ForFuel]/10:MMPGallonsW:1);
    END;
  END;

PROCEDURE WriteMMP;
  VAR Pos : INTEGER;
  BEGIN
    WITH MMP DO BEGIN
      for I:=1 to 6 do WritePrices(I);
      WGoto(68,4);
      Write(Usr,ShortDate(Log[CurrentLog].Date));
      WGoto(68,5);
      Write(Usr,ShortTime(Log[CurrentLog].Date));
      WGoto(29,10); Write(Usr,TR.Readings[1]:13:0);
      WGoto(47,10); Write(Usr,TR.Readings[2]:13:0);
      WGoto(65,10); Write(Usr,TR.Readings[3]:13:0);
      WGoto(47,11); Write(Usr,TR.Readings[4]:13:0);
      WGoto(29,11); Write(Usr,TR.Readings[5]:13:0);
      WGoto(29,13); Write(Usr,SubTotal[1]:13:0);
      WGoto(47,13); Write(Usr,SubTotal[2]:13:0);
      WGoto(65,13); Write(Usr,SubTotal[3]:13:0);
      WGoto(29,14); Write(Usr,Previous[1]:13:0);
      WGoto(47,14); Write(Usr,Previous[2]:13:0);
      WGoto(65,14); Write(Usr,Previous[3]:13:0);
      WGoto(29,16); Write(Usr,Withdrawn[1]:13:0);
      WGoto(47,16); Write(Usr,Withdrawn[2]:13:0);
      WGoto(65,16); Write(Usr,Withdrawn[3]:13:0);

      WGoto(29,20); Write(Usr,TR.Readings[6]:13:0);
      WGoto(47,20); Write(Usr,TR.Readings[7]:13:0);
      WGoto(65,20); Write(Usr,TR.Readings[8]:13:0);
      WGoto(47,21); Write(Usr,TR.Readings[9]:13:0);
      WGoto(29,21); Write(Usr,TR.Readings[10]:13:0);
      WGoto(29,23); Write(Usr,SubTotal[4]:13:0);
      WGoto(47,23); Write(Usr,SubTotal[5]:13:0);
      WGoto(65,23); Write(Usr,SubTotal[6]:13:0);
      WGoto(29,24); Write(Usr,Previous[4]:13:0);
      WGoto(47,24); Write(Usr,Previous[5]:13:0);
      WGoto(65,24); Write(Usr,Previous[6]:13:0);
      WGoto(29,26); Write(Usr,Withdrawn[4]:13:0);
      WGoto(47,26); Write(Usr,Withdrawn[5]:13:0);
      WGoto(65,26); Write(Usr,Withdrawn[6]:13:0);

      WGoto(68,44); Write(Usr,TotalAmount:10:2);
      WGoto(50,46); Write(Usr,CreditCard:10:2);
      WGoto(68,46); Write(Usr,CCFee:10:2);
      WGoto(68,48); Write(Usr,SubTotalFee:10:2);
      WGoto(68,50); Write(Usr,CreditCard:10:2);
      WGoto(68,52); Write(Usr,Total:10:2);
      WGoto(3,55);  Write(Usr,CheckNum:20);
      WGoto(30,55); Write(Usr,Total:10:2);
    END;
  END;


PROCEDURE CalcMMP;

  BEGIN
    WITH MMP DO BEGIN
      SubTotal[1]:=TR.Readings[1]+TR.Readings[5];
      SubTotal[2]:=TR.Readings[2]+TR.Readings[4];
      SubTotal[3]:=TR.Readings[3];
      SubTotal[4]:=TR.Readings[6]+TR.Readings[10];
      SubTotal[5]:=TR.Readings[7]+TR.Readings[9];
      SubTotal[6]:=TR.Readings[8];
      Previous[1]:=AuxTR.Readings[1]+AuxTR.Readings[5];
      Previous[2]:=AuxTR.Readings[2]+AuxTR.Readings[4];
      Previous[3]:=AuxTR.Readings[3];
      Previous[4]:=AuxTR.Readings[6]+AuxTR.Readings[10];
      Previous[5]:=AuxTR.Readings[7]+AuxTR.Readings[9];
      Previous[6]:=AuxTR.Readings[8];
      TotalAmount:=0;
      FOR I:=1 TO 6 DO BEGIN
        WithDrawn[I]:=SubTotal[I]-Previous[I];
        Amount[I]:=WithDrawn[I]*Price.Total[I]/10;
        TotalAmount:=TotalAmount+Amount[I];
      END; (* FOR *)
      CCFee:=CreditCard*Price.CardFee;
      SubTotalFee:=TotalAmount+CCFee;
      Total:=SubTotalFee-CreditCard;
    END;
  END;


PROCEDURE LoadPrice;

  BEGIN
    ReSet(PriceFile);
    IF Log[CurrentLog].Pointer[Pricet]>0 THEN BEGIN
      Seek(PriceFile,Log[CurrentLog].Pointer[Pricet]-1);
      Read(PriceFile,Price);
    END ELSE FillChar(Price,SizeOf(Price),0);
    Close(PriceFile);
  END;


PROCEDURE SavePrice;

  BEGIN
    ReSet(PriceFile);
    IF Log[CurrentLog].Pointer[Pricet]<0 THEN
      Log[CurrentLog].Pointer[Pricet]:=-Log[CurrentLog].Pointer[Pricet];
    IF Log[CurrentLog].Pointer[Pricet]=0 THEN
      Log[CurrentLog].Pointer[Pricet]:=FileSize(PriceFile)+1;
    Seek(PriceFile,Log[CurrentLog].Pointer[Pricet]-1);
    Write(PriceFile,Price);
    SaveLog(CurrentLog);
    Close(PriceFile);
  END;




PROCEDURE LoadMMP;

  VAR I : INTEGER;

  BEGIN
    ReSet(MMPFile);
    I:=CurrentLog-1;
    WHILE (Log[I].Pointer[MMPt]<=0) AND (I>=0) DO I:=I-1;
    LoadTR(I);
    IF Log[CurrentLog].Pointer[TRt]<=0 THEN EnterTR;
    IF Log[CurrentLog].Pointer[MMPt]>0 THEN BEGIN
      Seek(MMPFile,Log[CurrentLog].Pointer[MMPt]-1);
      Read(MMPFile,MMPS);
    END
    ELSE FillChar(MMP,SizeOf(MMP),0);
    Close(MMPFile);
    ReSet(PriceFile);
    I:=CurrentLog-1;
    WHILE (Log[I].Pointer[Pricet]<=0) AND (I>=0) DO I:=I-1;
    IF I>=0 THEN BEGIN
      Seek(PriceFile,Log[I].Pointer[Pricet]-1);
      Read(PriceFile,Price);
    END
    ELSE BEGIN
      IF Log[CurrentLog].Pointer[Pricet]>0 THEN BEGIN
        Seek(PriceFile,Log[CurrentLog].Pointer[Pricet]-1);
        Read(PriceFile,Price);
      END
      ELSE BEGIN
        FillChar(Price,SizeOf(Price),0);
      END;
    END;
    Close(PriceFile);
    CalcMMP;
  END;


PROCEDURE SaveMMP;

  BEGIN
    ReSet(MMPFile);
    IF Log[CurrentLog].Pointer[MMPt]=0 THEN Log[CurrentLog].Pointer[MMPt]:=FileSize(MMPFile)+1;
    IF Log[CurrentLog].Pointer[MMPt]<0 THEN Log[CurrentLog].Pointer[MMPt]:=-Log[CurrentLog].Pointer[MMPt];
    Seek(MMPFile,Log[CurrentLog].Pointer[MMPt]-1);
    Write(MMPFile,MMPS);
    Close(TRFile);
    SaveLog(CurrentLog);
  END;


PROCEDURE EditMMP;

  VAR XPos,YPos,Size : INTEGER;
  BEGIN
    MMPChanged:=FALSE;
    GotoLine(34);
    WriteEditLine(MMPt);
    REPEAT
      CASE K of
        1     : BEGIN
                  XPos:=68; YPos:=50; Size:=10;
                END;
        2     : BEGIN
                  XPos:=3; YPos:=55; Size:=20;
                END;
      END;
      HiLiteCell(XPos,YPos-33,Size-1);
      ReadKbd;
      LoLiteCell(XPos,YPos-33,Size-1);
      CASE Key of
        #75,#72  : IF K>1 THEN K:=K-1;
        #77,#80  : IF K<2 THEN K:=K+1;
        'r'      : IF Log[CurrentLog].Pointer[MMPt]<0 THEN BEGIN
                     Log[CurrentLog].Pointer[MMPt]:=-Log[CurrentLog].Pointer[MMPt];
                     LoadMMP;
                     WriteMMP;
                     SaveLog(CurrentLog);
                     WriteEditLine(MMPt);
                     K:=1;
                   END;
        'd'      : IF Log[CurrentLog].Pointer[MMPt]>0 THEN BEGIN
                     Log[CurrentLog].Pointer[MMPt]:=-Log[CurrentLog].Pointer[MMPt];
                     SaveLog(CurrentLog);
                     Key:=#27;
                     Exit;
                   END;
        '0'..'9','.',' ' : BEGIN
                     MMPChanged:=TRUE;
                     CASE K of
                       1 : BEGIN
                             Val(EnterCell(XPos,YPos-33,Size-1,
                                 ['0'..'9','.',' ']),X,I);
                             MMP.CreditCard:=X;
                             CalcMMP; WriteMMP;
                           END;
                       2 : BEGIN
                             MMP.CheckNum:=
                               EnterCell(XPos,YPos-33,Size-1,['0'..'9','A'..'Z',' ']);
                           END;
                     END;
                   END;
      END;
      IF Key=#13 THEN IF K<2 THEN K:=K+1 ELSE Key:=#27;
    UNTIL Key=#27;
    Key:=#0;
    WriteKeyLine;
  END;


PROCEDURE EnterMMP;
  BEGIN
    OneMoment;
    IF Log[CurrentLog].Pointer[MMPt]<=0 THEN IF NOT ChangeStatus THEN Exit;
    MMPChanged:=FALSE;
    LoadMMP;
    ChangeWindow(MMPWindow);
    WriteMMP;
    K:=1;
    IF Log[CurrentLog].Pointer[MMPt]<=0 THEN EditMMP;
    WriteKeyLine;
    REPEAT
      ReadKbd;
      CASE Key of
        #72 : GotoLine(TopLine-1);
        #80 : GotoLine(TopLine+1);
        #71 : GotoLine(1);
        #79 : GotoLine(CurWind^.YSize);
        'e' : IF ChangeStatus THEN BEGIN
                EditMMP;
                WriteKeyLine;
              END;
        'p' : BEGIN
                PrintWind;
                WriteKeyLine;
              END;
      END;
    UNTIL Key=#27;
    IF MMPChanged THEN SaveMMP;
    DrawLog;
  END;


(*****************************************************************************)
(*    MMP Summary                                                            *)
(*****************************************************************************)

{TYPE
  SummaryRec       = RECORD
    Amount         :   ARRAY[Regular..Premium] of REAL;
    CC             :   REAL;
    CCFee          :   REAL;
    Cash           :   REAL;
    Total          :   REAL;
                     END;

VAR
  MonthSummary     : SummaryRec;
  YearSummary      : SummaryRec;


PROCEDURE ViewMMPSummary;

  VAR Place        : INTEGER;

  BEGIN
    OneMoment;
    IF NOT ChangeStatus THEN WriteKeyLine
    ELSE BEGIN
      ChangeStatus:=FALSE;
      WriteKeyLine;
      ChangeStatus:=TRUE;
    END;
    WITH MonthSummary DO BEGIN
      FOR fuelcount:=Regular to Premium DO Amount[fuelcount]:=0;
      CC:=0;
      CCFee:=0;
      Cash:=0;
      Total:=0;
    END;
    WITH YearSummary DO BEGIN
      FOR fuelcount:=Regular to Premium DO Amount[fuelcount]:=0;
      CC:=0;
      CCFee:=0;
      Cash:=0;
      Total:=0;
    END;
    Place:=CurrentLog;
    REPEAT
      LoadMMP;
      IF Log[CurrentLog].Date.Month=Log[Place].Date.Month THEN
      WITH MonthSummary DO BEGIN
        FOR fuelcount:=Regular to Premium DO BEGIN
          Amount[fuelcount]:=Amount[fuelcount]+MMP.Amount[fuelcount];
          Total:=Total+Amount[fuelcount];
        END;
        CC:=CC+MMP.CreditCard;
        CCFee:=CCFee+MMP.CCFee;
        Cash:=Total-CC;
      END;
      WITH YearSummary DO BEGIN
        FOR fuelcount:=Regular to Premium DO BEGIN
          Amount[fuelcount]:=Amount[fuelcount]+MMP.Amount[fuelcount];
          Total:=Total+Amount[fuelcount];
        END;
        CC:=CC+MMP.CreditCard;
        CCFee:=CCFee+MMP.CCFee;
        Cash:=Total-CC;
      END;
      CurrentLog:=CurrentLog-1;
    UNTIL CurrentLog<0;
    CurrentLog:=Place;
    ChangeWindow(MMPSumWindow);
    WGoto(MMPSumDateX,MMPSumDateY);
    Write(Usr,ShortDate(Log[CurrentLog].Date));
    WGoto(MMPSumTimeX,MMPSumDateY);
    Write(Usr,ShortTime(Log[CurrentLog].Date));
    FOR fuelcount:=Regular to Premium DO BEGIN
      WGoto(MMPSumCol+Ord(fuelcount)*MMPSumSize,MMPSumLine);
      Write(Usr,MonthSummary.Amount[fuelcount]:MMPSumW:2);
      WGoto(MMPSumCol+Ord(fuelcount)*MMPSumSize,MMPSumLine+2);
      Write(Usr,YearSummary.Amount[fuelcount]:MMPSumW:2);
    END;
    WGoto(MMPSumCol+3*MMPSumSize,MMPSumLine+2);
    Write(Usr,YearSummary.CC:MMPSumW:2);
    WGoto(MMPSumCol+4*MMPSumSize,MMPSumLine+2);
    Write(Usr,YearSummary.Cash:MMPSumW:2);
    WGoto(MMPSumCol+5*MMPSumSize,MMPSumLine+2);
    Write(Usr,YearSummary.CCFee:MMPSumW:2);
    WGoto(MMPSumCol+6*MMPSumSize,MMPSumLine+2);
    Write(Usr,YearSummary.Total:MMPSumW:2);
    WGoto(MMPSumCol+3*MMPSumSize,MMPSumLine);
    Write(Usr,MonthSummary.CC:MMPSumW:2);
    WGoto(MMPSumCol+4*MMPSumSize,MMPSumLine);
    Write(Usr,MonthSummary.Cash:MMPSumW:2);
    WGoto(MMPSumCol+5*MMPSumSize,MMPSumLine);
    Write(Usr,MonthSummary.CCFee:MMPSumW:2);
    WGoto(MMPSumCol+6*MMPSumSize,MMPSumLine);
    Write(Usr,MonthSummary.Total:MMPSumW+1:2);
    REPEAT
      ReadKbd;
      IF Key='p' THEN PrintWind;
    UNTIL Key=#27;
    Key:=#0;
    DrawLog;
  END;}


(*****************************************************************************)
(*    Price Change                                                           *)
(*****************************************************************************)

PROCEDURE EditPrice;

  VAR XPos,YPos,Size : INTEGER;
      fuelcount  : INTEGER;
  BEGIN
    OneMoment;
    IF Log[CurrentLog].Pointer[MMPt]<=0 THEN BEGIN
      IF NOT ChangeStatus THEN Exit;
    END;
    ChangeWindow(MMPWindow); GotoLine(26);
    LoadPrice;
    FillChar(MMP,SizeOf(MMP),0);
    for I:=1 to 6 do WritePrices(I);
    PriceChanged:=FALSE;
    K:=1; fuelcount:=1;
    WriteEditLine(Pricet);
    REPEAT
      CASE fuelcount of
        1 : YPos:=31;
        2 : YPos:=33;
        3 : YPos:=35;
        4 : YPos:=38;
        5 : YPos:=40;
        6 : YPos:=42;
      END;
      CASE K of
        1 : BEGIN
              XPos:=MMPEstab;
              Size:=MMPEstabW;
            END;
        2 : BEGIN
              XPos:=MMPLess;
              Size:=MMPLessW;
            END;
        3 : BEGIN
              XPos:=MMPFed;
              Size:=MMPFedW;
            END;
        4 : BEGIN
              XPos:=MMPState;
              Size:=MMPStateW;
            END;
        5 : BEGIN
              XPos:=61;
              YPos:=46;
              Size:=4;
            END;
      END;
      HiLiteCell(XPos,YPos-25,Size-1);
      ReadKbd;
      LoLiteCell(XPos,YPos-25,Size-1);
      CASE Key of
        #72      : IF fuelcount>1 THEN
                     fuelcount:=Pred(fuelcount);
        #80      : IF fuelcount<6 THEN
                     fuelcount:=Succ(fuelcount);
        #75      : IF K>1 THEN K:=K-1;
        #77      : IF K<5 THEN K:=K+1;
        'r'      : IF Log[CurrentLog].Pointer[Pricet]<0 THEN BEGIN
                     Log[CurrentLog].Pointer[Pricet]:=-Log[CurrentLog].Pointer[Pricet];
                     LoadPrice;
                     WriteMMP;
                     SaveLog(CurrentLog);
                     WriteEditLine(Pricet);
                   END;
        'd'      : IF Log[CurrentLog].Pointer[Pricet]>0 THEN BEGIN
                     Log[CurrentLog].Pointer[Pricet]:=-Log[CurrentLog].Pointer[Pricet];
                     SaveLog(CurrentLog);
                     Key:=#27;
                   END;
        '0'..'9','.' : BEGIN
                     PriceChanged:=TRUE;
                     Val(EnterCell(XPos,YPos-25,Size-1,['0'..'9','.']),X,I);
                     IF Line<>'' THEN BEGIN
                       WITH Price DO BEGIN
                         CASE K of
                           1 : Estab[fuelcount]:=X/100;
                           2 : Disc[fuelcount]:=X/100;
                           3 : FedTaxes[fuelcount]:=X/100;
                           4 : StateTaxes[fuelcount]:=X/100;
                           5 : Price.CardFee:=X/100;
                         END;
                         Net[fuelcount]:=Estab[fuelcount]
                           +Disc[fuelcount];
                         Total[fuelcount]:=Net[fuelcount]
                           +FedTaxes[fuelcount]
                           +StateTaxes[fuelcount];
                       END;
                     END;
                     WritePrices(fuelcount);
                   END;
      END;
      IF Key=#13 THEN
        IF K=5 THEN Key:=#27
        ELSE BEGIN
          K:=K+1;
          IF K=5 THEN BEGIN
            fuelcount:=Succ(fuelcount);
            IF fuelcount<=6 THEN K:=1 ELSE K:=5;
          END;
        END;
    UNTIL Key=#27;
    IF PriceChanged THEN SavePrice;
    Key:=#0;
    DrawLog;
  END;