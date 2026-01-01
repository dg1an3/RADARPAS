/// Picture management module
/// Translated from Modula-2 PICTURES.DEF/MOD
module Radarpas.Pictures

open System
open System.IO
open Radarpas.CoreTypes
open Radarpas.IO
open Radarpas.TimeDate

// ============================================================================
// PICTURE OPERATIONS (Pure Functions)
// ============================================================================

/// Generate filename for a picture
/// Original: PROCEDURE FileName(Picture: PictureRec; VAR NameofFile: ARRAY OF CHAR)
let fileName (picture: PictureRec) : string =
    PictureRec.generateFileName picture

/// Parse filename to get picture parameters
/// Original: PROCEDURE FileParam(VAR Picture: PictureRec; NameofFile: ARRAY OF CHAR; VAR OK: BOOLEAN)
let fileParam (nameOfFile: string) : Result<PictureRec, string> =
    PictureRec.parseFileName nameOfFile

// ============================================================================
// PICTURE LIST OPERATIONS (Pure Functions)
// ============================================================================

/// Find insertion position for a picture based on chronological order
let private findInsertPosition (pictures: PictureRec list) (newPic: PictureRec) : int =
    pictures
    |> List.tryFindIndex (fun p ->
        match Time.compare p.TimeOfPic newPic.TimeOfPic with
        | c when c < 0 -> true  // Found earlier picture
        | _ -> false)
    |> Option.defaultValue (List.length pictures)

/// Add a picture to the list in chronological order
/// Original: PROCEDURE AddPicture(VAR PicList: ARRAY OF PictureRec; VAR MaxPic: CARDINAL;
///                                ForPicture: PictureRec; VAR Number: CARDINAL)
/// Returns: (updated list, insertion index)
let addPicture (pictures: PictureRec list) (newPicture: PictureRec)
    : PictureRec list * int =
    let insertPos = findInsertPosition pictures newPicture
    let before = List.take insertPos pictures
    let after = List.skip insertPos pictures
    let newList = before @ [newPicture] @ after
    (newList, insertPos)

/// Delete a picture from the list by index
/// Original: PROCEDURE DeletePicture(VAR PicList: ARRAY OF PictureRec;
///                                   VAR MaxPic: CARDINAL; PictureNum: CARDINAL)
/// Returns: updated list and the deleted picture (for cleanup)
let deletePicture (pictures: PictureRec list) (index: int)
    : (PictureRec list * PictureRec option) =
    if index < 0 || index >= List.length pictures then
        (pictures, None)
    else
        let deleted = pictures.[index]
        let newList =
            pictures
            |> List.indexed
            |> List.filter (fun (i, _) -> i <> index)
            |> List.map snd
        (newList, Some deleted)

/// Find picture by time
let findByTime (pictures: PictureRec list) (time: Time) : PictureRec option =
    pictures |> List.tryFind (fun p -> Time.compare p.TimeOfPic time = 0)

/// Find picture by filename
let findByFileName (pictures: PictureRec list) (name: string) : PictureRec option =
    pictures |> List.tryFind (fun p -> fileName p = name)

/// Get pictures within a time range
let filterByTimeRange (pictures: PictureRec list) (startTime: Time) (endTime: Time)
    : PictureRec list =
    pictures
    |> List.filter (fun p ->
        Time.compare p.TimeOfPic startTime >= 0 &&
        Time.compare p.TimeOfPic endTime <= 0)

/// Sort pictures by time (most recent first)
let sortByTimeDescending (pictures: PictureRec list) : PictureRec list =
    pictures |> List.sortByDescending (fun p -> p.TimeOfPic.Day, p.TimeOfPic.Minute)

/// Sort pictures by time (oldest first)
let sortByTimeAscending (pictures: PictureRec list) : PictureRec list =
    pictures |> List.sortBy (fun p -> p.TimeOfPic.Day, p.TimeOfPic.Minute)

// ============================================================================
// PICTURE FILE I/O (Effectful Functions)
// ============================================================================

/// Save a picture to disk
/// Original: PROCEDURE SavePicture(VAR ForPicture: PictureRec; VAR SaveDone: BOOLEAN)
let savePicture (directory: string) (picture: PictureRec)
    : Async<Result<PictureRec, string>> =
    async {
        match picture.Data with
        | None ->
            return Error "No data to save"
        | Some data ->
            let filePath = Path.Combine(directory, fileName picture)
            match! Async.readAllBytes filePath |> Async.Ignore |> Async.Catch with
            | Choice1Of2 _ -> ()  // File may or may not exist
            | Choice2Of2 _ -> ()

            let! result = Async.writeAllBytes filePath data
            match result with
            | Ok () ->
                // Mark as saved
                let updatedPic = { picture with Flags = picture.Flags |> PicFlagSet.remove NotSaved }
                return Ok updatedPic
            | Error msg ->
                return Error msg
    }

