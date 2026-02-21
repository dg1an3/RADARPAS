(* Backup.pas  Copyright (C) 1991  DG Lane *)

const   BACKUP_FILE  = 'a:\ssmback.dat';

type    BackupHdr  = record
            date  : DateRec;
            diskNum  : integer;
        end (* BackupRec *);

procedure InitBackup(backupPath  : LongStr;
    var toFile  : file; var bkhdr  : BackupHdr);
var     YearStr  : ShortStr;
        key  : char;
        escFlag  : boolean;
begin   bkhdr.date := TodaysDate;
        bkhdr.diskNum := bkhdr.diskNum+1;
        if (bkhdr.diskNum > 1) then
            close(toFile);
        Str(bkhdr.date.year, YearStr);
        Writeln;
        Writeln('Please insert backup disk ', bkhdr.diskNum, ' for ',
            YearStr, ' in drive A.');
        Writeln('Press any key to continue...'+^G);
        Writeln;
        ReadKbd(key, escFlag);
        Assign(toFile, backupPath);
        Rewrite(toFile, 1);
        BlockWrite(toFile, bkhdr, SizeOf(bkhdr));
end (* InitBackup *);

type    FileHdr  = record
            name  : LongStr;
            size  : real;
        end (* FileHdr *);

const   BUF_SIZE  = 1024;
var     buffer  : array [1..BUF_SIZE] of byte;

procedure BackupFile(fileName  : LongStr; var toFile  : file;
        var bkhdr  : BackupHdr;
        backupPath  : LongStr);
(* assumes toFile already opened and positioned *)
var     fromFile  : file;
        result  : integer;
        fhdr  : FileHdr;
        numBytes  : real;
        actWritten  : integer;
begin   Assign(fromFile, fileName);
        Reset(fromFile, 1);
        if (IOResult <> 0) then begin
            Writeln('  ', fileName, ' not found.');
            Exit;
        end (* if *);
        fhdr.name := fileName;
        fhdr.size := ActFileSize(fileName);
        BlockWrite(toFile, fhdr, SizeOf(fhdr));
        numBytes := 0.0;
        repeat
            BlockRead(fromFile, buffer, BUF_SIZE, result);
            BlockWrite(toFile, buffer, result, actWritten);
            numBytes := numBytes+actWritten;
            Write('  ', fhdr.name, '...', numBytes:0:0, ' of ',
                fhdr.size:0:0, ' bytes backed up.', ^M);
            (* check for out-of-space on disk *)
            if (actWritten < result) then begin
                Writeln;
                InitBackup(backupPath, toFile, bkhdr);
                result := result - actWritten;
                BlockWrite(toFile, buffer[actWritten+1],
                    result, actWritten);
                numBytes := numBytes+actWritten;
                Write('  ', fhdr.name, '...', numBytes:0:0, ' of ',
                    fhdr.size:0:0, ' bytes backed up.', ^M);
            end (* if *);
        until eof(fromFile);
        close(fromFile);
        Writeln;
end (* BackupFile *);

procedure BackUp;
var     YearStr, fileName  : ShortStr;
        FullPath  : LongStr;
        toFile  : file;
        h  : SearchHandle;
        result  : integer;
        bkhdr  : BackupHdr;
        key  : char;
        escFlag  : boolean;
