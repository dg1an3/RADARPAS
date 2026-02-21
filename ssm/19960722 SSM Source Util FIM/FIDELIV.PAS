{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     Delivery routines                                                        }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

TYPE
  DeliveryRec     = RECORD
    TicketNum     :   STRING[8];
    GalDeliv      :   ARRAY[fuel] of REAL;
    InchBefore    :   ARRAY[Regular..Premium] of BYTE;
    InchAfter     :   ARRAY[Regular..Premium] of BYTE;
                    END;

VAR
  Delivery        : DeliveryRec;
  DeliveryChanged : BOOLEAN;
  DeliveryFile    : FILE of DeliveryRec;
  LastDelivery    : INTEGER;
  AuxDelivery     : DeliveryRec;


FUNCTION Stick(Inches : BYTE;ForFuel : fuel) : REAL;

  BEGIN
    IF Inches in [0..96] THEN J:=Chart[ForFuel,Inches] ELSE J:=-1;
    Stick:=J;
  END;


PROCEDURE WriteDeliveryRow(ForFuel : fuel);

  VAR YPos : INTEGER;

  BEGIN
    CASE FuelCount of
        Regular  : YPos:=DelivStart+2;
        Premium  : YPos:=DelivStart;
        UnLeaded : YPos:=DelivStart+4;
    END;
    WITH Delivery DO BEGIN
      WGoto(Delivered,YPos);
      Write(Usr,GalDeliv[ForFuel]:12:0);
      WGoto(Deliv1Inch,YPos);
      Write(Usr,InchBefore[ForFuel]:6);
      WGoto(Deliv2Inch,YPos);
      Write(Usr,InchAfter[ForFuel]:6);
      WGoto(Deliv1Gall,YPos);
      IF Stick(InchBefore[ForFuel],ForFuel)>-1 THEN Write(Usr,J:9) ELSE Write(Usr,'ERROR':9);
      WGoto(Deliv2Gall,YPos);
      IF Stick(InchAfter[ForFuel],ForFuel)>-1 THEN Write(Usr,J:9) ELSE Write(Usr,'ERROR':9);
      WGoto(DelivDiff,YPos);
      Write(Usr,(Stick(InchAfter[ForFuel],ForFuel)-Stick(InchBefore[ForFuel],ForFuel))-GalDeliv[ForFuel]:10:0);
      WGoto(Delivered,DelivStart+6);
      Write(Usr,(GalDeliv[Regular]+GalDeliv[UnLeaded]+GalDeliv[Premium]):12:0);
    END;
  END;


PROCEDURE WriteDelivery;

  BEGIN
    ChangeWindow(DeliveryWindow);
    WGoto(DelivTicketX,DelivTicketY);
    Write(Usr,Delivery.TicketNum:12);
    WGoto(DelivDateX,DelivDateY);
    Write(Usr,ShortDate(Log[CurrentLog].Date));
    WGoto(DelivTimeX,DelivTimeY);
    Write(Usr,ShortTime(Log[CurrentLog].Date));
    FOR fuelcount:=Regular to Premium DO WriteDeliveryRow(fuelcount);
  END;


PROCEDURE LoadDelivery;

  BEGIN
    CheckFile('DELIV.DAT');
    ReSet(DeliveryFile);
    IF Log[CurrentLog].Pointer[Deliveryt]>0 THEN BEGIN
      Seek(DeliveryFile,Log[CurrentLog].Pointer[Deliveryt]-1);
      Read(DeliveryFile,Delivery);
    END
    ELSE FillChar(Delivery,SizeOf(Delivery),0);
    Close(DeliveryFile);
  END;


PROCEDURE SaveDelivery;

  BEGIN
    CheckFile('DELIV.DAT');
    ReSet(DeliveryFile);
    IF Log[CurrentLog].Pointer[Deliveryt]=0 THEN Log[CurrentLog].Pointer[Deliveryt]:=FileSize(DeliveryFile)+1;
    IF Log[CurrentLog].Pointer[Deliveryt]<0 THEN Log[CurrentLog].Pointer[Deliveryt]:=-Log[CurrentLog].Pointer[Deliveryt];
    Seek(DeliveryFile,Log[CurrentLog].Pointer[Deliveryt]-1);
    Write(DeliveryFile,Delivery);
    Close(TRFile);
    SaveLog(CurrentLog);
  END;


