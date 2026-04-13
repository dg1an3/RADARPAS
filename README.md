# RetroEevorg Archive

Synthetic git repository built from the RetroEevorg software archive (1984-2024).

Each branch represents a software family. Each commit represents a dated snapshot.

## Quick Overview

The archive contains multiple generations of software, transitioning from 8-bit BASIC to Turbo Pascal, Modula-2, C++, and eventually .NET/Java.

- **radar/** (1985–1992): **RADARPAS** - A commercial radar terminal for Ellason E300/E250 systems. Evolved from Turbo Pascal monolith to modular TopSpeed Modula-2.
- **eevorg/** (1987–2007): **EEVORG** - Cellular automata research exploring the "edge of chaos" (entropy 0.5) using genetic algorithms.
- **ssm/** (1986–1996): **Spreadsheet Management System** - A custom spreadsheet engine with formula evaluation.
- **thewheel/** (1990–2000): **theWheel** - Knowledge visualization using spreading activation networks and visual graph browsing.
- **kb/**: **Knowledge Base** - RDF/Turtle semantic metadata describing the archive's structure, modules, and functions. Queryable via Prolog.
- **cogmap/** (1996): **Cognitive Map** - Web-based knowledge mapping experiments.
- **gdem/** (1984–1985): **Graphical Data Entry Manager** - Mapping tools for radar overlays.
- **egalib-math/**: Custom EGA graphics and mathematical utility libraries.
- **misc/**: Miscellaneous projects including Browsee, Pic-Analysis, and TURING samples.
- **bqtourn/**: Tournament bracket and scoring software.

## Archive Contents

### radar/ -- E300PC / RADARPAS (1985-1992)

Original Pascal and MODULA-2 code for the E300/E250 radar (see http://ewradar.com/)

This is some very old code written when I was 15 years old. I still have a version that runs on a DOS simulator (though it only shows canned data).

**GDEM (Graphical Data Entry Manager)**

- GDEM 1.0 was a line-based digital map/geographic data entry and editing tool.
- GDEM's input was a set of coordinates manually entered from chart derived measurements. Protractor coordinates. Acetate.
- GDEM would output a binary formatted map, based on a pre-defined schema, using a third party EEPROM reader that Arnold had found.
- GDEM 1.0 was implemented as 300 lines of Commodore BASIC, which Derek had used with the eighth grade PET computers. DATA statements. GOSUBs.
- DG was paid $200 in 1984 to produce GDEM 1.0. The development was mostly in the spring and summer.
- GDEM Version 2.0 was imagined as having graphical preview capabilities. But E300PC happened instead.

**RADARPAS**

- RADARPAS was the name of the Turbo Pascal program that implemented the E300PC 1.0 product. Hardware PC.
- RADARPAS's input was data sent from the E300 radar system. It would interact with the system over a modem, and then receive the current radar feed.
- RADARPAS graphics library allowed visualization of radar images with a map overlay.
- Implemented in Turbo Pascal. EGA graphics. Hayes Racal-Vadic modem. Graphics, Communication, Control, and GUI modules. Functions. Interrupts.
- DG was paid $600 in 1985 to produce RADARPAS. This gave Ellason rights to sell as many copies as he wanted.
- DG made RADARPAS 2.0 with save and load options. The upgrade to 2.0 earned Derek $800 each.
- Storm cell recognition algorithm for automatic weather detection.
- Greensville trip. Auto programming.
- E300RX extensions 1990. Lawrenceburg TX.
- E250Term 1991 and ISR (Interrupt Service Routine).
- TopSpeed Modula-2 port -- the Pascal codebase was migrated to Modula-2 for better modularity and separate compilation.
- Dynamic camera model 1997 and orthorectification.
- ERDAS plugin architecture.
- Nelder-Mead simplex optimization for parameter fitting.
- Forstner-like operator and tie point extraction for image registration.

**24 dated snapshots** spanning the full evolution from Turbo Pascal to TopSpeed Modula-2:
- `1985xxxx E300PC Demo` -- earliest demo version
- `19870412-19870512` -- RADARPAS RadioTx, Tennterm variants (Pascal)
- `19871102 RADAR MOD Pas2Mod2` -- the Pascal-to-Modula-2 conversion
- `19880226-19890101` -- SN8801, RADIO, Tenn, Rad1dot1, 2dot1 releases
- `19880815 RADAR MOD` -- major Modula-2 release with full module set
- `19890316-19890326` -- RS811A interface, sweep display (assembly + Modula-2)
- `19910104-19910309` -- RADARDB, E250Term
- `19921021-19921228` -- Testchan, RADIO, AUTO system, final releases

### eevorg/ -- EEVORG Cellular Automata (1987-2007)

- Cellular automata evolved toward entropy 0.5 -- the edge of chaos.
- Rule space search using genetic algorithms.
- Originated as a Turbo Pascal project, later ported to C++ and then .NET.

### ssm/ -- Spreadsheet Management System (1986-1996)

- Custom spreadsheet engine with formula evaluation.
- Pascal and Modula-2 implementations spanning a decade of evolution.
- Financial and accounting applications.

### thewheel/ -- theWheel (1990-2000)

- Spreading activation networks -- knowledge as navigable space.
- Visual knowledge browser with coolbar/treeview navigation.
- Multiple generations: theWheel, wlXxx, theWheel-CoolDraw, theWheel2000.

### cogmap/ -- Cognitive Map (1996)

- Early web-based knowledge mapping experiments.
- HTML-based reference maps and link structures.

### gdem/ and gdem-eme/ -- GDEM and EME

- Graphical Data Entry Manager source and related tools.
- Geographic/map data editing for radar overlay generation.

### egalib-math/ -- EGA Library and Math

- Graphics library routines and mathematical utilities.
- Supporting code for the radar display system.

### misc/ -- Miscellaneous

- Pic-Analysis (1989) -- image analysis tools.
- browsee (2000) -- web browsing experiment.
- Other small utilities and experiments.

### bqtourn/ -- BQ Tournament

- Tournament bracket/scoring software.

### kb/ -- Knowledge Base

- RDF Turtle and Prolog-format semantic metadata for the RADARPAS project.
- Machine-readable descriptions of the archive contents.

### documents/

- PDF documentation and historical records.

## Building RADARPAS

The original RADARPAS source can be compiled with FreePascal. See [BUILD.md](BUILD.md) for instructions.

```bash
# Quick start with Docker
./build.sh

# Or with FreePascal installed locally
make
```

## License

The original software is Copyright (C) 1987 D. G. Lane. All rights reserved.
