using Test

using NeuroGraphs
using LightGraphs
g = WAdjMap(3)  # or use `SimpleWeightedDiGraph` for directed graphs
add_edge!(g, 1, 2, 0.5)
add_edge!(g, 2, 3, 0.8)
add_edge!(g, 1, 3, 2.0)

LightGraphs.DijkstraState{Int64, Int64}([0, 0, 0], [0, 9223372036854775807, 9223372036854775807], [Int64[], Int
64[], Int64[]], [1.0, 0.0, 0.0], Int64[])


enumerate_paths(dijkstra_shortest_paths(g, 1), 3)

LightGraphs.DijkstraState{Float64, Int64}([0, 1, 2], [0.0, 0.5, 1.3], [Int64[], Int64[], Int64[]], [1.0, 1.0, 1
.0], Int64[])



g = SimpleWeightedGraph(3)  # or use `SimpleWeightedDiGraph` for directed graphs
add_edge!(g, 1, 2, 0.5)
add_edge!(g, 2, 3, 0.8)
add_edge!(g, 1, 3, 2.0)
julia> outneighbors(g, 3)
2-element view(::Vector{Int64}, 5:6) with eltype Int64:
 1
 2


@testset "NeuroGraphs.jl" begin
    g = AdjMap(3)


    g5 = AdjDiMap(4)
    add_edge!(g5, 1, 2);
    add_edge!(g5, 2, 3);
    add_edge!(g5, 1, 3);
    add_edge!(g5, 3, 4)
    # Write your tests here.
end
