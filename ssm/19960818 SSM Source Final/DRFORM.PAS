(* DrForm.pas *)
(* Copyright (C) 1985, 91  DG Lane *)

type    LogRec  = record
            date  : DateRec;
            total  : real;
            dataPtr  : integer;
            descriptorPtr  : integer;
        end (* LogRec *);

        DataRec  = record
            shift  : integer;
            Bal1, Chg1, ROA1, Total1  : real;
            Cash, Chks, SubT, PO, Chg2,
            ManCC, CC, Total2, CCFee,
            Bal2, Over, Short, Bal3  : real;
            Gas, Oil, Acc, Lab, Snacks,
            Emiss, Kero, Wrkr, ROA2,
            Tax, Total3  : real;
        end (* record *);

const   MAX_LOG  = 731;

var     Log  : array [0..MAX_LOG] of LogRec;
        AuxLog  : LogRec;
        LogFile  : file of LogRec;
        CurrentLog  : integer;
        LastLog  : integer;
        SaveToLog  : integer;

        DIRWindow  : byte;
        DIRScreen  : array [1..52, 1..78] of char;
        Data  : DataRec;
        AuxData  : DataRec;
        DataFile  : file of DataRec;
        DIRChanged  : boolean;
        CurrentDescriptor  : integer;

procedure WriteDIR;
begin   WGoto(Col1, 3);
        Write(Usr, ShortDate(Log[CurrentLog].Date), '    ');
        WGoto(Col3, 3);
        Write(Usr, Data.Shift:8);
        (* Write first column *)
        WGoto(Col1, 11);
        Write(Usr, Data.Bal1:8:2);
        WGoto(Col1, 12);
        Write(Usr, Data.Chg1:8:2 );
        WGoto(Col1, 13);
        Write(Usr, Data.ROA1:8:2 );
        WGoto(Col1, 15);
        Write(Usr, Data.Total1:8:2);
        (* Write second column *)
        WGoto(Col2, 7);
        Write(Usr, Data.Cash:8:2);
        WGoto(Col2, 8);
        Write(Usr, Data.Chks:8:2);
        WGoto(Col2,9);
        Write(Usr, Data.SubT:8:2);
        WGoto(Col2, 11);
        Write(Usr, Data.PO:8:2);
        WGoto(Col2, 12);
        Write(Usr, Data.Chg2:8:2);
        WGoto(Col2, 13);
        Write(Usr, Data.ManCC:8:2);
        WGoto(Col2, 14);
        Write(Usr, Data.CC:8:2);
        WGoto(Col2, 15);
        Write(Usr, Data.Total2:8:2);
        WGoto(Col2, 17);
        Write(Usr, Data.CCFee:8:2);
        WGoto(Col2, 18);
        Write(Usr, Data.Bal2:8:2);
        WGoto(Col2, 19);
        Write(Usr, Data.Over:8:2);
        WGoto(Col2, 20);
        Write(Usr, Data.Short:8:2);
        WGoto(Col2, 21);
        Write(Usr, Data.Bal3:8:2);
        (* Write third column *)
        WGoto(Col3, 7);
        Write(Usr, Data.Gas:8:2);
        WGoto(Col3, 8);
        Write(Usr, Data.Oil:8:2);
        WGoto(Col3, 9);
        Write(Usr, Data.Acc:8:2);
        WGoto(Col3, 10);
        Write(Usr, Data.Lab:8:2);
        WGoto(Col3, 11);
        Write(Usr, Data.Snacks:8:2);
        WGoto(Col3, 12);
        Write(Usr, Data.Emiss:8:2);
        WGoto(Col3, 13);
        Write(Usr, Data.Kero:8:2);
        WGoto(Col3, 14);
        Write(Usr, Data.Wrkr:8:2);
        WGoto(Col3, 15);
        Write(Usr, Data.ROA2:8:2);
        WGoto(Col3, 16);
        Write(Usr, Data.Tax:8:2);
        WGoto(Col3, 17);
        Write(Usr, Data.Total3:8:2);
end (* WriteDIR *);

procedure ReTotal;
begin   with Data do begin
            Total1 := Bal1 + Chg1 + ROA1;
            SubT := Cash + Chks;
            Total2 := SubT + PO + Chg2 + ManCC + CC;
            Bal2 := Total2 - CCFee;
            (* Over *)
            (* Short *)
            (* Bal2 *)
            Total3 := Gas + Oil + Acc + Lab + Snacks +
                Emiss + Kero + Wrkr + ROA2 + Tax;
        end (* with *);
        Log[CurrentLog].Total := Data.Total2;
end (* ReTotal *);

procedure EditEdit;
var     Place  : integer;
        XPos, YPos  : integer;
        key  : char;
        escFlag, decPoint  : boolean;
