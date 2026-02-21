MODULE RadarStore;

IMPORT Debug;
IMPORT ASCII;
FROM EGALib IMPORT
  SetPlane, SetFunc, xor, clr, FillArea, FillAreaFunc, Window, GotoXY,
  ScrollUp, ScrollDown, Line;
FROM FileSystem IMPORT
  File, Response, Lookup, Close, ReadNBytes, WriteNBytes, Delete;
FROM FileUtility IMPORT
  AttrType, AttrSet, SetDrive, SetDirSearch, DirEntry, ChDir;
FROM InOut IMPORT
  Write, WriteInt, WriteCard, ReadCard, WriteString, WriteLn;
FROM Keyboard IMPORT
  KeyPressed, Read;
FROM NumberConversion IMPORT
  StringToCard, CardToString;
FROM Picture IMPORT
  Display;
FROM Screen IMPORT
  ArmyTime, WriteTime, WriteDate, WriteTilt, WriteRange,
  WriteGain, WriteParams;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE, Available;
FROM Strings IMPORT
  Assign, Copy, Concat, Pos;
FROM SYSTEM IMPORT
  BYTE, ADR, ADDRESS;
FROM TimeDate IMPORT
  GetTime, Time;

TYPE
  (* The flags which store the state of a picture *)
  PicFlag         = (NotSaved,BeingDownLoaded);
  PicFlagSet      = SET OF PicFlag;

  PictureRec      = RECORD
    Tilt, Range,
    Gain          :   CARDINAL;
    TimeofPic     :   Time;
    (* Purge number: to determine when to purge the picture from memory *)
    Purge         :   CARDINAL;
    Flags         :   PicFlagSet;
    (* The size of the picture's compressed data *)
    Size          :   CARDINAL;
    (* The pointer to the data for the picture.  If the picture isn't in
       memory, this value is NIL *)
    Data          :   ADDRESS;
  END; (* RECORD *)

  StationPtr      = POINTER TO StationRec;
  StationRec      = RECORD
    (* Pointer to the next link in the linked list *)
    Next          :   StationPtr;
    (* Only used by StationMenu to determine where to put the selector *)
    StationNumber :   CARDINAL;
    (* Station subdirectory name - including extension *)
    StationName   :   ARRAY[0..11] OF CHAR;
    (* Phone number - may contain Hayes dial modifiers *)
    Phone         :   ARRAY[0..63] OF CHAR;
    (* If this station is active, the number of the picture being displayed *)
    CurrentPicture,
    (* Amount of valid picture headers in the picture list *)
    NumofPictures :   CARDINAL;
    (* The picture list *)
    Picture       :   ARRAY[1..100] OF PictureRec;
  END; (* RECORD *)

PROCEDURE FileName(Picture    : PictureRec;
               VAR NameofFile : ARRAY OF CHAR);
(* Generates the filename for the file associated with Picture *)
VAR
  TimeString  : ARRAY[0..1] OF CHAR;
  Hour,Minute : CARDINAL;
BEGIN
  (* Check if NameofFile is big enough to hold a valid file name *)
  IF HIGH(NameofFile)<10 THEN
    NameofFile[0]:=CHR(0);
    RETURN;
  END; (* IF *)
  (* The first four characters of the file name represent the time *)
  CardToString(Picture.TimeofPic.minute DIV 60,TimeString,2);
  IF TimeString[0]=' ' THEN TimeString[0]:='0'; END;
  Assign(TimeString,NameofFile);
  CardToString(Picture.TimeofPic.minute MOD 60,TimeString,2);
  IF TimeString[0]=' ' THEN TimeString[0]:='0'; END;
  Concat(NameofFile,TimeString,NameofFile);
  (* The fourth, fifth, and sixth characters represent, respectively, the
     tilt, range, and gain of the picture *)
  NameofFile[4]:=CHR(65+Picture.Tilt);
  NameofFile[5]:=CHR(65+Picture.Range);
  NameofFile[6]:=CHR(64+Picture.Gain);
  NameofFile[7]:=CHR(0);
  (* Now add the extension *)
  Concat(NameofFile,'.PIC',NameofFile);
END FileName;

PROCEDURE FileParam(VAR Picture    : PictureRec;
                        NameofFile : ARRAY OF CHAR;
                    VAR OK         : BOOLEAN);
(* Does the reverse of FileName, above.  As the filename might not be
   a valid picture file, OK is set if the operation was successful *)
VAR
  TimeString  : ARRAY[0..1] OF CHAR;
  Hour,Minute : CARDINAL;
BEGIN
  Copy(NameofFile,0,2,TimeString);
  StringToCard(TimeString,Hour,OK);
  IF NOT(OK) THEN RETURN; END;
  Copy(NameofFile,2,2,TimeString);
  StringToCard(TimeString,Minute,OK);
  IF NOT(OK) THEN RETURN; END;
  WITH Picture DO
    TimeofPic.minute:=Hour*60+Minute;
    Tilt:=ORD(NameofFile[4])-65;
    Range:=ORD(NameofFile[5])-65;
    Gain:=ORD(NameofFile[6])-64;
    Data:=NIL;
    Flags:=PicFlagSet{};
  END; (* WITH *)
END FileParam;

PROCEDURE ReserveMem(VAR ForBuffer : ADDRESS;
                         Size      : CARDINAL;
                     VAR done      : BOOLEAN);
(* Allocates Size bytes on the heap, pointed to by ForBuffer.  If not
   enough memory remains, this purges the earliest picture, according
   to the Purge number.  If that picture has not been saved, it auto-
   matically saves it *)
VAR
  Count,Earliest : CARDINAL;
BEGIN
  WITH CurrentStation^ DO
    (* Check to see if Size bytes available *)
    WHILE NOT(Available(Size)) DO
      (* No, so find the earliest picture *)
      Earliest:=0;
      FOR Count:=1 TO NumofPictures DO
        (* Only check purge number if picture is in memory *)
        IF (Picture[Count].Data<>NIL) THEN
          IF (Earliest=0) OR
          (Picture[Count].Purge<Picture[Earliest].Purge) THEN
            Earliest:=Count;
          END; (* IF *)
        END; (* IF *)
      END; (* FOR *)
      (* If no purge numbers found (no pictures in memory), fail *)
      IF Earliest=0 THEN done:=FALSE; RETURN; END;
      (* If the earliest picture has not been saved, save it *)
      IF NotSaved IN Picture[Earliest].Flags THEN
        SavePicture(Picture[Earliest],done);
        IF NOT done THEN RETURN; END;
      END; (* IF *)
      (* Free up the memory, and loop to check if Size bytes available *)
      DEALLOCATE(Picture[Earliest].Data,Picture[Earliest].Size);
    END; (* WHILE *)
  END; (* WITH *)
  ALLOCATE(ForBuffer,Size);
  done:=TRUE;
END ReserveMem;

VAR
  DiskMemFree : CARDINAL; (* Stores amount of disk space left *)

PROCEDURE SavePicture(VAR ForPicture : PictureRec; VAR SaveDone : BOOLEAN);
(* Saves a picture (assumed unsaved) to its corresponding file.  Assumes
   current directory is station's directory *)
VAR
  DataFileName : ARRAY[1..12] OF CHAR;
  DataFile     : File;
  BytesWritten : CARDINAL;
BEGIN
  (* Generate the name of the file *)
  GotoXY(0,10); WriteString('SAVING ');
  FileName(ForPicture,DataFileName);
  WriteString(DataFileName);
  Lookup(DataFile,DataFileName,TRUE);
  IF DataFile.res<>done THEN SaveDone:=FALSE; RETURN; END;
  WriteNBytes(DataFile,ForPicture.Data,ForPicture.Size,BytesWritten);
  Close(DataFile);
  (* Check to see if all data written *)
  SaveDone:=(BytesWritten=ForPicture.Size);
  (* If all data is written, set the NotSaved flag off *)
  IF SaveDone THEN EXCL(ForPicture.Flags,NotSaved); END;
  GotoXY(0,10); WriteString('                  ');
END SavePicture;

PROCEDURE SelectPicture(VAR ForPicture : PictureRec);
(* Displays indicated picture.  Assumes current directory is station's
   directory *)
VAR
  DataFileName : ARRAY[1..12] OF CHAR;
  DataFile     : File;
  Count        : CARDINAL;
  Done         : BOOLEAN;
BEGIN
  WITH ForPicture DO
    (* See if picture is already in memory *)
    IF NotSaved IN Flags THEN
      SetPlane({2});
      GotoXY(568,280); WriteString('NOT SAVED');
    ELSE
      SetPlane({2});
      GotoXY(568,280); WriteString('         ');
    END;
    IF Data=NIL THEN
      (* No, so generate its file name and read in the file *)
      FileName(ForPicture,DataFileName);
      Lookup(DataFile,DataFileName,FALSE);
      IF DataFile.res<>done THEN
        RETURN;
      END;
      (* Set aside enough memory *)
      ReserveMem(Data,Size,Done);
      (* File was just read, so it must be saved *)
      EXCL(Flags,NotSaved);
      IF Done=TRUE THEN
        ReadNBytes(DataFile,Data,50000,Size);
        Close(DataFile);
      ELSE
        Close(DataFile);
        RETURN;
      END; (* IF *)
    END; (* IF *)
    (* Write the picture's parameters *)
    WriteParams(Tilt,Range,Gain,TimeofPic);
    (* Now draw the picture *)
    Display(Data,Data+Size);
  END; (* WITH *)
END SelectPicture;

PROCEDURE AddPicture(VAR Station    : StationRec;
                         ForPicture : PictureRec;
                     VAR Number     : CARDINAL);
(* Adds a new picture header into its proper position in Station's
   picture list *)
VAR
  Count : CARDINAL;
BEGIN
  WITH Station DO
    (* First, search for the chronological position to insert the
       picture header *)
    Number:=1;
    LOOP
      IF Number>NumofPictures THEN EXIT; END;
      (* Check to see if the date is the same *)
      IF Picture[Number].TimeofPic.day=ForPicture.TimeofPic.day THEN
        (* Is the time earlier? *)
        IF Picture[Number].TimeofPic.minute<ForPicture.TimeofPic.minute THEN
          EXIT;
        END;
      (* Is the date earlier? *)
      ELSIF Picture[Number].TimeofPic.day<ForPicture.TimeofPic.day THEN
        EXIT;
      END; (* IF *)
      INC(Number);
    END; (* LOOP *)
    (* Increment picture count only if within range *)
    IF NumofPictures<99 THEN INC(NumofPictures); END;
    (* Move all the later pictures up *)
    FOR Count:=NumofPictures TO Number BY -1 DO
      Picture[Count+1]:=Picture[Count];
    END; (* FOR *)
    (* Check if CurrentPicture was also moved up *)
    IF CurrentPicture>Number THEN INC(CurrentPicture); END;
    (* Insert picture header into its place *)
    Picture[Number]:=ForPicture;
  END; (* WITH *)
END AddPicture;

PROCEDURE DeletePicture(VAR Station : StationRec; PictureNum : CARDINAL);
(* Deletes a picture from the current station's picture list, as well
   as the corresponding file.  Assumes the current directory is the
   station's directory *)
VAR
  DataFileName : ARRAY[0..10] OF CHAR;
  DataFile     : File;
  Count        : CARDINAL;
BEGIN
  WITH Station DO
    (* First, delete the picture's file *)
    FileName(Station.Picture[PictureNum],DataFileName);
    Delete(DataFileName,DataFile);
    (* Now, if the picture was in memory, free up the memory *)
    IF Picture[PictureNum].Data<>NIL THEN
      DEALLOCATE(Picture[PictureNum].Data,Picture[PictureNum].Size);
    END; (* IF *)
    (* Move all the pictures above down *)
    FOR Count:=PictureNum TO NumofPictures DO
      Picture[Count]:=Picture[Count+1];
    END; (* WITH *)
    (* Adjust the picture count *)
    DEC(NumofPictures);
  END; (* WITH *)
END DeletePicture;

PROCEDURE PictureMenu(VAR Station : StationRec);
(* Menu-driven picture management.  Accesses SelectPicture and DeletePicture. *)
  PROCEDURE WriteEntry(ForPicture : PictureRec);
  (* Writes one entry of the picture list *)
  BEGIN
    WITH ForPicture DO
      WriteDate(TimeofPic); Write(' ');
      WriteTime(TimeofPic); Write(' ');
      WriteTilt(Tilt); WriteString('   ');
      WriteRange(Range); WriteString('   ');
      WriteGain(Gain); WriteLn;
    END; (* WITH *)
  END WriteEntry;
VAR
  AtPicture,
  TopPicture    : CARDINAL;
  Key           : CHAR;
BEGIN
  (* Draw the window *)
  SetPlane({2}); SetFunc(clr);
  FillArea(280,14,544,294,255)(*192,35,456,315,255*);
  SetPlane({3});
  Window(280,14,544,294)(*192,35,456,315*);
(*  WriteString('อออออออออออ PICTURES ออออออออออออ'); WriteLn; *)
  WriteString('Date     Time    Tilt Range Gain ');
  GotoXY(0,252);
  WriteString('อออออออออออออออออออออออออออออออออ'); WriteLn;
  WriteString('     <RET>๚Select  F1๚Delete');
  Window(280,28,544,308)(*192,63,456,287*);
  WITH Station DO
    (* Start at picture 1 for the first sixteen, otherwise, start at 7
       before the current picture *)
    IF CurrentPicture<=16 THEN
      TopPicture:=1;
    ELSE
      TopPicture:=CurrentPicture-7;
    END;
    AtPicture:=TopPicture;
    (* Write the entries *)
    WHILE (AtPicture<=NumofPictures) AND (AtPicture<=TopPicture+16) DO
      WriteEntry(Picture[AtPicture]);
      INC(AtPicture);
    END; (* WHILE *)
    AtPicture:=CurrentPicture;
    REPEAT
      IF AtPicture>0 THEN
        (* Draw the selector bar *)
        FillAreaFunc(280,(AtPicture-TopPicture)*14+28,
                     544,(AtPicture-TopPicture)*14+41,255,xor);
      END; (* IF *)
      (* Get a key *)
      Read(Key);
      IF Key=ASCII.nul THEN
        Read(Key);
        INC(Key,128);
      END; (* IF *)
      IF AtPicture>0 THEN
        (* Undraw the selector bar *)
        FillAreaFunc(280,(AtPicture-TopPicture)*14+14,
                     544,(AtPicture-TopPicture)*14+27,255,xor);
      END; (* IF *)
      CASE Key OF
        320C,(* DOWN ARROW *)
        '+'  : IF AtPicture<NumofPictures THEN INC(AtPicture); END;
               (* If you moved below the bottom of the window, scroll up *)
               IF AtPicture>TopPicture+15 THEN
                 ScrollUp; INC(TopPicture);
                 GotoXY(0,210);
                 WriteEntry(Picture[AtPicture]);
               END (* IF *)
|       310C,(* UP ARROW *)
        '-'  : IF AtPicture>0 THEN DEC(AtPicture); END;
               (* If you moved above the top of the window, scroll down *)
               IF (AtPicture<TopPicture) AND (AtPicture>0) THEN
                 ScrollDown; DEC(TopPicture);
                 GotoXY(0,0);
                 WriteEntry(Picture[AtPicture]);
               END  (* IF *)
|       273C (* F1 *)
             : WriteString('DELETEING');
               IF AtPicture>0 THEN DeletePicture(Station,AtPicture); END
        ELSE
      END;
    UNTIL Key=ASCII.EOL;
    (* Erase the window *)
    SetPlane({2,3}); SetFunc(clr);
    FillArea(280,14,544,294,0)(*192,35,456,315,0*);
    Window(0,0,639,349);
    (* If a valid picture was selected, draw it *)
    IF (AtPicture>0) AND (AtPicture<>CurrentPicture) THEN
      SelectPicture(Station.Picture[AtPicture]);
    (* Otherwise, clear the screen *)
    ELSIF AtPicture=0 THEN
      SetPlane({0,1}); FillArea(0,0,639,349,0);
      WriteParams(255,255,255,CurrentTime);
    END; (* IF *)
    Station.CurrentPicture:=AtPicture;
  END; (* WITH *)
END PictureMenu;

VAR
  FirstStation,
  CurrentStation : StationPtr;
  NumofStations  : CARDINAL;

PROCEDURE SelectStation(VAR ForStation : StationRec);
(* Changes the current directory to the station's directory.  Loads the
   map files *)
VAR
  ShortName : ARRAY[0..7] OF CHAR;
  OK        : BOOLEAN;
BEGIN
  (* If in another station's directory, move out of it *)
  IF CurrentStation<>NIL THEN
    ChDir('..',OK);
  END; (* IF *)
  WITH ForStation DO
    (* Change to station directory *)
    ChDir(StationName,OK);
    IF OK THEN
      (* Write current station in lower right-hand corner of screen *)
      Copy(StationName,0,Pos('.',StationName),ShortName);
      Concat(ShortName,'        ',ShortName);
      SetPlane({2});
      GotoXY(576,308); WriteString(ShortName);
      (* Reset Current Picture *)
      CurrentPicture:=0;
      CurrentStation:=ADR(ForStation);
    ELSE
      CurrentStation:=NIL;
      SetPlane({2});
      GotoXY(576,308); WriteString('        ');
    END; (* IF *)
  END; (* WITH *)
END SelectStation;

PROCEDURE StationMenu;
(* Menu-driven station management.  Calls SelectStation *)
VAR
  TempStation,
  AtStation    : StationPtr;
  ShortName    : ARRAY[0..15] OF CHAR;
  Key          : CHAR;
BEGIN
  (* Draw the window *)
  SetPlane({2}); SetFunc(clr);
  FillArea(112,14,320,238,255)(*216,70,424,294,255*);
  SetPlane({3});
  Window(112,14,320,238)(*216,70,424,294*);
(*  WriteString('ออออออออ STATIONS ออออออออ'); *)
  WriteString('NAME     PHONE            ');
  GotoXY(0,168);
  WriteString('ออออออออออออออออออออออออออ');
  WriteString('   <RET>๚Select Station'); WriteLn;
  WriteString('     F1๚Add  F2๚Delete');
  Window(112,28,320,182)(*216,98,424,252*);
  AtStation:=FirstStation;
  WHILE AtStation<>NIL DO
    WITH AtStation^ DO
      Copy(StationName,0,Pos('.',StationName),ShortName);
      Concat(ShortName,'        ',ShortName);
      ShortName[9]:=CHR(0);
      WriteString(ShortName);
      Copy(Phone,0,15,ShortName);                          
      WriteString(ShortName);
      AtStation:=Next;
    END; (* WITH *)
  END; (* WHILE *)
  AtStation:=CurrentStation;
  REPEAT
    IF AtStation<>NIL THEN
      FillAreaFunc(112,AtStation^.StationNumber*14+14,
                   320,AtStation^.StationNumber*14+27,255,xor);
    END; (* IF *)
    Read(Key);
    IF Key=ASCII.nul THEN
      Read(Key);
      INC(Key,128);
    END; (* IF *)
    IF AtStation<>NIL THEN
      FillAreaFunc(112,AtStation^.StationNumber*14+14,
                   320,AtStation^.StationNumber*14+27,255,xor);
    END; (* IF *)
    CASE Key OF
      320C,(* DOWN ARROW *)
      '+' : IF AtStation=NIL THEN
              AtStation:=FirstStation;
            ELSIF AtStation^.Next<>NIL THEN
              AtStation:=AtStation^.Next;
            END
|     310C,(* UP ARROW *)
      '-' : IF AtStation<>FirstStation THEN
              TempStation:=FirstStation;
              WHILE (TempStation^.Next<>AtStation) DO
                TempStation:=TempStation^.Next;
              END; (* WHILE *)
              AtStation:=TempStation;
            ELSE
              AtStation:=NIL;
            END (* IF *)
      ELSE
    END;
  UNTIL Key=ASCII.EOL;
  SetPlane({2,3}); SetFunc(clr);
  FillArea(112,14,320,238,0)(*216,70,424,294,0*);
  Window(0,0,639,349);
  IF (AtStation<>NIL) AND (AtStation<>CurrentStation) THEN
    SelectStation(AtStation^);
  END; (* IF *)
END StationMenu;

PROCEDURE InitStationDir;
(* Sets up the picture storage system *)
VAR
  Name      : ARRAY[0..11] OF CHAR;
  FileTime  : Time;
  SizeHigh,
  SizeLow   : CARDINAL;
  Attr      : AttrSet;
  Last,OK   : BOOLEAN;
  PhoneFile : File;
  AtStation : CARDINAL;
  TempPic   : PictureRec;
BEGIN
  (* Searches for station subdirectories, and creates station
     headers for each one it finds *)
  SetDirSearch('????????.STA',AttrSet{subdir},Last);
  IF NOT(Last) THEN
    DirEntry(Name,FileTime,SizeHigh,SizeLow,Attr,Last);
    NEW(FirstStation);
    (* Set the name and station number *)
    Assign(Name,FirstStation^.StationName);
    FirstStation^.StationNumber:=1;
    CurrentStation:=FirstStation;
    (* Set the number of stations *)
    NumofStations:=1;
    WHILE NOT(Last) DO
      INC(NumofStations);
      DirEntry(Name,FileTime,SizeHigh,SizeLow,Attr,Last);
      (* Create a new station header, linked into the list *)
      NEW(CurrentStation^.Next);
      CurrentStation:=CurrentStation^.Next;
      (* Set the name and station number *)
      Assign(Name,CurrentStation^.StationName);
      CurrentStation^.StationNumber:=NumofStations;
    END; (* WHILE *)
    CurrentStation^.Next:=NIL;
  ELSE
    FirstStation:=NIL;
    NumofStations:=0;
  END; (* IF *)
  (* Now, read the picture lists for each station found *)
  CurrentStation:=FirstStation;
  WHILE CurrentStation<>NIL DO
    (* Go into the station's subdirectory *)
    ChDir(CurrentStation^.StationName,OK);
    IF OK THEN
      WITH CurrentStation^ DO
        (* Read the phone number from PHONENUM.TXT *)
        Lookup(PhoneFile,'PHONENUM.TXT',FALSE);
        ReadNBytes(PhoneFile,ADR(Phone),63,SizeLow);
        Phone[SizeLow]:=CHR(0);
        Close(PhoneFile);
        NumofPictures:=0; CurrentPicture:=0;
        (* Search for picture files *)
        SetDirSearch('???????.PIC',AttrSet{},Last);
        WHILE NOT(Last) DO
          DirEntry(Name,FileTime,SizeHigh,SizeLow,Attr,Last);
          (* Set picture's time, range, tilt and gain *)
          FileParam(TempPic,Name,OK);
          (* Set the picture's date by date of file creation *)
          TempPic.TimeofPic.day:=FileTime.day;
          TempPic.Size:=SizeLow;
          IF OK THEN
            (* Insert the picture into the picture list *)
            AddPicture(CurrentStation^,TempPic,CurrentPicture);
          END; (* IF *)
        END; (* WHILE *)
        CurrentPicture:=0;
      END; (* WITH *)
      ChDir('..',OK);
    END; (* IF *)
    CurrentStation:=CurrentStation^.Next;
  END; (* WHILE *)
  CurrentStation:=NIL;
END InitStationDir;

VAR
  CurrentTime : Time;
  Com         : CHAR;
  TPtr        : ADDRESS;
  CursX,CursY : CARDINAL;
  OK          : BOOLEAN;

BEGIN
  GetTime(CurrentTime);
  WriteParams(255,255,255,CurrentTime);
  SetPlane({2});
  FillArea(0,0,640,13,255);
  SetPlane({3});
  GotoXY(0,0);
  WriteString('ออออออออออออออ F1๚STATION  F2๚DIAL  F3๚STORAGE  F4๚MAPS  ESC๚EXIT ออออออออออออออ');
  Line(0,13,639,13);
  SetDrive(2);
  InitStationDir;
  StationMenu;
  CursX:=320; CursY:=175;
  REPEAT
    SetPlane({3});
    Read(Com);
    IF Com=ASCII.nul THEN
      Read(Com); INC(Com,128);
    END;
    CASE Com OF
      273C (* F1 *)
          : SetPlane({3}); FillAreaFunc(112,0,208,12,255,xor);
            StationMenu;
            SetPlane({3}); FillAreaFunc(112,0,208,12,255,xor);
|     275C (* F3 *)
          : SetPlane({3}); FillAreaFunc(280,0,382,12,255,xor);
            PictureMenu(CurrentStation^);
            SetPlane({3}); FillAreaFunc(280,0,382,12,255,xor);
|     276C (* F4 *)
          : WITH CurrentStation^ DO
              INCL(Picture[CurrentPicture].Flags,NotSaved);
            END;
|     277C (* F5 *)
          : IF Available(32768) THEN
              ALLOCATE(TPtr,32768);
              GotoXY(0,10); SetPlane({2});
              WriteString('32K-');
            ELSE
              GotoXY(0,10); SetPlane({2});
              WriteString('    ');
            END
|     320C (* DOWN ARROW  *) : INC(CursY)
|     310C (* UP ARROW    *) : DEC(CursY)
|     315C (* RIGHT ARROW *) : INC(CursX)
|     313C (* LEFT ARROW  *) : DEC(CursX)
|     324C..336C (* SHIFT F1..F10 *)
          : GotoXY(CursX,CursY);
            DEC(Com,174);
            Write('['); Write(Com); Write(']')
|     '+' : WITH CurrentStation^ DO
              IF CurrentPicture<NumofPictures THEN
                INC(CurrentPicture);
                SelectPicture(Picture[CurrentPicture]);
              END; (* IF *)
            END (* WITH *)
|     '-' : WITH CurrentStation^ DO
              IF CurrentPicture>1 THEN
                DEC(CurrentPicture);
                SelectPicture(Picture[CurrentPicture]);
              ELSIF CurrentPicture=1 THEN
                DEC(CurrentPicture);
                SetPlane({0,1}); FillArea(0,0,639,349,0);
                WriteParams(255,255,255,CurrentTime);
              END; (* IF *)
            END (* WITH *)
      ELSE
    END; (* CASE *)
  UNTIL Com=ASCII.esc;
  ChDir('..',OK);
END RadarStore.
