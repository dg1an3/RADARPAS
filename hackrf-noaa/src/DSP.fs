/// Digital Signal Processing Module for HackRF NOAA Receiver
/// Provides FFT, filtering, and resampling operations
/// Inspired by RADARPAS sweep generation and trigonometric table patterns
module HackRF.NOAA.DSP

open System
open HackRF.NOAA.CoreTypes

// ============================================================================
// Trigonometric Lookup Tables (following RADARPAS E250DRAW.MOD pattern)
// ============================================================================

/// Pre-computed sine table for fast lookup (360 entries like RADARPAS)
let private sinTable : float[] =
    Array.init 360 (fun i -> sin (float i * Math.PI / 180.0))

/// Pre-computed cosine table
let private cosTable : float[] =
    Array.init 360 (fun i -> cos (float i * Math.PI / 180.0))

/// Fast sine lookup (degree input)
let fastSin (angle: int) =
    let normalizedAngle = ((angle % 360) + 360) % 360
    sinTable.[normalizedAngle]

/// Fast cosine lookup (degree input)
let fastCos (angle: int) =
    let normalizedAngle = ((angle % 360) + 360) % 360
    cosTable.[normalizedAngle]

// ============================================================================
// FFT Implementation (Cooley-Tukey Radix-2 DIT)
// ============================================================================

/// Check if n is power of 2
let isPowerOfTwo n =
    n > 0 && (n &&& (n - 1)) = 0

/// Get next power of 2 >= n
let nextPowerOfTwo n =
    let mutable result = 1
    while result < n do
        result <- result <<< 1
    result

/// Bit reversal for FFT
let private bitReverse (n: int) (bits: int) =
    let mutable result = 0
    let mutable value = n
    for _ in 0 .. bits - 1 do
        result <- (result <<< 1) ||| (value &&& 1)
        value <- value >>> 1
    result

/// In-place Cooley-Tukey FFT
let fft (samples: ComplexSample[]) =
    let n = samples.Length
    if not (isPowerOfTwo n) then
        failwith "FFT size must be power of 2"

    let bits = int (Math.Log(float n, 2.0))

    // Bit-reversal permutation
    let result = Array.copy samples
    for i in 0 .. n - 1 do
        let j = bitReverse i bits
        if i < j then
            let temp = result.[i]
            result.[i] <- result.[j]
            result.[j] <- temp

    // Cooley-Tukey butterflies
    let mutable size = 2
    while size <= n do
        let halfSize = size / 2
        let tableStep = n / size

        for i in 0 .. halfSize - 1 do
            let angle = -2.0 * Math.PI * float i / float size
            let tw = { I = float32 (cos angle); Q = float32 (sin angle) }

            let mutable j = i
            while j < n do
                let k = j + halfSize
                let temp = result.[k] * tw
                result.[k] <- result.[j] - temp
                result.[j] <- result.[j] + temp
                j <- j + size

        size <- size * 2

    result

/// Inverse FFT
let ifft (spectrum: ComplexSample[]) =
    let n = spectrum.Length
    // Conjugate input
    let conjugated = spectrum |> Array.map (fun s -> s.Conjugate)
    // Forward FFT
    let transformed = fft conjugated
    // Conjugate and scale
    transformed |> Array.map (fun s -> { I = s.I / float32 n; Q = -s.Q / float32 n })

// ============================================================================
// Window Functions
// ============================================================================

type WindowType =
    | Rectangular
    | Hamming
    | Hanning
    | Blackman
    | BlackmanHarris
    | Kaiser of float  // Beta parameter

/// Generate window coefficients
let generateWindow (windowType: WindowType) (length: int) : float[] =
    let n = float length
    match windowType with
    | Rectangular ->
        Array.create length 1.0

    | Hamming ->
        Array.init length (fun i ->
            0.54 - 0.46 * cos (2.0 * Math.PI * float i / (n - 1.0)))

    | Hanning ->
        Array.init length (fun i ->
            0.5 * (1.0 - cos (2.0 * Math.PI * float i / (n - 1.0))))

    | Blackman ->
        Array.init length (fun i ->
            let x = 2.0 * Math.PI * float i / (n - 1.0)
            0.42 - 0.5 * cos x + 0.08 * cos (2.0 * x))

    | BlackmanHarris ->
        Array.init length (fun i ->
            let x = 2.0 * Math.PI * float i / (n - 1.0)
            0.35875 - 0.48829 * cos x + 0.14128 * cos (2.0 * x) - 0.01168 * cos (3.0 * x))

    | Kaiser beta ->
        // Approximate Bessel I0 function
        let besselI0 x =
            let mutable sum = 1.0
            let mutable term = 1.0
            for k in 1 .. 20 do
                term <- term * (x / 2.0 / float k) * (x / 2.0 / float k)
                sum <- sum + term
            sum

        let denominator = besselI0 (Math.PI * beta)
        Array.init length (fun i ->
            let ratio = 2.0 * float i / (n - 1.0) - 1.0
            let arg = Math.PI * beta * sqrt (1.0 - ratio * ratio)
            besselI0 arg / denominator)

