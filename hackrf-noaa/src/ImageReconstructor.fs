/// Image Reconstruction Module for NOAA APT Images
/// Converts decoded APT lines into viewable satellite images
/// Inspired by RADARPAS graphics and compression modules
module HackRF.NOAA.ImageReconstructor

open System
open System.IO
open HackRF.NOAA.CoreTypes
open HackRF.NOAA.APTDecoder

// ============================================================================
// Image Buffer Management
// ============================================================================

/// Image channel type
type ImageChannel =
    | ChannelA    // Typically visible/AVHRR
    | ChannelB    // Typically infrared
    | Composite   // Combined false color

/// Raw image buffer
type ImageBuffer =
    { Width: int
      Height: int
      mutable Data: byte[,]
      mutable CurrentLine: int }

    static member Create(width: int, maxHeight: int) =
        { Width = width
          Height = maxHeight
          Data = Array2D.zeroCreate maxHeight width
          CurrentLine = 0 }

    /// Add a line to the buffer
    member this.AddLine(pixels: byte[]) =
        if this.CurrentLine < this.Height then
            let copyLen = min pixels.Length this.Width
            for x in 0 .. copyLen - 1 do
                this.Data.[this.CurrentLine, x] <- pixels.[x]
            this.CurrentLine <- this.CurrentLine + 1
            true
        else
            false

    /// Get actual image height (lines received)
    member this.ActualHeight = this.CurrentLine

    /// Get a horizontal line
    member this.GetLine(y: int) : byte[] =
        if y >= 0 && y < this.CurrentLine then
            Array.init this.Width (fun x -> this.Data.[y, x])
        else
            Array.zeroCreate this.Width

    /// Get pixel value
    member this.GetPixel(x: int, y: int) : byte =
        if x >= 0 && x < this.Width && y >= 0 && y < this.CurrentLine then
            this.Data.[y, x]
        else
            0uy

// ============================================================================
// APT Image Assembly
// ============================================================================

/// APT Image assembler
type APTImageAssembler =
    { Satellite: NOAASatellite
      ChannelABuffer: ImageBuffer
      ChannelBBuffer: ImageBuffer
      mutable StartTime: DateTime option
      mutable LastLineTime: DateTime
      mutable TotalLines: int
      MaxLines: int }

    static member Create(satellite: NOAASatellite, maxLines: int) =
        { Satellite = satellite
          ChannelABuffer = ImageBuffer.Create(APTFrame.imageAWidth, maxLines)
          ChannelBBuffer = ImageBuffer.Create(APTFrame.imageBWidth, maxLines)
          StartTime = None
          LastLineTime = DateTime.UtcNow
          TotalLines = 0
          MaxLines = maxLines }

    /// Add decoded APT line to image
    member this.AddLine(line: APTLine) =
        match this.StartTime with
        | None -> this.StartTime <- Some line.Timestamp
        | Some _ -> ()

        this.ChannelABuffer.AddLine(line.ChannelA) |> ignore
        this.ChannelBBuffer.AddLine(line.ChannelB) |> ignore
        this.LastLineTime <- line.Timestamp
        this.TotalLines <- this.TotalLines + 1

    /// Get current progress
    member this.Progress =
        float this.TotalLines / float this.MaxLines

    /// Build final APT image
    member this.BuildImage() : APTImage =
        let height = this.ChannelABuffer.ActualHeight
        let width = APTFrame.imageAWidth

        let channelA = Array2D.init height width (fun y x -> this.ChannelABuffer.Data.[y, x])
        let channelB = Array2D.init height width (fun y x -> this.ChannelBBuffer.Data.[y, x])

        { Satellite = this.Satellite
          StartTime = this.StartTime |> Option.defaultValue DateTime.UtcNow
          EndTime = this.LastLineTime
          Lines = []  // Raw lines not stored in final image
          ChannelAData = channelA
          ChannelBData = channelB
          Metadata = Map.ofList [
              "Satellite", this.Satellite.Name
              "Lines", string this.TotalLines
              "Width", string width
              "Height", string height
          ] }

// ============================================================================
// Image Enhancement
// ============================================================================

