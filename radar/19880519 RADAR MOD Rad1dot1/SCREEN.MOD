턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬GA and screen *)
VAR
  Segment,Offset : CARDINAL;
  Temp : ADDRESS;
BEGIN
  SETREG(AX,0010H); (* Set 640 X 350, 16 color mode *)
  SWI(10H);
  SETREG(AX,1130H); (* Get address of 8 X 14 characters *)
  SETREG(BX,0200H);
  SWI(10H);
  GETREG(ES,Segment);
  GETREG(BP,Offset);
  Temp.SEGMENT:=Segment;
  Temp.OFFSET:=Offset;
  CharTab14:=Temp;
  SETREG(AX,1130H); (* Get address of 8 X 8 characters *)
  SETREG(BX,0300H);
  SWI(10H);
  GETREG(ES,Segment);
  GETREG(BP,Offset);
  Temp.SEGMENT:=Segment;
  Temp.OFFSET:=Offset;
  CharTab8:=Temp;
  FOR I:=0 TO 15 DO (* Set up palette according to Colors[0..15] *)
    INBYTE(3DAH,J);
    OUTBYTE(3C0H,I);
    OUTBYTE(3C0H,I);
  END; (* FOR I:=0 To 15 *)
  OUTBYTE(3C0H,20H); (* Enable new palette *)
  AssignWrite(EGAOut,OK); (* Redirect output through EGAOut *)
  WriteParams; (* Write initiale parameters *)
  GotoXY(1,22); 
  WriteString('* H = HELP *'); (* And help message *)
  GraphicsOn:=TRUE;
  Map1On:=FALSE;
  Map2On:=FALSE;
  RangeMarksOn:=FALSE;
END Initialize;

PROCEDURE Deinit;
BEGIN
  UnAssignWrite(OK); (* Standard output *)
  SETREG(AX,0003H); (* Set 80 X 25 color text mode *)
  SWI(10H);
END Deinit;

VAR 
  GraphicsOn : BOOLEAN;

PROCEDURE ToggleGraphics; (* Toggle blue and white planes *)
BEGIN
  GraphicsOn:=NOT GraphicsOn;
  INBYTE(3DAH,J);
  OUTBYTE(3C0H,12H);
  IF GraphicsOn THEN 
    OUTBYTE(3C0H,0FH);
  ELSE
    OUTBYTE(3C0H,03H);
  END;
END ToggleGraphics;
    
VAR
  RangeMarksOn : BOOLEAN;

PROCEDURE ToggleRangeMarks;
BEGIN
  RangeMarksOn:=NOT RangeMarksOn;
END ToggleRangeMarks;

VAR
  Map1On : BOOLEAN;

PROCEDURE ToggleMap1;
BEGIN
  Map1On:=NOT Map1On;
END ToggleMap1;

VAR
  Map2On : BOOLEAN;

PROCEDURE ToggleMap2;
BEGIN
  Map2On:=NOT Map2On;
END ToggleMap2;

PROCEDURE WriteScreen;
BEGIN
  ClearScreen;
END WriteScreen;

PROCEDURE WriteParams;
BEGIN
  WITH Storage.CurrParams DO
    GotoXY(8,0); WriteCard(TiltVal[Tilt],3);
    GotoXY(72,0); WriteTime(Time);
    GotoXY(8,24); WriteCard(RangeVal[Range],3);
    GotoXY(72,24); 
    IF Gain<17 THEN
      WriteCard(Gain,4);
    ELSE
      WriteString(' PRE');
    END;
  END;
END WriteParams;

PROCEDURE DecompPic(ForPic : ADDRESS; Start, Max : CARDINAL);
VAR
  LineNum[ForPic.SEGMENT:ForPic.OFFSET] : CARDINAL;
  Line[ForPic.SEGMENT:ForPic.OFFSET] : ARRAY [-1..1280] OF BYTE;
  Count,Repeat,
  AtByte,AtBit : CARDINAL;       
  ROn,GOn : BOOLEAN;
  RByte,GByte : BYTE;
  Size : CARDINAL;
