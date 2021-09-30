
struct AdjacencyMap{D,T,M} <: AbstractGraph{T}
    colptr::Vector{T}  # column i is in colptr[i]:(colptr[i+1]-1)
    rowval::Vector{T}  # row indices of stored values
    metadata::M

    AdjacencyMap{D,T,M}() where {D,T,M} = new{D::Bool,T,M}(T[1], T[], M())
    function AdjacencyMap{D,T,M}(n::Integer, m::M) where {D,T,M}
        (n < 0) && throw(ArgumentError("cannot have negative number of vertices"))
        _check_meta_length(0, m)
        return new{D::Bool,T,M}(fill(one(T), n + 1), T[], m)
    end
    function AdjacencyMap{D,T,M}(n::Integer) where {D,T,M}
        (n < 0) && throw(ArgumentError("cannot have negative number of vertices"))
        return new{D::Bool,T,M}(fill(one(T), n + 1), T[], M())
    end
    #= TODO appropriate way to bypass some checks
    function AdjacencyMap{D}(c::Vector{T}, r::Vector{T}, m::M) where {D,T,M}
        AdjacencyMap{D}(length(c) - 1, c, r, m)
    end
    =#
    function AdjacencyMap{D}(n::Integer, c::Vector{T}, r::Vector{T}, m::M) where {D,T,M}
        _check_type(n, T)
        _goodbuffers(n, c, r, m)
        return new{D::Bool,T,M}(c, r, m)
    end
    function AdjacencyMap{false,T,NoMetadata}(x::AbstractMatrix) where {N,T}
        n, m = size(x)
        n === m || throw(ArgumentError("Adjacency / distance matrices must be square"))
        g = new{false,T,NoMetadata}(fill(one(T), n+1), T[], no_metadata)
        @inbounds for j in OneTo(n)
            for k in OneTo(n)
                if ((j < k) && !iszero(x[j,k]))
                    throw(ArgumentError("Undirected AdjacencyMap can only be constructed from matrices where the lower triangular values are all zero"))
                end
                if !iszero(x[j,k])
                    add_edge!(x, j, k)
                end
            end
        end
        return g
    end
    function AdjacencyMap{true,T,NoMetadata}(x::AbstractMatrix) where {T}
        n, m = size(x)
        n === m || throw(ArgumentError("Adjacency / distance matrices must be square"))
        g = new{true,T,NoMetadata}(fill(one(T), n+1), T[], no_metadata)
        @inbounds for j in OneTo(n)
            for k in OneTo(n)
                if !iszero(x[j,k])
                    add_edge!(x, j, k)
                end
            end
        end
        return g
    end
    function AdjacencyMap{true,Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(x::AbstractSparseMatrixCSC) where {Ti,Tv}
        n, m = size(x)
        n === m || throw(ArgumentError("Adjacency / distance matrices must be square"))
        new{true,Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(
            copy(getcolptr(x)),
            copy(rowvals(x)),
            ListOfMeta(copy(nonzeros(x)), static(1):static(1))
        )
    end
    function AdjacencyMap{false,Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(x::AbstractSparseMatrixCSC) where {Ti,Tv}
        n, m = size(x)
        n === m || throw(ArgumentError("Adjacency / distance matrices must be square"))
        # TODO should this be don by hand to allow for self loops
        if istriu(x)
            throw(ArgumentError("Undirected AdjacencyMap can only be constructed from matrices where the lower triangular values are all zero"))
        end
        new{true,Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(
            copy(getcolptr(x)),
            copy(rowvals(x)),
            ListOfMeta(copy(nonzeros(x)), static(1):static(1))
        )
    end
end

const AdjMap{T,M} = AdjacencyMap{false,T,M}

const AdjDiMap{T,M} = AdjacencyMap{true,T,M}

const WAdjMap{Ti,Tv} = AdjMap{Ti,ListOfMeta{Tv,SUnitRange{1,1}}}

const WAdjDiMap{Ti,Tv} = AdjDiMap{Ti,ListOfMeta{Tv,SUnitRange{1,1}}}

WAdjMap{Ti}() where {Ti} = WAdjMap{Ti,Float64}()
WAdjDiMap{Ti}() where {Ti} = WAdjDiMap{Ti,Float64}()

WAdjMap() = WAdjMap{Int}()
WAdjDiMap() = WAdjDiMap{Int}()

WAdjMap{Ti}(n::Integer) where {Ti} = WAdjMap{Ti,Float64}(n)
WAdjDiMap{Ti}(n::Integer) where {Ti} = WAdjDiMap{Ti,Float64}(n)

WAdjMap(n::Integer) = WAdjMap{Int}(n)
WAdjDiMap(n::Integer) = WAdjDiMap{Int}(n)


weights(g::WAdjDiMap{Ti,Tv}) where {Ti,Tv} = MetaAdjView{Tv}(g, 1)
weights(g::WAdjMap{Ti,Tv}) where {Ti,Tv} = Symmetric(MetaAdjView{Tv}(g, 1), :U)

## empty
AdjDiMap{T}() where {T} = AdjDiMap{T,NoMetadata}()

AdjMap{T}() where {T} = AdjMap{T,NoMetadata}()

## from nvertices
AdjDiMap{T}(n::Integer) where {T} = AdjDiMap{T,NoMetadata}(n)
AdjDiMap(n::Integer) = AdjDiMap{typeof(n)}(n)

AdjMap{T}(n::Integer) where {T} = AdjMap{T,NoMetadata}(n)
AdjMap(n::Integer) = AdjMap{typeof(n)}(n)

# from matrix
AdjDiMap{T}(x::AbstractMatrix) where {T} = AdjDiMap{T,NoMetadata}(x)
AdjDiMap(x::AbstractMatrix) = AdjDiMap{Int}(x)
function AdjDiMap{Ti}(x::AbstractSparseMatrixCSC{Tv}) where {Tv,Ti}
    AdjDiMap{Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(x)
end
function AdjDiMap(x::AbstractSparseMatrixCSC{Tv,Ti}) where {Tv,Ti}
    AdjDiMap{Ti}(x::AbstractSparseMatrixCSC)
end

AdjMap{T}(x::AbstractMatrix) where {T} = AdjMap{T,NoMetadata}(x)
AdjMap(x::AbstractMatrix) = AdjMap{Int}(x)
function AdjMap{Ti}(x::AbstractSparseMatrixCSC{Tv}) where {Tv,Ti}
    AdjMap{Ti,ListOfMeta{Tv,SUnitRange{1,1}}}(x)
end
function AdjMap(x::AbstractSparseMatrixCSC{Tv,Ti}) where {Tv,Ti}
    AdjMap{Ti}(x::AbstractSparseMatrixCSC)
end

vertices(g::AdjacencyMap) = OneTo(nvertices(g))

SparseArrays.getcolptr(g::AdjacencyMap) = getfield(g, :colptr)

SparseArrays.rowvals(g::AdjacencyMap) = getfield(g, :rowval)

Base.eltype(::AdjacencyMap{D,T,M}) where {D,T,M} = T
Base.eltype(::Type{<:AdjacencyMap{D,T,M}}) where {D,T,M} = T

@inline nvertices(g::AdjacencyMap) = length(getcolptr(g)) - 1

@inline nedges(g::AdjacencyMap) = Int(@inbounds(getcolptr(g)[nvertices(g) + 1])) - 1

function Base.size(g::AdjacencyMap, i::Int)
    if i === 1 || i === 2
        return nvertices(g)
    else
        return 1
    end
end
@inline function Base.size(g::AdjacencyMap)
    v = nvertices(g)
    return (v, v)
end

function Base.show(io::IO, @nospecialize(g::AdjacencyMap))
    dir = is_directed(g) ? "directed" : "undirected"
    print(io, "{$(nvertices(g)), $(nedges(g))} $dir simple $(eltype(g)) graph")
end

""" MetaAdjView """
struct MetaAdjView{Tv,D,Ti,M,K} <: AbstractSparseMatrixCSC{Tv,Ti}
    parent::AdjacencyMap{D,Ti,ListOfMeta{M,K}}
    index::Int

    function MetaAdjView{Tv}(p::AdjacencyMap{D,Ti,ListOfMeta{M,K}}, i::Int) where {Tv,D,Ti,M,K}
        new{Tv,D,Ti,M,K}(p, i)
    end
end

Base.parent(x::MetaAdjView) = getfield(x, :parent) 

SparseArrays.getcolptr(x::MetaAdjView) = getcolptr(parent(x))

SparseArrays.rowvals(x::MetaAdjView) = rowvals(parent(x))

function SparseArrays.nonzeros(x::MetaAdjView{Tv,D,Ti,M,K}) where {Tv,D,Ti,M,K}
    ItemView{Tv,M,K}(metadata(parent(x)), getfield(x, :index))
end

nvertices(g::MetaAdjView) = nvertices(parent(g))

@inline function Base.size(g::MetaAdjView)
    v = nvertices(g)
    return (v, v)
end

Base.setindex!(x::MetaAdjView, val, i, j) = throw(MethodError(setindex!, (x, val, i, j)))

Base.setindex!(x::MetaAdjView, val, i) = throw(MethodError(setindex!, (x, val, i)))

function Metadata.metadata_keys(x::AdjacencyMap{D,T,M}) where {D,T,M<:ListOfMeta}
    Metadata.metadata_keys(metadata(x))
end
metadata(g::AdjacencyMap) = getfield(g, :metadata)

function metadata(x::AdjacencyMap, k::Int)
    @boundscheck (1 <= i <= length(metadata_keys(x))) && throw(BoundsError(x, i))
    return MetaAdjView{typeof(first(@inbounds(getfield(x, :metadata)[i])))}(x, k)
end

metadata_type(::Type{<:AdjacencyMap{D,T,M}}) where {D,T,M} = eltype(M)

