  MaxEntry:=MaxEntry+1;
  CurrentEntry:=MaxEntry;
  Move(Entry[CurrentEntry],TempEntry,SizeOf(EntryRec));
  DelEntry;
  J:=MaxEntry;
  while (CompareDates(Entry[J].Date,TempEntry.Date)>0) and (J>0) do
    J:=J-1;
  while (CompareDates(Entry[J].Date,TempEntry.Date)=0) and
    (Entry[J].Description>TempEntry.Description) do
    J:=J-1;
  if J<MaxEntry then
    Move(Entry[J+1],Entry[J+2],Ofs(Entry[MaxEntry+1])-Ofs(Entry[J+1]));
  CurrentEntry:=J+1; MaxEntry:=MaxEntry+1;
  Move(TempEntry,Entry[CurrentEntry],SizeOf(EntryRec));
  ReCalc;
