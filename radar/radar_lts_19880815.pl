%% ============================================================================
%% radar_lts_19880815.pl  --  Labeled Transition System for the
%%                            Modula-2 v3.0 build (continuation of the
%%                            19871102 / 19880519 lineage).
%%                            (1988-08-15 "RADAR MOD",
%%                             banner: "ELLASON E300 RADAR TERMINAL, ver 3.0
%%                             Revision 7/20/88  Copyright (C) 1987,88
%%                             D. G. Lane")
%% ============================================================================
%%
%% Source program:  radar/19880815 RADAR MOD/MAIN.MOD
%%                  + ~50 supporting DEF/MOD pairs:
%%                    Auto, ASCII, CRC, E300Interface, ExtendKey, FIO, Graph,
%%                    Graphics, IO, Lib, Locator, MemCompress, Modem,
%%                    Pictures, RadarRx, RadarTx, RadioRx, RadioTx, rs (RS2),
%%                    ScreenHandler, Selector, Stations, Storage, Str,
%%                    SYSTEM, TimeDate, Compr, Options, Windows, ...
%% Companion files: radar/radar_lts_1985.pl
%%                  radar/radar_lts_19870412.pl
%%                  radar/radar_lts_19870416.pl
%%                  radar/radar_lts_19870512_radiorx.pl
%%                  radar/radar_lts_19871102.pl   (Modula-2 transition stub)
%%                  radar/radar_lts_19880114.pl
%%                  radar/radar_lts_19880226.pl
%%                  radar/radar_lts_19880519.pl   (Modula-2 v1.0)
%%
%% Three months after Rad1dot1.  This is the largest Modula-2 build to
%% date and the first one with a richer architectural feature set than
%% any Pascal mainline snapshot.  Highlights:
%%
%%   * MAIN.MOD declares ModeType = (Modem, Interactive, RxPic, RxGraph)
%%     -- 4 modes again, but RxGraph remains *reserved*: CheckMaps and
%%     GetMaps are commented out at MAIN.MOD lines 179-184, so the
%%     map-auto-refresh path is wired in DEF but inactive in this build.
%%
%%   * EGALib has been retired.  The Graphics module (created 6/7/88,
%%     Derek's own) plus Graph (Jensen & Partners International, third-
%%     party) replace it.  No LTS impact.
%%
%%   * E300Interface unifies the prior Control + Picture + Map modules.
%%     It exports GetParam, SetParam, MakePic, AbortPic, PicReady,
%%     GetLine, CheckMaps, GetMaps and types TiltType/RangeType/GainType
%%     /RTState.
%%
%%   * The Stations module owns a *linked list* of station records, each
%%     with PhoneNum, NumofPictures, CurrentPicture, and a Picture[]
%%     array.  Pictures are now stored *per station* rather than in a
%%     single global library.  See StationMenu, AddStation, DelStation,
%%     CallStation, SelectStation, InitStationDir.
%%
%%   * The Pictures module owns picture-record management: SavePicture,
%%     AddPicture, DeletePicture, SelectPicture, PictureMenu, FileName,
%%     ReserveMem.  PicFlag and PicFlagSet survive from the November 1987
%%     transition's Store module.
%%
%%   * NEW: Auto.ProgramMenu / Auto.DoAuto -- a background scheduler.
%%     ModemLoop calls DoAuto on every iteration, allowing the program
%%     to perform automated radar polling without user intervention.
%%
%%   * NEW: Locator.CX/CY/CursorOn -- a screen-coordinate cursor with
%%     range/bearing readout (WriteRangeBear) driven by arrow keys.
%%
%%   * The F6/GainDown bug from Rad1dot1 is FIXED: MAIN.MOD line 269
%%     correctly does DEC(Gain).
%%
%%   * RadarTx.TransmitPic exists in the .DEF/.MOD but is COMMENTED OUT
%%     at the call site (MAIN.MOD lines 500-507).  No `transmit_pic`
%%     action is exposed in this LTS.
%%
%% RADAR.MOD's top-level structure (MAIN.MOD lines 560-624):
%%
%%   GetDir + ChDir setup;
%%   rs.Install + rs.Init + AT command sequence;
%%   InitEGA, GraphMode, SetFont, SetPalette;
%%   InitStationDir(FirstStation, NumofStations);
%%   IF NumofStations = 1 THEN
%%       SelectStation(FirstStation^);   (* auto-pick when only one *)
%%   ELSE
%%       StationMenu(...);
%%   END;
%%   ModemLoop;                          (* never returns *)
%%   TextMode; ChDir(MainDir).
%%
%% Where:
%%   ModemLoop  -- F1 = StationMenu; F2 = InterLoop (if station set);
%%                 F3 = PictureMenu (if station set); F4 = ProgramMenu
%%                 (Auto module); +/- = browse pictures; arrow keys =
%%                 move locator cursor; G/R/H/L/1/2 = ExecCom toggles;
%%                 DoAuto called every iteration; ESC = exit prompt.
%%   InterLoop  -- CallStation; if false RETURN.  GetParam.  If radar
%%                 unresponsive (Tilt > MAX) -> 'No Response'; RETURN.
%%                 (CheckMaps/GetMaps would go here, but commented out.)
%%                 Main loop: F1-F6 = SetParam; F7 = MakePic, allocate
%%                 buffer, await PicReady (with optional abort), then
%%                 GetLine + ComprLine for each line, then SavePicture
%%                 + AddPicture (to current station) + INC(CurrentPicture)
%%                 + Mode := Modem (auto-disconnect).  ESC = disconnect
%%                 prompt.  G/R/H/L/1/2 toggles via ExecCom.
%%   ExecCom    -- G ToggleGraphics; R toggle range marks; H toggle help;
%%                 L toggle locator cursor; 1/2 toggle map1/map2.
%%                 Available from both ModemLoop and inside the F7
%%                 picture-receive sub-loop.
%%
%% New / re-shaped at the LTS level:
%%
%%   * station_menu, picture_menu, program_menu  -- UI sub-flows.
%%     Modelled as no-op steps; concrete state effects are reached via
%%     the parameterised actions load_station/1, select_pic_next,
%%     select_pic_prev (already in the prior Pascal LTSes).
%%   * do_auto -- background tick.  No-op at LTS level (Auto module's
%%     internal scheduler state isn't observable through MAIN.MOD).
%%   * toggle_locator -- 'L' in ExecCom.  Modelled as a no-op because
%%     CursorOn is purely a display concern; we don't extend the Flags
%%     tuple to keep it cross-LTS-comparable.
%%   * complete_pic -- now performs SavePicture + AddPicture + INC
%%     (CurrentPicture) + Mode := Modem; the LTS update increments
%%     library.curr_pic and library.max_pic, sets picture_saved := true,
%%     and returns to mode = modem (auto-disconnect).
%%   * handshake_fail -- preserved from prior LTSes.  Models the 'No
%%     Response' RETURN at MAIN.MOD lines 161-165 (plus by extension the
%%     CallStation = false RETURN at line 150).
%%   * F6 / send_gain_dn -- BUG FIXED.  Now correctly DEC(Gain), guard
%%     V > 1.
%%
%% State shape (six-tuple) and predicate signatures match the prior
%% date-stamped LTSes.  Mode atom `interactive` continues to correspond
%% to Modula-2's source token (it is identical here, since MAIN.MOD's
%% ModeType uses `Interactive` rather than the Rad1dot1 spelling
%% `Online`).
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_19880815, [
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

mode(modem).            %% MAIN.MOD top-level ModemLoop
mode(interactive).      %% inside InterLoop (after CallStation succeeds)
mode(wait_pic).         %% reserved (no separate WaitPic in MAIN.MOD's
                        %% MakePic-then-PicReady loop)
mode(rx_pic).           %% F7 picture-receive sub-loop (PicReady() = true)
mode(rx_graph).         %% reserved: CheckMaps/GetMaps commented out in
                        %% MAIN.MOD lines 179-184

%% MAIN.MOD line 85: ModeType = ( Modem, Interactive, RxPic, RxGraph ).
%% Direct one-to-one match with our atoms (lowercase).

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

%% Library accessors are needed in this snapshot since complete_pic /
%% select_pic_* now actively touch the library.  Same shape as the
%% Pascal LTSes 19870412 onwards.
lib_field(curr_pic,       library(V,_,_,_), V).
lib_field(max_pic,        library(_,V,_,_), V).
lib_field(picture_saved,  library(_,_,V,_), V).
lib_field(gfx_match,      library(_,_,_,V), V).

set_lib_field(curr_pic,      library(_,B,C,D), V, library(V,B,C,D)).
set_lib_field(max_pic,       library(A,_,C,D), V, library(A,V,C,D)).
set_lib_field(picture_saved, library(A,B,_,D), V, library(A,B,V,D)).
set_lib_field(gfx_match,     library(A,B,C,_), V, library(A,B,C,V)).


%% ----------------------------------------------------------------------------
%% Action vocabulary
%% ----------------------------------------------------------------------------

%% --- Carried over from 19880519 ------------------------------------------
action(call_station).            %% F2 in ModemLoop -> InterLoop ->
                                 %% Stations.CallStation(CurrentStation^);
                                 %% returns TRUE on Connect300/1200/2400.
action(dial_failure(_Outcome)).  %% Stations.CallStation returns FALSE.
action(handshake_fail).          %% MAIN.MOD lines 161-165: GetParam returned
                                 %% Tilt > MAX(TiltType) -> 'No Response.';
                                 %% RETURN before the InterLoop main body.
action(hang_up).                 %% InterLoop ESC + 'Disconnect Station (Y/N)?'
                                 %% confirmation -> exit InterLoop with Mode
                                 %% := Modem (HangUp itself is commented out
                                 %% at line 398).
action(line_disconnect).         %% Carrier drop detected by ISR; InterLoop
                                 %% UNTIL exit clause: ( Mode = Modem ).
action(send_tilt_up).            %% F1 in InterLoop: INC(Tilt) + SetParam
action(send_tilt_dn).            %% F2 in InterLoop: DEC(Tilt) + SetParam
action(send_range_up).           %% F3 in InterLoop: INC(Range) + SetParam
                                 %% + ClearScreen + Redraw
action(send_range_dn).           %% F4 in InterLoop: DEC(Range) + SetParam
                                 %% + ClearScreen + Redraw
action(send_gain_up).            %% F5 in InterLoop: INC(Gain) + SetParam
action(send_gain_dn).            %% F6 in InterLoop: DEC(Gain) + SetParam
                                 %% *** BUG FROM 19880519 IS FIXED HERE ***
action(request_pic).             %% F7 in InterLoop: E300Interface.MakePic
action(begin_rx_pic).            %% PicReady() returns TRUE (after MakePic
                                 %% and possibly a wait loop).
action(complete_pic).            %% Receive WHILE loop completes (Number > 476):
                                 %% SavePicture + AddPicture + INC
                                 %% (CurrentPicture) + Mode := Modem.
action(abort_pic).               %% User confirms 'Abort Picture (Y/N)?' = Y;
                                 %% AbortPic + Mode stays Interactive.
action(toggle_graphics).         %% ExecCom 'G'
action(toggle_help).             %% ExecCom 'H': WriteHelp(~HelpOn)
action(toggle_rng_mks).          %% ExecCom 'R': WriteRngMks(~RngMksOn)
action(toggle_gfx1).             %% ExecCom '1': WriteMap(1, ~MapOn[1])
action(toggle_gfx2).             %% ExecCom '2': WriteMap(2, ~MapOn[2])

%% --- New / re-shaped in 19880815 ------------------------------------------
action(load_station(_Name)).     %% StationMenu / SelectStation side effect:
                                 %% the user picks a station from the linked
                                 %% list, and CurrentStation^.PhoneNum etc.
                                 %% become available.  Modelled abstractly.
action(station_menu).            %% F1 in ModemLoop: Stations.StationMenu UI.
                                 %% No-op at LTS level; concrete selections
                                 %% are reached via load_station/1.
action(picture_menu).            %% F3 in ModemLoop: Pictures.PictureMenu UI.
                                 %% No-op; selections via select_pic_*.
action(program_menu).            %% F4 in ModemLoop: Auto.ProgramMenu UI for
                                 %% configuring the auto-poll schedule.
                                 %% No-op at LTS level.
action(do_auto).                 %% Auto.DoAuto: background scheduler tick,
                                 %% called every ModemLoop iteration.  No
                                 %% LTS-level state effect.
action(toggle_locator).          %% ExecCom 'L': CursorOn := ~CursorOn.
                                 %% Modelled as a no-op since CursorOn is a
                                 %% display-only flag we don't track in the
                                 %% six-tuple state.
action(select_pic_next).         %% '+' in ModemLoop, when CurrentPicture <
                                 %% NumofPictures.
action(select_pic_prev).         %% '-' in ModemLoop, when CurrentPicture > 1.


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

%% F2 in ModemLoop -> InterLoop -> Stations.CallStation requires a
%% currently-selected station with a phone number.
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

%% Models the user picking a station from Stations.StationMenu and the
%% subsequent population of CurrentStation^.PhoneNum from PHONENUM.TXT.
guard(load_station(Name), S) :-
    st_mode(S, modem),
    atom(Name), Name \== ''.

guard(station_menu, S) :- st_mode(S, modem).
guard(picture_menu, S) :- st_mode(S, modem), station_loaded(S).
guard(program_menu, S) :- st_mode(S, modem).
guard(do_auto, S)      :- st_mode(S, modem).

%% MAIN.MOD lines 161-165: GetParam returns Tilt > MAX(TiltType) when the
%% radar is unresponsive, and InterLoop RETURNs.  Mode is conceptually
%% Interactive at this point (CallStation just succeeded); the LTS rolls
%% it back to Modem to keep the state machine well-formed.
guard(handshake_fail, S) :-
    st_mode(S, interactive).

%% InterLoop ESC + 'Disconnect Station (Y/N)?' = Y -> Mode := Modem on
%% exit (line 409).
guard(hang_up, S) :-
    st_mode(S, interactive).

%% Carrier loss propagates through rs and surfaces in the InterLoop UNTIL
%% clause: ( Key = ASCII.esc ) OR ( Mode = Modem ) (line 394).
guard(line_disconnect, S) :-
    st_mode(S, M), member(M, [interactive, rx_pic]).

%% Parameter-bump guards.  The Modula-2 source updates NewPicture inline
%% with INC/DEC, range-checked against MAX(TiltType) etc.  The gain bug
%% from 19880519 is fixed in this snapshot.
guard(send_tilt_up, S)  :- interactive_with(S, tilt,  V), V < 11.
guard(send_tilt_dn, S)  :- interactive_with(S, tilt,  V), V >  0.
guard(send_range_up, S) :- interactive_with(S, range, V), V <  4.
guard(send_range_dn, S) :- interactive_with(S, range, V), V >  0.
guard(send_gain_up, S)  :- interactive_with(S, gain,  V), V < 17.
guard(send_gain_dn, S)  :- interactive_with(S, gain,  V), V >  1.

guard(request_pic, S)   :- st_mode(S, interactive).
guard(begin_rx_pic, S)  :- st_mode(S, interactive).
guard(complete_pic, S)  :- st_mode(S, rx_pic).
guard(abort_pic, S)     :- st_mode(S, rx_pic).

%% ExecCom toggles are accepted from anywhere keypresses are read --
%% ModemLoop and the InterLoop main body.  Per MAIN.MOD lines 102-122
%% there are no mode preconditions on the AuxCommand keys.
guard(toggle_graphics, S) :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).
guard(toggle_help, S)     :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).
guard(toggle_rng_mks, S)  :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).
guard(toggle_gfx1, S)     :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).
guard(toggle_gfx2, S)     :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).
guard(toggle_locator, S)  :- st_mode(S, M), member(M, [modem, interactive, rx_pic]).

