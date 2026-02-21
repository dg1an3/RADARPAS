IMPLEMENTATION MODULE Options;

IMPORT ASCII;

IMPORT FIO;

FROM Graphics IMPORT
  SetPlane, SetFunc, clr, or, FillArea, SetWindow, GotoXY;

FROM IO IMPORT
  WrStr, WrLn, WrCard;

FROM Lib IMPORT
  Fill;

FROM Selector IMPORT
  Select;

FROM SYSTEM IMPORT
  ADR;

PROCEDURE WriteOptionEntry( ForItem : CARDINAL );
BEGIN
  CASE ForItem OF
    1 : WrStr( '   Modem port : ' );
        IF ModemPort = 1 THEN
            WrStr( 'COM1:' );
        ELSE
            WrStr( 'COM2:' );
        END (* IF *); |
    2 : WrStr( '   Modem baud : ' );
        WrCard( ModemBaud, 1 ); |
    3 : WrStr( '   Modem type : Hayes Compatible' ); |
    4 : WrStr( '        Clock : ' );
        IF ClockType = 1 THEN
            WrStr( '12 hour ' );
        ELSE
            WrStr( '24 hour ' );
        END (* IF *); |
    5 : WrStr( ' Printer type : Epson MX80      ' );
  END (* CASE *);
END WriteOptionEntry;


PROCEDURE OptionMenu;

VAR
  OptionSelect : CARDINAL;
  Key          : CHAR;
  Escape       : BOOLEAN;

CONST
  NumofOptions = 5;

BEGIN

  (* Draw the window *)
  SetPlane( {2} );
  SetFunc( clr, 0 );
  FillArea( 184, 28, 264, 294, CARDINAL(0FFFFH) );
  SetPlane( {3} );
  SetFunc( or, 0 );
  SetWindow( 184, 28, 264, 294 );
  GotoXY( 0, 0 );
  WrStr( 'อออออออออออ OPTIONS ออออออออออออ' ); WrLn;
  GotoXY( 0, 266 );
  WrStr( 'อออออออออออออออออออออออออออออออออ' ); WrLn;
  WrStr( ' <RET>๚Change option  <ESC>๚Exit ');

  OptionSelect := 0;
  REPEAT

      SetPlane( {3} );
      SetFunc( clr, 0 );
      FillArea( 184, 42, 264, 140, CARDINAL(0) );

      Select( 184, 42, 448, 182, WriteOptionEntry,
          NumofOptions, OptionSelect, Key, Escape );

      IF Key = ASCII.cr THEN
          CASE OptionSelect OF
            1 : IF ModemPort = 1 THEN
                    ModemPort := 2;
                ELSE
                    ModemPort := 1;
                END (* IF *); |
            2 : IF ModemBaud = 1200 THEN
                    ModemBaud := 2400;
                ELSIF ModemBaud = 2400 THEN
                    ModemBaud := 9600;
                ELSE
                    ModemBaud := 1200;
                END (* IF *); |
            4 : IF ClockType = 1 THEN
                    ClockType := 2;
                ELSE
                    ClockType := 1;
                END (* IF *);
          END (* CASE *);
      END (* IF *);

  UNTIL Key = ASCII.esc;

  SetPlane( {2,3} );
  SetFunc( clr, 0 );
  FillArea( 184, 28, 264, 294, CARDINAL(0) );
  SetWindow( 0, 0, 639, 349 );

  SaveOptions;

END OptionMenu;


PROCEDURE SaveOptions;

VAR OptFile : FIO.File;

BEGIN
  OptFile := FIO.Create( OptFileName );
  FIO.WrBin( OptFile, ModemPort, 892 );
  FIO.Close( OptFile );
END SaveOptions;


PROCEDURE LoadOptions;

VAR OptFile : FIO.File;
    Read : CARDINAL;

BEGIN
  OptFile := FIO.Open( OptFileName );
  IF OptFile < MAX( CARDINAL ) THEN
      Read := FIO.RdBin( OptFile, ModemPort, 892 );
      FIO.Close( OptFile );
  ELSE
      Fill( ADR( Programs ), 882, 0 );
      ModemPort := 2;
      ModemBaud := 2400;
      ClockType := 1;
  END (* IF *);
END LoadOptions;

END Options.
