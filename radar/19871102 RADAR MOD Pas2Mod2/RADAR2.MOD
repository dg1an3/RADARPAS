MODULE E300PC; (* version 2.0 *)

(*            C R E A T E D  : 11/2/87
 *        L A S T   E D I T  : 11/2/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *
 *  Main body of radar terminal program.
 *)

MODULE Station;

  EXPORT
    StationRec, Select, Connect, Storage;

  TYPE
    StationRec = RECORD
    END; (* RECORD *)

  PROCEDURE Select
  ( VAR Station : StationRec );
  BEGIN
  END Select;
  
  PROCEDURE Connect
  ( Station : StationRec );
  BEGIN
  END Connect;
  
  PROCEDURE Storage
  ( Station : StationRec );
  BEGIN
  END Storage;

END Station;

BEGIN
  InOut.WriteString('E300PC RADAR TERMINAL'); InOut.WriteLn;
  InOut.WriteString('     version 2.1     '); InOut.WriteLn;
  InOut.WriteLn;
  InOut.WriteString(' Copyright (C) 1987  '); InOut.WriteLn;
  InOut.WriteString('     D. G. Lane      '); InOut.WriteLn;
  EGALib.SetHiRes;
  Fonts.SetFont(14);
  LOOP
    ExtendKey.Read(Key,Escape)
    IF Escape THEN
      CASE Key OF
        (* F1 *)
          Station.Select(CurrentStation); |
        (* F2 *)
          Station.Connect(CurrentStation); |
        (* F3 *)
          Station.Storage(CurrentStation);
      END; (* CASE *)
    ELSE
      CASE Key OF
        '1'..'9' :
          DisplayMap(Map[ORD(Key)-48]); |
        'R' :
          DisplayRangeMarks;
      END; (* CASE *)
    END; (* IF *)
  END; (* LOOP *)
  EGALib.SetText;
END E300PC.