%% Picture browsing in ModemLoop.  Bounds match ModemLoop lines 441-471.
guard(select_pic_next, S) :-
    st_mode(S, modem),
    st_library(S, L),
    lib_field(curr_pic, L, C),
    lib_field(max_pic,  L, M),
    C < M.
guard(select_pic_prev, S) :-
    st_mode(S, modem),
    st_library(S, L),
    lib_field(curr_pic, L, C),
    C > 0.

%% Helpers ------------------------------------------------------------------
interactive_with(S, F, V) :-
    st_mode(S, interactive),
    st_params(S, P),
    param_field(F, P, V).

station_loaded(S) :-
    st_station(S, station(_, _, true)).


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(call_station, S0, S1) :-
    set_mode(S0, interactive, S1).

step(dial_failure(_), S0, S1) :-
    set_mode(S0, modem, S1).

step(load_station(Name), S0, S1) :-
    %% Approximate: assume a non-empty phone is loaded with the station.
    %% Library is also reset to 0/0 since the station's Picture[] array
    %% is per-station (Stations.StationRec.NumofPictures starts at 0
    %% on InitStationDir for a fresh station).
    set_station(S0, station(Name, '5555555', true), S1mid),
    st_library(S1mid, L0),
    set_lib_field(curr_pic, L0, 0, L1),
    set_lib_field(max_pic, L1, 0, L2),
    set_lib_field(picture_saved, L2, false, L3),
    set_lib_field(gfx_match, L3, true, L4),
    set_library(S1mid, L4, S1).

