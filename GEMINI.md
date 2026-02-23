# RADARPAS / RetroEevorg Archive Context

Historical software archive (1984–2024) preserving the early works of Derek G. Lane. This repository is a synthetic git history built from dated snapshots of several distinct software families.

## Project Overview

The archive contains multiple generations of software, transitioning from 8-bit BASIC to Turbo Pascal, Modula-2, C++, and eventually .NET/Java.

### Key Software Families
- **radar/** (1985–1992): **RADARPAS** - A commercial radar terminal for Ellason E300/E250 systems. Evolved from Turbo Pascal monolith to modular TopSpeed Modula-2 with assembly ISRs.
- **eevorg/** (1987–2007): **EEVORG** - Cellular automata research exploring the "edge of chaos" (entropy 0.5) using genetic algorithms.
- **ssm/** (1986–1996): **Spreadsheet Management System** - A custom spreadsheet engine with formula evaluation.
- **thewheel/** (1990–2000): **theWheel** - Knowledge visualization using spreading activation networks and visual graph browsing.
- **cogmap/** (1996): **Cognitive Map** - Web-based knowledge mapping experiments.
- **gdem/** (1984–1985): **Graphical Data Entry Manager** - Mapping tools for radar overlays.
- **egalib-math/**: Custom EGA graphics and mathematical utility libraries.
- **misc/**: Miscellaneous projects including Browsee, Pic-Analysis, and TURING samples.
- **bqtourn/**: Tournament bracket and scoring software.
- **kb/**: **Knowledge Base** - RDF/Turtle semantic metadata describing the archive's structure, modules, and functions. Queryable via Prolog.
- **documents/**: PDF documentation and historical records.

## Technical Environment

### Build System
The primary modern entry point is a FreePascal-compatible port of RADARPAS.

- **Compiler**: FreePascal (FPC) with Turbo Pascal compatibility mode (`-Mtp`).
- **Commands**:
  - `make`: Compiles `radar/radar.pas` into the `radarpas` executable.
  - `make run`: Builds and executes the program.
  - `make clean`: Removes build artifacts.
  - `./build.sh`: Runs the build process within a Docker container (requires Docker).
- **Docker**: A `Dockerfile` is provided for a consistent FreePascal build environment.

### Original Hardware Context
- **CPU**: Intel 8088/8086 (PC/XT/AT).
- **Graphics**: EGA (640x350, 16 colors).
- **Communication**: RS-232 serial via 2400 baud modems.
- **Operating System**: MS-DOS.

*Note: The modern `radar/radar.pas` stubs out direct hardware access (ports, interrupts, EGA memory) to remain compilable on modern systems.*

## Knowledge Base (kb/)

RDF/Turtle ontology describing the archive's modules, functions, types, and files. Queryable via Prolog (`kb/radarpas_kb.pl`):

```prolog
?- find_function('InitEGA', Description).
?- function_category('Graphics & Display', FuncName).
?- version_lineage('E300PC 3.1', Parent).
```

## Development Conventions

- **Historical Preservation**: Original source files (e.g., `19880114 RADAR.PAS`) are preserved exactly as they were. Do not modify these unless explicitly instructed for a specific experiment.
- **Dated Snapshots**: The directory structure uses `YYYYMMDD Name/` patterns. Each represents a significant state in the software's lineage.
- **Metadata-First**: Refer to `kb/` for structural understanding. The RDF data in `kb/*.ttl` defines the relationships between modules, functions, and versions.
- **Prolog Integration**: Use `kb/radarpas_kb.pl` with SWI-Prolog to query the software's architecture (e.g., `find_function('InitEGA', D).`).

## Key Facts

- Compiler flags: `-Mtp` (Turbo Pascal mode), `-O2`, `-vh`, `-l`
- The 24 radar snapshots track evolution from Turbo Pascal 3.0 to TopSpeed Modula-2 with x86 assembly ISRs
- Original hardware context: 8088 PC, 640KB RAM, EGA graphics, 2400 baud modem
- License: Copyright (C) 1987 D. G. Lane. All rights reserved.

## Key Files
- `README.md`: High-level archive description and history.
- `BUILD.md`: Detailed instructions for the FreePascal/Docker build.
- `CLAUDE.md`: Brief technical guide for AI assistants.
- `Makefile`: Build automation.
- `radar/radar.pas`: The modern, compilable entry point.
- `kb/ontology.ttl`: The semantic schema for the project's metadata.

## Usage Guidelines
When analyzing or extending this project:
1. **Respect Lineage**: Acknowledge the transition from Pascal to Modula-2 (approx. Nov 1987) as a major architectural shift.
2. **Hardware Awareness**: Remember that original code assumes direct memory and port I/O which will fail on modern OSs without emulation or stubs.
3. **Semantic Queries**: If unsure about a function's purpose or where it is called, check the `kb/` semantic data.
