/// Computation Expressions for functional effect handling
/// These provide monadic syntax for common patterns in the RADARPAS codebase
module Radarpas.Computations

open System

// ============================================================================
// RESULT COMPUTATION EXPRESSION
// ============================================================================

/// Builder for Result<'T, 'E> computation expressions
type ResultBuilder() =
    member _.Bind(x: Result<'a, 'e>, f: 'a -> Result<'b, 'e>) : Result<'b, 'e> =
        Result.bind f x

    member _.Return(x: 'a) : Result<'a, 'e> = Ok x

    member _.ReturnFrom(x: Result<'a, 'e>) : Result<'a, 'e> = x

    member _.Zero() : Result<unit, 'e> = Ok ()

    member _.Combine(a: Result<unit, 'e>, b: unit -> Result<'b, 'e>) : Result<'b, 'e> =
        match a with
        | Ok () -> b()
        | Error e -> Error e

    member _.Delay(f: unit -> Result<'a, 'e>) : unit -> Result<'a, 'e> = f

    member _.Run(f: unit -> Result<'a, 'e>) : Result<'a, 'e> = f()

    member this.While(guard: unit -> bool, body: unit -> Result<unit, 'e>) : Result<unit, 'e> =
        if guard() then
            match body() with
            | Ok () -> this.While(guard, body)
            | Error e -> Error e
        else
            Ok ()

    member this.For(sequence: seq<'a>, body: 'a -> Result<unit, 'e>) : Result<unit, 'e> =
        use enumerator = sequence.GetEnumerator()
        this.While(
            (fun () -> enumerator.MoveNext()),
            (fun () -> body enumerator.Current))

    member _.TryWith(body: unit -> Result<'a, 'e>, handler: exn -> Result<'a, 'e>) : Result<'a, 'e> =
        try body()
        with ex -> handler ex

    member _.TryFinally(body: unit -> Result<'a, 'e>, compensation: unit -> unit) : Result<'a, 'e> =
        try body()
        finally compensation()

    member this.Using(resource: 'a when 'a :> IDisposable, body: 'a -> Result<'b, 'e>) : Result<'b, 'e> =
        this.TryFinally(
            (fun () -> body resource),
            (fun () -> if not (isNull (box resource)) then resource.Dispose()))

/// Result computation expression instance
let result = ResultBuilder()

// ============================================================================
// ASYNC RESULT COMPUTATION EXPRESSION
// ============================================================================

/// Builder for Async<Result<'T, 'E>> computation expressions
type AsyncResultBuilder() =
    member _.Bind(x: Async<Result<'a, 'e>>, f: 'a -> Async<Result<'b, 'e>>) : Async<Result<'b, 'e>> =
        async {
            let! result = x
            match result with
            | Ok value -> return! f value
            | Error e -> return Error e
        }

    member _.Bind(x: Result<'a, 'e>, f: 'a -> Async<Result<'b, 'e>>) : Async<Result<'b, 'e>> =
        async {
            match x with
            | Ok value -> return! f value
            | Error e -> return Error e
        }

    member _.Return(x: 'a) : Async<Result<'a, 'e>> =
        async { return Ok x }

    member _.ReturnFrom(x: Async<Result<'a, 'e>>) : Async<Result<'a, 'e>> = x

    member _.ReturnFrom(x: Result<'a, 'e>) : Async<Result<'a, 'e>> =
        async { return x }

    member _.Zero() : Async<Result<unit, 'e>> =
        async { return Ok () }

    member _.Delay(f: unit -> Async<Result<'a, 'e>>) : Async<Result<'a, 'e>> =
        async.Delay(f)

    member _.Combine(a: Async<Result<unit, 'e>>, b: Async<Result<'b, 'e>>) : Async<Result<'b, 'e>> =
        async {
            let! aResult = a
            match aResult with
            | Ok () -> return! b
            | Error e -> return Error e
        }

/// Async Result computation expression instance
let asyncResult = AsyncResultBuilder()

// ============================================================================
// OPTION COMPUTATION EXPRESSION
// ============================================================================

/// Builder for Option<'T> computation expressions
type OptionBuilder() =
    member _.Bind(x: 'a option, f: 'a -> 'b option) : 'b option =
        Option.bind f x

    member _.Return(x: 'a) : 'a option = Some x

    member _.ReturnFrom(x: 'a option) : 'a option = x

    member _.Zero() : unit option = Some ()

    member _.Combine(a: unit option, b: unit -> 'b option) : 'b option =
        match a with
        | Some () -> b()
        | None -> None

    member _.Delay(f: unit -> 'a option) : unit -> 'a option = f

    member _.Run(f: unit -> 'a option) : 'a option = f()

/// Option computation expression instance
let option = OptionBuilder()

// ============================================================================
// STATE COMPUTATION EXPRESSION
// ============================================================================

/// State monad type
type State<'s, 'a> = 's -> 'a * 's

/// State monad operations
module State =
    let run (state: 's) (m: State<'s, 'a>) : 'a * 's = m state

    let get : State<'s, 's> = fun s -> (s, s)

    let put (s: 's) : State<'s, unit> = fun _ -> ((), s)

    let modify (f: 's -> 's) : State<'s, unit> =
        fun s -> ((), f s)

/// Builder for State<'S, 'T> computation expressions
type StateBuilder() =
    member _.Bind(m: State<'s, 'a>, f: 'a -> State<'s, 'b>) : State<'s, 'b> =
        fun s ->
            let (a, s') = m s
            f a s'

    member _.Return(x: 'a) : State<'s, 'a> =
        fun s -> (x, s)

    member _.ReturnFrom(m: State<'s, 'a>) : State<'s, 'a> = m

    member _.Zero() : State<'s, unit> =
        fun s -> ((), s)

    member _.Combine(a: State<'s, unit>, b: unit -> State<'s, 'b>) : State<'s, 'b> =
        fun s ->
            let ((), s') = a s
            b() s'

    member _.Delay(f: unit -> State<'s, 'a>) : State<'s, 'a> =
        fun s -> f() s

/// State computation expression instance
let state = StateBuilder()

// ============================================================================
// READER COMPUTATION EXPRESSION
// ============================================================================

/// Reader monad type (for dependency injection)
type Reader<'env, 'a> = 'env -> 'a

/// Reader monad operations
module Reader =
    let run (env: 'env) (m: Reader<'env, 'a>) : 'a = m env

    let ask : Reader<'env, 'env> = id

    let asks (f: 'env -> 'a) : Reader<'env, 'a> = f

/// Builder for Reader<'Env, 'T> computation expressions
type ReaderBuilder() =
    member _.Bind(m: Reader<'env, 'a>, f: 'a -> Reader<'env, 'b>) : Reader<'env, 'b> =
        fun env ->
            let a = m env
            f a env

    member _.Return(x: 'a) : Reader<'env, 'a> =
        fun _ -> x

    member _.ReturnFrom(m: Reader<'env, 'a>) : Reader<'env, 'a> = m

    member _.Zero() : Reader<'env, unit> =
        fun _ -> ()

/// Reader computation expression instance
let reader = ReaderBuilder()

// ============================================================================
// VALIDATION COMPUTATION EXPRESSION
// ============================================================================

/// Validation result that accumulates errors
type Validation<'a, 'e> =
    | Valid of 'a
    | Invalid of 'e list

module Validation =
    let map (f: 'a -> 'b) (v: Validation<'a, 'e>) : Validation<'b, 'e> =
        match v with
        | Valid a -> Valid (f a)
        | Invalid errors -> Invalid errors

    let apply (fv: Validation<'a -> 'b, 'e>) (av: Validation<'a, 'e>) : Validation<'b, 'e> =
        match fv, av with
        | Valid f, Valid a -> Valid (f a)
        | Invalid e1, Invalid e2 -> Invalid (e1 @ e2)
        | Invalid e, _ | _, Invalid e -> Invalid e

    let ofResult (r: Result<'a, 'e>) : Validation<'a, 'e> =
        match r with
        | Ok a -> Valid a
        | Error e -> Invalid [e]

    let toResult (v: Validation<'a, 'e>) : Result<'a, 'e list> =
        match v with
        | Valid a -> Ok a
        | Invalid errors -> Error errors

/// Validation builder
type ValidationBuilder() =
    member _.Return(x: 'a) : Validation<'a, 'e> = Valid x
    member _.ReturnFrom(v: Validation<'a, 'e>) : Validation<'a, 'e> = v

    member _.Bind(v: Validation<'a, 'e>, f: 'a -> Validation<'b, 'e>) : Validation<'b, 'e> =
        match v with
        | Valid a -> f a
        | Invalid errors -> Invalid errors

/// Validation computation expression instance
let validation = ValidationBuilder()

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Traverse a list with a function that returns Result
let traverseResult (f: 'a -> Result<'b, 'e>) (list: 'a list) : Result<'b list, 'e> =
    let rec loop acc remaining =
        match remaining with
        | [] -> Ok (List.rev acc)
        | x :: xs ->
            match f x with
            | Ok y -> loop (y :: acc) xs
            | Error e -> Error e
    loop [] list

/// Traverse a list with a function that returns Async<Result>
let traverseAsyncResult (f: 'a -> Async<Result<'b, 'e>>) (list: 'a list)
    : Async<Result<'b list, 'e>> =
    async {
        let rec loop acc remaining =
            async {
                match remaining with
                | [] -> return Ok (List.rev acc)
                | x :: xs ->
                    let! result = f x
                    match result with
                    | Ok y -> return! loop (y :: acc) xs
                    | Error e -> return Error e
            }
        return! loop [] list
    }

/// Sequence a list of Results into a Result of list
let sequenceResult (results: Result<'a, 'e> list) : Result<'a list, 'e> =
    traverseResult id results

/// Sequence a list of Async<Result> into Async<Result> of list
let sequenceAsyncResult (results: Async<Result<'a, 'e>> list) : Async<Result<'a list, 'e>> =
    traverseAsyncResult id results
