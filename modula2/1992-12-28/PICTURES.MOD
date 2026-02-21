IMPLEMENTATION MODULE Pictures;


IMPORT ASCII;

FROM E300Interface IMPORT
    RTState;

IMPORT ExtendKey;

FROM FIO IMPORT
    File, Open, Close, Create, WrBin, RdBin, Erase;
IMPORT FIO;

FROM Graphics IMPORT
    SetPlane, SetFunc, or, clr, SetWindow, GotoXY,
    FillArea;

FROM IO IMPORT
    WrStr, WrCard, WrChar, WrLngCard, WrLn, RdKey;

FROM Lib IMPORT
    Dos;

(*
FROM RadarTx IMPORT
    TransmitPic;
*)

FROM ScreenHandler IMPORT
    WriteDate, WriteTime, WriteTilt, WriteRange,
    WriteGain, WriteParams, Redraw, WritePic, Pause,
    Message, ClearScreen, MapOn;

FROM Selector IMPORT
    Select;

FROM Storage IMPORT
    Available, ALLOCATE, DEALLOCATE;

FROM Str IMPORT
    CardToStr, Concat, Length, Slice, StrToCard;

FROM SYSTEM IMPORT
    Registers;

FROM TimeDate IMPORT
    Time, GetTime;


PROCEDURE FileName(Picture    : PictureRec;
               VAR NameofFile : ARRAY OF CHAR);

(* Generates the filename for the file associated with Picture *)

VAR

  TimeString : ARRAY[0..1] OF CHAR;
          OK : BOOLEAN;
BEGIN

  (* Check if NameofFile is big enough to hold a valid file name *)
  IF HIGH(NameofFile) < 10 THEN

      NameofFile[0] := 000C;
      RETURN;

  END (* IF *);

  (* The first four characters of the file name represent the time *)
  WITH Picture.TimeofPic DO

      CardToStr( LONGCARD(minute DIV 60 * 100 + minute MOD 60),
          NameofFile, 10, OK );

  END (* WITH *);

  IF Length(NameofFile) < 4 THEN

      Concat( NameofFile, '0', NameofFile );

  END (* IF *);

  (* The fourth, fifth, and sixth characters represent, respectively, the
     tilt, range, and gain of the picture *)
  Concat( NameofFile, NameofFile, CHR(65+Picture.Tilt) );
  Concat( NameofFile, NameofFile, CHR(65+Picture.Range) );
  Concat( NameofFile, NameofFile, CHR(64+Picture.Gain) );

  (* Now add the extension *)
  Concat( NameofFile, NameofFile, '.WX' );

END FileName;



PROCEDURE FileParam(VAR Picture    : PictureRec;
                        NameofFile : ARRAY OF CHAR;
                    VAR OK         : BOOLEAN);

(* Does the reverse of FileName, above.  As the filename might not be
   a valid picture file, OK is set if the operation was successful *)

VAR

   TimeString : ARRAY[0..1] OF CHAR;
  Hour,Minute : CARDINAL;

BEGIN

  Slice( TimeString, NameofFile, 0, 2 );
  Hour := CARDINAL(StrToCard(TimeString,10,OK));
  IF NOT(OK) THEN
      RETURN;
  END (* IF *);

  Slice( TimeString, NameofFile, 2, 2 );
  Minute := CARDINAL(StrToCard(TimeString,10,OK));
  IF NOT(OK) THEN
      RETURN;
  END (* IF *);

  WITH Picture DO

      TimeofPic.minute := Hour * 60 + Minute;
      Tilt := ORD(NameofFile[4]) - 65;
      Range := ORD(NameofFile[5]) - 65;
      Gain := ORD(NameofFile[6]) - 64;
      Data := NIL;
      Flags := PicFlagSet{};

  END; (* WITH *)

END FileParam;


PROCEDURE SavePicture( VAR ForPicture : PictureRec;
                         VAR SaveDone : BOOLEAN );