begin   Message('EDIT MODE: ESC = Exit');
        Place := 1;
        repeat
            (* Store value in proper variable *)
            case Place OF
                1  : begin XPos := Col3; YPos := 3; end;
                2  : begin XPos := Col1; YPos := 11; end;
                3  : begin XPos := Col1; YPos := 12; end;
                4  : begin XPos := Col1; YPos := 13; end;
                5  : begin XPos := Col2; YPos := 7; end;
                6  : begin XPos := Col2; YPos := 8; end;
                7  : begin XPos := Col2; YPos := 11; end;
                8  : begin XPos := Col2; YPos := 12; end;
                9  : begin XPos := Col2; YPos := 13; end;
                10  : begin XPos := Col2; YPos := 14; end;
                11  : begin XPos := Col2; YPos := 17; end;
                12  : begin XPos := Col2; YPos := 18; end;
                13  : begin XPos := Col2; YPos := 19; end;
                14  : begin XPos := Col2; YPos := 20; end;
                15  : begin XPos := Col3; YPos := 7; end;
                16  : begin XPos := Col3; YPos := 8; end;
                17  : begin XPos := Col3; YPos := 9; end;
                18  : begin XPos := Col3; YPos := 10; end;
                19  : begin XPos := Col3; YPos := 11; end;
                20  : begin XPos := Col3; YPos := 12; end;
                21  : begin XPos := Col3; YPos := 13; end;
                22  : begin XPos := Col3; YPos := 14; end;
                23  : begin XPos := Col3; YPos := 15; end;
                24  : begin XPos := Col3; YPos := 16; end;
            end (* case *);
            HiLiteCell(XPos, YPos, 7);
            ReadKbd(key, escFlag);
            LoLiteCell(XPos, YPos, 7);
            case Key of
                KEY_UP, KEY_LT  : if (Place > 1) then
                    Place := Place - 1
                else
                    Place := 24;
                KEY_DN, KEY_RT, KEY_TAB  : if (Place < 24) then
                    Place := Place + 1
                else
                    Place := 1;
                KEY_ENTER  : Place := Place + 1;
                '0'..'9', '.' : begin
                    Val(EnterCell(XPos, YPos, 7, ['0'..'9','.'],
                        key, decPoint), X, I);
                    if (Place > 1) and not decPoint then
                        X := X / 100;
                    (* Store value in proper variable *)
                    case Place OF
                        1  : Data.Shift := trunc(X);
                        2  : Data.Bal1  := X;
                        3  : Data.Chg1  := X;
                        4  : Data.ROA1  := X;
                        5  : Data.Cash  := X;
                        6  : Data.Chks  := X;
                        7  : Data.PO    := X;
                        8  : Data.Chg2  := X;
                        9  : Data.ManCC := X;
                        10  : Data.CC    := X;
                        11  : Data.CCFee := X;
                        12  : Data.Bal2  := X;
                        13  : Data.Over  := X;
                        14  : Data.Short := X;
                        15  : Data.Gas   := X;
                        16  : Data.Oil   := X;
                        17  : Data.Acc   := X;
                        18  : Data.Lab   := X;
                        19  : Data.Snacks:= X;
                        20  : Data.Emiss := X;
                        21  : Data.Kero  := X;
                        22  : Data.Wrkr  := X;
                        23  : Data.ROA2  := X;
                        24  : Data.Tax   := X;
                    end (* case *);
                    ReTotal;
                    WriteDIR;
                    DIRChanged := true;
                    Place := Place + 1;
                end (* 0..9, . *);
            end (* case *);
(*            if (key = KEY_ENTER) then
                Place := Place + 1; *)
        until (Key = KEY_ESC) or (Place > 24);
        Message('E = Edit  P = Print  ESC = Exit');
end (* EditEdit *);

procedure LoadDIR;
begin   with Log[CurrentLog] do begin
            if (DataPtr > 0) then begin
                ReSet(DataFile);
                Seek(DataFile, DataPtr-1);
                Read(DataFile, Data);
                Close(DataFile);
                Total := Data.Total2;
            end else begin
                FillChar(Data, SizeOf(Data), 0);
                WriteDIR;
                EditEdit;
            end (* if *);
        end (* with *);
end (* LoadDIR *);

procedure SaveLog(ForLog  : integer); forward;

procedure SaveDIR;
begin   with Log[CurrentLog] do begin
            ReSet(DataFile);
            if (DataPtr < 0) then
                DataPtr := -DataPtr;
            if (DataPtr = 0) then
                DataPtr := FileSize(DataFile) + 1;
            Seek(DataFile, DataPtr - 1);
            Write(DataFile, Data);
            Close(DataFile);
            SaveLog(CurrentLog);
        end (* with *);
end (* SaveDIR *);

procedure Edit;
var     key  : char;
        escFlag  : boolean;
begin   DIRChanged := false;
        ChangeWindow(DRWindow);
        Message('E = Edit  P = Print  ESC = Exit');
        LoadDIR;
        WriteDIR;
        repeat
            ReadKbd(key, escFlag);
            case Key of
                'e'  : EditEdit;
                'p'  : PrintWind;
            end (* case *);
        until (Key = #27);
        if DIRChanged then
            SaveDIR;
end (* Edit *);
