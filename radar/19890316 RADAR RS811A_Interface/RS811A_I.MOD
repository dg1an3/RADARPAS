MODULE RadarInterface;

(* CREATED : 3/14/89
 *  AUTHOR : D. Lane
 *
 * Bendix RS811A Radar Receiver/Transmitter interface.  Communicates
 * via an interface card, an ARINC 429 control bus, and an ARINC 453
 * high-speed data bus.  This module provides all functions available
 * over these busses, and all diagnostic information, also.
 *
 *)


MODULE RS811AControl;


(* ARINC 429 Control Word 1 Format:
 *
 *          BITS     FIELD      COMMENTS
 *          ==================================
 *           0 -  7  LABEL      = 270C
 *           8 - 12  RESERVED   = 0000B
 *          13 - 15  MODE       000B = Standby
 *                              001B = Weather only
 *                              010B = Map only
 *                              100B = Test
 *          16 - 22  TILT       Degrees*4
 *          23 - 28  GAIN       000000B = max, 111111B = min
 *          29 - 30  MATRIX     = 00B
 *          31       PARITY     Must be odd
 *
 *
 * ARINC 429 Control Word 2 Format:
 *
 *          BITS     FIELD      COMMENTS
 *          ==================================
 *           0 -  7  LABEL      = 271C
 *           8 -  9  RESERVED   = 00B
 *               10  MAINT REQ  Set to receive
 *                              maintenaince word (below)
 *          11 - 22  RESERVED   = 000000000000B
 *          23 - 28  RANGE      Miles/5
 *          29 - 30  MATRIX     = 00B
 *          31       PARITY     Must be odd
 *)

CONST
      ModeShift = 13;
      TiltShift = 16;
      GainShift = 23;
    ParityShift = 31;
  MaintReqShift = 10;
     RangeShift = 23;

(*                33322222222221111111111
 *           BIT# 21098765432109876543210987654321 *)
   ControlWord1 = 00000000000000000000000000011101
(*                P  GGGGGGTTTTTTTMMM     (LABEL-)
 *
 *                P = Parity bit
 *                G = Gain value
 *                T = Tilt value
 *                M = Mode
 *)

(*                33322222222221111111111
 *           BIT# 21098765432109876543210987654321 *)
   ControlWord2 = 00000000000000000000000010011101
(*                P  RRRRRR            Q  (LABEL-)
 *
 *                P = Parity bit
 *                R = Range value
 *                Q = Maintenance request
 *)


PROCEDURE ARINC429Interrupt;

(* Sends control information to RS-811A via ARINC 429 bus.
 * Called by clock timer interrupt, 18 times per second.
 *)


VAR
    ControlWord : LONGCARD;

BEGIN

  (* Adjust Mode, Tilt, Gain, and Range values *)

  ControlWord := ControlWord1 + Mode << ModeShift +
                 Tilt << TiltShift + Gain << GainShift;
  (* Set parity bit *)
  (* Send control word 1 *)

  ControlWord := ControlWord2 + Range << RangeVal +
                 CARDINAL(MaintReq) << MaintReqShift;
  MaintReq := ~ MaintReq;
  (* Set parity bit *)
  (* Send control word 2 *)

  (* Ensure data is being received via ARINC 453 *)

END ARINC429Interrupt;



(* ARINC 453 Data Word Format:
 *
 *          BITS     FIELD      COMMENTS
 *          ==================================
 *           0 -  7  LABEL      = 055C
 *           8 - 17  RESERVED   = 0000000011B
 *               18  RESERVED
 *               19  FAULT      Display fault
 *               20  FAULT      Calibration fault
 *               21  FAULT      Altitude input fault
 *               22  FAULT      Control fault
 *               23  FAULT      Antenna fault
 *               24  FAULT      R/T fault
 *               25  RESERVED   = 0B
 *          26 - 28  MODE       000B = Standby
 *                              001B = Weather only
 *                              010B = Map only
 *                              100B = Test
 *          29 - 35  TILT       Degrees*4
 *          36 - 41  GAIN       000000B = max, 111111B = min
 *          42 - 47  RANGE      Miles/5
 *          48 - 50  RESERVED   = 011B
 *          51 - 62  AZIMUTH    4096 steps per 360 degrees
 *                              (0.08789 degrees per step)
 *               63  RESERVED
 *        64 - 1599  WEATHER DATA
 *
 *
 * ARINC 453 Maintenance Word Format
 *
 *          BITS     FIELD      COMMENTS
 *          ==================================
 *           0 -  7  LABEL      = 170C
 *           8 -  9  RESERVED   = 11B
 *               10  MAINT      Elevation fault
 *               11  MAINT      400 Hz reference fault
 *               12  MAINT      Gyro input fault
 *               13  MAINT      HV fault
 *               14  MAINT      AFC fault
 *               15  MAINT      AGC fault
 *               16  MAINT      Transmitter inhibited
 *               17  MAINT      Not used
 *          18 - 21  REV CODE   0 = A, 1 = B, etc.
 *          22 - 28  400 HZ REF ANGLE
 *          29 - 35  ANT ELEV   Degrees*2 (from feedback pot in R/T)
 *          36 - 50  RESERVED   = 000000000000000B
 *          51 - 62  AZIMUTH    4096 steps per 360 degrees
 *                              (0.08789 degrees per step)
 *               63  RESERVED
 *        64 - 1599  WEATHER DATA
 *)

(* CONST
      ModeShift = 13;
      TiltShift = 16;
      GainShift = 23;
    ParityShift = 31;
  MaintReqShift = 10;
     RangeShift = 23; *)

(*             33322222222221111111111
 *        BIT# 21098765432109876543210987654321 *)
   DataWord1 = 00000000000000000000001100011101
(*             TTTMMM FFFFFFF          (LABEL-)
 *
 *                P = Parity bit
 *                G = Gain value
 *                T = Tilt value
 *                M = Mode
 *)

(*                33322222222221111111111
 *           BIT# 21098765432109876543210987654321 *)
   DataWord2 = 00000000000000000000000010011101
(*                P  RRRRRR            Q  (LABEL-)
 *
 *                P = Parity bit
 *                R = Range value
 *                Q = Maintenance request
 *)


PROCEDURE ARINC453Interrupt;

(* Receives weather and parameter data from RS-811A via ARINC
 * 453 bus.  Called when interrupted by full buffer, 64 times
 * per second. *)


BEGIN

(* Receive word - 64 bits
 * IF Label = Data word THEN
 *     Set fault flags
 *     Check mode, tilt, gain, and range
 * ELSIF Label = Maint word THEN
 *     Set maint flags
 *     Set revision code
 *     Set 400 Hz ref angle value
 *     Set ant elev value
 * Set azimuth angle
 * Receive weather data into buffer
 * IF Five minutes have elapsed since fault condition
 *     flagged, and it has not been resolved, reset RT.
 *)

END ARINC453Interrupt;


BEGIN
END RS811AControl;


BEGIN
END RadarInterface.