module ImageEnhancement =

    /// Histogram equalization for contrast enhancement
    let histogramEqualize (data: byte[,]) : byte[,] =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        // Build histogram
        let histogram = Array.zeroCreate 256
        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                let value = int data.[y, x]
                histogram.[value] <- histogram.[value] + 1

        // Build cumulative distribution function
        let cdf = Array.zeroCreate 256
        cdf.[0] <- histogram.[0]
        for i in 1 .. 255 do
            cdf.[i] <- cdf.[i-1] + histogram.[i]

        // Find min non-zero CDF value
        let cdfMin = cdf |> Array.find (fun x -> x > 0)
        let totalPixels = height * width

        // Build lookup table
        let lut = Array.init 256 (fun i ->
            if cdf.[i] > 0 then
                let normalized = float (cdf.[i] - cdfMin) / float (totalPixels - cdfMin)
                byte (normalized * 255.0)
            else
                0uy)

        // Apply LUT
        Array2D.init height width (fun y x -> lut.[int data.[y, x]])

    /// Median filter for noise reduction
    let medianFilter (data: byte[,]) (kernelSize: int) : byte[,] =
        let height = Array2D.length1 data
        let width = Array2D.length2 data
        let half = kernelSize / 2
        let result = Array2D.zeroCreate height width

        let kernel = Array.zeroCreate (kernelSize * kernelSize)

        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                let mutable idx = 0
                for ky in -half .. half do
                    for kx in -half .. half do
                        let sy = max 0 (min (height - 1) (y + ky))
                        let sx = max 0 (min (width - 1) (x + kx))
                        kernel.[idx] <- data.[sy, sx]
                        idx <- idx + 1

                Array.sortInPlace kernel
                result.[y, x] <- kernel.[kernel.Length / 2]

        result

    /// Sharpen image using unsharp mask
    let sharpen (data: byte[,]) (amount: float) : byte[,] =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        // Simple 3x3 blur for unsharp mask
        let blurred = Array2D.zeroCreate height width
        for y in 1 .. height - 2 do
            for x in 1 .. width - 2 do
                let sum =
                    int data.[y-1, x-1] + int data.[y-1, x] + int data.[y-1, x+1] +
                    int data.[y, x-1] + int data.[y, x] + int data.[y, x+1] +
                    int data.[y+1, x-1] + int data.[y+1, x] + int data.[y+1, x+1]
                blurred.[y, x] <- byte (sum / 9)

        // Apply unsharp mask: result = original + amount * (original - blurred)
        Array2D.init height width (fun y x ->
            if y > 0 && y < height - 1 && x > 0 && x < width - 1 then
                let diff = float data.[y, x] - float blurred.[y, x]
                let sharpened = float data.[y, x] + amount * diff
                byte (max 0.0 (min 255.0 sharpened))
            else
                data.[y, x])

    /// Gamma correction
    let gammaCorrect (data: byte[,]) (gamma: float) : byte[,] =
        let lut = Array.init 256 (fun i ->
            let normalized = float i / 255.0
            let corrected = Math.Pow(normalized, 1.0 / gamma)
            byte (corrected * 255.0))

        let height = Array2D.length1 data
        let width = Array2D.length2 data
        Array2D.init height width (fun y x -> lut.[int data.[y, x]])

    /// Linear stretch (percentile-based)
    let linearStretch (data: byte[,]) (lowPercentile: float) (highPercentile: float) : byte[,] =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        // Build sorted list of values
        let values = ResizeArray<byte>()
        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                values.Add(data.[y, x])

        values.Sort()

        let lowIdx = int (float values.Count * lowPercentile / 100.0)
        let highIdx = int (float values.Count * highPercentile / 100.0)

        let lowVal = float values.[max 0 lowIdx]
        let highVal = float values.[min (values.Count - 1) highIdx]

        let range = highVal - lowVal
        if range < 1.0 then
            data
        else
            Array2D.init height width (fun y x ->
                let v = float data.[y, x]
                let stretched = (v - lowVal) / range * 255.0
                byte (max 0.0 (min 255.0 stretched)))

// ============================================================================
// False Color Composite
// ============================================================================

