%% ============================================================================
%% radar_lts_19880519.pl  --  Labeled Transition System for the
%%                            Modula-2 port (continuation of the
%%                            19871102 transition lineage).
%%                            (1988-05-19 "RADAR MOD Rad1dot1",
%%                             banner: "MODULE E300RadarTerm  Title: Ellason
%%                             300 Radar Terminal  Version: 1.0
%%                             Author: Derek Lane  System: Logitech
%%                             Modula-2/86")
%% ============================================================================
%%
%% Source program:  radar/19880519 RADAR MOD Rad1dot1/RADAR.MOD
%%                  + DEF/MOD pairs for: Modem, RS232, Storage, Screen,
%%                    Environment.
%% Companion files: radar/radar_lts_1985.pl
%%                  radar/radar_lts_19870412.pl
%%                  radar/radar_lts_19870416.pl
%%                  radar/radar_lts_19870512_radiorx.pl
%%                  radar/radar_lts_19871102.pl   (Modula-2 transition stub)
%%                  radar/radar_lts_19880114.pl
%%                  radar/radar_lts_19880226.pl
%%
%% This is the second Modula-2 LTS in the lineage and the first that
%% models a *substantively wired-up* port.  The module surface is much
%% smaller than the November 1987 transition snapshot and the wiring is
%% considerably more complete.
%%
%% Key architectural facts (from the .DEF files):
%%
%%   * RS232.ModeType       = (Modem, Online, RxPic)            -- 3 modes
%%       (no separate WaitPic; no RxGraph; the picture-receive ISR flips
%%        directly from Online to RxPic when a sync header arrives.)
%%   * Modem.ResultType     = (Connect300, Connect1200, Connect2400,
%%                             NoCarrier, Error, NoDialTone, Busy,
%%                             NoAnswer)
%%   * Modem.StateType      = (Offline, Online, NoResponse)
%%   * Storage.ParamType    = RECORD Tilt, Range, Gain, Hour, Minute END
%%   * Storage.PicBuf       : ARRAY[1..40000] OF BYTE   -- single picture
%%                            (no library, no MaxPic/CurrPic indexing)
%%   * Storage.PhoneNum     : ARRAY[1..50] OF CHAR
%%   * RS232 command consts : TiltUp/Down, RangeUp/Down, GainUp/Down,
%%                            SendPic, CheckMap, SendMap, SendParam
%%       (CheckMap and SendMap are defined but never invoked; map auto-
%%        refresh is not yet wired up in this snapshot.)
%%
%% RADAR.MOD's top-level structure (lines 147-160):
%%
%%   Initialize all subsystems;
%%   Storage.SelectStation;            (* may dial as a side effect *)
%%   IF Modem.Connected THEN Online;
%%   Offline;                          (* main loop, never returns *)
%%
%% Where:
%%   Offline  -- F1 = Storage.SelectStation (may dial); F2 = Modem.Call;
%%               either may transition to Online.  AuxCommand processes
%%               G/R/1/2/H toggles.
%%   Online   -- F1-F6 = RS232.SendCom + conditional Storage.CurrParams
%%               update on RS232.Response; F7 = ReceivePicture; ESC ->
%%               Ask('DISCONNECT STATION') -> Modem.HangUp + EXIT.
%%               Auto-EXIT if RS232.Mode flips to Modem (carrier dropped).
%%   AuxCommand -- G = ToggleGraphics, R = ToggleRangeMarks,
%%                 1/2 = ToggleMap1/2, H = ToggleHelp.  Available in
%%                 both modes.
%%   ReceivePicture -- SendPic; if Response then "WAITING FOR PICTURE",
%%                     DrawScale, ADR(Storage.PicBuf), and if RS232 has
%%                     transitioned to RxPic mode, DecompPic.  Returns
%%                     to Online.
%%
%% Notable departures from the Pascal v2.x main line:
%%
%%   1. Mode set is reduced.  No WaitPic; no RxGraph.
%%   2. No picture library.  Storage holds one PicBuf and one CurrParams.
%%   3. No map auto-refresh.  CheckMap/SendMap exist but are unused.
%%   4. No autosave.  Pictures live in memory until overwritten.
%%   5. No update_params from radar.  Parameters change only as local
%%      consequences of user F1-F6 keystrokes (gated by RS232.Response).
%%   6. No no-phone fallback.  Modem.Call requires a non-empty PhoneNum
%%      (caller passes Storage.PhoneNum directly).
%%   7. SOURCE BUG -- F6 in Online (RADAR.MOD line 103) sets
%%      Storage.CurrParams.Gain := Storage.CurrParams.Gain + 1
%%      where it should be -1.  This LTS faithfully reproduces the bug;
%%      a `send_gain_dn` action in 19880519 increments Gain (same as
%%      `send_gain_up`) and is therefore enabled only when Gain < 17.
%%
%% State shape (six-tuple) and predicate signatures (initial_state/1,
%% action/1, guard/2, step/3, trans/3, run/3, reachable/1-2) match the
%% other date-stamped LTSes for compositional consistency.  Mode atoms
%% wait_pic and rx_graph remain defined for vocabulary continuity but
%% are unreachable in this snapshot.
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_19880519, [
        initial_state/1,
        guard/2,
        step/3,
        trans/3,
        run/3,
        action/1,
        reachable/1,
        reachable/2
    ]).


