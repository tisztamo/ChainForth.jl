using ChainForth
using Test

function pushnums(forth)
    interpret(forth, "21")
    @test forth.stack[end] == 21

    interpret(forth, "10")
    @test forth.stack[end] == 10
end

@testset "Interpreter basics" begin
    forth = interpreter()
    pushnums(forth)
    interpret(forth, "+ \n")
    @test length(forth.stack) == 1
    @test forth.stack[end] == 31

    out = IOBuffer()
    forth = interpreter(stdin, out)
    interpret(forth, "5 6 +")
    @test forth.stack[end] == 11

    interpret(forth, ".")
    @test length(forth.stack) == 0
    @test String(take!(out)) == "11"
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

    interpret(forth, ": double dup + ;")
    interpret(forth, ": quadruple double double ;")
    interpret(forth, "3 5* quadruple")
    @test forth.stack[end] == 60
end

@testset "Immediate words" begin
    forth = interpreter()
    interpret(forth, ": push5 5 ; immediate")    
    interpret(forth, ": x 1 push5 3 ;")
    @test length(forth.stack) == 1
    @test forth.stack[1] == 5
    interpret(forth, "x")
    @test length(forth.stack) == 3
    @test forth.stack[2] == 1
    @test forth.stack[3] == 3
end

@testset "Stack manipulation" begin
    forth = interpreter()
    interpret(forth, "1 2 3 dup")
    @test length(forth.stack) == 4
    @test forth.stack[end] == 3
    interpret(forth, "4 drop")
    @test length(forth.stack) == 4
    @test forth.stack[end] == 3
    interpret(forth, "drop drop")
    @test length(forth.stack) == 2
    @test forth.stack[end] == 2
    interpret(forth, "9 rot")
    @test length(forth.stack) == 3
    @test forth.stack[end] == 1
    @test forth.stack[end-1] == 9
    @test forth.stack[end-2] == 2
end

@testset "Memory Allocation" begin
    forth = interpreter()
    interpret(forth, "5 allot here")
    @test forth.stack == [1]
    interpret(forth, "3 allot here")
    @test forth.stack == [1, 6]
    interpret(forth, "100 allot here")
    @test forth.stack == [1, 6, 9]
    @test length(forth.memory) == 108

    interpret(forth, "12 5 ! 13 8 !")
    @test forth.memory[5] == 12
    @test forth.memory[8] == 13
    @test forth.stack == [1, 6, 9]
    interpret(forth, "5 @ 8 @ 5 @")
    @test forth.stack == [1, 6, 9, 12, 13, 12]
end

@testset "Variables" begin
    forth = interpreter()
    interpret(forth, "variable x")    
    interpret(forth, "variable y")
    interpret(forth, "variable zuzu1234567890")
    @test forth.stack == []
    interpret(forth, "9 zuzu1234567890 !")
    @test forth.stack == []
    interpret(forth, "zuzu1234567890 @")
    @test forth.stack == [9]
    interpret(forth, "drop 8 x ! 7 y !")
    interpret(forth, "x @ y @ zuzu1234567890 @")
    @test forth.stack == [8, 7, 9]
end

@testset "Execute" begin
    forth = interpreter()
    interpret(forth, ": GT1 123 ;")
    interpret(forth, ": GT2 ' ' , ;")
    interpret(forth, "GT2 GT1 execute")
    @test forth.stack == [123]
end