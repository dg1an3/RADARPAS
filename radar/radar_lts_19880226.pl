%% ============================================================================
%% radar_lts_19880226.pl  --  Labeled Transition System for RADARPAS
%%                            (1988-02-26 "RADARPAS SN8801" deployment,
%%                             banner unchanged: "ver 2.1 Revision 1/14/88
%%                             Copyright (C) 1987 D. G. Lane")
%% ============================================================================
%%
%% Source program:  radar/19880226 RADARPAS SN8801/RADAR.PAS
%%                  (uses external MISC.RDR / GRAPH.RDR / SCREEN.RDR includes;
%%                  the deployment archive also bundles RADAR.COM, RADAR2.COM,
%%                  RADART.PAS [v2.0 4/7/87], RADTEST.PAS [v2.0 6/25/87],
%%                  MODEM.PAS, LISTT.PAS as ancillary files).
%% Companion files: radar/radar_lts_1985.pl
%%                  radar/radar_lts_19870412.pl
%%                  radar/radar_lts_19870416.pl
%%                  radar/radar_lts_19870512_radiorx.pl
%%                  radar/radar_lts_19871102.pl
%%                  radar/radar_lts_19880114.pl
%%
%% Six weeks after the 19880114 snapshot.  The banner is identical, and
%% MODEM/CallStation/ModemLoop/RxPicLoop/RxGraphLoop are byte-equivalent
%% to 19880114.  The single behavioural change is in **InterLoop**:
%%
%%     19880114 had the "VERSION 2.0" manual-control block ACTIVE and the
%%     "VERSION 2.1" auto path commented out.  19880226 flips the comment
%%     markers: the v2.0 keypress loop is now commented out and the v2.1
%%     body -- which is just `RxPicLoop;` -- is active (RADAR.PAS lines
%%     2332-2369 in the inlined version, or the equivalent in the
%%     RDR-include version of 19880226).
%%
%% Consequences for the LTS:
%%
%%   1. Parameter-tweak actions are unreachable from Interactive mode.
%%      The keypress dispatch on extended F1-F6 codes is gone, so the
%%      following actions are dropped from the action/1 vocabulary:
%%        send_tilt_up, send_tilt_dn,
%%        send_range_up, send_range_dn,
%%        send_gain_up,  send_gain_dn.
%%      (The radar still receives 'Q' parameter records over the wire,
%%       so update_params/1 remains -- those come from the radar to us,
%%       not the other way round.)
%%
%%   2. Picture download is now driven by program flow, not a keypress.
%%      Once Interactive is entered, RxPicLoop runs unconditionally and
%%      issues SendPic itself.  request_pic/begin_rx_pic/complete_pic/
%%      abort_pic remain in the vocabulary as state-change events; only
%%      the agency changed (program-driven rather than user F7-driven).
%%
%%   3. NEW action: handshake_fail.  Before RxPicLoop runs, InterLoop
%%      tries SendCom('X', 150) up to four times to confirm the radar
%%      responded.  All four failing leads to "NO RESPONSE. PRESS ANY
%%      KEY", HangUp, and a goto Abort that returns InterLoop's caller
%%      with Mode := Modem.  Modelled as Interactive -> Modem.
%%
%%   4. HangUp's body remains commented out (carrier physically stays up;
%%      LTS-level Mode := Modem still applies).
%%
%% Same six-tuple state shape and predicate signatures as the prior
%% date-stamped LTSes for compositional consistency.
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_19880226, [
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
%% Domains  (RADAR2.PAS lines 14-22, 59-62).
%% ----------------------------------------------------------------------------

mode(modem).
mode(interactive).
mode(wait_pic).
mode(rx_pic).
mode(rx_graph).

range_index(I) :- between(0, 4, I).
tilt_index(I)  :- between(0, 11, I).
gain_index(I)  :- between(1, 17, I).
rt_state(0). rt_state(1). rt_state(2).

%% Pictures: 0 means "no picture selected" (matches CurrPic=0 sentinel).
pic_index(I) :- between(0, 100, I).

%% Modem dial outcomes (RADAR2.PAS lines 567-580).
dial_outcome(connect).        % '1' or 'L'
dial_outcome(no_carrier).     % '3'
dial_outcome(modem_error).    % '4' or 'C'
dial_outcome(no_dial_tone).   % '6' or 'E'
dial_outcome(busy).           % '7' or 'B'
dial_outcome(no_answer).      % '8' or 'F'
dial_outcome(time_out).       % 'T'


%% ----------------------------------------------------------------------------
%% The Application State  (extended from v1)
%%
%%   state(Mode, Params, Flags, Station, Reception, Library)
%%
%%   Params     = params(StationId, time(H,M), Range, Tilt, Gain, Rt)
%%   Flags      = flags(GraphicsOn, HelpOn, Gfx1On, Gfx2On, RngMksOn)
%%   Station    = station(Name, Phone, Loaded)
%%   Reception  = reception(LineAt, WriteAt, PicSaveAt, MapCount, Response)
%%   Library    = library(CurrPic, MaxPic, PictureSaved, GfxMatch)   *** NEW ***
%%
%% State terms are immutable; every step builds a fresh term.
%% ----------------------------------------------------------------------------

%% initial_state/1 mirrors the main block (RADAR2.PAS lines 1161-1176):
%%   GetDir; Initialize; CUSTOM banner; SelectStation; ModemLoop.
%% After Initialize, all global counts are zero; CurrPic, MaxPic start at 0.
%% GfxMatch defaults to true (no overlay refresh needed until CheckGraph runs).
initial_state(state(
        modem,
        params(0, time(0,0), 3, 0, 1, 0),
        flags(true, false, false, false, false),
        station('', '', false),
        reception(-20001, -20000, -20000, 0, false),
        library(0, 0, false, true))).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
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

%% Param projections + update  (identical to v1).
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

%% Boolean lattice.
not_b(true, false).
not_b(false, true).

%% Flag accessors / setters  (identical to v1).
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

%% Library projections.
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

%% --- Inherited from v1 (same labels, same intent) -------------------------
action(call_station).
action(hang_up).
%% Parameter-tweak actions are removed in 19880226: InterLoop's keypress
%% dispatch is commented out, so F1-F6 in Interactive no longer issue
%% SendCom(TiltUp/Down/...).  The radar's outgoing 'Q' records still
%% arrive in update_params/1 (radar -> us, unaffected).
action(request_pic).          % auto-issued from RxPicLoop entry
action(begin_rx_pic).
action(complete_pic).         % autosaves and hangs up
action(abort_pic).
action(request_graph).
action(complete_graph).
action(abort_graph).
action(toggle_graphics).
action(toggle_help).          % v2 guard relaxed
action(toggle_rng_mks).       % v2 guard relaxed
action(toggle_gfx1).          % v2 guard relaxed
action(toggle_gfx2).          % v2 guard relaxed
action(load_station(_Name)).
action(update_params(_Pms)).
action(line_disconnect).

%% --- New in v2 ------------------------------------------------------------
action(dial_failure(_Outcome)).  % CallStation: NO CARRIER / BUSY / etc.
action(check_graph(_Match)).     % SendCom(CheckGraph,...): updates GfxMatch
action(select_pic_next).         % '+' in ModemLoop: CurrPic := CurrPic + 1
action(select_pic_prev).         % '-' in ModemLoop: CurrPic := CurrPic - 1
action(delete_pic).              % Storage: F1 erases Pic[CurrPic]
action(save_pic).                % Internal: PicSaveAt closes, MaxPic += 1

%% --- New in 19880114 ------------------------------------------------------
action(call_no_phone).           % CallStation: PhoneNum='' and StationName<>''
                                 % -> Mode:=Interactive (RADAR.PAS 1256-1259)

%% --- New in 19880226 ------------------------------------------------------
action(handshake_fail).          % InterLoop: SendCom('X',150) retries fail
                                 % four times -> HangUp + goto Abort


%% ----------------------------------------------------------------------------
%% Guards
%%
%% Conditions trace ExecCom (RADAR.PAS 1612-1649), InterLoop (1764-1833),
%% RxPicLoop (1689-1762), RxGraphLoop (1650-1687), CallStation (1252-1296),
%% ModemLoop (1128-1156), and the RS-232 ISR (228-337).
%% ----------------------------------------------------------------------------

guard(call_station, S) :-
    st_mode(S, modem),
    st_station(S, station(_, Phone, _)),
    Phone \== ''.

guard(dial_failure(O), S) :-
    st_mode(S, modem),
    dial_outcome(O), O \== connect,
    st_station(S, station(_, Phone, _)),
    Phone \== ''.

guard(hang_up, S) :-
    st_mode(S, M),
    member(M, [interactive, wait_pic, rx_pic, rx_graph]).

%% NEW in 19880226: handshake_fail.  After CallStation succeeds, InterLoop
%% retries SendCom('X', 150) up to four times.  All four failing leads to
%% HangUp + goto Abort, returning Mode := Modem with no picture saved
%% (RADAR.PAS InterLoop, lines 2310-2330 in the inlined version).
guard(handshake_fail, S) :-
    st_mode(S, interactive).

guard(check_graph(Match), S) :-
    st_mode(S, interactive),
    member(Match, [true, false]).

guard(request_pic, S)    :- st_mode(S, interactive).
guard(begin_rx_pic, S)   :- st_mode(S, wait_pic).
guard(complete_pic, S)   :- st_mode(S, rx_pic).
guard(abort_pic, S)      :- st_mode(S, M), member(M, [wait_pic, rx_pic]).
guard(save_pic, S)       :- st_mode(S, rx_pic).

%% In v2, RxGraph can be auto-triggered by !GfxMatch after CheckGraph
%% (lines 1081-1083) or invoked manually.  The guard accepts both routes.
guard(request_graph, S)  :- st_mode(S, interactive).
guard(complete_graph, S) :- st_mode(S, rx_graph).
guard(abort_graph, S)    :- st_mode(S, rx_graph).

guard(toggle_graphics, _).                     % unconditional (unchanged)
guard(toggle_help, _).                         % v2: unconditional
guard(toggle_rng_mks, _).                      % v2: unconditional
guard(toggle_gfx1, S) :- station_loaded(S).    % v2: only requires loaded station
guard(toggle_gfx2, S) :- station_loaded(S).    % v2: only requires loaded station

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

%% Picture-library actions are driven from ModemLoop (RADAR2.PAS 1128-1156)
%% and Storage (447-500), both of which run only with Mode = Modem.
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

guard(delete_pic, S) :-
    st_mode(S, modem),
    st_library(S, L),
    lib_field(curr_pic, L, C),
    C > 0.

%% New in 19880114: CallStation lets the user enter Interactive without a
%% dial attempt when no phone number is configured but a station has been
%% loaded -- a development convenience preserved from earlier internal
%% builds and now formalised in the source.
guard(call_no_phone, S) :-
    st_mode(S, modem),
    st_station(S, station(Name, Phone, _)),
    Name \== '',
    Phone == ''.

%% Helpers ------------------------------------------------------------------
station_loaded(S) :-
    st_station(S, station(_, _, true)).


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(call_station, S0, S1) :-
    set_mode(S0, interactive, S1).        % MessReady[1] in ['1','L']

step(dial_failure(_), S0, S1) :-
    set_mode(S0, modem, S1).              % HangUp; Mode stays Modem

step(hang_up, S0, S1) :-
    set_mode(S0, modem, S1).

step(handshake_fail, S0, S1) :-
    set_mode(S0, modem, S1).

step(check_graph(Match), S0, S1) :-
    set_lib(gfx_match, Match, S0, S1).

step(request_pic, S0, S1) :-
    set_mode(S0, wait_pic, S1).

step(begin_rx_pic, S0, S2) :-
    set_mode(S0, rx_pic, S1),
    set_reception(S1, reception(-20001, -20000, -20000, 0, true), S2).

step(complete_pic, S0, S3) :-
    %% RxPicLoop on LastLine>=352:
    %%   HangUp; SavePic(...); PictureSaved := true; Mode := Modem.
    %% Also commits the reserved slot (MaxPic was bumped at InterLoop entry).
    st_library(S0, L0),
    lib_field(max_pic, L0, M0),
    M1 is M0 + 1,
    set_lib_field(max_pic, L0, M1, L1),
    set_lib_field(curr_pic, L1, M1, L2),
    set_lib_field(picture_saved, L2, true, L3),
    set_library(S0, L3, S1),
    set_mode(S1, modem, S2),
    set_reception(S2, reception(-20001, -20000, -20000, 0, false), S3).

step(abort_pic, S0, S2) :-
    %% RxPicLoop on user abort: Mode := Interactive; PictureSaved := false.
    set_mode(S0, interactive, S1),
    set_lib(picture_saved, false, S1, S2).

step(save_pic, S0, S1) :-
    %% Internal "SavePic finished writing" event; analogous to complete_pic
    %% but without mode change (allows modelling completion separately
    %% from disconnect).
    set_lib(picture_saved, true, S0, S1).

step(request_graph, S0, S2) :-
    set_mode(S0, rx_graph, S1),
    st_reception(S1, reception(L,W,P,_,_)),
    set_reception(S1, reception(L,W,P,0,true), S2).

step(complete_graph, S0, S2) :-
    %% RxGraphLoop completion: writes MAP1.DAT/MAP2.DAT, returns to Interactive,
    %% and the freshly-downloaded overlay implies GfxMatch becomes true.
    set_mode(S0, interactive, S1),
    set_lib(gfx_match, true, S1, S2).

step(abort_graph, S0, S1) :-
    set_mode(S0, interactive, S1).

step(toggle_graphics, S0, S1) :- flip_flag(graphics_on, S0, S1).
step(toggle_help,    S0, S1)  :- flip_flag(help_on,    S0, S1).
step(toggle_rng_mks, S0, S1)  :- flip_flag(rng_mks_on, S0, S1).
step(toggle_gfx1,    S0, S1)  :- flip_flag(gfx1_on,    S0, S1).
step(toggle_gfx2,    S0, S1)  :- flip_flag(gfx2_on,    S0, S1).

step(load_station(Name), S0, S2) :-
    %% LoadStation reads PHONENUM.TXT and the .PIC directory; replaces the
    %% library with that station's catalogue.  We model the catalogue size
    %% only opaquely: MaxPic resets, CurrPic := 0.
    set_station(S0, station(Name, '', true), S1),
    st_library(S1, L0),
    set_lib_field(curr_pic, L0, 0, L1),
    set_lib_field(max_pic, L1, 0, L2),
    set_lib_field(picture_saved, L2, false, L3),
    set_lib_field(gfx_match, L3, true, L4),
    set_library(S1, L4, S2).

step(update_params(P), S0, S1) :-
    set_params(S0, P, S1).

step(line_disconnect, S0, S1) :-
    set_mode(S0, modem, S1).

step(select_pic_next, S0, S1) :- bump_curr_pic(+1, S0, S1).
step(select_pic_prev, S0, S1) :- bump_curr_pic(-1, S0, S1).

step(delete_pic, S0, S1) :-
    %% Storage: removes Pic[CurrPic], shifts higher slots down, decrements
    %% MaxPic.  CurrPic stays put (now points at what was CurrPic+1) unless
    %% it was the last entry, in which case it clamps to MaxPic.
    st_library(S0, L0),
    lib_field(curr_pic, L0, C0),
    lib_field(max_pic,  L0, M0),
    M1 is M0 - 1,
    (   C0 > M1 -> C1 = M1 ; C1 = C0 ),
    set_lib_field(max_pic,  L0, M1, L1),
    set_lib_field(curr_pic, L1, C1, L2),
    set_library(S0, L2, S1).

step(call_no_phone, S0, S1) :-
    set_mode(S0, interactive, S1).


%% Helpers used by step/3 ---------------------------------------------------

flip_flag(Name, S0, S1) :-
    st_flags(S0, F0),
    flag_field(Name, F0, V0),
    not_b(V0, V1),
    set_flag_field(Name, F0, V1, F1),
    set_flags(S0, F1, S1).

set_lib(Field, Value, S0, S1) :-
    st_library(S0, L0),
    set_lib_field(Field, L0, Value, L1),
    set_library(S0, L1, S1).

bump_curr_pic(Delta, S0, S1) :-
    st_library(S0, L0),
    lib_field(curr_pic, L0, C0),
    lib_field(max_pic,  L0, M),
    C1 is C0 + Delta,
    C1 >= 0, C1 =< M,
    set_lib_field(curr_pic, L0, C1, L1),
    set_library(S0, L1, S1).


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
%%   %% Successful call -> auto map refresh -> picture capture:
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station,
%%            check_graph(false),    request_graph, complete_graph,
%%            request_pic, begin_rx_pic, complete_pic ], S0, S),
%%      st_mode(S, M), st_library(S, L).
%%   M = modem,
%%   L = library(1, 1, true, true).
%%
%%   %% Dial fails: stays in Modem, library unchanged.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            dial_failure(busy) ], S0, S),
%%      st_mode(S, M).
%%   M = modem.
%%
%%   %% Browsing the library is only possible when pictures exist.
%%   ?- initial_state(S0), \+ trans(select_pic_next, S0, _).
%%   true.
%%
%%   %% A station with no phone number can still be entered in Interactive
%%   %% mode (carried over from 19880114).
%%   ?- initial_state(S0),
%%      trans(load_station('LOCAL'), S0, S1),
%%      trans(call_no_phone, S1, S2),
%%      st_mode(S2, M).
%%   M = interactive.
%%
%%   %% NEW in 19880226: handshake_fail terminates a session before any
%%   %% picture is downloaded.
%%   ?- initial_state(S0),
%%      run([ load_station('WLLX'),
%%            call_station,
%%            handshake_fail ], S0, S),
%%      st_mode(S, M), st_library(S, library(C,Mx,Sv,_)).
%%   M = modem, C = 0, Mx = 0, Sv = false.
%%
%%   %% Removed in 19880226: parameter-tweak actions are gone -- the v2.0
%%   %% manual control loop in InterLoop is commented out.
%%   ?- initial_state(S0),
%%      \+ trans(send_tilt_up,  S0, _),
%%      \+ trans(send_range_up, S0, _),
%%      \+ trans(send_gain_up,  S0, _).
%%   true.
%%
%%   %% Removed earlier in 19880114, still gone: F4 RadioTx.
%%   ?- initial_state(S0), \+ trans(radio_tx, S0, _).
%%   true.
%% ----------------------------------------------------------------------------
