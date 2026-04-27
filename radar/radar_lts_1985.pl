%% ============================================================================
%% radar_lts_1985.pl  --  Labeled Transition System for RADARPAS
%%                        (1985xxxx "E300PC Demo" snapshot)
%% ============================================================================
%%
%% Source program:  radar/1985xxxx E300PC Demo/RADAR.PAS
%% Author of model: Derived from D. G. Lane's Turbo Pascal 3 source (c. 1985).
%%
%% The original program is a single-threaded Pascal application driving an
%% Ellason E300 radar receiver over RS-232.  Application behaviour is dictated
%% by:
%%
%%   * a finite "Mode" variable                 (Modem | Interactive |
%%                                               WaitPic | RxPic | RxGraph)
%%   * the current RadarParams record           (Range, Tilt, Gain, Time, RT)
%%   * the loaded Station                       (name, phone, .STA loaded?)
%%   * five toggle flags                        (graphics, help, gfx1, gfx2,
%%                                               range marks)
%%   * picture/graphics reception bookkeeping   (LineAt, WriteAt, PicSaveAt,
%%                                               MapCount, Response)
%%
%% This file extracts those into an *immutable* application-state term and
%% re-expresses the program as a Labeled Transition System.  Every transition
%% has:
%%
%%   1. a label                     (action atom),
%%   2. a guard predicate           guard(+Action, +State),
%%   3. an update function          step(+Action, +State0, -State1).
%%
%% The relation
%%
%%       trans(Action, S0, S1) :-  guard(Action, S0), step(Action, S0, S1).
%%
%% is the labeled transition relation.  No clause asserts mutable state; each
%% step produces a brand-new state term.
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_1985, [
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
%% Domains  (drawn from the constant declarations at lines 26-28, 52 of
%% RADAR.PAS).
%% ----------------------------------------------------------------------------

mode(modem).
mode(interactive).
mode(wait_pic).
mode(rx_pic).
mode(rx_graph).

%% RangeVal[0..4] = (10, 25, 50, 100, 200) nautical miles
range_index(I) :- between(0, 4, I).

%% TiltVal[0..11] = (0,1,2,3,4,5,6,8,10,12,15,20) degrees
tilt_index(I)  :- between(0, 11, I).

%% Gain 1..16 ; 17 sentinels "PRE" preset
gain_index(I)  :- between(1, 17, I).

%% RT byte: 0=off, 1=on, 2=fault
rt_state(0). rt_state(1). rt_state(2).


%% ----------------------------------------------------------------------------
%% The Application State
%%
%%   state(Mode, Params, Flags, Station, Reception)
%%
%%   Params     = params(StationId, time(H,M), Range, Tilt, Gain, Rt)
%%   Flags      = flags(GraphicsOn, HelpOn, Gfx1On, Gfx2On, RngMksOn)
%%   Station    = station(Name, Phone, Loaded)
%%   Reception  = reception(LineAt, WriteAt, PicSaveAt, MapCount, Response)
%%
%% State terms are immutable: every step constructs a fresh term.
%% ----------------------------------------------------------------------------

%% initial_state/1 mirrors the main block (lines 1667-1673):
%%   Initialize; SelectStation; Mode:=Modem; CurrentParams.Range:=3;
%%   StatName:='ELLASON'; LoadStation; ShowLoop;
%% After Initialize, FillChar zeroes CurrentParams; Range is then set to 3.
initial_state(state(
        modem,
        params(0, time(0,0), 3, 0, 1, 0),
        flags(true, false, false, false, false),
        station('', '', false),
        reception(-20001, -20000, -20000, 0, false))).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
%% ----------------------------------------------------------------------------

st_mode(state(M,_,_,_,_), M).
st_params(state(_,P,_,_,_), P).
st_flags(state(_,_,F,_,_), F).
st_station(state(_,_,_,S,_), S).
st_reception(state(_,_,_,_,R), R).

set_mode(state(_,P,F,S,R),       M, state(M,P,F,S,R)).
set_params(state(M,_,F,S,R),     P, state(M,P,F,S,R)).
set_flags(state(M,P,_,S,R),      F, state(M,P,F,S,R)).
set_station(state(M,P,F,_,R),    S, state(M,P,F,S,R)).
set_reception(state(M,P,F,S,_),  R, state(M,P,F,S,R)).

%% Param field projections + update.
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

%% Booleans: a tiny lattice.
not_b(true, false).
not_b(false, true).

%% Flag accessors / setters indexed by name.
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
%% Action vocabulary  (the labels of the LTS).
%%
%% Each label corresponds to one self-contained Pascal control event:
%% a key press, an RS-232 ISR completion, a hardware response, etc.
%% ----------------------------------------------------------------------------

action(call_station).        % SelectStation -> CallStation; Mode:=Interactive
action(hang_up).             % HangUp; Mode:=Modem
action(send_tilt_up).        % SendCom(TiltUp,...)
action(send_tilt_dn).        % SendCom(TiltDown,...)
action(send_range_up).       % SendCom(RangeUp,...)
action(send_range_dn).       % SendCom(RangeDown,...)
action(send_gain_up).        % SendCom(GainUp,...)
action(send_gain_dn).        % SendCom(GainDown,...)
action(request_pic).         % RxPicLoop: SendCom(SendPic,...); Mode:=WaitPic
action(begin_rx_pic).        % ISR: FF FE FD header  -> Mode:=RxPic
action(complete_pic).        % ISR: LineNum>=352     -> Mode:=Modem
action(abort_pic).           % User: Tx('Y') x3      -> Mode:=Modem (escape)
action(request_graph).       % RxGraphLoop: SendCom(SendGraph,...) -> RxGraph
action(complete_graph).      % MapCount>3            -> Mode:=Interactive
action(abort_graph).         % User aborts; LoadStation; Mode:=Interactive
action(toggle_graphics).     % 'G' key
action(toggle_help).         % 'H' key
action(toggle_rng_mks).      % 'R' key
action(toggle_gfx1).         % '1' key
action(toggle_gfx2).         % '2' key
action(load_station(_Name)). % SelectStation digit -> LoadStation
action(update_params(_Pms)). % ISR 'Q' record       -> SetParams
action(line_disconnect).     % CD/CTS dropout in ISR -> Mode:=Modem


%% ----------------------------------------------------------------------------
%% Guards
%%
%% guard(+Action, +State) succeeds iff that action is currently enabled.
%% The conditions reflect the explicit `if Mode<>...` and `if Mode=...`
%% gating found in ExecCom (lines 1320-1357), InterLoop (lines 1419-1468),
%% RxPicLoop, RxGraphLoop, and the RS232 ISR.
%% ----------------------------------------------------------------------------

guard(call_station, S) :-
    st_mode(S, modem),
    st_station(S, station(Name, _, _)),
    Name \== ''.

guard(hang_up, S) :-
    st_mode(S, M),
    member(M, [interactive, rx_pic, rx_graph, wait_pic]).

guard(send_tilt_up, S)  :- interactive_with(S, tilt,  V), V < 11.
guard(send_tilt_dn, S)  :- interactive_with(S, tilt,  V), V >  0.
guard(send_range_up, S) :- interactive_with(S, range, V), V <  4.
guard(send_range_dn, S) :- interactive_with(S, range, V), V >  0.
guard(send_gain_up, S)  :- interactive_with(S, gain,  V), V < 17.
guard(send_gain_dn, S)  :- interactive_with(S, gain,  V), V >  1.

guard(request_pic, S)    :- st_mode(S, interactive).
guard(begin_rx_pic, S)   :- st_mode(S, wait_pic).
guard(complete_pic, S)   :- st_mode(S, rx_pic).
guard(abort_pic, S)      :- st_mode(S, M), member(M, [wait_pic, rx_pic]).

guard(request_graph, S)  :- st_mode(S, interactive).
guard(complete_graph, S) :- st_mode(S, rx_graph).
guard(abort_graph, S)    :- st_mode(S, rx_graph).

guard(toggle_graphics, _).                                % unconditional
guard(toggle_help,    S) :- \+ st_mode(S, rx_pic).
guard(toggle_rng_mks, S) :- \+ st_mode(S, rx_pic).
guard(toggle_gfx1, S)    :- \+ st_mode(S, rx_pic), station_loaded(S).
guard(toggle_gfx2, S)    :- \+ st_mode(S, rx_pic), station_loaded(S).

guard(load_station(Name), S) :-
    st_mode(S, modem),
    atom(Name), Name \== ''.

guard(update_params(P), S) :-
    st_mode(S, M),
    member(M, [interactive, wait_pic]),
    P = params(_, time(H,Mi), R, T, G, Rt),
    integer(H), integer(Mi),
    valid_param(range, R),
    valid_param(tilt,  T),
    valid_param(gain,  G),
    valid_param(rt,    Rt).

guard(line_disconnect, S) :-
    st_mode(S, M), M \== modem.

%% Convenience: in interactive mode and parameter F holds value V.
interactive_with(S, F, V) :-
    st_mode(S, interactive),
    st_params(S, P),
    param_field(F, P, V).

station_loaded(S) :-
    st_station(S, station(_, _, true)).


%% ----------------------------------------------------------------------------
%% Update functions  (state-transition functions per label)
%%
%% step(+Action, +State0, -State1) describes how the state evolves
%% when Action fires.  Each clause yields exactly one successor state
%% (the LTS is deterministic given the label and arguments).
%% ----------------------------------------------------------------------------

step(call_station, S0, S1) :-
    set_mode(S0, interactive, S1).

step(hang_up, S0, S1) :-
    set_mode(S0, modem, S1).

step(send_tilt_up,  S0, S1) :- bump_param(tilt,  +1, S0, S1).
step(send_tilt_dn,  S0, S1) :- bump_param(tilt,  -1, S0, S1).
step(send_range_up, S0, S1) :- bump_param(range, +1, S0, S1).
step(send_range_dn, S0, S1) :- bump_param(range, -1, S0, S1).
step(send_gain_up,  S0, S1) :- bump_param(gain,  +1, S0, S1).
step(send_gain_dn,  S0, S1) :- bump_param(gain,  -1, S0, S1).

step(request_pic, S0, S1) :-
    set_mode(S0, wait_pic, S1).

step(begin_rx_pic, S0, S2) :-
    %% RxPicLoop initialisation (lines 1397-1399):
    %%   WriteAt:=-20000; LineAt:=-20001; PicSaveAt:=-20000.
    set_mode(S0, rx_pic, S1),
    set_reception(S1, reception(-20001, -20000, -20000, 0, true), S2).

step(complete_pic, S0, S1) :-
    set_mode(S0, modem, S1).

step(abort_pic, S0, S1) :-
    set_mode(S0, modem, S1).

step(request_graph, S0, S2) :-
    %% RxGraphLoop (lines 1361): BufPtr:=Addr(Land1); MapCount:=0.
    set_mode(S0, rx_graph, S1),
    st_reception(S1, reception(L,W,P,_,_)),
    set_reception(S1, reception(L,W,P,0,true), S2).

step(complete_graph, S0, S1) :-
    set_mode(S0, interactive, S1).

step(abort_graph, S0, S1) :-
    %% Aborted: LoadStation restores prior overlays, mode returns Interactive.
    set_mode(S0, interactive, S1).

step(toggle_graphics, S0, S1) :- flip_flag(graphics_on, S0, S1).
step(toggle_help,    S0, S1)  :- flip_flag(help_on,    S0, S1).
step(toggle_rng_mks, S0, S1)  :- flip_flag(rng_mks_on, S0, S1).
step(toggle_gfx1,    S0, S1)  :- flip_flag(gfx1_on,    S0, S1).
step(toggle_gfx2,    S0, S1)  :- flip_flag(gfx2_on,    S0, S1).

step(load_station(Name), S0, S1) :-
    set_station(S0, station(Name, '', true), S1).

step(update_params(P), S0, S1) :-
    set_params(S0, P, S1).

step(line_disconnect, S0, S1) :-
    set_mode(S0, modem, S1).


%% Helpers used by step/3 ------------------------------------------------------

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

%% trans(?Action, +State0, -State1)
%%
%% The fundamental relation: there is an Action-labeled edge from State0 to
%% State1 in the LTS iff its guard holds and the update produces State1.
trans(Action, S0, S1) :-
    guard(Action, S0),
    step(Action, S0, S1).

%% run(+Trace, +State0, -State) executes a list of actions.
run([],        S, S).
run([A | As],  S0, S2) :-
    trans(A, S0, S1),
    run(As, S1, S2).

%% reachable(?S) -- depth-first reachability from initial_state/1.
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
%%   ?- initial_state(S0), trans(load_station('ELLASON'), S0, S1),
%%      trans(call_station, S1, S2), trans(send_range_up, S2, S3),
%%      st_params(S3, params(_,_,R,_,_,_)).
%%   R = 4.
%%
%%   ?- initial_state(S0),
%%      run([ load_station('ELLASON'), call_station,
%%            request_pic, begin_rx_pic, complete_pic ], S0, S),
%%      st_mode(S, M).
%%   M = modem.
%%
%%   ?- initial_state(S0),
%%      \+ trans(toggle_gfx1, S0, _).        % no station loaded yet
%%   true.
%% ----------------------------------------------------------------------------
