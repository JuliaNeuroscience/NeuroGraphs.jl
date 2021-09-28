
const AdjDiMap{T,M} = AdjacencyMap{T,M,true}
const AdjMap{T,M} = AdjacencyMap{T,M,false}

AdjMap{T}(n::Integer) where {T} = AdjMap{T}(n, no_metadata)

AdjDiMap{T}(n::Integer) where {T} = AdjDiMap{T}(n, no_metadata)

function AdjMap{T}(n::Integer, m) where {T}
    (n < 0) && throw(ArgumentError("cannot have negative number of vertices"))
    return AdjMap(DynamicAxis(n), fill(one(T), n+1), T[], m)
end

function AdjDiMap{T}(n::Integer) where {T}
    (n < 0) && throw(ArgumentError("cannot have negative number of vertices"))
    return AdjDiMap(DynamicAxis(n), fill(one(T), n+1), T[], m)
end

function AdjMap{T}() where {T} = AdjMap{T}(n)
    AdjMap(DynamicAxis(n), T[1]), T[], no_metadata)
end

AdjDiMap{T}() where {T} = AdjDiMap{T}(n, no_metadata)