/// Load a picture from disk
/// Original: Part of PROCEDURE SelectPicture
let loadPicture (directory: string) (picture: PictureRec)
    : Async<Result<PictureRec, string>> =
    async {
        match picture.Data with
        | Some _ ->
            // Already loaded
            return Ok picture
        | None ->
            let filePath = Path.Combine(directory, fileName picture)
            let! result = Async.readAllBytes filePath
            match result with
            | Ok data ->
                let updatedPic = {
                    picture with
                        Data = Some data
                        Size = uint32 data.Length
                        Flags = picture.Flags |> PicFlagSet.remove NotSaved
                }
                return Ok updatedPic
            | Error msg ->
                return Error msg
    }

/// Delete a picture file from disk
let deletePictureFile (directory: string) (picture: PictureRec)
    : Result<unit, string> =
    let filePath = Path.Combine(directory, fileName picture)
    deleteFile filePath

/// Load all picture headers from a directory
let loadPictureHeaders (directory: string) : Async<Result<PictureRec list, string>> =
    async {
        try
            let files = Directory.GetFiles(directory, "*.WX")
            let pictures =
                files
                |> Array.choose (fun filePath ->
                    let name = Path.GetFileName(filePath)
                    let fileInfo = FileInfo(filePath)
                    match fileParam name with
                    | Ok pic ->
                        // Update with file date and size
                        let day = Time.packDate fileInfo.CreationTime.Year
                                                fileInfo.CreationTime.Month
                                                fileInfo.CreationTime.Day
                        Some {
                            pic with
                                TimeOfPic = { pic.TimeOfPic with Day = day }
                                Size = uint32 fileInfo.Length
                        }
                    | Error _ -> None)
                |> Array.toList
                |> sortByTimeDescending
            return Ok pictures
        with ex ->
            return Error ex.Message
    }

// ============================================================================
// MEMORY MANAGEMENT (with LRU eviction)
// ============================================================================

/// Picture cache state
type PictureCache = {
    Pictures: Map<string, PictureRec>  // Keyed by filename
    AccessOrder: string list           // Most recent first
    MaxMemory: int64
    CurrentMemory: int64
}

module PictureCache =
    /// Create empty cache
    let create (maxMemory: int64) : PictureCache = {
        Pictures = Map.empty
        AccessOrder = []
        MaxMemory = maxMemory
        CurrentMemory = 0L
    }

    /// Calculate size of a picture's data
    let private pictureSize (pic: PictureRec) : int64 =
        pic.Data |> Option.map (fun d -> int64 d.Length) |> Option.defaultValue 0L

    /// Update access order (move to front)
    let private touch (key: string) (cache: PictureCache) : PictureCache =
        let newOrder = key :: (cache.AccessOrder |> List.filter ((<>) key))
        { cache with AccessOrder = newOrder }

    /// Find least recently used picture with data
    let private findLru (cache: PictureCache) : string option =
        cache.AccessOrder
        |> List.rev
        |> List.tryFind (fun key ->
            cache.Pictures
            |> Map.tryFind key
            |> Option.bind (fun p -> p.Data)
            |> Option.isSome)

    /// Evict pictures until enough memory is free
    /// Original: PROCEDURE ReserveMem(...)
    let evictUntilFree (requiredSize: int64) (directory: string) (cache: PictureCache)
        : Async<Result<PictureCache, string>> =
        async {
            let rec evictLoop currentCache =
                async {
                    let freeSpace = currentCache.MaxMemory - currentCache.CurrentMemory
                    if freeSpace >= requiredSize then
                        return Ok currentCache
                    else
                        match findLru currentCache with
                        | None ->
                            return Error "Cannot free enough memory - no pictures to evict"
                        | Some picKey ->
                            let pic = currentCache.Pictures.[picKey]

                            // Save if not saved
                            let! saveResult =
                                if PicFlagSet.contains NotSaved pic.Flags then
                                    savePicture directory pic
                                else
                                    async { return Ok pic }

                            match saveResult with
                            | Error msg ->
                                return Error (sprintf "Failed to save before eviction: %s" msg)
                            | Ok savedPic ->
                                // Evict data from memory
                                let freedSize = pictureSize pic
                                let evictedPic = { savedPic with Data = None }
                                let newCache = {
                                    currentCache with
                                        Pictures = currentCache.Pictures |> Map.add picKey evictedPic
                                        CurrentMemory = currentCache.CurrentMemory - freedSize
                                }
                                return! evictLoop newCache
                }
            return! evictLoop cache
        }

    /// Add or update a picture in the cache
    let add (picture: PictureRec) (directory: string) (cache: PictureCache)
        : Async<Result<PictureCache, string>> =
        async {
            let key = fileName picture
            let newSize = pictureSize picture
            let oldSize =
                cache.Pictures
                |> Map.tryFind key
                |> Option.bind (fun p -> p.Data)
                |> Option.map (fun d -> int64 d.Length)
                |> Option.defaultValue 0L

            let sizeNeeded = newSize - oldSize

            // Evict if necessary
            let! evictResult =
                if sizeNeeded > 0L then
                    evictUntilFree sizeNeeded directory cache
                else
                    async { return Ok cache }

            match evictResult with
            | Error msg -> return Error msg
            | Ok evictedCache ->
                let newCache = {
                    evictedCache with
                        Pictures = evictedCache.Pictures |> Map.add key picture
                        CurrentMemory = evictedCache.CurrentMemory + sizeNeeded
                }
                return Ok (touch key newCache)
        }

    /// Get a picture from cache (loads from disk if needed)
    let get (key: string) (directory: string) (cache: PictureCache)
        : Async<Result<PictureRec * PictureCache, string>> =
        async {
            match cache.Pictures |> Map.tryFind key with
            | None ->
                return Error "Picture not in cache"
            | Some pic when pic.Data.IsSome ->
                // Already in memory
                return Ok (pic, touch key cache)
            | Some pic ->
                // Need to load from disk
                let! loadResult = loadPicture directory pic
                match loadResult with
                | Error msg ->
                    return Error msg
                | Ok loadedPic ->
                    let! addResult = add loadedPic directory cache
                    match addResult with
                    | Error msg -> return Error msg
                    | Ok newCache -> return Ok (loadedPic, newCache)
        }

