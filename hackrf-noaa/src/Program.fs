/// HackRF NOAA APT Satellite Image Receiver
/// Main program and CLI interface
/// Based on RADARPAS terminal control patterns
module HackRF.NOAA.Program

open System
open System.IO
open System.Threading
open HackRF.NOAA.CoreTypes
open HackRF.NOAA.DSP
open HackRF.NOAA.HackRFInterface
open HackRF.NOAA.FMDemodulator
open HackRF.NOAA.APTDecoder
open HackRF.NOAA.ImageReconstructor
open HackRF.NOAA.SatelliteTracker
open HackRF.NOAA.Compression

// ============================================================================
// CLI Display (inspired by RADARPAS SCREENHA.MOD)
// ============================================================================

module Display =

    /// Clear screen (ANSI)
    let clearScreen() =
        Console.Clear()

    /// Move cursor
    let moveCursor (x: int) (y: int) =
        Console.SetCursorPosition(x, y)

    /// Print at position
    let printAt (x: int) (y: int) (text: string) =
        Console.SetCursorPosition(x, y)
        Console.Write(text)

    /// Print header
    let printHeader() =
        Console.ForegroundColor <- ConsoleColor.Cyan
        printfn "╔══════════════════════════════════════════════════════════════════╗"
        printfn "║   HackRF NOAA APT Satellite Receiver v1.0                        ║"
        printfn "║   Based on RADARPAS Signal Processing (1988-2024)                ║"
        printfn "╚══════════════════════════════════════════════════════════════════╝"
        Console.ResetColor()

    /// Print satellite info
    let printSatelliteInfo (satellite: NOAASatellite) =
        Console.ForegroundColor <- ConsoleColor.Yellow
        printfn ""
        printfn "  Satellite: %s" satellite.Name
        printfn "  Frequency: %.4f MHz" (float satellite.Frequency)
        printfn "  NORAD ID:  %d" satellite.NoradId
        Console.ResetColor()

    /// Print reception status
    let printStatus (state: ReceiverState) (linesReceived: int) (quality: SignalQuality) =
        Console.ForegroundColor <- ConsoleColor.Green
        printfn ""
        printfn "  ┌─ Reception Status ─────────────────────────────────────────────┐"
        let stateStr =
            match state with
            | Idle -> "IDLE"
            | Acquiring -> "ACQUIRING SIGNAL..."
            | Synchronizing -> "SYNCHRONIZING..."
            | Receiving -> "RECEIVING IMAGE"
            | Processing -> "PROCESSING..."
            | Error msg -> $"ERROR: {msg}"
        printfn "  │ State: %-20s                                    │" stateStr
        printfn "  │ Lines: %-6d   SNR: %+6.1f dB   Signal: %+6.1f dB          │"
            linesReceived (float quality.SNR) (float quality.SignalStrength)
        printfn "  │ Sync Confidence: %5.1f%%   Freq Offset: %+7.1f Hz            │"
            (quality.SyncConfidence * 100.0) (float quality.FrequencyOffset)
        printfn "  └────────────────────────────────────────────────────────────────┘"
        Console.ResetColor()

    /// Print progress bar
    let printProgress (current: int) (total: int) (width: int) =
        let percent = float current / float total
        let filled = int (percent * float width)
        let bar = String.replicate filled "█" + String.replicate (width - filled) "░"
        printf "\r  [%s] %5.1f%% (%d/%d lines)" bar (percent * 100.0) current total

    /// Print pass prediction
    let printPassPrediction (pass: SatellitePass) =
        Console.ForegroundColor <- ConsoleColor.Magenta
        printfn ""
        printfn "  ┌─ Next Pass Prediction ─────────────────────────────────────────┐"
        printfn "  │ Satellite: %-20s                                │" pass.Satellite.Name
        printfn "  │ AOS:       %s UTC                           │" (pass.AOS.ToString("yyyy-MM-dd HH:mm:ss"))
        printfn "  │ LOS:       %s UTC                           │" (pass.LOS.ToString("yyyy-MM-dd HH:mm:ss"))
        printfn "  │ Duration:  %d min %d sec                                       │"
            (int pass.Duration.TotalMinutes) (pass.Duration.Seconds)
        printfn "  │ Max Elev:  %.1f° at %s UTC               │"
            (float pass.MaxElevation) (pass.MaxElevationTime.ToString("HH:mm:ss"))
        printfn "  │ Az AOS:    %.1f°    Az LOS: %.1f°                             │"
            (float pass.AzimuthAtAOS) (float pass.AzimuthAtLOS)
        printfn "  └────────────────────────────────────────────────────────────────┘"
        Console.ResetColor()

    /// Print help
    let printHelp() =
        printfn ""
        printfn "  Commands:"
        printfn "    r, receive   - Start receiving (HackRF or simulation)"
        printfn "    f, file      - Process WAV/IQ file"
        printfn "    p, predict   - Show pass predictions"
        printfn "    s, satellite - Select satellite (15, 18, 19)"
        printfn "    l, location  - Set ground station location"
        printfn "    o, output    - Set output directory"
        printfn "    h, help      - Show this help"
        printfn "    q, quit      - Exit program"
        printfn ""

