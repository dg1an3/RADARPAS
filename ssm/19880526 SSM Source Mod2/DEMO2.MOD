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
     CloseDisplayFile, MainFrame, FrameKey, ReadDisplayFrame, 
     ShowDisplayFrame; 
FROM ScreenInput IMPORT FrameSequence, Input, ChangeField, Control; 
FROM Scrn2Ndx IMPORT PutScrRec, FillScr;
FROM SmartScreen IMPORT SetCursorHeight;
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
  OpenDisplayFile( ScreenFile, 'demo1.dsp' );
  FrameSequence(1);
  CloseDisplayFile( ScreenFile );
  SetCursorHeight(2);
END Demo1.
