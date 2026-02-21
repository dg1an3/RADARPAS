(* include.pas Edited 6/22/96 DGL *)
(* Contains common includes for the SSM modules *)
(* Copyright (C) 1985,96 DG Lane *)

const   SERIAL_NUMBER  = '102';
        COMP_NAME = 'St. Andrew`s Texaco           ';
        COMP_NAME_CAP = 'ST. ANDREW`S TEXACO           ';
        COMP_ADDR = '2000 Campus Drive             ';
        COMP_CITY = 'St. Charles, MO  63301        ';

        PROGRAM_PATH = 'd:\';
        DATA_PATH = 'd:\';

        NORM_COLOR = White;
        NORM_BACKG  = Black;
        HILITE_COLOR  = Black;
        HILITE_BACKG  = LightGray;

type    ShortStr  = string[12];
        LongStr  = string[80];
        String30  = string[30];
        String10  = string[10];
        LineType  = string[80];

        DateRec  = record
            Month  : byte;
            Day  : byte;
            Year  : integer;
            Hour  : byte;
            Minute  : byte;
        end (* DateRec *);

var     TodaysDate :   DateRec;
        DateEntered :   byte;
        ChangeStatus :   boolean;
        PassWord :   string[16];

        MenuProg :   file;
        Changed :   boolean;
        CaseErr :   integer;
        ErrorNumber :   integer;
        Line :   LineType;
        StrA, StrB :   String10;
        X, Y, Z :   real;
        I, J, K :   integer;
        Right :   boolean;
        Match :   boolean;
        ErrorFlag :   boolean;




