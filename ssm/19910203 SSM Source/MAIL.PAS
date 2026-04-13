program Mailing_Labels;

(*$I-*)

CONST
  ModuleName       = 'Mailing Label Printer';

  Abbreviation     = 'ML';

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

{$I CUSTOM.ML}

type
  string12       = string[12];

  AddressRec     = record
    Number       :   integer;
    Name         :   string[40];
    Address      :   string[40];
    City         :   string[30];
  end;

var
  AddressFile : file;
  Address     : array[1..200] of AddressRec;
  MaxAddress  : integer;
  CurrentAddress : integer;
  OldDir      : LineType;
  AddressFileName : LineType;

PROCEDURE ChangeDirectory( ToYear : INTEGER; Abbr : LineType );

  BEGIN
    Str(ToYear,StrA);
    ChDir(DrivetoUse+':\'+StrA+Abbr+'.'+SerialNumber);
    IF IOError=$01 THEN BEGIN
      ErrorMsg('Please put '+Abbr+' Data disk in drive '+DrivetoUse);
      IF Key='+' THEN BEGIN
        MkDir(DrivetoUse+':\'+StrA+Abbr+'.'+SerialNumber);
        ChDir(DrivetoUse+':\'+StrA+Abbr+'.'+SerialNumber);
      END;
      ChDir(DrivetoUse+':\'+StrA+Abbr+'.'+SerialNumber);
      IF IOError=$01 THEN Quit;
    END;
  END;


procedure LoadAddress;
(* var
  count : integer;
  TempAcc : AddressRec;
  Sorted : boolean; *)
begin
  (* Change to this years directory *)
  FillChar(Address,SizeOf(Address),0);
  Assign( AddressFile, AddressFileName );
  ReSet( AddressFile, SizeOf( AddressRec ) );
  if IOResult = 0 then begin
    BlockRead( AddressFile, Address, FileSize(AddressFile), MaxAddress );
    Close( AddressFile );
  end else MaxAddress := 0;
(*  Sort Addresss by Address name
  Writeln( 'SORTING', MaxAddress);
  if MaxAddress > 1 then
    repeat
      Sorted := TRUE;
      for count := 1 to MaxAddress-1 do begin
        if Address[count].Name > Address[count+1].Name then begin
          TempAcc := Address[count];
          Address[count] := Address[count+1];
          Address[count+1] := TempAcc;
          Sorted := FALSE;
        end;
      end;
    until Sorted; *)
  CurrentAddress := 1;
end; (* LoadAddress *)

procedure SaveAddress;
begin
  Assign( AddressFile, AddressFileName );
  ReSet( AddressFile, SizeOf( AddressRec ) );
  if IOResult<>0 then ReWrite( AddressFile, SizeOf( AddressRec ) );
  BlockWrite( AddressFile, Address, MaxAddress );
  Truncate( AddressFile );
  Close( AddressFile );
end; (* SaveAddress *)

procedure UpdateAccount( AccountDir : LineType );
type
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
var
  Account : AccountRec;
  AccountFile : file of AccountRec;
  FileName    : LineType;
  count   : integer;
begin
  (* Change to this years directory *)
  Message( 'UPDATING '+AccountDir );
  ChangeDirectory( TodaysDate.Year, AccountDir );
  Mask := 'ACC?????.DAT'+#0;
  SetDir($00);
  while not ErrorFlag do begin
    FileName:=DirEntry;
    Assign(AccountFile,FileName);
    ReSet(AccountFile);
    if IOResult=0 then begin
      Read(AccountFile,Account);
      Close(AccountFile);
    end else Message(' SLADKHJFKDSH ' );
    Str(Account.Number,StrA);
    count := 1;
    while ( count <= MaxAddress ) and
      ( Address[count].Number <> Account.Number ) do
      count := count+1;
    if count > MaxAddress then begin
      Message( 'UPDATING '+AccountDir+' ACC# '+StrA );
      MaxAddress := MaxAddress+1;
      Address[MaxAddress].Number := Account.Number;
      Address[MaxAddress].Name := Account.Name;
      Address[MaxAddress].Address := Account.Address;
      Address[MaxAddress].City := Account.City;
    end; (* if *)
  end;
  ChangeDirectory( TodaysDate.Year, Abbreviation );
end; (* UpdateAccounts *)


{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     Main Menu routines                                                     }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}


PROCEDURE DrawAddress;

  BEGIN
    ChangeWindow(MLWindow);
    Window(UXLog,UYLog,LXLog,LYLog); ClrScr;
    FOR J:=CurrentAddress to CurrentAddress+3 do
      if J <= MaxAddress then with Address[J] do begin
        WriteLn( Name );
        WriteLn( Address );
        if J < CurrentAddress+3 then begin
          WriteLn( City );
          WriteLn;
        end else
          Write( City );
      end; (* with *)
    Window(1,1,80,25);
    GotoXY( 40, 4 );
    if AddressFileName='APADDR.DAT' THEN Write('*') ELSE Write(' ');
    GotoXY( 40, 5 );
    if AddressFileName='ARADDR.DAT' THEN Write('*') ELSE Write(' ');
    GotoXY( 40, 6 );
    if AddressFileName='MISCADDR.DAT' THEN Write('*') ELSE Write(' ');
  END;


PROCEDURE EditAddress;
VAR
  AtField : integer;
BEGIN
(*  DrawAddress; *)
  Window(1,1,80,25);
  AtField:=1;
  with Address[CurrentAddress] do
    repeat
      case AtField of
        1 : HiLiteCell(8,8,40);
        2 : HiLiteCell(8,9,40);
        3 : HiLiteCell(8,10,30);
      end; (* case *)
      ReadKbd;
      case AtField of
        1 : LoLiteCell(8,8,40);
        2 : LoLiteCell(8,9,40);
        3 : LoLiteCell(8,10,30);
      end; (* case *)
      if escape then
        case Key of
          'P' : if AtField<3 then AtField:=AtField+1;
          'H' : if AtField>1 then AtField:=AtField-1;
        end
      else
        case Key of
          ^M  : if AtField<4 then AtField:=AtField+1;
          else begin
            case AtField of
              1 : Name:=EnterCell(8,8,40,[' '..'~']);
              2 : Address:=EnterCell(8,9,40,[' '..'~']);
              3 : City:=EnterCell(8,10,30,[' '..'~']);
            end; (* case *)
            DrawAddress;
            Window(1,1,80,25);
            AtField:=AtField+1;
          end;
        end; (* case *)
    until (AtField>3) or (Key=#27);
end; (* EditAddress *)


PROCEDURE PrintAddress;

BEGIN
  Message( 'Printing label...' );
  WriteLn(Lst,Address[CurrentAddress].Name);
  WriteLn(Lst,Address[CurrentAddress].Address);
  WriteLn(Lst,Address[CurrentAddress].City);
  WriteLn(Lst);
  WriteLn(Lst);
  WriteLn(Lst);
END; (* PrintAddress *)


PROCEDURE MainMenu;
  BEGIN
    AddressFileName := 'MISCADDR.DAT';
    LoadAddress;
    DrawAddress;
    Cursor(16,0);
    REPEAT
      Message( 'I = Insert address  D = Delete address  E = Edit address' );
      ReadKbd;
      Key := Upcase(Key);
      CASE Key of
        ';'  :  BEGIN (* Payables *)
                  SaveAddress;
                  AddressFileName := 'APADDR.DAT';
                  LoadAddress;
                  DrawAddress;
                END;
        '<'  :  BEGIN (* Receivables *)
                  SaveAddress;
                  AddressFileName := 'ARADDR.DAT';
                  LoadAddress;
                  DrawAddress;
                END;
        '='  :  BEGIN (* Miscellaneous *)
                  SaveAddress;
                  AddressFileName := 'MISCADDR.DAT';
                  LoadAddress;
                  DrawAddress;
                END;
        '>'  :  PrintAddress;
        '?'  :  BEGIN (* Print All *)
                  for CurrentAddress := 1 to MaxAddress do begin
                    DrawAddress;
                    PrintAddress;
                  end;
                END;
        '@'  :  IF AddressFileName = 'APADDR.DAT' THEN BEGIN
                  UpdateAccount( 'AP' );
                  CurrentAddress := 1;
                  DrawAddress;
                END (* IF *) ELSE
                IF AddressFileName = 'ARADDR.DAT' THEN BEGIN
                  UpdateAccount( 'AR' );
                  CurrentAddress := 1;
                  DrawAddress;
                END; (* IF *)
        'E'  :  BEGIN (* Edit *)
                  EditAddress;
                END;
        'I'  :  BEGIN (* Insert *)
                  MaxAddress := MaxAddress+1;
                  CurrentAddress := MaxAddress;
                  DrawAddress;
                  EditAddress;
                END;
        'D'  :  BEGIN (* Delete *)
                  if MaxAddress>0 then begin
                    FOR J := CurrentAddress+1 TO MaxAddress DO
                      Address[J-1] := Address[J];
                    MaxAddress := MaxAddress-1;
                  end;
                  DrawAddress;
                END;
        'H'  :  IF CurrentAddress>1 THEN BEGIN
                  CurrentAddress:=CurrentAddress-1;
                  DrawAddress;
                END;
        'P'  :  IF CurrentAddress<MaxAddress THEN BEGIN
                  CurrentAddress:=CurrentAddress+1;
                  DrawAddress;
                END;
        'G'  :  BEGIN
                  CurrentAddress:=1;
                  DrawAddress;
                END;
        'O'  :  BEGIN
                  CurrentAddress:=MaxAddress;
                  DrawAddress;
                END;
        'I'  :  IF CurrentAddress-4>0 THEN BEGIN
                  CurrentAddress:=CurrentAddress-4;
                  DrawAddress;
                END;
        'Q'  :  IF CurrentAddress+4<=MaxAddress THEN BEGIN
                  CurrentAddress:=CurrentAddress+4;
                  DrawAddress;
                END;
        #27  :  BEGIN
                  SaveAddress;
                  Exit;
                END;
      END;
    UNTIL FALSE;
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
  GetDir(DefaultDrive,OldDir);
  OldDir:=Chr(64+DefaultDrive)+':\';
  ChangeDirectory(TodaysDate.Year, Abbreviation);
  Window(1,1,80,25); ClrScr; InfoLine;
  MainMenu;
  ChDir(OldDir);
  Quit;
END.
