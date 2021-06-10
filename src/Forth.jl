# Conquer with words

module Forth

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

function _compile(engine, wordstr)
    if isnothing(engine.latest)
        engine.latest = engine.dictionary[wordstr] = ExecutionToken(wordstr)
        return true
    else
        word = codeof(engine, wordstr)
        if isnothing(word)
            print(engine.out, "$(wordstr)?\n")
            return false
        elseif word isa ExecutionToken && word.immediate
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
    if engine.mode == MODE_COMPILE && (!(word isa ExecutionToken) || !word.immediate)
        return _compile(engine, wordstr)
    else
        if isnothing(word)
            print(engine.out, "$(wordstr)?\n")
            return false
        end
        execute_codeword(engine, word) # No branching during interpretation
        return true
    end
end

# Execute the word either by dispatching to its Julia function if its a native word,
# or by recursively executing its compiled definition. (The "inner interpreter")
function execute_codeword(engine, word::ExecutionToken, parent = nothing, myidx = 0)
    if word.code isa Function
        return word.code(engine, parent, myidx)
    elseif word.code isa Number
        push!(engine.stack, word.code)
        return 1
    else
        idx = 1 # DOCOL
        code = word.code
        codelength = length(code)
        while idx > 0 && idx <= codelength
            idx += execute_codeword(engine, code[idx], word, idx)
        end
        return 1
    end
end

function execute_codeword(engine, num::Number, parent = nothing, myidx = 0)
    push!(engine.stack, num)
    return 1
end

function define(engine, wordstr, definition, immediate = false)
    engine.dictionary[wordstr] = ExecutionToken(wordstr, definition, immediate)
    return engine
end

function interpreter(input = stdin, output = stdout)
    return define_stdlib(ForthEngine(input, output))
end

include("stackops.jl")

function define_stdlib(machine)
    # stack
    define(machine, "dup",      op_dup)
    define(machine, "swap",     op_swap)
    define(machine, "drop",     op_drop)
    define(machine, "2drop",    op_2drop)
    define(machine, "over",     op_over)
    define(machine, "rot",      op_rot)
    define(machine, "-rot",     op_nrot)

    # arithmetic
    define(machine, "+",        gen_op_nn_n(+))
    define(machine, "-",        gen_op_nn_n(-))
    define(machine, "*",        gen_op_nn_n(*))
    define(machine, "/",        gen_op_nn_n(/))

    # various
    define(machine, ".",        op_print)
    define(machine, "branch",   op_branch)
    define(machine, "?branch",  op_qbranch)

    # compile
    define(machine, ":",        op_colon)
    define(machine, ";",        op_semicolon,   true)
    define(machine, ",",        op_comma,       true)
    define(machine, "'",        op_apostrophe,  true)
    define(machine, "[",        op_leftbracket, true)
    define(machine, "]",        op_rightbracket)
    define(machine, "immediate", op_immediate,  true)
    define(machine, "see",      op_see)
    define(machine, "postpone", op_postpone,    true)
    define(machine, "postponed", op_postponed,  true)
    define(machine, "mark",     op_mark,        true) # non-std ( -- i ) Push the current index in the compiled definition
    define(machine, "slot",     op_slot,        true) # non-std ( -- ) Add a slot to the compiled definition to fill later
    define(machine, "store",    op_store,       true) # non-std ( i v -- ) Store a value in the current definition at i

    oldin = machine.input
    machine.input = IOBuffer(
"""
: if immediate
    postpone ?branch
    ' slot ,
    ' mark ,
;

: then immediate
    ' dup ,
    ' mark ,
    ' - ,
    ' 2 ,
    ' + ,
    ' store ,
;

: else immediate
    postpone branch
    ' slot ,
    ' then ,
    ' mark ,
;
"""
)
    while !eof(machine.input)
        (w, eol) = word(machine.input)
        _interpret(machine, w)
    end
    machine.input = oldin
    return machine
