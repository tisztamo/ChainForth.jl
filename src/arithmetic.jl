function define_arithmetic(machine)
    define(machine, "+",        gen_op_nn_n(+))
    define(machine, "-",        gen_op_nn_n(-))
    define(machine, "*",        gen_op_nn_n(*))
    define(machine, "/",        gen_op_nn_n(/))
    define(machine, "<",        gen_op_nn_n(less))
    define(machine, ">",        gen_op_nn_n(more))
    define(machine, "=",        gen_op_nn_n(equal))
end

less(a, b) = a < b ? -1 : 0
more(a, b) = less(b, a)
equal(a, b) = a == b ? -1 : 0

function gen_op_nn_n(operation)
    return (machine, parent, myidx) -> begin
        arg2 = pop!(machine.stack)
        arg1 = pop!(machine.stack)
        push!(machine.stack, operation(arg1, arg2))
        return 1
    end
end