module FalseColor =

    /// RGB pixel for composite images
    [<Struct>]
    type RGBPixel =
        { R: byte; G: byte; B: byte }

    /// Create false color composite from channels A and B
    /// Channel A (visible) -> Green/Cyan
    /// Channel B (IR) -> Red/Orange (inverted for temperature)
    let createComposite (channelA: byte[,]) (channelB: byte[,]) : RGBPixel[,] =
        let height = min (Array2D.length1 channelA) (Array2D.length1 channelB)
        let width = min (Array2D.length2 channelA) (Array2D.length2 channelB)

        Array2D.init height width (fun y x ->
            let a = channelA.[y, x]
            let b = channelB.[y, x]

            // Invert IR for temperature visualization (bright = cold = high clouds)
            let irInv = 255uy - b

            // Simple false color mapping:
            // Warm areas (low IR) = brownish/orange
            // Cold areas (high IR, clouds) = white/cyan
            // Vegetation (high visible) = green
            { R = byte (min 255 (int irInv + int a / 4))
              G = byte (min 255 (int a + int irInv / 4))
              B = byte (min 255 (int irInv + int irInv / 2)) })

    /// MSA (Multi-Spectral Analysis) color enhancement
    let msaEnhance (channelA: byte[,]) (channelB: byte[,]) : RGBPixel[,] =
        let height = min (Array2D.length1 channelA) (Array2D.length1 channelB)
        let width = min (Array2D.length2 channelA) (Array2D.length2 channelB)

        Array2D.init height width (fun y x ->
            let vis = float channelA.[y, x] / 255.0
            let ir = float channelB.[y, x] / 255.0
            let irInv = 1.0 - ir

            // Enhanced color mapping for weather features
            let r = irInv * 0.7 + vis * 0.3
            let g = vis * 0.8 + irInv * 0.2
            let b = irInv * 0.9 + vis * 0.1

            { R = byte (r * 255.0)
              G = byte (g * 255.0)
              B = byte (b * 255.0) })

    /// Temperature colormap for IR channel
    let temperatureColormap (irChannel: byte[,]) : RGBPixel[,] =
        // Color scale: black (warm) -> red -> yellow -> white (cold)
        let colormap = Array.init 256 (fun i ->
            let t = float i / 255.0
            if t < 0.25 then
                // Black to red
                let s = t / 0.25
                { R = byte (s * 255.0); G = 0uy; B = 0uy }
            elif t < 0.5 then
                // Red to yellow
                let s = (t - 0.25) / 0.25
                { R = 255uy; G = byte (s * 255.0); B = 0uy }
            elif t < 0.75 then
                // Yellow to cyan
                let s = (t - 0.5) / 0.25
                { R = byte ((1.0 - s) * 255.0); G = 255uy; B = byte (s * 255.0) }
            else
                // Cyan to white
                let s = (t - 0.75) / 0.25
                { R = byte (s * 255.0); G = 255uy; B = 255uy })

        let height = Array2D.length1 irChannel
        let width = Array2D.length2 irChannel
        Array2D.init height width (fun y x ->
            // Invert: high values (bright) = cold = high index
            colormap.[int irChannel.[y, x]])

// ============================================================================
// Image Export (PNG using ImageSharp concepts)
// ============================================================================

module ImageExport =

    /// Save grayscale image as PGM (Portable GrayMap)
    let savePGM (data: byte[,]) (filename: string) =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        use writer = new StreamWriter(filename)
        writer.WriteLine("P5")
        writer.WriteLine($"{width} {height}")
        writer.WriteLine("255")
        writer.Flush()

        use binWriter = new BinaryWriter(writer.BaseStream)
        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                binWriter.Write(data.[y, x])

    /// Save RGB image as PPM (Portable PixMap)
    let savePPM (data: FalseColor.RGBPixel[,]) (filename: string) =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        use writer = new StreamWriter(filename)
        writer.WriteLine("P6")
        writer.WriteLine($"{width} {height}")
        writer.WriteLine("255")
        writer.Flush()

        use binWriter = new BinaryWriter(writer.BaseStream)
        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                let pixel = data.[y, x]
                binWriter.Write(pixel.R)
                binWriter.Write(pixel.G)
                binWriter.Write(pixel.B)

    /// Save image as raw binary
    let saveRaw (data: byte[,]) (filename: string) =
        let height = Array2D.length1 data
        let width = Array2D.length2 data

        use stream = File.Create(filename)
        for y in 0 .. height - 1 do
            for x in 0 .. width - 1 do
                stream.WriteByte(data.[y, x])

