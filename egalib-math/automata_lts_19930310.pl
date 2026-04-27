%% ============================================================================
%% automata_lts_19930310.pl  --  Labeled Transition System for the EEVORG
%%                               1D cellular automaton simulator.
%%                               (1993-03-10 "AUTOMATA",
%%                                source banner: "MODULE Automata
%%                                Copyright (C) 1991, Derek Graham Lane
%%                                Scalable state one-dimensional cellular
%%                                automaton simulator, including simple
%%                                editing and saver/restore functions.")
%% ============================================================================
%%
%% Source program:  egalib-math/19930310 AUTOMATA/AUTOMATA.MOD
%% Companion files: radar/radar_lts_*.pl   (the radar LTS lineage)
%%
%% This LTS sits *outside* the radar/ tree.  It models a cellular-
%% automaton research program that shares Derek Lane's Modula-2
%% graphics infrastructure (the `Graphics` module that succeeded EGALib
%% in mid-1988, plus the third-party `Graph` library by Jensen &
%% Partners) but is otherwise an independent project.
%%
%% Naming the modes in this LTS does not reuse the radar mode set --
%% the source has no `Modem` / `Interactive` / `RxPic` / `RxGraph`
%% concepts.  It has two macro-modes:
%%
%%   prompting  -- before the main LOOP, the program writes "NAME: "
%%                 and reads RuleFileName (lines 193-194).
%%   running    -- inside the LOOP (lines 226-339), which never exits
%%                 from the source -- the simulator runs until the
%%                 user kills the process.
%%
%% Two orthogonal sub-state dimensions live inside `running`:
%%
%%   1. Cell configuration (Ned.Cells).  We abstract its many possible
%%      configurations into five qualitative classes:
%%
%%         empty         -- Cells[i] = 0 for all i  (after 'b' or initial)
%%         seeded_one    -- a single non-zero cell at Size DIV 2  ('1')
%%         seeded_two    -- two non-zero cells at quarter points    ('2')
%%         scattered     -- random sprinkling of cells              ('c')
%%         evolving      -- HaveaKid has been called at least once
%%                          since the last seed/clear/scatter
%%
%%   2. Mutation-search state (the OldRule/OldCount lifecycle, lines
%%      315-337).  Three phases:
%%
%%         no_trial       -- OldRule = MAX(CARDINAL); no mutation in
%%                           flight.  The next tick will start one.
%%         testing(C)     -- OldRule set, OldCount = C in [0, 30).
%%                           A rule slot has been mutated; entropy is
%%                           being observed.
%%         evaluated(C)   -- OldCount in [30, 50].  The rule was kept
%%                           or reverted at OldCount = 30 based on
%%                           SE/TE comparison; either way the trial is
%%                           still in the bookkeeping window until
%%                           OldCount > 50, when it commits.
%%
%%   The Times2 zoom flag (lines 192, 269) is also tracked; everything
%%   else (palette, RuleFileName, the actual cell array contents) is
%%   abstracted away.
%%
%% Predicate signatures match the radar LTS family:
%%   initial_state/1, action/1, guard/2, step/3, trans/3, run/3,
%%   reachable/1, reachable/2.
%%
%% ----------------------------------------------------------------------------

:- module(automata_lts_19930310, [
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

mode(prompting).
mode(running).

%% Cell-configuration class.
cells(empty).
cells(seeded_one).
cells(seeded_two).
cells(scattered).
cells(evolving).

%% Mutation-search lifecycle phase.
mutation_phase(no_trial).
mutation_phase(testing).
mutation_phase(evaluated).


%% ----------------------------------------------------------------------------
%% The Application State
%%
%%   state(Mode, Cells, Mutation, Times2)
%%
%%   Mode      :: prompting | running
%%   Cells     :: empty | seeded_one | seeded_two | scattered | evolving
%%   Mutation  :: no_trial | testing | evaluated
%%   Times2    :: false | true
%%
%% State terms are immutable; every step builds a fresh term.
%% ----------------------------------------------------------------------------

%% initial_state/1 mirrors the BEGIN block at line 189: program just
%% started, has not yet read the filename.  All bookkeeping cleared.
initial_state(state(prompting, empty, no_trial, false)).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
%% ----------------------------------------------------------------------------

st_mode(state(M,_,_,_),     M).
st_cells(state(_,C,_,_),    C).
st_mutation(state(_,_,X,_), X).
st_times2(state(_,_,_,T),   T).

set_mode(state(_,C,X,T),     M, state(M,C,X,T)).
set_cells(state(M,_,X,T),    C, state(M,C,X,T)).
set_mutation(state(M,C,_,T), X, state(M,C,X,T)).
set_times2(state(M,C,X,_),   T, state(M,C,X,T)).

not_b(true, false).
not_b(false, true).


%% ----------------------------------------------------------------------------
%% Action vocabulary
%% ----------------------------------------------------------------------------

%% --- Setup ----------------------------------------------------------------
action(enter_filename(_Name)). %% line 194: IO.RdStr(RuleFileName); the
                               %% program then leaves the prompting mode.

%% --- Generation evolution -------------------------------------------------
action(evolve_step).           %% one HaveaKid call (lines 234, 96): Bob ->
                               %% next generation.  Cells become `evolving`.

%% --- User keypresses (lines 238-279) -------------------------------------
action(key_clear).             %% 'b': zero all Cells   (lines 248-251)
action(key_scatter).           %% 'c': random sprinkle  (lines 241-244)
action(key_seed_one).          %% '1': clear, then one center cell
                               %%      (lines 256-260)
action(key_seed_two).          %% '2': clear, then two cells at quarters
                               %%      (lines 261-267)
action(key_mutate_rule).       %% 'r': mutate one rule slot directly
                               %%      (lines 245-247)
action(key_save_rule).         %% 's': SaveRule (line 252)
action(key_load_rule).         %% 'l': ReadRandomRule from file (line 254)
action(key_toggle_zoom).       %% 'x': Times2 := ~Times2 (line 269)
action(key_random_palette).    %% 'p': random palette (lines 270-277)

%% --- Background mutation-search lifecycle (lines 315-337) ----------------
%% This lifecycle is internal to each tick: no_trial -> testing -> evaluated
%% -> no_trial.  Each transition is automatically driven by OldCount in the
%% source; we expose them as explicit actions for LTS analysability.
action(mutation_propose).      %% OldRule = MAX -> pick a slot; mutate;
                               %% OldCount := 0   (lines 315-322)
action(mutation_evaluate).     %% OldCount = 30: compare SE/TE to OldSE/
                               %% OldTE.  Either way the trial continues
                               %% bookkeeping until OldCount > 50.
                               %% (lines 326-329)
action(mutation_commit).       %% OldCount > 50: clear pending; if SE
                               %% per-mille in [280, 400), SaveRule.
                               %% (lines 330-336)


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

guard(enter_filename(Name), S) :-
    st_mode(S, prompting),
    atom(Name), Name \== ''.

%% Everything else requires running mode.  The keypresses are processed
%% inside the LOOP (lines 238-279) and the mutation lifecycle runs every
%% iteration of the inner FOR.

guard(evolve_step, S)        :- st_mode(S, running).
guard(key_clear, S)          :- st_mode(S, running).
guard(key_scatter, S)        :- st_mode(S, running).
guard(key_seed_one, S)       :- st_mode(S, running).
guard(key_seed_two, S)       :- st_mode(S, running).
guard(key_mutate_rule, S)    :- st_mode(S, running).
guard(key_save_rule, S)      :- st_mode(S, running).
guard(key_load_rule, S)      :- st_mode(S, running).
guard(key_toggle_zoom, S)    :- st_mode(S, running).
guard(key_random_palette, S) :- st_mode(S, running).

%% Mutation lifecycle is a strict cycle: no_trial -> testing ->
%% evaluated -> no_trial.  Each transition is allowed only when the
%% current phase matches.
guard(mutation_propose, S) :-
    st_mode(S, running),
    st_mutation(S, no_trial).

guard(mutation_evaluate, S) :-
    st_mode(S, running),
    st_mutation(S, testing).

guard(mutation_commit, S) :-
    st_mode(S, running),
    st_mutation(S, evaluated).


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(enter_filename(_), S0, S1) :-
    set_mode(S0, running, S1).

step(evolve_step, S0, S1) :-
    %% HaveaKid replaces Cells with the next generation.  Regardless of
    %% prior class (empty/seeded/scattered) the post-state is `evolving`
    %% as long as Rules contain at least one non-zero output for the
    %% relevant Sum -- which the LTS does not gate on.
    set_cells(S0, evolving, S1).

step(key_clear, S0, S1)       :- set_cells(S0, empty,       S1).
step(key_scatter, S0, S1)     :- set_cells(S0, scattered,   S1).
step(key_seed_one, S0, S1)    :- set_cells(S0, seeded_one,  S1).
step(key_seed_two, S0, S1)    :- set_cells(S0, seeded_two,  S1).

step(key_mutate_rule, S, S).      %% Affects rules, not our four state
                                  %% dimensions.
step(key_save_rule, S, S).        %% Pure I/O side effect.
step(key_load_rule, S, S).        %% Replaces rules; cells unchanged.
step(key_random_palette, S, S).   %% Display only.

step(key_toggle_zoom, S0, S1) :-
    st_times2(S0, T0),
    not_b(T0, T1),
    set_times2(S0, T1, S1).

%% Mutation lifecycle.
step(mutation_propose, S0, S1) :-
    set_mutation(S0, testing, S1).

step(mutation_evaluate, S0, S1) :-
    %% At OldCount = 30 the source either keeps or reverts the mutation
    %% based on the SE/TE comparison.  Either branch leaves the trial
    %% in the same bookkeeping phase, so the LTS abstracts both into
    %% a single non-deterministic step.
    set_mutation(S0, evaluated, S1).

step(mutation_commit, S0, S1) :-
    %% At OldCount > 50 the trial closes.  If SE per-mille falls in
    %% the [280, 400) "edge of chaos" band the rule is saved (an I/O
    %% side effect).  Either branch returns the lifecycle to no_trial.
    set_mutation(S0, no_trial, S1).


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
%%   %% Setup, seed, evolve, mutate-search lifecycle.
%%   ?- initial_state(S0),
%%      run([ enter_filename('test.dat'),
%%            key_seed_one,
%%            evolve_step,
%%            mutation_propose,
%%            mutation_evaluate,
%%            mutation_commit ], S0, S),
%%      st_mode(S, M),
%%      st_cells(S, C),
%%      st_mutation(S, X).
%%   M = running, C = evolving, X = no_trial.
%%
%%   %% None of the running-mode actions are enabled before
%%   %% enter_filename/1.
%%   ?- initial_state(S0),
%%      \+ trans(evolve_step,  S0, _),
%%      \+ trans(key_seed_one, S0, _),
%%      \+ trans(mutation_propose, S0, _).
%%   true.
%%
%%   %% Mutation lifecycle is a strict cycle.  Cannot evaluate before
%%   %% proposing.
%%   ?- initial_state(S0),
%%      run([ enter_filename('rules.dat') ], S0, S1),
%%      \+ trans(mutation_evaluate, S1, _).
%%   true.
%%
%%   %% 'x' toggles the Times2 zoom flag.
%%   ?- initial_state(S0),
%%      run([ enter_filename('rules.dat'),
%%            key_toggle_zoom ], S0, S),
%%      st_times2(S, T).
%%   T = true.
%% ----------------------------------------------------------------------------
