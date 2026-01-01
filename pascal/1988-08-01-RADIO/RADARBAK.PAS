{.HE%F - %D update}
{.FOpage %#}
{.LW79}
{.N+}
{$C-,V-,I-,R-,U-,K-}

Program Radar_Terminal;

type
  TiltType         = 0..11;
  RangeType        = 0..4;
  GainType         = 1..17;

  LineType         = string[80];

  Gen8Type         = array[1..8] of byte;

  ModeType         = (Modem,Interactive,WaitPic,RxPic,RxGraph);

  BufType          = array[1..2000] of byte;

  TimeRec          = record
    Year           :   1980..2099;
    Month          :   1..12;
    Day            :   1..31;
    Hour           :   0..23;
    Minute         :   0..59;
                     end;

  RegisterType     = record
    case integer of
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : integer);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;


const
  DirPath          : string[24] = '';
  ModemType        : byte = 0;
  ComPort          : integer = $2F8;
  Printer          : byte = 0;
  Clock            : byte = 0;

  OnOff            = #1;
  SendPic          = #4;
  CheckGraph       = #16;
  SendGraph        = #10;
  TiltUp           = #2;
  TiltDown         = #5;
  RangeUp          = #3;
  RangeDown        = #6;
  GainUp           = #13;
  GainDown         = #14;

  TiltVal          : array[TiltType] of byte =
                       (0,1,2,3,4,5,6,8,10,12,15,20);
  RangeVal         : array[RangeType] of byte =
                       (10,25,50,100,200);


type
  PicRec           = record
    FileName       :   string[12];
    FileDate,
    FileTime       :   integer;
    Time           :   TimeRec;
    Tilt           :   TiltType;
    Range          :   RangeType;
    Gain           :   GainType;
                     end;

var
  StationName      : string[12];
  Pic              : array[0..100] of PicRec;
  CurrPic, MaxPic  : integer;
  RT               : byte;

var
  Mode             : ModeType;

{Mode Flags}
  ErrorFlag        : boolean;
  GraphicsOn       : boolean;
  OldCon           : integer;

{Miscellaneous Variables}
  Registers        : RegisterType;
  Key              : char;
  DTA              : array[0..127] of byte;
  Escape           : boolean;
  I,J              : integer;
  Map1             : array[1..512,1..8] of byte;
  Map2             : array[1..512,1..8] of byte;
  Map1Size         : integer;

{$I MISC.RDR}

{$I GRAPH.RDR}

{$I SCREEN.RDR}

function IOError : boolean;
  var
    Dummy : integer;
  begin
    Dummy:=IOResult;
    if Dummy=0 then begin
      IOError:=false;
    end else begin
      case Dummy of
        $99 : GRMessage('ERROR : Unexpected end of file',true);
        $F0 : GRMessage('ERROR : Disk is full',true);
        $F1 : GRMessage('ERROR : Directory is full',true);
        $F2 : GRMessage('ERROR : File is too big',true);
        $FF : GRMessage('ERROR : Disk changed. Please replace and retry.',true);
      end;
      IOError:=true;
    end;
  end;


{.PA}
{*****************************************************************************}
{* RS232 Routines                                                            *}
{*****************************************************************************}
var
  Buf              : LineType;
  CheckSum         : byte;
  DSave            : integer absolute CSeg:$0006;
  GRBuf            : array[1..1250] of byte;
  LineNum          : integer absolute GRBuf;
  PhoneNum         : string[31];
  POver            : array[1..4] of Gen8Type absolute PhoneNum;
  MapCount         : byte;
  Response         : boolean;
  GfxMatch         : boolean;
  LineAt,WriteAt   : integer;
  BufPtr           : ^BufType;
  BufCount         : integer;
  GRSize           : integer;
  PicSave          : array[-20000..30000] of byte;
  PicSaveAt        : integer;

procedure HangUp;

  begin
{    Port[ComPort+4]:=$08; Delay(1000); Port[ComPort+4]:=$0B;}
  end;

procedure Tx(Charac : char);
  begin
    repeat until (port[ComPort+5] and $20)=$20;
    Port[ComPort]:=ord(Charac);
  end;

procedure SendCom(Command : char; DelTime : integer);
  var
    StartTime, CurrTime : integer;
  begin
    if Mode=Interactive then begin
      Buf:=''; Response:=false;
      Tx('Z'); Delay(15); Tx(Command);
      if (RT=0) and not(Command=SendGraph) then Delay(1000);
      with Registers do begin
        AH:=$2C;
        MsDos(Registers);
        StartTime:=DH*100+DL;
        repeat
          AH:=$2C;
          MsDos(Registers);
          CurrTime:=DH*100+DL;
          IF CurrTime<StartTime THEN CurrTime:=CurrTime+6000;
        until (CurrTime-StartTime>DelTime) OR Response;
      end; (* with *)
      if Command=SendGraph then Mode:=RxGraph;
      if Response then WriteParams
      else begin
        Sound(440); Delay(10); NoSound;
      end;
    end;
  end;

