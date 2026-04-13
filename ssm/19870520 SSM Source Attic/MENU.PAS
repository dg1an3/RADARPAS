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
  PassPar              : RECORD
    NormColor          :   BYTE;
    NormBack           :   BYTE;
    HiColor            :   BYTE;
    HiBack             :   BYTE;
    ErrColor           :   BYTE;
    ErrBack            :   BYTE;
    ProgDrive          :   CHAR;
    DataDrive          :   CHAR;
                         END;


CONST
  ModuleName           = 'Service Station Manager 1.0';
  Abbreviation         = 'SSM';
  NormColor            : BYTE = White;
  NormBack             : BYTE = Black;
  HiColor              : BYTE = Black;
  HiBack               : BYTE = White;
  ErrColor             : BYTE = Black;
  ErrBack              : BYTE = White;
  ProgDrive            : CHAR = 'A';
  DataDrive            : CHAR = 'B';


  MainMenu                 : BYTE = 23;
  MainMenuScr              : ARRAY[1..23,1..78] of CHAR =(
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                                                                            บ',
'บ                          SERVICE STATION MANAGER                           บ',
'บ                                                                            บ',
'บ                                VERSION 1.0                                 บ',
'บ                                                                            บ',
'ฬออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ                        Don Hewlett                                         บ',
'บ                        1980 First Capitol Drive South                      บ',
'บ                        St. Charles, MO  63302                              บ',
'ฬอออออออออออออออออออออออออออัออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ                      PRESSณ                                                บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ                        F1 ณ Fuel Inventory Manager                         บ',
'บ                        F2 ณ Income Account                                 บ',
'บ                        F3 ณ Accounts Payable                               บ',
'บ                        F4 ณ Accounts Recievable                            บ',
'บ                        F5 ณ Payroll                                        บ',
'บ                        F6 ณ BACK UP FILES                                  บ',
'บ                        D  ณ Change Date                                    บ',
'ฬอออออออออออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ (C) Copyright 1985 by Derek Lane                                     SN100 บ',
'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
  Colornames : array[0..15] of string[20] =
    ('0 - Black','1 - Blue','2 - Green','3 - Cyan',
     '4 - Red','5 - Magenta','6 - Brown','7 - LightGray',
     '8 - DarkGray','9 - Light Blue','10 - Light Green','11 - Light Cyan',
     '12 - Pink','13 - Light Magenta','14 - Yellow','15 - White');

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


{$I UTILITY.PAS}


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
      Cursor(0,7);
      Frame(20,10,70,20);
      ClrScr;
      Write('Access 1 (Read Only) password? ');Readln(Access1);
      Write('Access 2 (Read & Write) password? ');Readln(Access2);
      SaveChange(Access1,30,'MENU.COM');
      SaveChange(Access2,30,'MENU.COM');
      ChangeWindow(MainMenu);
      Cursor(16,0);
    END;
  END;


PROCEDURE SetDefaults;

  BEGIN
    IF ChangeStatus THEN BEGIN
      Frame(20,3,70,22);
      REPEAT
        ClrScr;
        FOR I:=0 to 7 DO BEGIN
          GotoXY(1,I+1);
          TextColor(I);Write('Û ');TextColor(NormColor);
          Writeln(ColorNames[I]);
        END;
        FOR I:=8 to 15 DO BEGIN
          GotoXY(20,I-7);
          TextColor(I);Write('Û ');TextColor(NormColor);
          Writeln(ColorNames[I]);
        END;
        Writeln(^M,^J,' F1 Normal Color      : ',ColorNames[NormColor]);
        Writeln(' F2 Normal Background : ',ColorNames[NormBack]);
        TextColor(HiColor);TextBackground(HiBack);
        Writeln(' F3 HiLite Color      : ',ColorNames[HiColor]);
        Writeln(' F4 HiLite Background : ',ColorNames[HiBack]);
        TextColor(ErrColor);TextBackground(ErrBack);
        Writeln(' F5 Error Color       : ',ColorNames[ErrColor]);
        Writeln(' F6 Error Background  : ',ColorNames[ErrBack]);
        TextColor(NormColor);TextBackground(NormBack);
        Writeln(' F7 Prog Drive        : ',ProgDrive);
        Writeln(' F8 Data Drive        : ',DataDrive);
        Write(' ESC Exit');
        ReadKbd;
        IF Key in [';'..'@'] THEN BEGIN
          GotoXY(25,Ord(Key)-49);
          ClrEol;
          Cursor(0,7);
          IF Key in [';'..'@'] THEN Read(I) ELSE Read(StrA);
          Cursor(16,0);
          CASE Key of
            ';'      : BEGIN
                         NormColor:=I;
                         TextColor(NormColor);
                       END;
            '<'      : BEGIN
                         NormBack:=I;
                         TextBackground(NormColor);
                       END;
            '='      : HiColor:=I;
            '>'      : HiBack:=I;
            '?'      : ErrColor:=I;
            '@'      : ErrBack:=I;
            'A'      : ProgDrive:=StrA[1];
            'B'      : DataDrive:=StrA[1];
          END;
        END;
      UNTIL Key=#27;
      Key:=#0;
      SaveChange(NormColor,8,'MENU.COM');
      ChangeWindow(MainMenu);
      InfoLine;
    END;
  END;


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
  EnterPassWord;
  PassPar.NormColor:=NormColor;
  PassPar.NormBack:=NormBack;
  PassPar.HiColor:=HiColor;
  PassPar.HiBack:=HiBack;
  PassPar.ErrColor:=ErrColor;
  PassPar.ErrBack:=ErrBack;
  PassPar.ProgDrive:=ProgDrive;
  PassPar.DataDrive:=DataDrive;
  TextColor(NormColor);TextBackground(NormBack);
  Cursor(16,0);
  Window(1,1,80,25);ClrScr;
  IF Not DateEntered THEN BEGIN
    SetDate(TodaysDate);
    DateEntered:=TRUE;
  END;
  Infoline;
  ChangeWindow(MainMenu);
  GotoXY(1,24);
  REPEAT
    ReadKbd;
    CASE Key of
      'd'      :BEGIN
                  SetDate(TodaysDate);
                  ChangeWindow(MainMenu);
                  InfoLine;GotoXY(1,24);ClrEol;
                END;
      'p'      :AssignPassWord;
      'c'      :SetDefaults;
      ';'      :Assign(NxtProg,'FIM.CHN');
      '<'      :Assign(NxtProg,'IA.CHN');
      '='      :Assign(NxtProg,'AP.CHN');
      '>'      :Assign(NxtProg,'AR.CHN');
      '?'      :Assign(NxtProg,'PR.CHN');
      '@'      :begin
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
                end;
    END;
    IF Key in [';'..'?'] THEN BEGIN
      Chain(NxtProg);
      IF IOResult=$01 THEN
        ErrorMsg('Please put the program disk in drive '+ProgDrive);
    END;
  UNTIL Key=#27;
  Quit;
END.