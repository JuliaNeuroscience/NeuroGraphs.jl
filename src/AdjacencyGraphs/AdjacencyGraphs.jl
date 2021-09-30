module AdjacencyGraphs

using ArrayInterface
using Base: @propagate_inbounds, OneTo
using LinearAlgebra
using Metadata
import Metadata: NoMetadata, no_metadata, metadata_keys, metadata_type, metadata
using Static
using SparseArrays
using SparseArrays: rowvals, getcolptr, AbstractSparseMatrixCSC, fkeep!

using LightGraphs
import LightGraphs: is_directed, add_edge!, rem_edge!, has_edge, vertices, edges,
    induced_subgraph, add_vertex!, add_vertices!, rem_vertex!, rem_vertices!, inneighbors,
    outneighbors, neighbors, indegree, outdegree, degree, all_neighbors, common_neighbors,
    density, num_self_loops, degree_histogram, weights

export AdjMap, AdjDiMap, WAdjMap, WAdjDiMap

const SUnitRange{F,L} = ArrayInterface.OptionallyStaticUnitRange{StaticInt{F},StaticInt{L}}

SUnitRange{F,L}() where {F,L} = static(F):static(L)

include("metadata.jl")
include("adjacency_map.jl")
include("interface.jl")
include("adjedge.jl")
include("core.jl")
include("utils.jl")

LightGraphs.nv(g::AdjacencyMap) = nvertices(g)

@inline LightGraphs.ne(g::AdjacencyMap) = nedges(g)

end
