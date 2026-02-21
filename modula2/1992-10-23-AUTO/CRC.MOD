IMPLEMENTATION MODULE CRC;
(*
 *  REPERTOIRE
 *  Release 1.5
 *  (c) Copyright 1986, 1987 PMI
 *  Portland, Oregon
 *  All rights reserved
 *  Compuserve:  74706,262
 *  BIX:  pmi
 *
 *  Written and contributed by David Tingler of
 *  Telepath Systems, Inc., in Norman, Oklahoma.
 *
 *)

IMPORT LowLevel;
IMPORT SYSTEM;

VAR
  crctab: ARRAY [0..255] OF BITSET;


PROCEDURE CalcCRC( BufAdr: SYSTEM.ADDRESS; BufSize: CARDINAL ): CARDINAL;
  VAR
    segm, offs, h, i, crc: CARDINAL;
  BEGIN
    crc := 0;
    i := 0;
    h := BufSize - 1;
    segm := LowLevel.seg( BufAdr );
    offs := LowLevel.ofs( BufAdr );
    FOR i := 0 TO h DO
      AddCRC(crc, LowLevel.PeekByte(segm, offs + i));
    END;
    RETURN crc;
  END CalcCRC;


PROCEDURE AddCRC(VAR crc: CARDINAL; ch: SYSTEM.BYTE);
  VAR
    CRC, c: BITSET;
    tab: CARDINAL;
  BEGIN
    c   := BITSET( ORD(ch) );
    CRC := BITSET( crc );
    tab := CARDINAL( (CRC / c) * {0..7} );
      (* (crc XOR c) AND 0FFH *)
    CRC := (BITSET(CARDINAL(CRC) * 256) * {0..7}) / crctab[tab];
      (* (SHIFT(crc, -8) AND 0FFH) OR crctab[tab] *)
    crc := CARDINAL(CRC);
  END AddCRC;


VAR i: CARDINAL;

PROCEDURE Init(x: CARDINAL);
  BEGIN
    crctab[i] := BITSET(x);
    INC(i);
  END Init;

BEGIN
  i := 0;
  Init(00000H); Init(0C0C1H); Init(0C181H); Init(00140H);
  Init(0C301H); Init(003C0H); Init(00280H); Init(0C241H);
  Init(0C601H); Init(006C0H); Init(00780H); Init(0C741H);
  Init(00500H); Init(0C5C1H); Init(0C481H); Init(00440H);
  Init(0CC01H); Init(00CC0H); Init(00D80H); Init(0CD41H);
  Init(00F00H); Init(0CFC1H); Init(0CE81H); Init(00E40H);
  Init(00A00H); Init(0CAC1H); Init(0CB81H); Init(00B40H);
  Init(0C901H); Init(009C0H); Init(00880H); Init(0C841H);
  Init(0D801H); Init(018C0H); Init(01980H); Init(0D941H);
  Init(01B00H); Init(0DBC1H); Init(0DA81H); Init(01A40H);
  Init(01E00H); Init(0DEC1H); Init(0DF81H); Init(01F40H);
  Init(0DD01H); Init(01DC0H); Init(01C80H); Init(0DC41H);
  Init(01400H); Init(0D4C1H); Init(0D581H); Init(01540H);
  Init(0D701H); Init(017C0H); Init(01680H); Init(0D641H);
  Init(0D201H); Init(012C0H); Init(01380H); Init(0D341H);
  Init(01100H); Init(0D1C1H); Init(0D081H); Init(01040H);
  Init(0F001H); Init(030C0H); Init(03180H); Init(0F141H);
  Init(03300H); Init(0F3C1H); Init(0F281H); Init(03240H);
  Init(03600H); Init(0F6C1H); Init(0F781H); Init(03740H);
  Init(0F501H); Init(035C0H); Init(03480H); Init(0F441H);
  Init(03C00H); Init(0FCC1H); Init(0FD81H); Init(03D40H);
  Init(0FF01H); Init(03FC0H); Init(03E80H); Init(0FE41H);
  Init(0FA01H); Init(03AC0H); Init(03B80H); Init(0FB41H);
  Init(03900H); Init(0F9C1H); Init(0F881H); Init(03840H);
  Init(02800H); Init(0E8C1H); Init(0E981H); Init(02940H);
  Init(0EB01H); Init(02BC0H); Init(02A80H); Init(0EA41H);
  Init(0EE01H); Init(02EC0H); Init(02F80H); Init(0EF41H);
  Init(02D00H); Init(0EDC1H); Init(0EC81H); Init(02C40H);
  Init(0E401H); Init(024C0H); Init(02580H); Init(0E541H);
  Init(02700H); Init(0E7C1H); Init(0E681H); Init(02640H);
  Init(02200H); Init(0E2C1H); Init(0E381H); Init(02340H);
  Init(0E101H); Init(021C0H); Init(02080H); Init(0E041H);
  Init(0A001H); Init(060C0H); Init(06180H); Init(0A141H);
  Init(06300H); Init(0A3C1H); Init(0A281H); Init(06240H);
  Init(06600H); Init(0A6C1H); Init(0A781H); Init(06740H);
  Init(0A501H); Init(065C0H); Init(06480H); Init(0A441H);
  Init(06C00H); Init(0ACC1H); Init(0AD81H); Init(06D40H);
  Init(0AF01H); Init(06FC0H); Init(06E80H); Init(0AE41H);
  Init(0AA01H); Init(06AC0H); Init(06B80H); Init(0AB41H);
  Init(06900H); Init(0A9C1H); Init(0A881H); Init(06840H);
  Init(07800H); Init(0B8C1H); Init(0B981H); Init(07940H);
  Init(0BB01H); Init(07BC0H); Init(07A80H); Init(0BA41H);
  Init(0BE01H); Init(07EC0H); Init(07F80H); Init(0BF41H);
  Init(07D00H); Init(0BDC1H); Init(0BC81H); Init(07C40H);
  Init(0B401H); Init(074C0H); Init(07580H); Init(0B541H);
  Init(07700H); Init(0B7C1H); Init(0B681H); Init(07640H);
  Init(07200H); Init(0B2C1H); Init(0B381H); Init(07340H);
  Init(0B101H); Init(071C0H); Init(07080H); Init(0B041H);
  Init(05000H); Init(090C1H); Init(09181H); Init(05140H);
  Init(09301H); Init(053C0H); Init(05280H); Init(09241H);
  Init(09601H); Init(056C0H); Init(05780H); Init(09741H);
  Init(05500H); Init(095C1H); Init(09481H); Init(05440H);
  Init(09C01H); Init(05CC0H); Init(05D80H); Init(09D41H);
  Init(05F00H); Init(09FC1H); Init(09E81H); Init(05E40H);
  Init(05A00H); Init(09AC1H); Init(09B81H); Init(05B40H);
  Init(09901H); Init(059C0H); Init(05880H); Init(09841H);
  Init(08801H); Init(048C0H); Init(04980H); Init(08941H);
  Init(04B00H); Init(08BC1H); Init(08A81H); Init(04A40H);
  Init(04E00H); Init(08EC1H); Init(08F81H); Init(04F40H);
  Init(08D01H); Init(04DC0H); Init(04C80H); Init(08C41H);
  Init(04400H); Init(084C1H); Init(08581H); Init(04540H);
  Init(08701H); Init(047C0H); Init(04680H); Init(08641H);
  Init(08201H); Init(042C0H); Init(04380H); Init(08341H);
  Init(04100H); Init(081C1H); Init(08081H); Init(04040H);
END CRC.

