IMPLEMENTATION MODULE Modem; (* For E300 Radar Terminal *)

IMPORT RS232Code;
FROM RS232Code IMPORT Write;

VAR
  done        : BOOLEAN;
  Count    : CARDINAL;
  Response : CHAR;

PROCEDURE Call(PhoneNum : ARRAY OF CHAR);
VAR
  Char1,Char2 : CHAR;
BEGIN
  REPEAT
    RS232Code.BusyRead(Char1,done);
  UNTIL done=FALSE;
  Write('A'); Write('T');
  Write('T'); Write('D');
  FOR Count:=0 TO HIGH(PhoneNum) DO
    Write(PhoneNum[Count]);
  END; (* FOR *)
  Write(CHR(13));
  RS232Code.Read(Char1);
  RS232Code.Read(Char2);
  CASE Char1 OF
    '1' : 
        IF Char2='0' THEN
          Result:=Connect2400; State:=Online;
        ELSE
          Result:=Connect300;  State:=Online;
        END|
    '3' : Result:=NoCarrier;   State:=Offline|
    '4' : Result:=Error;       State:=Offline|
    '5' : Result:=Connect1200; State:=Online|
    '6' : Result:=NoDialTone;  State:=Offline|
    '7' : Result:=Busy;        State:=Offline|
    '8' : Result:=NoAnswer;    State:=Offline
    ELSE  Result:=Error;       State:=Offline;
  END; (* CASE *)
END Call;

PROCEDURE HangUp;
BEGIN
END HangUp;

BEGIN  
  RS232Code.Init(    2400,   1, FALSE, FALSE,   8, done);
                (*   BAUD STOP PARITY   EVEN DATA *)
  RS232Code.StartReading;
  Count:=0;
  LOOP
    Write('A'); Write('T'); 
    Write('&'); Write('C'); Write('1'); (* Carrier detect option 1 : 
                                           CDC follows true carrier *)
    Write('&'); Write('D'); Write('3'); (* DTR option 3 : 
                                           Modem resets with DTR *)
    Write('L');                         (* Low speaker volume *)
    Write('M'); Write('1');             (* Speaker on until carrier detect *)
    Write('E');                         (* No command echo *)
    Write('V');                         (* Short-form result codes *)
    Write('X'); Write('4');             (* Wait for dial tone, BUSY *)
    Write('&'); Write('W');             (* Store parameters in permanent mem *)
    Write(CHR(13));
    RS232Code.Read(Response);
    IF Response='0' THEN EXIT; END;
    Count:=Count+1;
    IF Count=4 THEN 
      State:=NoResponse;
      EXIT; 
    END; (* IF *)
  END; (* LOOP *)
END Modem.
