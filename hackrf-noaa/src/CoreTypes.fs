/// Core types for HackRF NOAA APT Satellite Receiver
/// Based on RADARPAS signal processing concepts
module HackRF.NOAA.CoreTypes

open System

// ============================================================================
// Units of Measure (following RADARPAS F# translation pattern)
// ============================================================================

[<Measure>] type Hz       // Frequency in Hertz
[<Measure>] type kHz      // Frequency in kilohertz
[<Measure>] type MHz      // Frequency in megahertz
[<Measure>] type dB       // Decibels for signal strength
[<Measure>] type sample   // Sample count
[<Measure>] type second   // Time in seconds
[<Measure>] type degree   // Angle in degrees
[<Measure>] type radian   // Angle in radians
[<Measure>] type km       // Distance in kilometers
[<Measure>] type pixel    // Image pixel count

// Unit conversions
let hzToKHz (f: float<Hz>) : float<kHz> = f / 1000.0<Hz/kHz>
let kHzToHz (f: float<kHz>) : float<Hz> = f * 1000.0<Hz/kHz>
let mHzToHz (f: float<MHz>) : float<Hz> = f * 1000000.0<Hz/MHz>
let degToRad (d: float<degree>) : float<radian> = d * (Math.PI / 180.0)<radian/degree>
let radToDeg (r: float<radian>) : float<degree> = r * (180.0 / Math.PI)<degree/radian>

// ============================================================================
// NOAA Satellite Configuration
// ============================================================================

/// NOAA satellite identifiers with their APT frequencies
type NOAASatellite =
    | NOAA15
    | NOAA18
    | NOAA19

    member this.Frequency : float<MHz> =
        match this with
        | NOAA15 -> 137.62<MHz>
        | NOAA18 -> 137.9125<MHz>
        | NOAA19 -> 137.1<MHz>

    member this.Name : string =
        match this with
        | NOAA15 -> "NOAA-15"
        | NOAA18 -> "NOAA-18"
        | NOAA19 -> "NOAA-19"

    member this.NoradId : int =
        match this with
        | NOAA15 -> 25338
        | NOAA18 -> 28654
        | NOAA19 -> 33591

/// APT (Automatic Picture Transmission) signal parameters
/// Reference: NOAA KLM User's Guide
module APTConstants =
    /// APT line rate: 2 lines per second (120 LPM)
    let lineRate = 2.0<Hz>

    /// Subcarrier frequency for APT
    let subcarrierFrequency = 2400.0<Hz>

    /// Total samples per line at 11025 Hz sample rate
    let samplesPerLine = 5512<sample>

    /// Words (pixels) per line
    let wordsPerLine = 2080<pixel>

    /// Sync A marker (channel A - visible/AVHRR)
    let syncAPattern = [| 0; 0; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0;
                          255; 255; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0;
                          255; 255; 0; 0; 255; 255; 0; 0 |]

    /// Sync B marker (channel B - infrared)
    let syncBPattern = [| 255; 255; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255;
                          0; 0; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255; 0; 0; 255; 255;
                          0; 0; 255; 255; 0; 0 |]

    /// Image A width (visible channel)
    let imageAWidth = 909<pixel>

    /// Image B width (infrared channel)
    let imageBWidth = 909<pixel>

    /// Telemetry frame width
    let telemetryWidth = 45<pixel>

    /// Minutes marker width
    let minutesMarkerWidth = 47<pixel>

    /// Sync marker width
    let syncWidth = 39<pixel>

    /// Space data width
    let spaceWidth = 47<pixel>

// ============================================================================
// SDR and Signal Processing Types
// ============================================================================

/// Complex sample for IQ data (In-phase and Quadrature)
[<Struct>]
type ComplexSample =
    { I: float32   // In-phase component
      Q: float32 } // Quadrature component

    static member Zero = { I = 0.0f; Q = 0.0f }

    static member (+) (a: ComplexSample, b: ComplexSample) =
        { I = a.I + b.I; Q = a.Q + b.Q }

    static member (-) (a: ComplexSample, b: ComplexSample) =
        { I = a.I - b.I; Q = a.Q - b.Q }

    static member (*) (a: ComplexSample, b: ComplexSample) =
        { I = a.I * b.I - a.Q * b.Q
          Q = a.I * b.Q + a.Q * b.I }

    static member (*) (a: ComplexSample, s: float32) =
        { I = a.I * s; Q = a.Q * s }

    member this.Magnitude = sqrt(this.I * this.I + this.Q * this.Q)

    member this.Phase = atan2 this.Q this.I

    member this.Conjugate = { I = this.I; Q = -this.Q }