end

function gen_op_nn_n(operation)
    return (machine, parent, myidx) -> begin
        arg1 = pop!(machine.stack)
        arg2 = pop!(machine.stack)
        push!(machine.stack, operation(arg1, arg2))
        return 1
    end
end

function op_print(machine, parent, myidx) 
    print(machine.out, pop!(machine.stack))
    return 1
end

function op_colon(machine, parent, myidx)
    if machine.mode != MODE_INTERPRET
        return print(machine.out, "Colon is only allowed while interpreting.")
    end
    machine.mode = MODE_COMPILE
    machine.latest = nothing
    return 1
end

function op_semicolon(machine, parent, myidx)
    if machine.mode != MODE_COMPILE
        return print(machine.out, "Semicolon is only allowed while compiling.")
    end
    machine.mode = MODE_INTERPRET
    return 1
end

function op_comma(machine, parent, myidx)
    push!(machine.latest.code, pop!(machine.stack))
    return 1
end

function op_apostrophe(machine, parent, myidx)
    push!(machine.stack, codeof(machine, word(machine.input)[1]))
    return 1
end

function op_leftbracket(machine, parent, myidx)
    machine.mode = MODE_INTERPRET
end

function op_rightbracket(machine, parent, myidx)
    machine.mode = MODE_COMPILE
end

function op_immediate(machine, parent, myidx)
    if isnothing(machine.latest)
        return print(machine.out, "Invalid IMMEDIATE.")
    end
    machine.latest.immediate = true
    return 1
end

function op_branch(machine, parent, myidx)
    return parent.code[myidx + 1]
end

function op_qbranch(machine, parent, myidx)
    if pop!(machine.stack) == 0
        return parent.code[myidx + 1]
    end
    return 2
end

function op_see(machine, parent, myidx)
    what = codeof(machine, word(machine.input)[1])
    println(machine.out, join(what.code, ' ') * (what.immediate ? " ; immediate" : ""))
end

function op_postpone(machine, parent, myidx)
    push!(machine.latest.code, codeof(machine, "postponed"))
    push!(machine.latest.code, codeof(machine, word(machine.input)[1]))
    return 1
end

function op_postponed(machine, parent, myidx)
    push!(machine.latest.code, parent.code[myidx + 1])
    return 2
end

function op_mark(machine, parent, myidx)
    push!(machine.stack, length(machine.latest.code))
    return 1
end

function op_slot(machine, parent, myidx)
    push!(machine.latest.code, 0)
    return 1    
end

function op_store(machine, parent, myidx)
    val = pop!(machine.stack)
    pos = pop!(machine.stack)::Number
    machine.latest.code[pos] = val
    return 1
end

# read a space-separated word from io and return (word, end_of_line)
function word(io)
    buf = Char[]
    chr = ' '
    while isspace(chr)
        chr = read(io, Char)
    end
    while true
        if isspace(chr)
            return (String(buf), chr == '\n')
        end
        push!(buf, chr)
        chr = read(io, Char)
    end
end

function interpret(machine, sentence::String)
    for wordstr in split(sentence, ' ')
        _interpret(machine, wordstr)
    end
end

function repl(engine = interpreter(); silent = false)
    if !silent
        print(engine.out, "ChainForth.jl v\"$VERSION\":\n")
    end
    while !eof(engine.input)
        try
            (w, eol) = word(engine.input)
            if w == "exit"
                return
            end
            ok = _interpret(engine, w)
            if eol && ok
                println(engine.out, " ok")
            end
        catch e
            if e isa ArgumentError && e.msg == "array must be non-empty"
                println(engine.out, " Stack underflow")
            elseif e isa InterruptException
                return
            else
                println(engine.out)
                if !silent
                    for (exc, bt) in Base.catch_stack()
                        showerror(engine.out, exc, bt)
                        println(engine.out)
                    end
                end
            end
        end
    end
end

end # module
