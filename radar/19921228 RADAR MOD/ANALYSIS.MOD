IMPLEMENTATION MODULE Analysis;

IMPORT Graph, ASCII;
FROM Graphics IMPORT
  SetFunc, clr, or, xor, SetPlane, EnablePlane, FillArea, GotoXY,
  GetWindow, SetWindow, SetFont;
FROM IO IMPORT WrChar, WrStr, WrCard, RdStr, RdKey, WrLngReal;
FROM Lib IMPORT
  Move, ScanR, Fill;
FROM Locator IMPORT
  CurrRange, CurrTilt, CursorOn;
FROM SYSTEM IMPORT ADDRESS;
FROM Str IMPORT Length, Concat;
FROM TimeDate IMPORT Time;
FROM E300Interface IMPORT MapEntry, Map;
IMPORT MATHLIB;
FROM ScreenHandler IMPORT Message;

(*
TYPE
    MarkerRec  =  RECORD
        X, Y   :    CARDINAL;
        Picture  :  CARDINAL;
    END (* MarkerRec *);

VAR
    Trail  :  ARRAY [ 0..50 ] OF MarkerRec;
*)

VAR
    Speed, Dir    :  LONGREAL;

PROCEDURE DrawMarkers;
VAR
    Count  :  CARDINAL;
    dX, dY :  LONGREAL;

BEGIN
    IF LastMarker=0 THEN
        RETURN;
    END (* IF *);
    SetPlane( { 4 } );
    FOR Count := 0 TO LastMarker-1 DO
        WITH Trail[ Count ] DO
            Graph.Circle( X, Y, 3, 8 );
            IF Count > 0 THEN
                Graph.Line( X, Y, Trail[ Count-1 ].X,
                    Trail[ Count-1 ].Y, 8 );
            END (* IF *);
        END (* WITH *);
    END (* FOR *);
    IF LastMarker > 1 THEN
        dX :=  ( LONGREAL( Trail[ LastMarker-1 ].X ) -
            LONGREAL( Trail[ LastMarker-2 ].X ) )*LONGREAL( CurrRange )/256.0;
        dY :=  ( LONGREAL( Trail[ LastMarker-2 ].Y ) -
            LONGREAL( Trail[ LastMarker-1 ].Y ) )*LONGREAL( CurrRange )*
            48.0/35.0/256.0;
        Speed := MATHLIB.Sqrt( dX*dX + dY*dY );
        Dir := MATHLIB.ATan( dX/dY )*180.0/3.1415927;
        Message( " " );
        GotoXY( 310, 10 );
        WrCard( TRUNC( Speed ), 8 );
        WrCard( TRUNC( Dir+360.0 ) MOD 360, 8 );
    END (* IF *);
END DrawMarkers;


PROCEDURE Analyze;
BEGIN
END Analyze;

END Analysis.