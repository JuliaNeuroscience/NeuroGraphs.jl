
function strength(g::MetaDiGraph, v::Integer; normalize::Bool=true)
    instrength(g, v; normalize=normalize) + outstrength(g, v; normalize=normalize)
end
function strength(g::MetaGraph, v::Integer; normalize::Bool=true)
    instrength(g, v; normalize=normalize)
end

function strength(g, vs::AbstractVector=vertices(g); normalize::Bool=true)
    [strength(g, v_i; normalize=normalize) for v_i in vs]
end


function instrength(g, vs::AbstractVector=vertices(g); normalize::Bool=true)
    [instrength(g, v_i; normalize=normalize) for v_i in vs]
end
function instrength(g::AbstractMetaGraph{T,M}, v::Integer; normalize::Bool=true) where {T,M}
    v_v = inneighbors(g, v)
    out = zero(weighttype(M))
    for e in getfield(v_v, :v)
        out += metadata(e, :weight)
    end
    if normalize
        return out / (length(v_v) - 1)
    else
        return out
    end
end

function outstrength(g, vs::AbstractVector=vertices(g); normalize::Bool=true)
    [outstrength(g, v_i; normalize=normalize) for v_i in vs]
end
function outstrength(g::AbstractMetaGraph{T,M}, v::Integer; normalize::Bool=true) where {T,M}
    v_v = outneighbors(g, v)
    out = zero(weighttype(M))
    for e in getfield(v_v, :v)
        out += metadata(e, :weight)
    end
    if normalize
        return out / (length(v_v) - 1)
    else
        return out
    end
end
