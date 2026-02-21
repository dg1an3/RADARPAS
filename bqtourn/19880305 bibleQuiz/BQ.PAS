program Bible_Quiz_Tournament_Manager;

{$I-}

const
  MaxRound         = 8;
  MaxTeam          = 18;

  NumRound         : byte = 8;
  NumTeam          : byte = 16;

  MC               = White;
  BC               = LightGray;

  BrowseSize       : byte = 24;
  BrowseWind       : array[1..24,1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออปษออออออออออออออออออออออออออออออออป',
'บ                                          บบ                                บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถวฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ                                          บบ   COACH :                      บ',
'บ                                          บบ   ------ NAME ------     SCORE บ',
'บ                                          บบ 1.                             บ',
'บ                                          บบ 2.                             บ',
'บ                                          บบ 3.                             บ',
'บ                                          บบ 4.                             บ',
'บ                                          บบ 5.                             บ',
'บ                                          บบ 6.                             บ',
'บ                                          บบ 7.                             บ',
'บ                                          บบ 8.                             บ',
'บ                                          บบ 9.                             บ',
'บ                                          บบ10.                             บ',
'บ                                          บบ          FOULS/BONUSES         บ',
'บ                                          บบ--------------------------------บ',
'บ                                          บบ                  TOTAL         บ',
'บ                                          บบ         OPPOSING TOTAL         บ',
'บ                                          บบ       WINS/LOSSES/TIES         บ',
'บ                                          บวฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถบ OPPOSING TEAM :                บ',
'บ ROUND:                                   บบ                                บ',
'ศออออออออออออออออออออออออออออออออออออออออออผศออออออออออออออออออออออออออออออออผ');

  EditSize         : byte = 22;
  EditWind         : array[1..22,1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                                                             ROUND :        บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤถ',
'บ                         |   CORRECT    |    |  INCORRECT   |    |          บ',
'บ                         |              |QUIZ|              |    |          บ',
'บ TEAM MEMBER             | 10 | 20 | 30 |OUTS| 10 | 20 | 30 |FOUL|  TOTAL   บ',
'บ-------------------------|----|----|----|----|----|----|----|----|----------บ',
'บ      TEAM FOULS/BONUSES | -- | -- | -- | -- | -- | -- | -- | -- |          บ',
'บ-------------------------|----|----|----|----|----|----|----|----|          บ',
'บ 1.                      |    |    |    |    |    |    |    |    |          บ',
'บ 2.                      |    |    |    |    |    |    |    |    |          บ',
'บ 3.                      |    |    |    |    |    |    |    |    |          บ',
'บ 4.                      |    |    |    |    |    |    |    |    |          บ',
'บ 5.                      |    |    |    |    |    |    |    |    |          บ',
'บ 6.                      |    |    |    |    |    |    |    |    |          บ',
'บ 7.                      |    |    |    |    |    |    |    |    |          บ',
'บ 8.                      |    |    |    |    |    |    |    |    |          บ',
'บ 9.                      |    |    |    |    |    |    |    |    |          บ',
'บ10.                      |    |    |    |    |    |    |    |    |          บ',
'บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤลฤฤฤฤฤฤฤฤฤฤบ',
'บ                                                           TOTAL ณ          บ',
'ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออฯออออออออออผ');

type
  WindPtr          = ^WindRec;
  WindRec          = record
    Size           :   byte;
    Data           :   array[1..60,1..78] of char;
                     end;
  StrType          = string[255];

var
  CurrWind         : WindPtr;
  Screen           : array[1..25,1..80,1..2] of char absolute $B000:$8000;
  Key              : char;
  Escape           : boolean;

procedure ReadKbd;

  begin
    Read(Kbd,Key);
    if KeyPressed then begin
      Read(Kbd,Key);
      Escape:=true;
    end;
  end;


procedure DrawLine(var Where;AtLine : BYTE);

  var
    I,J  : integer;
    Line : array[1..78] of CHAR absolute Where;

  begin
    for I:= 1 to 78 do Screen[AtLine,I,1]:=Line[I];
  end;


procedure ShowWind;

  var
    I,J,K          : integer;

  begin
    Window(1,1,80,24); ClrScr;
    with CurrWind^ do begin
      if Size<=24 then K:=Size else K:=24;
      for J:= 1 to K do
        for I:= 1 to 78 do
          Screen[J,I,1]:=Data[J,I];
      Window(1,1,80,23);
    end;
  end;


