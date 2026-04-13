PROGRAM Map_Editor;

(*$I GRAPH.P *)

TYPE
  LandMarkRec = RECORD
    Bearing   :   INTEGER;
    Range     :   INTEGER;
    Name      :   ARRAY[1..3] OF CHAR;
    Nothing   :   BYTE;
  END; (* RECORD *)

  SegmentRec  = RECORD
    Range1    :   INTEGER;
    Bear1     :   INTEGER;
    Range2    :   INTEGER;
    Bear2     :   INTEGER;
  END; (* RECORD *)

  String40 = STRING[40];

VAR
  LandmarkHIGH : INTEGER;
  Landmark     : ARRAY[1..80] OF LandMarkRec;
  SegmentHIGH  : INTEGER;
  Segment      : ARRAY[1..500] OF SegmentRec;
  CurrentRange : INTEGER;
  Pen          : INTEGER;

PROCEDURE ReadString(VAR ToString : String40);
VAR
  X,Y : INTEGER;
  Key : CHAR;
BEGIN
  X:=WhereX; Y:=WhereY;
  REPEAT
    GotoXY(X,Y);
    Write(ToString);
    Read(Kbd,Key);
    IF (Key=^H) THEN BEGIN
      IF Length(ToString)>0 THEN BEGIN
        ToString[0]:=CHR(ORD(ToString[0])-1);
        Write(^H,' ');
      END;
    END ELSE IF Key in [#32..#126] THEN ToString:=ToString+Key;
  UNTIL Key=#13;
END; (* ReadString *)

(*********************************************************)
(* WRITE SEGMENT AND LANDMARK                            *)
(*********************************************************)

CONST
  RangeVal : ARRAY[0..10] OF INTEGER =
    (5, 10, 25, 35, 50, 75, 100, 125, 150, 175, 200);

  ASin : ARRAY[0..360] OF BYTE = (
128,128,128,129,129,130,130,131,131,132,132,132,133,133,134,134,135,135,135,136,
136,137,137,138,138,138,139,139,140,140,140,141,141,141,142,142,143,143,143,144,
144,144,145,145,145,146,146,146,147,147,147,147,148,148,148,148,149,149,149,149,
150,150,150,150,151,151,151,151,151,151,152,152,152,152,152,152,152,152,153,153,
153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,153,
153,153,153,152,152,152,152,152,152,152,152,151,151,151,151,151,151,150,150,150,
150,149,149,149,149,148,148,148,148,147,147,147,147,146,146,146,145,145,145,144,
144,144,143,143,143,142,142,141,141,141,140,140,140,139,139,138,138,138,137,137,
136,136,135,135,135,134,134,133,133,132,132,132,131,131,130,130,129,129,128,128,
128,128,128,127,127,126,126,125,125,124,124,124,123,123,122,122,121,121,121,120,
120,119,119,118,118,118,117,117,116,116,116,115,115,115,114,114,113,113,113,112,
112,112,111,111,111,110,110,110,109,109,109,109,108,108,108,108,107,107,107,107,
106,106,106,106,105,105,105,105,105,105,104,104,104,104,104,104,104,104,103,103,
103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,103,
103,103,103,104,104,104,104,104,104,104,104,105,105,105,105,105,105,106,106,106,
106,107,107,107,107,108,108,108,108,109,109,109,109,110,110,110,111,111,111,112,
112,112,113,113,113,114,114,115,115,115,116,116,116,117,117,118,118,118,119,119,
120,120,121,121,121,122,122,123,123,124,124,124,125,125,126,126,127,127,128,128,
128);

  ACos : ARRAY[0..360] OF BYTE = (
146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,145,145,145,145,
145,145,145,145,145,144,144,144,144,144,144,144,143,143,143,143,143,142,142,142,
142,142,141,141,141,141,140,140,140,140,139,139,139,139,138,138,138,138,137,137,
137,137,136,136,136,135,135,135,134,134,134,134,133,133,133,132,132,132,131,131,
131,130,130,130,129,129,129,128,128,128,128,128,128,128,127,127,127,126,126,126,
125,125,125,124,124,124,123,123,123,122,122,122,122,121,121,121,120,120,120,119,
119,119,119,118,118,118,118,117,117,117,117,116,116,116,116,115,115,115,115,114,
114,114,114,114,113,113,113,113,113,113,112,112,112,112,112,112,111,111,111,111,
111,111,111,111,111,110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,110,111,111,111,111,
111,111,111,111,111,112,112,112,112,112,112,112,113,113,113,113,113,114,114,114,
114,114,115,115,115,115,116,116,116,116,116,117,117,117,118,118,118,118,119,119,
119,119,120,120,120,121,121,121,122,122,122,122,123,123,123,124,124,124,125,125,
125,126,126,126,127,127,127,128,128,128,128,128,128,128,129,129,129,130,130,130,
131,131,131,132,132,132,133,133,133,134,134,134,134,135,135,135,136,136,136,137,
137,137,137,138,138,138,138,139,139,139,139,140,140,140,140,141,141,141,141,142,
142,142,142,142,143,143,143,143,143,143,144,144,144,144,144,144,145,145,145,145,
145,145,145,145,145,146,146,146,146,146,146,146,146,146,146,146,146,146,146,146,
146);


PROCEDURE WriteSegment(ForSegment : SegmentRec);
VAR
  Max, Adj : INTEGER;
BEGIN
  Max:=RangeVal[CurrentRange]*10;
  Adj:=RangeVal[CurrentRange]*2;
  WITH ForSegment DO BEGIN
    IF (Range1<Max) AND (Range2<Max) THEN BEGIN
      IF (Range1>1310) OR (Range2>1310) THEN BEGIN
        Draw(Trunc(Range1*(ASin[Bear1]-128.0)/Adj)+160,
          50-Trunc(Range1*(ACos[Bear1]-128.0)/Adj),
          Trunc(Range2*(ASin[Bear2]-128.0)/Adj)+160,
          50-Trunc(Range2*(ACos[Bear2]-128.0)/Adj),Pen);
      END ELSE BEGIN
        Draw(Range1*(ASin[Bear1]-128) div Adj+160,
          50-Range1*(ACos[Bear1]-128) div Adj,
          Range2*(ASin[Bear2]-128) div Adj+160,
          50-Range2*(ACos[Bear2]-128) div Adj,Pen);
      END; (* IF *)
    END; (* IF *)
  END; (* WITH *)
END; (* WriteSegment *)

PROCEDURE WriteLandmark(ForLandmark : LandmarkRec);
VAR
  Max, Min, Adj : INTEGER;
BEGIN
  Max:=RangeVal[CurrentRange]*10; Min:=Max div 7;
  Adj:=RangeVal[CurrentRange];
  WITH ForLandmark DO BEGIN
    IF (Min<Range) AND (Range<Max) THEN BEGIN
      IF Range>1310 THEN BEGIN
        GotoXY(Trunc(Range*(ASin[Bearing]-128)/Adj/8)+300,
               Trunc(170-Range*(ACos[Bearing]-128)/Adj/8));
        Write(Name);
      END ELSE BEGIN
        GotoXY(Range*(ASin[Bearing]-128) div Adj+300,
               170-Range*(ACos[Bearing]-128) div Adj);
        Write(Name);
      END; (* IF *)
    END; (* IF *)
  END; (* WITH *)
END; (* WriteLandmarks *)


PROCEDURE Disk;
BEGIN
  Window(1,1,80,25);
  GotoXY(40,15); Write('************** DISK MENU ***************');
  GotoXY(40,16); Write('* F1: Load                             *');
  GotoXY(40,17); Write('* F2: New file : Landmark              *');
  GotoXY(40,18); Write('* F3: New file : Segment               *');
  GotoXY(40,19); Write('* F4: Erase file                       *');
  GotoXY(40,20); Write('* F5: Rename file                      *');
  GotoXY(40,21); Write('*                                      *');
  GotoXY(40,22); Write('****************************************');
  GotoXY(40,23); Write('*                                      *');
  GotoXY(40,24); Write('****************************************');
END; (* Disk *)

PROCEDURE EditLandmarks;
BEGIN
END; (* EditLandmarks *)

VAR
  AutoConnect : BOOLEAN;

PROCEDURE EditSegments;

  PROCEDURE WriteEntry(ForSegment : INTEGER);
  BEGIN
    WITH Segment[ForSegment] DO BEGIN
      Write(ForSegment:3,': ',Range1/10.0:6:1,' ',Bear1:6);
      WriteLn(' ',Range2/10.0:6:1,' ',Bear2:6,' ');
    END; (* WITH *)
  END; (* WriteEntry *)

VAR
  TopY    : INTEGER;
  X,Y     : INTEGER;
  Key     : CHAR;
  Instr   : STRING[40];
  RealVal : REAL;
  Pos     : INTEGER;
BEGIN
  Pen:=1;
  FOR Y:=1 TO SegmentHIGH DO
    WriteSegment(Segment[Y]);
  GotoXY(1,1);
  Y:=1;
  WHILE (Y<=20) AND (Y<=SegmentHIGH) DO BEGIN
    WriteEntry(Y);
    Y:=Y+1;
  END; (* WHILE *)
  X:=1; Y:=1; TopY:=1;
  REPEAT
    GotoXY(X*7-1,Y-TopY+1); Write('[');
    GotoXY(X*7+5,Y-TopY+1); Write(']');
    WHILE NOT(KeyPressed) DO BEGIN
      Pen:=0; WriteSegment(Segment[Y]);
      Pen:=1; WriteSegment(Segment[Y]);
    END; (* WHILE *)
    Read(Kbd,Key);
    IF KeyPressed THEN Read(Kbd,Key);
    GotoXY(X*7-1,Y-TopY+1); Write(' ');
    GotoXY(X*7+5,Y-TopY+1); Write(' ');
    CASE Key OF
      'H' : IF Y>1 THEN Y:=Y-1;
      'P' : IF Y<SegmentHIGH THEN Y:=Y+1;
      'K' : IF X>1 THEN X:=X-1;
      'M' : IF X<4 THEN X:=X+1;
      'G' : Y:=1;
      'O' : Y:=SegmentHIGH;
      'I' : IF Y>20 THEN Y:=Y-20
            ELSE Y:=1;
      'Q' : IF Y+19<SegmentHIGH THEN Y:=Y+20
            ELSE Y:=SegmentHIGH;
      '>' : AutoConnect:=NOT AutoConnect;
      '+' : IF CurrentRange<10 THEN BEGIN
        CurrentRange:=CurrentRange+1;
        FillScreen(0);
        Pen:=1;
        FOR Y:=1 TO SegmentHIGH DO
          WriteSegment(Segment[Y]);
      END;
      '-' : IF CurrentRange>0 THEN BEGIN
        CurrentRange:=CurrentRange-1;
        FillScreen(0);
        Pen:=1;
        FOR Y:=1 TO SegmentHIGH DO
          WriteSegment(Segment[Y]);
      END;
      '0'..'9' : BEGIN
        Pen:=0; WriteSegment(Segment[Y]);
        InStr:=Key;
        GotoXY(X*7-1,Y-TopY+1); Write('[     ]');
        GotoXY(X*7,Y-TopY+1);
        ReadString(InStr);
        Val(InStr,RealVal,Pos);
        WITH Segment[Y] DO
          CASE X OF
            1 : Range1:=Trunc(RealVal*10);
            2 : Bear1:=Trunc(RealVal);
            3 : Range2:=Trunc(RealVal*10);
            4 : Bear2:=Trunc(RealVal);
          END;
        GotoXY(1,Y-TopY+1); WriteEntry(Y);
        Pen:=1; WriteSegment(Segment[Y]);
        IF X<4 THEN X:=X+1
        ELSE BEGIN
          X:=1;
          Y:=Y+1;
          IF Y>SegmentHIGH THEN BEGIN
            SegmentHIGH:=Y;
            IF AutoConnect THEN BEGIN
              Segment[Y].Range1:=Segment[Y-1].Range2;
              Segment[Y].Bear1:=Segment[Y-1].Bear2;
              X:=3;
            END;
            GotoXY(1,Y-TopY+1);
            WriteEntry(Y);
          END;
        END;
      END;
    END; (* CASE *)
    WHILE Y<TopY DO BEGIN
      GotoXY(1,1); InsLine;
      TopY:=TopY-1;
      WriteEntry(TopY);
    END;
    WHILE Y>TopY+19 DO BEGIN
      GotoXY(1,1); DelLine;
      GotoXY(1,20);
      TopY:=TopY+1;
      WriteEntry(TopY+19);
    END;
  UNTIL Key=#27;
END; (* EditSegments *)

BEGIN
  CurrentRange:=10;
  FillChar(Segment,SizeOf(Segment),0);
  SegmentHIGH:=1;
  AutoConnect:=FALSE;
  HiRes;
  Draw(0,0,0,199,1);
  Draw(0,199,639,199,1);
  Draw(639,199,639,105,1);
  Draw(639,105,315,105,1);
  Draw(315,105,315,0,1);
  Draw(315,0,0,0,1);
  Draw(320,0,320,100,1);
  Draw(320,100,639,100,1);
  Draw(639,100,639,0,1);
  Draw(639,0,320,0,1);
  GotoXY(2,2); Write('ELECTRONIC MAP EDITOR 1.0');
  GotoXY(2,3); Write('--------------------------------------');
  GotoXY(40,15); Write('***************** MENU *****************');
  GotoXY(40,16); Write('* F1: Disk          | INS: Insert one  *');
  GotoXY(40,17); Write('* F2: Erase all     | DEL: Delete one  *');
  GotoXY(40,18); Write('* F3: Range marks   | +: Range up      *');
  GotoXY(40,19); Write('* F4: Auto connect  | -: Range down    *');
  GotoXY(40,20); Write('* F5: Prepare EPROM |                  *');
  GotoXY(40,21); Write('****************************************');
  GotoXY(40,22); Write('* NAME    :                            *');
  GotoXY(40,23); Write('* ENTRIES :      AUTO-CONNECT :        *');
  GotoXY(40,24); Write('****************************************');
  Window(2,4,39,24);
  GraphWindow(321,1,638,99);
  EditSegments;
END.
