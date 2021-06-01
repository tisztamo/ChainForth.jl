module Forth

export VM, interpreter, execute

struct LiteralParser end

function codeof(::LiteralParser, wordstr)
    wordstr == "" && return false
    parsed = tryparse(Float64, wordstr)
    if isnothing(parsed)
        return nothing
    end
    return parsed
end

printerr(out, err) = return print(out, err)
what(out) = return printerr(out, "?")

struct VM
    super::LiteralParser
    stack::Vector{Any}
    dictionary::Dict{String, Function}
    out::IO
    mode::Nothing
    VM(out = stdout) = begin
        stack = []
        return new(LiteralParser(), stack, Dict(), out, nothing)
    end
end

mutable struct Word
    code::Union{Function, Vector, Number}
    immediate::Bool
    Word(code = [], immediate = false) = new(code, immediate)
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

function _compile(preter, wordstr)
    if isnothing(preter.word_compiling)
        preter.word_compiling = preter.dictionary[wordstr] = Word()
        return true
    else
        word = codeof(preter, wordstr)
        if isnothing(word)
            return false
        elseif word isa Word && word.immediate
            execute(preter, word)
            return true
        else
            push!(preter.word_compiling.code, word)
            return true
        end
    end
end

function _interpret(preter, wordstr)
    word = codeof(preter, wordstr)
    if preter.mode == MODE_COMPILE && (!(word isa Word) || !word.immediate)
        return _compile(preter, wordstr)
    else
        if isnothing(word)
            return printerr(preter.out, "$(wordstr)?")
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

function _define(preter, word, definition, immediate = false)
    preter.dictionary[word] = Word(definition, immediate)
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
    _define(machine, ";", op_semicolon, true)
    _define(machine, "immediate", op_immediate, true)
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
op_dup(machine) = push!(machine.stack, machine.stack[end])

function op_colon(machine)
    if machine.mode != MODE_INTERPRET
        return what(machine.out)
    end
    machine.mode = MODE_COMPILE
    machine.word_compiling = nothing
end

function op_swap(machine)
    top = machine.stack[end]
    machine.stack[end] = machine.stack[end-1]
    machine.stack[end-1] = top
end

function op_semicolon(machine)
    if machine.mode != MODE_COMPILE
        return what(machine.out)
    end
    machine.mode = MODE_INTERPRET
end

function op_immediate(machine)
    if machine.mode != MODE_INTERPRET || isnothing(machine.word_compiling)
        return printerr(machine.out, "Invalid IMMEDIATE")
    end
    machine.word_compiling.immediate = true
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
