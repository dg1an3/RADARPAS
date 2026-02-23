# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Historical software archive (1984–2024) preserved as a synthetic git repository built from dated snapshots. The main project is **RADARPAS** — a radar terminal for the Ellason E300/E250 system, written by Derek G. Lane starting at age 15. The repo also contains EEVORG (cellular automata), SSM (spreadsheet engine), theWheel (spreading activation networks), and several other sub-projects.

Each top-level directory is a software family. Each dated subdirectory is a snapshot.

## Build Commands

```bash
# FreePascal build (compiles radar/radar.pas → radarpas executable)
make                # build
make run            # build and run
make clean          # remove .o, .ppu, radarpas

# Docker build (no local FPC required)
./build.sh          # automated: builds image + compiles
# Or manually:
docker build -t radarpas-fpc:latest .
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make
```

The modern `radar/radar.pas` is a FreePascal-compatible stub — it compiles but stubs out hardware (EGA, RS-232, interrupts). The historical originals (e.g., `radar/19880114 RADAR.PAS`) are preserved unmodified.

## Architecture

- **radar/** (1985–1992): **RADARPAS** - A commercial radar terminal for Ellason E300/E250 systems. Evolved from Turbo Pascal monolith to modular TopSpeed Modula-2 with assembly ISRs. Key transition: 19871102 Pas2Mod2.
- **eevorg/** (1987–2007): **EEVORG** - Cellular automata research exploring the "edge of chaos" (entropy 0.5) using genetic algorithms.
- **ssm/** (1986–1996): **Spreadsheet Management System** - A custom spreadsheet engine with formula evaluation. Pascal/Modula-2, 26+ releases.
- **thewheel/** (1990–2000): **theWheel** - Knowledge visualization using spreading activation networks and visual graph browsing. C++/MFC.
- **cogmap/** (1996): **Cognitive Map** - Web-based knowledge mapping experiments.
- **gdem/** (1984–1985): **Graphical Data Entry Manager** - Mapping tools for radar overlays.
- **egalib-math/**: Custom EGA graphics library and mathematical utility libraries.
- **misc/**: Miscellaneous projects including Browsee, Pic-Analysis, and TURING samples.
- **bqtourn/**: Tournament bracket and scoring software.
- **kb/**: **Knowledge Base** - RDF/Turtle semantic metadata describing the archive's structure, modules, and functions. Queryable via Prolog.
- **documents/**: PDF documentation and historical records.

## Knowledge Base (kb/)

RDF/Turtle ontology describing the archive's modules, functions, types, and files. Queryable via Prolog (`kb/radarpas_kb.pl`):

```prolog
?- find_function('InitEGA', Description).
?- function_category('Graphics & Display', FuncName).
?- version_lineage('E300PC 3.1', Parent).
```

## Key Facts

- Compiler flags: `-Mtp` (Turbo Pascal mode), `-O2`, `-vh`, `-l`
- The 24 radar snapshots track evolution from Turbo Pascal 3.0 to TopSpeed Modula-2 with x86 assembly ISRs
- Original hardware context: 8088 PC, 640KB RAM, EGA graphics, 2400 baud modem
- License: Copyright (C) 1987 D. G. Lane. All rights reserved.
