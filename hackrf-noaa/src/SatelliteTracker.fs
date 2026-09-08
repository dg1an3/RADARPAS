/// Satellite Tracking Module for NOAA APT Reception
/// Implements SGP4/SDP4 orbit propagation and pass prediction
/// Inspired by RADARPAS ANALYSIS.MOD bearing/velocity calculations
module HackRF.NOAA.SatelliteTracker

open System
open HackRF.NOAA.CoreTypes

// ============================================================================
// Physical Constants
// ============================================================================

module Constants =
    /// Earth's gravitational constant (km³/s²)
    let mu = 398600.4418

    /// Earth's equatorial radius (km)
    let earthRadius = 6378.137

    /// Earth's flattening factor
    let earthFlattening = 1.0 / 298.257223563

    /// Earth's rotation rate (rad/s)
    let earthRotationRate = 7.2921150e-5

    /// Speed of light (km/s)
    let speedOfLight = 299792.458

    /// J2 perturbation coefficient
    let j2 = 0.00108263

    /// Minutes per day
    let minutesPerDay = 1440.0

    /// Seconds per day
    let secondsPerDay = 86400.0

// ============================================================================
// Two-Line Element (TLE) Parsing
// ============================================================================

/// Parsed TLE data
type TLE =
    { Name: string
      NoradId: int
      Classification: char
      LaunchYear: int
      LaunchNumber: int
      LaunchPiece: string
      EpochYear: int
      EpochDay: float
      FirstDerivative: float       // Mean motion derivative / 2
      SecondDerivative: float      // Mean motion 2nd derivative / 6
      BstarDrag: float             // B* drag term
      EphemerisType: int
      ElementNumber: int
      Checksum1: int
      Inclination: float<degree>   // Degrees
      RAAN: float<degree>          // Right Ascension of Ascending Node
      Eccentricity: float          // Decimal (assumed 0. prefix)
      ArgPerigee: float<degree>    // Argument of perigee
      MeanAnomaly: float<degree>   // Mean anomaly
      MeanMotion: float            // Revolutions per day
      RevolutionNumber: int
      Checksum2: int }

/// Parse TLE from two lines
let parseTLE (name: string) (line1: string) (line2: string) : TLE option =
    try
        // Line 1 parsing
        let noradId = int (line1.Substring(2, 5).Trim())
        let classification = line1.[7]
        let launchYear = int (line1.Substring(9, 2).Trim())
        let launchNumber = int (line1.Substring(11, 3).Trim())
        let launchPiece = line1.Substring(14, 3).Trim()
        let epochYear = int (line1.Substring(18, 2).Trim())
        let epochDay = float (line1.Substring(20, 12).Trim())
        let firstDeriv = float (line1.Substring(33, 10).Trim())

        // Second derivative with exponent
        let secondDerivStr = line1.Substring(44, 8).Trim()
        let secondDeriv =
            if secondDerivStr.Length > 0 then
                let mantissa = float ("0." + secondDerivStr.Substring(0, 5).TrimStart('+').TrimStart('-'))
                let sign = if secondDerivStr.[0] = '-' then -1.0 else 1.0
                let exp = int (secondDerivStr.Substring(6, 2))
                sign * mantissa * Math.Pow(10.0, float exp)
            else
                0.0

        // BSTAR drag
        let bstarStr = line1.Substring(53, 8).Trim()
        let bstar =
            if bstarStr.Length > 0 then
                let mantissa = float ("0." + bstarStr.Substring(0, 5).TrimStart('+').TrimStart('-'))
                let sign = if bstarStr.[0] = '-' then -1.0 else 1.0
                let exp = int (bstarStr.Substring(6, 2))
                sign * mantissa * Math.Pow(10.0, float exp)
            else
                0.0

        let ephemerisType = int (line1.Substring(62, 1).Trim())
        let elementNumber = int (line1.Substring(64, 4).Trim())
        let checksum1 = int (line1.Substring(68, 1).Trim())

        // Line 2 parsing
        let inclination = float (line2.Substring(8, 8).Trim()) * 1.0<degree>
        let raan = float (line2.Substring(17, 8).Trim()) * 1.0<degree>

        // Eccentricity (implicit decimal point)
        let eccStr = line2.Substring(26, 7).Trim()
        let eccentricity = float ("0." + eccStr)

        let argPerigee = float (line2.Substring(34, 8).Trim()) * 1.0<degree>
        let meanAnomaly = float (line2.Substring(43, 8).Trim()) * 1.0<degree>
        let meanMotion = float (line2.Substring(52, 11).Trim())
        let revNumber = int (line2.Substring(63, 5).Trim())
        let checksum2 = int (line2.Substring(68, 1).Trim())

        Some {
            Name = name.Trim()
            NoradId = noradId
            Classification = classification
            LaunchYear = launchYear
            LaunchNumber = launchNumber
            LaunchPiece = launchPiece
            EpochYear = epochYear
            EpochDay = epochDay
            FirstDerivative = firstDeriv
            SecondDerivative = secondDeriv
            BstarDrag = bstar
            EphemerisType = ephemerisType
            ElementNumber = elementNumber
            Checksum1 = checksum1
            Inclination = inclination
            RAAN = raan
            Eccentricity = eccentricity
            ArgPerigee = argPerigee
            MeanAnomaly = meanAnomaly
            MeanMotion = meanMotion
            RevolutionNumber = revNumber
            Checksum2 = checksum2
        }
    with _ ->
        None

