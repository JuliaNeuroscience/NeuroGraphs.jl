module NeuroGraphs

using ArrayInterface

export AdjMap, AdjDiMap, WAdjMap, WAdjDiMap

include("AdjacencyGraphs/AdjacencyGraphs.jl")
using .AdjacencyGraphs

end