step(station_menu, S, S).
step(picture_menu, S, S).
step(program_menu, S, S).
step(do_auto, S, S).
step(toggle_locator, S, S).

step(handshake_fail, S0, S1) :-
    set_mode(S0, modem, S1).

step(hang_up, S0, S1) :-
    set_mode(S0, modem, S1).

step(line_disconnect, S0, S1) :-
    set_mode(S0, modem, S1).

step(send_tilt_up,  S0, S1) :- bump_param(tilt,  +1, S0, S1).
step(send_tilt_dn,  S0, S1) :- bump_param(tilt,  -1, S0, S1).
step(send_range_up, S0, S1) :- bump_param(range, +1, S0, S1).
step(send_range_dn, S0, S1) :- bump_param(range, -1, S0, S1).
step(send_gain_up,  S0, S1) :- bump_param(gain,  +1, S0, S1).
%% Bug fixed: send_gain_dn now correctly decrements (MAIN.MOD line 269).
step(send_gain_dn,  S0, S1) :- bump_param(gain,  -1, S0, S1).

step(request_pic, S, S).             %% MakePic dispatched; PicReady flips
                                     %% mode via begin_rx_pic
step(begin_rx_pic, S0, S1) :-
    set_mode(S0, rx_pic, S1).

%% complete_pic in MAIN.MOD lines 365-374:
%%   SavePicture; AddPicture; INC(CurrentPicture); Mode := Modem.
%% This combines autosave + auto-disconnect, mirroring Pascal v2.1's
%% complete_pic behaviour.
step(complete_pic, S0, S2) :-
    st_library(S0, L0),
    lib_field(max_pic, L0, M0),
    M1 is M0 + 1,
    set_lib_field(max_pic, L0, M1, L1),
    set_lib_field(curr_pic, L1, M1, L2),
    set_lib_field(picture_saved, L2, true, L3),
    set_library(S0, L3, S1),
    set_mode(S1, modem, S2).

