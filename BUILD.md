# RADARPAS - FreePascal Build Instructions

This document describes how to build the RADARPAS software using FreePascal in a Docker container.

## About

RADARPAS (Radar Terminal in Pascal) is historical software from 1988, originally written in Turbo Pascal by D. G. Lane for the Ellason E300 Radar Terminal system. This was commercial software that interfaced with radar systems via RS-232 modems and displayed radar imagery using EGA graphics.

## Prerequisites

- Docker installed on your system
- Basic familiarity with command line

## Quick Start

### Build and Run (Automated)

```bash
./build.sh
```

This will:
1. Build the Docker image with FreePascal
2. Compile the program inside the container
3. Show instructions for running

### Manual Build Steps

1. **Build the Docker image:**
   ```bash
   docker build -t radarpas-fpc:latest .
   ```

2. **Compile the program:**
   ```bash
   docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make
   ```

3. **Run the program:**
   ```bash
   docker run --rm -it -v "$(pwd):/build" radarpas-fpc:latest ./radarpas
   ```

### Using Make Targets

Inside the container, you can use various make targets:

```bash
# Build everything
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make

# Build and run
docker run --rm -it -v "$(pwd):/build" radarpas-fpc:latest make run

# Clean build artifacts
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make clean

# Show build information
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make info

# Show help
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make help
```

### Interactive Development

To get a shell inside the container for development:

```bash
docker run --rm -it -v "$(pwd):/build" radarpas-fpc:latest /bin/bash
```

Then inside the container:
```bash
make        # Build
make run    # Run
make clean  # Clean
```

## About the Conversion

### Original Code

The original `19880114 RADAR.PAS` was written for:
- **Turbo Pascal 3.0+** (Borland)
- **MS-DOS** operating system
- **EGA graphics** (640x350, 16 colors)
- **RS-232 serial** communication
- **Direct hardware access** (port I/O, interrupts)

### FreePascal Version

The `radar.pas` file is a FreePascal-compatible version that:
- Uses FreePascal's Turbo Pascal mode (`{$MODE TP}`)
- Stubs out hardware-specific code (port access, interrupts)
- Provides a demonstration build that compiles but doesn't require 1980s hardware
- Maintains the structure and spirit of the original code

### Limitations

This build is primarily for:
- **Historical preservation** - keeping the code compilable
- **Educational purposes** - studying 1980s programming techniques
- **Demonstration** - showing what the software did

It will NOT:
- Display actual radar imagery (no EGA hardware)
- Connect to modems (no RS-232 implementation)
- Run the full original functionality (hardware dependencies)

## Technical Details

### Compiler

- **FreePascal Compiler (FPC)** version 3.2.0+
- Turbo Pascal compatibility mode
- Optimizations enabled

### Original Features

The original software included:
- Real-time radar image reception via 2400 baud modem
- EGA graphics display with map overlays
- Picture storage and retrieval
- Multiple radar station management
- Configurable tilt, range, and gain settings
- Screen dump to dot matrix printers

### Build Environment

- Base: Ubuntu 22.04
- Compiler: FreePascal (fpc)
- Build system: GNU Make

## Files

- `Dockerfile` - Container definition
- `Makefile` - Build configuration
- `build.sh` - Automated build script
- `radar.pas` - FreePascal-compatible source
- `19880114 RADAR.PAS` - Original Turbo Pascal source (preserved)

## Historical Context

This software was written when the author was a teenager, sold commercially for $600-800 in 1985-1987, and represents the state of the art for PC-based radar terminal software of that era. It demonstrates:

- Direct hardware programming
- Real-time data processing
- Telecommunications
- Custom graphics rendering
- File management
- User interface design

All on an 8088/8086 PC with 640KB RAM, no hard drive, and a 4.77MHz processor.

## License

The original software is Copyright (C) 1987 D. G. Lane. All rights reserved.

This build configuration and FreePascal port are provided for historical and educational purposes.
