using Documenter, Forth

makedocs(
    modules = [Forth],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Schäffer Krisztián",
    sitename = "ChainForth.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/tisztamo/ChainForth.jl.git",
    push_preview = true
)