%% ----------------------------------------------------------------------------
%% Domains
%% ----------------------------------------------------------------------------

mode(modem).            %% "top-level" -- Modula-2 source has no explicit
                        %% Mode global; this represents the outer LOOP in
                        %% RadarVersion2point0 (RADAR.MOD lines 96-132).
mode(interactive).      %% inside the Interact procedure (lines 36-91)
mode(wait_pic).         %% reserved, not wired up in this snapshot
mode(rx_pic).           %% reserved, not wired up in this snapshot
mode(rx_graph).         %% reserved (no map mode in this snapshot)

%% Naming: RS232.ModeType is (Modem, Online, RxPic).  For cross-LTS
%% compositional comparison we keep the prior naming convention --
%% `interactive` here corresponds to the source's `Online` mode.

range_index(I) :- between(0, 4, I).
tilt_index(I)  :- between(0, 11, I).
gain_index(I)  :- between(1, 17, I).
rt_state(0). rt_state(1). rt_state(2).

%% Modem.ResultType  (MODEM.DEF lines 7-14).  Note this is a tighter
%% set than the November 1987 transition (no Ring, no Ok, no
%% NoResponse here -- NoResponse moved to Modem.StateType in this
%% snapshot).  The token spelling Modem.Error remains shortened
%% to `modem_error` for cross-LTS consistency.
dial_outcome(connect300).
dial_outcome(connect1200).
dial_outcome(connect2400).
dial_outcome(no_carrier).
dial_outcome(modem_error).
dial_outcome(no_dialtone).
dial_outcome(busy).
dial_outcome(no_answer).

dial_success(connect300).
dial_success(connect1200).
dial_success(connect2400).


%% ----------------------------------------------------------------------------
%% The Application State  (six-tuple, identical shape to 19870412/19870416)
%%
%%   state(Mode, Params, Flags, Station, Reception, Library)
%%
%%   Params     = params(StationId, time(H,M), Range, Tilt, Gain, Rt)
%%   Flags      = flags(GraphicsOn, HelpOn, Gfx1On, Gfx2On, RngMksOn)
%%   Station    = station(Name, Phone, Loaded)
%%   Reception  = reception(LineAt, WriteAt, PicSaveAt, MapCount, Response)
%%   Library    = library(CurrPic, MaxPic, PictureSaved, GfxMatch)
%%
%% In this snapshot the Reception and Library tuples are present for shape
%% compatibility but are never updated.  Storage holds one CurrParams
%% (modelled in Params) and one PicBuf (not modelled at the LTS level --
%% there is no library/index).
%%
%% State terms are immutable; every step builds a fresh term.
%% ----------------------------------------------------------------------------

%% initial_state/1: top-level just before the main LOOP in RADAR.MOD.
%% Initialize is implicit (SetHiRes, font setup, banner).  Defaults match
%% the prior snapshots so traces compose cleanly.
initial_state(state(
        modem,
        params(0, time(0,0), 3, 0, 1, 0),
        flags(true, false, false, false, false),
        station('', '', false),
        reception(-20001, -20000, -20000, 0, false),
        library(0, 0, false, true))).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates  (identical to 19870412/19870416)
%% ----------------------------------------------------------------------------

st_mode(state(M,_,_,_,_,_),       M).
st_params(state(_,P,_,_,_,_),     P).
st_flags(state(_,_,F,_,_,_),      F).
st_station(state(_,_,_,S,_,_),    S).
st_reception(state(_,_,_,_,R,_),  R).
st_library(state(_,_,_,_,_,L),    L).

