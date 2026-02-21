{$I-}
{$C+}

PROGRAM MainMenu;

TYPE
  DateRec              = RECORD
    Month              :   BYTE;
    Day                :   BYTE;
    Year               :   INTEGER;
    Hour               :   BYTE;
    Minute             :   BYTE;
                         END;

  String30             = STRING[30];
  String10             = STRING[10];

  LineType             = STRING[80];


VAR
  TodaysDate           : DateRec;
  DateEntered          : BOOLEAN;
  ChangeStatus         : BOOLEAN;
  PassWord             : String30;

CONST
  ModuleName           = 'Service Station Manager 1.0';
  Abbreviation         = 'SSM';
  DrivetoUse           = 'B';

  MainMenu                 : BYTE = 23;
  MainMenuScr              : ARRAY[1..23,1..78] of CHAR =(
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                                                                            บ',
'บ                          SERVICE STATION MANAGER                           บ',
'บ                                                                            บ',
'บ                                VERSION 1.0                                 บ',
'บ                                                                            บ',
'ฬออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ                        St. Andrew`s Texaco                                 บ',
'บ                        2000 Campus Drive                                   บ',
'บ                        St. Charles, MO  63301                              บ',
'ฬอออออออออออออออออัอออออออออออออออออออออออออออออออออออออัออออออออออออออออออออน',
'บ            PRESSณ MAIN FUNCTIONS                 PRESSณ UTILITIES          บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ              F1 ณ Fuel Inventory Manager            D ณ Change Date        บ',
'บ              F2 ณ Income Account                  ESC ณ Exit to DOS        บ',
'บ              F3 ณ Accounts Payable                    ณ                    บ',
'บ              F4 ณ Accounts Receivable                 ณ                    บ',
'บ              F5 ณ Mailing Label Printing              ณ                    บ',
'บ              F6 ณ Daily Report                        ณ                    บ',
'บ                 ณ                                     ณ                    บ',
'ฬอออออออออออออออออฯอออออออออออออออออออออออออออออออออออออฯออออออออออออออออออออน',
'บ (C) Copyright 1985 by Derek Lane                                     SN102 บ',
'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
  Access1 : String30 = '';
  Access2 : String30 = '';

VAR
  Changed              : BOOLEAN;
  CaseErr              : INTEGER;
  ErrorNumber          : INTEGER;
  Line                 : LineType;
  StrA,StrB            : String10;
  X,Y,Z                : REAL;
  I,J,K                : INTEGER;
  Right                : BOOLEAN;
  ErrorFlag            : BOOLEAN;
  NxtProg              : FILE;


{$I UTILITY2.PAS}


PROCEDURE EnterPassword;

  BEGIN
    IF Access2<>'' THEN BEGIN
      IF (Password<>Access2) AND (Password<>Access1) THEN BEGIN
        Write('PASSWORD: ');
        Read(Password);
        IF Password=Access2 THEN ChangeStatus:=TRUE ELSE
          IF Password=Access1 THEN ChangeStatus:=FALSE ELSE Halt;
      END;
    END
    ELSE ChangeStatus:=TRUE;
  END;


PROCEDURE SetDate(VAR ForDay : DateRec);

  VAR
    Dateinput  :STRING[8];
    Timeinput  :STRING[8];
    Right      :BOOLEAN;
    Number     :INTEGER;
    NextChar   :INTEGER;

  BEGIN
    Window(1,1,80,24);ClrScr;
    Frame(30,11,50,14);ClrScr;
    Cursor(0,7);
    REPEAT
      GotoXY(1,1);Write('DATE: ');Readln(StrA);
      GotoXY(1,2);Write('TIME: ');Readln(StrB);
      ParseDate(StrA,StrB,TodaysDate);
    UNTIL Right;
    Cursor(16,0);
  END;


PROCEDURE AssignPassWord;

  BEGIN
    IF ChangeStatus THEN BEGIN
      Frame(20,10,70,20);
      ClrScr;
      Write('Access 1 (Read Only) password? ');Readln(Access1);
      Write('Access 2 (Read & Write) password? ');Readln(Access2);
      ChangeWindow(MainMenu);
    END;
  END;


PROCEDURE NewDisk;

BEGIN
END; (* NewDisk *)


PROCEDURE Quit;

  BEGIN
    Password:='';
    Cursor(6,7);
    ClrScr;
  END;


VAR
  FileA,FileB      : file;
  Buffer           : array[0..127,1..100] of byte;
  Result           : integer;
  Size             : integer;

PROCEDURE BackUp(Name : LineType);

  BEGIN
    Write('BACKING UP ',Name,^M);
    SetAttribute('A:'+Name,$00);
    SetAttribute('B:'+Name,$00);
    Assign(FileA,'A:'+Name);
    Assign(FileB,'B:'+Name);
    ReWrite(FileA);
    ReSet(FileB);
    if IOResult=0 then begin
      Size:=0;
      repeat
        BlockRead(FileB,Buffer,100,Result);
        BlockWrite(FileA,Buffer,Result);
        Size:=Size+Result;
        Write('BACKING UP ',Name,' - ',Size*128,' bytes',^M);
      until Result=0;
      Close(FileB);
      Close(FileA);
      SetAttribute('A:'+Name,$03);
      SetAttribute('B:'+Name,$03);
    end else Write('** ERROR ');
    Writeln;
  END;


VAR
  DateFile         : text;
  DateLine         : LineType;

BEGIN
  TextColor(NormVid);TextBackground(NormBack);
  Cursor(16,0);
  Window(1,1,80,25);ClrScr;
  ChangeStatus:=TRUE;
  IF Not DateEntered THEN BEGIN
    SetDate(TodaysDate);
    DateEntered:=TRUE;
  END;
  Infoline;
  ChangeWindow(MainMenu);
(*  IF DiskMemory( 2 ) < 2048.0 THEN
      ErrorMsg( ' Data disk is almost full.  Press "N" to start new disk. ' ); *)
  GotoXY(1,24);
  REPEAT
    Read(Kbd,Key);
    IF KeyPressed AND (key=#27) THEN BEGIN
      Read(Kbd,Key);
    END;
    CASE Key of
      'd'      :BEGIN
                  SetDate(TodaysDate);
                  ChangeWindow(MainMenu);
                  InfoLine;GotoXY(1,24);ClrEol;
                END;
(*      'n'      :Newdisk; *)
      'p'      :AssignPassWord;
      ';'      :Assign(NxtProg,'FIM.CHN');
      '<'      :Assign(NxtProg,'IA.CHN');
      '='      :Assign(NxtProg,'AP.CHN');
      '>'      :Assign(NxtProg,'AR.CHN');
      '?'      :Assign(NxtProg,'MAIL.CHN');
      '@'      :Assign(NxtProg,'DR.CHN');
(*      'b'      :begin
                  Frame(20,3,70,22); ClrScr;
                  Writeln('INSERT BACKUP DISK IN DRIVE A: AND HIT A KEY');
                  ReadKbd;
                  Assign(DateFile,'A:DATEBACK.DAT');
                  ReSet(DateFile);
                  if IOResult=0 then begin
                    Readln(DateFile,DateLine);
                    Close(DateFile);
                    Writeln('LAST BACKUP - ',DateLine);
                    Writeln('CONTINUE (Y/N)?');
                    ReadKbd;
                    if UpCase(Key)='Y' then begin
                      Str(TodaysDate.Year,DateLine);
                      Backup('\'+DateLine+'FIM.100\LOG.DAT');
                      Backup('\'+DateLine+'FIM.100\TR.DAT');
                      Backup('\'+DateLine+'FIM.100\MFI.DAT');
                      Backup('\'+DateLine+'FIM.100\DELIV.DAT');
                      Backup('\'+DateLine+'FIM.100\MMP.DAT');
                      Backup('\'+DateLine+'FIM.100\PRICE.DAT');
                      Backup('\'+DateLine+'IA.100\LOG.DAT');
                      Backup('\'+DateLine+'IA.100\DATA.DAT');
                      ReWrite(DateFile);
                      with TodaysDate do Writeln(DateFile,Month,'/',Day,'/',Year);
                      Close(DateFile);
                    end;
                  end;
                  ChangeWindow(MainMenu);
                end; *)
    END;
    IF Key in [';'..'@'] THEN BEGIN
      Chain(NxtProg);
      IF IOError=$01 THEN
        ErrorMsg('Please put the program disk in drive '+Chr(DefaultDrive+64));
    END;
  UNTIL Key=#27;
  Quit;
END.