# HackRF NOAA APT Satellite Image Receiver

A software-defined radio (SDR) application for receiving NOAA weather satellite APT (Automatic Picture Transmission) images using HackRF One, based on signal processing concepts from the RADARPAS codebase.

## Overview

This project implements a complete NOAA APT satellite image receiver chain:

1. **SDR Interface** - HackRF One or file-based input (WAV/IQ)
2. **FM Demodulation** - Multiple demodulation algorithms (polar, quadrature, PLL)
3. **APT Decoding** - Sync detection, line extraction, telemetry parsing
4. **Image Reconstruction** - Channel separation, enhancement, false color composites
5. **Satellite Tracking** - SGP4 orbit propagation, pass prediction, Doppler correction

## NOAA Satellites Supported

| Satellite | Frequency | NORAD ID | Status |
|-----------|-----------|----------|--------|
| NOAA-15   | 137.6200 MHz | 25338 | Active |
| NOAA-18   | 137.9125 MHz | 28654 | Active |
| NOAA-19   | 137.1000 MHz | 33591 | Active |

## Building

Requires .NET 8.0 SDK:

```bash
cd hackrf-noaa
dotnet build
```

## Usage

### Interactive Mode

```bash
dotnet run
```

Commands:
- `receive` or `r` - Start receiving (add `sim` for simulation mode)
- `file <path>` or `f` - Process a WAV file recording
- `predict` or `p` - Show upcoming satellite passes
- `satellite <15|18|19>` or `s` - Select satellite
- `location <lat> <lon> <alt>` or `l` - Set ground station location
- `output <dir>` or `o` - Set output directory
- `help` or `h` - Show help
- `quit` or `q` - Exit

### Command Line

```bash
# Process a WAV file
dotnet run -- --file recording.wav --satellite 19 --output ./images

# Show help
dotnet run -- --help
```

## Architecture

### Based on RADARPAS

This project draws inspiration from the RADARPAS radar terminal system (1988-1992):

- **DSP Module** - Uses lookup table patterns from RADARPAS `SWEEP.MOD` and `E250DRAW.MOD`
- **Compression** - Implements RLE compression based on RADARPAS `COMPR.MOD`
- **Display** - Terminal interface inspired by RADARPAS `SCREENHA.MOD`
- **Analysis** - Bearing/velocity calculations from RADARPAS `ANALYSIS.MOD`

### Module Structure

```
src/
├── CoreTypes.fs        - Type definitions, units of measure
├── DSP.fs              - FFT, filtering, windowing, resampling
├── HackRFInterface.fs  - SDR hardware abstraction
├── FMDemodulator.fs    - FM demodulation algorithms
├── APTDecoder.fs       - APT sync detection and line decoding
├── ImageReconstructor.fs - Image assembly and enhancement
├── SatelliteTracker.fs - Orbit propagation and pass prediction
├── Compression.fs      - RLE and LZ compression
└── Program.fs          - Main application and CLI
```

## Signal Processing Chain

```
HackRF (2 MSPS IQ)
    → Channel Filter (40 kHz BW)
    → Decimation (÷45)
    → FM Demodulation
    → Resample to 11025 Hz
    → Subcarrier Demod (2400 Hz AM)
    → APT Sync Detection
    → Line Extraction
    → Image Assembly
    → Enhancement & Export
```

## APT Signal Format

Each APT line (transmitted at 2 lines/second) contains:

| Section | Width | Description |
|---------|-------|-------------|
| Sync A | 39 | 1040 Hz tone (7 cycles) |
| Space A | 47 | Minute markers |
| Image A | 909 | Visible/AVHRR channel |
| Telemetry A | 45 | Calibration wedges |
| Sync B | 39 | 832 Hz tone (7 cycles) |
| Space B | 47 | Minute markers |
| Image B | 909 | Infrared channel |
| Telemetry B | 45 | Calibration wedges |
| **Total** | **2080** | pixels per line |

## Output Formats

- **PGM** - Grayscale images (visible and infrared channels)
- **PPM** - Color composites (false color, temperature map)
- **APT** - Compressed native format with metadata

## Image Enhancement

- Histogram equalization
- Median filter noise reduction
- Unsharp mask sharpening
- Gamma correction
- Linear percentile stretch
- Telemetry-based calibration

## Requirements

- .NET 8.0 SDK
- HackRF One (optional - can use WAV files)
- libhackrf (for hardware mode)
- Antenna suitable for 137 MHz reception

## Dependencies

- MathNet.Numerics - Numerical computing
- SixLabors.ImageSharp - Image processing
- Spectre.Console - Terminal UI

## License

Part of the RADARPAS project. See repository root for license information.

## References

- [NOAA APT Signal Specification](https://www.sigidwiki.com/wiki/Automatic_Picture_Transmission_(APT))
- [NOAA KLM User's Guide](https://www.ncei.noaa.gov/products/polar-orbiter-products)
- [SGP4 Orbit Propagation](https://celestrak.org/NORAD/documentation/)
- [RADARPAS Original Documentation](../documents/)
