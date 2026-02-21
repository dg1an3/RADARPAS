(* DrCustom.pas *)
(* Copyright (C) 1985, 91  DG Lane *)

const   DRWindow  : byte  = 22;
        DRScreen  : array [1..22, 1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                                DAILY REPORT                                บ',
'บ  DATE:                                                 SHIFT:              บ',
'ฬออออออออออออออออออออออออออัออออออออออออออออออออออออออัออออออออออออออออออออออน',
'บ  CHARGES                 ณ         R.O.A.           ณ               P.O.   บ',
'บ                          ณ                          ณ                      บ',
'บ                          ณ    Cash                  ณ    Gas               บ',
'บ                          ณ  Checks                  ณ    Oil               บ',
'บ                          ณ   Sub-T                  ณ   Acc.               บ',
'บ                          ณ                          ณ   Lab.               บ',
'บ     Bal.                 ณ    P.O.                  ณ Snacks               บ',
'บ     Chg.                 ณ    Chg.                  ณ Emiss.               บ',
'บ   R.O.A.                 ณ  Man CC                  ณ  Kero.               บ',
'บ                          ณ    C.C.                  ณ  Wrkr.               บ',
'บ    Total                 ณ   Total                  ณ R.O.A.               บ',
'บ                          ณ                          ณ    Tax               บ',
'บ                          ณ C.C.Fee                  ณ  Total               บ',
'บ                          ณ Balance                  ณ                      บ',
'บ                          ณ    Over                  ณ                      บ',
'บ                          ณ   Short                  ณ                      บ',
'บ                          ณ Balance                  ณ                      บ',
'ศออออออออออออออออออออออออออฯออออออออออออออออออออออออออฯออออออออออออออออออออออผ');
        Col1  = 12;
        Col2  = 38;
        Col3  = 64;

        IAWindow  : byte  = 22;
        IAScreen  : array [1..22, 1..78] of char = (
'ษอออออออออออออออออออออออออออออออออออออออัออออออออออออออออออออออออออออออออออออป',
'บ DAILY REPORT                          ณ DATE                      TOTAL    บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด                                    บ',
'บ ST. ANDREW`S TEXACO                   ณ                                    บ',
'บ 2000 Campus Drive                     ณ                                    บ',
'บ St. Charles, MO  63301                ณ                                    บ',
'วฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด                                    บ',
'บ PRESS ณ                               ณ                                    บ',
'วฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด                                    บ',
'บ    F1 : Edit Entry                    ณ                                    บ',
'บ    F2 : Month-to-Date                 ณ                                    บ',
'บ    F3 : Year-to-Date                  ณ                                    บ',
'บ       :                               ณ                                    บ',
'บ    G  : Goto Entry                    ณ                                    บ',
'บ    I  : Insert Entry                  ณ                                    บ',
'บ    C  : Change Date of Entry          ณ                                    บ',
'บ    D  : Delete Entry                  ณ                                    บ',
'บ       :                               ณ                                    บ',
'บ       :                               ณ                                    บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด                                    บ',
'บ                                       ณ                                    บ',
'ศอออออออออออออออออออออออออออออออออออออออฯออออออออออออออออออออออออออออออออออออผ');
        AboveLog  = 8;
        BelowLog  = 9;
        LogWindSize  = 19;
        UXLog  = 42;
        UYLog  = 3;
        LXLog  = 77;
        LYLog  = 21;
