%% ============================================================================
%% radar_lts_19870512_radiorx.pl  --  Labeled Transition System for the
%%                                    sibling fork: RADIO-RX receiver-only
%%                                    terminal.
%%                                    (1987-05-12 "RADARPAS Tennterm",
%%                                     banner: "ver 1.2  Copyright (C) 1986
%%                                     SN 8705 -- WLLX RADIO LAWRENCEBURG")
%% ============================================================================
%%
%% Source program:  radar/19870512 RADARPAS Tennterm/RADAR.PAS
%% Companion files: radar/radar_lts_1985.pl
%%                  radar/radar_lts_19870412.pl
%%                  radar/radar_lts_19870416.pl
%%
%% This snapshot is *not* a continuation of the v2.x bidirectional terminal
%% lineage.  It is a separate, smaller program: a one-way customer-site
%% receiver that decodes pictures broadcast over a radio link by RADIOTX.
%% Hence the name "_radiorx" -- to distinguish this LTS from the
%% main-line evolution captured in radar_lts_1985.pl, _19870412.pl,
%% and _19870416.pl.
%%
%% Defining differences from the bidirectional terminal:
%%
%%   * No modem dialling, no Interactive mode, no SendCom, no RxGraph mode.
%%   * No picture library.  Each new picture overwrites the previous one
%%     in display memory.
%%   * No station selection.  StationName/PhoneNum are unused; LoadStation
%%     just reads MAP1.DAT/MAP2.DAT once at startup (the station is always
%%     WLLX).
%%   * ModeType = (WaitPic, RxPic).  Two states.  After Initialize the
%%     program enters WaitPic; on the first $18 $18 sync header it
%%     transitions to RxPic and stays there for the rest of the run.
%%   * Frames carry their own (Tilt, Range, Gain, Time) header (5 bytes
%%     before the line data).  The receiver maintains two copies:
%%        CurrentParams -- params of the picture currently displayed
%%        RParams       -- params of the picture currently being received
%%     A change in RParams.Time is the cue that a new picture has begun;
%%     CurrentParams is then refreshed from RParams and the reception
%%     buffers are reset.
%%   * Loop wraparound is detected via the FirstLine sentinel (overlapped
%%     with PicSave[-20000] via the `absolute` directive); when the next
%%     incoming line number matches FirstLine, reception is reset.
%%
%% Naming, predicate signatures, and structural conventions match the
%% main-line LTSes (initial_state/1, action/1, guard/2, step/3, trans/3,
%% run/3, reachable/1-2).
%%
%% ----------------------------------------------------------------------------

:- module(radar_lts_19870512_radiorx, [
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
%% Domains  (RADAR.PAS lines 46-88).
%% ----------------------------------------------------------------------------

mode(wait_pic).
mode(rx_pic).

range_index(I) :- between(0, 4, I).
tilt_index(I)  :- between(0, 11, I).
gain_index(I)  :- between(1, 17, I).
rt_state(0). rt_state(1). rt_state(2).


%% ----------------------------------------------------------------------------
%% The Application State
%%
%%   state(Mode, CurrentParams, RParams, Flags, Reception)
%%
%%   CurrentParams = params(StationId, time(H,M), Range, Tilt, Gain, Rt)
%%   RParams       = params(StationId, time(H,M), Range, Tilt, Gain, Rt)
%%   Flags         = flags(GraphicsOn, HelpOn, Gfx1On, Gfx2On, RngMksOn)
%%   Reception     = reception(LineAt, WriteAt, PicSaveAt, FirstLine, GRSize)
%%
%% Two `params` slots: CurrentParams is what is on screen now; RParams is
%% what the ISR is currently capturing.  When their Time fields disagree,
%% the foreground RxPicLoop commits RParams to CurrentParams and resets
%% reception buffers.
%%
%% Reception adds two fields beyond the main-line LTS:
%%   FirstLine -- the line number at PicSave[-20000], used to detect the
%%                broadcast loop's wraparound (overlapping with PicSave via
%%                `absolute` in the Pascal source).
%%   GRSize    -- number of bytes accumulated in the current ISR frame
%%                buffer (GRBuf), reset on each completed frame.
%%
%% State terms are immutable; every step builds a fresh term.
%% ----------------------------------------------------------------------------

%% initial_state/1 mirrors Initialize + main block (RADAR.PAS lines 990-1009,
%% 1126-1136): FillChar zeroes CurrentParams; Mode := WaitPic; LoadStation
%% reads MAP1/MAP2 once, then RxPicLoop begins.  RParams is also zeroed.
%% Reception starts with the same sentinel offsets used by the main-line
%% LTSes; FirstLine and GRSize start at zero.
initial_state(state(
        wait_pic,
        params(0, time(0,0), 0, 0, 0, 0),
        params(0, time(0,0), 0, 0, 0, 0),
        flags(true, false, false, false, false),
        reception(-20001, -20000, -20000, 0, 0))).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
%% ----------------------------------------------------------------------------

st_mode(state(M,_,_,_,_),           M).
st_current_params(state(_,P,_,_,_), P).
st_r_params(state(_,_,P,_,_),       P).
st_flags(state(_,_,_,F,_),          F).
st_reception(state(_,_,_,_,R),      R).

set_mode(state(_,P,Q,F,R),           M, state(M,P,Q,F,R)).
set_current_params(state(M,_,Q,F,R), P, state(M,P,Q,F,R)).
set_r_params(state(M,P,_,F,R),       Q, state(M,P,Q,F,R)).
set_flags(state(M,P,Q,_,R),          F, state(M,P,Q,F,R)).
set_reception(state(M,P,Q,F,_),      R, state(M,P,Q,F,R)).

%% Param projections + update  (identical shape to main-line LTSes).
param_field(range, params(_,_,V,_,_,_), V).
param_field(tilt,  params(_,_,_,V,_,_), V).
param_field(gain,  params(_,_,_,_,V,_), V).
param_field(rt,    params(_,_,_,_,_,V), V).
param_field(time,  params(_,T,_,_,_,_), T).

valid_param(range, V) :- range_index(V).
valid_param(tilt,  V) :- tilt_index(V).
valid_param(gain,  V) :- gain_index(V).
valid_param(rt,    V) :- rt_state(V).

%% Boolean lattice.
not_b(true, false).
not_b(false, true).

%% Flag accessors / setters  (identical to main-line LTSes).
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

%% Reception accessors.
recep_field(line_at,    reception(V,_,_,_,_), V).
recep_field(write_at,   reception(_,V,_,_,_), V).
recep_field(pic_save_at, reception(_,_,V,_,_), V).
recep_field(first_line, reception(_,_,_,V,_), V).
recep_field(gr_size,    reception(_,_,_,_,V), V).


%% ----------------------------------------------------------------------------
%% Action vocabulary
%%
%% A radio-rx terminal has a much smaller action set than the bidirectional
%% terminal.  It comprises:
%%
%%   * one ISR-driven mode switch   (sync_header)
%%   * frame-level ISR events       (receive_frame, frame_wrap)
%%   * foreground commit            (commit_new_picture, display_frame)
%%   * UI display toggles           (the same five flag flips as the main line)
%%
%% There is no Modem, Interactive, RxGraph; no dialling, no SendCom, no
%% picture library.
%% ----------------------------------------------------------------------------

action(sync_header).                %% $18 $18 detected -> WaitPic to RxPic
action(receive_frame(_RParams)).    %% complete frame received in RxPic
action(frame_wrap).                 %% FirstLine = incoming LineNum -> reset
action(commit_new_picture).         %% RParams.Time != CurrentParams.Time
action(display_frame).              %% advances WriteAt by LineSize
action(toggle_graphics).
action(toggle_help).
action(toggle_rng_mks).
action(toggle_gfx1).
action(toggle_gfx2).


%% ----------------------------------------------------------------------------
%% Guards
%%
%% Conditions trace the ISR (RADAR.PAS lines 880-940), RxPicLoop (1096-1124),
%% and ExecCom (1057-1094).  Note the absence of any `if Mode <> ...` gating
%% on the toggles: in this fork they are unconditional.
%% ----------------------------------------------------------------------------

guard(sync_header, S) :-
    st_mode(S, wait_pic).

guard(receive_frame(P), S) :-
    st_mode(S, rx_pic),
    P = params(_, time(H,Mi), R, T, G, Rt),
    integer(H), integer(Mi),
    valid_param(range, R),
    valid_param(tilt,  T),
    valid_param(gain,  G),
    valid_param(rt,    Rt).

guard(frame_wrap, S) :-
    st_mode(S, rx_pic).

guard(commit_new_picture, S) :-
    %% Foreground RxPicLoop fires this when RParams.Time differs.
    st_mode(S, rx_pic),
    st_current_params(S, CP),
    st_r_params(S, RP),
    param_field(time, CP, TC),
    param_field(time, RP, TR),
    TC \== TR.

guard(display_frame, S) :-
    %% RxPicLoop's "while (Mode=RxPic) and (LineAt>WriteAt)" loop body.
    st_mode(S, rx_pic),
    st_reception(S, R),
    recep_field(line_at,  R, L),
    recep_field(write_at, R, W),
    L > W.

guard(toggle_graphics, _).
guard(toggle_help, _).
guard(toggle_rng_mks, _).
guard(toggle_gfx1, _).      %% No StationName check -- station is fixed (WLLX).
guard(toggle_gfx2, _).


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

%% sync_header: WaitPic -> RxPic; reception buffers reset; FirstLine := -1
%% (the sentinel that guarantees the first incoming frame is *not*
%% interpreted as a wrap).
step(sync_header, S0, S2) :-
    set_mode(S0, rx_pic, S1),
    set_reception(S1, reception(-20001, -20000, -20000, -1, 0), S2).

%% receive_frame(P): updates RParams from the incoming frame; advances
%% PicSaveAt and LineAt by one abstract "line".  The Pascal ISR copies
%% bytes 6..GRSize-1 into PicSave; we abstract the size as one unit.
step(receive_frame(P), S0, S2) :-
    set_r_params(S0, P, S1),
    advance_reception(S1, S2).

%% frame_wrap: reception reset (LineAt < WriteAt forces foreground to stop
%% displaying); CurrentParams unchanged; RParams unchanged.
step(frame_wrap, S0, S1) :-
    set_reception(S0, reception(-20001, -20000, -20000, -1, 0), S1).

%% commit_new_picture: copies RParams to CurrentParams; reception reset so
%% the next set of incoming frames begins displaying from offset -20000.
step(commit_new_picture, S0, S2) :-
    st_r_params(S0, RP),
    set_current_params(S0, RP, S1),
    set_reception(S1, reception(-20001, -20000, -20000, -1, 0), S2).

%% display_frame: foreground advances WriteAt by an abstract LineSize unit.
step(display_frame, S0, S1) :-
    st_reception(S0, reception(L,W,P,F,G)),
    W1 is W + 1,
    set_reception(S0, reception(L,W1,P,F,G), S1).

step(toggle_graphics, S0, S1) :- flip_flag(graphics_on, S0, S1).
step(toggle_help,    S0, S1)  :- flip_flag(help_on,    S0, S1).
step(toggle_rng_mks, S0, S1)  :- flip_flag(rng_mks_on, S0, S1).
step(toggle_gfx1,    S0, S1)  :- flip_flag(gfx1_on,    S0, S1).
step(toggle_gfx2,    S0, S1)  :- flip_flag(gfx2_on,    S0, S1).


%% Helpers ------------------------------------------------------------------

flip_flag(Name, S0, S1) :-
    st_flags(S0, F0),
    flag_field(Name, F0, V0),
    not_b(V0, V1),
    set_flag_field(Name, F0, V1, F1),
    set_flags(S0, F1, S1).

%% Advance reception by one abstract frame: LineAt := PicSaveAt;
%% PicSaveAt := PicSaveAt + 1.  GRSize and FirstLine are unchanged at this
%% abstraction level.
advance_reception(S0, S1) :-
    st_reception(S0, reception(_,W,P,F,G)),
    P1 is P + 1,
    set_reception(S0, reception(P,W,P1,F,G), S1).


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
%%   %% First sync, then a frame for a brand-new picture, commit, display.
%%   ?- initial_state(S0),
%%      run([ sync_header,
%%            receive_frame(params(0, time(14,30), 3, 2, 8, 1)),
%%            commit_new_picture,
%%            display_frame ], S0, S),
%%      st_mode(S, M),
%%      st_current_params(S, params(_, time(H,Mi), _, _, _, _)).
%%   M = rx_pic, H = 14, Mi = 30.
%%
%%   %% Toggling display options never changes Mode and is unconditional.
%%   ?- initial_state(S0),
%%      trans(toggle_gfx1, S0, S1),
%%      st_mode(S1, wait_pic).
%%   true.
%%
%%   %% Loop wraparound resets reception but does not commit a new picture.
%%   ?- initial_state(S0),
%%      run([ sync_header,
%%            receive_frame(params(0, time(14,30), 3, 2, 8, 1)),
%%            frame_wrap ], S0, S),
%%      st_reception(S, reception(L,W,P,F,_)).
%%   L = -20001, W = -20000, P = -20000, F = -1.
%% ----------------------------------------------------------------------------
