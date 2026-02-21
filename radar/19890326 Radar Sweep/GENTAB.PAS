program GenTable;

const
  Steps   = 400;        (* Number of steps in one quandrant *)
  XRatio  = 0.9375;     (* Ratio for X = 1:1 *)
  YRatio  = 0.6835937; (* Ratio for Y = 350:480 *)

type
  string3 = string[3];

var
  OutFile  :  text;

const
  HexDig : array[0..15] of char =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

function Hex(Num : byte) : string3;
var result : string3;
begin
  result[0]:=#2;
  result[1]:=HexDig[Num div 16];
  result[2]:=HexDig[Num mod 16];
  Hex:=result;
end;

const
  pi = 3.141592654;

var
  Table     : SET OF BYTE;
  TableData : ARRAY[0..31] OF BYTE ABSOLUTE Table;

procedure OutTable;
var
  Count : integer;
begin
  Write(OutFile,'           DW ');
  for Count:=15 downto 8 do begin
    Write(OutFile,'0',Hex(TableData[Count*2+1]),Hex(TableData[Count*2]),'H');
    if Count>8 then Write(OutFile,',');
  end;
  Writeln(OutFile);
  Write(OutFile,'           DW ');
  for Count:=7 downto 0 do begin
    Write(OutFile,'0',Hex(TableData[Count*2+1]),Hex(TableData[Count*2]),'H');
    if Count>0 then Write(OutFile,',');
  end;
  Writeln(OutFile);
end;

procedure MakeXTable;
var
  Angle,Step : real;
  sinAngle   : real;
  Prev       : integer;
  Count,
  Count2     : integer;
begin
  Write('GENERATING X TABLE : ');
  Angle:=0.0; Step:=pi/2/Steps;
  for Count:=0 to Steps-1 do begin
    Write(Count:3,^H,^H,^H);
    sinAngle:=sin(Angle)*XRatio; Angle:=Angle+Step;
    Prev:=0;
    fillchar(Table,SizeOf(Table),0);
    for Count2:=0 to 255 do begin
      if Trunc(sinAngle*Count2)>Prev then Table:=Table+[Count2];
      Prev:=Trunc(sinAngle*Count2);
    end;
    OutTable;
  end;
  Writeln;
end;

procedure MakeYTable;
var
  Angle,Step : real;
  sinAngle   : real;
  Prev       : integer;
  Count,
  Count2     : integer;
begin
  Write('GENERATING Y TABLE : ');
  Angle:=0.0; Step:=pi/2/Steps;
  for Count:=0 to Steps-1 do begin
    Write(Count:3,^H,^H,^H);
    sinAngle:=cos(Angle)*YRatio; Angle:=Angle+Step;
    Prev:=0;
    fillchar(Table,SizeOf(Table),0);
    for Count2:=0 to 255 do begin
      if Trunc(sinAngle*Count2)>Prev then Table:=Table+[Count2];
      Prev:=Trunc(sinAngle*Count2);
    end;
    OutTable;
  end;
  Writeln;
end;

begin
  Assign(OutFile,'IncTabX.ASM');
  ReWrite(OutFile);
  Writeln(OutFile,'           PUBLIC IncTableX');
  Writeln(OutFile);
  Writeln(OutFile,'DataSeg    SEGMENT PARA ',#39,'DATA',#39);
  Writeln(OutFile,'IncTableX  LABEL FAR');
  MakeXTable;
  Writeln(OutFile,'DataSeg    ENDS');
  Writeln(OutFile,'           END');
  Close(OutFile);

  Assign(OutFile,'IncTabY.ASM');
  ReWrite(OutFile);
  Writeln(OutFile,'           PUBLIC IncTableY');
  Writeln(OutFile);
  Writeln(OutFile,'DataSeg    SEGMENT PARA ',#39,'DATA',#39);
  Writeln(OutFile,'IncTableY  LABEL FAR');
  MakeYTable;
  Writeln(OutFile,'DataSeg    ENDS');
  Writeln(OutFile,'           END');
  Close(OutFile);
end.