PROCEDURE EditDelivery;

  VAR XPos,YPos,Size : INTEGER;

  BEGIN
    WriteEditLine(Deliveryt);
    REPEAT
      CASE FuelCount of
        Regular  : YPos:=DelivStart+2;
        Premium  : YPos:=DelivStart;
        UnLeaded : YPos:=DelivStart+4;
      END;
      CASE K of
        1 : BEGIN
              XPos:=DelivTicketX;
              YPos:=DelivTicketY;
              Size:=12;
            END;
        2 : BEGIN
              XPos:=Delivered;
              Size:=12;
            END;
        3 : BEGIN
              XPos:=Deliv1Inch;
              Size:=6;
            END;
        4 : BEGIN
              XPos:=Deliv2Inch;
              Size:=6;
            END;
      END;
      HiLiteCell(XPos,YPos,Size);
      ReadKbd;
      LoLiteCell(XPos,YPos,Size);
      CASE Key of
        #72      : IF fuelcount>Regular THEN fuelcount:=Pred(fuelcount)
                     ELSE fuelcount:=Premium;
        #80      : IF fuelcount<Premium THEN fuelcount:=Succ(fuelcount)
                     ELSE fuelcount:=Regular;
        #75      : IF K>1 THEN K:=K-1;
        #77      : IF K<4 THEN K:=K+1;
        'r'      : IF Log[CurrentLog].Pointer[Deliveryt]<0 THEN BEGIN
                     Log[CurrentLog].Pointer[Deliveryt]:=-Log[CurrentLog].Pointer[Deliveryt];
                     LoadDelivery;
                     WriteDelivery;
                     SaveLog(CurrentLog);
                     WriteEditLine(Deliveryt);
                     K:=1; fuelcount:=Regular;
                   END;
        'd'      : IF Log[CurrentLog].Pointer[Deliveryt]>0 THEN BEGIN
                     Log[CurrentLog].Pointer[Deliveryt]:=-Log[CurrentLog].Pointer[Deliveryt];
                     SaveLog(CurrentLog);
                     Key:=#27;
                     Exit;
                   END;
        '0'..'9' : BEGIN
                     DeliveryChanged:=TRUE;
                     Val(EnterCell(XPos,YPos,Size,['0'..'9']),J,I);
                     IF Line<>'' THEN BEGIN
                       CASE K of
                         1 : Delivery.TicketNum:=Line;
                         2 : Delivery.GalDeliv[fuelcount]:=J;
                         3 : Delivery.InchBefore[fuelcount]:=J;
                         4 : Delivery.InchAfter[fuelcount]:=J;
                       END;
                       WriteDeliveryRow(fuelcount);
                     END;
                   END;
      END;
      IF Key=#13 THEN
        IF K=1 THEN K:=2 ELSE BEGIN
          IF fuelcount<Premium THEN fuelcount:=Succ(fuelcount)
            ELSE fuelcount:=Regular;
          IF fuelcount=Premium THEN K:=K+1;
          IF K=5 THEN BEGIN
            Key:=#27;
            K:=1;
          END;
        END;
    UNTIL Key=#27;
    Key:=#0;
    WriteKeyLine;
  END;


PROCEDURE EnterDelivery;

  BEGIN
    OneMoment;
    IF Log[CurrentLog].Pointer[Deliveryt]<=0 THEN IF NOT ChangeStatus THEN Exit;
    DeliveryChanged:=FALSE;
    LoadDelivery;
    WriteDelivery;
    fuelcount:=Premium;K:=1;
    IF Log[CurrentLog].Pointer[Deliveryt]<=0 THEN EditDelivery;
    WriteKeyLine;
    REPEAT
      ReadKbd;
      CASE Key of
        'e' : IF ChangeStatus THEN BEGIN
                EditDelivery;
                WriteKeyLine;
              END;
        'p' : BEGIN
                PrintWind;
                WriteKeyLine;
              END;
      END;
    UNTIL Key=#27;
    IF DeliveryChanged THEN SaveDelivery;
    DrawLog;
  END;