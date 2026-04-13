procedure CheckKeyFile;
begin   result := SetSearch(h, PROGRAM_PATH+'KEYFILE.DAT', $0);
        if (result = 0) then begin
            Assign(keyFile, PROGRAM_PATH+'KEYFILE.DAT');
            Reset(keyFile);
            keyFilePresent := true;
        end else
            keyFilePresent := false;
end (* CheckKeyFile *);

