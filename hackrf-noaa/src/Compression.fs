/// Compression Module for HackRF NOAA Receiver
/// Implements RLE and other compression algorithms based on RADARPAS COMPR.MOD
module HackRF.NOAA.Compression

open System
open System.IO

// ============================================================================
// Run-Length Encoding (Based on RADARPAS COMPR.MOD)
// ============================================================================

/// RLE compression following RADARPAS pattern
/// Special handling for 0x00 and 0xFF bytes
module RLE =

    /// Escape byte marker
    let private escapeMarker = 0xFEuy

    /// Compress data using RLE
    let compress (data: byte[]) : byte[] =
        if data.Length = 0 then
            [||]
        else
            let output = ResizeArray<byte>(data.Length)
            let mutable i = 0

            while i < data.Length do
                let current = data.[i]
                let mutable runLength = 1

                // Count consecutive identical bytes
                while i + runLength < data.Length &&
                      data.[i + runLength] = current &&
                      runLength < 255 do
                    runLength <- runLength + 1

                // Encoding decision
                if runLength >= 4 then
                    // RLE encode: ESCAPE + LENGTH + VALUE
                    output.Add(escapeMarker)
                    output.Add(byte runLength)
                    output.Add(current)
                elif current = escapeMarker then
                    // Escape the escape marker: ESCAPE + 1 + ESCAPE
                    for _ in 1 .. runLength do
                        output.Add(escapeMarker)
                        output.Add(1uy)
                        output.Add(escapeMarker)
                else
                    // Output raw bytes
                    for _ in 1 .. runLength do
                        output.Add(current)

                i <- i + runLength

            output.ToArray()

    /// Decompress RLE data
    let decompress (data: byte[]) : byte[] =
        if data.Length = 0 then
            [||]
        else
            let output = ResizeArray<byte>()
            let mutable i = 0

            while i < data.Length do
                if data.[i] = escapeMarker && i + 2 < data.Length then
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
// Image-Specific RLE (Two-Plane RADARPAS Style)
// ============================================================================

module ImageRLE =

    /// Compress image scanline (optimized for radar/satellite images)
    let compressScanline (pixels: byte[]) : byte[] =
        // Satellite images often have:
        // - Large areas of similar values (ocean, land)
        // - Gradients (atmospheric effects)
        // We use delta encoding + RLE

        if pixels.Length = 0 then
            [||]
        else
            let deltas = Array.zeroCreate pixels.Length
            deltas.[0] <- pixels.[0]

            for i in 1 .. pixels.Length - 1 do
                // Delta from previous pixel, wrapped to byte
                let delta = int pixels.[i] - int pixels.[i-1]
                deltas.[i] <- byte ((delta + 128) &&& 0xFF)

            RLE.compress deltas

    /// Decompress scanline
    let decompressScanline (data: byte[]) (width: int) : byte[] =
        let deltas = RLE.decompress data

        if deltas.Length = 0 then
            Array.zeroCreate width
        else
            let pixels = Array.zeroCreate (min deltas.Length width)
            pixels.[0] <- deltas.[0]

            for i in 1 .. pixels.Length - 1 do
                let delta = int deltas.[i] - 128
                pixels.[i] <- byte ((int pixels.[i-1] + delta) &&& 0xFF)

            pixels

    /// Compress full image
    let compressImage (image: byte[,]) : byte[] =
        let height = Array2D.length1 image
        let width = Array2D.length2 image

        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream)

        // Header
        writer.Write(width)
        writer.Write(height)

        // Compress each line
        for y in 0 .. height - 1 do
            let line = Array.init width (fun x -> image.[y, x])
            let compressed = compressScanline line

            writer.Write(compressed.Length)
            writer.Write(compressed)

        stream.ToArray()

    /// Decompress full image
    let decompressImage (data: byte[]) : byte[,] =
        use stream = new MemoryStream(data)
        use reader = new BinaryReader(stream)

        let width = reader.ReadInt32()
        let height = reader.ReadInt32()

        let image = Array2D.zeroCreate height width

        for y in 0 .. height - 1 do
            let compressedLen = reader.ReadInt32()
            let compressed = reader.ReadBytes(compressedLen)
            let line = decompressScanline compressed width

            for x in 0 .. min (line.Length - 1) (width - 1) do
                image.[y, x] <- line.[x]

        image

// ============================================================================
// LZ-Style Compression (Simple LZ77 variant)
// ============================================================================

