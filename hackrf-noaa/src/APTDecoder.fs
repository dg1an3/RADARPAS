/// APT (Automatic Picture Transmission) Decoder Module
/// Decodes NOAA weather satellite APT signals into image lines
/// Inspired by RADARPAS sweep and analysis patterns
module HackRF.NOAA.APTDecoder

open System
open System.Collections.Generic
open HackRF.NOAA.CoreTypes
open HackRF.NOAA.DSP

// ============================================================================
// APT Frame Structure
// ============================================================================

/// APT line structure (following NOAA specification)
/// Total: 2080 words (pixels) per line at 4160 words/second
/// Line rate: 2 lines/second (0.5 seconds per line)
module APTFrame =
    /// Sync A pulse train (39 words)
    let syncAWidth = 39

    /// Space A (47 words) - minute markers
    let spaceAWidth = 47

    /// Image A data (909 words) - visible/AVHRR channel
    let imageAWidth = 909

    /// Telemetry A (45 words) - calibration wedges
    let telemetryAWidth = 45

    /// Sync B pulse train (39 words)
    let syncBWidth = 39

    /// Space B (47 words)
    let spaceBWidth = 47

    /// Image B data (909 words) - infrared channel
    let imageBWidth = 909

    /// Telemetry B (45 words)
    let telemetryBWidth = 45

    /// Total words per line
    let totalWidth = syncAWidth + spaceAWidth + imageAWidth + telemetryAWidth +
                     syncBWidth + spaceBWidth + imageBWidth + telemetryBWidth  // = 2080

    /// Starting offsets for each section
    let syncAStart = 0
    let spaceAStart = syncAWidth
    let imageAStart = spaceAStart + spaceAWidth
    let telemetryAStart = imageAStart + imageAWidth
    let syncBStart = telemetryAStart + telemetryAWidth
    let spaceBStart = syncBStart + syncBWidth
    let imageBStart = spaceBStart + spaceBWidth
    let telemetryBStart = imageBStart + imageBWidth

    /// Standard sample rate for APT audio
    let standardSampleRate = 11025.0<Hz>

    /// Samples per line at 11025 Hz
    let samplesPerLine = 5512  // 11025 / 2

// ============================================================================
// Sync Pattern Detection
// ============================================================================

/// Sync pattern (7 cycles of 1040 Hz square wave for Sync A)
/// Represented as +1/-1 samples at 4160 samples/second word rate
let private generateSyncACorrelator (samplesPerWord: float) : float[] =
    // Sync A: 7 cycles at 1040 Hz = 7 peaks in 39 words
    // Pattern: low-high alternating at word rate / 2
    let wordCount = APTFrame.syncAWidth
    let sampleCount = int (float wordCount * samplesPerWord)

    Array.init sampleCount (fun i ->
        let wordPos = float i / samplesPerWord
        let cyclePos = wordPos / (39.0 / 7.0)  // 7 cycles in 39 words
        if sin (2.0 * Math.PI * cyclePos) > 0.0 then 1.0 else -1.0)

/// Sync B pattern (7 cycles of 832 Hz)
let private generateSyncBCorrelator (samplesPerWord: float) : float[] =
    let wordCount = APTFrame.syncBWidth
    let sampleCount = int (float wordCount * samplesPerWord)

    Array.init sampleCount (fun i ->
        let wordPos = float i / samplesPerWord
        let cyclePos = wordPos / (39.0 / 7.0)
        // Sync B is inverse of Sync A
        if sin (2.0 * Math.PI * cyclePos) > 0.0 then -1.0 else 1.0)