procedure WriteScreen(ForStr : StrType;X,Y,S : byte);

  var
    I              : byte;

  begin
    for I:=1 to Length(ForStr) do Screen[Y,X+I-1,1]:=ForStr[I];
    for I:=I+1 to S do Screen[Y,X+I-1,1]:=' ';
  end;


type
  QType            = (R10,R20,R30,W10,W20,W30,FOUL);

  TeamRec          = record
    TeamName       :   string[40];
    Coach          :   string[20];
    Mem            :   array[1..10] of string[20];
    W,L,T          :   byte;
    Per            :   real;
    Round          :   array[0..MaxRound] of record
      Entered      :     boolean;
      Opp          :     byte;
      Mem          :     array[1..10] of record
        Pt         :       array[Qtype] of byte;
        QO         :       boolean;
        Tot        :       integer;
                         end;
      FB           :     integer;
      Tot          :     integer;
                       end;
                     end;

  StringType       = string[255];

const
  PtVal : array[QType] of integer = (10,20,30,-5,-10,-15,-5);

var
  TournName        : string[40];
  Team             : array[1..MaxTeam] of TeamRec;
  ComLine          : string[80] absolute CSeg:$0080;
  Desc             : Text;
  DescName         : string[20];
  CurrTeam         : byte;
  CurrRound        : byte;
  I,J              : integer;


procedure LoadNames;

  var
    Line           : string[255];
    Count1,Count2  : integer;

  procedure Skip;
    begin
      while (Line='') and not EOF(Desc) do Readln(Desc,Line);
    end;

  begin
    Line:='';
    Assign(Desc,DescName+'.BQ');
    ReSet(Desc);
    if IOResult<>0 then begin
      Writeln('Name file not found.');
      Halt;
    end;
    Skip;
    TournName:=Line;
    Readln(Desc,Line);
    Count1:=1;
    while Line<>':END' do begin
      Readln(Desc,Line);
      Team[Count1].TeamName:=Copy(Line,1,40);
      Readln(Desc,Line);
      Team[Count1].Coach:=Copy(Line,2,21);
      Write(^M,'Loading ',Count1,' teams.');
      Count2:=1;
      repeat
        Readln(Desc,Line);
        if Line[1]<>':' then Team[Count1].Mem[Count2]:=Copy(Line,1,20);
        Count2:=Count2+1;
      until (Line='') or (Line[1]=':');
      Count1:=Count1+1;
    end;
    Writeln;
    NumTeam:=Count1-1;
    Line:='';
    Skip;
    Count1:=1;
    while Line<>':END' do begin
      while Line<>'' do begin
        while Line[1]=' ' do Line:=Copy(Line,2,Length(Line));
        Val(Line,I,Count2);
        if Count2>0 then Line:=Copy(Line,Count2+1,Length(Line)) else Line:='';
        while Line[1]=' ' do Line:=Copy(Line,2,Length(Line));
        Val(Line,J,Count2);
        if Count2>0 then Line:=Copy(Line,Count2+1,Length(Line)) else Line:='';
        Team[I].Round[Count1].Opp:=J;
        Team[J].Round[Count1].Opp:=I;
      end;
      Writeln('Loading ',Count1,' rounds.');
      Count1:=Count1+1;
      Readln(Desc,Line);
    end;
    NumRound:=Count1-1;
    Close(Desc);
  end;


var
  TeamStand        : boolean;
  IndivStand       : boolean;
  TeamStats        : boolean;
  TournStats       : boolean;
  WrFile           : boolean;
  Wr               : text;

procedure ReCalc(ForTeam : byte);

  var
    QCount         : QType;

  begin
    with Team[ForTeam] do begin
      W:=0; L:=0;
      for J:=1 to 10 do begin
        Round[0].Mem[J].Tot:=0;
        for QCount:=R10 to FOUL do Round[0].Mem[J].Pt[QCount]:=0;
      end;
      for I:=1 to NumRound do begin
        if Round[I].Tot<Team[Round[I].Opp].Round[I].Tot then L:=L+1;
        if Round[I].Tot>Team[Round[I].Opp].Round[I].Tot then W:=W+1;
        for J:=1 to 10 do begin
          Round[0].Mem[J].Tot:=Round[0].Mem[J].Tot+Round[I].Mem[J].Tot;
          for QCount:=R10 to FOUL do
            Round[0].Mem[J].Pt[QCount]:=Round[0].Mem[J].Pt[QCount]+Round[I].Mem[J].Pt[QCount];
        end;
      end;
    end;
  end;