(* Saves a picture (assumed unsaved) to its corresponding file.  Assumes
   current directory is station's directory *)

VAR

  DataFileName : ARRAY[1..12] OF CHAR;
      DataFile : File;
  BytesWritten : CARDINAL;

BEGIN

  (* Generate the name of the file *)
  FileName( ForPicture, DataFileName );

  DataFile := Create( DataFileName );
  IF DataFile = MAX(CARDINAL) THEN

      SaveDone := FALSE;
      RETURN;

  END (* IF *);

  WrBin( DataFile, ForPicture.Data^, ForPicture.Size );
  Close( DataFile );

  (* Check to see if all data written
  SaveDone := ( BytesWritten = ForPicture.Size ); *)

  (* If all data is written, set the NotSaved flag off *)
  IF SaveDone THEN
      EXCL( ForPicture.Flags,NotSaved );
  END (* IF *);

END SavePicture;



PROCEDURE ReserveMem( VAR ForBuffer : ADDRESS;
                          Size      : CARDINAL;
                          PicList   : ARRAY OF PictureRec;
                          MaxPic    : CARDINAL;
                      VAR done      : BOOLEAN );

(* Allocates Size bytes on the heap, pointed to by ForBuffer.  If not
   enough memory remains, this purges the earliest picture, according
   to the Purge number.  If that picture has not been saved, it auto-
   matically saves it *)

VAR

  Count,Earliest : CARDINAL;

BEGIN

  (* Check to see if Size bytes available *)
  WHILE NOT(Available(Size)) DO

      (* No, so find the earliest picture *)
      Earliest := 0;
      FOR Count := 1 TO MaxPic DO

          (* Only check purge number if picture is in memory *)
          IF ( PicList[Count].Data # NIL ) THEN

              IF ( Earliest = 0 ) OR
              ( PicList[Count].Purge < PicList[Earliest].Purge ) THEN
                  Earliest:=Count;
              END; (* IF *)

          END; (* IF *)

      END; (* FOR *)

      (* If no purge numbers found (no pictures in memory), fail *)
      IF Earliest = 0 THEN

          done := FALSE;
          RETURN;

      END (* IF *);

      (* If the earliest picture has not been saved, save it
      IF NotSaved IN PicList[Earliest].Flags THEN

          SavePicture( PicList[Earliest], done );
          IF ~ done THEN

              RETURN;

          END (* IF *);

      END;  IF *)

      (* Free up the memory, and loop to check if Size bytes available *)
      IF PicList[Earliest].Data # NIL THEN
          DEALLOCATE( PicList[Earliest].Data, PicList[Earliest].Size );
          PicList[Earliest].Data := NIL;
      END (* IF *);

  END; (* WHILE *)

(*  ALLOCATE( ForBuffer, Size ); *)
  done := TRUE;

END ReserveMem;



PROCEDURE SelectPicture( VAR ForPicture : PictureRec );

(* Displays indicated picture.  Assumes current directory is station's
   directory *)

VAR

  DataFileName : ARRAY [ 1..12 ] OF CHAR;
      DataFile : File;
          Done : BOOLEAN;
   CurrentTime : Time;
           Key : CHAR;

BEGIN

  WITH ForPicture DO

      IF Data = NIL THEN

          (* Picture not in memory, so generate its file name
             and read in the file *)
          FileName( ForPicture, DataFileName );
          DataFile := Open( DataFileName );
          IF DataFile = MAX(CARDINAL) THEN

              GetTime( CurrentTime );
              WriteParams( 255, 255, 255, CurrentTime, NoRT );
              RETURN;

          END (* IF *);

          (* Set aside enough memory *)
(*          ReserveMem( Data, Size, Done ); *)
          Size := CARDINAL( FIO.Size( DataFile ) );
          ALLOCATE( Data, Size );
          Done := TRUE;

          (* File was just read, so it must be saved *)
          EXCL( Flags, NotSaved );

          IF Done = TRUE THEN

              Size := RdBin( DataFile, Data^ , (* 50000 *) Size );
              Close( DataFile );

          ELSE

              Message( ' Not enough space ' );
              Close( DataFile );
              RETURN;

          END (* IF *);

      END (* IF *);

      (* Write the picture's parameters *)
      WriteParams( Tilt, Range, Gain, TimeofPic, NoRT );

      (* Now draw the picture *)
      WritePic( Data^, Size );

  END (* WITH *);

(*  IF MapOn[1] OR MapOn[2] THEN
      SetPlane( {2,3} );
      ClearScreen;
      Redraw;
  END (* IF *); *)

END SelectPicture;



PROCEDURE AddPicture( VAR PicList : ARRAY OF PictureRec;
                       VAR MaxPic : CARDINAL;
                       ForPicture : PictureRec;
                       VAR Number : CARDINAL );

(* Adds a new picture header into its proper position in the
   picture list *)


VAR

  Count : CARDINAL;
  PicFileName : ARRAY [ 0..11 ] OF CHAR;

BEGIN

  (* First, search for the chronological position to insert the
     picture header *)
  Number := 0;
  LOOP

      IF Number >= MaxPic THEN

          EXIT;

      END (* IF *);

      (* Check to see if the date is the same *)
      IF PicList[Number].TimeofPic.day = ForPicture.TimeofPic.day THEN

          (* Is the time earlier? *)
          IF PicList[Number].TimeofPic.minute <
          ForPicture.TimeofPic.minute THEN

              EXIT;

          END (* IF *);

      (* Is the date earlier? *)
      ELSIF PicList[Number].TimeofPic.day < ForPicture.TimeofPic.day THEN

          EXIT;

      END; (* IF *)

      INC( Number );

  END; (* LOOP *)

  (* Increment picture count only if within range *)
  IF MaxPic < HIGH( PicList ) THEN

      INC( MaxPic );

  END (* IF *);

  (* Move all the later pictures up *)
  FOR Count := MaxPic TO Number+1 BY -1 DO

      PicList[Count] := PicList[Count-1];

  END; (* FOR *)

(* MOVE TO MAIN BODY
  (* Check if CurrentPicture was also moved up *)
  IF CurrentPicture > Number THEN

      INC( CurrentPicture );

  END (* IF *);
*)

  (* Insert picture header into its place *)
  PicList[Number] := ForPicture;

(* SCA TRANSMISSION *)

(*  IF Number = 0 THEN
      FileName( ForPicture, PicFileName );
      TransmitPic( PicFileName, ForPicture.Data^, ForPicture.Size );
  END (* IF *); *)

(* END SCA TRANSMISSION *)

END AddPicture;



PROCEDURE DeletePicture( VAR PicList : ARRAY OF PictureRec;
                          VAR MaxPic : CARDINAL;
                          PictureNum : CARDINAL );

(* Deletes a picture from the current station's picture list, as well
   as the corresponding file.  Assumes the current directory is the
   station's directory *)

VAR

  DataFileName : ARRAY [ 0..10 ] OF CHAR;
      DataFile : File;
         Count : CARDINAL;

BEGIN

  (* First, delete the picture's file *)
  FileName( PicList[PictureNum],
      DataFileName );
  Erase( DataFileName );

  (* Now, if the picture was in memory, free
         up the memory *)
  IF PicList[PictureNum].Data # NIL THEN

      DEALLOCATE( PicList[PictureNum].Data,
          PicList[PictureNum].Size );
      PicList[PictureNum].Data := NIL;

  END (* IF *);

  (* Move all the pictures above down *)
  FOR Count := PictureNum TO MaxPic DO

      PicList[Count] := PicList[Count+1];

  END (* FOR *);

  (* Adjust the picture count *)
  DEC(MaxPic);

END DeletePicture;



VAR
  CurrList : POINTER TO ARRAY [ 1..100 ] OF PictureRec;

PROCEDURE WritePictureEntry(PictureNum : CARDINAL);

(* Writes one entry of the picture list *)

BEGIN

  IF PictureNum > 0 THEN

      WITH CurrList^[PictureNum] DO

          WriteDate( TimeofPic );
          WrChar( ' ' );
          WriteTime( TimeofPic );
          WrChar( ' ' );
          WriteTilt( Tilt );
          WrStr( '   ' );
          WriteRange( Range );
          WrStr( '   ' );
          WriteGain( Gain );
          WrLn;

      END; (* WITH *)

  END (* IF *);

END WritePictureEntry;



PROCEDURE PictureMenu( VAR PicList : ARRAY OF PictureRec;
                        VAR MaxPic : CARDINAL;
                      VAR Selected : CARDINAL );

(* Menu-driven picture management.  Accesses SelectPicture
       and DeletePicture. *)


VAR

      AtPicture,
     TopPicture : CARDINAL;
            Key : CHAR;
         Escape : BOOLEAN;
              R : Registers;
  DiskFreeSpace : LONGCARD;
    CurrentTime : Time;

BEGIN

  (* Draw the window *)
  SetPlane( {2} );
  SetFunc( clr, 0 );
  FillArea( 184, 28, 264, 294, CARDINAL(0FFFFH) );
  SetPlane( {3} );
  SetFunc( or, 0 );
  SetWindow( 184, 28, 264, 294 );
  GotoXY( 0, 0 );
  WrStr( 'อออออออออออ PICTURES ออออออออออออ' );
  WrStr( 'Date     Time    Tilt Range Gain ' );
  GotoXY( 0, 266 );
  WrStr( 'อออออออออออออออออออออออออออออออออ' );
  WrStr( '     <RET>๚Select  F1๚Delete');

  AtPicture := Selected;
  CurrList := ADR( PicList );

  LOOP

          SetWindow( 184, 28, 264, 294 );
          SetPlane( {3} );
          SetFunc( clr, 0 );
          GotoXY( 8, 252 );
          IF MaxPic = 0 THEN

              WrStr( 'No Pictures. ' );

          ELSIF MaxPic = 1 THEN

              WrStr( '1 Picture. ' );

          ELSE

              WrCard( MaxPic, 1 );
              WrStr( ' Pictures. ' );

          END (* IF *);

          WITH R DO

              AH := 36H; (* Get Disk Free Space *)
              DL := 00H; (* Default drive *)
              Dos( R );
              DiskFreeSpace := LONGCARD(AX) * LONGCARD(BX)
                  * LONGCARD(CX) DIV 1000; (* in kbytes *)

          END (* WITH *);

          WrLngCard( DiskFreeSpace, 1 );
          WrStr( ' kbytes free.' );

          Select( 184, 56, 448, 280, WritePictureEntry,
              MaxPic, AtPicture, Key, Escape );

          IF Escape & ( Key = ExtendKey.F1 ) THEN

              IF CAP(Pause( 'Delete this picture ( Y/N )? ' )) = 'Y' THEN

                  DeletePicture( PicList, MaxPic, AtPicture-1 );

              END (* IF *);

          ELSIF ~ Escape & ( Key = ASCII.esc ) THEN

              AtPicture := Selected;
              EXIT;

          ELSIF ~ Escape & ( Key = ASCII.cr ) THEN

              EXIT;

          END (* IF *);

          SetPlane( {3} );
          SetFunc( clr, 0 );
          FillArea( 184, 56, 264, 238, CARDINAL(0) );

      END (* LOOP *);

      (* Erase the window *)
      SetPlane( {2,3} );
      SetFunc( clr, 0 );
      FillArea( 184, 28, 264, 294, CARDINAL(0) );
      SetWindow( 0, 0, 639, 349 );

      SetPlane( {0,1,2,3} );
      ClearScreen;
      Redraw;

      (* If a valid picture was selected, draw it *)
      IF ( AtPicture > 0 ) & ( AtPicture # Selected ) THEN

          SelectPicture( CurrList^[AtPicture] );

      (* Otherwise, clear the screen *)
      ELSIF AtPicture = 0 THEN

          SetPlane( {0,1} );
          FillArea( 0, 0, 639, 349, CARDINAL(0) );
          WriteParams( 255, 255, 255, CurrentTime, NoRT );

      END (* IF *);

      Selected := AtPicture;

END PictureMenu;



END Pictures.