/// Sync detector state
type SyncDetector =
    { SamplesPerWord: float
      SyncAPattern: float[]
      SyncBPattern: float[]
      mutable Buffer: float[]
      mutable BufferIndex: int
      Threshold: float }

    static member Create(sampleRate: float<Hz>) =
        let samplesPerWord = float sampleRate / 4160.0  // 4160 words/second
        let syncA = generateSyncACorrelator samplesPerWord
        let syncB = generateSyncBCorrelator samplesPerWord

        { SamplesPerWord = samplesPerWord
          SyncAPattern = syncA
          SyncBPattern = syncB
          Buffer = Array.zeroCreate (syncA.Length * 2)
          BufferIndex = 0
          Threshold = 0.7 }  // Correlation threshold (0-1)

    /// Correlate buffer with sync pattern
    member private this.Correlate(pattern: float[], startIndex: int) : float =
        let mutable sum = 0.0
        let mutable energy = 0.0

        for i in 0 .. pattern.Length - 1 do
            let bufIdx = (startIndex + i) % this.Buffer.Length
            sum <- sum + this.Buffer.[bufIdx] * pattern.[i]
            energy <- energy + this.Buffer.[bufIdx] * this.Buffer.[bufIdx]

        let normEnergy = sqrt energy
        if normEnergy > 0.001 then
            sum / (normEnergy * sqrt (float pattern.Length))
        else
            0.0

    /// Add sample and check for sync
    member this.ProcessSample(sample: float) : (bool * bool * float) =
        // Add to circular buffer
        this.Buffer.[this.BufferIndex] <- sample
        let searchIndex = (this.BufferIndex - this.SyncAPattern.Length + 1 + this.Buffer.Length) % this.Buffer.Length

        // Check correlations
        let corrA = this.Correlate(this.SyncAPattern, searchIndex)
        let corrB = this.Correlate(this.SyncBPattern, searchIndex)

        this.BufferIndex <- (this.BufferIndex + 1) % this.Buffer.Length

        let foundA = abs corrA > this.Threshold
        let foundB = abs corrB > this.Threshold

        (foundA, foundB, max (abs corrA) (abs corrB))

// ============================================================================
// APT Line Decoder
// ============================================================================

/// Decoder state
type DecoderState =
    | WaitingForSync     // Looking for first sync pulse
    | CollectingLine     // Collecting samples for current line
    | LineComplete       // Full line received

/// APT Line decoder
type APTLineDecoder =
    { SampleRate: float<Hz>
      SamplesPerLine: int
      SamplesPerWord: float
      SyncDetector: SyncDetector
      mutable State: DecoderState
      mutable LineBuffer: float[]
      mutable LineBufferIndex: int
      mutable CurrentLineNumber: int
      mutable SyncConfidence: float
      mutable LastSyncType: char  // 'A' or 'B'
      mutable LinesDecoded: int }

    static member Create(sampleRate: float<Hz>) =
        let samplesPerLine = int (float sampleRate / 2.0)  // 2 lines/second
        let samplesPerWord = float sampleRate / 4160.0

        { SampleRate = sampleRate
          SamplesPerLine = samplesPerLine
          SamplesPerWord = samplesPerWord
          SyncDetector = SyncDetector.Create(sampleRate)
          State = WaitingForSync
          LineBuffer = Array.zeroCreate samplesPerLine
          LineBufferIndex = 0
          CurrentLineNumber = 0
          SyncConfidence = 0.0
          LastSyncType = ' '
          LinesDecoded = 0 }

    /// Convert samples to pixel values (0-255)
    member private this.SamplesToPixels(samples: float[], startIdx: int, count: int) : byte[] =
        let pixelCount = int (float count / this.SamplesPerWord)
        let pixels = Array.zeroCreate pixelCount

        for p in 0 .. pixelCount - 1 do
            let sampleStart = startIdx + int (float p * this.SamplesPerWord)
            let sampleEnd = startIdx + int (float (p + 1) * this.SamplesPerWord)

            // Average samples for this pixel
            let mutable sum = 0.0
            let mutable count = 0
            for s in sampleStart .. min (sampleEnd - 1) (samples.Length - 1) do
                if s >= 0 && s < samples.Length then
                    sum <- sum + samples.[s]
                    count <- count + 1

            let avg = if count > 0 then sum / float count else 0.0

            // Scale to 0-255 (assuming input is -1 to +1 or 0 to 1)
            let scaled = int ((avg + 1.0) * 127.5)
            pixels.[p] <- byte (max 0 (min 255 scaled))

        pixels

    /// Extract APT line data from sample buffer
    member this.ExtractLine() : APTLine option =
        if this.LineBufferIndex < this.SamplesPerLine then
            None
        else
            // Calculate pixel positions
            let wordToSample w = int (float w * this.SamplesPerWord)

            // Extract channel A image
            let imageAStart = wordToSample APTFrame.imageAStart
            let imageASamples = wordToSample APTFrame.imageAWidth
            let channelA = this.SamplesToPixels(this.LineBuffer, imageAStart, imageASamples)

            // Extract channel B image
            let imageBStart = wordToSample APTFrame.imageBStart
            let imageBSamples = wordToSample APTFrame.imageBWidth
            let channelB = this.SamplesToPixels(this.LineBuffer, imageBStart, imageBSamples)

            // Extract telemetry
            let telAStart = wordToSample APTFrame.telemetryAStart
            let telASamples = wordToSample APTFrame.telemetryAWidth
            let telemetryA = this.SamplesToPixels(this.LineBuffer, telAStart, telASamples)

            let telBStart = wordToSample APTFrame.telemetryBStart
            let telBSamples = wordToSample APTFrame.telemetryBWidth
            let telemetryB = this.SamplesToPixels(this.LineBuffer, telBStart, telBSamples)

            Some {
                LineNumber = this.CurrentLineNumber
                Timestamp = DateTime.UtcNow
                ChannelA = channelA
                ChannelB = channelB
                TelemetryA = telemetryA
                TelemetryB = telemetryB
                Quality = {
                    SNR = 0.0<dB>
                    SignalStrength = 0.0<dB>
                    FrequencyOffset = 0.0<Hz>
                    BitErrorRate = 0.0
                    SyncConfidence = this.SyncConfidence
                }
            }

    /// Process a block of demodulated samples
    member this.Process(samples: float[]) : APTLine list =
        let lines = ResizeArray<APTLine>()

        for i in 0 .. samples.Length - 1 do
            match this.State with
            | WaitingForSync ->
                let (foundA, foundB, confidence) = this.SyncDetector.ProcessSample(samples.[i])
                if foundA || foundB then
                    this.State <- CollectingLine
                    this.LineBufferIndex <- 0
                    this.SyncConfidence <- confidence
                    this.LastSyncType <- if foundA then 'A' else 'B'

            | CollectingLine ->
                if this.LineBufferIndex < this.SamplesPerLine then
                    this.LineBuffer.[this.LineBufferIndex] <- samples.[i]
                    this.LineBufferIndex <- this.LineBufferIndex + 1

                    // Also check for sync (to track timing)
                    let (foundA, foundB, confidence) = this.SyncDetector.ProcessSample(samples.[i])
                    if (foundA || foundB) && confidence > this.SyncConfidence then
                        this.SyncConfidence <- confidence

                    if this.LineBufferIndex >= this.SamplesPerLine then
                        this.State <- LineComplete
                else
                    this.State <- LineComplete

            | LineComplete ->
                // Extract the line
                match this.ExtractLine() with
                | Some line ->
                    lines.Add(line)
                    this.LinesDecoded <- this.LinesDecoded + 1
                | None -> ()

                // Reset for next line
                this.CurrentLineNumber <- this.CurrentLineNumber + 1
                this.State <- WaitingForSync

        lines |> List.ofSeq

