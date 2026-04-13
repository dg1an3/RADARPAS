Program Music;

{$U+}
(* Note Frequencies:
     A  = 440
     A# = 466
     B  = 494
     C  = 523
     C# = 554
     D  = 587
     D# = 622
     E  = 659
     F  = 698
     F# = 740
     G  = 784
     G# = 831
     A  = 880
     A# = 932
     B  = 988
     C  = 1047
     C# = 1109
     D  = 1175
     D# = 1245
     E  = 1319
     F  = 1397
     F# = 1480
     G  = 1568
     G# = 1661
     A  = 1760
*)

Var
  Count : integer;

Begin
  For Count:=100 downto 1 do begin
    Sound(523);
    Delay(Count);
    Sound(659);
    Delay(Count);
    Sound(784);
    Delay(Count);
  End;
  NoSound;
End.