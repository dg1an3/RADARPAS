/// CRC-16 calculation module
/// Translated from Modula-2 CRC.MOD
/// Original: (c) Copyright 1986, 1987 PMI, Portland, Oregon
///           Written by David Tingler of Telepath Systems, Inc.
module Radarpas.Crc

open System

// ============================================================================
// CRC-16 Lookup Table
// ============================================================================

/// CRC-16 lookup table (precomputed polynomial table)
/// Original: crctab: ARRAY [0..255] OF BITSET
let private crcTable : uint16 array =
    [|
        0x0000us; 0xC0C1us; 0xC181us; 0x0140us; 0xC301us; 0x03C0us; 0x0280us; 0xC241us
        0xC601us; 0x06C0us; 0x0780us; 0xC741us; 0x0500us; 0xC5C1us; 0xC481us; 0x0440us
        0xCC01us; 0x0CC0us; 0x0D80us; 0xCD41us; 0x0F00us; 0xCFC1us; 0xCE81us; 0x0E40us
        0x0A00us; 0xCAC1us; 0xCB81us; 0x0B40us; 0xC901us; 0x09C0us; 0x0880us; 0xC841us
        0xD801us; 0x18C0us; 0x1980us; 0xD941us; 0x1B00us; 0xDBC1us; 0xDA81us; 0x1A40us
        0x1E00us; 0xDEC1us; 0xDF81us; 0x1F40us; 0xDD01us; 0x1DC0us; 0x1C80us; 0xDC41us
        0x1400us; 0xD4C1us; 0xD581us; 0x1540us; 0xD701us; 0x17C0us; 0x1680us; 0xD641us
        0xD201us; 0x12C0us; 0x1380us; 0xD341us; 0x1100us; 0xD1C1us; 0xD081us; 0x1040us
        0xF001us; 0x30C0us; 0x3180us; 0xF141us; 0x3300us; 0xF3C1us; 0xF281us; 0x3240us
        0x3600us; 0xF6C1us; 0xF781us; 0x3740us; 0xF501us; 0x35C0us; 0x3480us; 0xF441us
        0x3C00us; 0xFCC1us; 0xFD81us; 0x3D40us; 0xFF01us; 0x3FC0us; 0x3E80us; 0xFE41us
        0xFA01us; 0x3AC0us; 0x3B80us; 0xFB41us; 0x3900us; 0xF9C1us; 0xF881us; 0x3840us
        0x2800us; 0xE8C1us; 0xE981us; 0x2940us; 0xEB01us; 0x2BC0us; 0x2A80us; 0xEA41us
        0xEE01us; 0x2EC0us; 0x2F80us; 0xEF41us; 0x2D00us; 0xEDC1us; 0xEC81us; 0x2C40us
        0xE401us; 0x24C0us; 0x2580us; 0xE541us; 0x2700us; 0xE7C1us; 0xE681us; 0x2640us
        0x2200us; 0xE2C1us; 0xE381us; 0x2340us; 0xE101us; 0x21C0us; 0x2080us; 0xE041us
        0xA001us; 0x60C0us; 0x6180us; 0xA141us; 0x6300us; 0xA3C1us; 0xA281us; 0x6240us
        0x6600us; 0xA6C1us; 0xA781us; 0x6740us; 0xA501us; 0x65C0us; 0x6480us; 0xA441us
        0x6C00us; 0xACC1us; 0xAD81us; 0x6D40us; 0xAF01us; 0x6FC0us; 0x6E80us; 0xAE41us
        0xAA01us; 0x6AC0us; 0x6B80us; 0xAB41us; 0x6900us; 0xA9C1us; 0xA881us; 0x6840us
        0x7800us; 0xB8C1us; 0xB981us; 0x7940us; 0xBB01us; 0x7BC0us; 0x7A80us; 0xBA41us
        0xBE01us; 0x7EC0us; 0x7F80us; 0xBF41us; 0x7D00us; 0xBDC1us; 0xBC81us; 0x7C40us
        0xB401us; 0x74C0us; 0x7580us; 0xB541us; 0x7700us; 0xB7C1us; 0xB681us; 0x7640us
        0x7200us; 0xB2C1us; 0xB381us; 0x7340us; 0xB101us; 0x71C0us; 0x7080us; 0xB041us
        0x5000us; 0x90C1us; 0x9181us; 0x5140us; 0x9301us; 0x53C0us; 0x5280us; 0x9241us
        0x9601us; 0x56C0us; 0x5780us; 0x9741us; 0x5500us; 0x95C1us; 0x9481us; 0x5440us
        0x9C01us; 0x5CC0us; 0x5D80us; 0x9D41us; 0x5F00us; 0x9FC1us; 0x9E81us; 0x5E40us
        0x5A00us; 0x9AC1us; 0x9B81us; 0x5B40us; 0x9901us; 0x59C0us; 0x5880us; 0x9841us
        0x8801us; 0x48C0us; 0x4980us; 0x8941us; 0x4B00us; 0x8BC1us; 0x8A81us; 0x4A40us
        0x4E00us; 0x8EC1us; 0x8F81us; 0x4F40us; 0x8D01us; 0x4DC0us; 0x4C80us; 0x8C41us
        0x4400us; 0x84C1us; 0x8581us; 0x4540us; 0x8701us; 0x47C0us; 0x4680us; 0x8641us
        0x8201us; 0x42C0us; 0x4380us; 0x8341us; 0x4100us; 0x81C1us; 0x8081us; 0x4040us
    |]