// ============================================================================
// APT Frame Timing and Synchronization
// ============================================================================

/// Frame synchronizer for maintaining line alignment
type FrameSynchronizer =
    { SampleRate: float<Hz>
      mutable ExpectedLineStart: int64
      mutable ActualLineStart: int64
      mutable SampleCounter: int64
      mutable DriftRate: float        // Samples drift per line
      mutable TotalDrift: float
      LineLength: int64 }

    static member Create(sampleRate: float<Hz>) =
        let lineLength = int64 (float sampleRate / 2.0)  // 2 lines/second
        { SampleRate = sampleRate
          ExpectedLineStart = 0L
          ActualLineStart = 0L
          SampleCounter = 0L
          DriftRate = 0.0
          TotalDrift = 0.0
          LineLength = lineLength }

    /// Update synchronizer when sync is detected
    member this.OnSyncDetected(sampleOffset: int) =
        this.ActualLineStart <- this.SampleCounter + int64 sampleOffset

        // Calculate drift
        let drift = float (this.ActualLineStart - this.ExpectedLineStart)
        this.TotalDrift <- this.TotalDrift + drift

        // Update drift rate estimate (low-pass filtered)
        this.DriftRate <- this.DriftRate * 0.9 + (drift / float this.LineLength) * 0.1

        // Update expected position for next line
        this.ExpectedLineStart <- this.ActualLineStart + this.LineLength

    /// Advance sample counter
    member this.AdvanceSamples(count: int) =
        this.SampleCounter <- this.SampleCounter + int64 count

    /// Get predicted next sync position
    member this.PredictNextSync() : int64 =
        this.ExpectedLineStart + int64 (this.DriftRate * float this.LineLength)

// ============================================================================
// Telemetry Decoder
// ============================================================================

