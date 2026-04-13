Program TransferAccounts;

Type
  RegisterType  = RECORD
    CASE INTEGER of
      1 : (AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : INTEGER);
      2 : (AL,AH,BL,BH,CL,CH,DL,DH : BYTE);
              END;

  LineType      = string[80];

VAR
  Registers     : RegisterType;
  DTA           : ARRAY[0..127] of BYTE;
  Mask          : LineType;
  Option        : INTEGER;
  ErrorFlag     : boolean;
  ErrorNumber   : Integer;

PROCEDURE SetDTA(VAR DTA);

  BEGIN
    WITH Registers DO BEGIN
      AH:= $1A;
      DS:= Seg(DTA);
      DX:= Ofs(DTA);
      MSDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


PROCEDURE SetDir(OptionSelect : INTEGER);

  BEGIN
    Option:=OptionSelect;
    WITH Registers DO BEGIN
      AH:= $4E;
      DS:= Seg(Mask);
      DX:= Ofs(Mask)+1;
      CX:= Option;
      MsDos(Registers);
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;


FUNCTION DirEntry : LineType;

  VAR
    Line : LineType;
    I    : Integer;
  BEGIN
    Line:=''; I:=29;
    REPEAT
      Line:=Line+Chr(DTA[I]);
      I:=I+1;
    UNTIL DTA[I]=0;
    DirEntry:=Line;
    WITH Registers DO BEGIN
      AH:= $4F;
      CX:= Option;
      MSDos( Registers );
      ErrorFlag:=(Flags AND $01)<>0;
      IF ErrorFlag THEN ErrorNumber:= AL;
    END;
  END;

Type
  AccountRec     = record
    Number       :   integer;
    Name         :   string[40];
    Address      :   string[40];
    City         :   string[30];
    Phone        :   string[15];
    Balance      :   real;
    GT30         :   real;
    GT60         :   real;
  end;

Var
  Account     : AccountRec;
  AccountFile : File of AccountRec;
  Line        : LineType;

Begin
  SetDTA(DTA);
  Mask:='ACC????.DAT'+#0;
  SetDir($00);
  While Not ErrorFlag do begin
    Line := DirEntry;
    Line:=Copy(Line,2,255);
    WriteLn('EMPTYING FILE : ',Line);
    Assign(AccountFile,Line);
    ReSet(AccountFile);
    Read(AccountFile,Account);
    Close(AccountFile);
    ReWrite(AccountFile);
    Account.Balance:=0.0;
    Account.GT30:=0.0;
    Account.GT60:=0.0;
    Write(AccountFile,Account);
    Close(AccountFile);
  End;
End.