var
  InFile : file of integer;
  OutFile : file of integer;
  I       : integer;

begin
  Assign(InFile,'PIC.DAT');
  Assign(OutFile,'PIC.BAK');
  ReSet(InFile);
  ReWrite(OutFile);
  Read(InFile,I);
  repeat
    Read(InFile,I);
    repeat
      Write(OutFile,I);
      Read(InFile,I);
    until I=$1818;
    Read(InFile,I);
    Writeln(I);
  until (I>=351) or EOF(InFile) or KeyPressed;
  Close(InFile);
  Close(OutFile);
end.
