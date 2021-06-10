# Conquer with words

module ChainForth

export interpreter, interpret, ForthEngine

const VERSION = "0 dev"

mutable struct ExecutionToken
    code::Union{Function, Vector, Number}
    immediate::Bool
    name::String
    ExecutionToken(name, code = [], immediate = false) = new(code, immediate, name)
end

Base.show(io::IO, w::ExecutionToken) = print(io, w.name)
@enum EngineMode MODE_INTERPRET=1 MODE_COMPILE=2

mutable struct ForthEngine
    input::IO
    out::IO
    stack::Vector{Any}
    dictionary::Dict{String, ExecutionToken}
    mode::EngineMode
    latest::Union{ExecutionToken, Nothing}
    ForthEngine(input, output) = new(input, output, [], Dict(), MODE_INTERPRET, nothing)
end

getword(engine, wordstr) = get(engine.dictionary, wordstr, nothing)

function codeof(engine, wordstr)
    word = getword(engine, wordstr)
    if isnothing(word)
        return tryparse(Int64, wordstr)
    end
    return word
end

function define(engine, wordstr, definition, immediate = false)
    engine.dictionary[wordstr] = ExecutionToken(wordstr, definition, immediate)
    return engine
end

function interpreter(input = stdin, output = stdout)
    return define_stdlib(ForthEngine(input, output))
end

include("stackops.jl")
include("arithmetic.jl")
include("compile.jl")
include("control.jl")

function define_stdlib(machine)
    define_stackops(machine)
    define_artihmetic(machine)
    define_controlstructures(machine)
    define_compiler(machine)

    # redirecting input and interpret 
    oldin = machine.input
    machine.input = IOBuffer(
        op_ifthenelse # control.jl
    )
    while !eof(machine.input)
        (w, eol) = word(machine.input)
        _interpret(machine, w)
    end
    machine.input = oldin
    return machine
end

include("interpret.jl")

end # module
