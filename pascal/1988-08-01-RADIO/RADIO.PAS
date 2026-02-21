{.PA}
{*****************************************************************************}
{* Continuous Transmission                                                   *}
{*****************************************************************************}

procedure RadioTx;
var
  At       : integer;
  CurrLine : ^integer;
  StrA     : string[5];
  CheckSum : byte;

  procedure TxCheck(ForByte : BYTE);
  begin
    Tx(CHR(ForByte));
    CheckSum:=CheckSum+ForByte;
  end;

begin
  if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
  InitRS232;
  Port[ComPort+3]:=$80; {Set baud rate access bit}
  Port[ComPort]:= 48; {Set baud rate (2400 = 48)}
  Port[ComPort+1]:=$00;
  Port[ComPort+3]:=$03; {Set Line Control Data (8 data,1 stop,0 parity)}
  Port[ComPort+1]:=$09;
  Port[ComPort+4]:=$0B; {Set DTR & RTS high}
  At:=-20000;
  repeat
    CheckSum:=0;
    CurrLine:=ADDR(PicSave[At]);
    Str(CurrLine^,StrA);
    GRMessage('SENDING LINE '+StrA,false);
    with Pic[CurrPic] do begin
      TxCheck(Tilt);
      TxCheck(Range);
      TxCheck(Gain);
      TxCheck(Time.Hour);
      TxCheck(Time.Minute);
    end; (* with *)
    repeat
      TxCheck(PicSave[At]);
      At:=At+1;
    until (PicSave[At-1]=$18) and (PicSave[At-2]=$18) and (At mod 2=0);
    Tx(CHR(CheckSum));
    if KeyPressed then begin
      ReadKbd;
      if Ask('END TRANSMISSION AT LINE '+StrA) then Key:=#27;
    end;
    if CurrLine^>=350 then At:=-20000;
    Delay(50);
  until Key=#27;
  Key:=#0;
  if ComPort=$3F8 then ComPort:=$2F8 else ComPort:=$3F8;
end; (* RadioTx *)

