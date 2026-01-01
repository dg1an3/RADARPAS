{$U+}
program Modem;

type
  RegisterType     = record
    case integer of
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : integer);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;

const
  ComPort          : integer = $3F8;

var
  Registers        : RegisterType;
  Key              : char;
  Escape           : boolean;
  I,J              : integer;

{*****************************************************************************}
{* RS232 Routines                                                            *}
{*****************************************************************************}
var
  Buf              : array[0..1000] of char;
  DSave            : integer;
  Head,Tail        : integer;

procedure HangUp;

  begin
    Port[ComPort+4]:=$08; Delay(1000); Port[ComPort+4]:=$0B;
  end;

procedure Tx(Charac : char);
  begin
    repeat until (port[ComPort+5] and $20)=$20;
    Port[ComPort]:=ord(Charac);
  end;

function Rx : char;
  begin
    if Tail=Head then Rx:=#0
    else begin
      Rx:=Buf[Tail];
      Tail:=Tail+1;
    end;
  end;

procedure RS232Interupt;
  begin
    inline($1E/       {PUSH DS}
           $50/       {PUSH AX}
           $53/       {PUSH BX}
           $51/       {PUSH CX}
           $52/       {PUSH DX}
           $57/       {PUSH DI}
           $56/       {PUSH SI}
           $06/       {PUSH ES}
           $8C/$C8/   {MOV AX,CS}
           $8E/$D8/   {MOV DS,AX}
           $A1/DSave/ {MOV AX,DSave}
           $8E/$D8/$FB);  {MOV DS,AX}
{    if port[ComPort+2]=$04 then begin}
      Buf[Head]:=Chr(port[ComPort]);
      Write(Buf[Head]);
      Head:=Head+1;
{      Sound(440); Delay(10); NoSound;
    end;}
    port[$20]:=$20;
    inline($07/       {POP ES}
           $5E/       {POP SI}
           $5F/       {POP DI}
           $5A/       {POP DX}
           $59/       {POP CX}
           $5B/       {POP BX}
           $58/       {POP AX}
           $1F);      {POP DS}
    inline($FB);      {STI}
    inline($CF);      {IRET}
  end;

procedure InitRS232; {& interrupt routine}
  begin
    DSave:=DSeg; Tail:=0; Head:=0;
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
    Port[ComPort+4]:=$00; {Set DTR & RTS high}
    if ComPort=$3F8 then port[$21]:=port[$21] and not(1 shl 4)
    else port[$21]:=port[$21] and not(1 shl 3);
    UsrOutPtr:=Ofs(Tx);
    UsrInPtr:=Ofs(Rx);
  end;

begin
  InitRS232;
  Write(Usr,'AT&F',^M);
  Delay(500);
  Write(Usr,'ATS10=255 &L1 &M3',^M);
  Delay(1000);
  Port[ComPort+4]:=$01;
  Delay(1000);
  Write(Usr,'HELLO, TESTING!!!');
end.