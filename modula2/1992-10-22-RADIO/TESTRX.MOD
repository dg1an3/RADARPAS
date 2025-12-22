MODULE TestRx;

IMPORT DB, IO;


BEGIN
    DB.InstallRx;
    IO.WrStr( ' DB installed. ' ); IO.WrLn;
    LOOP
        IO.WrStr( ' Size: ' ); IO.WrCard( DB.Size, 5 );
        IO.WrStr( ' At: ' ); IO.WrCard( DB.At, 5 );
        IO.WrStr( ' NewFile: ' ); IO.WrBool( DB.NewFile, 1 ); IO.WrLn;
        IO.WrShtCard( DB.Buffer[ 0 ], 4 );
        IO.WrShtCard( DB.Buffer[ 1 ], 4 );
        IO.WrShtCard( DB.Buffer[ 2 ], 4 );
        IO.WrShtCard( DB.Buffer[ 3 ], 4 );
        IO.WrShtCard( DB.Buffer[ 4 ], 4 );
        IO.WrShtCard( DB.Buffer[ 5 ], 4 );
        IF IO.KeyPressed() THEN
            DB.NewFile := FALSE;
            IF IO.RdKey() = "Q" THEN HALT END;
        END (* IF *);
    END (* LOOP *);
END TestRx.