// ============================================================================
// Receiver Application
// ============================================================================

type ReceiverApp() =
    let mutable currentSatellite = NOAA19
    let mutable outputDirectory = "./output"
    let mutable groundStation = GroundStationLocation.Default
    let mutable state = Idle
    let mutable isRunning = false

    let mutable demodChain: APTDemodulationChain option = None
    let mutable decoderPipeline: APTDecoderPipeline option = None
    let mutable imageAssembler: APTImageAssembler option = None

    /// Initialize receiver components
    member private this.InitializeReceiver(sampleRate: float<Hz>) =
        demodChain <- Some (APTDemodulationChain.Create(sampleRate, currentSatellite))
        decoderPipeline <- Some (APTDecoderPipeline.Create(11025.0<Hz>))
        imageAssembler <- Some (APTImageAssembler.Create(currentSatellite, 3000))

    /// Process incoming IQ samples
    member private this.ProcessSamples(samples: ComplexSample[]) =
        match demodChain, decoderPipeline, imageAssembler with
        | Some demod, Some decoder, Some assembler ->
            // Demodulate
            let audioSamples = demod.Process samples

            // Decode APT
            let newLines = decoder.Process audioSamples

            // Add to image
            for line in newLines do
                assembler.AddLine line

            newLines.Length
        | _ -> 0

    /// Receive from HackRF (or simulation)
    member this.ReceiveFromSDR(useSimulation: bool) =
        printfn "  Initializing receiver for %s..." currentSatellite.Name

        // Create SDR source
        let source: ISDRSource =
            if useSimulation then
                upcast SimulatedSource(currentSatellite)
            else
                upcast HackRFSource()

        // Configure
        let config =
            { HackRFConfig.Default with
                CenterFrequency = currentSatellite.Frequency
                SampleRate = 2000000.0<Hz> }

        match source.Open() with
        | Failure msg ->
            printfn "  Error opening SDR: %s" msg
        | Success () ->

        match source.Configure(config) with
        | Failure msg ->
            printfn "  Error configuring SDR: %s" msg
            source.Close()
        | Success () ->

        this.InitializeReceiver(config.SampleRate)
        state <- Acquiring
        isRunning <- true

        let mutable totalLines = 0
        let startTime = DateTime.UtcNow

        let callback (samples: ComplexSample[]) =
            if isRunning then
                let lines = this.ProcessSamples samples
                totalLines <- totalLines + lines

                if lines > 0 then
                    state <- Receiving

                // Update display periodically
                if totalLines % 10 = 0 then
                    Display.printProgress totalLines 3000 40

        match source.StartReceive(callback) with
        | Failure msg ->
            printfn "  Error starting receive: %s" msg
        | Success () ->
            printfn "  Receiving... Press any key to stop."
            printfn ""

            // Wait for keypress or completion
            while isRunning && source.IsStreaming && not Console.KeyAvailable do
                Thread.Sleep(100)

            if Console.KeyAvailable then
                Console.ReadKey(true) |> ignore

            isRunning <- false
            source.StopReceive()

        source.Close()
        printfn ""
        printfn "  Reception complete. %d lines received." totalLines

        // Save image if we got data
        match imageAssembler with
        | Some assembler when assembler.TotalLines > 0 ->
            this.SaveImage(assembler)
        | _ ->
            printfn "  No image data to save."

    /// Process WAV file
    member this.ProcessWavFile(filename: string) =
        if not (File.Exists filename) then
            printfn "  File not found: %s" filename
        else
            printfn "  Processing WAV file: %s" filename

            let source = new WavFileSource(filename)

            match source.Open() with
            | Failure msg ->
                printfn "  Error opening file: %s" msg
            | Success () ->

            let config = source.GetConfig()
            this.InitializeReceiver(config.SampleRate)
            state <- Acquiring
            isRunning <- true

            let mutable totalLines = 0

            let callback (samples: ComplexSample[]) =
                if isRunning then
                    let lines = this.ProcessSamples samples
                    totalLines <- totalLines + lines

                    if lines > 0 then
                        state <- Receiving

                    Display.printProgress totalLines 3000 40

            match source.StartReceive(callback) with
            | Failure msg ->
                printfn "  Error processing: %s" msg
            | Success () ->
                // Wait for completion
                while source.IsStreaming do
                    Thread.Sleep(100)

            (source :> IDisposable).Dispose()

            printfn ""
            printfn "  Processing complete. %d lines decoded." totalLines

            match imageAssembler with
            | Some assembler when assembler.TotalLines > 0 ->
                this.SaveImage(assembler)
            | _ ->
                printfn "  No image data decoded."

    /// Save received image
    member private this.SaveImage(assembler: APTImageAssembler) =
        state <- Processing
        printfn "  Saving image..."

        // Create output directory
        if not (Directory.Exists outputDirectory) then
            Directory.CreateDirectory(outputDirectory) |> ignore

        // Build and process image
        let image = assembler.BuildImage()
        let processor = APTImageProcessor.Create(EnhancementOptions.Default)
        let files = processor.ProcessImage(image, outputDirectory)

        // Also save compressed format
        let compressedPath = Path.Combine(outputDirectory,
            $"{image.Satellite.Name}_{image.StartTime:yyyyMMdd_HHmmss}.apt")
        APTFormat.saveCompressed image compressedPath true

        printfn ""
        printfn "  Saved files:"
        for file in files do
            printfn "    - %s" file
        printfn "    - %s (compressed)" compressedPath

        state <- Idle

    /// Show pass predictions
    member this.ShowPassPredictions() =
        printfn "  Calculating pass predictions for %s..." currentSatellite.Name

        match DefaultTLE.getDefaultTLE currentSatellite with
        | None ->
            printfn "  Error: Could not load TLE data"
        | Some tle ->
            let propagator = SGP4Propagator(tle)
            let predictor = PassPredictor(groundStation, 10.0<degree>)

            let passes = predictor.PredictPasses(propagator, currentSatellite, DateTime.UtcNow, 5)

            if passes.IsEmpty then
                printfn "  No passes found in next 48 hours"
            else
                for pass in passes do
                    Display.printPassPrediction pass

    /// Set satellite
    member this.SetSatellite(satNum: int) =
        currentSatellite <-
            match satNum with
            | 15 -> NOAA15
            | 18 -> NOAA18
            | _ -> NOAA19
        printfn "  Selected satellite: %s" currentSatellite.Name

    /// Set ground station location
    member this.SetLocation(lat: float, lon: float, alt: float) =
        groundStation <-
            { Latitude = lat * 1.0<degree>
              Longitude = lon * 1.0<degree>
              Altitude = alt * 1.0<km> }
        printfn "  Ground station set to: %.4f°, %.4f°, %.1f km"
            lat lon alt

    /// Set output directory
    member this.SetOutputDirectory(path: string) =
        outputDirectory <- path
        printfn "  Output directory: %s" outputDirectory

    /// Main loop
    member this.Run() =
        Display.clearScreen()
        Display.printHeader()
        Display.printSatelliteInfo currentSatellite
        Display.printHelp()

        let mutable running = true

        while running do
            printf "  > "
            let input = Console.ReadLine()

            if not (String.IsNullOrWhiteSpace input) then
                let parts = input.Trim().Split(' ')
                let cmd = parts.[0].ToLower()

                match cmd with
                | "r" | "receive" ->
                    let useSimulation = parts.Length > 1 && parts.[1] = "sim"
                    this.ReceiveFromSDR(useSimulation)

                | "f" | "file" ->
                    if parts.Length > 1 then
                        this.ProcessWavFile(parts.[1])
                    else
                        printfn "  Usage: file <path.wav>"

                | "p" | "predict" ->
                    this.ShowPassPredictions()

                | "s" | "satellite" ->
                    if parts.Length > 1 then
                        match Int32.TryParse(parts.[1]) with
                        | true, n -> this.SetSatellite(n)
                        | _ -> printfn "  Usage: satellite <15|18|19>"
                    else
                        printfn "  Current: %s" currentSatellite.Name
                        printfn "  Usage: satellite <15|18|19>"

                | "l" | "location" ->
                    if parts.Length >= 4 then
                        match Double.TryParse(parts.[1]), Double.TryParse(parts.[2]), Double.TryParse(parts.[3]) with
                        | (true, lat), (true, lon), (true, alt) ->
                            this.SetLocation(lat, lon, alt)
                        | _ ->
                            printfn "  Usage: location <lat> <lon> <alt_km>"
                    else
                        printfn "  Current: %.4f°, %.4f°, %.1f km"
                            (float groundStation.Latitude)
                            (float groundStation.Longitude)
                            (float groundStation.Altitude)
                        printfn "  Usage: location <lat> <lon> <alt_km>"

                | "o" | "output" ->
                    if parts.Length > 1 then
                        this.SetOutputDirectory(parts.[1])
                    else
                        printfn "  Current: %s" outputDirectory

                | "h" | "help" | "?" ->
                    Display.printHelp()

                | "q" | "quit" | "exit" ->
                    running <- false

                | "" -> ()

                | _ ->
                    printfn "  Unknown command. Type 'help' for commands."

        printfn ""
        printfn "  Goodbye!"

// ============================================================================
// Entry Point
// ============================================================================

[<EntryPoint>]
let main args =
    try
        // Parse command line arguments
        if args.Length > 0 then
            match args.[0].ToLower() with
            | "--help" | "-h" ->
                printfn "HackRF NOAA APT Satellite Receiver"
                printfn ""
                printfn "Usage: hackrf-noaa [options]"
                printfn ""
                printfn "Options:"
                printfn "  --help, -h        Show this help"
                printfn "  --file <path>     Process WAV file directly"
                printfn "  --satellite <n>   Select satellite (15, 18, or 19)"
                printfn "  --output <dir>    Set output directory"
                printfn ""
                0

            | "--file" | "-f" when args.Length > 1 ->
                let app = ReceiverApp()
                if args.Length > 3 && (args.[2] = "--satellite" || args.[2] = "-s") then
                    app.SetSatellite(Int32.Parse(args.[3]))
                app.ProcessWavFile(args.[1])
                0

            | _ ->
                let app = ReceiverApp()
                app.Run()
                0
        else
            let app = ReceiverApp()
            app.Run()
            0

    with ex ->
        Console.ForegroundColor <- ConsoleColor.Red
        printfn "Error: %s" ex.Message
        Console.ResetColor()
        1
