
struct AdjacencyMap{T,M,D} <: AbstractGraph{T}
    vertices::DynamicCount
    colptr::Vector{T}      # Column i is in colptr[i]:(colptr[i+1]-1)
    rowval::Vector{T}      # Row indices of stored values
    metadata::M
end

colptr(g::AdjacencyMap) = getfield(g, :colptr)

rowvals(g::AdjacencyMap) = getfield(g, :rowval)

Metadata.metadata(g::AdjacencyMap) = getfield(g, :metadata)

Metadata.metadata_type(::Type{<:AdjacencyMap{T,M}}) where {T,M} = eltype(M)

LightGraphs.nv(g::AdjacencyMap) = length(getield(g, :vertices))

LightGraphs.vertices(g::AdjacencyMap) = OneTo(nv(g))

LightGraphs.is_directed(::AdjacencyMap{T,M,D}) where {T,M,D} = D

Base.length(g::AdjacencyMap) = ne(g)

Base.in(e, g::AdjacencyMap) = has_edge(g, e)

@inline LightGraphs.ne(g::AdjacencyMap) = Int(@inbounds(getcolptr(g)[nv(g) + 1])) - 1

LightGraphs.has_edge(g::AdjacencyMap, e::AbstractEdge) = has_edge(g, src(e), dst(e))
function LightGraphs.has_edge(g::AdjacencyMap{T,M,false}, i::Integer, j::Integer) where {T,M}
    if i < j
        if j <= nv(g)
            unsafe_has_edge(colptr(g), rowvals(g), i, j)
        else
            return false
        end
    elseif i <= nv(g)
        return false
    else
        unsafe_has_edge(colptr(g), rowvals(g), j, i)
    end
