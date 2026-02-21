{procedure ChangeDirectory(ToYear : INTEGER);
var     key  : char;
        escFlag  : boolean;
        yearStr  : String10;
        fullPath  : LineType;
begin   Str(ToYear, yearStr);
        GetDir(DefaultDrive, OldDir);
        fullPath := DATA_PATH+yearStr+Abbreviation+'.'+SerialNumber;
        ChDir(fullPath);
        if (IOResult = $01) then begin
            Message('No data directory.  Press <+> to create directory');
            ReadKbd(key, escFlag);
            if (key = '+') then begin
                MkDir(fullPath);
                ChDir(fullPath);
            end else
                Quit;
        end (* if *);
end (* ChangeDirectory *); }

