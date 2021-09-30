
struct Cycle{T<:Integer}
    n::T
end
nvertices(g::Cycle) = getfield(g, :n)

function AdjMap(g::Cycle{T}) where {T <: Integer}
    n = Int(nvertices(g))
    if n <= 1
        return AdjMap{T}(n)
    elseif n == 2
        g = AdjMap{T}(n)
        add_edge!(g, 1, 2)
        return g
    else
        NP = n + 1
        NM = n - 1
        cptr = Vector{T}(undef, NP)
        @inbounds(setindex!(cptr, 1, 1))
        @inbounds(setindex!(cptr, NP, NP))
        @inbounds for i in OneTo(NM)
            cptr[i + 1] = i
        end
        rval = Vector{T}(undef, n)
        @inbounds(setindex!(rval, 1, NM))
        @inbounds(setindex!(rval, NM, n))
        @inbounds for i in OneTo(n - 2)
            rval[i] = i
        end
        return AdjMap(n, cptr, rval, no_metadata)
    end
end

gs = SimpleGraph(5)
g = AdjMap(5)
add_edge!(g, 1, 2)
add_edge!(g, 1, 5)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 5)

julia> add_edge!(g, 1, 2, 1)
true

julia> add_edge!(g, 1, 5, 1)
true

julia> add_edge!(g, 2, 3, 1)
true

julia> add_edge!(g, 3, 4, 1)
true

julia> add_edge!(g, 4, 5, 1)
true

julia> g
{5, 5} undirected simple Int64 graph with Float64 weights

julia>

julia> g.weights
5×5 SparseArrays.SparseMatrixCSC{Float64, Int64} with 10 stored entries:
  ⋅   1.0   ⋅    ⋅   1.0
 1.0   ⋅   1.0   ⋅    ⋅
  ⋅   1.0   ⋅   1.0   ⋅
  ⋅    ⋅   1.0   ⋅   1.0
 1.0   ⋅    ⋅   1.0   ⋅

julia> g.^C

julia> w = weights(g)
5×5 SparseArrays.SparseMatrixCSC{Float64, Int64} with 10 stored entries:
  ⋅   1.0   ⋅    ⋅   1.0
 1.0   ⋅   1.0   ⋅    ⋅
  ⋅   1.0   ⋅   1.0   ⋅
  ⋅    ⋅   1.0   ⋅   1.0
 1.0   ⋅    ⋅   1.0   ⋅

julia> w.colptr
6-element Vector{Int64}:
  1
  3
  5
  7
  9
 11

julia> w.rowval
10-element Vector{Int64}:
 2
 5
 1
 3
 2
 4
 3
 5
 1
 4

julia> outneighbors(g, 2)
2-element view(::Vector{Int64}, 3:4) with eltype Int64:
 1
 3

julia> inneighbors(g, 2)
2-element view(::Vector{Int64}, 3:4) with eltype Int64:
 1
 3


