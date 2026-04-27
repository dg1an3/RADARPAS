%% ============================================================================
%% fracgen_lts_19911218.pl  --  Labeled Transition System for the FracGen
%%                              Mandelbrot tile generator.
%%                              (1991-12-18 "FRACGEN_FRACPLOT",
%%                               source banner: "MODULE FracGen
%%                               IMPORT MATHLIB, Graph, Graphics, ...")
%% ============================================================================
%%
%% Source program:  egalib-math/19911218 FRACGEN_FRACPLOT/FRACGEN.MOD
%% Companion files: egalib-math/automata_lts_19930310.pl
%%                  egalib-math/fracplot_lts_19911218.pl  (the consumer)
%%                  radar/radar_lts_*.pl
%%
%% FracGen is a batch tile generator for a Mandelbrot atlas.  It has no
%% interactive UI: the program runs a sequence of hard-coded
%% GenSquareFile() calls, each of which:
%%
%%   1. fills out a Square record (FileName, C1, C2 corners),
%%   2. calls CalcSquare (which iterates the Mandelbrot map z_{n+1}
%%      = z_n^2 + c per pixel, accumulating IterCount up to 255 or
%%      until |z|^2 >= 8.0; results stored in Data[][]),
%%   3. calls SaveSquare (binary write of the whole Square record to
%%      `SQ####.FRC`).
%%
%% Each GenSquareFile produces one tile.  The set of tiles forms the
%% input that FracPlot (companion module) later consumes for printing.
%%
%% LTS abstraction: model the per-tile lifecycle as a small state
%% machine, with a counter for tiles completed.  The pixel-level
%% iteration inside CalcSquare is collapsed to a single `compute_tile`
%% transition; the `step_pixel` transition would be inappropriate at
%% the application LTS level.
%%
%% Predicate signatures match the radar / automata LTS family:
%%   initial_state/1, action/1, guard/2, step/3, trans/3, run/3,
%%   reachable/1, reachable/2.
%%
%% ----------------------------------------------------------------------------

:- module(fracgen_lts_19911218, [
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

%% Phase corresponds to where the program currently is in the per-tile
%% lifecycle (or in the bracketing initialisation / completion).
phase(init).         %% before InitEGA + GraphMode + SetPalette have run
phase(idle).         %% initialisation done; ready to begin next tile
phase(computing).    %% inside CalcSquare; pixel grid being filled
phase(saving).       %% inside SaveSquare; binary tile being written
phase(done).         %% all hard-coded GenSquareFile calls have returned


%% ----------------------------------------------------------------------------
%% The Application State
%%
%%   state(Phase, TilesCompleted, ScheduleSize)
%%
%%   Phase           :: init | idle | computing | saving | done
%%   TilesCompleted  :: non-negative integer; how many tiles have been
%%                      written to .FRC files since program start.
%%   ScheduleSize    :: total number of tiles the program will compute.
%%                      In FRACGEN.MOD's active body (lines 231-262)
%%                      this is 16 (sixteen GenSquareFile calls); the
%%                      LTS leaves it as a parameter so different builds
%%                      with different schedule lengths can reuse this
%%                      model.
%%
%% State terms are immutable.
%% ----------------------------------------------------------------------------

initial_state(state(init, 0, 16)).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
%% ----------------------------------------------------------------------------

st_phase(state(P,_,_),    P).
st_completed(state(_,N,_), N).
st_schedule(state(_,_,K), K).

set_phase(state(_,N,K),     P, state(P,N,K)).
set_completed(state(P,_,K), N, state(P,N,K)).


%% ----------------------------------------------------------------------------
%% Action vocabulary
%% ----------------------------------------------------------------------------

action(init_graphics).     %% InitEGA + GraphMode + SetPalette
                           %% (FRACGEN.MOD CalcSquare lines 58-65, in
                           %% practice run once at first GenSquareFile)
action(begin_tile).        %% start of a GenSquareFile call: Square
                           %% record populated, control enters
                           %% CalcSquare.
action(compute_tile).      %% completion of CalcSquare's nested loop:
                           %% all SquareResolution^2 = 22500 pixels
                           %% iterated.  We do not model the per-
                           %% pixel escape iteration at the LTS level.
action(save_tile).         %% SaveSquare writes the .FRC file; the
                           %% per-tile lifecycle ends and the schedule
                           %% counter advances.
action(terminate).         %% program-end transition once every
                           %% scheduled tile has been emitted.


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

guard(init_graphics, S) :-
    st_phase(S, init).

%% A new tile can only begin when the previous tile is fully saved
%% (idle phase) AND we have not yet exhausted the schedule.
guard(begin_tile, S) :-
    st_phase(S, idle),
    st_completed(S, N),
    st_schedule(S, K),
    N < K.

guard(compute_tile, S) :-
    st_phase(S, computing).

guard(save_tile, S) :-
    st_phase(S, saving).

%% Termination is allowed once the schedule is exhausted; this is the
%% transition into FracGen's implicit END (no main loop -- the body
%% just falls through after the last GenSquareFile call).
guard(terminate, S) :-
    st_phase(S, idle),
    st_completed(S, N),
    st_schedule(S, K),
    N >= K.


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(init_graphics, S0, S1) :-
    set_phase(S0, idle, S1).

step(begin_tile, S0, S1) :-
    set_phase(S0, computing, S1).

step(compute_tile, S0, S1) :-
    set_phase(S0, saving, S1).

step(save_tile, S0, S2) :-
    set_phase(S0, idle, S1),
    st_completed(S1, N0),
    N1 is N0 + 1,
    set_completed(S1, N1, S2).

step(terminate, S0, S1) :-
    set_phase(S0, done, S1).


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
%%   %% Three tiles + termination.  ScheduleSize defaults to 16 in
%%   %% initial_state/1, so we'd need begin/compute/save 16 times to
%%   %% reach `done` properly; trim the schedule for a quick check:
%%   ?- run([ init_graphics,
%%            begin_tile, compute_tile, save_tile,
%%            begin_tile, compute_tile, save_tile,
%%            begin_tile, compute_tile, save_tile ],
%%          state(init, 0, 3), S),
%%      st_phase(S, P), st_completed(S, N).
%%   P = idle, N = 3.
%%
%%   ?- run([ init_graphics,
%%            begin_tile, compute_tile, save_tile,
%%            begin_tile, compute_tile, save_tile,
%%            begin_tile, compute_tile, save_tile,
%%            terminate ],
%%          state(init, 0, 3), S),
%%      st_phase(S, P).
%%   P = done.
%%
%%   %% Cannot save before computing.
%%   ?- initial_state(S0),
%%      run([ init_graphics, begin_tile ], S0, S1),
%%      \+ trans(save_tile, S1, _).
%%   true.
%%
%%   %% Cannot terminate while tiles remain on the schedule.
%%   ?- initial_state(S0),
%%      run([ init_graphics ], S0, S1),
%%      \+ trans(terminate, S1, _).
%%   true.
%% ----------------------------------------------------------------------------
