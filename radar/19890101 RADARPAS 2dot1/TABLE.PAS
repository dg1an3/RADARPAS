Program Table;

(* Calculate height table for radar. *)

Var
  Range, Tilt : Integer;
  TiltRad     : Real;
  HeightMiles : Real;
  R           : Real;
  ToFile      : Text;

Const
  Pi = 3.141592654;
  ER = 3956.56;

Begin
  Assign(ToFile,'HEIGHT.TAB');
  ReWrite(ToFile);
  Write(ToFile,'        ');
  For Tilt := 0 to 20 do
    If Tilt in [0,1,2,3,4,5,6,8,10,12,15,20] then
      Write(ToFile,Tilt:7);
  WriteLn(ToFile);
  For Range := 1 to 20 do begin
    Write(ToFile,Range*10:6,'  ');
    For Tilt := 0 to 20 do begin
      If Tilt in [0,1,2,3,4,5,6,8,10,12,15,20] then begin
        R := 10.0*Range;
        TiltRad := (Tilt+90)*Pi/180;
        HeightMiles := SqRt(ER*ER + R*R - 2*ER*R*Cos(TiltRad))-ER;
        Write(ToFile,HeightMiles*5380:7:0);
      End;
    End;
    WriteLn(ToFile);
  End;
  Close(ToFile)
End.