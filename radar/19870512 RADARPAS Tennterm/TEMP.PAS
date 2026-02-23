procedure Tx(Charac : char);
  begin
    repeat until (port[ComPort+5] and $20)=$20;
    Port[ComPort]:=ord(Charac);
  end;

