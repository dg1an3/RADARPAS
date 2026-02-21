(* apCustom.pas *)
(* Copyright (C) 1985, 91  DG Lane *)

const   SERIAL_NUMBER     = '103';

const   HILITE_COLOR  = Blue;
        HILITE_BACKG  = LightGray;
        NORM_COLOR = Yellow;
        NORM_BACKG  = Black;

        APWindow  : byte = 23;
        APScreen  : array [1..23,1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป',
'บ                              ACCOUNTS PAYABLE                              บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ      Lane Consulting                ณ F1 : View Acct ณ F4 : Checks         บ',
'บ      7125 Southwest 2E              ณ F2 : Add Acct  ณ F5 : Delete Acct    บ',
'บ      St. Louis, MO  6314301         ณ F3 : Edit Acct ณ F6 : Print Payables บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ NUMBER  NAME                                     BALANCE   30 DAY   60 DAY บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                                                            บ',
'บ                                        SUMMARY:                            บ',
'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
        AboveLog  = 7;
        BelowLog  = 5;
        LogWindSize  = 13;
        UXLog  = 2;
        UYLog  = 9;
        LXLog  = 77;
        LYLog  = 21;


        AccountWindow  : byte = 23;
        AccountScreen  : array [1..23,1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออัอออออออออออออออออออออป',
'บ                                                      ณ F1 : Add Entry      บ',
'บ                                                      ณ F2 : Delete Entry   บ',
'บ                                                      ณ F3 : Edit Entry     บ',
'บ                                                      ณ F4 : Print Account  บ',
'วฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤถ',
'บ DATE     ณ DESCRIPTION                    ณ DEBIT    ณ CREDIT   ณ BALANCE  บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'บ          ณ                                ณ          ณ          ณ          บ',
'ศออออออออออฯออออออออออออออออออออออออออออออออฯออออออออออฯออออออออออฯออออออออออผ');
        AboveEntry  = 7;
        BelowEntry  = 7;