// ============================================================================
// CRC CALCULATION FUNCTIONS
// ============================================================================

/// Add a single byte to the CRC calculation
/// Original: PROCEDURE AddCRC(VAR crc: CARDINAL; ch: BYTE)
/// Converted to pure function that returns new CRC value
let addCrc (crc: uint16) (byte: byte) : uint16 =
    let index = int ((crc ^^^ uint16 byte) &&& 0xFFus)
    ((crc >>> 8) &&& 0xFFus) ^^^ crcTable.[index]

/// Calculate CRC-16 for a byte array
/// Original: PROCEDURE CalcCRC(BufAdr: ADDRESS; BufSize: CARDINAL): CARDINAL
/// Uses fold for functional iteration
let calcCrc (data: byte array) : uint16 =
    data |> Array.fold addCrc 0us

/// Calculate CRC-16 for a portion of a byte array
let calcCrcSlice (data: byte array) (offset: int) (length: int) : uint16 =
    let mutable crc = 0us
    for i = offset to offset + length - 1 do
        crc <- addCrc crc data.[i]
    crc

/// Calculate CRC-16 for a ReadOnlySpan (for high-performance scenarios)
let calcCrcSpan (data: ReadOnlySpan<byte>) : uint16 =
    let mutable crc = 0us
    for i = 0 to data.Length - 1 do
        crc <- addCrc crc data.[i]
    crc

/// Calculate CRC-16 for a sequence of bytes
let calcCrcSeq (data: byte seq) : uint16 =
    data |> Seq.fold addCrc 0us

// ============================================================================
// VERIFICATION FUNCTIONS
// ============================================================================

/// Verify that data with appended CRC is valid (CRC should be 0 after processing)
let verifyCrc (dataWithCrc: byte array) : bool =
    calcCrc dataWithCrc = 0us

/// Append CRC to data (returns new array with CRC appended)
let appendCrc (data: byte array) : byte array =
    let crc = calcCrc data
    let result = Array.zeroCreate (data.Length + 2)
    Array.blit data 0 result 0 data.Length
    result.[data.Length] <- byte (crc &&& 0xFFus)
    result.[data.Length + 1] <- byte (crc >>> 8)
    result

/// Extract data and verify CRC (returns data without CRC if valid)
let extractAndVerify (dataWithCrc: byte array) : byte array option =
    if dataWithCrc.Length < 2 then
        None
    else
        let dataLength = dataWithCrc.Length - 2
        let data = dataWithCrc.[0..dataLength - 1]
        let storedCrc =
            uint16 dataWithCrc.[dataLength] |||
            (uint16 dataWithCrc.[dataLength + 1] <<< 8)
        let calculatedCrc = calcCrc data
        if calculatedCrc = storedCrc then Some data
        else None

// ============================================================================
// STREAMING CRC (for processing data in chunks)
// ============================================================================

/// State for streaming CRC calculation
type CrcState = { Value: uint16 }

module CrcState =
    /// Initial state
    let init = { Value = 0us }

    /// Update state with more bytes
    let update (data: byte array) (state: CrcState) : CrcState =
        { Value = data |> Array.fold addCrc state.Value }

    /// Update state with a single byte
    let updateByte (byte: byte) (state: CrcState) : CrcState =
        { Value = addCrc state.Value byte }

    /// Get final CRC value
    let finalize (state: CrcState) : uint16 = state.Value

// Example usage:
// let crc =
//     CrcState.init
//     |> CrcState.update chunk1
//     |> CrcState.update chunk2
//     |> CrcState.finalize