/// Apply window to samples
let applyWindow (window: float[]) (samples: ComplexSample[]) =
    Array.mapi (fun i s ->
        { I = s.I * float32 window.[i]
          Q = s.Q * float32 window.[i] }) samples

// ============================================================================
// FIR Filter Design
// ============================================================================

type FilterType =
    | LowPass
    | HighPass
    | BandPass
    | BandStop

/// Design FIR filter using windowed sinc method
let designFirFilter
    (filterType: FilterType)
    (sampleRate: float)
    (cutoffLow: float)
    (cutoffHigh: float)
    (numTaps: int)
    (windowType: WindowType) : float[] =

    let normalizedLow = cutoffLow / sampleRate
    let normalizedHigh = cutoffHigh / sampleRate

    // Compute ideal impulse response
    let idealResponse =
        Array.init numTaps (fun i ->
            let n = float i - float (numTaps - 1) / 2.0
            if abs n < 1e-10 then
                match filterType with
                | LowPass -> 2.0 * normalizedLow
                | HighPass -> 1.0 - 2.0 * normalizedLow
                | BandPass -> 2.0 * (normalizedHigh - normalizedLow)
                | BandStop -> 1.0 - 2.0 * (normalizedHigh - normalizedLow)
            else
                match filterType with
                | LowPass ->
                    sin (2.0 * Math.PI * normalizedLow * n) / (Math.PI * n)
                | HighPass ->
                    -sin (2.0 * Math.PI * normalizedLow * n) / (Math.PI * n)
                | BandPass ->
                    let sinHigh = sin (2.0 * Math.PI * normalizedHigh * n) / (Math.PI * n)
                    let sinLow = sin (2.0 * Math.PI * normalizedLow * n) / (Math.PI * n)
                    sinHigh - sinLow
                | BandStop ->
                    let sinHigh = sin (2.0 * Math.PI * normalizedHigh * n) / (Math.PI * n)
                    let sinLow = sin (2.0 * Math.PI * normalizedLow * n) / (Math.PI * n)
                    sinLow - sinHigh)

    // Apply window
    let window = generateWindow windowType numTaps
    Array.mapi (fun i h -> h * window.[i]) idealResponse

/// FIR filter state for streaming processing
type FIRFilter =
    { Coefficients: float[]
      mutable DelayLine: float[]
      mutable DelayIndex: int }

    static member Create(coefficients: float[]) =
        { Coefficients = coefficients
          DelayLine = Array.zeroCreate coefficients.Length
          DelayIndex = 0 }

    /// Process single sample
    member this.ProcessSample(input: float) =
        this.DelayLine.[this.DelayIndex] <- input
        let mutable output = 0.0
        let mutable j = this.DelayIndex
        for i in 0 .. this.Coefficients.Length - 1 do
            output <- output + this.Coefficients.[i] * this.DelayLine.[j]
            j <- j - 1
            if j < 0 then j <- this.Coefficients.Length - 1
        this.DelayIndex <- (this.DelayIndex + 1) % this.Coefficients.Length
        output

    /// Process array of samples
    member this.Process(input: float[]) =
        Array.map this.ProcessSample input

/// Complex FIR filter for IQ data
type ComplexFIRFilter =
    { IFilter: FIRFilter
      QFilter: FIRFilter }

    static member Create(coefficients: float[]) =
        { IFilter = FIRFilter.Create(coefficients)
          QFilter = FIRFilter.Create(coefficients) }

    member this.ProcessSample(input: ComplexSample) =
        { I = float32 (this.IFilter.ProcessSample(float input.I))
          Q = float32 (this.QFilter.ProcessSample(float input.Q)) }

    member this.Process(input: ComplexSample[]) =
        Array.map this.ProcessSample input

// ============================================================================
// Resampling (Polyphase FIR)
// ============================================================================

