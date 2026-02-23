MODULE ExCom;

(*            C R E A T E D  : 10/14/87
 *        L A S T   E D I T  : 10/14/87
 *              A U T H O R  : Derek Lane
 *              S Y S T E M  : LOGITECH MODULA-2/86
 *
 *  Extended command processor for DOS.  Supplies screen-oriented
 *  file management, disk system searches, etc.
 *)

IMPORT Drectory;

TYPE
  FileListPtr  = POINTER TO FileListRec;
  FileListRec  = RECORD
    Parent     :   FileListPtr;
    File       :   ARRAY[0..255] OF RECORD
      Info     :     Drectory.FileInfoRec;
      SubDir   :     FileListPtr;
    END; (* RECORD *)
  END; (* RECORD *)

PROCEDURE 
