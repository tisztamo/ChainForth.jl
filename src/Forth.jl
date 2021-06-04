module Forth

export interpreter, interpret

struct LiteralParser end

function parselit(wordstr)
    wordstr == "" && return false
    parsed = tryparse(Int64, wordstr)
    if isnothing(parsed)
        return nothing
    end
    return parsed
end

printerr(out, err) = return print(out, err)
what(out) = return printerr(out, "?")

mutable struct Word
    code::Union{Function, Vector, Number}
    immediate::Bool
    Word(code = [], immediate = false) = new(code, immediate)
end

@enum EngineMode MODE_INTERPRET=1 MODE_COMPILE=2

mutable struct ForthEngine
    stack::Vector{Any}
    out::IO
    dictionary::Dict{String, Word}
    mode::EngineMode
    latest::Union{Word, Nothing}
    ForthEngine(out) = new([], out, Dict(), MODE_INTERPRET, nothing)
end

getword(engine, wordstr) = get(engine.dictionary, wordstr, nothing)

function codeof(engine, wordstr)
    word = getword(engine, wordstr)
    if isnothing(word)
        return parselit(wordstr)
    end
    return word
end

function _compile(engine, wordstr)
    if isnothing(engine.latest)
        engine.latest = engine.dictionary[wordstr] = Word()
        return true
    else
        word = codeof(engine, wordstr)
        if isnothing(word)
            return false
        elseif word isa Word && word.immediate
            execute_codeword(engine, word) # ???? branching?
            return true
        else
            push!(engine.latest.code, word)
            return true
        end
    end
end

function _interpret(engine, wordstr)
    word = codeof(engine, wordstr)
    if engine.mode == MODE_COMPILE && (!(word isa Word) || !word.immediate)
        return _compile(engine, wordstr)
    else
        if isnothing(word)
            return printerr(engine.out, "$(wordstr)?")
        end
        execute_codeword(engine, word) # No branching during interpretation
        return true
    end
end

# Execute the word either by dispatching to its Julia function if its a native word,
# or by recursively codeword-ing its compiled definition. (The "inner interpreter")
function execute_codeword(engine, word::Word)
    if word.code isa Function
        return word.code(engine)
    elseif word.code isa Number
        push!(engine.stack, word.code)
        return 1
    else
        idx = 1 # DOCOL
        codelength = length(word.code)
        while idx <= codelength
            idx += execute_codeword(engine, word.code[idx])
        end
        return 1
    end
end

function execute_codeword(engine, num::Number) 
    push!(engine.stack, num)
    return 1
end

function define(engine, word, definition, immediate = false)
    engine.dictionary[word] = Word(definition, immediate)
    return engine
end

function interpreter(out = stdout)
    return define_stdlib(ForthEngine(out))
end

function define_stdlib(machine)
    define(machine, "+", gen_op_nn_n(+))
    define(machine, "-", gen_op_nn_n(-))
    define(machine, "*", gen_op_nn_n(*))
    define(machine, "/", gen_op_nn_n(/))
    define(machine, ".", op_print)
    define(machine, ":", op_colon)
    define(machine, ";", op_semicolon, true)
    define(machine, "immediate", op_immediate, true)
    define(machine, "dup", op_dup)
    define(machine, "swap", op_swap)
    define(machine, "drop", op_drop)
    define(machine, "2drop", op_2drop)
    define(machine, "over", op_over)
    define(machine, "rot", op_rot)
    define(machine, "-rot", op_nrot)
    define(machine, "?branch", op_qbranch)
end

function gen_op_nn_n(operation)
    return machine -> begin
        arg1 = pop!(machine.stack)
        arg2 = pop!(machine.stack)
        push!(machine.stack, operation(arg1, arg2))
        return 1
    end
end

function op_print(machine) 
    print(machine.out, pop!(machine.stack))
    return 1
end

function op_dup(machine)
    push!(machine.stack, machine.stack[end])
    return 1
end

function op_swap(machine)
    top = machine.stack[end]
    machine.stack[end] = machine.stack[end-1]
    machine.stack[end-1] = top
    return 1
end

function op_drop(machine)
    pop!(machine.stack)
    return 1
end

function op_2drop(machine)
    pop!(machine.stack)
    pop!(machine.stack)
    return 1
end

function op_over(machine)
    push!(machine.stack, machine.stack[end-1])
    return 1
end

function op_rot(machine)
    t1 = pop!(machine.stack)
    t2 = pop!(machine.stack)
    t3 = pop!(machine.stack)
    push!(machine.stack, t2)
    push!(machine.stack, t1)
    push!(machine.stack, t3)
    return 1
end

function op_nrot(machine)
    c = pop!(machine.stack)
    b = pop!(machine.stack)
    a = pop!(machine.stack)
    push!(machine.stack, c)
    push!(machine.stack, a)
    push!(machine.stack, b)
    return 1
end

function op_colon(machine)
    if machine.mode != MODE_INTERPRET
        return what(machine.out)
    end
    machine.mode = MODE_COMPILE
    machine.latest = nothing
    return 1
end

function op_semicolon(machine)
    if machine.mode != MODE_COMPILE
        return what(machine.out)
    end
    machine.mode = MODE_INTERPRET
    return 1
end

function op_immediate(machine)
    if machine.mode != MODE_INTERPRET || isnothing(machine.latest)
        return printerr(machine.out, "Invalid IMMEDIATE")
    end
    machine.latest.immediate = true
    return 1
end

function op_qbranch(machine)
    if pop!(machine.stack) == 0
        return 1
    end
    return 2 #?
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