// ============================================================================
// PICTURE DISPLAY
// ============================================================================

/// Picture display state for UI
type PictureListState = {
    Pictures: PictureRec list
    SelectedIndex: int
    TopIndex: int       // First visible item
    PageSize: int       // Number of visible items
}

module PictureListState =
    let create (pictures: PictureRec list) (pageSize: int) : PictureListState = {
        Pictures = pictures
        SelectedIndex = if List.isEmpty pictures then -1 else 0
        TopIndex = 0
        PageSize = pageSize
    }

    let moveUp (state: PictureListState) : PictureListState =
        if state.SelectedIndex <= 0 then state
        else
            let newIndex = state.SelectedIndex - 1
            let newTop = if newIndex < state.TopIndex then newIndex else state.TopIndex
            { state with SelectedIndex = newIndex; TopIndex = newTop }

    let moveDown (state: PictureListState) : PictureListState =
        let maxIndex = List.length state.Pictures - 1
        if state.SelectedIndex >= maxIndex then state
        else
            let newIndex = state.SelectedIndex + 1
            let newTop =
                if newIndex >= state.TopIndex + state.PageSize
                then newIndex - state.PageSize + 1
                else state.TopIndex
            { state with SelectedIndex = newIndex; TopIndex = newTop }

    let pageUp (state: PictureListState) : PictureListState =
        let newIndex = max 0 (state.SelectedIndex - state.PageSize)
        let newTop = max 0 (state.TopIndex - state.PageSize)
        { state with SelectedIndex = newIndex; TopIndex = newTop }

    let pageDown (state: PictureListState) : PictureListState =
        let maxIndex = List.length state.Pictures - 1
        let newIndex = min maxIndex (state.SelectedIndex + state.PageSize)
        let newTop = min (maxIndex - state.PageSize + 1 |> max 0) (state.TopIndex + state.PageSize)
        { state with SelectedIndex = newIndex; TopIndex = newTop }

    let selectedPicture (state: PictureListState) : PictureRec option =
        if state.SelectedIndex >= 0 && state.SelectedIndex < List.length state.Pictures
        then Some state.Pictures.[state.SelectedIndex]
        else None

    let visiblePictures (state: PictureListState) : (int * PictureRec) list =
        state.Pictures
        |> List.indexed
        |> List.skip state.TopIndex
        |> List.truncate state.PageSize

// ============================================================================
// PICTURE MENU ACTIONS
// ============================================================================

/// Actions that can be performed in the picture menu
type PictureMenuAction =
    | Select of int
    | Delete of int
    | Cancel
    | Refresh

/// Format a picture entry for display
/// Original: PROCEDURE WritePictureEntry(PictureNum: CARDINAL)
let formatPictureEntry (pic: PictureRec) : string =
    sprintf "%s %s %2d   %2d   %2d"
        (TimeDate.Format.dateShort pic.TimeOfPic)
        (TimeDate.Format.timeShort pic.TimeOfPic)
        pic.Tilt
        pic.Range
        pic.Gain