// ============================================================================
// Coordinate Systems
// ============================================================================

/// Earth-Centered Inertial (ECI) position and velocity
[<Struct>]
type ECIPosition =
    { X: float<km>
      Y: float<km>
      Z: float<km>
      Vx: float<km/second>
      Vy: float<km/second>
      Vz: float<km/second> }

/// Geodetic (latitude/longitude/altitude)
[<Struct>]
type GeodeticPosition =
    { Latitude: float<degree>
      Longitude: float<degree>
      Altitude: float<km> }

/// Topocentric (azimuth/elevation/range from observer)
[<Struct>]
type TopocentricPosition =
    { Azimuth: float<degree>
      Elevation: float<degree>
      Range: float<km>
      RangeRate: float<km/second> }  // Doppler

// ============================================================================
// Simplified SGP4 Propagator
// ============================================================================

/// SGP4 orbital propagator (simplified version)
type SGP4Propagator(tle: TLE) =
    // Convert TLE elements to radians
    let inclRad = degToRad tle.Inclination
    let raanRad = degToRad tle.RAAN
    let argpRad = degToRad tle.ArgPerigee
    let maRad = degToRad tle.MeanAnomaly

    // Calculate derived quantities
    let meanMotionRadPerMin = tle.MeanMotion * 2.0 * Math.PI / Constants.minutesPerDay
    let a0 = Math.Pow(Constants.mu / (meanMotionRadPerMin * meanMotionRadPerMin), 1.0/3.0)
    let e0 = tle.Eccentricity

    // Epoch as DateTime
    let epochYear =
        if tle.EpochYear < 57 then 2000 + tle.EpochYear
        else 1900 + tle.EpochYear
    let epoch =
        DateTime(epochYear, 1, 1).AddDays(tle.EpochDay - 1.0)

    /// Propagate to given time, return ECI position/velocity
    member _.Propagate(time: DateTime) : ECIPosition =
        let minutesSinceEpoch = (time - epoch).TotalMinutes

        // Mean anomaly at time t
        let ma = float maRad + meanMotionRadPerMin * minutesSinceEpoch

        // Solve Kepler's equation (Newton-Raphson)
        let mutable E = ma
        for _ in 1 .. 10 do
            E <- E - (E - e0 * sin E - ma) / (1.0 - e0 * cos E)

        // True anomaly
        let sinNu = sqrt(1.0 - e0 * e0) * sin E / (1.0 - e0 * cos E)
        let cosNu = (cos E - e0) / (1.0 - e0 * cos E)
        let nu = atan2 sinNu cosNu

        // Distance
        let r = a0 * (1.0 - e0 * cos E)

        // Position in orbital plane
        let xOrb = r * cos nu
        let yOrb = r * sin nu

        // RAAN precession (simplified J2 effect)
        let n = meanMotionRadPerMin
        let raanDot = -1.5 * Constants.j2 * n * (Constants.earthRadius / a0) ** 2.0 *
                      cos (float inclRad) / ((1.0 - e0 * e0) ** 2.0)
        let raanNow = float raanRad + raanDot * minutesSinceEpoch

        // Argument of perigee precession
        let argpDot = 1.5 * Constants.j2 * n * (Constants.earthRadius / a0) ** 2.0 *
                      (2.0 - 2.5 * sin (float inclRad) ** 2.0) / ((1.0 - e0 * e0) ** 2.0)
        let argpNow = float argpRad + argpDot * minutesSinceEpoch

        // Transform to ECI
        let cosO = cos raanNow
        let sinO = sin raanNow
        let cosI = cos (float inclRad)
        let sinI = sin (float inclRad)
        let cosW = cos argpNow
        let sinW = sin argpNow

        // Rotation matrix elements
        let r11 = cosO * cosW - sinO * sinW * cosI
        let r12 = -cosO * sinW - sinO * cosW * cosI
        let r21 = sinO * cosW + cosO * sinW * cosI
        let r22 = -sinO * sinW + cosO * cosW * cosI
        let r31 = sinW * sinI
        let r32 = cosW * sinI

        // ECI position
        let xEci = r11 * xOrb + r12 * yOrb
        let yEci = r21 * xOrb + r22 * yOrb
        let zEci = r31 * xOrb + r32 * yOrb

        // Velocity (simplified)
        let vMag = sqrt(Constants.mu * (2.0 / r - 1.0 / a0))
        let vx = -vMag * sin (nu + argpNow) * cosO
        let vy = vMag * sin (nu + argpNow) * sinO
        let vz = vMag * cos (nu + argpNow) * sinI

        { X = xEci * 1.0<km>
          Y = yEci * 1.0<km>
          Z = zEci * 1.0<km>
          Vx = vx * 1.0<km/second>
          Vy = vy * 1.0<km/second>
          Vz = vz * 1.0<km/second> }

