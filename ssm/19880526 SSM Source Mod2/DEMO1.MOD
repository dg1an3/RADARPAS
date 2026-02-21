MODULE Demo1;
(*
 *  REPERTOIRE
 *  Release 1.4
 *  (c) Copyright 1986, 1987 PMI
 *  Portland, Oregon
 *  All rights reserved
 *  Compuserve:  74706,262
 *  BIX:  pmi
 *)
FROM NdxBones IMPORT NdxFileType, OpenNdxFile, 
     CloseNdxFile; 
FROM NdxFiles IMPORT CreateNdxFile, WriteRecord; 
FROM ScreenDisplay IMPORT DisplayFile, OpenDisplayFile, 
     MainFrame, FrameKey, ReadDisplayFrame, 
     ShowDisplayFrame; 
FROM ScreenInput IMPORT Input, ChangeField, Control; 
FROM Scrn2Ndx IMPORT PutScrRec, FillScr;
FROM StrEdit IMPORT AssignStr;
FROM UserOps IMPORT EndCode;
FROM WindowPrims IMPORT PushCursorHeight, 
     PopCursorHeight;

VAR
  NdxFile: NdxFileType;
  ScreenFile: DisplayFile;
  NextFrame: FrameKey;
  RecName: ARRAY [0..19] OF CHAR;

BEGIN
  PushCursorHeight();
    (*Save the cursor height because the screen system 
      turns it off, and we will want to restore it as 
      we exit the program.*) 
  IF NOT OpenNdxFile( NdxFile, 'demo1.ndx' ) THEN
    (*If the file doesn't exist, create it.*)
    CreateNdxFile( NdxFile, 'demo1.ndx', 
        'RecName, age, job' );
  END;
  OpenDisplayFile( ScreenFile, 'demo1.dsp' );
  REPEAT
    NextFrame := 1;
    Input( NextFrame );
      (*This will always display the screen that says 
        "Enter a record name."*) 
    IF NextFrame # EndCode THEN
      AssignStr( MainFrame^.fields^.txt, RecName );
      ReadDisplayFrame( ScreenFile, MainFrame, 2 );
      IF NOT FillScr( NdxFile, MainFrame, RecName, '') 
        THEN ChangeField( MainFrame, RecName, 
             'RecName', TRUE ); 
      END;
      ShowDisplayFrame( MainFrame, 0, 0, 0, 0 );
      NextFrame := Control();
      IF NextFrame = MainFrame^.normlnext THEN
        IF NOT PutScrRec(NdxFile, MainFrame, RecName,'')
            THEN HALT(); END;
        IF NOT WriteRecord( NdxFile, RecName ) 
            THEN HALT(); END;
      END;
    END;
  UNTIL NextFrame = EndCode;
  CloseNdxFile( NdxFile );
  PopCursorHeight();
END Demo1.
