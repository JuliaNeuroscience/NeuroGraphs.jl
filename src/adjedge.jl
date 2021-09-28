
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

#LightGraphs.edges(g::AdjMap) = AdjEdgeIter(g)

# TODO LightGraphs.edges(m::AdjacencyMap, n::Integer)

