program Test;

type
    LineType = string[80];

const
     NumNameOnes : array[0..19] of string[10] =
              ('zero ', 'one ', 'two ', 'three ', 'four ', 'five ',
               'six ', 'seven ', 'eight ', 'nine ', 'ten ',
               'eleven ', 'twelve ', 'thirteen ', 'fourteen ', 'fifteen ',
               'sixteen ', 'seventeen ', 'eighteen ', 'nineteen ');
    NumNameTens : array[2..9] of string[10] =
              ('twenty ', 'thirty ', 'forty ', 'fifty ',
               'sixty ', 'seventy ', 'eighty ', 'ninety ');

function NumberText(ForNum : real) : LineType;
var
   Text, FracStr : LineType;
begin
     Text := '';
     if (ForNum >= 1000) then
     begin
         FracStr := NumberText(Trunc(ForNum / 1000 + 0.01));
         FracStr := Copy(FracStr, 1, Length(FracStr)-9);
         Text := FracStr + 'thousand ';
         ForNum := ForNum - (Trunc(ForNum/1000 + 0.01)*1000);
                {had to jerryrig the Trunc function}
     end;
     if (ForNum >= 100) then
     begin
         Text := Text + NumNameOnes[Trunc(ForNum/100 + 0.01)] + 'hundred ';
         ForNum := ForNum - ((Trunc(ForNum/100 + 0.01))*100);
     end;
     if (ForNum >= 20) then
     begin
         Text := Text + NumNameTens[Trunc(ForNum/10 + 0.01)];
         ForNum := ForNum - ((Trunc(ForNum/10 + 0.01))*10);
     end;

     if ((Text = '') or ((Trunc(ForNum + 0.01)) > 0)) then
        Text := Text + NumNameOnes[Trunc(ForNum + 0.01)];

     Str(Abs(-0.01+Frac(ForNum + 0.01))*100:0:0, FracStr);
                               { had to jerryrig the Frac function }
     Text := Text + 'and ' + FracStr + '/100';

    NumberText := Text;
end;

var
   count : real;
begin
     count := 0;
     while (count < 100000.0) do
     begin
         WriteLn(count:5:2, '    ', NumberText(count));
         count := count+100;
     end;
end.

