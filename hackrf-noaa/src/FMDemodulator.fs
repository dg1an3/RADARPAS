/// FM Demodulator Module for NOAA APT Signal Processing
/// Implements various FM demodulation techniques for SDR
module HackRF.NOAA.FMDemodulator

open System
open HackRF.NOAA.CoreTypes
open HackRF.NOAA.DSP

// ============================================================================
// FM Demodulation Algorithms
// ============================================================================

/// FM demodulation method selection
type FMDemodMethod =
    | PolarDiscriminator      // Classic polar discriminator (atan2 derivative)
    | QuadratureDemod         // Quadrature (IQ) demodulator
    | PhaseLocked             // PLL-based demodulator
    | FastArctan              // Optimized arctan approximation

/// FM Demodulator state
type FMDemodulator =
    { Method: FMDemodMethod
      SampleRate: float<Hz>
      Deviation: float<Hz>          // FM deviation (+/- Hz)
      mutable PreviousSample: ComplexSample
      mutable PreviousPhase: float
      // PLL state
      mutable PLLPhase: float
      mutable PLLFrequency: float
      PLLBandwidth: float
      PLLDamping: float }

    /// Create a new FM demodulator
    static member Create(method: FMDemodMethod, sampleRate: float<Hz>, deviation: float<Hz>) =
        { Method = method
          SampleRate = sampleRate
          Deviation = deviation
          PreviousSample = ComplexSample.Zero
          PreviousPhase = 0.0
          PLLPhase = 0.0
          PLLFrequency = 0.0
          PLLBandwidth = 0.01    // Normalized bandwidth
          PLLDamping = 0.707 }   // Critical damping

// ============================================================================
// Polar Discriminator (Phase Derivative)
// ============================================================================

/// Classic FM demodulation using phase derivative
/// Output is proportional to instantaneous frequency
let private demodPolarDiscriminator (demod: FMDemodulator) (samples: ComplexSample[]) : float[] =
    let output = Array.zeroCreate samples.Length
    let normFactor = float demod.SampleRate / (2.0 * Math.PI * float demod.Deviation)

    for i in 0 .. samples.Length - 1 do
        let current = samples.[i]
        let phase = atan2 (float current.Q) (float current.I)

        // Phase difference (handle wraparound)
        let mutable phaseDiff = phase - demod.PreviousPhase
        if phaseDiff > Math.PI then
            phaseDiff <- phaseDiff - 2.0 * Math.PI
        elif phaseDiff < -Math.PI then
            phaseDiff <- phaseDiff + 2.0 * Math.PI

        output.[i] <- phaseDiff * normFactor
        demod.PreviousPhase <- phase

    output

// ============================================================================
// Quadrature Demodulator
// ============================================================================

/// Fast quadrature demodulator (no atan, approximation)
/// Uses: d(phase)/dt ≈ (I * dQ/dt - Q * dI/dt) / (I² + Q²)
let private demodQuadrature (demod: FMDemodulator) (samples: ComplexSample[]) : float[] =
    let output = Array.zeroCreate samples.Length
    let normFactor = float demod.SampleRate / (2.0 * Math.PI * float demod.Deviation)

    for i in 0 .. samples.Length - 1 do
        let current = samples.[i]
        let prev = if i > 0 then samples.[i-1] else demod.PreviousSample

        // Compute derivative approximation
        let dI = float current.I - float prev.I
        let dQ = float current.Q - float prev.Q

        // Cross product gives instantaneous frequency
        let iVal = float current.I
        let qVal = float current.Q
        let magnitude = iVal * iVal + qVal * qVal

        if magnitude > 1e-10 then
            output.[i] <- (iVal * dQ - qVal * dI) / magnitude * normFactor
        else
            output.[i] <- 0.0

    demod.PreviousSample <- samples.[samples.Length - 1]
    output

// ============================================================================
// Fast Arctan Approximation
// ============================================================================

/// Fast arctan2 approximation (max error ~0.07 radians)
let private fastAtan2 (y: float) (x: float) =
    let absY = abs y + 1e-10
    let r, angle =
        if x >= 0.0 then
            let r = (x - absY) / (x + absY)
            r, Math.PI / 4.0 - Math.PI / 4.0 * r
        else
            let r = (x + absY) / (absY - x)
            r, 3.0 * Math.PI / 4.0 - Math.PI / 4.0 * r
    if y < 0.0 then -angle else angle

/// FM demodulation using fast arctan approximation
let private demodFastArctan (demod: FMDemodulator) (samples: ComplexSample[]) : float[] =
    let output = Array.zeroCreate samples.Length
    let normFactor = float demod.SampleRate / (2.0 * Math.PI * float demod.Deviation)

    for i in 0 .. samples.Length - 1 do
        let current = samples.[i]
        let phase = fastAtan2 (float current.Q) (float current.I)

        let mutable phaseDiff = phase - demod.PreviousPhase
        if phaseDiff > Math.PI then
            phaseDiff <- phaseDiff - 2.0 * Math.PI
        elif phaseDiff < -Math.PI then
            phaseDiff <- phaseDiff + 2.0 * Math.PI

        output.[i] <- phaseDiff * normFactor
        demod.PreviousPhase <- phase

    output

