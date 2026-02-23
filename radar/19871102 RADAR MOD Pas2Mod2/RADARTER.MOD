MODULE RadarTerminal;

IMPORT Control;
IMPORT Map;
IMPORT Modem;
IMPORT Picture;
IMPORT ScreenHandler;

PROCEDURE Interactive;
BEGIN
  Modem.Call(*PhoneNum*);
  IF Modem.Result=Modem.connect2400 THEN
    Control.CurrParam(AParam);
    Control.GetParam;
    ScreenHandler.WriteParam;
  END; (* IF *)
END Interactive;

END RadarTerminal.
