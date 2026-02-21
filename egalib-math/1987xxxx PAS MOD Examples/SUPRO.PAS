program SUPRO_DIOS; { Operating System: Disk IO Subsystem}

type
  RegisterType     = record
    case integer of
      1 : (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags : integer);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH          : byte);
                     end;

  DirEntry         = record
    Name           :   array[1..16] of char;
    Extension      :   array[1..4] of char;
    FirstSector    :   integer;
    SizeSectors    :   integer;
    RecordSize     :   integer;
    LastEntry      :   boolean;
    Extra          :   array[1..5] of byte;
                     end;
var
  Registers        : RegisterType;
  DiskDir          : array[1..32] of DirEntry;
  I,J,K            : integer;
  Name             : string[25];

procedure ReadSector(SectNum,NumSectors : integer; var ToVar);
  begin
    with Registers do begin
      AH:=$02; {Op code for read}
      AL:=NumSectors; {Number of sectors}
      BX:=Ofs(ToVar); {Set Buffer}
      ES:=Seg(ToVar);
      CH:=SectNum div 18; {Track Number}
      DH:=SectNum mod 18 div 9; {Head Number}
      CL:=SectNum mod 9 +1; {Sector Number}
      DL:=1; {Drive Number}
      Intr($13,Registers);
    end;
  end;

procedure WriteSector(SectNum,NumSectors : integer; var FromVar);
  begin
    with Registers do begin
      AH:=$03; {Op code for write}
      AL:=NumSectors; {Number of sector}
      BX:=Ofs(FromVar); {Set Buffer}
      ES:=Seg(FromVar);
      CH:=SectNum div 18; {Track Number}
      DH:=SectNum mod 18 div 9; {Head Number}
      CL:=SectNum mod 9 +1; {Sector Number}
      DL:=1; {Drive Number}
      Intr($13,Registers);
    end;
  end;

var
  ComLine          : string[255];

procedure ShowDir;
  begin
  end;

procedure Copy;
  begin
  end;

begin
  ReadSector(1,2,DiskDir);
  repeat
    Writeln(DiskDir[1].Name);
    Write(':>'); Readln(ComLine);
    if ComLine='dir' then ShowDir;
    if ComLine='copy' then Copy;
  until ComLine='exit';
end.
