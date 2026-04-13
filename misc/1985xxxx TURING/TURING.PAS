PROGRAM TuringMachine;

{$I-}

{$C-}

CONST
  NumberofStates   = 50;
  NumberofSymbols  = 1;


TYPE
  Direction        = (None,Right,Left);

  States           = 1..NumberofStates;

  Symbols          = 0..NumberofSymbols;

  TranslatorRec    = ARRAY[Symbols] of CHAR;

CONST
  Translator       : TranslatorRec = ('0','1');

  DirectionName    : ARRAY[Direction] of CHAR = ('N','R','L');


VAR
  FirstState       : BYTE;
  CurrentState     : States;
  LastState        : States;
  CurrentSymbol    : Symbols;
  DelayTime        : INTEGER;
  Trace            : BOOLEAN;
  Continue         : BOOLEAN;
  EditFlag         : BOOLEAN;
  Screen           : ARRAY[1..25,1..80,1..2] of CHAR ABSOLUTE $B000:$8000;
  Cell             : STRING[20];



CONST

  TuringWindow     : ARRAY[1..25,1..77] of CHAR =(
'ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ TURING MACHINE :    DEFAULT.TUR  TAPE :    DEFAULT.TAP                    บ',
'ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน',
'บ                                                                           บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ                                                                           บ',
'ฬ SELECT EDIT ออออออ RUN อออออออออออออออ DISK อออออออ DEBUG ออออออออออออออออน',
'บ  T ape edit      |  G o              |  L oad     |  D elay       -     0 บ',
'บ  M achine edit   |  C ontinue        |  S ave     |  R trace      -   OFF บ',
'บ                  |  P ause  Q uit    |  F iles    |  F irst state -     1 บ',
'วฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤถ',
'บSTณ   0   ณ   1   ณSTณ   0   ณ   1   ณSTณ   0   ณ   1   ณSTณ   0   ณ   1   บ',
'วฤฤลฤฤฤฤฤฤฤลฤฤฤฤฤฤฤลฤฤลฤฤฤฤฤฤฤลฤฤฤฤฤฤฤลฤฤลฤฤฤฤฤฤฤลฤฤฤฤฤฤฤลฤฤลฤฤฤฤฤฤฤลฤฤฤฤฤฤฤถ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'บ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       ณ  ณ       ณ       บ',
'ศออฯอออออออฯอออออออฯออฯอออออออฯอออออออฯออฯอออออออฯอออออออฯออฯอออออออฯอออออออผ');

  BigColumnWidth   = 19;
  BigColumnOffset  = 5;
  LittleColumnW    = 8;
  RowStart         = 14;

TYPE
  RegisterType = RECORD
    CASE INTEGER of
      1 : (AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : INTEGER);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH : BYTE);
              END;

VAR
  Registers        : RegisterType;
  Key              : CHAR;
  Escape           : BOOLEAN;
  I,J,K            : INTEGER;


PROCEDURE Cursor(Startline,Endline : BYTE);

  BEGIN
    WITH Registers DO BEGIN
      AH:=$01;
      CH:=Startline;
      CL:=Endline;
      Intr($10,Registers);
    END;
  END;


PROCEDURE ReadKbd;

  BEGIN
    Read(Kbd,Key);
    IF KeyPressed THEN BEGIN
      Read(Kbd,Key);
      Escape:=TRUE;
    END
    ELSE Escape:=FALSE;
  END;


PROCEDURE WriteScreen;

  VAR
    Count1,Count2  : BYTE;

  BEGIN
    FOR Count1:=1 to 25 DO
      FOR Count2:=1 to 77 DO
        Screen[Count1,Count2,1]:=TuringWindow[Count1,Count2];
  END;