module LZ =

    /// Simple LZ77-style compression
    let compress (data: byte[]) (windowSize: int) (minMatch: int) : byte[] =
        if data.Length = 0 then
            [||]
        else
            let output = ResizeArray<byte>()
            let mutable pos = 0

            while pos < data.Length do
                let mutable bestOffset = 0
                let mutable bestLength = 0

                // Search for match in window
                let windowStart = max 0 (pos - windowSize)
                for i in windowStart .. pos - 1 do
                    let mutable length = 0
                    while pos + length < data.Length &&
                          length < 255 &&
                          data.[i + length] = data.[pos + length] do
                        length <- length + 1

                    if length >= minMatch && length > bestLength then
                        bestLength <- length
                        bestOffset <- pos - i

                if bestLength >= minMatch then
                    // Output match: FLAG + OFFSET + LENGTH
                    output.Add(0xFFuy)  // Match flag
                    output.Add(byte bestOffset)
                    output.Add(byte bestLength)
                    pos <- pos + bestLength
                else
                    // Output literal
                    if data.[pos] = 0xFFuy then
                        output.Add(0xFFuy)
                        output.Add(0uy)  // Literal 0xFF marker
                        output.Add(data.[pos])
                    else
                        output.Add(data.[pos])
                    pos <- pos + 1

            output.ToArray()

    /// Decompress LZ data
    let decompress (data: byte[]) : byte[] =
        if data.Length = 0 then
            [||]
        else
            let output = ResizeArray<byte>()
            let mutable i = 0

            while i < data.Length do
                if data.[i] = 0xFFuy && i + 2 < data.Length then
                    if data.[i + 1] = 0uy then
                        // Literal 0xFF
                        output.Add(data.[i + 2])
                        i <- i + 3
                    else
                        // Match
                        let offset = int data.[i + 1]
                        let length = int data.[i + 2]
                        let startPos = output.Count - offset

                        for j in 0 .. length - 1 do
                            if startPos + j >= 0 && startPos + j < output.Count then
                                output.Add(output.[startPos + j])
                            else
                                output.Add(0uy)

                        i <- i + 3
                else
                    output.Add(data.[i])
                    i <- i + 1

            output.ToArray()

// ============================================================================
// File Format for Compressed APT Images
// ============================================================================

module APTFormat =

    /// Magic bytes for APT file format
    let magic = [| 0x41uy; 0x50uy; 0x54uy; 0x31uy |]  // "APT1"

    /// File header
    type APTFileHeader =
        { Version: byte
          Satellite: byte    // 0=NOAA15, 1=NOAA18, 2=NOAA19
          Width: int
          Height: int
          StartTime: int64   // Unix timestamp
          EndTime: int64
          Compression: byte  // 0=none, 1=RLE, 2=LZ
          Flags: byte }

    /// Save APT image to compressed file
    let saveCompressed (image: HackRF.NOAA.CoreTypes.APTImage) (filename: string) (useCompression: bool) =
        use stream = File.Create(filename)
        use writer = new BinaryWriter(stream)

        // Magic
        writer.Write(magic)

        // Header
        let satByte =
            match image.Satellite with
            | HackRF.NOAA.CoreTypes.NOAA15 -> 0uy
            | HackRF.NOAA.CoreTypes.NOAA18 -> 1uy
            | HackRF.NOAA.CoreTypes.NOAA19 -> 2uy

        let height = Array2D.length1 image.ChannelAData
        let width = Array2D.length2 image.ChannelAData

        writer.Write(1uy)  // Version
        writer.Write(satByte)
        writer.Write(width)
        writer.Write(height)
        writer.Write(image.StartTime.ToFileTimeUtc())
        writer.Write(image.EndTime.ToFileTimeUtc())
        writer.Write(if useCompression then 1uy else 0uy)
        writer.Write(0uy)  // Flags

        // Channel A data
        if useCompression then
            let compressed = ImageRLE.compressImage image.ChannelAData
            writer.Write(compressed.Length)
            writer.Write(compressed)
        else
            for y in 0 .. height - 1 do
                for x in 0 .. width - 1 do
                    writer.Write(image.ChannelAData.[y, x])

        // Channel B data
        if useCompression then
            let compressed = ImageRLE.compressImage image.ChannelBData
            writer.Write(compressed.Length)
            writer.Write(compressed)
        else
            for y in 0 .. height - 1 do
                for x in 0 .. width - 1 do
                    writer.Write(image.ChannelBData.[y, x])

    /// Load compressed APT file
    let loadCompressed (filename: string) : HackRF.NOAA.CoreTypes.APTImage option =
        try
            use stream = File.OpenRead(filename)
            use reader = new BinaryReader(stream)

            // Verify magic
            let fileMagic = reader.ReadBytes(4)
            if fileMagic <> magic then
                None
            else
                // Read header
                let version = reader.ReadByte()
                let satByte = reader.ReadByte()
                let width = reader.ReadInt32()
                let height = reader.ReadInt32()
                let startTime = DateTime.FromFileTimeUtc(reader.ReadInt64())
                let endTime = DateTime.FromFileTimeUtc(reader.ReadInt64())
                let compression = reader.ReadByte()
                let _flags = reader.ReadByte()

                let satellite =
                    match satByte with
                    | 0uy -> HackRF.NOAA.CoreTypes.NOAA15
                    | 1uy -> HackRF.NOAA.CoreTypes.NOAA18
                    | _ -> HackRF.NOAA.CoreTypes.NOAA19

                // Read channel A
                let channelA =
                    if compression = 1uy then
                        let len = reader.ReadInt32()
                        let data = reader.ReadBytes(len)
                        ImageRLE.decompressImage data
                    else
                        let data = Array2D.zeroCreate height width
                        for y in 0 .. height - 1 do
                            for x in 0 .. width - 1 do
                                data.[y, x] <- reader.ReadByte()
                        data

                // Read channel B
                let channelB =
                    if compression = 1uy then
                        let len = reader.ReadInt32()
                        let data = reader.ReadBytes(len)
                        ImageRLE.decompressImage data
                    else
                        let data = Array2D.zeroCreate height width
                        for y in 0 .. height - 1 do
                            for x in 0 .. width - 1 do
                                data.[y, x] <- reader.ReadByte()
                        data

                Some {
                    HackRF.NOAA.CoreTypes.APTImage.Satellite = satellite
                    StartTime = startTime
                    EndTime = endTime
                    Lines = []
                    ChannelAData = channelA
                    ChannelBData = channelB
                    Metadata = Map.empty
                }
        with _ ->
            None
