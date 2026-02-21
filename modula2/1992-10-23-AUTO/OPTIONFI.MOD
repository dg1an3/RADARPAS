MODULE OptionFile;

IMPORT FIO, Str;

TYPE
  OptionRec   = RECORD
    Name      :   ARRAY [ 0..11 ] OF CHAR;
    VarAt     :   ADDRESS;
    VarLength :   CARDINAL;
    StrLength :   CARDINAL;
    WrProc    :   PROCEDURE(ARRAY OF BYTE);
    ModProc   :   PROCEDURE(VAR ARRAY OF BYTE);
  END (* RECORD *);

VAR
  OptionFileName : ARRAY [ 0..23 ] OF CHAR;
  Option         : ARRAY [ 0..11 ] OF OptionRec;
  LastOption     : CARDINAL;

PROCEDURE DefineOption
( Name       : ARRAY OF CHAR;
  VAR OptVar : ARRAY OF BYTE;
  StrLength  : CARDINAL );
BEGIN
  IF LastOption<12 THEN
    Str.Copy( Option[LastOption].Name, Name );
    Option[LastOption].VarAt := ADR(OptVar);
    Option[LastOption].VarLength := HIGH(OptVar);
    Option[LastOption].StrLength := StrLength;
    INC(LastOption);
  END (* IF *);
END DefineOption;

PROCEDURE LoadOptions;
VAR
  F     : FIO.File;
  Size,
  Count : CARDINAL;
BEGIN
  F := FIO.Open( OptionFileName );
  IF F<MAX(CARDINAL) THEN
    FOR Count := 0 TO LastOption-1 DO
      Size := FIO.RdBin( F, Option[Count].VarAt^, Option[Count].VarLength );
    END (* FOR *);
  END (* IF *);
END LoadOptions;

PROCEDURE SaveOptions;
VAR
  F     : FIO.File;
  Count : CARDINAL;
BEGIN
  F := FIO.Open( OptionFileName );
  IF F<MAX(CARDINAL) THEN
    FOR Count := 0 TO LastOption-1 DO
      FIO.WrBin( F, Option[Count].VarAt^, Option[Count].VarLength );
    END (* FOR *);
  END (* IF *);
END SaveOptions;

PROCEDURE SetOptions;
BEGIN
END SetOptions;

BEGIN
END OptionFile.
