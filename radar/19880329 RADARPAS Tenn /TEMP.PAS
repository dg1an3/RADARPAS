procedure InitRS232; {& interrupt routine}
  begin
    DSave:=DSeg; Buf:='';
    with Registers do begin
      AH:=$25;
      if ComPort=$3F8 then AL:=$0C else AL:=$0B;
      DX:=Ofs(RS232Interupt)+7;
      DS:=CSeg;
      Intr($21,Registers);
    end;
    for I:=ComPort to ComPort+6 do J:=port[I];
    Port[ComPort+3]:=$80; {Set baud rate access bit}
    Port[ComPort]:= 48; {Set baud rate (2400 = 48)}
    Port[ComPort+1]:=$00;
    Port[ComPort+3]:=$03; {Set Line Control Data (8 data,1 stop,0 parity)}
    Port[ComPort+1]:=$09;
    Port[ComPort+4]:=$0B; {Set DTR & RTS high}
    UsrOutPtr:=Ofs(Tx);
  end;

