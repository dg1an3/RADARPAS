(* include.pas Edited 6/22/96 DGL *)
(* Contains common includes for the SSM modules *)
(* Copyright (C) 1985,96 DG Lane *)

const   Program_Path  = 'c:\ssm\source\';
        Data_Path  = 'c:\ssm\source\';
        DataDrive  = 'c';

type    DateRec  = record
            Month  : byte;
            Day  : byte;
            Year  : integer;
            Hour  : byte;
            Minute  : byte;
        end (* DateRec *);

        String10  = string[10];

        LineType  = string[80];

        regType  = record
            case integer of
                1 : (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags  : integer);
                2 : (AL, AH, BL, BH, CL, CH, DL, DH  : byte);
        end (* regType *);

var     TodaysDate  : DateRec;    (* Shared variables *)
        DateEntered  : boolean;
        dChangeStatus  : boolean;
        dPassWord  : string[16];

        dMenuProg  : file;
        dChanged  : boolean;
        dCaseErr  : integer;
        ErrorNumber  : integer;
        dLine  : LineType;
        dStrA, dStrB  : String10;
        dX, dY, dZ  : real;
        dI, dJ, dK  : integer;
        dRight  : boolean;
        dMatch  : boolean;
        ErrorFlag  : boolean;
