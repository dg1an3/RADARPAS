PROGRAM Enhanced_Map_Editor;

(* Copyright (C) 2024 D. G. Lane *)

(*$I GRAPH.P *)

TYPE
  LandMarkRec = RECORD
    Bearing   : INTEGER;
    Range     : INTEGER;
    Name      : ARRAY[1..3] OF CHAR;
    Nothing   : BYTE;
  END; (* RECORD *)

  SegmentRec = RECORD
    Range1    : INTEGER;
    Bear1     : INTEGER;
    Range2    : INTEGER;
    Bear2     : INTEGER;
  END; (* RECORD *)

  String40 = STRING[40];

VAR
  LandmarkHIGH : INTEGER;
  Landmark     : ARRAY[1..80] OF LandMarkRec;
  SegmentHIGH  : INTEGER;
  Segment      : ARRAY[1..500] OF SegmentRec;
  CurrentRange : INTEGER;
  Pen          : INTEGER;

  (* Display parameters *)
  CenterX      : INTEGER;
  CenterY      : INTEGER;
  ScaleFactor  : REAL;
  DisplayMode  : INTEGER;

CONST
  RangeVal : ARRAY[0..10] OF INTEGER =
    (5, 10, 25, 35, 50, 75, 100, 125, 150, 175, 200);

  (* Pre-calculated sine lookup table for 0-360 degrees *)
  ASin : ARRAY[0..360] OF INTEGER = (
    0,17,35,52,70,87,105,122,139,156,174,191,208,225,242,259,
    276,292,309,326,342,358,375,391,407,423,438,454,469,485,
    500,515,530,545,559,574,588,602,616,629,643,656,669,682,
    695,707,719,731,743,755,766,777,788,799,809,819,829,839,
    848,857,866,875,883,891,899,906,914,921,928,934,940,946,
    951,956,961,966,970,974,978,982,985,988,990,993,995,996,
    998,999,999,1000,1000,1000,999,999,998,996,995,993,990,988,
    985,982,978,974,970,966,961,956,951,946,940,934,928,921,
    914,906,899,891,883,875,866,857,848,839,829,819,809,799,
    788,777,766,755,743,731,719,707,695,682,669,656,643,629,
    616,602,588,574,559,545,530,515,500,485,469,454,438,423,
    407,391,375,358,342,326,309,292,276,259,242,225,208,191,
    174,156,139,122,105,87,70,52,35,17,0,-17,-35,-52,-70,-87,
    -105,-122,-139,-156,-174,-191,-208,-225,-242,-259,-276,-292,
    -309,-326,-342,-358,-375,-391,-407,-423,-438,-454,-469,-485,
    -500,-515,-530,-545,-559,-574,-588,-602,-616,-629,-643,-656,
    -669,-682,-695,-707,-719,-731,-743,-755,-766,-777,-788,-799,
    -809,-819,-829,-839,-848,-857,-866,-875,-883,-891,-899,-906,
    -914,-921,-928,-934,-940,-946,-951,-956,-961,-966,-970,-974,
    -978,-982,-985,-988,-990,-993,-995,-996,-998,-999,-999,-1000,
    -1000,-1000,-999,-999,-998,-996,-995,-993,-990,-988,-985,-982,
    -978,-974,-970,-966,-961,-956,-951,-946,-940,-934,-928,-921,
    -914,-906,-899,-891,-883,-875,-866,-857,-848,-839,-829,-819,
    -809,-799,-788,-777,-766,-755,-743,-731,-719,-707,-695,-682,
    -669,-656,-643,-629,-616,-602,-588,-574,-559,-545,-530,-515,
    -500,-485,-469,-454,-438,-423,-407,-391,-375,-358,-342,-326,
    -309,-292,-276,-259,-242,-225,-208,-191,-174,-156,-139,-122,
    -105,-87,-70,-52,-35,-17,0);

  (* Pre-calculated cosine lookup table for 0-360 degrees *)
  ACos : ARRAY[0..360] OF INTEGER = (
    1000,1000,999,999,998,996,995,993,990,988,985,982,978,974,
    970,966,961,956,951,946,940,934,928,921,914,906,899,891,
    883,875,866,857,848,839,829,819,809,799,788,777,766,755,
    743,731,719,707,695,682,669,656,643,629,616,602,588,574,
    559,545,530,515,500,485,469,454,438,423,407,391,375,358,
    342,326,309,292,276,259,242,225,208,191,174,156,139,122,
    105,87,70,52,35,17,0,-17,-35,-52,-70,-87,-105,-122,-139,
    -156,-174,-191,-208,-225,-242,-259,-276,-292,-309,-326,-342,
    -358,-375,-391,-407,-423,-438,-454,-469,-485,-500,-515,-530,
    -545,-559,-574,-588,-602,-616,-629,-643,-656,-669,-682,-695,
    -707,-719,-731,-743,-755,-766,-777,-788,-799,-809,-819,-829,
    -839,-848,-857,-866,-875,-883,-891,-899,-906,-914,-921,-928,
    -934,-940,-946,-951,-956,-961,-966,-970,-974,-978,-982,-985,
    -988,-990,-993,-995,-996,-998,-999,-999,-1000,-1000,-1000,-999,
    -999,-998,-996,-995,-993,-990,-988,-985,-982,-978,-974,-970,
    -966,-961,-956,-951,-946,-940,-934,-928,-921,-914,-906,-899,
    -891,-883,-875,-866,-857,-848,-839,-829,-819,-809,-799,-788,
    -777,-766,-755,-743,-731,-719,-707,-695,-682,-669,-656,-643,
    -629,-616,-602,-588,-574,-559,-545,-530,-515,-500,-485,-469,
    -454,-438,-423,-407,-391,-375,-358,-342,-326,-309,-292,-276,
    -259,-242,-225,-208,-191,-174,-156,-139,-122,-105,-87,-70,
    -52,-35,-17,0,17,35,52,70,87,105,122,139,156,174,191,208,
    225,242,259,276,292,309,326,342,358,375,391,407,423,438,
    454,469,485,500,515,530,545,559,574,588,602,616,629,643,
    656,669,682,695,707,719,731,743,755,766,777,788,799,809,
    819,829,839,848,857,866,875,883,891,899,906,914,921,928,
    934,940,946,951,956,961,966,970,974,978,982,985,988,990,
    993,995,996,998,999,999,1000,1000,1000);