begin   Frame(2, 2, 77, 22);
        ClrScr;
        Writeln('                       *****  BACKUP UTILITY  *****');
        Writeln;
        bkhdr.diskNum := 0;
        InitBackup(BACKUP_FILE, toFile, bkhdr);
        Str(TodaysDate.year, YearStr);

        Writeln('Backing up Fuel Inventory data...');
        FullPath := DATA_PATH+YearStr+'fim.'+SERIAL_NUMBER+'\';
        BackupFile(FullPath+'log.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'tr.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'mmp.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'price.dat', toFile, bkhdr, BACKUP_FILE);

        Writeln('Backing up Income Account data...');
        FullPath := DATA_PATH+YearStr+'ia.'+SERIAL_NUMBER+'\';
        BackupFile(FullPath+'log.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'data.dat', toFile, bkhdr, BACKUP_FILE);

        Writeln('Backing up Accounts Payable...');
        FullPath := DATA_PATH+YearStr+'ap.'+SERIAL_NUMBER+'\';
        result := SetSearch(h, FullPath+'acc????.dat', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            BackupFile(FullPath+fileName, toFile, bkhdr, BACKUP_FILE);
        end (* while *);

        Writeln('Backing up Accounts Receivable...');
        FullPath := DATA_PATH+YearStr+'ar.'+SERIAL_NUMBER+'\';
        result := SetSearch(h, FullPath+'acc????.dat', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            BackupFile(FullPath+fileName, toFile, bkhdr, BACKUP_FILE);
        end (* while *);

        Writeln('Backing up Daily Report data...');
        FullPath := DATA_PATH+YearStr+'dr.'+SERIAL_NUMBER+'\';
        BackupFile(FullPath+'log.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'data.dat', toFile, bkhdr, BACKUP_FILE);

        Writeln('Backing up Mailing Label data...');
        FullPath := DATA_PATH+YearStr+'ml.'+SERIAL_NUMBER+'\';
        BackupFile(FullPath+'apaddr.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'araddr.dat', toFile, bkhdr, BACKUP_FILE);
        BackupFile(FullPath+'miscaddr.dat', toFile, bkhdr, BACKUP_FILE);

        Close(toFile);
        Writeln;
        Writeln('Done.  Press any key...');
        ReadKbd(key, escFlag);
        ChangeWindow(MainMenu);
end (* Backup *);

procedure InitRestore(restoreName  : LongStr;
        var fromFile  : file; var bkhdr  : BackupHdr);
var     YearStr  : ShortStr;
        key  : char;
        escFlag  : boolean;
        oldbkhdr  : BackupHdr;
        errnum  : integer;
begin   bkhdr.diskNum := bkhdr.diskNum+1;
        if (bkhdr.diskNum > 1) then
            close(fromFile);
        Str(bkhdr.date.year, YearStr);
        repeat
            Writeln;
            Writeln('Please insert backup disk ', bkhdr.diskNum, ' for ',
                YearStr, ' in drive A.');
            Writeln('Press any key to continue...'+^G);
            Writeln;
            ReadKbd(key, escFlag);
            errnum := IOResult;
            Assign(fromFile, restoreName);
            Reset(fromFile, 1);
            errnum := IOResult;
            while (errnum <> 0) do begin
                Writeln('Error ', errnum, 'opening backup file!  ',
                    'Please be sure correct disk is in drive A:');
                Writeln('Press any key to continue...');
                ReadKbd(key, escFlag);
                if (key = KEY_ESC) then
                    Exit;
                Assign(fromFile, restoreName);
                Reset(fromFile, 1);
            end (* while *);
            oldbkhdr := bkhdr;
            BlockRead(fromFile, bkhdr, SizeOf(bkhdr));
            if (bkhdr.diskNum = 1) then
                oldbkhdr.date := bkhdr.date;
            if (oldbkhdr.diskNum <> bkhdr.diskNum) then
                Writeln('ERROR: This disk is out of sequence.');
            if (CompareDates(oldbkhdr.date, bkhdr.date) <> 0) then
                Writeln('ERROR: This disk is not from the same backup set',
                    ' as the previous one.');
        until (oldbkhdr.diskNum = bkhdr.diskNum) and
            (CompareDates(oldbkhdr.date, bkhdr.date) = 0);
end (* InitRestore *);

procedure RestoreFile(var fromFile  : file;
        var bkhdr  : BackupHdr;
        backupPath  : LongStr);
(* assumes files are already opened and positioned *)
var     toFile  : file;
        result  : integer;
        fhdr  : FileHdr;
        numBytes  : real;
begin   (* read file header *)
        BlockRead(fromFile, fhdr, SizeOf(fhdr));
        Assign(toFile, fhdr.name);
        Rewrite(toFile, 1);
        numBytes := 0.0;
        repeat
            if (fhdr.size - numBytes > BUF_SIZE) then
                BlockRead(fromFile, buffer, BUF_SIZE, result)
            else
                BlockRead(fromFile, buffer, trunc(fhdr.size - numBytes),
                    result);
            BlockWrite(toFile, buffer, result, result);
            numBytes := numBytes+result;
            Write('  ', fhdr.name, '...', numBytes:0:0, ' of ',
                fhdr.size:0:0, ' bytes restored.', ^M);
            (* check for eof on disk *)
            if eof(fromFile) and (numBytes < fhdr.size) then begin
                Writeln;
                InitRestore(backupPath, fromFile, bkhdr);
            end (* if *);
        until (numBytes >= fhdr.size);
        close(toFile);
        Writeln;
end (* RestoreFile *);

procedure Restore;
var     YearStr, fileName  : ShortStr;
        FullPath  : LongStr;
        fromFile  : file;
        h  : SearchHandle;
        diskNum, result  : integer;
        key  : char;
        escFlag  : boolean;
        bkhdr  : BackupHdr;
begin   Frame(2, 2, 77, 22);
        ClrScr;
        Writeln('                     *****  RESTORE UTILITY  *****');
        Writeln;
        bkhdr.diskNum := 0;
        bkhdr.date := TodaysDate;
        InitRestore(BACKUP_FILE, fromFile, bkhdr);
        Writeln('Files backed up on ', ShortDate(bkhdr.date));
        if (TodaysDate.year <> bkhdr.date.year) then begin
            Writeln('NOTICE: This data is from a different year than ' +
                'the current year.');
            Writeln('You will need to change date with <D> from the main ' +
                'menu in order to view this data.');
            Writeln('Press any key to continue...');
            ReadKbd(key, escFlag);
        end (* if *);

        Str(bkhdr.date.year, YearStr);
        (* create the directories *)
        FullPath := DATA_PATH+YearStr+'fim.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);
        FullPath := DATA_PATH+YearStr+'ia.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);
        FullPath := DATA_PATH+YearStr+'ap.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);
        FullPath := DATA_PATH+YearStr+'ar.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);
        FullPath := DATA_PATH+YearStr+'dr.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);
        FullPath := DATA_PATH+YearStr+'ml.'+SERIAL_NUMBER;
        result := SetSearch(h, FullPath, $10);
        if (result <> 0) then
            MkDir(FullPath);

        Writeln('Restoring Service Station Manager data...');
        while not Eof(fromFile) do begin
            RestoreFile(fromFile, bkhdr, BACKUP_FILE);
        end (* while *);

        Close(fromFile);
        Writeln;
        Writeln('The restored files were backed up on ',
            ShortDate(bkhdr.date));
        Writeln('Done.  Press any key...');
        ReadKbd(key, escFlag);
        ChangeWindow(MainMenu);
end (* Restore *);

function IsNewYear  : boolean;
var     YearStr  : ShortStr;
        h  : SearchHandle;
        currResult, prevResult  : integer;
begin   Str(TodaysDate.year, YearStr);
        currResult := SetSearch(h,
            DATA_PATH+YearStr+'???.'+SERIAL_NUMBER, $10);
        Str(TodaysDate.year-1, YearStr);
        prevResult := SetSearch(h,
            DATA_PATH+YearStr+'???.'+SERIAL_NUMBER, $10);
        IsNewYear := (currResult <> 0) and (prevResult = 0);
end (* IsNewYear *);

procedure CreateFile(name  : LongStr);
var     newFile  : file;
begin   Assign(newFile, name);
        Rewrite(newFile);
        Close(newFile);
end (* CreateFile *);

procedure CopyAcctFile(fromFile, toFile  : LongStr);
type    AcctRec  = record
            number  : integer;
            name  : string[40];
            address  : string[40];
            city  : string[30];
            phone  : string[15];
            balance   : real;
            gt30   : real;
            gt60   : real;
        end (* AcctRec *);

        TransRec  = record
            date   : DateRec;
            description   : string[40];
            amount   : real;
            balance   : real;
        end (* TransRec *);

const   FIRST_VALID_ENTRY  = 3;
var     acct  : AcctRec;
        acctFile  : file of AcctRec;
        trans  : TransRec;
        transFile  : file of TransRec;
begin   Assign(acctFile, fromFile);
        Reset(acctFile);
        Read(acctFile, acct);
        Close(acctFile);
        Assign(acctFile, toFile);
        Rewrite(acctFile);
        Write(acctFile, acct);
        Write(acctFile, acct);    (* ensure enough space in file for
           balance forward transaction *)
        Close(acctFile);
        trans.date.month := 12;
        trans.date.day := 31;
        trans.date.year := TodaysDate.year-1;
        trans.description := 'BALANCE FORWARD';
        trans.amount := acct.balance;
        trans.balance := acct.balance;
        Assign(transFile, toFile);
        Reset(transFile);
        Seek(transFile, FIRST_VALID_ENTRY);
        Write(transFile, trans);
        Truncate(transFile);
        Close(transFile);
end (* CopyAcctFile *);

procedure CopyFile(fromFileName, toFileName  : LongStr);
var     fromFile, toFile  : file;
        actRead  : integer;
begin   Assign(fromFile, fromfileName);
        Reset(fromFile, 1);
        Assign(toFile, toFileName);
        Rewrite(toFile, 1);
        repeat
            BlockRead(fromFile, buffer, BUF_SIZE, actRead);
            BlockWrite(toFile, buffer, actRead);
        until eof(fromFile);
        Close(toFile);
        Close(fromFile);
end (* CopyFile *);

procedure DeleteData(forYear  : integer);
var     fullPath  : LongStr;
        yearStr, fileName  : ShortStr;
        f  : file;
        h  : SearchHandle;
        result  : integer;
        key  : char;
        escFlag  : boolean;
begin   Str(forYear, yearStr);
        fullPath := DATA_PATH+yearStr+'fim.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        fullPath := DATA_PATH+yearStr+'ia.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        fullPath := DATA_PATH+yearStr+'ap.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        fullPath := DATA_PATH+yearStr+'ar.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        fullPath := DATA_PATH+yearStr+'dr.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        fullPath := DATA_PATH+yearStr+'ml.'+SERIAL_NUMBER;
        result := SetSearch(h, fullPath+'\????????.???', $00);
        while (result = 0) do begin
            result := NextFile(h, fileName);
            Write('Deleting ', fullPath, '\', fileName, '...');
            Assign(f, fullPath+'\'+fileName);
            Erase(f);
            Writeln('done.');
        end (* while *);
        if (result <> 3) then    (* 3 = Path not found *)
            RmDir(fullPath);
        Writeln('Completed removing old data files.');
        Writeln('Press any key to continue...');
        ReadKbd(key, escFlag);
end (* DeleteData *);

procedure NewYear;
var     key  : char;
        escFlag  : boolean;
        h  : SearchHandle;
        NewPath, OldPath  : LongStr;
        NewYearStr, OldYearStr, fileName  : ShortStr;
        result  : integer;
begin   Frame(2, 2, 77, 22);
        ClrScr;
        Writeln('                     *****  NEW YEAR UTILITY  *****');
        Writeln;
        Writeln('New data files must be created for ', TodaysDate.Year, '.');
        Writeln('Do you want to create the new data files now? (Y/N)');
        ReadKbd(key, escFlag);
        if (key <> 'y') and (key <> 'Y') then begin
            ChangeWindow(MainMenu);
            Exit;
        end (* if *);
        Writeln('If you haven`t made a final backup of ', TodaysDate.Year-1,
            ' data files, you should do that now.');
        Writeln('Make final backup of ', TodaysDate.year-1, ' files? (Y/N)');
        ReadKbd(key, escFlag);
        if (key = 'y') or (key = 'Y') then begin
           TodaysDate.year := TodaysDate.year-1;
           Backup;
           TodaysDate.year := TodaysDate.year+1;
           Frame(2, 2, 77, 22);
           ClrScr;
           Writeln('                     *****  NEW YEAR UTILITY  *****');
        end (* if *);
        Writeln;

        Str(TodaysDate.year, NewYearStr);
        Str(TodaysDate.year-1, OldYearStr);
        Write('Creating Fuel Inventory Manager data files...');
        NewPath := DATA_PATH+NewYearStr+'fim.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        CreateFile(NewPath+'\log.dat');
        CreateFile(NewPath+'\tr.dat');
        CreateFile(NewPath+'\mmp.dat');
        CreateFile(NewPath+'\price.dat');
        Writeln('done.');

        Write('Creating Income Account data files...');
        NewPath := DATA_PATH+NewYearStr+'ia.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        CreateFile(NewPath+'\log.dat');
        CreateFile(NewPath+'\data.dat');
        Writeln('done.');

        Writeln('Creating Accounts Payable data files...');
        NewPath := DATA_PATH+NewYearStr+'ap.'+SERIAL_NUMBER;
        OldPath := DATA_PATH+OldYearStr+'ap.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        Writeln('Transferring Accounts Payable information...');
        result := SetSearch(h, OldPath+'\acc????.dat', $00);
        while  (result = 0) do begin
            result := NextFile(h, fileName);
            Writeln('  Copying ', fileName, '...');
            CopyAcctFile(OldPath+'\'+fileName, NewPath+'\'+fileName);
        end (* while *);
        Writeln('done.');

        Writeln('Creating Accounts Receivable data files...');
        NewPath := DATA_PATH+NewYearStr+'ar.'+SERIAL_NUMBER;
        OldPath := DATA_PATH+OldYearStr+'ar.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        Writeln('Transferring Accounts Receivable information...');
        result := SetSearch(h, OldPath+'\acc????.dat', $00);
        while  (result = 0) do begin
            result := NextFile(h, fileName);
            Writeln('  Copying ', fileName, '...');
            CopyAcctFile(OldPath+'\'+fileName, NewPath+'\'+fileName);
        end (* while *);
        Writeln('done.');

        Write('Creating Daily Report data files...');
        NewPath := DATA_PATH+NewYearStr+'dr.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        CreateFile(NewPath+'\log.dat');
        CreateFile(NewPath+'\data.dat');
        Writeln('done');

        Writeln('Creating Mailing Label data files...');
        NewPath := DATA_PATH+NewYearStr+'ml.'+SERIAL_NUMBER;
        OldPath := DATA_PATH+OldYearStr+'ar.'+SERIAL_NUMBER;
        result := SetSearch(h, NewPath, $10);
        if (result <> 0) then
            MkDir(NewPath);
        Writeln('Transferring Mailing Label data...');
        result := SetSearch(h, OldPath+'\acc????.dat', $00);
        while  (result = 0) do begin
            result := NextFile(h, fileName);
            Writeln('  Copying ', fileName, '...');
            CopyFile(OldPath+'\'+fileName, NewPath+'\'+fileName);
        end (* while *);
        Writeln('done.');

        Writeln;
        Writeln('Finished creating ', TodaysDate.year, ' data files.');
        Writeln('If ', TodaysDate.year-1, ' data has been backed up, it ',
            'may be deleted now');
        Writeln('Delete ', TodaysDate.year-1, ' data now? (Y/N)');
        ReadKbd(key, escFlag);
        if (key = 'y') or (key = 'Y') then
            DeleteData(TodaysDate.year-1);
        Writeln('Press any key to continue...');
        ReadKbd(key, escFlag);
        ChangeWindow(MainMenu);
end (* NewYear *);

procedure CheckForOldData;
var     h  : SearchHandle;
        result, year, next  : integer;
        subdirName  : ShortStr;
        key  : char;
        escFlag  : boolean;
begin   result := SetSearch(h, DATA_PATH+'????????.'+SERIAL_NUMBER, $10);
        while (result = 0) do begin
            result := NextFile(h, subdirName);
            Val(subdirName, year, next);
            if (year < TodaysDate.year) then begin
                Frame(4, 8, 75, 18);
                ClrScr;
                Writeln('Data from ', year, ' was found on the hard drive.');
                Writeln('If this data has been backed up, it can be deleted ',
                    'to save disk space.');
                Writeln('Delete ', year, ' data now? (Y/N)');
                ReadKbd(key, escFlag);
                if (key = 'y') or (key = 'Y') then begin
                    DeleteData(year);
                    result :=
                        SetSearch(h,
                            DATA_PATH+'????????.'+SERIAL_NUMBER, $10);
                end else
                    result := 1;
            end (* if *);
        end (* while *);
        ChangeWindow(MainMenu);
end (* CheckForOldData *);
