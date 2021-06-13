function define_stackops(machine)
    define(machine, "dup",      op_dup)
    define(machine, "swap",     op_swap)
    define(machine, "drop",     op_drop)
    define(machine, "2drop",    op_2drop)
    define(machine, "over",     op_over)
    define(machine, "rot",      op_rot)
    define(machine, "-rot",     op_nrot)
    define(machine, "depth",    op_depth)
end

function op_dup(machine, parent, myidx)
    push!(machine.stack, machine.stack[end])
    return 1
end

function op_swap(machine, parent, myidx)
    top = machine.stack[end]
    machine.stack[end] = machine.stack[end-1]
    machine.stack[end-1] = top
    return 1
end

function op_drop(machine, parent, myidx)
    pop!(machine.stack)
    return 1
end

function op_2drop(machine, parent, myidx)
    pop!(machine.stack)
    pop!(machine.stack)
    return 1
end

function op_over(machine, parent, myidx)
    push!(machine.stack, machine.stack[end-1])
    return 1
end

function op_rot(machine, parent, myidx)
    t1 = pop!(machine.stack)
    t2 = pop!(machine.stack)
    t3 = pop!(machine.stack)
    push!(machine.stack, t2)
    push!(machine.stack, t1)
    push!(machine.stack, t3)
    return 1
end

function op_nrot(machine, parent, myidx)
    c = pop!(machine.stack)
    b = pop!(machine.stack)
    a = pop!(machine.stack)
    push!(machine.stack, c)
    push!(machine.stack, a)
    push!(machine.stack, b)
    return 1
end

function op_depth(machine, parent, myidx)
    push!(machine.stack, length(machine.stack))
    return 1
end
