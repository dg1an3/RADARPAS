          ^P  : begin
                  SelectStation;
                  if Mode=Interactive then begin
                    Delay(1000); Write(Usr,'+++'); Delay(1500);
                    Write(Usr,'ATS18=0&T6');
                    Writeln('1v1;25fษออออออออREMOTE TESTออออออออป');
                    Writeln(     '25tบ Type any characters :     บ');
                    Writeln(     '25tบ                           บ');
                    Writeln(     '25tบ                           บ');
                    Writeln(     '25tบ ERRORS : 0                บ');
                    Writeln(     '25tศอออออออออออออออออออออออออออผ1;27f'_');
                    Buf:=''; I:=0;
                    repeat
                      ReadKbd; Write(^H,^H,Key);
                      Tx(Key); Delay(100);
                      Write(^J,^H,Buf[1],'u',^H,'_ ');
                      if Buf[1]<>Key then begin
                        I:=I+1; Write('5;36f',I);
                      end;
                      Buf:='';
                    until Key:=^M;
                    Delay(1000); Write(Usr,'+++'); Delay(1500);
                    Writeln(Usr,'ATH');
                    ClearScreen; Write('0v');
                  end;
                end;