step(abort_pic, S0, S1) :-
    set_mode(S0, interactive, S1).

step(select_pic_next, S0, S1) :-
    st_library(S0, L0),
    lib_field(curr_pic, L0, C),
    C1 is C + 1,
    set_lib_field(curr_pic, L0, C1, L1),
    set_library(S0, L1, S1).

step(select_pic_prev, S0, S1) :-
    st_library(S0, L0),
    lib_field(curr_pic, L0, C),
    C1 is C - 1,
    set_lib_field(curr_pic, L0, C1, L1),
    set_library(S0, L1, S1).

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
%%   %% Dial in, request a picture, ISR completes, autosave + auto-disconnect:
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station,
%%            request_pic, begin_rx_pic, complete_pic ], S0, S),
%%      st_mode(S, M),
%%      st_library(S, library(C, Mx, Saved, _)).
%%   M = modem, C = 1, Mx = 1, Saved = true.
%%
%%   %% After saving one picture, browse it.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station, request_pic, begin_rx_pic, complete_pic,
%%            select_pic_prev,             %% to slot 0 (no picture)
%%            select_pic_next              %% back to slot 1
%%          ], S0, S),
%%      st_library(S, library(C, _, _, _)).
%%   C = 1.
%%
%%   %% Bug from 19880519 is fixed: send_gain_dn properly decrements.
%%   ?- initial_state(S0),
%%      trans(load_station('WLLX'), S0, S1),
%%      trans(call_station, S1, S2),
%%      trans(send_gain_up, S2, S3),
%%      trans(send_gain_up, S3, S4),
%%      trans(send_gain_dn, S4, S5),
%%      st_params(S5, params(_,_,_,_,G,_)).
%%   G = 2.
%%
%%   %% Auto.DoAuto and the *_menu actions are no-ops at LTS level.
%%   ?- initial_state(S0),
%%      trans(do_auto, S0, S0),
%%      trans(station_menu, S0, S0),
%%      trans(program_menu, S0, S0).
%%   true.
%%
%%   %% Handshake fail: dial succeeded but radar GetParam returned
%%   %% Tilt > MAX(TiltType).  InterLoop RETURNs and we model the
%%   %% mode rollback to Modem.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'), call_station, handshake_fail ], S0, S),
%%      st_mode(S, M).
%%   M = modem.
%% ----------------------------------------------------------------------------
