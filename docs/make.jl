using NeuroGraphs
using Documenter

DocMeta.setdocmeta!(NeuroGraphs, :DocTestSetup, :(using NeuroGraphs); recursive=true)

makedocs(;
    modules=[NeuroGraphs],
    authors="Zachary P. Christensen <zchristensen7@gmail.com> and contributors",
    repo="https://github.com/JuliaNeuroscience/NeuroGraphs.jl/blob/{commit}{path}#{line}",
    sitename="NeuroGraphs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaNeuroscience.github.io/NeuroGraphs.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaNeuroscience/NeuroGraphs.jl",
)