procedure UsrOutRoutine(ForChr : char);

  begin
    Write(ForChr);
    if WrFile then Write(Wr,ForChr);
  end;

function FillName(ForStr : stringtype; Size : byte) : stringtype;

  begin
    while Length(ForStr)<Size do ForStr:=ForStr+' ';
    FillName:=ForStr;
  end;

procedure Report;

  var
    ToRound        : byte;

  procedure LstTeamStand;
    var
      TempPer      : array[1..MaxTeam] of real;
      Count        : byte;
      CurrPer      : real;
      MaxPer       : real;

    begin
      for I:=1 to NumTeam do with Team[I] do
        if W+L+T>0 then TempPer[I]:=(W*2+T)/(W+T+L) else TempPer[I]:=0;
      for I:=1 to NumTeam do begin
        Team[I].Per:=0; Count:=0;
        for J:=1 to NumRound do
          if Team[I].Round[J].Entered then begin
            Team[I].Per:=Team[I].Per+Team[Team[I].Round[J].Opp].Per;
            Count:=Count+1;
          end;
        if Count>0 then Team[I].Per:=(TempPer[I]*15.0+Team[I].Per/Count)/16.0;
      end;
      CurrPer:=1000;
      J:=1;
      ClrScr;
      Writeln(Usr,TournName);
      Writeln(Usr,'TEAM STANDINGS to ROUND ',ToRound,^J);
      Writeln(Usr,'    TEAM NAME                                RECORD    COACH');
      repeat
        MaxPer:=-1;
        Write(Usr,^M,J:3,'.');
        for I:=1 to NumTeam do begin
          if Team[I].Per=CurrPer then begin
            Write(Usr,FillName(Team[I].TeamName,40));
            Write(Usr,Team[I].W,'-',Team[I].L,'-',Team[I].T,'     ');
            Writeln(Usr,Team[I].Coach);
            Write(Usr,'    ');
            J:=J+1;
          end;
          if (Team[I].Per<CurrPer) and (Team[I].Per>MaxPer) then
            MaxPer:=Team[I].Per;
        end;
        CurrPer:=MaxPer;
      until CurrPer=-1;
      Write(Usr,^L);
      ReadKbd;
    end;

  procedure LstIndivid;
    var
      CurrSc       : integer;
      MaxSc        : integer;
      NumMem       : integer;

    begin
      CurrSc:=32767; NumMem:=1;
      ClrScr;
      Writeln(Usr,TournName);
      Writeln(Usr,'INDIVIDUAL STANDINGS to ROUND ',ToRound,^J);
      Writeln(Usr,'    NAME and SCORE');
      repeat
        MaxSc:=-32767;
        Write(Usr,^M,NumMem:3,'.');
        for I:=1 to NumTeam do begin
          J:=1;
          while Team[I].Mem[J]<>'' do with Team[I].Round[0].Mem[J] do begin
            if Tot=CurrSc then begin
              Writeln(Usr,Team[I].Mem[J],'  ',Tot);
              Write(Usr,'    ');
              NumMem:=NumMem+1;
            end;
            if (Tot<CurrSc) and (Tot>MaxSc) then MaxSc:=Tot;
            J:=J+1;
          end;
        end;
        CurrSc:=MaxSc;
      until MaxSc=-32767;
      Write(Usr,^L);
      ReadKbd;
    end;

  procedure LstTeamStat;
    var
      TeamCount    : byte;
      NumQO        : byte;

    begin
      TeamCount:=1;
      while TeamCount<=NumTeam do with Team[TeamCount] do begin
        Writeln(Usr,'TOURNAMENT STATISTICS');
        Writeln(Usr,TeamName);
        Writeln(Usr,' COACH  : ',Coach);
        Writeln(Usr,' RECORD : ',W,'-',L,'-',T);
        Writeln(Usr);
        Writeln('OPPONENT RECORDS :');
        for I:=1 to NumRound do with Team[Round[I].Opp] do begin
          Write(Usr,' ROUND',I:2,' : ',FillName(TeamName,45),W,'-',L,'-',T);
          if Round[I].Tot>Team[TeamCount].Round[I].Tot then Write(Usr,'  LOST ') else Write(Usr,'  WON ');
          Writeln(Usr,Team[TeamCount].Round[I].Tot,' to ',Round[I].Tot);
        end;
        Writeln(Usr);
        Writeln(Usr,'INDIVIDUAL STATISTICS :');
        I:=1;
        while Mem[I]<>'' do begin
          Writeln(Usr);
          Writeln(Usr,' ',I:2,'.',Mem[I]);
          Writeln(Usr,'   TOTAL POINTS SCORED : ',Round[0].Mem[I].Tot);
          NumQO:=0;
          Writeln(Usr,'     |    CORRECT   |   INCORRECT  |    |');
          Writeln(Usr,'     | 10 | 20 | 30 | 10 | 20 | 30 |FOUL| POINTS |');
          for J:=1 to NumRound do with Round[J].Mem[I] do begin
            if QO then NumQO:=NumQO+1;
            Writeln(Usr,J:4,' |',Pt[R10]:3,' |',Pt[R20]:3,' |',
              Pt[R30]:3,' |',Pt[W10]:3,' |',Pt[W20]:3,' |',
              Pt[W30]:3,' |',Pt[FOUL]:3,' |',Tot:5);
          end;
          with Round[0].Mem[I] do
            Writeln(Usr,'TOTAL|',Pt[R10]:3,' |',Pt[R20]:3,' |',
              Pt[R30]:3,' |',Pt[W10]:3,' |',Pt[W20]:3,' |',
              Pt[W30]:3,' |',Pt[FOUL]:3,' |',Tot:5);
          Writeln(Usr,^J,'   NUMBER OF QUIZ OUTS : ',NumQO);
          Writeln(Usr);
          I:=I+1;
        end;
        Write(Usr,^L);
        TeamCount:=TeamCount+1;
      end;
    end;

  procedure LstTourn;
    begin
    end;

  begin
    Window(1,1,80,24); ClrScr;
    TeamStand:=false;
    IndivStand:=false;
    TeamStats:=false;
    TournStats:=false;
    WrFile:=false;
    FillChar(TeamStand,6,0);
    Writeln('REPORT SELECTIONS : ');
    Writeln;
    Writeln('  F1 Team Standings');
    Writeln('  F2 Individual Standings');
    Writeln('  F3 Team Stats');
    Writeln('  F4 Tournament Stats');
    Writeln('  F5 Output to Printer');
    Writeln;
    Writeln('Press appropriate key to toggle selection');
    Writeln('Press <RETURN> to begin printing, or <ESC> to exit');
    repeat
      ReadKbd;
      GotoXY(1,Ord(Key)-59+3);
      case Key of
        #27 : Exit;
        ';' : if TeamStand then begin
                TeamStand:=false;
                Write(' ');
              end else begin
                TeamStand:=true;
                Write('*');
              end;
        '<' : if IndivStand then begin
                IndivStand:=false;
                Write(' ');
              end else begin
                IndivStand:=true;
                Write('*');
              end;
        '=' : if TeamStats then begin
                TeamStats:=false;
                Write(' ');
              end else begin
                TeamStats:=true;
                Write('*');
              end;
        '>' : if TournStats then begin
                TournStats:=false;
                Write(' ');
              end else begin
                TournStats:=true;
                Write('*');
              end;
        '?' : if WrFile then begin
                WrFile:=false;
                Write(' ');
              end else begin
                WrFile:=true;
                Write('*');
              end;
      end;
    until Key=#13;
    if WrFile then begin
      Assign(Wr,'OUTPUT');
      ReWrite(Wr);
    end;
    ToRound:=1;
    for I:=1 to NumRound do for J:=1 to NumTeam do
      if Team[J].Round[I].Entered then ToRound:=I;
    if TeamStand then LstTeamStand;
    if IndivStand then LstIndivid;
    if TeamStats then LstTeamStat;
    if TournStats then LstTourn;
    if WrFile then Close(Wr);
  end;