set_mode(state(_,P,F,S,R,L),       M, state(M,P,F,S,R,L)).
set_params(state(M,_,F,S,R,L),     P, state(M,P,F,S,R,L)).
set_flags(state(M,P,_,S,R,L),      F, state(M,P,F,S,R,L)).
set_station(state(M,P,F,_,R,L),    S, state(M,P,F,S,R,L)).
set_reception(state(M,P,F,S,_,L),  R, state(M,P,F,S,R,L)).
set_library(state(M,P,F,S,R,_),    L, state(M,P,F,S,R,L)).

param_field(range, params(_,_,V,_,_,_), V).
param_field(tilt,  params(_,_,_,V,_,_), V).
param_field(gain,  params(_,_,_,_,V,_), V).
param_field(rt,    params(_,_,_,_,_,V), V).

set_param_field(range, params(St,Tm,_,T,G,Rt), V, params(St,Tm,V,T,G,Rt)).
set_param_field(tilt,  params(St,Tm,R,_,G,Rt), V, params(St,Tm,R,V,G,Rt)).
set_param_field(gain,  params(St,Tm,R,T,_,Rt), V, params(St,Tm,R,T,V,Rt)).
set_param_field(rt,    params(St,Tm,R,T,G,_),  V, params(St,Tm,R,T,G,V)).

valid_param(range, V) :- range_index(V).
valid_param(tilt,  V) :- tilt_index(V).
valid_param(gain,  V) :- gain_index(V).
valid_param(rt,    V) :- rt_state(V).

not_b(true, false).
not_b(false, true).

flag_field(graphics_on, flags(V,_,_,_,_), V).
flag_field(help_on,     flags(_,V,_,_,_), V).
flag_field(gfx1_on,     flags(_,_,V,_,_), V).
flag_field(gfx2_on,     flags(_,_,_,V,_), V).
flag_field(rng_mks_on,  flags(_,_,_,_,V), V).

set_flag_field(graphics_on, flags(_,B,C,D,E), V, flags(V,B,C,D,E)).
set_flag_field(help_on,     flags(A,_,C,D,E), V, flags(A,V,C,D,E)).
set_flag_field(gfx1_on,     flags(A,B,_,D,E), V, flags(A,B,V,D,E)).
set_flag_field(gfx2_on,     flags(A,B,C,_,E), V, flags(A,B,C,V,E)).
set_flag_field(rng_mks_on,  flags(A,B,C,D,_), V, flags(A,B,C,D,V)).


%% ----------------------------------------------------------------------------
%% Action vocabulary
%% ----------------------------------------------------------------------------

%% --- Inherited (same labels and intent) -----------------------------------
action(call_station).            %% F2 in Offline: Modem.Call(Storage.PhoneNum)
                                 %% returns Connect2400 (or 1200/300)
action(dial_failure(_Outcome)).  %% Modem.Call returns non-success ResultType
action(hang_up).                 %% Online: Esc + Ask('DISCONNECT STATION')
                                 %% -> Modem.HangUp + EXIT
action(line_disconnect).         %% Online: RS232.Mode flips to Modem (carrier
                                 %% dropped) -> EXIT (RADAR.MOD line 115)
action(send_tilt_up).            %% F1 in Online: SendCom(TiltUp); CurrParams
                                 %% updated only if RS232.Response
action(send_tilt_dn).            %% F2 in Online: SendCom(TiltDown)
action(send_range_up).           %% F3 in Online: SendCom(RangeUp)+WriteScreen
action(send_range_dn).           %% F4 in Online: SendCom(RangeDown)+WriteScreen
action(send_gain_up).            %% F5 in Online: SendCom(GainUp)
action(send_gain_dn).            %% F6 in Online: SendCom(GainDown)
                                 %% *** SOURCE BUG: Gain := Gain + 1 ***
                                 %% (RADAR.MOD line 103; mirrors send_gain_up)
action(request_pic).             %% F7 in Online: ReceivePicture issues
                                 %% RS232.SendCom(SendPic) and waits for
                                 %% RS232.Mode to flip to RxPic.
action(begin_rx_pic).            %% RS232 ISR detects sync -> Mode := RxPic
action(complete_pic).            %% Screen.DecompPic finishes -> back to Online
action(abort_pic).               %% (Not exposed in source; included for LTS
                                 %% compositional symmetry with Pascal LTSes.)
action(toggle_graphics).         %% AuxCommand 'G': Screen.ToggleGraphics
action(toggle_help).             %% AuxCommand 'H': ToggleHelp (real body now,
                                 %% writes hotkey legend per current mode)
