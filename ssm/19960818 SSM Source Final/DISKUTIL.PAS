(* DiskUtil.pas  Disk handling routines *)
(* Copyright (C) 1985,1996 Derek G. Lane *)

type    SearchHandle  = record
            dta  : array [0..127] of byte;
            mask  : LongStr;
            option  : integer;
        end (* SearchHandle *);

        RegType  = record
            case integer of
                1 : (ax, bx, cx, dx, bp, si, di, ds, es, flags  : integer);
                2 : (al, ah, bl, bh, cl, ch, dl, dh  : byte);
        end (* RegType *);


procedure Setdta(var dta);
var     regs  : RegType;
begin   with regs do begin
            ah := $1a;
            ds := seg(dta);
            dx := ofs(dta);
            msdos(regs);
        end (* with *);
end (* Setdta *);

function SetSearch(var h  : SearchHandle; mask  : LongStr;
            option  : integer)  : integer;
var     regs  : RegType;
        key  : char;
begin   Setdta(h.dta);
        h.option := option;
        h.mask := mask + #0;
        with regs do begin
            ah := $4e;
            ds := seg(h.mask);
            dx := ofs(h.mask)+1;
            cx := h.option;
            msdos(regs);
            if ((flags and $01) <> 0) then
                SetSearch := ax
            else
                SetSearch := 0;
        end (* with *);
end (* SetSearch *);

function NextFile(var h  : searchHandle; var fileName  : LongStr)  : integer;
var     regs  : RegType;
        count  : integer;
begin   Setdta(h.dta);
        fileName := '';
        count := 30;
        repeat
            fileName := fileName + Chr(h.dta[count]);
            count := count + 1;
        until (h.dta[count] = 0);
        with regs do begin
            ah := $4f;
            cx := h.option;
            msdos(regs);
            if ((flags and $01) <> 0) then
                NextFile := ax
            else
                NextFile := 0;
        end (* with *);
end (* NextFile *);

function ActFileSize(fileName  : LongStr)  : real;
var     h  : SearchHandle;
        result  : integer;
begin   result := SetSearch(h, fileName, $00);
        if (result = 0) then
            ActFileSize := h.dta[26] + h.dta[27]*256.0 +
                65536.0*(h.dta[28] + h.dta[29]*256.0)
        else
            ActFileSize := 0;
end (* ActFileSize *);

function DefaultDrive  : byte;
var     regs  : RegType;
begin   with regs do begin
            ah := $19;
            msdos(regs);
            DefaultDrive := al+1;
        end (* with *);
end (* DefaultDrive *);

function DiskMemory(drive  : byte)  : real;
var     regs  : RegType;
begin   with regs do begin
            ah := $36;
            dl := drive;
            msdos(regs);
            DiskMemory := ((ax*cx*1.0)*bx);
        end (* with *);
end (* DiskMemory *);
