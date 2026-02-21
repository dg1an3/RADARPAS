MODULE Convert;

IMPORT FIO, IO, ScreenHandler, Lib, Graph, Graphics;

VAR
    D: FIO.DirEntry;

PROCEDURE GetLine
 ( F : FIO.File;
   VAR LineNum   : CARDINAL;
   VAR RedBitMap : ARRAY OF BYTE;
   VAR GrnBitMap : ARRAY OF BYTE );
VAR
  Count        : CARDINAL;
  Buffer       : RECORD
    CASE : CARDINAL OF
      1 : LineNum : CARDINAL; |
      2 : ChrData : ARRAY [ 0..2561 ] OF CHAR; |
      3 : Data    : ARRAY [ 0..1280 ] OF CARDINAL; |
    END; (* CASE : CARDINAL *)
  END; (* RECORD *)
  CheckSumCalc,
  CheckSumSent : CHAR;
  Rep,
  AtByte, AtBit,
  Size          : CARDINAL;
  Value         : BYTE;
  Color         : BITSET;
  I, J          : CARDINAL;
BEGIN
  Count := 0;
  CheckSumCalc := 000C;
  REPEAT
    I := FIO.RdBin(F, Buffer.ChrData[Count], 1 );
    INC(CheckSumCalc,ORD(Buffer.ChrData[Count]));
    INC(Count);
  UNTIL (Count>=2) AND (Count MOD 2=0)
  AND (Buffer.ChrData[Count-2]=030C);
(*  I := FIO.RdBin(F, CheckSumSent, 1); *)
  WITH Buffer DO
    IF LineNum<38400 THEN
      AtByte := 0;
      AtBit := 0;
      Count := 1;
      Lib.Fill(ADR(RedBitMap),SIZE(RedBitMap),0);
      Lib.Fill(ADR(GrnBitMap),SIZE(GrnBitMap),0);
      REPEAT
        Size:=Data[Count] DIV 256 + Data[Count] MOD 32 * 256;
        Color := BITSET(Data[Count] >> 5) * BITSET(03H);
        IF Size+AtBit<=8 THEN
          Value := BYTE(0FFH) >> BYTE(8-Size) << BYTE(AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF 0 IN Color... *)
          IF 1 IN Color THEN (* 1 = Green *)
            INC(GrnBitMap[AtByte],Value);
          END; (* IF 1 IN Color... *)
          AtBit:=AtBit+Size;
        ELSIF Size+AtBit<=1288 THEN
          Value := BYTE(0FFH) << BYTE(AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF *)
          IF 1 IN Color THEN
            INC(GrnBitMap[AtByte],Value);
          END;(* IF *)
          Size := Size+AtBit-8;
          AtBit := 0;
          AtByte := AtByte+1;
          IF Size+AtBit>8 THEN
            AtBit := Size MOD 8;
            Size := Size DIV 8;
            Value := BYTE(0FFH);
            IF 0 IN Color THEN (* 0 = Red *)
              Lib.Fill(ADR(RedBitMap[AtByte]),Size,Value);
            END (* IF 0 IN Color *);
            IF 1 IN Color THEN (* 1 = Green *)
              Lib.Fill(ADR(GrnBitMap[AtByte]),Size,Value);
            END (* IF 1 IN Color *);
            AtByte:=AtByte+Size;
          ELSE
            AtBit:=Size;
          END; (* IF *)
          Value := BYTE(0FFH) >> BYTE(8-AtBit);
          IF 0 IN Color THEN (* 0 = Red *)
            INC(RedBitMap[AtByte],Value);
          END; (* IF *)
          IF 1 IN Color THEN (* 1 = Green *)
            INC(GrnBitMap[AtByte],Value);
          END; (* IF *)
        ELSE
          Count := 641; (* Size>1280, so abort *)
        END (* IF Size+AtBit... *);
        Count := Count+1;
      UNTIL (Count>640) OR (Data[Count]=1818H);
    END (* IF LineNum... *)
  END (* WITH *);
  LineNum := Buffer.LineNum * 48 DIV 35;
END GetLine;

VAR
    Red, Grn  :  ARRAY [ 0..200 ] OF BYTE;
    Line, At  :  CARDINAL;
    Buf       :  ARRAY [ 0..32000 ] OF BYTE;
    F         :  FIO.File;

BEGIN

    Graph.InitEGA;
    Graph.GraphMode;
    Graphics.SetFont( 14 );
    Graphics.SetPalette(Graphics.PaletteType(0,36,50,54,63,63,63,63,9,9,9,9,9,9,9,9));
    FIO.IOcheck := FALSE;

    IF FIO.ReadFirstEntry( '*.PIC', FIO.FileAttr{}, D ) THEN

        At := 0;
        Line := 0;
        REPEAT
            F := FIO.Open( D.Name );
            IO.WrStr( D.Name );
            REPEAT
                GetLine( F, Line, Red, Grn );
                ScreenHandler.ComprLine( Line, Red, Grn, Buf, At );
            UNTIL FIO.EOF;
            FIO.Close( F );
            F := FIO.Create( D.Name );
            FIO.WrBin( F, Buf, At );
            FIO.Close( F );
        UNTIL ~ FIO.ReadNextEntry( D );

    END (* IF *);

END Convert.
