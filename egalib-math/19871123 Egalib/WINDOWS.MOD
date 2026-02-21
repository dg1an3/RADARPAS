IMPLEMENTATION MODULE Windows;



(*            C R E A T E D  : 10/29/87
 *        L A S T   E D I T  : 10/29/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *
 *  Provides a simple windowing system.  Provides color
 *  to fill in windows.
 *)

FROM SYSTEM IMPORT ADDRESS;

PROCEDURE OpenWindow
( X1, Y1,
  XSize, YSize : INTEGER;
  FillColor    : CARDINAL;
  VAR SaveData : ADDRESS );
BEGIN
  EGALib.SetPlanes(PlaneSet{0,1,2,3});

END OpenWindow;

PROCEDURE CloseWindow
( VAR SaveData : ADDRESS );
BEGIN
END CloseWindow;

END Windows.