/// NOAA APT telemetry wedge decoder
module TelemetryDecoder =

    /// Telemetry wedge calibration values
    type TelemetryWedge =
        { Wedge1: byte    // Reference black
          Wedge2: byte
          Wedge3: byte
          Wedge4: byte
          Wedge5: byte
          Wedge6: byte
          Wedge7: byte
          Wedge8: byte    // Reference white
          PatchTemp: byte // Patch temperature
          BackScan: byte  // Back scan reference
          SpaceView: byte // Space view reference
          ChannelId: byte // Channel identification wedge
          Wedge13: byte
          Wedge14: byte
          Wedge15: byte
          Zero: byte }    // Zero modulation reference

    /// Decode telemetry from frame
    let decodeTelemetry (telemetryPixels: byte[]) : TelemetryWedge option =
        if telemetryPixels.Length < 45 then
            None
        else
            // Each wedge is ~3 pixels wide (45 pixels / 16 wedges ≈ 2.8)
            let getWedge idx =
                let start = idx * 3
                if start + 2 < telemetryPixels.Length then
                    // Average 3 pixels for wedge value
                    let sum = int telemetryPixels.[start] +
                              int telemetryPixels.[start + 1] +
                              int telemetryPixels.[start + 2]
                    byte (sum / 3)
                else
                    0uy

            Some {
                Wedge1 = getWedge 0
                Wedge2 = getWedge 1
                Wedge3 = getWedge 2
                Wedge4 = getWedge 3
                Wedge5 = getWedge 4
                Wedge6 = getWedge 5
                Wedge7 = getWedge 6
                Wedge8 = getWedge 7
                PatchTemp = getWedge 8
                BackScan = getWedge 9
                SpaceView = getWedge 10
                ChannelId = getWedge 11
                Wedge13 = getWedge 12
                Wedge14 = getWedge 13
                Wedge15 = getWedge 14
                Zero = getWedge 15
            }

    /// Calibrate pixel values using telemetry
    let calibratePixels (telemetry: TelemetryWedge) (pixels: byte[]) : byte[] =
        // Linear calibration using reference black (wedge1) and white (wedge8)
        let black = float telemetry.Wedge1
        let white = float telemetry.Wedge8
        let range = white - black

        if range > 10.0 then
            pixels |> Array.map (fun p ->
                let normalized = (float p - black) / range
                let clamped = max 0.0 (min 1.0 normalized)
                byte (clamped * 255.0))
        else
            pixels

// ============================================================================
// Complete APT Decoder Pipeline
// ============================================================================

/// Full APT decoding pipeline
type APTDecoderPipeline =
    { LineDecoder: APTLineDecoder
      FrameSync: FrameSynchronizer
      mutable DecodedLines: APTLine list
      mutable TelemetryA: TelemetryDecoder.TelemetryWedge option
      mutable TelemetryB: TelemetryDecoder.TelemetryWedge option
      mutable IsReceiving: bool }

    static member Create(sampleRate: float<Hz>) =
        { LineDecoder = APTLineDecoder.Create(sampleRate)
          FrameSync = FrameSynchronizer.Create(sampleRate)
          DecodedLines = []
          TelemetryA = None
          TelemetryB = None
          IsReceiving = false }

    /// Process demodulated audio samples
    member this.Process(samples: float[]) : APTLine list =
        let newLines = this.LineDecoder.Process samples

        // Update telemetry from new lines
        for line in newLines do
            match TelemetryDecoder.decodeTelemetry line.TelemetryA with
            | Some tel -> this.TelemetryA <- Some tel
            | None -> ()

            match TelemetryDecoder.decodeTelemetry line.TelemetryB with
            | Some tel -> this.TelemetryB <- Some tel
            | None -> ()

        // Apply calibration if telemetry available
        let calibratedLines =
            newLines |> List.map (fun line ->
                let calA =
                    match this.TelemetryA with
                    | Some tel -> TelemetryDecoder.calibratePixels tel line.ChannelA
                    | None -> line.ChannelA

                let calB =
                    match this.TelemetryB with
                    | Some tel -> TelemetryDecoder.calibratePixels tel line.ChannelB
                    | None -> line.ChannelB

                { line with ChannelA = calA; ChannelB = calB })

        this.DecodedLines <- this.DecodedLines @ calibratedLines
        this.FrameSync.AdvanceSamples(samples.Length)

        if calibratedLines.Length > 0 then
            this.IsReceiving <- true

        calibratedLines

    /// Get total lines decoded
    member this.TotalLines = this.DecodedLines.Length

    /// Reset decoder state
    member this.Reset() =
        this.LineDecoder.State <- WaitingForSync
        this.LineDecoder.LineBufferIndex <- 0
        this.LineDecoder.CurrentLineNumber <- 0
        this.DecodedLines <- []
        this.TelemetryA <- None
        this.TelemetryB <- None
        this.IsReceiving <- false
