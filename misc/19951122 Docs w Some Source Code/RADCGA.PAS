var
  DataFile : file;
  Buffer   : array[1..20000] of integer;
  I,J,K    : integer;

var
  LastLine         : integer;
  LineSize         : integer;
  RealLineNum      : integer;
  Size             : integer;

procedure DispLine( var LinePtr );
  var
    LineNum2       : integer absolute LinePtr;
    Line           : array[-1..1280] of byte absolute LinePtr;
    LineNum        : integer;
    Count,Pos      : integer;
    Size           : integer;
    Color          : integer;

  begin
    Count:=1; Pos:=0; LineNum:=Trunc(RealLineNum*200.0/480.0);
    repeat
      Size:=((Line[Count] and $07) shl 8) or Line[Count+1];
      case (Line[Count] shr 5) and $03 of
        0 : Color:=0;
        1 : Color:=2;
        2 : Color:=1;
        3 : Color:=3;
      end;
      if Color>0 then Draw(Pos,LineNum,Pos+Size div 2,LineNum,Color);
      Pos:=Pos+Size div 2;
      Count:=Count+2;
    until (Line[Count]=$18) or KeyPressed;
    RealLineNum:=RealLineNum+2;
    LineSize:=Count+3;
  end;


begin
  FillChar(Buffer,20000,0);
  Assign(DataFile,'B:PIC4.DAT');
  Reset(DataFile);
  BlockRead(DataFile,Buffer,FileSize(DataFile),Size);
  Close(DataFile);
  I:=1; GraphColorMode; Palette(2); RealLineNum:=0;
  repeat
    DispLine(Buffer[I]);
    I:=I+LineSize div 2;
  until (RealLineNum>=460) or KeyPressed;
end.
