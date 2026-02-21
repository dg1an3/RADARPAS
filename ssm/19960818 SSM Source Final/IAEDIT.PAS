(* iaedit.pas *)
(* Copyright (C) 1985, 1996 Derek G Lane *)
(* Included from file ia.pas *)
(* Part of the SSM 1.5 Package *)

type    LogRec =   record
            Date :   DateRec;
            Total :   real;
            DataPtr :   integer;
            DescriptorPtr :   integer;
        end (* LogRec *);

        DataRec =   array [1..20] of real;

var     Log :   array [0..731] of LogRec;
        AuxLog :   LogRec;
        LogFile :   file of LogRec;
        CurrentLog :   integer;
        LastLog :   integer;
        SaveToLog :   integer;

        DIRWindow :   byte;
        DIRScreen :   array [1..52, 1..78] of char;
        Data :   DataRec;
        AuxData :   DataRec;
        DataFile :   file of DataRec;
        DIRChanged :   boolean;
        CurrentDescriptor :   integer;

procedure CreateDIRWindow;
var     Count :   integer;
begin   Move(DIRHeader, DIRScreen, SizeOf(DirHeader));
        for Count := 1 to NumberofAccounts do
            Move(DIRExpand, DIRScreen[Count*2 + 8], SizeOf(DIRExpand));
        Move(DIREnd, DIRScreen[Count*2 + 10], SizeOf(DIREnd));
        DIRWindow := NumberofAccounts*2 + 11;
        ChangeWindow(DIRWindow);
        for Count := 1 to NumberofAccounts do begin
            WGoto(4, Count*2+8);
            Write(Usr, Descriptor[Count].Number :8);
            WGoto(15, Count*2+8);
            Write(Usr, Descriptor[Count].Name);
        end (* for *);
end (* CreateDirWindow *);

procedure WriteDIR;
begin   WGoto(48, 2);
        Write(Usr, ShortDate(Log[CurrentLog].Date), '    ');
        for I:=1 to NumberofAccounts do begin
            WGoto(49, 8 + I*2);
            Write(Usr, Data[Descriptor[I].Number] :16:2);
            if (I < NumberofAccounts) then begin
                WGoto(66, 8 + I*2);
                if (Log[CurrentLog].Total <> 0) then
                    Write(Usr, Data[Descriptor[I].Number] /
                        (Log[CurrentLog].Total -
                            Data[NumberofAccounts])*100 :9:2)
                else
                    Write(Usr,'         ');
            end (* if *);
        end (* for *);
        WGoto(49, 10 + NumberofAccounts*2);
        Write(Usr, Log[CurrentLog].Total:16:2);
end (* WriteDIR *);

procedure ReTotal(AccountNum :   integer; Value :   real);
begin   with Log[CurrentLog] do begin
            Total := Total-Data[AccountNum];
            Data[AccountNum] := Value;
            Total := Total + Data[AccountNum];
            WriteDIR;
        end (* with *);
end (* ReTotal *);

procedure EditEdit;
var     Place :   integer;
        YPos :   integer;
begin   Message('EDIT MODE: ESC = Exit');
        Place := 1;
        repeat
            YPos := 8 + Place*2;
            GotoLine(YPos-10);
            HiLiteCell(49, YPos, 16);
            ReadKbd;
            LoLiteCell(49, YPos, 16);
            case Key of
                KEY_UP :   if (Place > 1) then
                    Place := Place - 1;
                KEY_DN :   if (Place < NumberofAccounts) then
                    Place := Place + 1;
                '0'..'9','.' :   begin
                    Val(EnterCell(49, YPos, 16, ['0'..'9','.']),
                        X, I);
                    if not DecPoint then
                        X := X / 100;
                    ReTotal(Descriptor[Place].Number, X);
                    DIRChanged := true;
                end;
            end (* case *);
            if (Key = #13) then
                Place := Place+1;
        until (Key = KEY_ESC) or (Place > NumberofAccounts);
        Key := #0;
        Message('E = Edit  P = Print  ESC = Exit');
end (* EditEdit *);

procedure LoadDIR;
begin   with Log[CurrentLog] do begin
            if (DataPtr > 0) then begin
                ReSet(DataFile);
                Seek(DataFile, DataPtr-1);
                Read(DataFile, Data);
                Close(DataFile);
                Total := 0;
                for I := 1 to NumberofAccounts do begin
                    Total := Total + Data[I];
                end (* for *);
            end else begin
                FillChar(Data, SizeOf(Data), 0);
                EditEdit;
            end (* if *);
        end (* with *);
end (* LoadDIR *);

procedure SaveLog(ForLog :   integer); forward;

procedure SaveDIR;
begin   with Log[CurrentLog] do begin
            ReSet(DataFile);
            if (DataPtr < 0) then
                DataPtr := -DataPtr;
            if (DataPtr = 0) then
                DataPtr := FileSize(DataFile) + 1;
            Seek(DataFile, DataPtr-1);
            Write(DataFile,Data);
            Close(DataFile);
            SaveLog(CurrentLog);
        end (* with *);
end (* SaveDIR *);


procedure Edit;
begin   DIRChanged := false;
        ChangeWindow(DIRWindow);
        Message('E = Edit  P = Print  ESC = Exit');
        LoadDIR;
        WriteDIR;
        repeat
            ReadKbd;
            case Key of
                KEY_UP :   GotoLine(TopLine - 1);
                KEY_DN :   GotoLine(TopLine + 1);
                KEY_HOME :   GotoLine(1);
                KEY_END :   GotoLine(DIRWindow);
                'e' :   EditEdit;
                'p' :   PrintWind;
            end (* case *);
        until (Key = KEY_ESC);
        if DIRChanged then
            SaveDIR;
end (* Edit *);
