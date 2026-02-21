Program CheckSumTest;

{$C-}

(* Tests reliability of 8-bit checksums. *)

Var
  Data       : Array[0..1279] of Byte;
  DataLength : Integer; (* In bytes *)
  CheckSum   : Integer;
  AtByte     : Integer;
  AtBit      : Integer;

Procedure ChangeBit(BitNumber : Integer);
Begin
  Data[BitNumber div 8]:=Data[BitNumber div 8] xor (1 shl (BitNumber mod 8));
End; (* ChangeBit *)

Procedure ShowDataBinary;
Begin
  WriteLn;
  For AtByte:=0 to DataLength do begin
    If AtByte mod 8 = 0 then
      Write(AtByte:4);
    If AtByte mod 2 = 0 then
      Write('  ')
    else
      Write(' ');
    For AtBit:=0 to 7 do begin
      If Data[AtByte] and (1 shl AtBit)=0 then
        Write('0')
      else
        Write('1');
    End; (* For *)
  End; (* For *)
  WriteLn;
End; (* ShowDataBinary *)

Function BitPosToCode( BitPos : Integer) : Integer;
Begin
  If BitPos=127 then BitPosToCode:=64
  else if BitPos=126 then BitPosToCode:=32
  else if BitPos=125 then BitPosToCode:=16
  else if BitPos=124 then BitPosToCode:=8
  else if BitPos=123 then BitPosToCode:=4
  else if BitPos=122 then BitPosToCode:=2
  else if BitPos=121 then BitPosToCode:=1
  else if BitPos>57 then BitPosToCode:=BitPos+7
  else if BitPos>26 then BitPosToCode:=BitPos+6
  else if BitPos>11 then BitPosToCode:=BitPos+5
  else if BitPos>4 then BitPosToCode:=BitPos+4
  else if BitPos>1 then BitPosToCode:=BitPos+3
  else if BitPos=1 then BitPosToCode:=3;
End; (* BitPosToCode *)

Function CodeToBitPos( Code : Integer) : Integer;
Begin
  If Code>64 then CodeToBitPos:=Code-7
  else if Code=64 then CodeToBitPos:=127
  else if Code>32 then CodeToBitPos:=Code-6
  else if Code=32 then CodeToBitPos:=126
  else if Code>16 then CodeToBitPos:=Code-5
  else if Code=16 then CodeToBitPos:=125
  else if Code>8 then CodeToBitPos:=Code-4
  else if Code=8 then CodeToBitPos:=124
  else if Code>4 then CodeToBitPos:=Code-3
  else if Code=4 then CodeToBitPos:=123
  else if Code=3 then CodeToBitPos:=1
  else if Code=2 then CodeToBitPos:=122
  else if Code=1 then CodeToBitPos:=121;
End; (* CodeToBitPos *)

Var
  Redundancy : byte;

Procedure CalcRedundancy;
Var
  Count  : Integer;
Begin
  Redundancy:=0;
  For Count:=0 to DataLength*8 do
    if Data[Count div 8] and (1 shl (Count mod 8))<>0 then
      Redundancy:=Redundancy xor BitPosToCode(Count);
End;

Var
  AStr        : string[255] absolute Data;
  OldRedund   : byte;
  Rate        : Integer;
  Errors      : Integer;
  NotDetected : Integer;
  Key         : Char;
  Count       : Integer;

Begin
  AStr:='ABCDEFGHIJKLMNO';
  DataLength:=Length(AStr);
  Rate:=1;
  Errors:=0;
  NotDetected:=0;
  Key:=#0;
  Randomize;
  ClrScr;
  Repeat
    WriteLn(AStr);
    CalcRedundancy;
    OldRedund:=Redundancy;
    Count:=Random(DataLength*8-1)+1;
    ChangeBit(Count);
    WriteLn('CHANGED AT ',Count);
    WriteLn(AStr);
    CalcRedundancy;
    OldRedund:=OldRedund xor Redundancy;
    Count:=CodeToBitPos(OldRedund);
    ChangeBit(Count);
    WriteLn('CORRECTED AT ',Count);
    WriteLn(AStr);
    WriteLn;
    If KeyPressed then begin
      Read(Kbd,Key);
      Case Key of
        '+' : Rate:=Rate+1;
        '-' : Rate:=Rate-1;
      End; (* Case *)
      Errors:=0;
      NotDetected:=0;
    End; (* If *)
  Until Key=#27;
End.