procedure Edit;

  var
    MemCount       : integer;
    PlaceCount     : QType;
    NewVal         : byte;
    StrA           : string[4];

  function QOut : boolean;
    var I : byte;
    begin
      with Team[CurrTeam].Round[CurrRound].Mem[MemCount] do begin
        I:=Pt[R10]+Pt[R20]+Pt[R30];
        if I>=6 then QOut:=true else QOut:=false;
        if I>6 then Write(^G);
        if Pt[W10]+Pt[W20]+Pt[W30]>3 then Write(^G);
      end;
    end;

  procedure WriteScore;

    begin
      with Team[CurrTeam].Round[CurrRound].Mem[MemCount] do begin
        if MemCount=0 then begin
          GotoXY(72,8);
          Write(Team[CurrTeam].Round[CurrRound].FB:4);
          Textbackground(Black);
          Exit;
        end;
        Tot:=Tot-PtVal[PlaceCount]*Pt[PlaceCount];
        Pt[PlaceCount]:=NewVal;
        if PlaceCount<=R30 then GotoXY(Ord(PlaceCount)*5+28,MemCount+9)
          else GotoXY(Ord(PlaceCount)*5+33,MemCount+9);
        Write(Team[CurrTeam].Round[CurrRound].Mem[MemCount].Pt[PlaceCount]:4);
        if QO then Tot:=Tot-10;
        QO:=QOut;
        if QO then Tot:=Tot+10;
        GotoXY(44,MemCount+9);
        TextBackground(Black);
        if QO then Write(' *') else Write('  ');
        Tot:=Tot+PtVal[PlaceCount]*Pt[PlaceCount];
        GotoXY(70,MemCount+9);
        Write(Tot:6);
      end;
    end;

  begin
    with Team[CurrTeam].Round[CurrRound] do begin
      Team[CurrTeam].Round[0].Tot:=Team[CurrTeam].Round[0].Tot-Tot;
      for I:=1 to 10 do
        Team[CurrTeam].Round[0].Mem[I].Tot:=
        Team[CurrTeam].Round[0].Mem[I].Tot-Mem[I].Tot;
      if Opp<>0 then I:=Team[Opp].Round[CurrRound].Tot
        else I:=Tot;
      if Entered then with Team[CurrTeam] do
        if I<Tot then begin
          W:=W-1;
          Team[Opp].L:=Team[Opp].L-1;
        end
        else
          if I>Tot then begin
            L:=L-1;
            Team[Opp].W:=Team[Opp].W-1;
          end
          else
            begin
              T:=T-1;
              Team[Opp].T:=Team[Opp].T-1;
            end;
      CurrWind:=Addr(EditSize);
      ShowWind;
      MemCount:=1;
      WriteScreen(Team[CurrTeam].TeamName,3,2,40);
      GotoXY(70,2);
      Write(CurrRound:3);
      GotoXY(70,21); Write(Tot:6);
      MemCount:=0; WriteScore;
      MemCount:=1;
      while Team[CurrTeam].Mem[MemCount]<>'' do begin
        GotoXY(5,MemCount+9);
        Write(Team[CurrTeam].Mem[MemCount]);
        for PlaceCount:=R10 to Foul do begin
          NewVal:=Mem[MemCount].Pt[PlaceCount];
          WriteScore;
        end;
        MemCount:=MemCount+1;
      end;
      if CurrRound=0 then begin
        ReadKbd;
        Exit;
      end;
      MemCount:=0; PlaceCount:=QType(6);
      repeat
        TextBackground(BC);
        NewVal:=Mem[MemCount].Pt[PlaceCount];
        WriteScore;
        ReadKbd;
        WriteScore;
        case Key of
          #75 : if PlaceCount>QType(0) then PlaceCount:=Pred(PlaceCount);
          #77 : if PlaceCount<QType(6) then PlaceCount:=Succ(PlaceCount);
          #72 : if MemCount>0 then MemCount:=MemCount-1;
          #80 : if Team[CurrTeam].Mem[MemCount+1]<>'' then MemCount:=MemCount+1;
          'e' : begin
                  Entered:=false;
                  Team[Opp].Round[CurrRound].Entered:=false;
                end;
          ^H  : if PlaceCount>QType(0) then PlaceCount:=Pred(PlaceCount);
          #13 : PlaceCount:=QType(6);
          '0'..'9','-' : begin
                  Entered:=true;
                  Team[Opp].Round[CurrRound].Entered:=true;
                  if MemCount>0 then begin
                    Tot:=Tot-Mem[MemCount].Tot;
                    NewVal:=Ord(Key)-48;
                    WriteScore;
                    Tot:=Tot+Mem[MemCount].Tot;
                  end
                  else begin
                    Tot:=Tot-FB;
                    GotoXY(72,8);
                    TextBackground(BC);
                    Write(Key); StrA[4]:=Key;
                    BufLen:=3;
                    Read(StrA);
                    StrA:=StrA[4]+StrA;
                    Val(StrA,FB,I);
                    TextBackground(Black);
                    Tot:=Tot+FB;
                    WriteScore;
                  end;
                  GotoXY(70,21); Write(Tot:6);
                  Key:=#13;
                end;
        end;
        if Key=#13 then
          if PlaceCount<QType(6) then PlaceCount:=Succ(PlaceCount)
            else if Team[CurrTeam].Mem[MemCount+1]<>'' then begin
              MemCount:=MemCount+1;
              PlaceCount:=QType(0);
            end else Key:=';';
      until Key in [';'..'D'];
      Team[CurrTeam].Round[0].Tot:=Team[CurrTeam].Round[0].Tot+Tot;
      for I:=1 to 10 do
        Team[CurrTeam].Round[0].Mem[I].Tot:=
        Team[CurrTeam].Round[0].Mem[I].Tot+Mem[I].Tot;
      if Opp<>0 then I:=Team[Opp].Round[CurrRound].Tot
        else I:=Tot;
      if Entered then with Team[CurrTeam] do
        if I<Tot then begin
          W:=W+1;
          Team[Opp].L:=Team[Opp].L+1;
        end
        else
          if I>Tot then begin
            L:=L+1;
            Team[Opp].W:=Team[Opp].W+1;
          end
          else
            begin
              T:=T+1;
              Team[Opp].T:=Team[Opp].T+1;
            end;
    end;
  end;