procedure SetParams(var ForBuf; var Params : PicRec);
  var
    Buf            : string[10] absolute ForBuf;
    Comp           : Gen8Type absolute Map1;
  begin
    CheckSum:=0;
    for I:=2 to 9 do CheckSum:=CheckSum+Ord(Buf[I]);
    Response:=CheckSum=Ord(Buf[10]);
    if (Buf[1]='Q') and Response then
      with Params do begin
        Gain:=(byte(Buf[2]) shr 4) +1;
        Tilt:=12-(byte(Buf[3]) and $0f);
        If (byte(Buf[3]) and (1 shl 5)) <> 0
          then Gain := 17;
        case (byte(Buf[4]) and $38) of
          $08 : Range:=1;
          $30 : Range:=2;
          $00 : Range:=3;
          $20 : Range:=4;
          $28 : Range:=0;
        end;
        Time.Hour:=(ord(Buf[6])-48)*10+(ord(Buf[7])-48);
        Time.Minute:=(ord(Buf[8])-48)*10+(ord(Buf[9])-48);
        if (byte(Buf[3]) and $80)=$00 then RT:=2
          else if (byte(Buf[3]) and $10)=$00 then RT:=0
            else RT:=1;
      end;
    if (Buf[1]='G') and Response then begin
      I:=2;
      while (Comp[I-1]=Ord(Buf[I])) and (I<9) do I:=I+1;
      GfxMatch:=not(I<9);
    end;
    Buf:='';
  end;


var
  MessReady        : string[5];
  data             : byte;
  RI               : integer;

