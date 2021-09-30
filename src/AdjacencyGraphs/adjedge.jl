
struct AdjEdge{T,M} <: AbstractEdge{T}
    src::T
    dst::T
    metadata::M

    AdjEdge{T}(s::T, d::T, m::M) where {T,M} = new{T,M}(s, d, m)
    AdjEdge(s::T, d::T, m::M) where {T,M} = AdjEdge{T}(s, d, m)
    AdjEdge(s::T, d::T) where {T} = AdjEdge(s, d, no_metadata)

    AdjEdge(t::Tuple, m) where {T} = AdjEdge(t[1], t[2], m)
    AdjEdge(t::Tuple) where {T} = AdjEdge(t[1], t[2])

    AdjEdge(p::Pair, m) = AdjEdge(p.first, p.second, m)
    AdjEdge(p::Pair) = AdjEdge(p.first, p.second)

    AdjEdge{T}(p::Pair, m) where {T} = AdjEdge(T(p.first), T(p.second), m)
    AdjEdge{T}(p::Pair) where {T} = AdjEdge(T(p.first), T(p.second))

    AdjEdge{T}(t::Tuple, m) where {T} = AdjEdge(T(t[1]), T(t[2]), m)
    AdjEdge{T}(t::Tuple) where {T} = AdjEdge(T(t[1]), T(t[2]))


    AdjEdge{T}(e::AbstractEdge) where {T} = AdjEdge{T}(T(src(e)), T(dst(e)))
end

LightGraphs.src(e::AdjEdge) = getfield(e, :src)

LightGraphs.dst(e::AdjEdge) = getfield(e, :dst)

Metadata.metadata(e::AdjEdge) = getfield(e, :metadata)

Base.eltype(::Type{<:AdjEdge{T,M}}) where {T,M} = T

Metadata.metadata_type(::Type{<:AdjEdge{T,M}}) where {T,M} = M

Base.Pair(e::AdjEdge) = Pair(src(e), dst(e))

Base.Tuple(e::AdjEdge) = (src(e), dst(e))

@inline Base.reverse(e::AdjEdge) = AdjEdge(dst(e), src(e), metadata(e))

@inline Base.:(==)(e1::AdjEdge, e2::AdjEdge) = (src(e1) == src(e2) && dst(e1) == dst(e2))

Base.hash(e::AdjEdge, h::UInt) = hash(src(e), hash(dst(e), h), hash(metadata(e), h))

function Base.show(io::IO, @nospecialize(e::AdjEdge)) 
    m = metadata(e)
    if m === no_metadata
        print(io, "AdjEdge($(src(e)) => $(dst(e)))")
    else
        print(io, "AdjEdge($(src(e)) => $(dst(e)), $(m))")
    end
end

# TODO Base.:(==)(e1::AdjMap, e2::AdjMap) = parent(e1) == parent(e2)


# TODO LightGraphs.edges(m::AdjacencyMap, n::Integer)

###
### AdjIterator
###
struct AdjIterator{D,T,M}
    parent::AdjacencyMap{D,T,M}
end

Base.parent(x::AdjIterator) = getfield(x, :parent)

Base.length(x::AdjIterator) = nedges(parent(x))

Base.in(e, g::AdjIterator) = has_edge(parent(g), e)

@inline function Base.iterate(itr::AdjIterator)
    g = parent(itr)
    N = nvertices(g)
    if N === 0
        return nothing
    else
        cptr = getcolptr(g)
        if @inbounds(cptr[1]) === cptr[end]
            return nothing
        else
            k = 0
            c = 0
            while c !== N
                c += 1
                k = @inbounds(cptr[c])
                (k !== @inbounds(cptr[c + 1])) && break
            end
            return AdjEdge(@inbounds(rowvals(g)[k]), c, _getindex(metadata(g), k)), (k, c)
        end
    end
end

@inline function Base.iterate(itr::AdjIterator, (k, c))
    g = parent(itr)
    N = nvertices(g)
    cptr = getcolptr(g)
    if k === (@inbounds(cptr[c + 1]) - 1)
        if c === N
            return nothing
        elseif k === nedges(g)
            return nothing
        else
            cnew = c
            knew = 0
            while cnew !== N
                cnew += 1
                knew = @inbounds(cptr[cnew])
                (knew !== @inbounds(cptr[cnew + 1])) && break
            end
            return AdjEdge(@inbounds(rowvals(g)[knew]), cnew, _getindex(metadata(g), knew)), (knew, cnew)
        end
    else
        cnew = c
        knew = k
        while cnew <= N
            knew += 1
            (knew !== @inbounds(cptr[cnew + 1])) && break
            cnew += 1
        end
        return AdjEdge(@inbounds(rowvals(g)[knew]), cnew, _getindex(metadata(g), knew)), (knew, cnew)
    end
end

_getindex(::NoMetadata, i) = no_metadata
_getindex(m, i) = @inbounds(m[i])

edges(g::AdjacencyMap) = AdjIterator(g)

function _isequal(e1::AdjacencyMap, e2)
    k = 0
    g = parent(e1)
    for e in e2
        has_edge(g, e) || return false
        k += 1
    end
    return k == ne(g)
end
Base.:(==)(e1::AdjIterator, e2::AbstractVector{AdjEdge}) = _isequal(parent(e1), e2)
Base.:(==)(e1::AbstractVector{AdjEdge}, e2::AdjIterator) = _isequal(e2, parent(e1))
Base.:(==)(e1::AdjIterator, e2::Set{AdjEdge}) = _isequal(parent(e1), e2)
Base.:(==)(e1::Set{AdjEdge}, e2::AdjIterator) = _isequal(e2, parent(e1))