end
function LightGraphs.has_edge(g::AdjacencyMap{T,M,true}, i::Integer, j::Integer) where {T,M}
    N = nv(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    else
        unsafe_has_edge(colptr(g), rowvals(g), i, j)
    end
end
function unsafe_has_edge(cptr, rvals, i, j)
    coljlastk = @inbounds(cptr[j + 1] - 1)
    searchk = searchsortedfirst(rvals, i, @inbounds(cptr[j]), coljlastk, Base.Order.Forward)
    return searchk <= coljlastk && @inbounds(rvals[searchk]) == i
end

LightGraphs.add_edge!(g::AdjacencyMap, i::Int, j::Int) = add_edge!(g, i, j, no_metadata)
function LightGraphs.add_edge!(g::AdjacencyMap{T,M,false}, i::Int, j::Int, val) where {T,M}
    N = nv(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    elseif i < j
        unsafe_add_edge!(g, i, j, m)
    else
        unsafe_add_edge!(g, j, i, m)
    end
end
function LightGraphs.add_edge!(g::AdjacencyMap{T,M,true}, i::Int, j::Int, val) where {T,M}
    N = nv(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    else
        return unsafe_add_edge!(g, i, j, m)
    end
end
function unsafe_add_edge!(g, i, j, m)
    coljlastk = @inbounds(colptr(g)[j + 1] - 1)
    searchk = searchsortedfirst(rowvals(g), i, @inbounds(colptr(g)[j]), coljlastk, Base.Order.Forward)
    if searchk <= coljlastk && rowvals(g)[searchk] == i
        _setindex!(metadata(g), val, searchk)
        return true
    else
        nz = colptr(g)[N + 1]
        # if nnz(A) < length(rowval/nzval): no need to grow rowval and preserve values
        _insert!(rowvals(g), searchk, i, nz)
        _insert!(metadata(g), searchk, val, nz)
        @simd for i in (j + 1):(N + 1)
            @inbounds colptr(g)[i] += 1
        end
    end
    return true
end

# insert item at position pos, shifting only from pos+1 to nz
_insert!(m, pos, ::NoMetadata, nz) = error()
function _insert!(m, pos::Integer, val, nz::Integer)
    if nz > length(m)
        insert!(m, pos, val)
    else # nz < length(v)
        Base.unsafe_copyto!(m, pos + 1, m, pos, nz - pos)
        @inbounds(setindex!(m, val, pos))
        m 
    end
end
_setindex!(nzvals, val, i) = @inbounds(setindex!(nzvals, val, i))
_setindex!(::NoMetadata, ::NoMetadata, i) = nothing
_setindex!(::NoMetadata, val, i) = nothing
_setindex!(nzvals, ::NoMetadata, i) = nothing

LightGraphs.rem_edge!(g::AdjacencyMap{T,M,true}, i::Integer, j::Integer) where {T,M} = unsafe_rem_edge!(g, i, j)
function LightGraphs.rem_edge!(g::AdjacencyMap{T,M,false}, i::Integer, j::Integer) where {T,M}
    if i < j
        return unsafe_rem_edge!(g, i, j)
    else
        return unsafe_rem_edge!(g, j, i)
    end
end

function unsafe_rem_edge!(g::AdjacencyMap, i::Integer, j::Integer)
    N = nv(g)
    if !((1 <= i <= N) && (1 <= j <= N))
        return false
    else
        cptr = colptr(g)
        rval = rowvals(g)
        m = metadata(g)

        coljlastk = @inbounds(cptr[j + 1]) - 1
        searchk = searchsortedfirst(rval, i, @inbounds(cptr[j]), coljlastk, Base.Order.Forward)
        if searchk > coljlastk || @inbounds(rval[searchk]) != i
            return false
        else
            Awritepos = 1
            oldAcolptrAj = 1
            @inbounds for Aj in OneTo(N)
                for Ak in oldAcolptrAj:(cptr[Aj + 1]-1)
                    if Ak != searchk && Awritepos != Ak
                        # If this element should be kept, rewrite in new position
                        rval[Awritepos] = rval[Ak]
                        _mv_nzval!(m, Awritepos, Ak)
                    end
                    Awritepos += 1
                end
                oldAcolptrAj = Acolptr[Aj + 1]
                Acolptr[Aj + 1] = Awritepos
            end

            # Trim A's storage if necessary
            Annz = Acolptr[end] - 1
            resize!(rval, Annz)
            resize!(m, Annz)
            return true
        end
    end
end

_mv_nzval!(nzvals, writepos, k) = @inbounds(setindex!(nzvals, nzvals[k], writepos))
_mv_nzval!(::NoMetadata, writepos, k) = nothing

######
######
######
LightGraphs.add_vertices!(g::AdjacencyMap, n::Integer) = _unsafe_add_vertices!(g, max(0, n))
function _unsafe_add_vertices!(g::AdjacencyMap, n)
    v = getfield(g, :vertices)
    cptr = colptr(g)
    c = last(cptr)
    for _ in OneTo(n)
        push!(cptr, c)
    end
    setfield(v, :stop, length(g) + n)
    return true
end
function LightGraphs.add_vertex!(m::AdjacencyMap{T}) where {T}
    v = getfield(g, :vertices)
    cptr = colptr(g)
    push!(cptr, last(cptr))
    setfield(v, :stop, length(g) + 1)
    return true
end

@propagate_inbounds function LightGraphs.outneighbors(g::AdjacencyMap, v::Integer)
    view(rowval(g), colptr(g)[v]:colptr(g)[v + 1] - 1)
end
function LightGraphs.inneighbors(g::AdjacencyMap, v::Integer)
    N = nv(g)
    colptrA = colptr(g);
    rowvalA = rowvals(g);
    nzinds = Int[]

    # adapted from SparseMatrixCSC's sorted_bsearch_A
    ptrI = 1
    @inbounds for j in OneTo(N)
        rowI = v
        ptrA = Int(colptrA[j])
        stopA = Int(colptrA[j+1]-1)
        if ptrA <= stopA
            if rowvalA[ptrA] <= rowI
                ptrA = searchsortedfirst(rowvalA, rowI, ptrA, stopA, Base.Order.Forward)
                if ptrA <= stopA && rowvalA[ptrA] == rowI
                    push!(nzinds, j)
                end
            end
            ptrI += 1
        end
    end
    return nzinds
end

## iterate
@inline function Base.iterate(g::AdjacencyMap)
    N = nv(g)
    if N === 0
        return nothing
    else
        cptr = colptr(g)
        c = @inbounds(cptr[1])
        if c === @inbounds(cptr[N])
            return nothing
        else
            k = 0
            while c <= N
                k = @inbounds(cptr[c])
                if k === (@inbounds(cptr[c + 1]) - 1)
                    c += 1
                else
                    break
                end
            end
            return AdjEdge(@inbounds(rvals[k]), c, _getindex(metadata(g), k)), (k, c)
        end
    end
end

@inline function Base.iterate(g::AdjacencyMap, (k, c))
    N = nv(g)
    cptr = colptr(g)
    if k === (@inbounds(cptr[c + 1]) - 1)
        if c === N
            return nothing
        elseif k === ne(g)
            return nothing
        else
            cnew = c + 1
            knew = 0
            while cnew <= N
                knew = @inbounds(cptr[cnew])
                if (knew !== (@inbounds(cptr[cnew + 1]) - 1))
                    break
                else
                    cnew += 1
                end
            end
            return AdjEdge(@inbounds(rvals[knew]), cnew, _getindex(metadata(g), knew)), (knew, cnew)
        end
    else
        cnew = c
        knew = k
        while c <= N
            knew += 1
            if knew !== (@inbounds(cptr[cnew + 1]) - 1)
                break
            else
                cnew += 1
            end
        end
        return AdjEdge(@inbounds(rvals[knew]), cnew, _getindex(metadata(g), knew)), (knew, cnew)
    end
end

_getindex(::NoMetadata, i) = no_metadata
_getindex(m, i) = @inbounds(m[i])

function _isequal(e1::AdjacencyMap, e2)
    k = 0
    g = parent(e1)
    for e in e2
        has_edge(g, e) || return false
        k += 1
    end
    return k == ne(g)
end
Base.:(==)(e1::AdjacencyMap, e2::AbstractVector{AdjEdge}) = _isequal(e1, e2)
Base.:(==)(e1::AbstractVector{AdjEdge}, e2::AdjacencyMap) = _isequal(e2, e1)
Base.:(==)(e1::AdjacencyMap, e2::Set{AdjEdge}) = _isequal(e1, e2)
Base.:(==)(e1::Set{AdjEdge}, e2::AdjacencyMap) = _isequal(e2, e1)

#= TODO
TODO LightGraphs.rem_vertex!(m::AdjMap, n::Integer)
TODO LightGraphs.rem_vertices!(m::AdjMap, n::AbstractVector)
function add_vertices!(g::AbstractSimpleWeightedGraph, n::Integer)
    T = eltype(g)
    U = weighttype(g)
    (nv(g) + one(T) <= nv(g)) && return false       # test for overflow
    emptycols = spzeros(U, nv(g) + n, n)
    g.weights = hcat(g.weights, emptycols[1:nv(g), :])
    g.weights = vcat(g.weights, emptycols')
    return true
end
=#

