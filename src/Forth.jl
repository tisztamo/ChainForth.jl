module Forth

export VM, interpreter, execute

struct LiteralParser
    out::IO
    stack::Vector{Any}
end

function what(out)
    print(out, "?")
end

function interpret(parser::LiteralParser, word)
    word == "" && return nothing
    parsed = tryparse(Float64, word)
    if isnothing(parsed)
        what(parser.out)
        return nothing
    end
    push!(parser.stack, parsed)
    return nothing
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

@enum InterpreterMode MODE_INTERPRET=1 MODE_PUSH=2

mutable struct Interpreter
    super::VM
    stack::Vector{Any}
    out::IO
    dictionary::Dict
    mode::InterpreterMode
    Interpreter(vm) = new(vm, vm.stack, vm.out, Dict(), MODE_INTERPRET)
end

function interpret(preter, word)
    if preter.mode == MODE_PUSH && word != ";"
        push!(preter.stack, word)
    else
        definition = get(preter.dictionary, word, nothing)
        if isnothing(definition)
            interpret(preter.super, word)
        else
            execute(preter, definition)
        end
        return nothing
    end
end

function execute(preter, definition::Function)
    definition(preter)
    return nothing
end

function execute(preter, definition::Vector)
    for word in definition
        interpret(preter, word)
    end
    return nothing
end

function define(preter, word, definition)
    preter.dictionary[word] = definition
    return preter
end

function interpreter(out = stdout)
    return define_stdlib(Interpreter(VM(out)))
end

function define_stdlib(machine)
    define(machine, "+", gen_op_nn_n(+))
    define(machine, "-", gen_op_nn_n(-))
    define(machine, "*", gen_op_nn_n(*))
    define(machine, "/", gen_op_nn_n(/))
    define(machine, ".", op_print)
    define(machine, ":", op_colon)
    define(machine, ";", op_semicolon)
    define(machine, "dup", op_dup)
    define(machine, "swap", op_swap)
end

function gen_op_nn_n(operation)
    return machine -> begin
        arg1 = pop!(machine.stack)
        arg2 = pop!(machine.stack)
        push!(machine.stack, operation(arg1, arg2))
    end
end

function op_print(machine)
    print(machine.out, pop!(machine.stack))
end

function op_colon(machine)
    machine.mode = MODE_PUSH
    push!(machine.stack, ":")
end

function op_dup(machine)
    push!(machine.stack, machine.stack[end])
end

function op_swap(machine)
    top = machine.stack[end]
    machine.stack[end] = machine.stack[end-1]
    machine.stack[end-1] = top
end

function op_semicolon(machine)
    if machine.mode != MODE_PUSH
        what(machine.out)
        return nothing
    end
    machine.mode = MODE_INTERPRET
    definition = []
    while true
        word = pop!(machine.stack)
        if word == ":"
            define(machine, definition[1], definition[2:end])
            return nothing
        end
        pushfirst!(definition, word)
    end
end

function execute(machine, sentence::String)
    return execute(machine, split(sentence, ' '))
end

function repl(machine = interpreter())
    print(machine.out, "Simple Forth:\n")
    while true
        try
            execute(machine, readline())
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
