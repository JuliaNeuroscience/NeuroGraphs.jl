
struct ListOfMeta{M,K}
    list::Vector{M}
    keys::K

    ListOfMeta{M,K}() where {M,K} = new{M,K}(M[], K())
    function ListOfMeta(x::Vector{NamedTuple{K,T}}) where {K,T}
        new{NamedTuple{K,T},Nothing}(x, nothing)
    end
    function ListOfMeta(x::Vector{Tuple{Vararg{Any,N}}}) where {N}
        ax = static(1)::static(N)
        new{eltype(x),typeof(ax)}(x, ax)
    end
    function ListOfMeta(x::Vector{M}, k) where {M}
        length(first(x)) == length(k) || throw(ArgumentError("Metadata items cannot have length different from provided keys."))
        new{M,typeof(k)}(x, k)
    end
    function ListOfMeta(x::Vector{M}) where {M<:Number}
        ax = static(1):static(1)
        new{M,typeof(ax)}(x, ax)
    end
    function ListOfMeta(x::Vector{M}) where {M<:AbstractVector}
        ax = axes(first(x), 1)
        new{M,typeof(ax)}(x, ax)
    end
end

Base.parent(m::ListOfMeta) = getfield(m, :list)

Base.eltype(::Type{<:ListOfMeta{M,K}}) where {M,K} = M

Base.length(x::ListOfMeta) = length(getfield(x, :list))

metadata_keys(x::ListOfMeta{NamedTuple{K,T},Nothing}) where {K,T} = K

metadata_keys(x::ListOfMeta{Tuple{Vararg{Any,N}},Nothing}) where {N} = static(1):static(N)

metadata_keys(x::ListOfMeta{M,K}) where {M,K} = getfield(x, :keys)

struct ItemView{T,M,K} <: AbstractVector{T}
    metadata::ListOfMeta{M,K}
    index::Int
end

Base.length(x::ItemView) = length(getfield(x, :metadata))

## getindex
@propagate_inbounds function Base.getindex(x::ListOfMeta, i::Int)
    @boundscheck (1 <= i <= length(keys(x))) && throw(BoundsError(x, i))
    return ItemView(x, i)
end

@propagate_inbounds function Base.getindex(x::ListOfMeta, i::Symbol)
    index = findfirst(==(i), keys(x))
    @boundscheck index === nothing && throw(BoundsError(x, i))
    return ItemView(x, index)
end

@propagate_inbounds function Base.getindex(x::ItemView, i::Int)
    item = getfield(getfield(x, :metadata), :list)[i]
    return @inbounds(item[getfield(x, :index)])
end