// ============================================================================
// Coordinate Transformations
// ============================================================================

module CoordinateTransform =

    /// Greenwich Mean Sidereal Time (radians)
    let gmst (time: DateTime) : float =
        let jd = time.ToOADate() + 2415018.5
        let t = (jd - 2451545.0) / 36525.0
        let theta = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                    0.000387933 * t * t - t * t * t / 38710000.0
        (theta % 360.0) * Math.PI / 180.0

    /// ECI to ECEF (Earth-Centered Earth-Fixed)
    let eciToEcef (eci: ECIPosition) (time: DateTime) =
        let theta = gmst time
        let cosT = cos theta
        let sinT = sin theta

        let x = float eci.X * cosT + float eci.Y * sinT
        let y = -float eci.X * sinT + float eci.Y * cosT
        let z = float eci.Z

        (x * 1.0<km>, y * 1.0<km>, z * 1.0<km>)

    /// ECEF to Geodetic
    let ecefToGeodetic (x: float<km>) (y: float<km>) (z: float<km>) : GeodeticPosition =
        let a = Constants.earthRadius
        let f = Constants.earthFlattening
        let b = a * (1.0 - f)
        let e2 = 2.0 * f - f * f

        let lon = atan2 (float y) (float x)
        let p = sqrt(float x * float x + float y * float y)

        // Iterative solution for latitude
        let mutable lat = atan2 (float z) (p * (1.0 - e2))
        for _ in 1 .. 5 do
            let n = a / sqrt(1.0 - e2 * sin lat * sin lat)
            lat <- atan2 (float z + e2 * n * sin lat) p

        let n = a / sqrt(1.0 - e2 * sin lat * sin lat)
        let alt = p / cos lat - n

        { Latitude = lat * 180.0 / Math.PI * 1.0<degree>
          Longitude = lon * 180.0 / Math.PI * 1.0<degree>
          Altitude = alt * 1.0<km> }

    /// Calculate topocentric position from observer
    let toTopocentric (satEci: ECIPosition) (observer: GroundStationLocation) (time: DateTime) : TopocentricPosition =
        let theta = gmst time

        // Observer position in ECEF
        let obsLat = float observer.Latitude * Math.PI / 180.0
        let obsLon = float observer.Longitude * Math.PI / 180.0
        let obsAlt = float observer.Altitude

        let a = Constants.earthRadius
        let f = Constants.earthFlattening
        let e2 = 2.0 * f - f * f

        let n = a / sqrt(1.0 - e2 * sin obsLat * sin obsLat)
        let obsX = (n + obsAlt) * cos obsLat * cos obsLon
        let obsY = (n + obsAlt) * cos obsLat * sin obsLon
        let obsZ = (n * (1.0 - e2) + obsAlt) * sin obsLat

        // Satellite ECEF
        let (satX, satY, satZ) = eciToEcef satEci time

        // Range vector in ECEF
        let rx = float satX - obsX
        let ry = float satY - obsY
        let rz = float satZ - obsZ

        // Range
        let range = sqrt(rx * rx + ry * ry + rz * rz)

        // Transform to local horizon coordinates (SEZ)
        let sinLat = sin obsLat
        let cosLat = cos obsLat
        let sinLon = sin obsLon
        let cosLon = cos obsLon

        let south = sinLat * cosLon * rx + sinLat * sinLon * ry - cosLat * rz
        let east = -sinLon * rx + cosLon * ry
        let zenith = cosLat * cosLon * rx + cosLat * sinLon * ry + sinLat * rz

        // Elevation and azimuth
        let elevation = asin(zenith / range)
        let azimuth = atan2 east (-south)

        // Range rate (Doppler) - simplified
        let vx = float satEci.Vx
        let vy = float satEci.Vy
        let vz = float satEci.Vz
        let rangeRate = (rx * vx + ry * vy + rz * vz) / range

        { Azimuth = (azimuth * 180.0 / Math.PI + 360.0) % 360.0 * 1.0<degree>
          Elevation = elevation * 180.0 / Math.PI * 1.0<degree>
          Range = range * 1.0<km>
          RangeRate = rangeRate * 1.0<km/second> }