procedure Browse;

  procedure ShowStats;

    var
      MemCount     : byte;
      StrA         : string[3];
      StrB         : string[8];

    begin
      with Team[CurrTeam] do begin
        TextBackground(Black);
        WriteScreen(Copy(TeamName,1,30),47,2,30);
        WriteScreen(Coach,57,4,20);
        Window(49,6,77,15); ClrScr;
        MemCount:=1;
        while (MemCount<=10) and (Mem[MemCount]<>'') do begin
          WriteScreen(Mem[MemCount],49,MemCount+5,26);
          Str(Round[CurrRound].Mem[MemCount].Tot:3,StrA);
          WriteScreen(StrA,73,MemCount+5,3);
          MemCount:=MemCount+1;
        end;
        Str(Round[CurrRound].FB:3,StrA);
        WriteScreen(StrA,73,16,3);
        Str(Round[CurrRound].Tot:3,StrA);
        WriteScreen(StrA,73,18,3);
        if (Round[CurrRound].Opp<>0) and (CurrRound<>0) then
          Str(Team[Round[CurrRound].Opp].Round[CurrRound].Tot:3,StrA)
          else StrA:='';
        WriteScreen(StrA,73,19,3);
        Str(W,StrA); StrB:=StrA+'-';
        Str(L,StrA); StrB:=StrB+StrA+'-';
        Str(T,StrA); StrB:=StrB+StrA;
        WriteScreen(StrB,70,20,8);
        if Round[CurrRound].Opp<>0 then
          WriteScreen(Copy(Team[Round[CurrRound].Opp].TeamName,1,30),47,23,30)
          else
            if CurrRound<>0 then WriteScreen(' BUY',47,23,30)
              else WriteScreen(' ',47,23,30);
      end;
    end;

  procedure WrRound(Color : Byte);

    begin
      TextBackground(Color);
      GotoXY(CurrRound*3+9,20);
      if CurrRound>0 then Write(CurrRound:3) else Write('TOT');
      TextBackground(Black);
    end;

  begin
    CurrWind:=Addr(BrowseSize);
    ShowWind;
    GotoXY(3,2); Write(TournName);
    Window(2,4,43,23); GotoXY(1,1);
    for I:=1 to NumTeam do begin
      Writeln(Team[I].TeamName);
    end;
    J:=CurrRound;
    for CurrRound:=0 to NumRound do WrRound(Black);
    CurrRound:=J;
    WrRound(BC);
    repeat
      GotoXY(1,CurrTeam);
      TextBackground(BC);
      Write(Team[CurrTeam].TeamName); ClrEol;
      TextBackground(Black);
      if not KeyPressed then ShowStats;
      Window(2,4,43,23);
      ReadKbd;
      GotoXY(1,CurrTeam);
      Write(Team[CurrTeam].TeamName); ClrEol;
      case Key of
        #80 : if CurrTeam<NumTeam then CurrTeam:=CurrTeam+1;
        #72 : if CurrTeam>1 then CurrTeam:=CurrTeam-1;
        #77 : if CurrRound<NumRound then begin
                WrRound(Black);
                CurrRound:=CurrRound+1;
                WrRound(BC);
              end;
        #75 : if CurrRound>0 then begin
                WrRound(Black);
                CurrRound:=CurrRound-1;
                WrRound(BC);
              end;
        ' ' : if Team[CurrTeam].Round[CurrRound].Opp in [1..NumTeam] then
                CurrTeam:=Team[CurrTeam].Round[CurrRound].Opp;
      end;
    until Key in [';'..'D'];
  end;


