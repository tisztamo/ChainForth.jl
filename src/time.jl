function define_time(machine)
    define(machine, "now", op_now)
end

function op_now(machine, _...)
    push!(machine.stack, time() |> round |> Int64)
    return 1
end

op_time =
"""
: ago ;
: mins  60 * ;
: hours 3600 * ;
: days  86400 * ;
: weeks 604800 * ;
"""