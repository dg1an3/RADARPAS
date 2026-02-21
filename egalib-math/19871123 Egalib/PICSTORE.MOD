IMPLEMENTATION MODULE PicStore;

(*
========================================================

 Created   : 8/12/87
 Last Edit : 8/12/87
 Author    : Derek Lane
 System    : LOGITECH MODULA-2/86

 Provides routines for storing and retrieving portions
 of the picture on the EGA screen.  The pictures are
 stored in a compressed, run-length encoded form.
========================================================
*)

(*$S- Stack check off *)
(*$R- Range check off *)
(*$T- Index check off *)

IMPORT EGALib;
FROM SYSTEM IMPORT
  ADR, BYTE;

TYPE
  DataRec      = RECORD
    Planes     :   EGALib.PlaneSet;
    XSize,
    YSize      :   CARDINAL;
    PicData    :   ARRAY[0..64000] OF BYTE;
  END; (* RECORD *)

VAR
  Screen [0A000H:0000H] : ARRAY [0..32767] OF BYTE;

PROCEDURE GetPicture
( X, Y,
  XSize, YSize : CARDINAL;
  VAR ToBuffer : ARRAY OF BYTE;
  VAR Size     : CARDINAL );
(* Stores the area defined by (X1,Y1) to (X1+XSize,Y1+YSize)
   in the buffer ToBuffer.  The variable Size tells how much
   of ToBuffer was used.  If ToBuffer isn't big enough, then
   Size will be zero, but ToBuffer will be filled with as
   much data as it could hold. *)
VAR
  Data       : POINTER TO DataRec;
  PlaneCount,
  XCount,
  YCount     : CARDINAL;
  TempSet    : EGALib.PlaneSet;
BEGIN
  Data:=ADR(ToBuffer);
  Data^.XSize:=XSize DIV 8; Data^.YSize:=YSize;
  WITH Data^ DO
    Planes:=EGALib.CurrentPlanes;
    Size:=0;
    FOR XCount:=(X DIV 8) TO (X DIV 8)+XSize DO
      FOR PlaneCount:=0 TO 3 DO
        IF PlaneCount IN Planes THEN
          TempSet:=EGALib.PlaneSet{}; INCL(TempSet,PlaneCount);
          EGALib.SetPlane(TempSet);
          FOR YCount:=Y TO Y+YSize DO
            PicData[Size]:=Screen[YCount*80+XCount];
            IF (PicData[Size]<>BYTE(0)) AND (PicData[Size]<>BYTE(255)) THEN
              INC(Size);
            ELSE
              IF (Size>=2) AND (PicData[Size-2]=PicData[Size]) AND
                (PicData[Size-1]<>BYTE(255)) THEN 
                INC(PicData[Size-1]);
              ELSE 
                INC(Size,2);
                PicData[Size-1]:=BYTE(1);
              END; (* IF *)
            END; (* IF *)
          END; (* FOR *)
        END; (* IF *)
      END; (* FOR *)
    END; (* FOR *)
    EGALib.SetPlane(Planes);
  END; (* WITH *)
END GetPicture;

PROCEDURE PutPicture
( X, Y       : CARDINAL;
  FromBuffer : ARRAY OF BYTE );
(* Retrieves the picture previously stored in FromBuffer at
   the position (X1,Y1). *)
VAR
  Data       : POINTER TO DataRec;
  PlaneCount,
  XCount,
  YCount,
  Size,
  Repeat     : CARDINAL;
  OldPlanes  : EGALib.PlaneSet;
  TempSet    : EGALib.PlaneSet;
BEGIN
  Data:=ADR(FromBuffer);
  OldPlanes:=EGALib.CurrentPlanes;
  WITH Data^ DO
    Size:=0; Repeat:=0;
    EGALib.SetFunc(EGALib.clr,0);
    FOR XCount:=(X DIV 8) TO (X DIV 8)+XSize DO
      FOR PlaneCount:=0 TO 3 DO
        IF PlaneCount IN Planes THEN
          TempSet:=EGALib.PlaneSet{}; INCL(TempSet,PlaneCount);
          EGALib.SetPlane(TempSet);
          FOR YCount:=Y TO Y+YSize DO
            Screen[YCount*80+XCount]:=PicData[Size];
            IF (PicData[Size]<>BYTE(0)) AND (PicData[Size]<>BYTE(255)) THEN
              INC(Size);
            ELSE
              INC(Repeat);
              IF Repeat>=ORD(PicData[Size+1]) THEN
                INC(Size,2);
                Repeat:=0;
              END; (* IF *)
            END; (* IF *)
          END; (* FOR *)
        END; (* IF *)
      END; (* FOR *)
    END; (* FOR *)
  END; (* WITH *)
  EGALib.SetPlane(OldPlanes);
END PutPicture;

END PicStore.
