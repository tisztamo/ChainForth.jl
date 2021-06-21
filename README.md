# ChainForth.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) 
[![Build Status](https://travis-ci.com/tisztamo/ChainForth.jl.svg?branch=master)](https://travis-ci.com/tisztamo/ChainForth.jl)
[![codecov.io](http://codecov.io/github/tisztamo/ChainForth.jl/coverage.svg?branch=master)](http://codecov.io/github/tisztamo/ChainForth.jl?branch=master)-->
<!--
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://tisztamo.github.io/ChainForth.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://tisztamo.github.io/ChainForth.jl/dev)
-->

ChainForth.jl is an embedded virtual machine that helps you provide a highly secure but programmable, Turing-complete API layer at the edge of your Julia projects.

It is a simple Forth-like environment interpreted (in the future hopefully also JIT-ed) in Julia,
which you can easily extend in native Julia to provide an API to the scripts,
and which you can easily extend by specifying your DSL in ChainForth itself.

The following  example shows the use of an ad-hoc query language created with ChainForth.
The example defines the new word (function) `Last7Days`, that queries some historical data
specifying aggregation and selection:

```julia
def Last7Days
    HISTORY 5 mins
        STARTAT now 7 days -
        ENDAT now
        FIELDS TimeStamp High
;
```

The syntax used in this DSL was defined in the language itself.

There is a super-minimal repl:

```
julia> using ChainForth

julia> ChainForth.repl()
ChainForth.jl v"0 dev":
: double 2 * ;
 ok
: quadruple double double ;
 ok
3 quadruple .
12 ok
```

[ProgrammableAPI.jl](https://github.com/tisztamo/ProgrammableAPI.jl) is a way to integrate this into your project.

Please read the source and the tests for more info. 
