MODULE ServiceStationManager;

FROM ScreenDisplay IMPORT
  DisplayFile, DisplayFrame, OpenDisplayFile, CloseDisplayFile,
  ReadDisplayFrame, ShowDisplayFrame, Display, CloseDisplayFrame;
FROM ScreenInput IMPORT
  FrameSequence;
FROM UserOps IMPORT
  DoPrompting;
  
   
VAR
  CurrDisplayFile : DisplayFile;
  PromptFrame     : DisplayFrame;

TYPE
  PTRRecord = RECORD
    ForDate :   Date;
    Shift   :   CARDINAL;
    Pump    :   ARRAY [ 1..10 ] OF LONGINT;
  END; (* PTRRecord *)
    
PROCEDURE PumpTotalizerReadings;
BEGIN
  OpenDisplayFile(CurrDisplayFile,'PTR.DSP');
  CloseDisplayFile(CurrDisplayFile,'PTR.DSP');
END PumpTotalizerReadings;

TYPE
  DeliveryRec   = RECORD
    ForDate      :   Date;
    TicketNumber :   ARRAY [ 0..10 ] OF CHAR;
    Premium, 
    Unleaded,
    Regular      :   RECORD
      Gallons    :     LONGINT;
      InchBefore :     CARDINAL;
      InchAfter  :     CARDINAL;
    END; (* RECORD *)
  END; (* DeliveryRec *)
  
PROCEDURE Delivery;
BEGIN
END Delivery;

TYPE
  FuelPaymentRec = RECORD
    ForDate      :   Date;
    CreditCard   :   LONGINT;
  END; (* FuelPaymentRec *)
  
  PriceRec       = RECORD
    FullPremium,
    FullRegular,
    FullUnleaded,
    SelfPremium,
    SelfRegular,
    SelfUnleaded :   RECORD
      Estab,
      Disc,
      Fed,
      State      :     LONGINT;
    END; (* RECORD *)
    CardFee      :   LONGINT;
  END; (* RECORD *)
  
PROCEDURE FuelPaymentReport;
BEGIN
END FuelPaymentReport;

PROCEDURE DailyIncomeReport;
BEGIN
END DailyIncomeReport;

PROCEDURE AccountsReceivable;
BEGIN
END AccountsReceivable;

BEGIN
  OpenDisplayFile(CurrDisplayFile,'ACC102.DSP');
  FrameSequence(1);
  CloseDisplayFile(CurrDisplayFile);
END ServiceStationManager.