// ============================================================================
// RLE Compression (based on RADARPAS COMPR.MOD)
// ============================================================================

module Compression =

    /// RLE compress image data (following RADARPAS pattern)
    let rleCompress (data: byte[]) : byte[] =
        let output = ResizeArray<byte>()
        let mutable i = 0

        while i < data.Length do
            let current = data.[i]
            let mutable runLength = 1

            // Count run length
            while i + runLength < data.Length &&
                  data.[i + runLength] = current &&
                  runLength < 255 do
                runLength <- runLength + 1

            if runLength >= 3 || current = 0x00uy || current = 0xFFuy then
                // Use RLE encoding
                output.Add(0xFFuy)  // Escape marker
                output.Add(byte runLength)
                output.Add(current)
            else
                // Output raw bytes
                for _ in 1 .. runLength do
                    if current = 0xFFuy then
                        output.Add(0xFFuy)
                        output.Add(1uy)
                        output.Add(0xFFuy)
                    else
                        output.Add(current)

            i <- i + runLength

        output.ToArray()

    /// RLE decompress
    let rleDecompress (data: byte[]) : byte[] =
        let output = ResizeArray<byte>()
        let mutable i = 0

        while i < data.Length do
            if data.[i] = 0xFFuy && i + 2 < data.Length then
                let count = int data.[i + 1]
                let value = data.[i + 2]
                for _ in 1 .. count do
                    output.Add(value)
                i <- i + 3
            else
                output.Add(data.[i])
                i <- i + 1

        output.ToArray()

// ============================================================================
// Complete Image Processor
// ============================================================================

/// Enhancement options
type EnhancementOptions =
    { HistogramEqualization: bool
      NoiseReduction: bool
      Sharpen: bool
      SharpenAmount: float
      GammaCorrection: float option
      LinearStretch: (float * float) option }

    static member Default =
        { HistogramEqualization = true
          NoiseReduction = false
          Sharpen = false
          SharpenAmount = 0.5
          GammaCorrection = None
          LinearStretch = Some (2.0, 98.0) }

/// Process APT image with enhancements
type APTImageProcessor =
    { Options: EnhancementOptions }

    static member Create(options: EnhancementOptions) =
        { Options = options }

    /// Apply all enhancements to channel data
    member this.EnhanceChannel(data: byte[,]) : byte[,] =
        let mutable result = data

        // Apply linear stretch first
        match this.Options.LinearStretch with
        | Some (low, high) ->
            result <- ImageEnhancement.linearStretch result low high
        | None -> ()

        // Noise reduction
        if this.Options.NoiseReduction then
            result <- ImageEnhancement.medianFilter result 3

        // Histogram equalization
        if this.Options.HistogramEqualization then
            result <- ImageEnhancement.histogramEqualize result

        // Gamma correction
        match this.Options.GammaCorrection with
        | Some gamma -> result <- ImageEnhancement.gammaCorrect result gamma
        | None -> ()

        // Sharpening (last)
        if this.Options.Sharpen then
            result <- ImageEnhancement.sharpen result this.Options.SharpenAmount

        result

    /// Process complete APT image
    member this.ProcessImage(image: APTImage, outputDir: string) =
        let timestamp = image.StartTime.ToString("yyyyMMdd_HHmmss")
        let baseName = $"{image.Satellite.Name}_{timestamp}"

        // Enhance channels
        let enhancedA = this.EnhanceChannel image.ChannelAData
        let enhancedB = this.EnhanceChannel image.ChannelBData

        // Save individual channels
        let channelAPath = Path.Combine(outputDir, $"{baseName}_visible.pgm")
        let channelBPath = Path.Combine(outputDir, $"{baseName}_infrared.pgm")
        ImageExport.savePGM enhancedA channelAPath
        ImageExport.savePGM enhancedB channelBPath

        // Create and save composites
        let composite = FalseColor.createComposite enhancedA enhancedB
        let compositePath = Path.Combine(outputDir, $"{baseName}_composite.ppm")
        ImageExport.savePPM composite compositePath

        let tempMap = FalseColor.temperatureColormap enhancedB
        let tempPath = Path.Combine(outputDir, $"{baseName}_temperature.ppm")
        ImageExport.savePPM tempMap tempPath

        // Return paths
        [ channelAPath; channelBPath; compositePath; tempPath ]
