/// HackRF Interface Module
/// Provides abstraction for SDR hardware interaction
/// Based on RADARPAS serial communication patterns (RS.MOD)
module HackRF.NOAA.HackRFInterface

open System
open System.IO
open System.Runtime.InteropServices
open System.Threading
open HackRF.NOAA.CoreTypes

// ============================================================================
// HackRF Native Bindings (libhackrf)
// ============================================================================

/// HackRF error codes
type HackRFError =
    | Success = 0
    | True = 1
    | InvalidParam = -2
    | NotFound = -5
    | Busy = -6
    | NoMem = -11
    | LibUSB = -1000
    | Thread = -1001
    | StreamingThreadErr = -1002
    | StreamingStopped = -1003
    | StreamingExitCalled = -1004
    | Other = -9999

/// Native HackRF library bindings
module NativeHackRF =
    [<Literal>]
    let LibraryName = "libhackrf"

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_init()

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_exit()

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_open(nativeint& device)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_close(nativeint device)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_freq(nativeint device, uint64 freq_hz)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_sample_rate(nativeint device, double freq_hz)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_lna_gain(nativeint device, uint32 value)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_vga_gain(nativeint device, uint32 value)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_amp_enable(nativeint device, uint8 value)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_set_antenna_enable(nativeint device, uint8 value)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_start_rx(nativeint device, nativeint callback, nativeint rx_ctx)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_stop_rx(nativeint device)

    [<DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)>]
    extern int hackrf_is_streaming(nativeint device)

// ============================================================================
// SDR Source Interface (abstraction for HackRF or file playback)
// ============================================================================

/// Interface for SDR data sources
type ISDRSource =
    inherit IDisposable
    abstract member Open: unit -> ReceiverResult<unit>
    abstract member Close: unit -> unit
    abstract member Configure: HackRFConfig -> ReceiverResult<unit>
    abstract member StartReceive: (ComplexSample[] -> unit) -> ReceiverResult<unit>
    abstract member StopReceive: unit -> unit
    abstract member IsStreaming: bool
    abstract member GetConfig: unit -> HackRFConfig

// ============================================================================
// HackRF Hardware Implementation
// ============================================================================

/// HackRF hardware source
type HackRFSource() =
    let mutable deviceHandle = nativeint 0
    let mutable isOpen = false
    let mutable isStreaming = false
    let mutable currentConfig = HackRFConfig.Default
    let mutable sampleCallback: (ComplexSample[] -> unit) option = None

    let sampleBuffer = CircularBuffer<byte>.Create(262144 * 8, 0uy)  // 2MB buffer

    /// Convert signed 8-bit IQ to complex samples
    let convertSamples (data: byte[]) : ComplexSample[] =
        let numSamples = data.Length / 2
        Array.init numSamples (fun i ->
            let iVal = float32 (sbyte data.[i * 2]) / 128.0f
            let qVal = float32 (sbyte data.[i * 2 + 1]) / 128.0f
            { I = iVal; Q = qVal })

    interface ISDRSource with
        member _.Open() =
            try
                let initResult = NativeHackRF.hackrf_init()
                if initResult <> 0 then
                    Failure $"Failed to initialize HackRF library: {initResult}"
                else
                    let mutable handle = nativeint 0
                    let openResult = NativeHackRF.hackrf_open(&handle)
                    if openResult <> 0 then
                        Failure $"Failed to open HackRF device: {openResult}"
                    else
                        deviceHandle <- handle
                        isOpen <- true
                        Success ()
            with ex ->
                Failure $"HackRF exception: {ex.Message}"

        member _.Close() =
            if isStreaming then
                NativeHackRF.hackrf_stop_rx(deviceHandle) |> ignore
                isStreaming <- false
            if isOpen then
                NativeHackRF.hackrf_close(deviceHandle) |> ignore
                NativeHackRF.hackrf_exit() |> ignore
                isOpen <- false

        member _.Configure(config: HackRFConfig) =
            if not isOpen then
                Failure "Device not open"
            else
                try
                    let freqHz = uint64 (float config.CenterFrequency * 1e6)
                    NativeHackRF.hackrf_set_freq(deviceHandle, freqHz) |> ignore

                    NativeHackRF.hackrf_set_sample_rate(deviceHandle, float config.SampleRate) |> ignore

                    NativeHackRF.hackrf_set_lna_gain(deviceHandle, uint32 (int config.LNAGain)) |> ignore
                    NativeHackRF.hackrf_set_vga_gain(deviceHandle, uint32 (int config.VGAGain)) |> ignore

                    let ampVal = if config.AmpEnable then 1uy else 0uy
                    NativeHackRF.hackrf_set_amp_enable(deviceHandle, ampVal) |> ignore

                    let antVal = if config.AntennaPort then 1uy else 0uy
                    NativeHackRF.hackrf_set_antenna_enable(deviceHandle, antVal) |> ignore

                    currentConfig <- config
                    Success ()
                with ex ->
                    Failure $"Configuration error: {ex.Message}"

        member _.StartReceive(callback: ComplexSample[] -> unit) =
            Failure "Native streaming not implemented - use FileSource for testing"

        member _.StopReceive() =
            if isStreaming then
                NativeHackRF.hackrf_stop_rx(deviceHandle) |> ignore
                isStreaming <- false

        member _.IsStreaming = isStreaming

        member _.GetConfig() = currentConfig

    interface IDisposable with
        member this.Dispose() =
            (this :> ISDRSource).Close()

