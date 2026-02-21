PROGRAM IncomeAccount;

{$I-}

{$V-}

CONST
  ModuleName       = 'Income Account';

  Abbreviation     = 'IA';

  DrivetoUse       = 'C';
  DataDrive        = 'C';


TYPE
  DateRec          = RECORD
    Month          :   BYTE;
    Day            :   BYTE;
    Year           :   INTEGER;
    Hour           :   BYTE;
    Minute         :   BYTE;
                     END;

  String10         = STRING[10];

  LineType         = STRING[80];


VAR  {Passed variables}
  TodaysDate       : DateRec;
  DateEntered      : BOOLEAN;
  ChangeStatus     : BOOLEAN;
  PassWord         : STRING[16];

  MenuProg         : FILE;
  Changed          : BOOLEAN;
  CaseErr          : INTEGER;
  ErrorNumber      : INTEGER;
  Line             : LineType;
  StrA,StrB        : String10;
  X,Y,Z            : REAL;
  I,J,K            : INTEGER;
  Right            : BOOLEAN;
  Match            : BOOLEAN;
  ErrorFlag        : BOOLEAN;


{$I UTILITY.PAS}

{$I CUSTOM.IA}

{$I EDIT.IA}

{$I SUMMARY.IA}

{$I MENU.IA}


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
        ReWrite(DataFile);
      END;
      ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
      IF IOError=$01 THEN Quit;
    END;
    SetAttribute('LOG.DAT',$00);
    SetAttribute('DATA.DAT',$00);
  END;


PROCEDURE HideFiles;

  BEGIN
    SetAttribute('LOG.DAT',$03);
    SetAttribute('DATA.DAT',$03);
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
  UsrOutPtr:=Ofs(ScreenOut);
  Assign(LogFile,'LOG.DAT');
  Assign(DataFile,'DATA.DAT');
  ChangeDirectory(TodaysDate.Year);
  LoadLog;
  MakeLog(TodaysDate);
  Window(1,1,80,25); ClrScr; InfoLine;
  MainMenu;
  Quit;
END.