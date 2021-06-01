using Forth
using Test

import Forth.interpret

function pushnums(forth)
    interpret(forth, "2.1")
    @test forth.stack[end] == 2.1

    interpret(forth, "10")
    @test forth.stack[end] == 10
end

@testset "Interpreter basics" begin
    forth = interpreter()
    pushnums(forth)
    interpret(forth, "+")
    @test length(forth.stack) == 1
    @test forth.stack[end] == 12.1

    out = IOBuffer()
    forth = interpreter(out)
    interpret(forth, "5 6 +")
    @test forth.stack[end] == 11

    interpret(forth, ".")
    @test length(forth.stack) == 0
    @test String(take!(out)) == "11.0"
end

@testset "Defining with : and ;" begin
    forth = interpreter()
    interpret(forth, ": 5* 5 * ;")
    pushnums(forth)
    interpret(forth, "5*")
    @test length(forth.stack) == 2
    @test forth.stack[end] == 50
    interpret(forth, ": x 1 5* ; x")
    @test length(forth.stack) == 3
    @test forth.stack[end] == 5
end