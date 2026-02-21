{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
{     Main Menu routines                                                     }
{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}


procedure WriteAccount(ForAccount : integer);
begin
    with Account[ForAccount] do begin
      GotoXY(1,ForAccount-CurrentAccount+AboveLog);
      ClrEOL;
      if (ForAccount<1) or (ForAccount>MaxAccount) then Exit;
      Write(Number:6,'   ',Name);
      GotoXY(50,WhereY);
      Write(Balance:8:2);
      if GT30>0.0 then Write(GT30:9:2) else Write('       --');
      if GT60>0.0 then Write(GT60:9:2) else Write('       --');
    end;
end;


PROCEDURE HiLiteLog;

  BEGIN
    TextColor(HiLite);TextBackground(HiLiteBack);
    WriteAccount(CurrentAccount);
    TextColor(NormVid);TextBackground(NormBack);
  END;


PROCEDURE LoLiteLog;

  BEGIN
    ClrEol;
    WriteAccount(CurrentAccount);
  END;


PROCEDURE DrawLog;

  BEGIN
    ChangeWindow(APWindow);
    Window(UXLog,UYLog,LXLog,LYLog); ClrScr;
    FOR J:=CurrentAccount-AboveLog+1 to CurrentAccount+BelowLog+1 DO
      WriteAccount(J);
    HiLiteLog;
  END;


PROCEDURE EditAccount;
VAR
  AtField : integer;
BEGIN
  DrawAccount;
  Window(1,1,80,25);
  AtField:=1;
  with Account[CurrentAccount] do
    repeat
      case AtField of
        1 : HiLiteCell(19,2,4);
        2 : HiLiteCell(4,3,40);
        3 : HiLiteCell(4,4,40);
        4 : HiLiteCell(4,5,30);
        5 : HiLiteCell(35,5,15);
      end; (* case *)
      ReadKbd;
      case AtField of
        1 : LoLiteCell(19,2,4);
        2 : LoLiteCell(4,3,40);
        3 : LoLiteCell(4,4,40);
        4 : LoLiteCell(4,5,30);
        5 : LoLiteCell(35,5,15);
      end; (* case *)
      if escape then
        case Key of
          'P' : if AtField<5 then AtField:=AtField+1;
          'H' : if AtField>1 then AtField:=AtField-1;
        end
      else
        case Key of
          ^M  : if AtField<6 then AtField:=AtField+1;
          else begin
            case AtField of
              1 : begin
                    StrA:=EnterCell(19,2,4,['0'..'9',' ']);
                    Val(StrA,Number,I);
                  end;
              2 : Name:=EnterCell(4,3,40,[' '..'~']);
              3 : Address:=EnterCell(4,4,40,[' '..'~']);
              4 : City:=EnterCell(4,5,30,[' '..'~']);
              5 : Phone:=EnterCell(35,5,15,[' '..'~']);
            end; (* case *)
            DrawAccount;
            Window(1,1,80,25);
            AtField:=AtField+1;
          end;
        end; (* case *)
    until (AtField>5) or (Key=#27);
  SaveAccount;
end; (* EditAccount *)

PROCEDURE MainMenu;
(* INSERTION 10/29/87 *)
  VAR Count : INTEGER;
      TotalBalance : REAL;
      StrT : STRING[30];
(* END INSERTION *)
  BEGIN
    FillChar(Entry,SizeOf(Entry),0);
    MaxEntry:=0;
    CurrentAccount:=1;
    DrawLog;
    Cursor(16,0);
    REPEAT
      ReadKbd;
      CASE Key of
        ';'  :  BEGIN
                  ViewAccount;
                  DrawLog;
                END;
        '<'  :  BEGIN
                  MaxAccount:=MaxAccount+1;
                  CurrentAccount:=MaxAccount;
                  with Account[CurrentAccount] do begin
                    Number:=0;
                    Name:='';
                    Address:='';
                    City:='';
                    Phone:='';
                    Balance:=0.0; GT30:=0.0; GT60:=0.0;
                  end;
                  EditAccount;
                  DrawLog;
                END;
        '='  :  BEGIN
                  EditAccount;
                  DrawLog;
                END;
        '>'  :  BEGIN
                  PrintAccount;
                  DrawLog;
                END;
(* INSERTION 10/29/87 *)
        '?'  :  BEGIN
                  TotalBalance:=0.0;
                  FOR Count:=1 TO MaxAccount DO
                    TotalBalance:=TotalBalance+Account[Count].Balance;
                  Str(TotalBalance:8:2,StrT);
                  StrT:='TOTAL BALANCE DUE: '+StrT;
                  Message(StrT);
                  Window(UXLog,UYLog,LXLog,LYLog);
                END;
(* END OF INSERTION *)
        'H'  :  IF CurrentAccount>1 THEN BEGIN
                  LoLiteLog;
                  GotoXY(1,1);
                  InsLine;
                  CurrentAccount:=CurrentAccount-1;
                  WriteAccount(CurrentAccount-AboveLog+1);
                  HiLiteLog;
                END;
        'P'  :  IF CurrentAccount<MaxAccount THEN BEGIN
                  LoLiteLog;
                  CurrentAccount:=CurrentAccount+1;
                  GotoXY(1,1);
                  DelLine;
                  WriteAccount(CurrentAccount+BelowLog+1);
                  HiLiteLog;
                END;
        'G'  :  BEGIN
                  CurrentAccount:=1;
                  DrawLog;
                END;
        'O'  :  BEGIN
                  CurrentAccount:=MaxAccount;
                  DrawLog;
                END;
        'I'  :  IF CurrentAccount-AboveLog-BelowLog>=0 THEN BEGIN
                  CurrentAccount:=CurrentAccount-AboveLog-BelowLog;
                  DrawLog;
                END;
        'Q'  :  IF CurrentAccount+AboveLog+BelowLog<=MaxAccount THEN BEGIN
                  CurrentAccount:=CurrentAccount+AboveLog+BelowLog;
                  DrawLog;
                END;
        #27  :  Exit;
      END;
    UNTIL FALSE;
  END;