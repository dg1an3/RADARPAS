PROGRAM Fuel_Inventory_Manager;

{$I-}

{$V-}

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

  DrivetoUse   : CHAR = 'C';
  DataDrive    : CHAR = 'C';

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


{$I UTILITY.PAS}

{$I CUSTOM.FIM}

{$I MENU.FIM}

{$I TR.FIM}

{$I DELIV.FIM}

{$I MFI.FIM}

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
    OldDir:=Chr(64+DefaultDrive)+':\';
    ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
    IF IOError=$01 THEN BEGIN
      ErrorMsg('Please put FIM Data disk in drive '+DrivetoUse);
      IF Key='+' THEN BEGIN
        MkDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
        ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
        ReWrite(LogFile);
        ReWrite(TRFile);
        ReWrite(DeliveryFile);
        ReWrite(DLMFIFile);
        ReWrite(PriceFile);
        ReWrite(MMPFile);
      END;
      ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
      IF IOError=$01 THEN Quit;
    END;
    SetAttribute('LOG.DAT',$00);
    SetAttribute('TR.DAT',$00);
    SetAttribute('DELIV.DAT',$00);
    SetAttribute('MFI.DAT',$00);
    SetAttribute('PRICE.DAT',$00);
    SetAttribute('MMP.DAT',$00);
  END;


PROCEDURE AssignFiles;

  BEGIN
    Line:='Be sure the program disk is in drive B';CaseErr:=$0101;
    Assign(LogFile,'LOG.DAT');
    Assign(TRFile,'TR.DAT');
    Assign(DeliveryFile,'DELIV.DAT');
    Assign(DLMFIFile,'MFI.DAT');
    Assign(PriceFile,'PRICE.DAT');
    Assign(MMPFile,'MMP.DAT');
  END;


PROCEDURE HideFiles;

  BEGIN
    SetAttribute('LOG.DAT',$03);
    SetAttribute('TR.DAT',$03);
    SetAttribute('DELIV.DAT',$03);
    SetAttribute('MFI.DAT',$03);
    SetAttribute('PRICE.DAT',$03);
    SetAttribute('MMP.DAT',$03);
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
  TextColor(NormColor);
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