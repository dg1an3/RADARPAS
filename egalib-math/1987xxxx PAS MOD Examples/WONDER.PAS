Program Wondrous;

Const
  Trace = FALSE;

Function NextInSequence(Number : INTEGER) : INTEGER;
Begin
  If Trace then WriteLn('  -> ',Number);
  If (Number MOD 2)=0 then
    NextInSequence:=Number DIV 2
  else
    NextInSequence:=Number*3+1;
End; (* NextInSequence *)

Function IsWondrous(Number : INTEGER) : BOOLEAN;
Begin
  If Number=1 then
    IsWondrous:=TRUE
  else
    IsWondrous:=IsWondrous(NextInSequence(Number));
End; (* IsWondrous *)

Var
  Count : INTEGER;

Begin
  For Count:=1 TO 1000 do
    WriteLn(Count,' ',IsWondrous(Count));
End.