// ============================================================================
// Phase-Locked Loop Demodulator
// ============================================================================

/// PLL-based FM demodulator
/// Better performance in low SNR conditions
let private demodPLL (demod: FMDemodulator) (samples: ComplexSample[]) : float[] =
    let output = Array.zeroCreate samples.Length

    // PLL loop filter coefficients (2nd order loop)
    let wn = demod.PLLBandwidth * 2.0 * Math.PI  // Natural frequency
    let zeta = demod.PLLDamping
    let k1 = 2.0 * zeta * wn      // Proportional gain
    let k2 = wn * wn              // Integral gain

    let normFactor = float demod.SampleRate / float demod.Deviation

    for i in 0 .. samples.Length - 1 do
        let current = samples.[i]

        // Generate local oscillator
        let loI = cos demod.PLLPhase
        let loQ = sin demod.PLLPhase

        // Phase detector (multiply and take Q of result for small angle approx)
        let phaseError = float current.I * loQ - float current.Q * loI

        // Loop filter (PI controller)
        demod.PLLFrequency <- demod.PLLFrequency + k2 * phaseError
        let phaseCorrection = k1 * phaseError + demod.PLLFrequency

        // NCO update
        demod.PLLPhase <- demod.PLLPhase + phaseCorrection
        if demod.PLLPhase > Math.PI then
            demod.PLLPhase <- demod.PLLPhase - 2.0 * Math.PI
        elif demod.PLLPhase < -Math.PI then
            demod.PLLPhase <- demod.PLLPhase + 2.0 * Math.PI

        // Output is the frequency correction (proportional to modulation)
        output.[i] <- phaseCorrection * normFactor

    output

// ============================================================================
// Main Demodulation Interface
// ============================================================================

/// Demodulate FM signal
let demodulate (demod: FMDemodulator) (samples: ComplexSample[]) : float[] =
    match demod.Method with
    | PolarDiscriminator -> demodPolarDiscriminator demod samples
    | QuadratureDemod -> demodQuadrature demod samples
    | FastArctan -> demodFastArctan demod samples
    | PhaseLocked -> demodPLL demod samples

// ============================================================================
// FM Demodulation Processing Chain
// ============================================================================

/// Complete FM demodulation chain with filtering and decimation
type FMReceiver =
    { Demodulator: FMDemodulator
      InputFilter: ComplexFIRFilter         // Channel selection filter
      OutputFilter: FIRFilter               // Audio/baseband filter
      DecimationFactor: int
      mutable DecimationCounter: int }

    /// Create FM receiver for NOAA APT
    /// Input: 2 MSPS IQ from HackRF
    /// Output: 11025 Hz baseband audio
    static member CreateForNOAA(inputSampleRate: float<Hz>) =
        let deviation = 17000.0<Hz>  // NOAA APT FM deviation is ±17 kHz

        // Input filter: 40 kHz bandwidth for APT signal
        let inputFilterCoeffs = designFirFilter LowPass (float inputSampleRate) 20000.0 0.0 127 Blackman
        let inputFilter = ComplexFIRFilter.Create(inputFilterCoeffs)

        // Decimation: 2 MSPS -> ~44100 Hz (decimate by ~45)
        let decimFactor = int (float inputSampleRate / 44100.0)

        // Demodulator at intermediate rate
        let intermediateRate = inputSampleRate / float decimFactor
        let demod = FMDemodulator.Create(QuadratureDemod, intermediateRate, deviation)

        // Output filter: 15 kHz low-pass for APT baseband
        let outputFilterCoeffs = designFirFilter LowPass (float intermediateRate) 6000.0 0.0 63 Hamming
        let outputFilter = FIRFilter.Create(outputFilterCoeffs)

        { Demodulator = demod
          InputFilter = inputFilter
          OutputFilter = outputFilter
          DecimationFactor = decimFactor
          DecimationCounter = 0 }

    /// Process a block of IQ samples
    member this.Process(samples: ComplexSample[]) : float[] =
        // Apply input filter
        let filtered = this.InputFilter.Process samples

        // Decimate
        let decimated = decimate this.DecimationFactor filtered

        // FM demodulate
        let demodulated = demodulate this.Demodulator decimated

        // Apply output filter
        this.OutputFilter.Process demodulated

// ============================================================================
// Automatic Frequency Control (AFC)
// ============================================================================