PROCEDURE InitDisplay;
BEGIN
  CenterX := 320;      (* Center of 640x480 EGA screen *)
  CenterY := 240;
  ScaleFactor := 1.0;
  DisplayMode := 1;
  CurrentRange := 4;   (* Default to 50-mile range *)
  GraphColorMode;
  Palette(1);
END; (* InitDisplay *)

PROCEDURE DrawRangeRings;
VAR
  I, Radius : INTEGER;
BEGIN
  (* Draw range rings for current scale *)
  FOR I := 1 TO 4 DO BEGIN
    Radius := Round(I * RangeVal[CurrentRange] * ScaleFactor);
    IF Radius < 300 THEN
      Circle(CenterX, CenterY, Radius, 1);
  END;

  (* Draw cardinal direction lines *)
  Line(CenterX, CenterY-200, CenterX, CenterY+200, 1);  (* N-S *)
  Line(CenterX-200, CenterY, CenterX+200, CenterY, 1);  (* E-W *)

  (* Draw bearing markers every 30 degrees *)
  FOR I := 0 TO 11 DO BEGIN
    Radius := Round(RangeVal[CurrentRange] * ScaleFactor * 4.2);
    Line(CenterX, CenterY,
         CenterX + Round(Radius * ASin[I*30] / 1000),
         CenterY - Round(Radius * ACos[I*30] / 1000), 1);
  END;