// ============================================================================
// File-based SDR Source (for testing with recorded IQ data)
// ============================================================================

/// Raw IQ file source (for testing/playback)
type FileSDRSource(filePath: string, sampleRate: float<Hz>) =
    let mutable fileStream: FileStream option = None
    let mutable isStreaming = false
    let mutable streamThread: Thread option = None
    let mutable stopRequested = false
    let mutable currentConfig =
        { HackRFConfig.Default with SampleRate = float sampleRate * 1.0<Hz> }

    /// Convert unsigned 8-bit IQ to complex samples (RTL-SDR format)
    let convertU8Samples (data: byte[]) : ComplexSample[] =
        let numSamples = data.Length / 2
        Array.init numSamples (fun i ->
            let iVal = (float32 data.[i * 2] - 127.5f) / 127.5f
            let qVal = (float32 data.[i * 2 + 1] - 127.5f) / 127.5f
            { I = iVal; Q = qVal })

    /// Convert signed 8-bit IQ to complex samples (HackRF format)
    let convertS8Samples (data: byte[]) : ComplexSample[] =
        let numSamples = data.Length / 2
        Array.init numSamples (fun i ->
            let iVal = float32 (sbyte data.[i * 2]) / 128.0f
            let qVal = float32 (sbyte data.[i * 2 + 1]) / 128.0f
            { I = iVal; Q = qVal })

    interface ISDRSource with
        member _.Open() =
            try
                if not (File.Exists filePath) then
                    Failure $"File not found: {filePath}"
                else
                    fileStream <- Some (new FileStream(filePath, FileMode.Open, FileAccess.Read))
                    Success ()
            with ex ->
                Failure $"Failed to open file: {ex.Message}"

        member _.Close() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            match fileStream with
            | Some fs -> fs.Dispose()
            | None -> ()
            fileStream <- None
            isStreaming <- false

        member _.Configure(config: HackRFConfig) =
            currentConfig <- config
            Success ()

        member _.StartReceive(callback: ComplexSample[] -> unit) =
            match fileStream with
            | None -> Failure "File not open"
            | Some fs ->
                stopRequested <- false
                isStreaming <- true

                let blockSize = 262144  // 128K samples (256KB)
                let buffer = Array.zeroCreate<byte> blockSize

                let threadProc() =
                    try
                        while not stopRequested && fs.Position < fs.Length do
                            let bytesRead = fs.Read(buffer, 0, blockSize)
                            if bytesRead > 0 then
                                let samples = convertU8Samples buffer.[..bytesRead-1]
                                callback samples

                            // Simulate real-time by sleeping
                            let sampleCount = bytesRead / 2
                            let durationMs = int (1000.0 * float sampleCount / float currentConfig.SampleRate)
                            Thread.Sleep(max 1 (durationMs / 10))  // Speed up 10x for testing
                    finally
                        isStreaming <- false

                streamThread <- Some (Thread(ThreadStart(threadProc)))
                streamThread.Value.Start()
                Success ()

        member _.StopReceive() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            isStreaming <- false

        member _.IsStreaming = isStreaming

        member _.GetConfig() = currentConfig

    interface IDisposable with
        member this.Dispose() =
            (this :> ISDRSource).Close()

