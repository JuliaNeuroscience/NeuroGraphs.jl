
mutable struct DynamicCount <: AbstractUnitRange{Int}
    stop::Int

    DynamicCount(stop::Real) = new(Int(max(0, stop)))

    function DynamicCount(r::AbstractRange)
        first(r) == 1 || (Base.@_noinline_meta; throw(ArgumentError("first element must be 1, got $(first(r))")))
        step(r)  == 1 || (Base.@_noinline_meta; throw(ArgumentError("step must be 1, got $(step(r))")))
        return DynamicCount(last(r))
    end
end

@inline Base.setproperty!(x::DynamicCount, s::Symbol, v::Int) = setfield!(x, s, max(0, v))

Base.first(x::DynamicCount) = 1

Base.last(x::DynamicCount) = getfield(x, :stop)

Base.length(x::DynamicCount) = last(x)

@propagate_inbounds function Base.getindex(x::DynamicCount, i::Integer)
    @boundscheck ((i > 0) & (i <= last(x))) || throw(BoundsError(x, i))
    return Int(i)
end

@inline Base.:(>)(x::DynamicCount, y::DynamicCount) = getfield(y, :stop) > getfield(y, :stop)

@inline Base.:(>)(x::DynamicCount, y::Int) = getfield(y, :stop) > y

@inline Base.:(>)(x::Int, y::DynamicCount) = x > getfield(y, :stop)

@inline Base.:(>=)(x::DynamicCount, y::DynamicCount) = getfield(y, :stop) >= getfield(y, :stop)

@inline Base.:(>=)(x::Int, y::DynamicCount) = x >= getfield(y, :stop)

@inline Base.:(>=)(x::DynamicCount, y::Int) = getfield(y, :stop) >= y

@inline Base.:(<)(x::Int, y::DynamicCount) = x < getfield(y, :stop)

@inline Base.:(<)(x::DynamicCount, y::Int) = getfield(y, :stop) < y

@inline Base.:(<)(x::DynamicCount, y::DynamicCount) = getfield(y, :stop) < getfield(y, :stop)

@inline Base.:(<=)(x::DynamicCount, y::DynamicCount) = getfield(y, :stop) <= getfield(y, :stop)

@inline Base.:(<=)(x::Int, y::DynamicCount) = x <= getfield(y, :stop)

@inline Base.:(<=)(x::DynamicCount, y::Int) = getfield(y, :stop) <= y

@inline Base.:(==)(x::DynamicCount, y::DynamicCount) = getfield(y, :stop) === getfield(y, :stop)

@inline Base.:(==)(x::Int, y::DynamicCount) = x === getfield(y, :stop)

@inline Base.:(==)(x::DynamicCount, y::Int) = getfield(y, :stop) === y

@inline add!(x::DynamicCount, y::Int) = setfield!(x, max(0, getfield(x, :stop) + y))

@inline sub!(x::DynamicCount, y::Int) = setfield!(x, :stop, max(0, getfield(x, :stop) - y))