procedure RS232Interupt;
  begin
    inline($1E/       {PUSH DS}
           $50/       {PUSH AX}
           $53/       {PUSH BX}
           $51/       {PUSH CX}
           $52/       {PUSH DX}
           $57/       {PUSH DI}
           $56/       {PUSH SI}
           $06/       {PUSH ES}
           $8C/$C8/   {MOV AX,CS}
           $8E/$D8/   {MOV DS,AX}
           $A1/DSave/ {MOV AX,DSave}
           $8E/$D8/$FB);  {MOV DS,AX}
    Write('O');
    if port[ComPort+2]=$04 then begin
      data:=port[ComPort];
      Write('X');
      port[$20]:=$20; {EOI for 8529}
      case Mode of
        Modem :
        begin
          Buf:=Buf+chr(data);
          if (Buf[Length(Buf)]=#13) then begin
            MessReady:=Buf;
            Buf:='';
          end;
        end;
        Interactive,WaitPic :
        begin
          Buf:=Buf+chr(data);
          GotoXY(0,10); Write(Buf);
          if Length(Buf)=10 then begin
            SetParams(Buf,Pic[CurrPic]);
            Delay(10);
            Tx('A');
            Buf:='';
          end;
          if Mode=WaitPic then
            if (Buf[1]=#$FF) and (Buf[2]=#$FE) and (Buf[3]=#$FD) then begin
              Mode:=RxPic; GRSize:=0;
              CheckSum:=0;
            end;
        end;
        RxPic :
        begin
          GRSize:=GRSize+1;
          GRBuf[GRSize]:=data;
          if (GRSize and $01)=$01 then
          if (GRBuf[GRSize-1]=$18) and
            (GRBuf[GRSize-2]=$18) and (GRSize>6) then begin
            CheckSum:=0;
            for RI:=1 to GRSize-1 do CheckSum:=CheckSum+GRBuf[RI];
            LineNum:=LineNum div 54;
            if (LineNum>=LastLine) and (LineNum<=352)
              and (CheckSum=GRBuf[GRSize]) then begin
              Tx('A');
              Move(GRBuf,PicSave[PicSaveAt],GRSize-1);
              LineAt:=PicSaveAt;
              PicSaveAt:=PicSaveAt+GRSize-1;
              Tx('O');
              GRSize:=0;
            end else begin
              Tx(#0);
              GRSize:=0;
            end;
          end;
        end;
        RxGraph :
        begin
          BufPtr^[BufCount]:=data; BufCount:=BufCount+1;
          if BufCount=9 then begin
            CheckSum:=0;
            for RI:=1 to 8 do CheckSum:=CheckSum+BufPtr^[RI];
            if {CheckSum=BufPtr^[BufCount]}true then begin
              if (BufPtr^[1]=0) and (BufPtr^[2]=0) and
                (BufPtr^[3]=0) and (BufPtr^[4]=0) then
              begin
                Sound(440); Delay(100); NoSound;
                MapCount:=MapCount+1;
                if MapCount=2 then begin
                  Map1Size:=OFS(BufPtr^)-OFS(Map1);
                  BufPtr:=Ptr(Seg(Map2),Ofs(Map2)-8);
                end;
              end;
              if Ofs(BufPtr^)<Ofs(Map1Size)-16 then
                BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+8);
              BufCount:=1;
              Delay(5);
              Tx('A');
            end else Tx(#0);
            BufCount:=1;
          end;
        end;
      end; (* case *)
    end; (* if *)
{    else begin
      if port[ComPort+2]=$00 then
        if (port[ComPort+6] and $88)=$08 then
          Mode:=Modem;
      port[$20]:=$20; {EOI for 8529}
{    end;}
    inline($07/       {POP ES}
           $5E/       {POP SI}
           $5F/       {POP DI}
           $5A/       {POP DX}
           $59/       {POP CX}
           $5B/       {POP BX}
           $58/       {POP AX}
           $1F);      {POP DS}
    inline($FB);      {STI}
    inline($CF);      {IRET}
  end;

procedure InitRS232; {& interrupt routine}
  begin
    DSave:=DSeg; Buf:='';
    with Registers do begin
      AH:=$25;
      if ComPort=$3F8 then AL:=$0C else AL:=$0B;
      DX:=Ofs(RS232Interupt)+7;
      DS:=CSeg;
      Intr($21,Registers);
    end;
    for I:=ComPort to ComPort+6 do J:=port[I];
    Port[ComPort+3]:=$80; {Set baud rate access bit}
    Port[ComPort]:= 48; {Set baud rate (2400 = 48)}
    Port[ComPort+1]:=$00;
    Port[ComPort+3]:=$03; {Set Line Control Data (8 data,1 stop,0 parity)}
    Port[ComPort+1]:=$09;
    Port[ComPort+4]:=$0B; {Set DTR & RTS high}
    UsrOutPtr:=Ofs(Tx);
  end;


{.PA}
{*****************************************************************************}
{* Storage                                                                   *}
{*****************************************************************************}
procedure FetchPic;
  var PicFile      : file;
  begin
    WriteParams;
    if CurrPic=0 then begin
      SelectPlane([0,1]);
      ClearScreen;
      EXIT;
    end;
    if Gfx1On or Gfx2On then begin
      SelectPlane([2]);
      ClearScreen;
      if Gfx1On then WriteGfx(Map1);
      if Gfx2On then WriteGfx(Map2);
      if RngMksOn then WriteRngMks;
    end;
    Assign(PicFile,Pic[CurrPic].FileName);
    ReSet(PicFile,1);
    if IOError then GRMessage('ERROR : Cannot find that picture file',true)
    else begin
      BlockRead(PicFile,PicSave,FileSize(PicFile)+1,I);
      BufPtr:=ADDR(PicSave); LastLine:=0;
      while (LastLine<351) do begin
        DispLine(BufPtr^);
        BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+LineSize);
      end;
      Close(PicFile);
    end;
  end;

procedure InsertPic(ForPic : PicRec);
var
  Count : integer;
  Later : boolean;
begin
  Count:=0; Later:=false;
  repeat
    Count:=Count+1;
    if Pic[Count].FileDate>ForPic.FileDate then
      Later:=true
    else if Pic[Count].FileDate=ForPic.FileDate then
      if Pic[Count].FileTime>ForPic.FileTime then
        Later:=true;
  until Later or (Count>MaxPic);
end;

procedure SavePic(Size : integer);
  var PicFile      : file;
  begin
    with Pic[CurrPic] do begin
      FileName[0]:=Chr(7);
      FileName[1]:=Chr(Time.Hour div 10+48);
      FileName[2]:=Chr(Time.Hour mod 10+48);
      FileName[3]:=Chr(Time.Minute div 10+48);
      FileName[4]:=Chr(Time.Minute mod 10+48);
      FileName[5]:=Chr(Tilt+65);
      FileName[6]:=Chr(Range+65);
      FileName[7]:=Chr(Gain+64);
      FileName:=FileName+'.PIC';
      Assign(PicFile,FileName);
      ReWrite(PicFile,1); if IOError then Exit;
      BlockWrite(PicFile,PicSave,Size); if IOError then Exit;
      Close(PicFile);
      GRMessage('',false);
    end;
  end;


procedure Storage;
  var
    SelectPic,
    TopPic     : integer;
    Count      : integer;
    PicFile    : file;
  begin
    Window(27,1,25,21);
    Write('ออออออออ STORAGE อออออออออ');
    Write('  ๚Time๚ ๚Tilt๚Range๚Gain๚');
    GotoXY(0,18);
    Write('ออออออออออออออออออออออออออ');
    Writeln(' RET ๚ Select Picture');
    Writeln(' F1  ๚ Delete Picture');
    Writeln(' ESC ๚ Exit');
    SelectPic:=CurrPic;
    TopPic:=MaxPic+1;
    repeat
      if (SelectPic<TopPic) or (SelectPic>TopPic+15) then begin
        if SelectPic<=8 then TopPic:=1 else TopPic:=SelectPic-8;
        GotoXY(0,2);
        for Count:=TopPic to TopPic+15 do
          if Count<=MaxPic then with Pic[Count] do begin
            Write('  ');
            WriteTime(Time);
            Write(TiltVal[Tilt]:4);
            Write(RangeVal[Range]:6);
            if Gain<17 then Write(Gain:5) else Write('  PRE');
            WriteLn;
          end else WriteLn('                        ');
      end;
      GotoXY(0,SelectPic-TopPic+2);
      if SelectPic<>0 then Write('->');
      ReadKbd;
      case Key of
        '+' : if SelectPic<MaxPic then SelectPic:=SelectPic+1;
        '-' : if SelectPic>0 then SelectPic:=SelectPic-1;
        ';' : if SelectPic>0 then if Ask('DELETE THIS PICTURE?') then begin
                Assign(PicFile,Pic[SelectPic].FileName);
                Erase(PicFile);
                for Count:=SelectPic+1 to MaxPic do Pic[Count-1]:=Pic[Count];
                TopPic:=MaxPic+1;
                MaxPic:=MaxPic-1;
              end;
      end;
      Write(^M,'  ');
    until (Key=^[) or (Key=^M);
    UnWindow;
    if Key=^M then begin
      CurrPic:=SelectPic;
      FetchPic;
    end;
    Key:=#0;
  end;

procedure LoadStation;
  var
    MapFile        : file;
    PhoneFile      : text;
    PicName        : string[20];
    PicVal         : array[0..7] of byte absolute PicName;
  begin
    ChDir(StationName); if IOError then Exit;
    SelectPlane([2]);
    GotoXY(68,21); Write(StationName:12);
    Assign(PhoneFile,'PHONENUM.TXT');
    ReSet(PhoneFile);
    if IOError then
      GRMessage('WARNING : No phone number found for '+StationName+'.',true)
    else begin
      Readln(PhoneFile,PhoneNum);
      Close(PhoneFile); if IOError then Exit;
    end;
    Assign(MapFile,'MAP1.DAT');
    Reset(MapFile);
    if IOError then
      GRMessage('WARNING : No map found for '+StationName+'.',true)
    else begin
      BlockRead(MapFile,Map1,FileSize(MapFile));
      Close(MapFile);
    end;
    Assign(MapFile,'MAP2.DAT');
    Reset(MapFile);
    if not IOError then begin
      BlockRead(MapFile,Map2,FileSize(MapFile));
      Close(MapFile);
    end;
    SetDir('????????.PIC'+#0,$00);
    MaxPic:=0;
    while not ErrorFlag do begin
      MaxPic:=MaxPic+1;
      PicName:=DirEntry;
      with Pic[MaxPic] do begin
        FileName:=PicName;
        Time.Hour:=(PicVal[1]-48)*10+PicVal[2]-48;
        Time.Minute:=(PicVal[3]-48)*10+PicVal[4]-48;
        Tilt:=PicVal[5]-65; Range:=PicVal[6]-65;
        Gain:=PicVal[7]-64;
      end;
    end;
    CurrPic:=0;
  end;

procedure CallStation;
  begin
    if PhoneNum<>'' then begin
      case ModemType of
        0 : begin
              GRMessage('DIALING - '+PhoneNum,false);
              Mode:=Modem;
              Writeln(Usr,'ATDT',PhoneNum);
            end;
        1 : begin
              Write(Usr,^E,^M,^E,^M); Delay(50);
              Write(Usr,'D',PhoneNum,^M);
            end;
      end;
      Buf:=''; MessReady:='';
      repeat
        if MessReady<>'' then begin
          case MessReady[1] of
            '1','L' : GRMessage('CONNECTED AT 2400 BAUD',false);
            '3'     : GRMessage('NO CARRIER',false);
            '4','C' : GRMessage('MODEM ERROR',false);
            '6','E' : GRMessage('NO DIAL TONE',false);
            '7','B' : GRMessage('BUSY!',false);
            '8','F' : GRMessage('NO ANSWER',false);
            'T'     : GRMessage('TIME OUT',false);
            'A'     : GRMessage('ANSWER TONE - '+PhoneNum,false);
            'D'     : GRMessage('DIALING - '+PhoneNum,false);
            'R'     : GRMessage('RINGING - '+PhoneNum,false);
            else MessReady:='';
          end;
          if MessReady[1] in ['A','D','R'] then MessReady:=#0;
        end;
      until (MessReady<>'') or KeyPressed;
      if MessReady[1] in ['1','L'] then Mode:=Interactive
      else begin
        ReadKbd; GRMessage('',false); HangUp;
      end;
    end else Mode:=Interactive;
  end;

var
  StatChar       : char;
  MaxChar        : char;
  Stat           : array['A'..'M'] of string[12];

procedure SelectStation;

  procedure AddStation;
    var
      PhoneFile : text;
      NewName   : string[12];
      NewPhone  : string[50];
    begin
      GotoXY(0,12);
      Write(' NAME :           ');
      GotoXY(8,12);
      NewName:=ReadStr(8)+'.STA';
      if NewName='' then Exit;
      Writeln(^M,' PHONE NUM :      ');
      NewPhone:=ReadStr(40);
      MkDir(NewName);
      if IOResult=0 then begin
        ChDir(NewName);
        Assign(PhoneFile,'PHONENUM.TXT');
        ReWrite(PhoneFile);
        if IOResult=0 then begin
          Writeln(PhoneFile,NewPhone);
          Close(PhoneFile);
        end;
        ChDir('..');
      end else begin
        GRMessage('UNABLE TO CREATE DIRECTORY',true);
      end;
    end;

  procedure DelStation;
    var
      DelFile : file;
      StatKey : char;
    begin
      GRMessage('STATION LETTER TO DELETE?',true);
      StatKey:=UpCase(Key);
      if (StatKey>='A') and (StatKey<=MaxChar) then
        if Ask('DELETE '+Stat[StatKey]+'. CONTINUE') then begin
          GRMessage('DELETING STATION '+Stat[StatKey],false);
          ChDir(Stat[StatKey]);
          if IOResult<>0 then Exit;
          SetDir('????????.???'+#0,$00);
          while not ErrorFlag do begin
            Assign(DelFile,DirEntry);
            Erase(DelFile);
          end;
          ChDir('..');
          RmDir(Stat[StatKey]);
          GRMessage('',false);
        end;
    end;

  begin
    if StationName<>'' then ChDir('..');
    repeat
      Window(27,1,25,14);
      GotoXY(0,0);
      Write('อออออ SELECT STATION อออออ');
      StatChar:='A'; SetDir('????????.STA'+#0,$10);
      while not ErrorFlag do begin
        Stat[StatChar]:=DirEntry;
        Writeln(' ',StatChar,' ๚ ',Stat[StatChar]:12);
        StatChar:=Succ(StatChar);
      end;
      MaxChar:=Pred(StatChar);
      GotoXY(0,11);
      Write('ออออออออออออออออออออออออออ');
      Writeln(' F1  ๚ Add station');
      Writeln(' F2  ๚ Remove station');
      Writeln(' ESC ๚ Exit');
      ReadKbd; Key:=UpCase(Key);
      if Escape then begin
        case Key of
          ';' : AddStation;
          '<' : DelStation;
        end;
        Key:=#0;
      end;
    until Key in [^[,'A'..'M'];
    UnWindow;
    if (Key>='A') and (Key<=MaxChar) then begin
      Gfx1On:=false; Gfx2On:=false;
      RngMksOn:=false;
      SelectPlane([0..3]); ClearScreen;
      StationName:=Stat[Key];
      LoadStation;
      FetchPic;
    end else if StationName<>'' then ChDir(StationName);
    Key:=#0;
  end;


{$I RADIO.PAS}

{.PA}
{*****************************************************************************}
{* Screen Dump                                                               *}
{*****************************************************************************}
var
  PrData           : array[0..79,0..2] of byte;
  PrI,PrJ,PrK      : integer;
  PrQ,RemCount     : byte;
  OldPrtScSeg,
  OldPrtScOfs      : integer;
procedure ColorJetPrtSc;
  label
    AbortPrtSc;
  begin
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    RemCount:=0;
    for PrI:=0 to 359 do begin
      for PrJ:=0 to 79 do begin
        if KeyPressed then begin
          ReadKbd;
          if Ask('ABORT SCREEN DUMP') then goto AbortPrtSc;
        end;
        for PrQ:=0 to 2 do begin
          port[$3CE]:=$04; port[$3CF]:=PrQ;
          PrData[PrJ,PrQ]:=Mem[$A000:PrI*80+PrJ];
        end;
        PrQ:=not(PrData[PrJ,0] or PrData[PrJ,1] or PrData[PrJ,2]);
        PrData[PrJ,2]:=not(PrData[PrJ,2]) or PrQ;
        PrData[PrJ,0]:=PrData[PrJ,0] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,1]:=PrData[PrJ,1] and PrData[PrJ,2] or PrQ;
        PrData[PrJ,2]:=PrQ;
      end;
      repeat
        if RemCount>=48 then RemCount:=RemCount-48;
        Write(Lst,Chr($1B),Chr($5B),Chr($4F),Chr(245),Chr(0));
        Write(Lst,Chr($80),Chr($1F),Chr($00),Chr(100),Chr(96));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,0]));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,1]));
        for PrJ:=0 to 79 do Write(Lst,Chr(PrData[PrJ,2]));
        Write(Lst,#0);
        RemCount:=RemCount+13;
      until RemCount<48;
    end;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  end;

const
  Pat : array[0..1,1..3] of byte = (($22,$55,$FF),($88,$AA,$FF));

var
  PrGrn,PrYel,PrRed,PrWhite : byte;

procedure EpsonMX80PrtSc;
  label
    AbortPrtSc;
  begin
    inline($FB/$1E/$50/$53/$51/$52/$57/$56/$06/
           $8C/$C8/$8E/$D8/$A1/DSave/$8E/$D8);
    Write(Lst,#27,#65,#8,#27,#50);
    port[$3CE]:=$05; port[$3CF]:=$08;
    for PrI:=0 to 79 do begin
      Write(Lst,#27,'K',#224,#1);
      RemCount:=0; PrJ:=349;
      for PrK:=0 to 479 do begin
        if KeyPressed then begin
          ReadKbd;
          if Ask('ABORT SCREEN DUMP') then goto AbortPrtSc;
        end;
        port[$3CE]:=$07; port[$3CF]:=$0F;
        port[$3CE]:=$02; port[$3CF]:=$01; PrRed:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$02; port[$3CF]:=$03; PrYel:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$02; port[$3CF]:=$02; PrGrn:=Mem[$A000:PrJ*80+PrI];
        port[$3CE]:=$07; port[$3CF]:=$0C;
        port[$3CE]:=$02; port[$3CF]:=$04; PrWhite:=Mem[$A000:PrJ*80+PrI];
        Write(Lst,CHR((PrGrn and Pat[PrK and 1,1])
                   or (PrYel and Pat[PrK and 1,2])
                   or (PrRed) xor PrWhite));
        RemCount:=RemCount+1;
        if RemCount>=8 then RemCount:=RemCount-8 else PrJ:=PrJ-1;
      end;
      Write(Lst,^M,^J);
    end;
    Write(Lst,^L);
    AbortPrtSc:
    inline($07/$5E/$5F/$5A/$59/$5B/$58/$1F/$CF);
  end;


{.PA}
{*****************************************************************************}
{* Initialization and Configuration                                          *}
{*****************************************************************************}
procedure Initialize;
  begin
    FillChar(Mode,Ofs(OldPrtScOfs)+20-Ofs(Mode),0);
    OldCon:=ConOutPtr;
    ConOutPtr:=Ofs(ConOut);
    GraphicsOn:=true;
    InitEGA;
    InitRS232;
    if ComPort=$3F8 then port[$21]:=port[$21] and not(1 shl 4)
    else port[$21]:=port[$21] and not(1 shl 3);
    Port[ComPort+1]:=$09;
{    if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
    WriteLn(Usr,'ATS10=255');
    if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;}
{    case ModemType of
      0 : Writeln(Usr,'AT &C1 &D3 L M1 E V X4');
      1 : begin
            Write(Usr,^E,^M,^E,^M); Delay(100);
            Write(Usr,'O21122111211111112112',^M);
          end;
    end;}
    with Registers do begin
      AH:=$35; AL:=$05;
      Intr($21,Registers);
      OldPrtScSeg:=ES; OldPrtScOfs:=BX;
      AH:=$25; AL:=$05;
      CASE Printer OF
        0 : DX:=Ofs(EpsonMX80PrtSc)+7;
        1 : DX:=Ofs(ColorJetPrtSc)+7;
      END;
      DS:=CSeg;
      MsDos(Registers);
    end;
    ChDir(DirPath);
    Pic[0].Range:=0;
    StationName:='';
    MaxPic:=0;
    HelpOn:=true; WriteHelp;
  end;

procedure DeInit;
  begin
    if StationName<>'' then ChDir('..');
    port[ComPort+4]:=$08;        {DTR & RTS off}
    port[ComPort+1]:=$00;        {Disable any interrupts}
    port[$21]:= port[$21] or (1 shl 4);
    with Registers do begin
      AH:=$25;
      AL:=$05;
      DX:=OldPrtScOfs;
      DS:=OldPrtScSeg;
      Intr($21,Registers);
    end;
  end;

procedure Config;
  var
    ProgFile         : file of byte;
    ProgDir          : string[20];
  begin
    SelectFunc(_Clr);
    Window(24,1,28,8);
    Write('ออออออออออ OPTIONS ออออออออออ');
    Write(' F1: Modem   =               ');
    Write(' F2: Serial  =               ');
    Write(' F3: Clock   =               ');
    Write(' F4: Printer =               ');
    Write(' F5: Directory Path =        ');
    Write('                             ');
    Write(' F10: Update disk and exit   ');
    Write(' ESC: Exit option menu       ');
    repeat
      GotoXY(15,1);
      if ModemType=0 then Write('Hayes Compat') else Write('Racal-Vadic ');
      GotoXY(15,2); if ComPort=$3F8 then Write('COM1:') else Write('COM2:');
      GotoXY(15,3); if Clock=0 then Write('12 hour') else Write('24 hour');
      GotoXY(15,4);
      case Printer of
        0 : Write('Epson MX80  ');
        1 : Write('Color InkJet');
      end;
      GotoXY(5,6); Write(DirPath);
      ReadKbd;
      case Key of
        ';' : ModemType:=(ModemType+1) mod 2;
        '=' : Clock:=(Clock+1) mod 2;
        '<' : if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
        '>' : Printer:=(Printer+1) mod 2;
        '?' : begin
          GotoXY(5,6); Write('                        ');
          GotoXY(5,6); DirPath:=ReadStr(22);
          if (Length(DirPath)>1) and (DirPath[Length(DirPath)]='\')
            and (DirPath[Length(DirPath)-1]<>':') then
            DirPath:=Copy(DirPath,1,Length(DirPath)-1);
        end;
        'D' : begin
          Window(24,11,28,1);
          Writeln('PROGRAM FILE DIRECTORY?');
          ProgDir:=ReadStr(20);
          UnWindow;
          GRMessage('UPDATING PROGRAM FILE...',false);
          ChDir(ProgDir);
          Assign(ProgFile,'RADAR.COM');
          ReSet(ProgFile);
          if not IOError then begin
            Seek(ProgFile,Ofs(DirPath)-256);
            for I:=Ofs(DirPath) to Ofs(Clock) do
              Write(ProgFile,Mem[CSeg:I]);
            Close(ProgFile);
          end else GRMessage('PROGRAM FILE NOT FOUND',true);
          GRMessage('',false);
          Key:=#27;
        end;
      end;
    until Key=#27;
    Key:=#0;
    DeInit;
    Initialize;
  end;

{.PA}
{*****************************************************************************}
{* Main Routines                                                             *}
{*****************************************************************************}
procedure ExecCom;
  begin
    case UpCase(Key) of {Process regular key codes}
      'G'  : ToggleGraphics;
      'R'  : begin
               RngMksOn:=not RngMksOn;
               if RngMksOn then WriteRngMks
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if Gfx1On then WriteGfx(Map1);
                 if Gfx2On then WriteGfx(Map2);
               end;
             end;
      'H'  : begin
               HelpOn:=not HelpOn;
               WriteHelp;
             end;
      '1'  : if StationName<>'' then begin
               Gfx1On:=not Gfx1On;
               if Gfx1On then WriteGfx(Map1)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx2On then WriteGfx(Map2);
               end;
             end;
      '2'  : if StationName<>'' then begin
               Gfx2On:=not Gfx2On;
               if Gfx2On then WriteGfx(Map2)
               else begin
                 SelectPlane([2,3]); ClearScreen;
                 if RngMksOn then WriteRngMks;
                 if Gfx1On then WriteGfx(Map1);
               end;
             end;
    end;
  end;

procedure RxGraphLoop;
  var
    MapFile : file;
  begin
    BufPtr:=Addr(Map1); BufCount:=1; MapCount:=0;
    SendCom(SendGraph,8000);
    if not Response then Exit;
    Mode:=RxGraph;
    GRMessage('ONE MOMENT PLEASE... RECEIVING MAP OVERLAY',false);
    repeat
      if KeyPressed then begin
        ReadKbd;
        if Key=#27 then if Ask('ABORT MAP OVERLAY RECEPTION') then Key:=^Q;
      end;
    until (Key=^Q) or (MapCount>3) or (Mode=Modem);
    If Key=^Q then begin
      Tx('Y'); Tx('Y');
    end;
    GRMessage('SAVING MAP OVERLAY...',false);
    Assign(MapFile,'MAP1.DAT');
    ReWrite(MapFile,1);
    If not IOError then begin
      BlockWrite(MapFile,Map1,Map1Size);
      Close(MapFile);
    end;
    Assign(MapFile,'MAP2.DAT');
    ReWrite(MapFile,1);
    If not IOError then begin
      BlockWrite(MapFile,Map2,Ofs(BufPtr^)-Ofs(Map2)+8);
      Close(MapFile);
    end;
    GRMessage('',false);
    Mode:=Interactive; Key:=#0;
  end;


var
  PictureSaved : boolean;

procedure RxPicLoop;
  var
    AbortPending   : boolean;
    ContWrite      : boolean;
  begin
    WriteHelp;
    SendCom(SendPic,400);
    if not Response then Exit;
    SelectPlane([0,1]); ClearScreen;
    GRMessage('WAITING FOR PICTURE',false);
    DrawScale;
    Mode:=WaitPic; BufPtr:=Addr(GRBuf);
    LastLine:=0; AbortPending:=false;
    repeat
      if KeyPressed then begin
        ReadKbd;
        ExecCom;
        if Key=#27 then if Ask('ABORT PICTURE') then Key:=^Q;
        GRMessage('WAITING FOR PICTURE',false);
      end;
    until (Key=^Q) or (Mode=RxPic);
    if Mode=RxPic then begin
      WriteAt:=-20000; LineAt:=-20001; PicSaveAt:=-20000;
      GRMessage('RECEIVING PICTURE',false);
      repeat
        repeat
          inline($FA); ContWrite:=LineAt>=WriteAt; inline($FB);
          if ContWrite then begin
            DispLine(PicSave[WriteAt]);
            WriteAt:=WriteAt+LineSize;
          end;
        until not ContWrite;
        if KeyPressed then begin
          ReadKbd;
          if AbortPending then
            if UpCase(Key)='Y' then begin
              Tx('Y'); Tx('Y');
              GRMessage('PICTURE ABORTED',true);
              Tx('Y');
              Key:=^Q;
            end else begin
              GRMessage('RECEIVING PICTURE',false);
              AbortPending:=false;
            end
          else begin
            ExecCom;
            if Key in ['1','2','G','R','H'] then
              GRMessage('RECEIVING PICTURE',false);
            if Key=#27 then begin
              AbortPending:=true;
              GRMessage('ABORT PICTURE? (Y/N)',false);
            end;
          end;
        end;
      until (Key=^Q) or (LastLine>=352) or (Mode=Modem);
      if LastLine>=352 then begin
        if Mode<>Modem then begin
          HangUp;
          Delay(500);
        end;
        GRMessage('SAVING PICTURE...',false);
        SavePic(PicSaveAt+20000);
        PictureSaved:=true;
      end else begin
        Mode:=Interactive;
        PictureSaved:=false;
      end;
    end;
    GRMessage('',false);
    Key:=#0;
    WriteHelp;
  end;


procedure InterLoop;
  label Abort;
  begin
    WriteHelp;
    MaxPic:=MaxPic+1;
    CurrPic:=MaxPic;
    PictureSaved:=false;
    SelectPlane([0,1]);
    ClearScreen;
    SendCom('X',100);
    if not Response then SendCom('X',100);
    if not Response then SendCom('X',100);
    if not Response then begin
      GRMessage('NO RESPONSE. PRESS ANY KEY',true);
      HangUp;
      goto Abort;
    end;
    SelectPlane([3]); GotoXY(73,22); Write('ON LINE');
    SendCom(CheckGraph,600);
    if Response and not GfxMatch then RxGraphLoop
    else GRMessage('',false);
    repeat
      ReadKbd;
      if Escape then
        case Key of              {Process extended key codes}
          #59  : SendCom(TiltUp,800);
          #60  : SendCom(TiltDown,800);
          #61  : begin
                   SendCom(RangeUp,2500);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Map1);
                     if Gfx2On then WriteGfx(Map2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #62  : begin
                   SendCom(RangeDown,2500);
                   if Gfx1On or Gfx2On then begin
                     SelectPlane([2]);
                     ClearScreen;
                     if Gfx1On then WriteGfx(Map1);
                     if Gfx2On then WriteGfx(Map2);
                     if RngMksOn then WriteRngMks;
                   end;
                 end;
          #63  : SendCom(GainUp,8000);
          #64  : SendCom(GainDown,8000);
          #65  : RxPicLoop;
        end
      else ExecCom;
      if Key=#27 then if Ask('DISCONNECT STATION') then Key:=^Q;
    until (Key=^Q) or (Mode=Modem);
    Abort:
    if Mode<>Modem then HangUp; Key:=#0;
    if not PictureSaved then begin
      MaxPic:=MaxPic-1;
      CurrPic:=0;
    end;
    SelectPlane([3]); GotoXY(73,22); Write('       ');
    Mode:=Modem;
    WriteHelp;
  end;

procedure ModemLoop;
  begin
    repeat
      ReadKbd;
      if Escape then
        case Key of
          #59 : begin
                  SelectStation;
                  if Mode=Interactive then InterLoop;
                end;
          #60 : begin
                  Mode:=Interactive;
                  InterLoop;
                end;
          #61 : Storage;
          #62 : if CurrPic>0 then RadioTx;
          ^X  : Config;
         end
      else begin
        case Key of
          '+' : if CurrPic<MaxPic then CurrPic:=CurrPic+1;
          '-' : if CurrPic>0 then CurrPic:=CurrPic-1;
          else ExecCom;
        end;
        if Key in ['+','-'] then FetchPic;
      end;
      if Key=#27 then if Ask('QUIT PROGRAM') then Key:=^Q;
    until Key=^Q;
  end;

var
  OldDir : string[40];

begin
  GetDir(0,OldDir);
  Initialize;
  (*$I CUSTOM.PAS *)
  Window(20,15,41,6);
  Write('ษออออออออออออออออออออออออออออออออออออออออป');
  Write('บ  ELLASON E300 RADAR TERMINAL, ver 2.2  บ');
  Write('บ            Revision 4/13/87            บ');
  Write('บ           Copyright (C) 1987           บ');
  Write('บ               D. G. Lane               บ');
  Write('บ           All rights reserved          บ');
  Write('ศออออออออออออออออออออออออออออออออออออออออผ');
  GRMessage('PRESS ANY KEY',true);
  UnWindow;
  SelectStation;
  ModemLoop;
  DeInit;
  TextMode;
  ChDir(OldDir);
end.