// ============================================================================
// WAV File Source (for audio-rate APT recordings)
// ============================================================================

/// WAV file source for audio APT recordings
type WavFileSource(filePath: string) =
    let mutable fileStream: FileStream option = None
    let mutable binaryReader: BinaryReader option = None
    let mutable isStreaming = false
    let mutable streamThread: Thread option = None
    let mutable stopRequested = false
    let mutable sampleRate = 11025.0<Hz>
    let mutable numChannels = 1
    let mutable bitsPerSample = 16
    let mutable dataOffset = 0L
    let mutable dataLength = 0L
    let mutable currentConfig = HackRFConfig.Default

    let readWavHeader (reader: BinaryReader) =
        // RIFF header
        let riff = reader.ReadBytes(4)
        if System.Text.Encoding.ASCII.GetString(riff) <> "RIFF" then
            failwith "Not a valid WAV file"

        let _ = reader.ReadInt32()  // File size
        let wave = reader.ReadBytes(4)
        if System.Text.Encoding.ASCII.GetString(wave) <> "WAVE" then
            failwith "Not a valid WAVE file"

        // Read chunks until we find 'data'
        let mutable foundData = false
        while not foundData do
            let chunkId = System.Text.Encoding.ASCII.GetString(reader.ReadBytes(4))
            let chunkSize = reader.ReadInt32()

            match chunkId with
            | "fmt " ->
                let audioFormat = reader.ReadInt16()
                numChannels <- int (reader.ReadInt16())
                sampleRate <- float (reader.ReadInt32()) * 1.0<Hz>
                let _ = reader.ReadInt32()  // Byte rate
                let _ = reader.ReadInt16()  // Block align
                bitsPerSample <- int (reader.ReadInt16())
                // Skip extra format bytes if any
                if chunkSize > 16 then
                    reader.ReadBytes(chunkSize - 16) |> ignore
            | "data" ->
                dataOffset <- reader.BaseStream.Position
                dataLength <- int64 chunkSize
                foundData <- true
            | _ ->
                // Skip unknown chunk
                reader.ReadBytes(chunkSize) |> ignore

    interface ISDRSource with
        member _.Open() =
            try
                if not (File.Exists filePath) then
                    Failure $"File not found: {filePath}"
                else
                    let fs = new FileStream(filePath, FileMode.Open, FileAccess.Read)
                    let br = new BinaryReader(fs)
                    fileStream <- Some fs
                    binaryReader <- Some br
                    readWavHeader br
                    currentConfig <- { currentConfig with SampleRate = float sampleRate * 1.0<Hz> }
                    Success ()
            with ex ->
                Failure $"Failed to open WAV file: {ex.Message}"

        member _.Close() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            match binaryReader with
            | Some br -> br.Dispose()
            | None -> ()
            match fileStream with
            | Some fs -> fs.Dispose()
            | None -> ()
            fileStream <- None
            binaryReader <- None
            isStreaming <- false

        member _.Configure(config: HackRFConfig) =
            currentConfig <- { config with SampleRate = float sampleRate * 1.0<Hz> }
            Success ()

        member _.StartReceive(callback: ComplexSample[] -> unit) =
            match binaryReader with
            | None -> Failure "WAV file not open"
            | Some reader ->
                stopRequested <- false
                isStreaming <- true

                let blockSamples = 8192
                let bytesPerSample = bitsPerSample / 8

                let threadProc() =
                    try
                        reader.BaseStream.Seek(dataOffset, SeekOrigin.Begin) |> ignore
                        let mutable bytesRemaining = dataLength

                        while not stopRequested && bytesRemaining > 0L do
                            let samplesToRead = min blockSamples (int (bytesRemaining / int64 bytesPerSample))
                            let samples = Array.zeroCreate<ComplexSample> samplesToRead

                            for i in 0 .. samplesToRead - 1 do
                                let value =
                                    if bitsPerSample = 16 then
                                        float32 (reader.ReadInt16()) / 32768.0f
                                    else
                                        (float32 (reader.ReadByte()) - 128.0f) / 128.0f

                                // WAV is real audio - put in I channel, Q=0
                                samples.[i] <- { I = value; Q = 0.0f }
                                bytesRemaining <- bytesRemaining - int64 bytesPerSample

                            callback samples

                            // Simulate real-time
                            let durationMs = int (1000.0 * float samplesToRead / float sampleRate)
                            Thread.Sleep(max 1 (durationMs / 4))
                    finally
                        isStreaming <- false

                streamThread <- Some (Thread(ThreadStart(threadProc)))
                streamThread.Value.Start()
                Success ()

        member _.StopReceive() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            isStreaming <- false

        member _.IsStreaming = isStreaming

        member _.GetConfig() = currentConfig

    interface IDisposable with
        member this.Dispose() =
            (this :> ISDRSource).Close()

