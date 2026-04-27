%% ============================================================================
%% radar_lts_19871102.pl  --  Labeled Transition System for RADARPAS
%%                            (1987-11-02 "RADAR MOD Pas2Mod2",
%%                             banner: "RadarVersion2point0  Copyright (C)
%%                             1987 by D. Lane")
%% ============================================================================
%%
%% Source program:  radar/19871102 RADAR MOD Pas2Mod2/RADAR.MOD
%%                  + DEF/MOD files for the supporting modules:
%%                    Modem, Control, Picture, Map, ScreenHandler, Store,
%%                    Interact, Selector, Serial, Ser, KeyDispatcher,
%%                    MenuUtilities, Help, Print, Timer, Sets.
%% Companion files: radar/radar_lts_1985.pl
%%                  radar/radar_lts_19870412.pl
%%                  radar/radar_lts_19870416.pl
%%                  radar/radar_lts_19870512_radiorx.pl
%%
%% This snapshot is the **Pascal-to-Modula-2 transition**.  The monolithic
%% Turbo Pascal source has been split into ~13 LOGITECH MODULA-2/86 modules
%% with separate DEF/MOD pairs.  The most prominent observable changes:
%%
%%   * Modular architecture                 (each subsystem isolated behind
%%                                           a DEF interface).
%%   * Richer Modem.ResultCode enum         (Connect300/1200/2400, Ring,
%%                                           NoCarrier, NoDialtone, Busy,
%%                                           NoAnswer, ModemError,
%%                                           NoResponse, Ok).
%%   * Control.GetParam/SetParam abstracts  (no more direct Tx('Z')+command
%%                                           sequences in the main loop).
%%   * Store linked-list of stations        (StationRec with Phone field
%%                                           and 100-picture array).
%%
%% However, this is a **work-in-progress port**.  RADAR.MOD's main loop
%% wires up only a subset of the new module surface:
%%
%%   ACTIVE in RadarVersion2point0:
%%     * top-level:  F2  -> Modem.Call('1 532 3414'); branch on result
%%                   'R' -> ScreenHandler.ToggleRangeMarks
%%                   '1','2' -> ScreenHandler.ToggleMap(N)
%%     * interactive (Interact): F1-F6 -> Control.SetParam (tilt/range/gain +/-)
%%                               F7    -> ScreenHandler.Message('WAITING
%%                                        FOR PICTURE')   {Picture.Wait/
%%                                                          Download commented}
%%                               'R','1','2' -> same toggles as top-level
%%
%%   STUBBED OR COMMENTED OUT:
%%     * F1 StationMenu        -- procedure body is empty.
%%     * Picture.Wait/Download -- commented out at call sites.
%%     * Map.CheckMaps         -- commented out.
%%     * Help.Toggle           -- commented out.
%%     * ScreenHandler.ToggleWhite -- commented out.
%%     * Interact loop has no break; Modem.HangUp interface exists but no
%%       call site routes back to top level.
%%
%% The LTS below models *what is actually wired up*, while keeping the
%% six-tuple state shape from radar_lts_19870412.pl / _19870416.pl for
%% structural consistency.  Mode atoms wait_pic, rx_pic, rx_graph remain
%% defined for vocabulary continuity but are unreachable from
%% initial_state/1 in this snapshot.
%%
%% A `hang_up` action is included so callers can model returning from
%% Interactive to top-level, even though RADAR.MOD's source loop omits
%% that break -- consistent with the Modem.HangUp interface in MODEM.DEF.
%%
%% Naming, predicate signatures, and structural conventions match the
%% other date-stamped LTSes (initial_state/1, action/1, guard/2, step/3,
%% trans/3, run/3, reachable/1-2).
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_19871102, [
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
mode(rx_graph).         %% reserved, not wired up in this snapshot

range_index(I) :- between(0, 4, I).
tilt_index(I)  :- between(0, 11, I).
gain_index(I)  :- between(1, 17, I).
rt_state(0). rt_state(1). rt_state(2).

pic_index(I) :- between(0, 100, I).

%% Modem.ResultCode  (MODEM.DEF lines 17-31).
dial_outcome(ok).
dial_outcome(connect300).
dial_outcome(ring).
dial_outcome(no_carrier).
dial_outcome(modem_error).
dial_outcome(connect1200).
dial_outcome(no_dialtone).
dial_outcome(busy).
dial_outcome(no_answer).
dial_outcome(connect2400).
dial_outcome(no_response).

%% Convenience: which outcomes count as a successful connection?
%% RADAR.MOD line 108 only checks State=onLine, but onLine implies any
%% Connect* result.  We promote the three Connect codes here.
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
%% compatibility but are never updated -- the wired-up actions only touch
%% Mode, Params, Flags, and Station.
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

%% --- Carried over from 19870416 (same labels) -----------------------------
action(call_station).            %% Modem.Call -> Connect2400 (or 1200/300)
action(dial_failure(_Outcome)).  %% Modem.Call -> non-success ResultCode
action(hang_up).                 %% Modem.HangUp (interface present, source
                                 %% main loop omits the call site)
action(send_tilt_up).            %% F1 in Interact: INC(Tilt) + SetParam
action(send_tilt_dn).            %% F2 in Interact: DEC(Tilt) + SetParam
action(send_range_up).           %% F3 in Interact
action(send_range_dn).           %% F4 in Interact
action(send_gain_up).            %% F5 in Interact
action(send_gain_dn).            %% F6 in Interact
action(toggle_rng_mks).          %% ScreenHandler.ToggleRangeMarks
action(toggle_gfx1).             %% ScreenHandler.ToggleMap(1)
action(toggle_gfx2).             %% ScreenHandler.ToggleMap(2)

%% --- New / re-shaped in 19871102 ------------------------------------------
action(station_menu).            %% F1 at top level: empty stub
action(request_pic_stub).        %% F7 in Interact: Message only;
                                 %% Picture.Wait/Download commented out


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

%% Modem.Call only succeeds if a real ResultCode comes back as Connect*.
%% A phone number is hard-coded in RADAR.MOD line 107, so we don't gate on
%% station-loaded; the LTS still requires Mode = modem (top level).
guard(call_station, S) :-
    st_mode(S, modem).

guard(dial_failure(O), S) :-
    st_mode(S, modem),
    dial_outcome(O),
    \+ dial_success(O).

guard(hang_up, S) :-
    st_mode(S, interactive).      %% Only top-level break point of interest

guard(send_tilt_up, S)  :- interactive_with(S, tilt,  V), V < 11.
guard(send_tilt_dn, S)  :- interactive_with(S, tilt,  V), V >  0.
guard(send_range_up, S) :- interactive_with(S, range, V), V <  4.
guard(send_range_dn, S) :- interactive_with(S, range, V), V >  0.
guard(send_gain_up, S)  :- interactive_with(S, gain,  V), V < 17.
guard(send_gain_dn, S)  :- interactive_with(S, gain,  V), V >  1.

guard(request_pic_stub, S) :-
    %% Only callable in Interact (where F7 is mapped); has no state effect.
    st_mode(S, interactive).

%% Display toggles are wired up in *both* the top-level main loop AND
%% inside Interact (RADAR.MOD lines 81-89, 121-130) and have no other
%% gating in the Modula-2 port.  No StationName check.
guard(toggle_rng_mks, S) :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_gfx1, S)    :- st_mode(S, M), member(M, [modem, interactive]).
guard(toggle_gfx2, S)    :- st_mode(S, M), member(M, [modem, interactive]).

%% F1 at top level invokes StationMenu, whose body is empty in this
%% snapshot.  We expose it as an action so reachability analysis can see
%% the input event, but step/3 returns the same state.
guard(station_menu, S) :-
    st_mode(S, modem).

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

step(hang_up, S0, S1) :-
    set_mode(S0, modem, S1).

step(send_tilt_up,  S0, S1) :- bump_param(tilt,  +1, S0, S1).
step(send_tilt_dn,  S0, S1) :- bump_param(tilt,  -1, S0, S1).
step(send_range_up, S0, S1) :- bump_param(range, +1, S0, S1).
step(send_range_dn, S0, S1) :- bump_param(range, -1, S0, S1).
step(send_gain_up,  S0, S1) :- bump_param(gain,  +1, S0, S1).
step(send_gain_dn,  S0, S1) :- bump_param(gain,  -1, S0, S1).

step(request_pic_stub, S, S).        %% commented-out body in source

step(toggle_rng_mks, S0, S1) :- flip_flag(rng_mks_on, S0, S1).
step(toggle_gfx1,    S0, S1) :- flip_flag(gfx1_on,    S0, S1).
step(toggle_gfx2,    S0, S1) :- flip_flag(gfx2_on,    S0, S1).

step(station_menu, S, S).            %% empty StationMenu procedure body

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
%%   %% Successful Hayes 2400 connect, then a parameter tweak, then hang up.
%%   ?- initial_state(S0),
%%      run([ call_station, send_tilt_up, send_range_up, hang_up ], S0, S),
%%      st_mode(S, M), st_params(S, params(_,_,R,T,_,_)).
%%   M = modem, R = 4, T = 1.
%%
%%   %% Modem.NoCarrier keeps us at top level; library/reception untouched.
%%   ?- initial_state(S0),
%%      trans(dial_failure(no_carrier), S0, S),
%%      st_mode(S, modem).
%%   true.
%%
%%   %% F1 StationMenu and F7 request_pic_stub are no-ops at LTS level
%%   %% because their Pascal/Modula-2 bodies are empty or commented out.
%%   ?- initial_state(S0),
%%      trans(station_menu, S0, S0),                   %% same state
%%      trans(call_station, S0, S1),
%%      trans(request_pic_stub, S1, S1).               %% same state
%%   true.
%% ----------------------------------------------------------------------------
