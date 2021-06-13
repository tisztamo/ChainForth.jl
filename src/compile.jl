function define_compiler(machine)
    define(machine, "create",   op_create)
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
    define(machine, "mark",     op_mark,        true) # non-std ( -- i ) Push the current index in the just compiled definition
    define(machine, "slot",     op_slot,        true) # non-std ( -- ) Add a slot to the just compiled definition to fill later
    define(machine, "store",    op_store,       true) # non-std ( i v -- ) Store a value in the just compiled definition at i
end

function _compile(engine, wordstr)
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

function op_create(machine, parent, myidx)
    wordstr = word(machine.input)[1]
    machine.latest = machine.dictionary[wordstr] = ExecutionToken(wordstr)
    return 1
end

function op_colon(machine, parent, myidx)
    if machine.mode != MODE_INTERPRET
        return print(machine.out, "Colon is only allowed while interpreting.")
    end
    machine.mode = MODE_COMPILE
    return op_create(machine, parent, myidx)
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

function op_see(machine, parent, myidx)
    what = codeof(machine, word(machine.input)[1])
    println(machine.out, ": $(what.name) " * join(what.code, ' ') * (what.immediate ? " ; immediate" : " ;"))
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
