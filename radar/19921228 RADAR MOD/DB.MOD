IMPLEMENTATION MODULE DB;

IMPORT Lib, rs2, Process, TimeDate;

(*
VAR
    Buffer  :  ARRAY [ 0..54000 ] OF BYTE;
    Size    :  CARDINAL;
    At      :  CARDINAL;
*)

CONST
    Baud  =  9600;


PROCEDURE TxProcess;
(* Send Tx over rs2 port *)
BEGIN

    LOOP
        WHILE rs2.TxCount() > 0 DO END;
        Process.Delay( 8 );
(*        Lib.Delay( 20000 DIV Baud );
        rs2.Break( 40000 DIV Baud ); *)
        rs2.Send( Buffer, Size );
    END (* LOOP *);

END TxProcess;

PROCEDURE InstallTx;
BEGIN
    rs2.Install( 2 );
    rs2.Init( Baud, 8, rs2.None, TRUE, FALSE );
    Size := 0;
    Process.StartScheduler;
    Process.StartProcess( TxProcess, 4096, 1 );
END InstallTx;

TYPE  BufType = ARRAY [ 0..54000 ] OF BYTE;

VAR  K  :  CHAR;
     RxBuf   : ARRAY [ 0..8000 ] OF BYTE;
     RxSize  :  CARDINAL;
     TimeOut :  CARDINAL;

PROCEDURE RxProcess;
(* Get Rx over rs2 port *)
BEGIN

    WHILE rs2.RxCount() > 0 DO
        rs2.Receive( RxBuf, rs2.RxCount() );
        Process.Delay( 4 );
    END (* WHILE *);
    LOOP
        (* Now receive until next sync *)
        At := 0;
        WHILE rs2.RxCount() > 0 DO
            Signal := TRUE;
            RxSize := rs2.RxCount();
            rs2.Receive( RxBuf, RxSize );
            Process.Lock;
            IF Lib.Compare( ADR( Buffer[ At ] ), ADR( RxBuf ),
                RxSize ) < RxSize THEN
                NewFile := TRUE;
                Lib.Move( ADR( RxBuf ), ADR( Buffer[ At ]), RxSize );
                At := At+RxSize;
                Size := At;
                Process.Unlock;
(*                Process.Lock;
                Lib.Fill( ADR( Buffer[ Size+1 ] ), 54000-Size, 0 );
                Process.Unlock; *)
            ELSE
(*                Lib.Move( ADR( RxBuf ), ADR( Buffer[ At ]), RxSize ); *)
                At := At+RxSize;
                Process.Unlock;
            END (* IF *);
            Process.Delay( 2 );
        END (* WHILE *);
        TimeOut := 10;
        WHILE ( rs2.RxCount()=0 ) & ( TimeOut > 0 ) DO
            Process.Delay( 1 );
            DEC( TimeOut );
        END (* WHILE *);
        IF TimeOut=0 THEN Signal:=FALSE END;
    END (* LOOP *);

END RxProcess;

PROCEDURE InstallRx;
BEGIN
    rs2.Install( 1 );
    rs2.Init( Baud, 8, rs2.None, TRUE, FALSE );

    DB.NewFile := FALSE;
    DB.Signal := FALSE;
    DB.Size := 0;
    DB.At := 0;
    Lib.Fill( ADR( Buffer ), 54000, 0 );
    Process.StartScheduler;
    Process.StartProcess( RxProcess, 4096, 1 );
END InstallRx;

END DB.