var
  DataFile         : file of TeamRec;
  TFile            : file of char;
  AChar            : char;

procedure LoadData;

  begin
    Assign(DataFile,DescName+'.DAT');
    ReSet(DataFile);
    if IOResult<>0 then begin
      FillChar(Team,SizeOf(Team),0);
      LoadNames;
      Exit;
    end;
    I:=0;
    repeat
      I:=I+1;
      Read(DataFile,Team[I]);
      Write('Loading ',I,' teams.',^M);
    until Team[I].TeamName[0]>=Chr(128);
    Writeln;
    Team[I].TeamName[0]:=Chr(Ord(Team[I].TeamName[0])-128);
    NumTeam:=I;
    Close(DataFile);
    Assign(TFile,DescName+'.DAT');
    ReSet(TFile);
    Seek(TFile,NumTeam*SizeOf(TeamRec)+1);
    TournName:='';
    repeat
      Read(TFile,AChar);
      TournName:=TournName+AChar;
    until AChar=#0;
    Close(TFile);
  end;


procedure SaveData;

  begin
    Assign(DataFile,DescName+'.DAT');
    ReWrite(DataFile);
    Window(1,1,80,25); GotoXY(1,25); Writeln;
    Team[NumTeam].TeamName[0]:=Chr(Ord(Team[NumTeam].TeamName[0])+128);
    for I:=1 to NumTeam do begin
      Write(DataFile,Team[I]);
      Write(^M,'Saving ',I,' teams.');
    end;
    Team[NumTeam].TeamName[0]:=Chr(Ord(Team[NumTeam].TeamName[0])-128);
    Close(DataFile);
    Assign(TFile,DescName+'.DAT');
    Reset(TFile);
    Seek(TFile,NumTeam*SizeOf(TeamRec)+1);
    TournName[Length(TournName)+1]:=#0;
    for I:=1 to Length(TournName)+1 do Write(TFile,TournName[I]);
    Close(TFile);
  end;