END; (* DrawRangeRings *)

PROCEDURE RenderSegment(ForSegment : SegmentRec);
VAR
  X1, Y1, X2, Y2 : INTEGER;
  R1, R2 : REAL;
BEGIN
  WITH ForSegment DO BEGIN
    R1 := Range1 / 10.0 * ScaleFactor;
    R2 := Range2 / 10.0 * ScaleFactor;

    (* Calculate screen coordinates using lookup tables *)
    X1 := CenterX + Round(R1 * ASin[Bear1] / 1000);
    Y1 := CenterY - Round(R1 * ACos[Bear1] / 1000);
    X2 := CenterX + Round(R2 * ASin[Bear2] / 1000);
    Y2 := CenterY - Round(R2 * ACos[Bear2] / 1000);

    (* Draw the segment *)
    Line(X1, Y1, X2, Y2, 2);
  END; (* WITH *)
END; (* RenderSegment *)

PROCEDURE RenderLandmark(ForLandmark : LandMarkRec);
VAR
  X, Y : INTEGER;
  R : REAL;
BEGIN
  WITH ForLandmark DO BEGIN
    R := Range / 10.0 * ScaleFactor;

    (* Calculate screen coordinates *)
    X := CenterX + Round(R * ASin[Bearing] / 1000);
    Y := CenterY - Round(R * ACos[Bearing] / 1000);

    (* Draw landmark marker *)
    Circle(X, Y, 3, 3);

    (* Draw landmark name *)
    GotoXY((X DIV 8) + 1, (Y DIV 8) + 1);
    Write(Name);
  END; (* WITH *)
END; (* RenderLandmark *)

PROCEDURE RenderMap;
VAR
  I : INTEGER;
BEGIN
  (* Clear screen and redraw *)
  GraphColorMode;

  (* Draw range rings and bearings *)
  DrawRangeRings;

  (* Render all segments *)
  FOR I := 1 TO SegmentHIGH DO
    RenderSegment(Segment[I]);

  (* Render all landmarks *)
  FOR I := 1 TO LandmarkHIGH DO
    RenderLandmark(Landmark[I]);

  (* Draw status information *)
  GotoXY(1, 1);
  Write('EME Map Editor - Range: ', RangeVal[CurrentRange], ' miles');
  GotoXY(1, 2);
  Write('Segments: ', SegmentHIGH, ' Landmarks: ', LandmarkHIGH);
END; (* RenderMap *)

PROCEDURE ReadString(VAR ToString : String40);
VAR
  X, Y : INTEGER;
  Key : CHAR;
