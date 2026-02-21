program Accounts_Payable;

(*$I-*)

CONST
  ModuleName       = 'Accounts Payable';

  Abbreviation     = 'AP';

  DrivetoUse       = 'B';


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


{$I UTILITY2.PAS}

{$I CUSTOM.AP}

type
  string12       = string[12];

  AccountRec     = record
    Number       :   integer;
    Name         :   string[40];
    Address      :   string[40];
    City         :   string[30];
    Phone        :   string[15];
    Balance      :   real;
    GT30         :   real;
    GT60         :   real;
  end;

  EntryRec       = record
    Date         :   DateRec;
    Description  :   string[40];
    Amount       :   real;
    Balance      :   real;
  end;

const
  FirstEntry = 3; (* First valid entry after Account Header *)

var
  AccountFile : file of AccountRec;
  Account     : array[1..100] of AccountRec;
  MaxAccount  : integer;
  CurrentAccount : integer;
  OldDir      : LineType;

function AccountFileName(ForAccount : integer) : string12;
var
  FileName : string12;
begin
  Str(Account[ForAccount].Number,FileName);
  FileName:='ACC'+Copy('0000'+FileName,Length(FileName)+1,4)+'.DAT';
  AccountFileName:=FileName;
end;

procedure LoadAccounts;
var
  FileName    : string[12];
  R : integer;
  count : integer;
  TempAcc : AccountRec;
  Sorted : boolean;
begin
  (* Change to this years directory *)
  MaxAccount:=0;
  Mask:='ACC?????.DAT'+#0;
  SetDir($00);
  while not ErrorFlag do begin
    FileName:=DirEntry;
    Assign(AccountFile,FileName);
    ReSet(AccountFile);
    if IOResult=0 then begin
      MaxAccount:=MaxAccount+1;
      Read(AccountFile,Account[MaxAccount]);
      Close(AccountFile);
    end;
  end;
  (* Sort accounts by account name *)
  Writeln( 'SORTING', MaxAccount);
  if MaxAccount > 1 then
    repeat
      Sorted := TRUE;
      for count := 1 to MaxAccount-1 do begin
        if Account[count].Name > Account[count+1].Name then begin
          TempAcc := Account[count];
          Account[count] := Account[count+1];
          Account[count+1] := TempAcc;
          Sorted := FALSE;
        end (* if *);
      end (* for *);
    until Sorted;
end; (* LoadAccounts *)

procedure SaveAccount;
begin
  Assign(AccountFile,AccountFileName(CurrentAccount));
  ReSet(AccountFile);
  if IOResult<>0 then ReWrite(AccountFile);
  Write(AccountFile,Account[CurrentAccount]);
  Close(AccountFile);
end;

{$I VA.AP }

{$I CHECK.AP }

{$I MENU.AR }

PROCEDURE ChangeDirectory(ToYear : INTEGER);

  BEGIN
    Str(ToYear,StrA);
    GetDir(DefaultDrive,OldDir);
    OldDir:=Chr(64+DefaultDrive)+':\';
    ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
    IF IOError=$01 THEN BEGIN
      ErrorMsg('Please put AR Data disk in drive '+DrivetoUse);
      IF Key='+' THEN BEGIN
        MkDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
        ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
      END;
      ChDir(DrivetoUse+':\'+StrA+Abbreviation+'.'+SerialNumber);
      IF IOError=$01 THEN Quit;
    END;
    SetAttribute('LOG.DAT',$00);
    SetAttribute('DATA.DAT',$00);
  END;


PROCEDURE Quit;

  BEGIN
    Assign(MenuProg,'MENU.COM');
    Execute(MenuProg);
  END;


var
  BDate : DateRec;

BEGIN
  TextColor(NormVid);
  TextBackground(NormBack);
  UsrOutPtr:=Ofs(ScreenOut);
  ChangeDirectory(TodaysDate.Year);
  LoadAccounts;
  Window(1,1,80,25); ClrScr; InfoLine;
  MainMenu;
  ChDir(OldDir);
  Quit;
END.