begin
  DescName:=ComLine;
  while DescName[1]=' ' do DescName:=Copy(DescName,2,Length(DescName));
  LoadData;
  TextColor(MC);
  ClrScr;
  GotoXY(1,25);
  Write('F1 BROWSE      F2 SCORES      F3 REPORT      F4 RELOAD NAMES');
  Key:=';';
  UsrOutPtr:=Ofs(UsrOutRoutine);
  CurrTeam:=1; CurrRound:=1;
  repeat
    case Key of
      ';' : begin
              GotoXY(1,25);
              TextBackground(BC);
              Write('F1 BROWSE');
              TextBackground(Black);
              Browse;
              Window(1,1,80,25);
              GotoXY(1,25);
              Write('F1 BROWSE');
            end;
      '<' : begin
              GotoXY(16,25);
              TextBackground(BC);
              Write('F2 SCORES');
              TextBackground(Black);
              Edit;
              Window(1,1,80,25);
              GotoXY(16,25);
              Write('F2 SCORES');
            end;
      '=' : begin
              GotoXY(31,25);
              TextBackground(BC);
              Write('F3 REPORT');
              TextBackground(Black);
              Report;
              Window(1,1,80,25);
              GotoXY(31,25);
              Write('F3 REPORT');
            end;
      '>' : begin
              GotoXY(46,25);
              TextBackground(BC);
              Write('F4 RELOAD NAMES');
              TextBackground(Black);
              LoadNames;
              Key:=';';
              Window(1,1,80,25);
              GotoXY(46,25);
              Write('F4 RELOAD NAMES');
            end;
      '?' : begin
              ReCalc(CurrTeam);
              Key:=';';
            end;
      else Key:=';';
    end;
  until Key='D';
  SaveData;
end.