BEGIN
  X := WhereX; Y := WhereY;
  ToString := '';
  REPEAT
    GotoXY(X, Y);
    Write(ToString, ' ');
    GotoXY(X + Length(ToString), Y);
    Read(Kbd, Key);

    IF (Key = ^H) THEN BEGIN
      IF Length(ToString) > 0 THEN
        ToString := Copy(ToString, 1, Length(ToString) - 1);
    END ELSE IF Key IN [#32..#126] THEN
      ToString := ToString + Key;
  UNTIL Key = #13;
END; (* ReadString *)

FUNCTION StrToInt(S : String40) : INTEGER;
VAR
  I, Result : INTEGER;
BEGIN
  Result := 0;
  FOR I := 1 TO Length(S) DO BEGIN
    IF S[I] IN ['0'..'9'] THEN
      Result := Result * 10 + Ord(S[I]) - Ord('0');
  END;
  StrToInt := Result;
END; (* StrToInt *)

PROCEDURE AddLandmark;
VAR
  TempName : String40;
  TempBearing, TempRange : INTEGER;
BEGIN
  IF LandmarkHIGH >= 80 THEN BEGIN
    GotoXY(1, 24);
    Write('Maximum landmarks reached!');
    REPEAT UNTIL KeyPressed;
    EXIT;
  END;

  TextMode;
  GotoXY(1, 10);
  Write('Enter landmark name (3 chars): ');
  ReadString(TempName);

  GotoXY(1, 11);
  Write('Enter bearing (0-359): ');
  ReadString(TempName);
  TempBearing := StrToInt(TempName);

  GotoXY(1, 12);
  Write('Enter range (tenths of miles): ');
  ReadString(TempName);
  TempRange := StrToInt(TempName);

  (* Add to landmark array *)
  INC(LandmarkHIGH);
  WITH Landmark[LandmarkHIGH] DO BEGIN
    IF Length(TempName) >= 1 THEN Name[1] := TempName[1] ELSE Name[1] := ' ';
    IF Length(TempName) >= 2 THEN Name[2] := TempName[2] ELSE Name[2] := ' ';
    IF Length(TempName) >= 3 THEN Name[3] := TempName[3] ELSE Name[3] := ' ';
    Bearing := TempBearing;
    Range := TempRange;
  END;

  RenderMap;
END; (* AddLandmark *)

PROCEDURE AddSegment;
VAR
  TempStr : String40;
  TempR1, TempB1, TempR2, TempB2 : INTEGER;
BEGIN
  IF SegmentHIGH >= 500 THEN BEGIN
    GotoXY(1, 24);
    Write('Maximum segments reached!');
    REPEAT UNTIL KeyPressed;
    EXIT;
  END;

  TextMode;
  GotoXY(1, 10);
  Write('Enter first point bearing (0-359): ');
  ReadString(TempStr);
  TempB1 := StrToInt(TempStr);

  GotoXY(1, 11);
  Write('Enter first point range (tenths): ');
  ReadString(TempStr);
  TempR1 := StrToInt(TempStr);

  GotoXY(1, 12);
  Write('Enter second point bearing (0-359): ');
  ReadString(TempStr);
  TempB2 := StrToInt(TempStr);

  GotoXY(1, 13);
  Write('Enter second point range (tenths): ');
  ReadString(TempStr);
  TempR2 := StrToInt(TempStr);

  (* Add to segment array *)
  INC(SegmentHIGH);
  WITH Segment[SegmentHIGH] DO BEGIN
    Bear1 := TempB1;
    Range1 := TempR1;
    Bear2 := TempB2;
    Range2 := TempR2;
  END;

  RenderMap;
END; (* AddSegment *)

PROCEDURE SaveMapData;
VAR
  F : FILE OF BYTE;
  I : INTEGER;
  TempStr : String40;
BEGIN
  TextMode;
  GotoXY(1, 10);
  Write('Enter filename: ');
  ReadString(TempStr);

  Assign(F, TempStr);
  Rewrite(F);

  (* Write header information *)
  BlockWrite(F, LandmarkHIGH, SizeOf(INTEGER));
  BlockWrite(F, SegmentHIGH, SizeOf(INTEGER));

  (* Write landmark data *)
  FOR I := 1 TO LandmarkHIGH DO
    BlockWrite(F, Landmark[I], SizeOf(LandMarkRec));

  (* Write segment data *)
  FOR I := 1 TO SegmentHIGH DO
    BlockWrite(F, Segment[I], SizeOf(SegmentRec));

  Close(F);

  GotoXY(1, 15);
  Write('Map data saved successfully!');
  REPEAT UNTIL KeyPressed;
  RenderMap;
END; (* SaveMapData *)

PROCEDURE LoadMapData;
VAR
  F : FILE OF BYTE;
  I : INTEGER;
  TempStr : String40;
BEGIN
  TextMode;
  GotoXY(1, 10);
  Write('Enter filename: ');
  ReadString(TempStr);

  Assign(F, TempStr);
  Reset(F);

  (* Read header information *)
  BlockRead(F, LandmarkHIGH, SizeOf(INTEGER));
  BlockRead(F, SegmentHIGH, SizeOf(INTEGER));

  (* Read landmark data *)
  FOR I := 1 TO LandmarkHIGH DO
    BlockRead(F, Landmark[I], SizeOf(LandMarkRec));

  (* Read segment data *)
  FOR I := 1 TO SegmentHIGH DO
    BlockRead(F, Segment[I], SizeOf(SegmentRec));

  Close(F);

  GotoXY(1, 15);
  Write('Map data loaded successfully!');
  REPEAT UNTIL KeyPressed;
  RenderMap;
END; (* LoadMapData *)

PROCEDURE DisplayMenu;
BEGIN
  TextMode;
  GotoXY(20, 8);
  Write('═══════════════════════════════════');
  GotoXY(20, 9);
  Write('║     EME - Enhanced Map Editor   ║');
  GotoXY(20, 10);
  Write('═══════════════════════════════════');
  GotoXY(20, 11);
  Write('║ F1 - Add Landmark               ║');
  GotoXY(20, 12);
  Write('║ F2 - Add Segment                ║');
  GotoXY(20, 13);
  Write('║ F3 - Load Map Data              ║');
  GotoXY(20, 14);
  Write('║ F4 - Save Map Data              ║');
  GotoXY(20, 15);
  Write('║ F5 - Change Range Scale         ║');
  GotoXY(20, 16);
  Write('║ F6 - Clear All Data             ║');
  GotoXY(20, 17);
  Write('║ F7 - View Map                   ║');
  GotoXY(20, 18);
  Write('║ ESC - Exit                      ║');
  GotoXY(20, 19);
  Write('═══════════════════════════════════');
END; (* DisplayMenu *)

PROCEDURE ChangeRangeScale;
VAR
  Key : CHAR;
BEGIN
  TextMode;
  GotoXY(10, 10);
  Write('Select Range Scale:');
  GotoXY(10, 12);
  Write('1 - 5 miles    6 - 75 miles');
  GotoXY(10, 13);
  Write('2 - 10 miles   7 - 100 miles');
  GotoXY(10, 14);
  Write('3 - 25 miles   8 - 125 miles');
  GotoXY(10, 15);
  Write('4 - 35 miles   9 - 150 miles');
  GotoXY(10, 16);
  Write('5 - 50 miles   0 - 175 miles');

  REPEAT
    Read(Kbd, Key);
  UNTIL Key IN ['0'..'9'];

  CASE Key OF
    '1': CurrentRange := 0;
    '2': CurrentRange := 1;
    '3': CurrentRange := 2;
    '4': CurrentRange := 3;
    '5': CurrentRange := 4;
    '6': CurrentRange := 5;
    '7': CurrentRange := 6;
    '8': CurrentRange := 7;
    '9': CurrentRange := 8;
    '0': CurrentRange := 9;
  END;

  (* Adjust scale factor based on range *)
  ScaleFactor := 200.0 / RangeVal[CurrentRange];

  RenderMap;
END; (* ChangeRangeScale *)

(* Main Program *)
VAR
  Key : CHAR;
  Done : BOOLEAN;

BEGIN
  (* Initialize data *)
  LandmarkHIGH := 0;
  SegmentHIGH := 0;
  Done := FALSE;

  InitDisplay;

  REPEAT
    DisplayMenu;

    REPEAT
      Read(Kbd, Key);
    UNTIL Key IN [#59..#65, #27]; (* F1-F7, ESC *)

    CASE Key OF
      #59: AddLandmark;           (* F1 *)
      #60: AddSegment;            (* F2 *)
      #61: LoadMapData;           (* F3 *)
      #62: SaveMapData;           (* F4 *)
      #63: ChangeRangeScale;      (* F5 *)
      #64: BEGIN                  (* F6 - Clear *)
             LandmarkHIGH := 0;
             SegmentHIGH := 0;
             RenderMap;
           END;
      #65: RenderMap;             (* F7 *)
      #27: Done := TRUE;          (* ESC *)
    END;

  UNTIL Done;

  TextMode;
END. (* Enhanced_Map_Editor *)