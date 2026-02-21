MODULE CreatDat;

IMPORT IO, FIO, Str;

VAR
    S  :  ARRAY [ 0..80 ] OF CHAR;

     Options  :  RECORD
         Baud     :  CARDINAL;
         ComPort  :  CARDINAL;
         Update   :  CARDINAL;
         ArmyTime :  BOOLEAN;
         Maps     :  BOOLEAN;
         Banner   :  ARRAY [ 0..40 ] OF CHAR;
     END (* RECORD *);

    OptFile  :  FIO.File;

BEGIN
    IO.WrStr( ' E300DB version 1.1 DAT file Creation Utility ' );
    IO.WrLn;
    IO.WrStr( ' Copyright (C) 1992, D. G. Lane ' );
    IO.WrLn;
    IO.WrLn;
    IO.WrStr( ' Type banner title (max 40 characters): ' );
    IO.WrLn;
    IO.RdStr( Options.Banner );

    S := '                    ';
    Str.Concat( S, S, Options.Banner );
    Str.Concat( S, S, '                   ' );
    Str.Slice( Options.Banner, S, Str.Length(Options.Banner) DIV 2, 40 );

    IO.WrLn;
    IO.WrStr( 'Sample output: ' ); IO.WrLn;
    IO.WrStr( 'ษออออออออออออออออออออออออออออออออออออออออป' ); IO.WrLn;
    IO.WrStr( 'บ        E300SCA TERMINAL, ver 1.0       บ' ); IO.WrLn;
    IO.WrStr( 'บ' );
    IO.WrStr( Options.Banner );
    IO.WrStr( 'บ' ); IO.WrLn;
    IO.WrStr( 'บ           Revision 11/13/92            บ' ); IO.WrLn;
    IO.WrStr( 'บ           Copyright (C) 1992           บ' ); IO.WrLn;
    IO.WrStr( 'บ               D. G. Lane               บ' ); IO.WrLn;
    IO.WrStr( 'บ           All rights reserved          บ' ); IO.WrLn;
    IO.WrStr( 'ศออออออออออออออออออออออออออออออออออออออออผ' ); IO.WrLn;

    Options.Baud := 9600;
    Options.ComPort := 1;
    Options.ArmyTime := FALSE;

    OptFile := FIO.Create( 'E300DB.DAT' );
    FIO.WrBin( OptFile, Options, SIZE( Options ) );
    FIO.Close( OptFile );

END CreatDat.
