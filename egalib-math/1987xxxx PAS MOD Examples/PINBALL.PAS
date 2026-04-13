Program Pinball;

{$I GRAPH.P}

Var
  Ball,
  BallBack : Array[1..40] of Byte;
  X, Y     : Real;
  dX, dY,
  ddX, ddY : Real;
  t        : Real;

Procedure NextState;
Var
  OldX, OldY : Integer;
Begin
  OldX:=TRUNC(X); OldY:=TRUNC(Y);
  X:=X+dX; Y:=Y+dY;
  PutPic(BallBack,OldX,OldY);
  GetPic(BallBack,TRUNC(X),TRUNC(Y)+10,TRUNC(X)+10,TRUNC(Y));
  PutPic(Ball,TRUNC(X),TRUNC(Y));
End; (* NextState *)

Begin
  GraphColorMode;
  Palette(2);
  (* Set up ball image *)
  Circle(100,100,5,1);
  Circle(100,100,4,2);
  Circle(100,100,3,3);
  Circle(100,100,2,1);
  Circle(100,100,1,1);
  GetPic(Ball,95,95,105,105);
  ClearScreen;
  Draw(0,149,20,199,3);
  Draw(269,199,319,149,3);
  X:=10.0; Y:=10.0;
  dX:=0.4; dY:=0.5;
  ddX:=0.0; ddY:=0.02;
  GetPic(BallBack,TRUNC(X),TRUNC(Y)+10,TRUNC(X)+10,TRUNC(Y));
  Repeat
    NextState;
(*    GotoXY(1,1);
    Write('dX:',dX:10:5,'dY:',dY:10:5); *)
    if (X<10) and (dx<0) then dX:=-0.9*dX;
    if (X>309) and (dx>0) then dX:=-0.9*dX;
    if (Y<10) and (dY<0) then dY:=-0.9*dY;
    if (Y>190) and (dY>0) then dY:=-0.9*dY;
    if (X+Y>468) and (dX>0) then begin
      Write('BAM! ');
      t:=dX*-1.01; dX:=dY*-1.01; dY:=t;
    end;
    dY:=dY+ddY; dX:=dX+ddX;
    dX:=dX*0.9999;
  Until KeyPressed;
End.
