MODULE E300RadarTerm;
(*
Title   : Ellason 300 Radar Terminal
Version : 1.0
LastEdit: 
Author  : Derek Lane
System  : LOGITECH MODULA-2/86 
*)

IMPORT Screen,RS232,Modem,Storage; (* Major Submodules *)
IMPORT ASCII,Keyboard; (* Miscellaneous *)
FROM SYSTEM IMPORT ADR;

VAR
  HelpOn : BOOLEAN;

PROCEDURE ToggleHelp; 
BEGIN (* Toggles Help screens on and off *)
  IF HelpOn THEN 
    HelpOn:=FALSE;
  ELSE
    HelpOn:=TRUE;
    IF RS232.Mode(Offline) THEN
      GotoXY(1,3); WriteString('F1 CALL STATION');
      GotoXY(1,4); WriteString('F2 REDIAL')
    ELSIF RS232.Mode(OnLine) THEN
      GotoXY(1,3); WriteString('F7 SEND PICTURE');
      GotoXY(1,4); WriteString('         ');
    ELSIF RS232.Mode(RxPic) THEN
      GotoXY(1,3);
    END;
  END;
END ToggleHelp;

PROCEDURE AuxCommand(Command : CHAR); (* Processes screen-related commands *)
BEGIN 
  CASE Command OF
    'G' : Screen.ToggleGraphics|
    'R' : Screen.ToggleRangeMarks|
    '1' : Screen.ToggleMap1|
    '2' : Screen.ToggleMap2|
    'H' : ToggleHelp
  END;
END AuxCommand;

PROCEDURE ReceivePicture; (* Loop for downloading the weather picture *)
VAR 
  WriteAt : CARDINAL;
BEGIN 
  RS232.SendCom(RS232.SendPic);
  IF RS232.Response THEN
    Screen.Message('WAITING FOR PICTURE');
    Screen.DrawScale;
    RS232.Buffer:=ADR(Storage.PicBuf);
    IF RS232.Mode(RS232.RxPic) THEN
      Screen.DecompPic(RS232.Buffer,WriteAt,RS232.BufferAt);
    END;
  END;
END ReceivePicture;

PROCEDURE Online; (* Loop for interacting with the radar *)
VAR 
  ComKey,ExtKey : CHAR;
BEGIN 
  LOOP
    Keyboard.Read(ComKey); (* Read the keyboard *)
    IF Keyboard.KeyPressed() THEN (* Another keycode? *)
      Keyboard.Read(ExtKey); (* Get it. *)
    ELSE
      ExtKey:=ASCII.nul;
    END;
    IF ComKey=ASCII.esc THEN (* Extended code? *)
      CASE ExtKey OF
        ';' : RS232.SendCom(RS232.TiltUp); (* F1 Key = Tilt Up *)
              IF RS232.Response THEN
                Storage.CurrParams.Tilt:=Storage.CurrParams.Tilt+1;
                Screen.WriteParams;
              END|
        '<' : RS232.SendCom(RS232.TiltDown); (* F2 Key = Tilt Down *)
              IF RS232.Response THEN
                Storage.CurrParams.Tilt:=Storage.CurrParams.Tilt-1;
                Screen.WriteParams;
              END|
        '=' : RS232.SendCom(RS232.RangeUp); (* F3 Key = Range Up *)
              IF RS232.Response THEN
                Storage.CurrParams.Range:=Storage.CurrParams.Range+1;
                Screen.WriteParams;
                Screen.WriteScreen;
              END|
        '>' : RS232.SendCom(RS232.RangeDown); (* F4 Key = Range Down *)
              IF RS232.Response THEN
                Storage.CurrParams.Range:=Storage.CurrParams.Range-1;
                Screen.WriteParams;
                Screen.WriteScreen;
              END|
        '?' : RS232.SendCom(RS232.GainUp); (* F5 Key = Gain Up *)
              IF RS232.Response THEN
                Storage.CurrParams.Gain:=Storage.CurrParams.Gain+1;
                Screen.WriteParams;
              END|
        'A' : RS232.SendCom(RS232.GainDown); (* F6 Key = Gain Down *)
              IF RS232.Response THEN
                Storage.CurrParams.Gain:=Storage.CurrParams.Gain+1;
                Screen.WriteParams;
              END|
        'B' : ReceivePicture|
        ASCII.nul: IF Screen.Ask('DISCONNECT STATION') THEN 
                     Modem.HangUp;
                     EXIT;
                   END
      END (* CASE ExtKey OF*)
    ELSE  
      AuxCommand(ComKey); (* Otherwise, process the G,R,1,2, or H key *)
    END; (* IF ComKey=ASCII.esc*)
    IF RS232.Mode(RS232.Modem) THEN EXIT; END; (* EXIT if radar hung up *)
  END; (* LOOP *)
END Online;

PROCEDURE Offline;
VAR
  ComKey,ExtKey : CHAR;
BEGIN
  LOOP
    Keyboard.Read(ComKey); (* Read the keyboard *)
    IF Keyboard.KeyPressed() THEN (* Another keycode? *)
      Keyboard.Read(ExtKey); (* Get it. *)
    ELSE
      ExtKey:=ASCII.nul;
    END;
    IF ComKey=ASCII.esc THEN (* Extended code? *)
      CASE ExtKey OF
        ';' : Storage.SelectStation;
              IF Modem.Connected THEN
                Online;
              END|
        '<' : Modem.Call(Storage.PhoneNum);
              IF Modem.Connected THEN
                Online;
              END
      END; (* CASE ExtKey OF *)
    ELSE
      AuxCommand(ComKey); (* Otherwise, process the G,R,1,2, or H key *)     
    END; (* IF ComKey=ASCII.esc *)
  END; (* LOOP *)
END Offline;

BEGIN
  Screen.Initialize;
  RS232.Initialize;
  Modem.Initialize;
  Storage.Initialize;
  Storage.SelectStation;
  IF Modem.Connected THEN
    Online;
  END;
  Offline;
  Screen.Deinit;
  RS232.Deinit;
  Storage.Deinit;
END E300RadarTerm.