/// AFC for tracking Doppler shift and oscillator drift
type AFC =
    { mutable CenterFrequency: float<Hz>
      mutable FrequencyOffset: float<Hz>
      LoopBandwidth: float
      MaxOffset: float<Hz> }

    static member Create(centerFreq: float<Hz>, bandwidth: float, maxOffset: float<Hz>) =
        { CenterFrequency = centerFreq
          FrequencyOffset = 0.0<Hz>
          LoopBandwidth = bandwidth
          MaxOffset = maxOffset }

    /// Update AFC based on demodulator output
    member this.Update(demodOutput: float[]) =
        // Estimate DC offset in demodulated signal (indicates frequency error)
        let dcOffset = Array.average demodOutput

        // Apply low-pass filtering to frequency estimate
        let correction = dcOffset * this.LoopBandwidth * 1.0<Hz>

        this.FrequencyOffset <- this.FrequencyOffset + correction

        // Clamp to maximum offset
        if this.FrequencyOffset > this.MaxOffset then
            this.FrequencyOffset <- this.MaxOffset
        elif this.FrequencyOffset < -this.MaxOffset then
            this.FrequencyOffset <- -this.MaxOffset

        this.FrequencyOffset

    /// Get corrected center frequency
    member this.CorrectedFrequency =
        this.CenterFrequency + this.FrequencyOffset

// ============================================================================
// NOAA APT Subcarrier Demodulator (AM on 2400 Hz)
// ============================================================================

/// Demodulate AM on 2400 Hz subcarrier
type APTSubcarrierDemod =
    { SampleRate: float<Hz>
      SubcarrierFreq: float<Hz>
      mutable NCOPhase: float
      LowPassFilter: FIRFilter }

    static member Create(sampleRate: float<Hz>) =
        let subcarrier = 2400.0<Hz>
        // Low-pass filter for AM envelope detection (< 1200 Hz)
        let lpfCoeffs = designFirFilter LowPass (float sampleRate) 1200.0 0.0 63 Hamming
        { SampleRate = sampleRate
          SubcarrierFreq = subcarrier
          NCOPhase = 0.0
          LowPassFilter = FIRFilter.Create(lpfCoeffs) }

    /// Demodulate subcarrier to extract pixel values
    member this.Process(samples: float[]) : float[] =
        let phaseIncrement = 2.0 * Math.PI * float this.SubcarrierFreq / float this.SampleRate

        // Mix to baseband (both I and Q for better AM detection)
        let mixed = Array.zeroCreate samples.Length

        for i in 0 .. samples.Length - 1 do
            // Multiply by 2400 Hz carrier (coherent detection)
            let loI = cos this.NCOPhase
            let loQ = sin this.NCOPhase

            let mixedI = samples.[i] * loI
            let mixedQ = samples.[i] * loQ

            // Envelope = sqrt(I² + Q²), but we can use abs for AM
            mixed.[i] <- sqrt (mixedI * mixedI + mixedQ * mixedQ)

            this.NCOPhase <- this.NCOPhase + phaseIncrement
            if this.NCOPhase > 2.0 * Math.PI then
                this.NCOPhase <- this.NCOPhase - 2.0 * Math.PI

        // Low-pass filter to remove 2*subcarrier component
        this.LowPassFilter.Process mixed

// ============================================================================
// Complete APT Demodulation Chain
// ============================================================================

/// Full APT signal demodulation chain
type APTDemodulationChain =
    { FMReceiver: FMReceiver
      SubcarrierDemod: APTSubcarrierDemod
      AFC: AFC
      OutputSampleRate: float<Hz>
      Resampler: Resampler option }

    /// Create full demod chain for HackRF -> APT pixels
    static member Create(inputSampleRate: float<Hz>, satellite: NOAASatellite) =
        let fmReceiver = FMReceiver.CreateForNOAA(inputSampleRate)
        let intermediateSampleRate = inputSampleRate / float fmReceiver.DecimationFactor

        // Resample from intermediate rate to standard 11025 Hz for APT
        let targetRate = 11025.0<Hz>
        let resampler =
            if abs (float intermediateSampleRate - float targetRate) > 100.0 then
                // Need resampling
                let gcd a b =
                    let rec loop a b = if b = 0 then a else loop b (a % b)
                    loop (abs a) (abs b)

                let iRate = int intermediateSampleRate
                let oRate = int targetRate
                let g = gcd iRate oRate
                Some (Resampler.Create(oRate / g, iRate / g, 64))
            else
                None

        let subcarrierDemod = APTSubcarrierDemod.Create(targetRate)

        let centerFreq = satellite.Frequency |> mHzToHz
        let afc = AFC.Create(centerFreq, 0.001, 10000.0<Hz>)

        { FMReceiver = fmReceiver
          SubcarrierDemod = subcarrierDemod
          AFC = afc
          OutputSampleRate = targetRate
          Resampler = resampler }

    /// Process IQ samples to APT pixel values
    member this.Process(iqSamples: ComplexSample[]) : float[] =
        // FM demodulate
        let fmOutput = this.FMReceiver.Process iqSamples

        // Update AFC
        this.AFC.Update fmOutput |> ignore

        // Resample if needed
        let resampled =
            match this.Resampler with
            | Some r -> r.Resample fmOutput
            | None -> fmOutput

        // AM demodulate subcarrier
        this.SubcarrierDemod.Process resampled
