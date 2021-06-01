module Forth

export VM, interpreter, execute

struct LiteralParser
    out::IO
    stack::Vector{Any}
end

function what(out)
    print(out, "?")
end

function _interpret(parser::LiteralParser, wordstr)
    wordstr == "" && return false
    parsed = tryparse(Float64, wordstr)
    if isnothing(parsed)
        what(parser.out)
        return false
    end
    push!(parser.stack, parsed)
    return true
end

function codeof(parser::LiteralParser, wordstr) 
    if _interpret(parser, wordstr)
        return pop!(parser.stack)
    else
        return nothing
    end
end

struct VM
    super::LiteralParser
    stack::Vector{Any}
    dictionary::Dict{String, Function}
    out::IO
    mode::Nothing
    VM(out = stdout) = begin
        stack = []
        return new(LiteralParser(out, stack), stack, Dict(), out, nothing)
    end
end

struct Word
    code::Union{Function, Vector, Number}
end

@enum EngineMode MODE_INTERPRET=1 MODE_COMPILE=2

mutable struct ForthEngine
    super::VM
    stack::Vector{Any}
    out::IO
    dictionary::Dict{String, Word}
    mode::EngineMode
    word_compiling::Union{Word, Nothing}
    ForthEngine(vm) = new(vm, vm.stack, vm.out, Dict(), MODE_INTERPRET, nothing)
end

getword(preter, wordstr) = get(preter.dictionary, wordstr, nothing)

function codeof(preter, wordstr)
    word = getword(preter, wordstr)
    if isnothing(word)
        return codeof(preter.super, wordstr)
    end
    return word
end

function _interpret(preter, wordstr)
    if preter.mode == MODE_COMPILE && wordstr != ";"
        if isnothing(preter.word_compiling)
            preter.word_compiling = preter.dictionary[wordstr] = Word([])
        else
            code = codeof(preter, wordstr)
            if isnothing(code)
                return false
            else
                push!(preter.word_compiling.code, code)
                return true
            end
        end
    else
        word = getword(preter, wordstr)
        if isnothing(word)
            return _interpret(preter.super, wordstr)
        end
        execute(preter, word)
        return true
    end
end

function execute(preter, word::Word)
    if word.code isa Function
        word.code(preter)
    elseif word.code isa Number
        push!(preter.stack, word.code)
    else
        for word in word.code
            execute(preter, word)
        end
    end
end

execute(preter, num::Number) = push!(preter.stack, num)

function _define(preter, word, definition)
    preter.dictionary[word] = Word(definition)
    return preter
end

function interpreter(out = stdout)
    return define_stdlib(ForthEngine(VM(out)))
end

function define_stdlib(machine)
    _define(machine, "+", gen_op_nn_n(+))
    _define(machine, "-", gen_op_nn_n(-))
    _define(machine, "*", gen_op_nn_n(*))
    _define(machine, "/", gen_op_nn_n(/))
    _define(machine, ".", op_print)
    _define(machine, ":", op_colon)
    _define(machine, ";", op_semicolon)
    _define(machine, "dup", op_dup)
    _define(machine, "swap", op_swap)
end

function gen_op_nn_n(operation)
    return machine -> begin
        arg1 = pop!(machine.stack)
        arg2 = pop!(machine.stack)
        push!(machine.stack, operation(arg1, arg2))
    end
end

op_print(machine) = print(machine.out, pop!(machine.stack))
op_colon(machine) = machine.mode = MODE_COMPILE
op_dup(machine) = push!(machine.stack, machine.stack[end])

function op_swap(machine)
    top = machine.stack[end]
    machine.stack[end] = machine.stack[end-1]
    machine.stack[end-1] = top
end

function op_semicolon(machine)
    if machine.mode != MODE_COMPILE
        what(machine.out)
        return nothing
    end
    machine.mode = MODE_INTERPRET
    machine.word_compiling = nothing
end

function interpret(machine, sentence::String)
    for wordstr in split(sentence, ' ')
        _interpret(machine, wordstr)
    end
end

function repl(machine = interpreter())
    print(machine.out, "Simple Forth:\n")
    while true
        try
            interpret(machine, readline())
        catch e
            if e isa ArgumentError && e.msg == "array must be non-empty"
                print(machine.out, "Stack underflow")
            elseif e isa InterruptException
                return
            else
                print(e)
            end
        end
        println(machine.out)
    end
end

end # module
