
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

# read a space-separated word from io and return (word, end_of_line)
function word(io)
    buf = Char[]
    chr = ' '
    while isspace(chr)
        chr = read(io, Char)
    end
    while true
        if isspace(chr)
            return (String(buf), chr == '\n' || chr == '\r')
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
            if (eol || eof(engine.input)) && ok
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
