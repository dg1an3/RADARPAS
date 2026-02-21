PROGRAM Fuel_Inventory_Manager;

{$I-}

{$V-}

{$U-}
TYPE
  DateRec      = RECORD
    Month      :   BYTE;
    Day        :   BYTE;
    Year       :   INTEGER;
    Hour       :   BYTE;
    Minute     :   BYTE;
                 END;


VAR  {Passed variables}
  TodaysDate   : DateRec;
  DateEntered  : BOOLEAN;
  ChangeStatus : BOOLEAN;
  PassWord     : STRING[16];


TYPE
  fuel         = (Regular,UnLeaded,Premium,All);

  LineType     = STRING[80];

  String10     = STRING[10];


CONST
  ModuleName   = 'Fuel Inventory Manager';

  Abbreviation = 'FIM';

  DrivetoUse   : CHAR = 'D';

  FuelName     : ARRAY[Regular..Premium] of ARRAY[1..9] of CHAR =
    ('Regular  ','Unleaded ','Premium  ');


VAR
  MenuProg     : FILE;
  Changed      : BOOLEAN;
  CaseErr      : INTEGER;
  ErrorNumber  : INTEGER;
  fuelcount    : fuel;
  Line         : LineType;
  StrA,StrB    : String10;
  X,Y,Z        : REAL;
  I,J,K        : INTEGER;
  Right        : BOOLEAN;
  ErrorFlag    : BOOLEAN;


{$I UTILITY2.PAS}

{$I CUSTOM.FIM}

{$I MENU.FIM}

{$I TR.FIM}

{$I MMP.FIM}

{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     MAIN LOOP                                                                }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

VAR
  OldDir           : STRING[80];

PROCEDURE ChangeDirectory(ToYear : INTEGER);

  BEGIN
    Str(ToYear,StrA);
    GetDir(DefaultDrive,OldDir);
    ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
    IF IOResult<>$00 THEN BEGIN
      ErrorMsg('No data directory.  Press <+> to create directory');
      IF Key='+' THEN BEGIN
        Message('CREATING NEW ACCOUNT FILE');
        MkDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
        ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
        ReWrite(LogFile);
        ReWrite(TRFile);
{        ReWrite(DeliveryFile);
        ReWrite(DLMFIFile);}
        ReWrite(PriceFile);
        ReWrite(MMPFile);
      END;
      ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
      IF IOResult<>$00 THEN Quit;
    END;
    SetAttribute('LOG.DAT',$00);
    SetAttribute('TR.DAT',$00);
{    SetAttribute('DELIV.DAT',$00);
    SetAttribute('MFI.DAT',$00);}
    SetAttribute('PRICE.DAT',$00);
    SetAttribute('MMP.DAT',$00);
  END;


PROCEDURE AssignFiles;

  BEGIN
    Line:='Be sure the program disk is in drive B';CaseErr:=$0101;
    Assign(LogFile,'LOG.DAT');
    Assign(TRFile,'TR.DAT');
{    Assign(DeliveryFile,'DELIV.DAT');
    Assign(DLMFIFile,'MFI.DAT');}
    Assign(PriceFile,'PRICE.DAT');
    Assign(MMPFile,'MMP.DAT');
  END;


PROCEDURE HideFiles;

  BEGIN
    SetAttribute('LOG.DAT',$00);
    SetAttribute('TR.DAT',$00);
{    SetAttribute('DELIV.DAT',$00);
    SetAttribute('MFI.DAT',$00);}
    SetAttribute('PRICE.DAT',$00);
    SetAttribute('MMP.DAT',$00);
  END;


PROCEDURE Quit;

  BEGIN
    CloseLog;
    HideFiles;
    ChDir(OldDir);
    Assign(MenuProg,'MENU.COM');
    Execute(MenuProg);
  END;


BEGIN
  TextColor(NormVid);
  TextBackground(NormBack);
  OneMoment;
  UsrOutPtr:=Ofs(ScreenOut);
  AssignFiles;
  ChangeDirectory(TodaysDate.Year);
  LoadLog;
  MakeLog(TodaysDate);
  Window(1,1,80,25); ClrScr; InfoLine;
  MainMenu;
  Quit;
END.