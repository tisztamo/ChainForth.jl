function define_memory(machine)
    define(machine, "allot",    op_allot)
    define(machine, "here",     op_here)
    define(machine, "@",        op_at)
    define(machine, "!",        op_exclamation)
end

function op_allot(machine, parent, myidx)
    cellcount = pop!(machine.stack)
    if cellcount == 0
        return 1
    end
    here = length(machine.memory)
    if cellcount < 0
        print(machine.out, "Err: Not implemented: deallocation")
        return 1
    end
    resize!(machine.memory, here + cellcount)
    machine.here = here + 1
    return 1
end

function op_here(machine, parent, myidx)
    push!(machine.stack, machine.here)
    return 1
end

function op_at(machine, parent, myidx)
    push!(machine.stack, machine.memory[@show machine.here])
    return 1
end

function op_exclamation(machine, parent, myidx)
    machine.memory[machine.here] = pop!(machine.stack)
    return 1
end

const op_memory =
"""
: variable immediate
    1 allot
;
"""