BEGIN
(*  AtByte:=LineNum*80; AtBit:=0;
  RByte:=00h; GByte:=00h;
  Count:=1;
  REPEAT
    Size:=((Line[Count] AND 07h) SHL 8) OR Line[Count+1];
    CASE (Line[Count] SHR 5) AND $03 OF
      0 : ROn:=false; GOn:=false|
      1 : ROn:=true; GOn:=false|
      2 : ROn:=false; GOn:=true|
      3 : ROn:=true; GOn:=true|
    END;
    IF Size+AtBit<=8 THEN
      IF ROn THEN RByte:=RByte or ($FF shr (8-Size) shl AtBit); END;
      IF GOn THEN GByte:=GByte or ($FF shr (8-Size) shl AtBit); END;
      AtBit:=AtBit+Size;
    턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬턬    FillChar(Mem[$A000:AtByte],Size shr 3,GByte);
        AtByte:=AtByte+(Size shr 3); AtBit:=Size and $07;
      end else AtBit:=Size;
      if ROn then RByte:=$FF shr (8-AtBit) else RByte:=$00;
      if GOn then GByte:=$FF shr (8-AtBit) else GByte:=$00;
    end;
    if AtBit=8 then begin
      SelectPlane([0]); Mem[$A000:AtByte]:=RByte;
      SelectPlane([1]); Mem[$A000:AtByte]:=GByte;
      AtByte:=AtByte+1; AtBit:=0;
      RByte:=$00; GByte:=$00;
    end;
    Count:=Count+2;
  until (Line[Count]=$18);
  LineSize:=Count+3; *)
END DecompPic;

PROCEDURE DrawScale;
VAR
  I : CARDINAL;
  WriteVal : CARDINAL;
BEGIN
  FOR I:=0 to 349 do begin
    IF (I MOD 100)=0 THEN
      WriteVal:=$FF;
    ELSIF (I MOD 50)=0 THEN
      WriteVal:=$FC;
    ELSIF (I MOD 10)=0 THEN
      WriteVal:=$F0;
    ELSE
      WriteVal:=$C0;
    END;
    Screen[I*80]:=WriteVal;
  end;
END DrawScale;

VAR
  LastMess : CARDINAL;

PROCEDURE Message(ForMessage : ARRAY OF CHAR);
BEGIN
  (* INCOMPLETE *)
END Message;

PROCEDURE Ask(ForMessage : ARRAY OF CHAR) : BOOLEAN;
VAR
  Resp : CHAR;
BEGIN
  Message(ForMessage);
  Read(Resp);
  RETURN (Resp='Y') OR (Resp='y');
END Ask;

VAR
  CursX,CursY : CARDINAL;
  XPos,YPos : CARDINAL;
  XMax,YMax : CARDINAL;

PROCEDURE GotoXY(X,Y : CARDINAL);
BEGIN
  CursX:=X; CursY:=Y;
END GotoXY;

PROCEDURE EGAOut(C : CHAR);
VAR
  CharPos,I : CARDINAL;
BEGIN
  CASE C OF
    ASCII.bs : IF CursX>0 THEN CursX:=CursX-1; END|
    ASCII.lf : IF CursY<YMax THEN CursY:=CursY+1; END|
    ASCII.cr : CursX:=0
  ELSE
    CharPos:=(CursX+XPos)+(CursY+YPos)*1180;
    FOR I:=0 TO 13 DO
      ScreenMem[CharPos+I*80]:=CharTab14^[ORD(C)*14+I];
    END;
    IF CursX<XMax THEN 
      CursX:=CursX+1;
    ELSE
      CursX:=0;
      CursY:=CursY+1;
    END;
  END;
END EGAOut;

PROCEDURE ClearScreen;
BEGIN
  (* INCOMPLETE *)
END ClearScreen;

END Screen.
