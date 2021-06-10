function define_controlstructures(machine)
    define(machine, ".",        op_print)
    define(machine, "branch",   op_branch)
    define(machine, "?branch",  op_qbranch)
end

function op_print(machine, parent, myidx) 
    print(machine.out, pop!(machine.stack))
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


const op_ifthenelse = """
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