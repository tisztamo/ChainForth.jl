# Conquer with words

module ChainForth

export interpreter, interpret, ForthEngine

const VERSION = "0 dev"

mutable struct ExecutionToken # todo immutable
    code::Union{Function, Vector, Number}
    immediate::Bool
    name::String
    ExecutionToken(name, code = [], immediate = false) = new(code, immediate, name)
end

Base.show(io::IO, w::ExecutionToken) = print(io, w.name)

@enum EngineMode::Int8 MODE_INTERPRET=0 MODE_COMPILE=-1

mutable struct ForthEngine
    input::IO
    out::IO
    stack::Vector{Any}
    memory::Vector{Any} # data-space, linear memory. Words are currently not defined here
    here::Int # "data-space pointer" 
    dictionary::Dict{String, ExecutionToken}
    mode::EngineMode
    latest::Union{ExecutionToken, Nothing}
    ForthEngine(input, output) = new(input, output, [], [], 0, Dict(), MODE_INTERPRET, nothing)
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
include("memory.jl")
include("time.jl")

function define_env(machine)
    define_stackops(machine)
    define_arithmetic(machine)
    define_controlstructures(machine)
    define_compiler(machine)
    define_memory(machine)
    define_time(machine)
end

function define_stdlib(machine)
    define_env(machine)
    interpret(machine, 
        op_ifthenelse * # control.jl TODO: separate the standard lib
        op_memory *
        op_time
    )
    return machine
end

include("interpret.jl")

end # module
