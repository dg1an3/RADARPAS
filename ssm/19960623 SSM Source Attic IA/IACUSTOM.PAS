(* iacustom.pas Modified 6/22/96 DGL *)
(* Copyright (C) 1985, 1996 DG Lane *)
(* Included from the file ia.pas *)
(* Part of the SSM 1.5 package *)

const   SerialNumber =   '102';

        DIRHeader :   array [1..9, 1..78] of char = (
'ษออออออออออออออออออออออออออออออออออออออัอออออออออออออออออออออออออออออออออออออป',
'บ DAILY INCOME REPORT                  ณ DATE:                               บ',
'ฬออออออออออออออออออออออออออออออออออออออฯอออออออออออออออออออออออออออออออออออออน',
'บ ST. ANDREW`S TEXACO                                                        บ',
'บ 2000 Campus Drive                                                          บ',
'บ St. Charles, MO  63301                                                     บ',
'วฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤถ',
'บ ACCOUNT # ณ ACCOUNT NAME                     ณ AMOUNT         ณ PERCENT    บ',
'วฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤถ');


        DIRExpand :   array [1..2, 1..78] of char = (
'บ           ณ                                  ณ                ณ            บ',
'วฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤถ');


        DIREnd : array[1..2, 1..78] of char = (
'บ           ณ                           TOTAL  ณ                ณ            บ',
'ศอออออออออออฯออออออออออออออออออออออออออออออออออฯออออออออออออออออฯออออออออออออผ');


        MENU_EDIT =   KEY_F1;    (* Key bindings *)
        MENU_MONTH_SUM =   KEY_F2;
        MENU_YEAR_SUM =   KEY_F3;
        MENU_GOTO_ENTRY =   'g';
        MENU_INS_ENTRY =   'i';
        MENU_NEW_DATE =   'n';
        MENU_DEL_ENTRY =   'd';

        IAWindow :   byte =   22;
        IAScreen :   array [1..22, 1..78] of char = (
'ษอออออออออออออออออออออออออออออออออออออออัออออออออออออออออออออออออออออออออออออป',
'บ INCOME ACCOUNT                        ณ DATE                      TOTAL    บ',
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
'บ    N  : New Date                      ณ                                    บ',
'บ    D  : Delete Entry                  ณ                                    บ',
'บ       :                               ณ                                    บ',
'บ       :                               ณ                                    บ',
'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด                                    บ',
'บ                                       ณ                                    บ',
'ศอออออออออออออออออออออออออออออออออออออออฯออออออออออออออออออออออออออออออออออออผ');

        AboveLog =   8;
        BelowLog =   9;
        LogWindSize =   19;
        UXLog =   42;
        UYLog =   3;
        LXLog =   77;
        LYLog =   21;


type    DescriptorRec =   array [1..20] of record
            Name :   string[40];
            Number :   integer;
        end (* DescriptorRec *);


const   NumberofAccounts :   byte =   10;
        Descriptor :   DescriptorRec = (
           (Name: 'Gasoline';Number: 1),
           (Name: 'Oil'; Number: 2),
           (Name: 'Accessories'; Number: 3),
           (Name: 'Labor'; Number: 4),
           (Name: 'MiniMart'; Number: 5),
           (Name: 'Emissions'; Number: 6),
           (Name: 'Kerosene'; Number: 7),
           (Name: 'Wrecker'; Number: 8),
           (Name: 'ROA'; Number: 9),
           (Name: 'Tax'; Number:10),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0),
           (Name: ''; Number: 0));
