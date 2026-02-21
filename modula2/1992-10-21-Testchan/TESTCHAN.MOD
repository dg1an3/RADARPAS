MODULE TestChannel;

(* Serial channel testing program tests a loop-through
   at various data rates, storing recall on disk. *)

IMPORT
    rs, rs2, IO, Lib;

CONST
    BlockSize = 1+2+128+2;

VAR
    TestBlock, RxBlock  : ARRAY [ 0..BlockSize-1 ] OF SHORTCARD;
    I, Retry  : CARDINAL;
    Blocks, ByteErrors, TimeOuts  :  CARDINAL;

BEGIN
    IO.WrStr(' TestChannel Error Testing Program ');
    IO.WrLn;

    FOR I := 0 TO BlockSize-1 DO
        TestBlock[ I ] := SHORTCARD(I*97);
(*        IO.WrCard( I, 4 );
        IO.WrShtCard( TestBlock[ I ], 4 );
        IO.WrLn; *)
    END (* FOR *);

    Lib.RANDOMIZE;

    rs.Install( 1 );
    rs.Init( 9600, 8, rs.None, TRUE, FALSE );
    rs2.Install( 2 );
    rs2.Init( 9600, 8, rs2.None, TRUE, FALSE );
    TimeOuts := 0;
    ByteErrors := 0;
    Blocks := 0;

    REPEAT

        INC( Blocks );
        IO.WrCard( Blocks, 5 );
        IO.WrStr( ' Send...' );
        rs.Send( TestBlock, SIZE( TestBlock) );
        IO.WrStr( 'rx...' );
        Retry := 0;
        I := 0;
        WHILE ( rs2.RxCount() < SIZE( RxBlock ) ) & ( Retry < 50 ) DO
            IF I < rs2.RxCount() THEN
                I := rs2.RxCount();
                Retry := 0;
            ELSE
                INC( Retry );
            END (* IF *);
        END (* WHILE *);
        IF Retry = 10  THEN
            INC( TimeOuts );
        ELSE
            rs2.Receive( RxBlock, SIZE( RxBlock ) );
        END (* IF *);

        FOR I := 0 TO BlockSize-1 DO
            IF TestBlock[ I ] # RxBlock[ I ] THEN
                INC( ByteErrors );
            END (* IF *);
    (*        IO.WrCard( I, 4 );
            IO.WrShtCard( TestBlock[ I ], 4 );
            IO.WrShtCard( RxBlock[ I ], 4 );
            IO.WrBool( TestBlock[ I ]=RxBlock[ I ], 8 );
            IO.WrLn; *)
        END (* FOR *);

        IO.WrStr( ' Byte Errors:' );
        IO.WrCard( ByteErrors, 6 );
        IO.WrStr( ' Time Outs:' );
        IO.WrCard( TimeOuts, 6 );
        IO.WrLn;

    UNTIL ( IO.KeyPressed() ) & ( IO.RdKey()=" " );

END TestChannel.