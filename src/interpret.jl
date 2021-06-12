
function _interpret(engine, wordstr)
    isnothing(wordstr) || wordstr == "" && return true
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
    code = word.code
    if code === op_swap # Fast, type.stabilized routes for a few words
        return code(engine, parent, myidx)
    elseif code === op_dup
        return code(engine, parent, myidx)
    elseif code === op_drop
        return code(engine, parent, myidx)
    elseif code isa Function
        return code(engine, parent, myidx)
    elseif code isa Number
        push!(engine.stack, code)
        return 1
    else
        idx = 1 # DOCOL
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

# read a space-separated word from io and return (word, end_of_line)
function word(io)
    buf = Char[]
    chr = ' '
    while isspace(chr) && !eof(io)
        chr = read(io, Char)
    end
    while true
        if isspace(chr)
            return (String(buf), chr == '\n' || eof(io))
        end
        push!(buf, chr)
        chr = eof(io) ? '\n' : read(io, Char)
    end
end

function interpret(machine, sentence::String)
    oldinput = machine.input
    machine.input = IOBuffer(sentence)
    while !eof(machine.input)
        (w, eol) = word(machine.input)
        _interpret(machine, w)
    end
    machine.input = oldinput    
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
