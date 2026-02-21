IMPLEMENTATION MODULE Options;

PROCEDURE OptionMenu;

BEGIN

  (* Draw the window *)
  SetPlane( {2} );
  SetFunc( clr, 0 );
  FillArea( 184, 28, 264, 294, CARDINAL(0FFFFH) );
  SetPlane( {3} );
  SetFunc( or, 0 );
  SetWindow( 184, 28, 264, 294 );
  GotoXY( 0, 0 );
  WrStr( 'อออออออออออ OPTIONS ออออออออออออ' );
  WrStr( '   MODEM PORT : COM1            ' );
  WrStr( '   MODEM BAUD : 2400            ' );
  WrStr( '   MODEM TYPE : HAYES COMPAT    ' );
  WrStr( '        CLOCK : 12 hour         ' );
  WrStr( '    XMIT BAUD : 2400            ' );
  WrStr( ' PRINTER TYPE : Epson           ' );
  WrStr( '                                ' );
  WrStr( '                                ' );
  WrStr( '                                ' );
  WrStr( '                                ' );
  GotoXY( 0, 266 );
  WrStr( 'อออออออออออออออออออออออออออออออออ' );
  WrStr( ' <RET>๚Change option  <ESC>๚Exit ');


END OptionMenu;

END Options.