PROCEDURE EditCell(X,Y,Size : INTEGER);

  BEGIN
    TextColor(White);TextBackground(Green);
    IF Key<>#0 THEN Cell:=Key ELSE Cell:='';
    GotoXY(X,Y);
    Write('':Size);
    REPEAT
      GotoXY(X,Y);
      Write(Cell,'_');Write('':Size-Length(Cell)-1);
      ReadKbd;
      IF Key=^H THEN Cell:=Copy(Cell,1,Length(Cell)-1);
      IF Key in [' '..'~'] THEN Cell:=Cell+Key;
      IF Length(Cell)>Size-1 THEN Cell:=Copy(Cell,2,Length(Cell));
    UNTIL (Key=#13) OR Escape;
    TextColor(Yellow);TextBackground(Black);
  END;


{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{  Tape Handling Routines                                                    }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}


CONST
  TapeLength       = 1000;


TYPE
  TuringTapeRec    = ARRAY[1..TapeLength] of Symbols;


VAR
  Tape             : TuringTapeRec;
  TapeName         : STRING[15];
  TapeFile         : FILE of Symbols;
  CarriagePosition : 1..TapeLength;
  LeftPosition     : 1..TapeLength;


PROCEDURE DrawTape(At : INTEGER);

  VAR
    Count          : INTEGER;

  BEGIN
    FOR Count:=2 to 76 DO BEGIN
      Screen[4,Count,1]:=Translator[Tape[Count-1+At]];
      Screen[4,Count,2]:=Chr(White+Blue*16);
    END;
    LeftPosition:=At;
  END;


PROCEDURE LoadTape;

  VAR
    Count          : INTEGER;

  BEGIN
    Key:=#0;
    EditCell(43,2,14);
    IF Cell<>'' THEN TapeName:=Cell;
    IF Pos('.',TapeName)=0 THEN TapeName:=TapeName+'.TAP';
    GotoXY(43,2); Write(TapeName:14);
    Assign(TapeFile,TapeName);
    ReSet(TapeFile);
    Count:=CarriagePosition;
    REPEAT
      Read(TapeFile,Tape[Count]);
      Count:=Count+1;
    UNTIL Eof(TapeFile);
    Close(TapeFile);
    DrawTape(LeftPosition);
  END;

VAR
  Start,Stop       : INTEGER;

PROCEDURE SaveTape;

  VAR
    Count          : INTEGER;

  BEGIN
    IF Start=0 THEN Start:=CarriagePosition ELSE BEGIN
      Stop:=CarriagePosition;
      Key:=#0;
      EditCell(43,2,14);
      IF Cell<>'' THEN TapeName:=Cell;
      IF Pos('.',TapeName)=0 THEN TapeName:=TapeName+'.TAP';
      GotoXY(43,2); Write(TapeName:14);
      Assign(TapeFile,TapeName);
      ReWrite(TapeFile);
      FOR Count:=Start to Stop DO Write(TapeFile,Tape[Count]);
      Close(TapeFile);
      Start:=0;
    END;
  END;


PROCEDURE CountSym;

  VAR
    TempPos        : 1..TapeLength;
    Count          : integer;

  BEGIN
    TempPos:=CarriagePosition-1;
    while Tape[TempPos]=Tape[CarriagePosition] do TempPos:=TempPos-1;
    Count:=CarriagePosition-TempPos;
    TempPos:=CarriagePosition+1;
    while Tape[TempPos]=Tape[CarriagePosition] do TempPos:=TempPos+1;
    Count:=Count+TempPos-CarriagePosition-1;
    GotoXY(CarriagePosition-LeftPosition+1,6);
    Write(Count);
    repeat until KeyPressed;
    GotoXY(CarriagePosition-LeftPosition+1,6);
    Write('   ');
  END;


PROCEDURE EditTape;

  BEGIN
    IF Escape THEN
      CASE Key of
        #75      : CarriagePosition:=CarriagePosition-1;
        #77      : CarriagePosition:=CarriagePosition+1;
        #38      : LoadTape;
        #31      : SaveTape;
      END
    ELSE BEGIN
      CASE Key of
        '0'      : Tape[CarriagePosition]:=0;
        '1'      : Tape[CarriagePosition]:=1;
        '?'      : CountSym;
      END;
      IF Key in ['0','1',' '] THEN BEGIN
        TextColor(White);TextBackground(Blue);
        GotoXY(CarriagePosition-LeftPosition+1,4);
        Write(Translator[Tape[CarriagePosition]]);
        TextColor(Yellow);TextBackground(Black);
        CarriagePosition:=CarriagePosition+1;
      END;
    END;
    IF CarriagePosition>LeftPosition+74 THEN DrawTape(LeftPosition+1);
    IF CarriagePosition<LeftPosition+2 THEN DrawTape(LeftPosition-1);
    GotoXY(CarriagePosition-LeftPosition,5);
    Write('ฤ');
    TextColor(White);TextBackground(Green);
    Write('^');
    TextColor(Yellow);TextBackground(Black);
    Write('ฤ');
  END;




{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{  Machine Handling Routines                                                 }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

TYPE
  InstructionRec   = RECORD
    WriteChar      :   Symbols;
    State          :   States;
    Move           :   Direction;
    Stop           :   BOOLEAN;
                     END;


VAR
  Machine            : ARRAY[States,Symbols] of InstructionRec;
  MachineFile       : FILE of BYTE;
  MachineName      : STRING[15];


PROCEDURE WriteInstruct(State : States;Symbol : Symbols);

  VAR
    Line           : STRING[10];

  BEGIN
    GotoXY(
      ((State-1) div 11)*BigColumnWidth+BigColumnOffset+Symbol*LittleColumnW,
      ((State-1) mod 11)+RowStart);
    WITH Machine[State,Symbol] DO BEGIN
      IF Stop THEN Line:=Translator[WriteChar]+',HALT'
      ELSE BEGIN
        Str(State,Line);
        Line:=Translator[WriteChar]+','+Line+','+DirectionName[Move];
      END;
      Write(Line:7);
    END;
  END;


PROCEDURE NullInstruct(ForState : States;ForSymbol : Symbols);

  BEGIN
    WITH Machine[ForState,ForSymbol] DO BEGIN
      WriteChar:=ForSymbol;
      State:=ForState;
      Move:=Right;
      Stop:=FALSE;
    END;
  END;


PROCEDURE DrawMachine;

  VAR
    Count1         : INTEGER;
    Count2         : INTEGER;

  BEGIN
    FOR Count1:=1 to LastState DO
      FOR Count2:=0 to NumberofSymbols DO BEGIN
        GotoXY(((Count1-1) div 11)*BigColumnWidth+2,((Count1-1) mod 11)+RowStart);
        Write(Count1:2);
        WriteInstruct(Count1,Count2);
      END;
  END;


PROCEDURE LoadMachine;

  VAR
    DummyArray     : ARRAY[1..4096] of BYTE ABSOLUTE Machine;
    Count          : INTEGER;

  BEGIN
    Key:=#0;
    EditCell(20,2,14);
    IF Cell<>'' THEN MachineName:=Cell;
    IF Pos('.',MachineName)=0 THEN MachineName:=MachineName+'.TUR';
    GotoXY(20,2); Write(MachineName:14);
    Assign(MachineFile,MachineName);
    ReSet(MachineFile);
    Read(MachineFile,FirstState);
    GotoXY(71,10);Write(FirstState:5);
    LastState:=(FileSize(MachineFile)-1) div SizeOf(Machine[1]) + 1;
    NullInstruct(LastState,0); NullInstruct(LastState,1);
    FOR Count:=1 to FileSize(MachineFile)-1 DO
      Read(MachineFile,DummyArray[Count]);
    Close(MachineFile);
    DrawMachine;
  END;


PROCEDURE SaveMachine;

  VAR
    DummyArray     : ARRAY[1..4096] of BYTE ABSOLUTE Machine;
    Count          : INTEGER;

  BEGIN
    Key:=#0;
    EditCell(20,2,14);
    IF Cell<>'' THEN MachineName:=Cell;
    IF Pos('.',MachineName)=0 THEN MachineName:=MachineName+'.TUR';
    GotoXY(20,2); Write(MachineName:14);
    Assign(MachineFile,MachineName);
    ReWrite(MachineFile);
    Write(MachineFile,FirstState);
    FOR Count:=1 to (LastState-1)*SizeOf(Machine[1]) DO
      Write(MachineFile,DummyArray[Count]);
    Close(MachineFile);
  END;


PROCEDURE EditInstruct;

  VAR
    Value,Place    : INTEGER;

  BEGIN
    EditCell(
      ((CurrentState-1) div 11)*BigColumnWidth+BigColumnOffset+CurrentSymbol*LittleColumnW,
      ((CurrentState-1) mod 11)+RowStart,7);
    WITH Machine[CurrentState,CurrentSymbol] DO BEGIN
      NullInstruct(CurrentState,CurrentSymbol);
      IF UpCase(Cell[1])='H' THEN Stop:=TRUE ELSE BEGIN
        WriteChar:=Ord(Cell[1])-48;
        Cell:=Copy(Cell,3,Length(Cell));
        IF UpCase(Cell[1])='H' THEN Stop:=TRUE ELSE BEGIN
          Val(Cell,Value,Place);
          State:=Value;
          Cell:=Copy(Cell,Place+1,Length(Cell));
          IF UpCase(Cell[1])='H' THEN Stop:=TRUE ELSE BEGIN
            CASE UpCase(Cell[1]) of
              'L'  : Move:=Left;
              'R'  : Move:=Right;
            END;
            Cell:=Copy(Cell,3,Length(Cell));
            IF UpCase(Cell[1])='H' THEN Stop:=TRUE;
          END;
        END;
      END;
      IF CurrentState=LastState THEN BEGIN
        LastState:=LastState+1;
        NullInstruct(LastState,0);
        NullInstruct(LastState,1);
        GotoXY(((LastState-1) div 11)*BigColumnWidth+2,((LastState-1) mod 11)+RowStart);
        Write(LastState:2);
        WriteInstruct(LastState,0);
        WriteInstruct(LastState,1);
      END;
    END;
  END;


PROCEDURE EditMachine;

  BEGIN
    TextColor(Yellow);TextBackground(Black);
    WriteInstruct(CurrentState,CurrentSymbol);
    IF Escape THEN
      CASE Key of
        'K'      : CurrentSymbol:=0;
        'M'      : CurrentSymbol:=1;
        'H'      : IF CurrentState>1 THEN CurrentState:=CurrentState-1;
        'P'      : IF CurrentState<LastState THEN CurrentState:=CurrentState+1;
        'G'      : CurrentState:=1;
        'O'      : CurrentState:=LastState;
    END ELSE BEGIN
      CASE Key of
        '0'..'9','h','H' : EditInstruct;
        ^D               : IF CurrentState=LastState THEN BEGIN
                             CurrentState:=CurrentState-1;
                             LastState:=LastState-1;
                             GotoXY((LastState div 11)*BigColumnWidth+2,(LastState mod 11)+RowStart);
                             Write('  ณ       ณ       ');
                           END;
      END;
      WriteInstruct(CurrentState,CurrentSymbol);
      IF Key=#13 THEN IF CurrentSymbol=0 THEN CurrentSymbol:=1 ELSE BEGIN
        CurrentSymbol:=0;
        IF CurrentState<LastState THEN CurrentState:=CurrentState+1;
      END;
    END;
    TextColor(White);TextBackground(Green);
    WriteInstruct(CurrentState,CurrentSymbol);
    TextColor(Yellow);TextBackground(Black);
  END;




{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{  Executive Routines                                                        }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

PROCEDURE DrawPosition;

  BEGIN
    IF CarriagePosition>LeftPosition+70 THEN DrawTape(LeftPosition+1);
    IF CarriagePosition<LeftPosition+2 THEN DrawTape(LeftPosition-1);
    GotoXY(CarriagePosition-LeftPosition,5);
    Writeln('ฤ^ฤ');
    GotoXY(CarriagePosition-LeftPosition,6);
    Writeln(' ',CurrentState,'  ');
  END;


PROCEDURE ExecuteInstruct(ForInstruct : InstructionRec);

  BEGIN
    WITH ForInstruct DO BEGIN
      Delay(DelayTime);
      IF KeyPressed OR Trace THEN BEGIN
        TextColor(White);TextBackground(Red);
        WriteInstruct(CurrentState,Tape[CarriagePosition]);
        Read(Kbd,Key);
        IF Key='p' THEN Read(Kbd,Key);
        IF Key='q' THEN Continue:=FALSE;
        TextColor(Yellow);TextBackground(Black);
        WriteInstruct(CurrentState,Tape[CarriagePosition]);
      END;
      Tape[CarriagePosition]:=WriteChar;
      Screen[4,CarriagePosition-LeftPosition+1,1]:=Translator[Tape[CarriagePosition]];
      CASE Move of
        Right      : CarriagePosition:=CarriagePosition+1;
        Left       : CarriagePosition:=CarriagePosition-1;
      END;
      CurrentState:=State;
      DrawPosition;
    END;
  END;


PROCEDURE RunMachine;

  BEGIN
    Continue:=TRUE;
    WHILE NOT(Machine[CurrentState,Tape[CarriagePosition]].Stop) AND (Continue=TRUE) DO
      ExecuteInstruct(Machine[CurrentState,Tape[CarriagePosition]]);
    ExecuteInstruct(Machine[CurrentState,Tape[CarriagePosition]]);
    REPEAT UNTIL KeyPressed;
    GotoXY(CarriagePosition-LeftPosition,6);
    Write('     ');
  END;




{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{  Main Routines                                                             }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

PROCEDURE Edit;

  BEGIN
    Key:=#0; EditMachine;
    REPEAT
      ReadKbd;
      CASE Key of
        'g'      : BEGIN
                     CurrentState:=FirstState;
                     RunMachine;
                   END;
        'c'      : RunMachine;
        't'      : BEGIN
                     EditFlag:=FALSE;
                     WriteInstruct(CurrentState,CurrentSymbol);
                     Key:=#0;
                     EditTape;
                   END;
        'm'      : BEGIN
                     EditFlag:=TRUE;
                     GotoXY(CarriagePosition-LeftPosition+1,5);
                     Write('^');
                     Key:=#0;
                     EditMachine;
                   END;
        'f'      : BEGIN
                     Key:=#0;
                     EditCell(71,10,5);
                     Val(Cell,I,J);
                     FirstState:=I;
                     GotoXY(71,10);Write(FirstState:5);
                   END;
        'd'      : BEGIN
                     Key:=#0;
                     EditCell(71,8,5);
                     Val(Cell,I,J);
                     DelayTime:=I;
                     GotoXY(71,8);Write(DelayTime:5);
                   END;
        'r'      : IF Trace THEN BEGIN
                     Trace:=FALSE;
                     GotoXY(71,9);
                     Write('OFF':5);
                   END ELSE BEGIN
                     Trace:=TRUE;
                     GotoXY(71,9);
                     Write('ON':5);
                   END;
        'l'      : LoadMachine;
        's'      : SaveMachine;
        ELSE IF EditFlag THEN EditMachine ELSE EditTape;
      END;
    UNTIL Key=#27;
  END;


PROCEDURE Initialize;

  BEGIN
    CarriagePosition:=TapeLength div 2;
    TapeName:='DEFAULT.TAP';
    FirstState:=1;
    CurrentState:=1;
    LastState:=1;
    NullInstruct(1,0);NullInstruct(1,1);
    CurrentSymbol:=0;
    MachineName:='DEFAULT.TUR';
    Trace:=FALSE;
    DelayTime:=0;
    EditFlag:=TRUE;
    Start:=0;
  END;


BEGIN
  Cursor(16,0);
  ClrScr;
  WriteScreen;
  Initialize;
  FillChar(Tape,SizeOf(Tape),0);
  DrawTape(CarriagePosition-40);
  DrawMachine;
  Edit;
  ClrScr;
  Cursor(6,7);
END.