# core methods

###
### neighbors
###
@propagate_inbounds function outneighbors(g::AdjacencyMap, v::Integer)
    cptr = getcolptr(g)
    rvals = rowvals(g)
    out = unsafe_inneighbors(nvertices(g), cptr, rvals, v)
    @inbounds for i in cptr[v]:cptr[v + 1] - 1
        pushfirst!(out, i)
    end
    return out
end

inneighbors(g::AdjMap, v::Integer) = outneighbors(g, v)
function inneighbors(g::AdjDiMap, v::Integer)
    unsafe_inneighbors(nvertices(g), getcolptr(g), rowvals(g), v)
end
function unsafe_inneighbors(N, cptr, rval, v)
    nzinds = Int[]
    ptrI = 1
    @inbounds for j in OneTo(N)
        rowI = v
        ptrA = Int(cptr[j])
        stopA = Int(cptr[j+1]-1)
        if ptrA <= stopA
            if rval[ptrA] <= rowI
                ptrA = searchsortedfirst(rval, rowI, ptrA, stopA, Base.Order.Forward)
                if ptrA <= stopA && rval[ptrA] == rowI
                    push!(nzinds, j)
                end
            end
            ptrI += 1
        end
    end
    return nzinds
end

neighbors(g::AdjMap, v::Integer) = outneighbors(g, v)

## all_neighbors
all_neighbors(g::AdjMap, v::Integer) = outneighbors(g, v)
all_neighbors(g::AdjDiMap, v::Integer) = union(outneighbors(g, v), inneighbors(g, v))

## common_neighbors
function common_neighbors(g::AdjacencyMap, u::Integer, v::Integer)
    intersect(neighbors(g, u), neighbors(g, v))
end

###
### density
###
function density(g::AdjDiMap)
    N = nvertices(g)
    return nedges(g) / (N * (N - 1))
end
function density(g::AdjMap)
    N = nvertices(g)
    return (2 * nedges(g)) / (N * (N - 1))
end

## num_self_loops
function num_self_loops(g::AdjacencyMap)
    if nvertices(g) == 0
        return 0
    else
        return sum(v -> has_edge(g, v, v), vertices(g))
    end
end

## degree_histogram
function degree_histogram(g::AdjacencyMap, degfn=degree)
    hist = Dict{eltype(g),Int}()
    for v in vertices(g)        # minimize allocations by
        for d in degfn(g, v)    # iterating over vertices
            hist[d] = get(hist, d, 0) + 1
        end
    end
    return hist
end

###
### induced_subgraph
###
#=
function induced_subgraph(g::AdjacencyMap, elist::AbstractVector{U}) where {U <: AbstractEdge}
    h = zero(g)
    T = eltype(T)
    newvid = Dict{T,T}()
    vmap = Vector{T}()

    for e in elist
        u, v = Tuple(e)
        for i in (u, v)
            if !haskey(newvid, i)
                add_vertex!(h)
                newvid[i] = nvertices(h)
                push!(vmap, i)
            end
        end
        add_edge!(h, newvid[u], newvid[v])
    end
    return h, vmap
end
=#

