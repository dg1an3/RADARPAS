MODULE Test; (* Serial file transfers *)


IMPORT IO, Process;



VAR
  TxCount, RxCount : CARDINAL;



PROCEDURE TxFiles;

BEGIN

  LOOP

      IF rs.TxCount() < TxLevel THEN

(*        FetchBlock( SubChan, BlockNum, BlockData );
 *        CalcRS( BlockData, RSCode );
 *        rs.Send( SubChan, 2 );
 *        rs.Send( BlockNum, 2 );
 *        rs.Send( BlockData, BlockSize );
 *        rs.Send( RSCode, RSCodeSize );
 *        rs.Break( BreakLength );
 *)
      END (* IF *);

      Process.Delay( 0 );

  END (* LOOP *);

END TxFiles;



PROCEDURE RxFiles;

BEGIN

  (* Synchronize to break code *)
  REPEAT

      rs.Receive( BlockData, 1 );

  UNTIL rs.BreakTest();

  LOOP

      (* Wait until receiver buffer is fill and DOS is available *)
      IF ( rs.RxCount() > RxLevel ) & ~ DosFlag THEN

          (* Receive the data *)
(*        rs.Receive( SubChan, 2 );
 *        rs.Receive( BlockNum, 2 );
 *        rs.Receive( BlockData, BlockSize );
 *        rs.Receive( RSCode, RSCodeSize );
 *
 *        (* Are we still synchronized? *)
 *        IF rs.BreakTest() THEN
 *
 *            (* Yes, so correct the data and store it *)
 *            CheckRS( BlockData, RSCode );
 *            StoreBlock( SubChan, BlockNum, BlockData );
 *
 *        ELSE
 *
 *            (* No, so re-synch the data *)
 *            REPEAT
 *
 *                rs.Receive( BlockData, 1 );
 *
 *            UNTIL rs.BreakTest();
 *
 *        END (* IF *);
 *)
      END (* IF *);

      Process.Delay( 0 );

  END (* LOOP *);

END RxFiles;


BEGIN

  TxCount := 0;
  RxCount := 0;

  Process.StartScheduler;

  Process.StartProcess( TxFiles, 4096, 1 );
  Process.StartProcess( RxFiles, 4096, 1 );

  LOOP

      IO.WrCard( TxCount, 10 );
      IO.WrCard( RxCount, 10 );
      IO.WrLn;
      IF RxCount >= 100 THEN EXIT END;

  END (* LOOP *);

END Test.