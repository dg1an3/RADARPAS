        begin
          BufPtr^[BufCount]:=port[$3F8];
          if (BufPtr^[BufCount-1]=$18) and (BufPtr^[BufCount-2]=$18) then begin
{            if CheckSum=BufPtr^[BufCount] then begin}
              Tx('A');
              Move(BufPtr^[LastCount],I,2);
              I:=I div 54;
              Move(I,BufPtr^[LastCount],2);
              if I>=352 then Mode:=Interactive;
              BufPtr^[BufCount-1]:=0;
              DispLine(BufPtr^[LastCount]);
              CheckSum:=0;
              BufCount:=BufCount-1;
              LastCount:=BufCount;
              Tx('O');
{            end else begin
              BufCount:=LastCount;
              Tx(#0);
            end;}
          end else begin
            BufCount:=BufCount+1;
            CheckSum:=CheckSum+BufPtr^[BufCount];
          end;
        end;