action(toggle_rng_mks).          %% AuxCommand 'R': Screen.ToggleRangeMarks
action(toggle_gfx1).             %% AuxCommand '1': Screen.ToggleMap1
action(toggle_gfx2).             %% AuxCommand '2': Screen.ToggleMap2

%% --- New / re-shaped in 19880519 ------------------------------------------
action(load_station(_Name)).        %% Models the station-info side effect of
                                    %% Storage.SelectStation: PhoneNum and
                                    %% CurrParams populate from station data.
action(select_station_no_connect).  %% Storage.SelectStation completes without
                                    %% triggering a dial -- stays in Modem.
action(select_station_connect).     %% Storage.SelectStation dials internally
                                    %% and reaches Online.


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

%% Modem.Call(Storage.PhoneNum) requires a non-empty phone number.  Caller
%% in RADAR.MOD line 136 passes Storage.PhoneNum directly, so we gate on
%% the station's Phone field.
guard(call_station, S) :-
    st_mode(S, modem),
    st_station(S, station(_, Phone, _)),
    Phone \== ''.

guard(dial_failure(O), S) :-
    st_mode(S, modem),
    st_station(S, station(_, Phone, _)),
    Phone \== '',
    dial_outcome(O),
    \+ dial_success(O).

%% load_station(Name) records that the user picked a station and its
%% PhoneNum was loaded from disk; this is a precondition for call_station.
guard(load_station(Name), S) :-
    st_mode(S, modem),
    atom(Name), Name \== ''.

%% Storage.SelectStation pops up a station list and may dial as a side
%% effect (Storage.DEF: "if one is selected, dials it").  Both outcomes
%% leave us in either modem or interactive depending on whether dial
%% succeeded.
guard(select_station_no_connect, S) :- st_mode(S, modem).
guard(select_station_connect, S)    :-
    st_mode(S, modem),
    st_station(S, station(_, Phone, _)),
    Phone \== ''.

%% Online's only intentional break: Esc + Ask('DISCONNECT STATION') ->
%% Modem.HangUp + EXIT (RADAR.MOD lines 107-110).
guard(hang_up, S) :-
    st_mode(S, interactive).

%% RS232 ISR detects carrier loss -> Mode := Modem; Online's loop body
%% checks `IF RS232.Mode(RS232.Modem) THEN EXIT;` (line 115).
guard(line_disconnect, S) :-
    st_mode(S, M), member(M, [interactive, rx_pic]).

%% Parameter-bump guards.  The radar acknowledges with RS232.Response
%% before CurrParams is updated; we model the success path only.  Note
%% the gain bug below.
guard(send_tilt_up, S)  :- interactive_with(S, tilt,  V), V < 11.
guard(send_tilt_dn, S)  :- interactive_with(S, tilt,  V), V >  0.
guard(send_range_up, S) :- interactive_with(S, range, V), V <  4.
guard(send_range_dn, S) :- interactive_with(S, range, V), V >  0.
guard(send_gain_up, S)  :- interactive_with(S, gain,  V), V < 17.
%% SOURCE BUG: F6 in Online (RADAR.MOD line 103) writes Gain := Gain + 1.
%% So `send_gain_dn` actually *increments* gain in Rad1dot1 -- enabled
%% only when Gain < 17.  The intended `Gain - 1` semantics are absent.
guard(send_gain_dn, S)  :- interactive_with(S, gain,  V), V < 17.

guard(request_pic, S)   :- st_mode(S, interactive).
guard(begin_rx_pic, S)  :- st_mode(S, interactive).
guard(complete_pic, S)  :- st_mode(S, rx_pic).
guard(abort_pic, S)     :- st_mode(S, rx_pic).

%% AuxCommand toggles are accepted in Modem and Online and (per the
%% source) also in RxPic since the keypress dispatch isn't gated by
%% mode in RADAR.MOD's Online/Offline loops.  ReceivePicture itself
%% has no key handler, so during RxPic the toggles aren't consumable
%% in practice -- but we keep the LTS open here.
guard(toggle_graphics, S) :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_help, S)     :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_rng_mks, S)  :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_gfx1, S)     :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_gfx2, S)     :- st_mode(S, M), member(M, [modem, interactive]).

%% Helpers ------------------------------------------------------------------
interactive_with(S, F, V) :-
    st_mode(S, interactive),
    st_params(S, P),
    param_field(F, P, V).


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(call_station, S0, S1) :-
    set_mode(S0, interactive, S1).

step(dial_failure(_), S0, S1) :-
    set_mode(S0, modem, S1).

