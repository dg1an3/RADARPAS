MODULE Test;

IMPORT Graph, Graphics,
   ScreenHandler, E300Interface, TimeDate, FIO, Lib,
   IO;

VAR
    CurrentTime  :  TimeDate.Time;
    MapFile      :  FIO.File;
    I            :  CARDINAL;
    K            :  CHAR;

BEGIN
  Graph.InitEGA;
  Graph.GraphMode;
  Graphics.SetFont( 14 );

  TimeDate.GetTime(CurrentTime);
  ScreenHandler.WriteParams( 255, 4, 255, CurrentTime,
      E300Interface.NoRT );

  Lib.Fill( ADR(ScreenHandler.ScrnMap[1]), SIZE(ScreenHandler.ScrnMap[1]), 0 );
  Lib.Fill( ADR(ScreenHandler.ScrnMap[2]), SIZE(ScreenHandler.ScrnMap[2]), 0 );
  MapFile := FIO.Open( 'MAP1.DAT' );
  I := FIO.RdBin( MapFile, ScreenHandler.ScrnMap[ 1 ], 32768 );
  FIO.Close( MapFile );

  ScreenHandler.WriteMap( 1, TRUE );

  LOOP

      K := IO.RdKey();
      IF K = "Q" THEN HALT END;
      ScreenHandler.ClearScreen;
      ScreenHandler.WriteParams( 255, 3, 255, CurrentTime,
          E300Interface.NoRT );
      ScreenHandler.WriteMap( 1, TRUE );

  END (* LOOP *);

END Test.