// ============================================================================
// Simulated Signal Source (for development/testing)
// ============================================================================

/// Simulated NOAA APT signal source for testing
type SimulatedSource(satellite: NOAASatellite) =
    let mutable isStreaming = false
    let mutable streamThread: Thread option = None
    let mutable stopRequested = false
    let mutable currentConfig = HackRFConfig.Default

    let generateAPTSignal (sampleRate: float) (numSamples: int) =
        let subcarrier = 2400.0  // 2400 Hz subcarrier
        let samples = Array.zeroCreate<ComplexSample> numSamples
        let rng = Random()

        for i in 0 .. numSamples - 1 do
            let t = float i / sampleRate

            // Generate AM-modulated subcarrier
            // APT signal: AM on 2400 Hz subcarrier, then FM on carrier
            let lineRate = 2.0  // 2 lines per second
            let pixelRate = 4160.0  // ~4160 pixels per second

            // Simulated pixel value (sine pattern for testing)
            let pixelValue = 0.5 + 0.5 * sin (2.0 * Math.PI * 0.5 * t)

            // AM modulate onto subcarrier
            let amSignal = pixelValue * sin (2.0 * Math.PI * subcarrier * t)

            // Add noise
            let noise = (rng.NextDouble() - 0.5) * 0.1

            // FM modulate (simplified - just use as baseband for now)
            let phase = 2.0 * Math.PI * subcarrier * t * (1.0 + 0.3 * amSignal)
            samples.[i] <- { I = float32 (cos phase + noise * 0.5)
                            Q = float32 (sin phase + noise * 0.5) }

        samples

    interface ISDRSource with
        member _.Open() = Success ()

        member _.Close() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            isStreaming <- false

        member _.Configure(config: HackRFConfig) =
            currentConfig <- config
            Success ()

        member _.StartReceive(callback: ComplexSample[] -> unit) =
            stopRequested <- false
            isStreaming <- true

            let threadProc() =
                try
                    let blockSize = 65536
                    while not stopRequested do
                        let samples = generateAPTSignal (float currentConfig.SampleRate) blockSize
                        callback samples

                        // Simulate real-time
                        let durationMs = int (1000.0 * float blockSize / float currentConfig.SampleRate)
                        Thread.Sleep(max 10 durationMs)
                finally
                    isStreaming <- false

            streamThread <- Some (Thread(ThreadStart(threadProc)))
            streamThread.Value.Start()
            Success ()

        member _.StopReceive() =
            stopRequested <- true
            match streamThread with
            | Some t when t.IsAlive -> t.Join(1000) |> ignore
            | _ -> ()
            isStreaming <- false

        member _.IsStreaming = isStreaming

        member _.GetConfig() = currentConfig

    interface IDisposable with
        member this.Dispose() =
            (this :> ISDRSource).Close()
