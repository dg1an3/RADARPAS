Program Lines;

Procedure UpDate(VAR Coor, Delta : Integer; Min, Max : Integer);
Begin
  Coor:=Coor+Delta;
  If (Coor<Min) then Coor:=Min
  else if (Coor>Max) then Coor:=Max
  else Exit;
  Delta:=-Delta;
End; (* UpDate *)

Const
  NumLines = 500;

Var
  X1, dX1, Y1, dY1,
  X2, dX2, Y2, dY2  : Integer;
  OldX1, OldY1, OldX2, OldY2 : Array [1..1000] of Integer;
  Count, OldCount : Integer;
  PreCount : Integer;
  Stop : boolean;
  Key : char;
Begin
  GraphColorMode;
  Draw(0,0,319,0,3);
  Draw(319,0,319,199,3);
  Draw(319,199,0,199,3);
  Draw(0,199,0,0,3);
  X1:=50; dX1:=2;
  Y1:=102; dY1:=-4;
  X2:=90; dX2:=2;
  Y2:=11; dY2:=3;
  PreCount:=NumLines;
  Stop:=false;
  Repeat
    if KeyPressed then Stop:=true;
    If not Stop then begin
      Count:=Count+1;
      If Count>1000 then Count:=1;
      UpDate(X1,dX1,1,318); OldX1[Count]:=X1;
      UpDate(Y1,dY1,1,198); OldY1[Count]:=Y1;
      UpDate(X2,dX2,1,318); OldX2[Count]:=X2;
      UpDate(Y2,dY2,1,198); OldY2[Count]:=Y2;
      Draw(X1,Y1,X2,Y2,2);
    end;
    If PreCount=0 then begin
      OldCount:=Count-NumLines;
      If OldCount<1 then OldCount:=OldCount+1000;
      Draw(OldX1[OldCount],OldY1[OldCount],
           OldX2[OldCount],OldY2[OldCount],0);
    end else PreCount:=PreCount-1;
  Until Stop and (OldCount=Count);
End.