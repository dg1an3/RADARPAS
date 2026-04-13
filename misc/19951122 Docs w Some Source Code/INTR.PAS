type
  RegisterType     = record
    case integer of
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : integer);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;
var
  MessReady        : char;
  Registers        : RegisterType;
  Key              : char;
  Buf              : string[20];
const
  DSave            : integer = 0;
  ComPort          = $2F8;
procedure ReadKbd;
begin
  Read(Kbd,Key);
end;

procedure RS232Interupt;
  begin
    inline($FB/       {STI}
           $1E/       {PUSH DS}
           $50/       {PUSH AX}
           $53/       {PUSH BX}
           $51/       {PUSH CX}
           $52/       {PUSH DX}
           $57/       {PUSH DI}
           $56/       {PUSH SI}
           $06);      {PUSH ES}
    inline($8C/$C8/   {MOV AX,CS}
           $8E/$D8/   {MOV DS,AX}
           $A1/DSave/ {MOV AX,DSave}
           $8E/$D8);  {MOV DS,AX}
    Write('*');
    port[$20]:=$20;
    case port[ComPort+2] of
      0 : Write('MODEM STATUS ');
      1 : Write('NOT AN INTERRUPT ');
      2 : Write('THRE INTERRUPT ');
      4 : begin
            Write('DATA READY -');
            Write(port[ComPort]:5);
          end;
      6 : Write('LINE STATUS ')
      ELSE Write('UNKNOWN ');
    end;
(*    if port[ComPort+2]=$04 then
      case Mode of
        Modem :
        begin
          Buf:=Buf+Chr(port[ComPort]);
          if (Buf[Length(Buf)]=#10) or (Buf[Length(Buf)]=#13) then begin
            if Length(Buf)>1 then MessReady:=Buf[1];
            Buf:='';
          end;
        end;
        Interactive,WaitPic :
        begin
          Buf:=Buf+Chr(port[ComPort]);
          if Length(Buf)=10 then begin
            SetParams(Buf,CurrentParams);
            Tx('A');
            Buf:='';
          end;
          if Mode=WaitPic then
            if (Buf[1]=#$FF) and (Buf[2]=#$FE) and (Buf[3]=#$FD) then begin
              Mode:=RxPic; GRSize:=0;
              CheckSum:=0;
            end;
        end;
        RxPic :
        begin
          GRSize:=GRSize+1;
          GRBuf[GRSize]:=port[ComPort];
          if (GRSize and $01)=$01 then
          if (GRBuf[GRSize-1]=$18) and
            (GRBuf[GRSize-2]=$18) and (GRSize>6) then begin
            CheckSum:=0;
            for I:=1 to GRSize-1 do CheckSum:=CheckSum+GRBuf[I];
            LineNum:=LineNum div 54;
            if (LineNum>=LastLine) and (LineNum<=352)
              and (CheckSum=GRBuf[GRSize]) then begin
              Tx('A');
              Move(GRBuf,PicSave[PicSaveAt],GRSize-1);
              LineAt:=PicSaveAt;
              PicSaveAt:=PicSaveAt+GRSize-1;
              Tx('O');
              GRSize:=0;
            end else begin
              Tx(#0);
              GRSize:=0;
            end;
            if LineNum>=352 then Mode:=Modem;
          end;
        end;
        RxGraph :
        begin
          BufPtr^[BufCount]:=port[ComPort]; BufCount:=BufCount+1;
          if BufCount=9 then begin
            CheckSum:=0;
            for I:=1 to 8 do CheckSum:=CheckSum+BufPtr^[I];
            if {CheckSum=BufPtr^[BufCount]}true then begin
              if (BufPtr^[1]=0) and (BufPtr^[2]=0) and
                (BufPtr^[3]=0) and (BufPtr^[4]=0) then
              begin
                Sound(440); Delay(100); NoSound;
                MapCount:=MapCount+1;
                case MapCount of
                  1 : BufPtr:=Addr(Seg1);
                  2 : BufPtr:=Addr(Land2);
                  3 : BufPtr:=Addr(Seg2);
                end;
              end else BufPtr:=Ptr(Seg(BufPtr^),Ofs(BufPtr^)+8);
              BufCount:=1;
              Delay(5);
              Tx('A');
            end else Tx(#0);
            BufCount:=1;
          end;
        end;
    end;
    if port[ComPort+2]=$00 then
      if (port[ComPort+6] and $88)=$88 then Mode:=Modem; *)
    inline($07/       {POP ES}
           $5E/       {POP SI}
           $5F/       {POP DI}
           $5A/       {POP DX}
           $59/       {POP CX}
           $5B/       {POP BX}
           $58/       {POP AX}
           $1F);      {POP DS}
    port[$20]:=$20; {EOI for 8529}
    inline($CF);      {IRET}
  end;

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
    Port[ComPort+3]:=$80; {Set baud rate access bit}
    Port[ComPort]:= 48; {Set baud rate (2400 = 48)}
    Port[ComPort+1]:=$00;
    Writeln('BAUD RATE SET - 2400');
    Port[ComPort+3]:=$03; {Set Line Control Data (8 data,1 stop,0 parity)}
    Writeln('8 data, 1 stop, 0 parity.');
    Port[ComPort+1]:=$09;
    Writeln('NO INTERRUPTS');
    Port[ComPort+4]:=$0B; {Set DTR & RTS high}
    Writeln('DTR & DSR high');
    if ComPort=$3F8 then port[$21]:=port[$21] and not(1 shl 4)
    else port[$21]:=port[$21] and not(1 shl 3);
    port[$20]:=$20;
    Writeln('8259 interrupt 3 or 4 enabled');
(*    UsrOutPtr:=Ofs(Tx); *)
    Writeln('Press any key');
    ReadKbd;
  end;

begin
  InitRS232;
  repeat
    Write('PRESS ANOTHER KEY.');
    ReadKbd;
  until Key=^C;
end.