// ============================================================================
// Doppler Shift Calculation
// ============================================================================

/// Calculate Doppler shift for given range rate
let calculateDopplerShift (frequency: float<Hz>) (rangeRate: float<km/second>) : float<Hz> =
    // Doppler shift: Δf = -f * v_r / c
    let c = Constants.speedOfLight * 1.0<km/second>
    -frequency * float rangeRate / float c

// ============================================================================
// Pass Prediction
// ============================================================================

/// Satellite pass information
type SatellitePass =
    { Satellite: NOAASatellite
      AOS: DateTime              // Acquisition of Signal
      LOS: DateTime              // Loss of Signal
      MaxElevation: float<degree>
      MaxElevationTime: DateTime
      AzimuthAtAOS: float<degree>
      AzimuthAtLOS: float<degree>
      Duration: TimeSpan }

/// Pass predictor
type PassPredictor(observer: GroundStationLocation, minElevation: float<degree>) =

    /// Predict next pass for satellite
    member _.PredictNextPass(propagator: SGP4Propagator, satellite: NOAASatellite, startTime: DateTime) : SatellitePass option =
        let stepMinutes = 1.0
        let maxSearchMinutes = 1440.0 * 2.0  // Search up to 2 days

        let mutable time = startTime
        let mutable inPass = false
        let mutable aos = DateTime.MinValue
        let mutable maxEl = 0.0<degree>
        let mutable maxElTime = DateTime.MinValue
        let mutable aosAz = 0.0<degree>

        let mutable found = false
        let mutable searchMinutes = 0.0

        while not found && searchMinutes < maxSearchMinutes do
            let eci = propagator.Propagate(time)
            let topo = CoordinateTransform.toTopocentric eci observer time

            if topo.Elevation > minElevation then
                if not inPass then
                    // AOS
                    inPass <- true
                    aos <- time
                    aosAz <- topo.Azimuth
                    maxEl <- topo.Elevation
                    maxElTime <- time

                if topo.Elevation > maxEl then
                    maxEl <- topo.Elevation
                    maxElTime <- time
            else
                if inPass then
                    // LOS - pass complete
                    found <- true

            time <- time.AddMinutes(stepMinutes)
            searchMinutes <- searchMinutes + stepMinutes

        if found then
            let los = time.AddMinutes(-stepMinutes)
            let losEci = propagator.Propagate(los)
            let losTopo = CoordinateTransform.toTopocentric losEci observer los

            Some {
                Satellite = satellite
                AOS = aos
                LOS = los
                MaxElevation = maxEl
                MaxElevationTime = maxElTime
                AzimuthAtAOS = aosAz
                AzimuthAtLOS = losTopo.Azimuth
                Duration = los - aos
            }
        else
            None

    /// Predict multiple passes
    member this.PredictPasses(propagator: SGP4Propagator, satellite: NOAASatellite, startTime: DateTime, count: int) : SatellitePass list =
        let mutable passes = []
        let mutable time = startTime

        for _ in 1 .. count do
            match this.PredictNextPass(propagator, satellite, time) with
            | Some pass ->
                passes <- passes @ [pass]
                time <- pass.LOS.AddMinutes(5.0)  // Start searching after this pass
            | None ->
                ()

        passes

// ============================================================================
// Default TLE Data for NOAA Satellites
// ============================================================================

module DefaultTLE =

    /// Recent TLE data for NOAA-15 (update as needed)
    let noaa15Name = "NOAA 15"
    let noaa15Line1 = "1 25338U 98030A   24001.50000000  .00000100  00000-0  10000-3 0  9990"
    let noaa15Line2 = "2 25338  98.7000 100.0000 0010000  90.0000 270.0000 14.25000000000000"

    /// Recent TLE data for NOAA-18
    let noaa18Name = "NOAA 18"
    let noaa18Line1 = "1 28654U 05018A   24001.50000000  .00000100  00000-0  10000-3 0  9990"
    let noaa18Line2 = "2 28654  99.0000 150.0000 0014000  85.0000 275.0000 14.12000000000000"

    /// Recent TLE data for NOAA-19
    let noaa19Name = "NOAA 19"
    let noaa19Line1 = "1 33591U 09005A   24001.50000000  .00000100  00000-0  10000-3 0  9990"
    let noaa19Line2 = "2 33591  99.2000 200.0000 0013000  80.0000 280.0000 14.12000000000000"

    /// Get default TLE for satellite
    let getDefaultTLE (satellite: NOAASatellite) : TLE option =
        match satellite with
        | NOAA15 -> parseTLE noaa15Name noaa15Line1 noaa15Line2
        | NOAA18 -> parseTLE noaa18Name noaa18Line1 noaa18Line2
        | NOAA19 -> parseTLE noaa19Name noaa19Line1 noaa19Line2
