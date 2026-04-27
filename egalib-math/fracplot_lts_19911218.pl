%% ============================================================================
%% fracplot_lts_19911218.pl  --  Labeled Transition System for the FracPlot
%%                               printer-output companion to FracGen.
%%                               (1991-12-18 "FRACGEN_FRACPLOT",
%%                                source banner: "MODULE FracPlot
%%                                IMPORT MATHLIB, Graph, Graphics,
%%                                Storage, ...")
%% ============================================================================
%%
%% Source program:  egalib-math/19911218 FRACGEN_FRACPLOT/FRACPLOT.MOD
%% Companion files: egalib-math/automata_lts_19930310.pl
%%                  egalib-math/fracgen_lts_19911218.pl   (the producer)
%%                  radar/radar_lts_*.pl
%%
%% FracPlot is the consumer half of the FracGen/FracPlot pair.  It loads
%% the .FRC tile files written by FracGen, dithers each tile's escape-
%% count grid into a 3-channel CMY raster (using a stochastic tone
%% reproduction trick driven by MATHLIB.Sin and Lib.RAND), plots the
%% result on the EGA screen, and emits HP-PCL escape sequences plus the
%% raw raster bytes to per-page .PRN files for printing.
%%
%% The control structure (FRACPLOT.MOD lines 54-171) is:
%%
%%   InitEGA + GraphMode;
%%   FOR C2 := 8 TO 24 DO NEW( S[C2] ) END;        (* allocate 17 tile slots *)
%%
%%   FOR C1 := 4 TO 15 DO                          (* 12 output pages *)
%%     FOR C2 := 8 TO 24 DO                        (* 17 tiles per page *)
%%       build SQ####.FRC filename;
%%       LoadSquare( S[C2]^ );
%%     END;
%%     create  SQ###.PRN  output file;
%%     FOR Line := 149 TO 0 BY -1 DO               (* 150 raster rows per page *)
%%       fill CBuf, YBuf, MBuf with zeros;
%%       FOR C2 := 8 TO 24, FOR Col := 0 TO 149 DO
%%         dither pixel; pack into CBuf/YBuf/MBuf;
%%         Graph.Plot to screen;
%%       END;
%%       write '*b300V' + CBuf, '*b300V' + YBuf, '*b300W' + MBuf to .PRN;
%%     END;
%%     close  SQ###.PRN  output file;
%%   END;
%%
%%   write 14C (form feed);
%%   close .PRN;
%%
%% The LTS abstracts the per-pixel dithering, per-row buffering, and
%% per-tile loading into atomic transitions.  Three counters accompany
%% the phase atom:
%%
%%   PageIdx   :: which output page is currently being processed.
%%   TilesLoaded :: how many of the 17 tiles for the current page have
%%                  been read from disk.
%%   LinesEmitted :: how many of the 150 raster rows for the current
%%                   page have been emitted to the .PRN file.
%%
%% Predicate signatures match the radar / automata / FracGen LTS
%% family: initial_state/1, action/1, guard/2, step/3, trans/3, run/3,
%% reachable/1, reachable/2.
%%
%% ----------------------------------------------------------------------------

:- module(fracplot_lts_19911218, [
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

phase(init).            %% before InitEGA + GraphMode + NEW S[..]
phase(loading).         %% inside the FOR C2 := 8 TO 24 DO LoadSquare loop
phase(page_open).       %% .PRN file just created; ready to emit lines
phase(emitting).        %% inside the FOR Line loop: rendering + writing
phase(page_closing).    %% all 150 lines emitted; .PRN file being closed
phase(between_pages).   %% .PRN closed; ready to advance C1 or terminate
phase(done).            %% form-feed written; final .PRN closed

%% Page count (C1 = 4 .. 15) and per-page tile count / line count.
%% These aren't enumerated explicitly; bounds are written into the
%% guards as integer comparisons.


%% ----------------------------------------------------------------------------
%% The Application State
%%
%%   state(Phase, PageIdx, TilesLoaded, LinesEmitted)
%%
%%   Phase         :: init | loading | page_open | emitting |
%%                    page_closing | between_pages | done
%%   PageIdx       :: which output page is in flight  (0-indexed; 0..11
%%                    correspond to C1 = 4..15 in the source)
%%   TilesLoaded   :: how many of the 17 SQ####.FRC tiles for the
%%                    current page have been loaded (0..17).  Cleared
%%                    when entering `loading` for a new page.
%%   LinesEmitted  :: how many of the 150 raster rows for the current
%%                    page have been pushed to .PRN (0..150).  Cleared
%%                    when entering `emitting` for a new page.
%%
%% Tile slot allocation (NEW S[8..24], lines 69-71) is handled by
%% init_graphics + alloc_slots; we collapse them into a single
%% init_graphics action since the source runs them back-to-back.
%% ----------------------------------------------------------------------------

initial_state(state(init, 0, 0, 0)).


%% ----------------------------------------------------------------------------
%% Field accessors / functional updates
%% ----------------------------------------------------------------------------

st_phase(state(P,_,_,_),    P).
st_page(state(_,P,_,_),     P).
st_tiles(state(_,_,T,_),    T).
st_lines(state(_,_,_,L),    L).

set_phase(state(_,P,T,L),  Ph, state(Ph,P,T,L)).
set_page(state(Ph,_,T,L),  P,  state(Ph,P,T,L)).
set_tiles(state(Ph,P,_,L), T,  state(Ph,P,T,L)).
set_lines(state(Ph,P,T,_), L,  state(Ph,P,T,L)).


%% ----------------------------------------------------------------------------
%% Domain constants matching the source
%% ----------------------------------------------------------------------------

num_pages(12).            %% C1 = 4 .. 15
tiles_per_page(17).       %% C2 = 8 .. 24
lines_per_page(150).      %% Line = 149 DOWNTO 0


%% ----------------------------------------------------------------------------
%% Action vocabulary
%% ----------------------------------------------------------------------------

action(init_graphics).    %% InitEGA + GraphMode + NEW S[8..24]
                          %% (FRACPLOT.MOD lines 56-71)
action(load_tile).        %% one iteration of FOR C2 := 8 TO 24:
                          %% LoadSquare(S[C2]^).  TilesLoaded += 1.
action(open_page).        %% all 17 tiles loaded; FIO.Create(SQ###.PRN)
                          %% advances phase to emitting; LinesEmitted := 0.
action(emit_line).        %% one iteration of FOR Line := 149 TO 0:
                          %% dither, plot, pack CBuf/YBuf/MBuf,
                          %% FIO.WrStr/WrBin x 3.  LinesEmitted += 1.
action(close_page).       %% all 150 lines emitted; FIO.Close(.PRN);
                          %% advances PageIdx (line 165, end of inner FOR).
action(begin_next_page).  %% return to loading phase for the next C1
                          %% iteration; TilesLoaded := 0.
action(form_feed).        %% terminating tail at FRACPLOT.MOD lines
                          %% 168-170: FIO.WrChar(14C); FIO.Close(...).


%% ----------------------------------------------------------------------------
%% Guards
%% ----------------------------------------------------------------------------

guard(init_graphics, S) :-
    st_phase(S, init).

guard(load_tile, S) :-
    st_phase(S, loading),
    st_tiles(S, T),
    tiles_per_page(K),
    T < K.

guard(open_page, S) :-
    st_phase(S, loading),
    st_tiles(S, T),
    tiles_per_page(K),
    T >= K.

guard(emit_line, S) :-
    st_phase(S, emitting),
    st_lines(S, L),
    lines_per_page(K),
    L < K.

guard(close_page, S) :-
    st_phase(S, emitting),
    st_lines(S, L),
    lines_per_page(K),
    L >= K.

%% After close_page the source's outer FOR C1 loop either iterates
%% (begin_next_page) or completes (form_feed).
guard(begin_next_page, S) :-
    st_phase(S, between_pages),
    st_page(S, P),
    num_pages(K),
    P < K.

guard(form_feed, S) :-
    st_phase(S, between_pages),
    st_page(S, P),
    num_pages(K),
    P >= K.


%% ----------------------------------------------------------------------------
%% Update functions
%% ----------------------------------------------------------------------------

step(init_graphics, S0, S2) :-
    %% Move to loading phase for the first page; counters reset.
    set_phase(S0, loading, S1),
    set_tiles(S1, 0, S2).

step(load_tile, S0, S1) :-
    st_tiles(S0, T0),
    T1 is T0 + 1,
    set_tiles(S0, T1, S1).

step(open_page, S0, S2) :-
    set_phase(S0, emitting, S1),
    set_lines(S1, 0, S2).

step(emit_line, S0, S1) :-
    st_lines(S0, L0),
    L1 is L0 + 1,
    set_lines(S0, L1, S1).

step(close_page, S0, S2) :-
    set_phase(S0, between_pages, S1),
    st_page(S1, P0),
    P1 is P0 + 1,
    set_page(S1, P1, S2).

step(begin_next_page, S0, S2) :-
    set_phase(S0, loading, S1),
    set_tiles(S1, 0, S2).

step(form_feed, S0, S1) :-
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
%%   %% Skeleton of one full page using one tile per page and one line
%%   %% per page (override the defaults via a fresh starting state):
%%   ?- run([ init_graphics, load_tile, open_page,
%%            emit_line, close_page, form_feed ],
%%          state(init, 0, 0, 0), S),
%%      st_phase(S, P), st_page(S, Pg).
%%   P = done, Pg = 1.
%%   %% (only meaningful if num_pages, tiles_per_page, lines_per_page
%%   %%  are all 1; otherwise the schedule must run to its true bounds.)
%%
%%   %% Open_page can't fire until 17 tiles are loaded.
%%   ?- initial_state(S0),
%%      run([ init_graphics, load_tile ], S0, S1),
%%      \+ trans(open_page, S1, _).
%%   true.
%%
%%   %% Form_feed can't fire while pages remain.
%%   ?- initial_state(S0),
%%      run([ init_graphics ], S0, S1),
%%      \+ trans(form_feed, S1, _).
%%   true.
%% ----------------------------------------------------------------------------