/// HackRF device configuration
type HackRFConfig =
    { CenterFrequency: float<MHz>
      SampleRate: float<Hz>
      LNAGain: int<dB>           // 0-40 dB in 8 dB steps
      VGAGain: int<dB>           // 0-62 dB in 2 dB steps
      AmpEnable: bool            // Enable 14 dB RF amplifier
      AntennaPort: bool }        // Antenna port power

    static member Default =
        { CenterFrequency = 137.5<MHz>    // Center for NOAA band
          SampleRate = 2000000.0<Hz>      // 2 MSPS
          LNAGain = 32<dB>
          VGAGain = 40<dB>
          AmpEnable = true
          AntennaPort = false }

/// Receiver state machine states
type ReceiverState =
    | Idle
    | Acquiring          // Looking for signal
    | Synchronizing      // Found signal, looking for sync
    | Receiving          // Actively receiving image
    | Processing         // Post-processing received image
    | Error of string

/// Signal quality metrics (inspired by RADARPAS Q-response)
type SignalQuality =
    { SNR: float<dB>              // Signal-to-noise ratio
      SignalStrength: float<dB>   // RSSI
      FrequencyOffset: float<Hz>  // Doppler + oscillator error
      BitErrorRate: float         // Estimated BER
      SyncConfidence: float }     // 0.0 - 1.0

    static member Empty =
        { SNR = -100.0<dB>
          SignalStrength = -100.0<dB>
          FrequencyOffset = 0.0<Hz>
          BitErrorRate = 1.0
          SyncConfidence = 0.0 }

/// APT line data structure
type APTLine =
    { LineNumber: int
      Timestamp: DateTime
      ChannelA: byte[]      // 909 pixels - visible/AVHRR
      ChannelB: byte[]      // 909 pixels - infrared
      TelemetryA: byte[]    // 45 pixels
      TelemetryB: byte[]    // 45 pixels
      Quality: SignalQuality }

/// Complete APT image
type APTImage =
    { Satellite: NOAASatellite
      StartTime: DateTime
      EndTime: DateTime
      Lines: APTLine list
      ChannelAData: byte[,]   // 2D array [line, pixel]
      ChannelBData: byte[,]
      Metadata: Map<string, string> }

// ============================================================================
// Buffer Types (following RADARPAS serial buffer pattern)
// ============================================================================

/// Circular buffer for streaming samples
type CircularBuffer<'T> =
    { Buffer: 'T[]
      mutable WritePos: int
      mutable ReadPos: int
      Capacity: int }

    static member Create(capacity: int, defaultValue: 'T) =
        { Buffer = Array.create capacity defaultValue
          WritePos = 0
          ReadPos = 0
          Capacity = capacity }

    member this.Available =
        let diff = this.WritePos - this.ReadPos
        if diff >= 0 then diff else diff + this.Capacity

    member this.Free =
        this.Capacity - this.Available - 1

    member this.Write(data: 'T[], offset: int, count: int) =
        let mutable written = 0
        for i in 0 .. count - 1 do
            if this.Free > 0 then
                this.Buffer.[this.WritePos] <- data.[offset + i]
                this.WritePos <- (this.WritePos + 1) % this.Capacity
                written <- written + 1
        written

    member this.Read(data: 'T[], offset: int, count: int) =
        let mutable read = 0
        let toRead = min count this.Available
        for i in 0 .. toRead - 1 do
            data.[offset + i] <- this.Buffer.[this.ReadPos]
            this.ReadPos <- (this.ReadPos + 1) % this.Capacity
            read <- read + 1
        read

// ============================================================================
// Configuration and Settings
// ============================================================================

/// Application configuration
type ReceiverConfig =
    { Satellite: NOAASatellite
      OutputDirectory: string
      SaveRawIQ: bool
      SaveWav: bool
      SavePng: bool
      AutoGain: bool
      DopplerCorrection: bool
      GroundStation: GroundStationLocation option }

and GroundStationLocation =
    { Latitude: float<degree>
      Longitude: float<degree>
      Altitude: float<km> }

    static member Default =
        { Latitude = 0.0<degree>
          Longitude = 0.0<degree>
          Altitude = 0.0<km> }

/// Result type for operations (following F# RADARPAS pattern)
type ReceiverResult<'T> =
    | Success of 'T
    | Failure of string

module ReceiverResult =
    let map f = function
        | Success x -> Success (f x)
        | Failure e -> Failure e

    let bind f = function
        | Success x -> f x
        | Failure e -> Failure e

    let toOption = function
        | Success x -> Some x
        | Failure _ -> None
