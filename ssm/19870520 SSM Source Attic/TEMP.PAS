PROCEDURE SetAttribute(Name : LineType;Attribute : BYTE);

  BEGIN
    WITH Registers DO BEGIN
      AX:=$4301;
      Name:=Name+Chr(0);
      CX:=Attribute;
      DX:=Ofs(Name)+1;
      DS:=Seg(Name);
      MsDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