step(load_station(Name), S0, S1) :-
    %% Approximate: assume a non-empty phone is loaded with the station;
    %% the LTS doesn't model the on-disk PHONENUM.TXT format.
    set_station(S0, station(Name, '5555555', true), S1).

step(select_station_no_connect, S, S).

step(select_station_connect, S0, S1) :-
    set_mode(S0, interactive, S1).

step(hang_up, S0, S1) :-
    set_mode(S0, modem, S1).

step(line_disconnect, S0, S1) :-
    set_mode(S0, modem, S1).

step(send_tilt_up,  S0, S1) :- bump_param(tilt,  +1, S0, S1).
step(send_tilt_dn,  S0, S1) :- bump_param(tilt,  -1, S0, S1).
step(send_range_up, S0, S1) :- bump_param(range, +1, S0, S1).
step(send_range_dn, S0, S1) :- bump_param(range, -1, S0, S1).
step(send_gain_up,  S0, S1) :- bump_param(gain,  +1, S0, S1).
%% SOURCE BUG: send_gain_dn increments gain (mirrors send_gain_up).
step(send_gain_dn,  S0, S1) :- bump_param(gain,  +1, S0, S1).

step(request_pic, S, S).             %% SendPic issued; mode still online
                                     %% until ISR flips it
step(begin_rx_pic, S0, S1) :-
    set_mode(S0, rx_pic, S1).

step(complete_pic, S0, S1) :-
    set_mode(S0, interactive, S1).   %% return to Online (no autosave,
                                     %% no autohangup -- this differs
                                     %% from Pascal v2.1)
step(abort_pic, S0, S1) :-
    set_mode(S0, interactive, S1).

step(toggle_graphics, S0, S1) :- flip_flag(graphics_on, S0, S1).
step(toggle_help,     S0, S1) :- flip_flag(help_on,     S0, S1).
step(toggle_rng_mks,  S0, S1) :- flip_flag(rng_mks_on,  S0, S1).
step(toggle_gfx1,     S0, S1) :- flip_flag(gfx1_on,     S0, S1).
step(toggle_gfx2,     S0, S1) :- flip_flag(gfx2_on,     S0, S1).

%% Helpers ------------------------------------------------------------------

bump_param(Field, Delta, S0, S1) :-
    st_params(S0, P0),
    param_field(Field, P0, V0),
    V1 is V0 + Delta,
    valid_param(Field, V1),
    set_param_field(Field, P0, V1, P1),
    set_params(S0, P1, S1).

flip_flag(Name, S0, S1) :-
    st_flags(S0, F0),
    flag_field(Name, F0, V0),
    not_b(V0, V1),
    set_flag_field(Name, F0, V1, F1),
    set_flags(S0, F1, S1).


%% ----------------------------------------------------------------------------
%% Labeled transition relation + traces
%% ----------------------------------------------------------------------------

trans(Action, S0, S1) :-
    guard(Action, S0),
    step(Action, S0, S1).

run([],        S, S).
run([A | As],  S0, S2) :-
    trans(A, S0, S1),
    run(As, S1, S2).

reachable(S) :-
    initial_state(S0),
    reachable(S0, S).

reachable(S, S).
reachable(S0, S) :-
    trans(_, S0, S1),
    S1 \== S0,
    reachable(S1, S).


%% ----------------------------------------------------------------------------
%% Example queries
%%
%%   %% Dial in, request a picture, ISR completes, decompression done.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station,
%%            request_pic, begin_rx_pic, complete_pic ], S0, S),
%%      st_mode(S, M).
%%   M = interactive.
%%
%%   %% Modem.NoCarrier keeps us at modem mode.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            dial_failure(no_carrier) ], S0, S),
%%      st_mode(S, M).
%%   M = modem.
%%
%%   %% Carrier loss mid-session forces an EXIT from Online.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station,
%%            line_disconnect ], S0, S),
%%      st_mode(S, M).
%%   M = modem.
%%
%%   %% SOURCE BUG: send_gain_dn increments gain.  After ten downs, gain is
%%   %% 11 (started at 1; could only go up to 17).
%%   ?- initial_state(S0),
%%      trans(load_station('WLLX'), S0, S1),
%%      trans(call_station, S1, S2),
%%      run([send_gain_dn,send_gain_dn,send_gain_dn,
%%           send_gain_dn,send_gain_dn,send_gain_dn,
%%           send_gain_dn,send_gain_dn,send_gain_dn,
%%           send_gain_dn], S2, S),
%%      st_params(S, params(_,_,_,_,G,_)).
%%   G = 11.
%% ----------------------------------------------------------------------------