/// Rational resampler (L/M rate change)
type Resampler =
    { InterpolationFactor: int
      DecimationFactor: int
      Filter: FIRFilter
      mutable PhaseAccumulator: int }

    static member Create(interpFactor: int, decimFactor: int, filterLength: int) =
        // Design anti-aliasing filter
        let cutoff = 0.5 / float (max interpFactor decimFactor)
        let coeffs = designFirFilter LowPass 1.0 cutoff 0.0 filterLength Blackman
        // Scale by interpolation factor
        let scaledCoeffs = coeffs |> Array.map (fun c -> c * float interpFactor)
        { InterpolationFactor = interpFactor
          DecimationFactor = decimFactor
          Filter = FIRFilter.Create(scaledCoeffs)
          PhaseAccumulator = 0 }

    /// Resample a block of data
    member this.Resample(input: float[]) =
        let outputLength = (input.Length * this.InterpolationFactor) / this.DecimationFactor
        let output = Array.zeroCreate outputLength

        let mutable outIdx = 0
        let mutable inIdx = 0
        let mutable phase = this.PhaseAccumulator

        while outIdx < outputLength && inIdx < input.Length do
            // Insert zeros between samples (interpolation)
            if phase % this.InterpolationFactor = 0 then
                ignore (this.Filter.ProcessSample input.[inIdx])
                inIdx <- inIdx + 1
            else
                ignore (this.Filter.ProcessSample 0.0)

            // Output every M samples (decimation)
            if phase % this.DecimationFactor = 0 then
                output.[outIdx] <- this.Filter.ProcessSample 0.0
                outIdx <- outIdx + 1

            phase <- phase + 1
            if phase >= this.InterpolationFactor * this.DecimationFactor then
                phase <- 0

        this.PhaseAccumulator <- phase
        output.[..outIdx-1]

// ============================================================================
// Signal Analysis
// ============================================================================

/// Compute power spectrum (dB)
let powerSpectrum (samples: ComplexSample[]) : float[] =
    let spectrum = fft samples
    spectrum |> Array.map (fun s ->
        let power = float s.I * float s.I + float s.Q * float s.Q
        10.0 * log10 (power + 1e-10))

/// Estimate signal strength (RMS)
let signalStrength (samples: ComplexSample[]) : float<dB> =
    let sumSquares = samples |> Array.sumBy (fun s -> float s.I * float s.I + float s.Q * float s.Q)
    let rms = sqrt (sumSquares / float samples.Length)
    (20.0 * log10 (rms + 1e-10)) * 1.0<dB>

/// Estimate carrier frequency offset using FFT
let estimateFrequencyOffset (samples: ComplexSample[]) (sampleRate: float<Hz>) : float<Hz> =
    let paddedLength = nextPowerOfTwo samples.Length
    let padded = Array.append samples (Array.create (paddedLength - samples.Length) ComplexSample.Zero)

    let windowed = applyWindow (generateWindow Hamming paddedLength) padded
    let spectrum = fft windowed

    // Find peak in spectrum
    let mutable maxIdx = 0
    let mutable maxVal = 0.0f
    for i in 0 .. spectrum.Length - 1 do
        let mag = spectrum.[i].Magnitude
        if mag > maxVal then
            maxVal <- mag
            maxIdx <- i

    // Convert bin to frequency
    let binWidth = sampleRate / float paddedLength
    let offset =
        if maxIdx > paddedLength / 2 then
            float (maxIdx - paddedLength) * float binWidth
        else
            float maxIdx * float binWidth

    offset * 1.0<Hz>

/// Calculate SNR using noise floor estimation
let estimateSNR (samples: ComplexSample[]) (signalBandwidth: float<Hz>) (sampleRate: float<Hz>) : float<dB> =
    let spectrum = powerSpectrum samples

    // Sort spectrum to find noise floor (use lower 25% as noise estimate)
    let sorted = spectrum |> Array.sort
    let noiseFloor = sorted.[sorted.Length / 4]

    // Signal power is the peak
    let signalPeak = spectrum |> Array.max

    (signalPeak - noiseFloor) * 1.0<dB>

// ============================================================================
// Decimation and Mixing (for frequency translation)
// ============================================================================

/// NCO (Numerically Controlled Oscillator) for frequency translation
type NCO =
    { mutable Phase: float
      PhaseIncrement: float }

    static member Create(frequency: float, sampleRate: float) =
        { Phase = 0.0
          PhaseIncrement = 2.0 * Math.PI * frequency / sampleRate }

    member this.NextSample() =
        let sample = { I = float32 (cos this.Phase); Q = float32 (sin this.Phase) }
        this.Phase <- this.Phase + this.PhaseIncrement
        if this.Phase >= 2.0 * Math.PI then
            this.Phase <- this.Phase - 2.0 * Math.PI
        sample

    member this.Mix(input: ComplexSample) =
        let lo = this.NextSample()
        input * lo

    member this.SetFrequency(frequency: float, sampleRate: float) =
        // Keep phase continuous but change frequency
        let newIncrement = 2.0 * Math.PI * frequency / sampleRate
        // Adjust phase to prevent discontinuity
        this.Phase <- this.Phase * (newIncrement / this.PhaseIncrement)
        // Update increment - Note: This is a simplified approach

/// Decimate signal by factor M
let decimate (factor: int) (samples: ComplexSample[]) =
    Array.init (samples.Length / factor) (fun i -> samples.[i * factor])

/// Decimate with anti-aliasing filter
let decimateFiltered (factor: int) (filter: ComplexFIRFilter) (samples: ComplexSample[]) =
    let filtered = filter.Process samples
    decimate factor filtered
