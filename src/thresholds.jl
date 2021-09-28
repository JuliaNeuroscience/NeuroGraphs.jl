
function binarize_proportion(g::Union{SimpleWeightedGraph,SimpleWeightedDiGraph}, prop)
    b = nonzeros(g.weights)
    N = round(Int, length(b) * prop)
    return binarize_absolute(g, sort(b)[N])
end

function compute_threshold_from_proportion(
    g::Union{SimpleWeightedGraph,SimpleWeightedDiGraph},
    prop::AbstractVector
)
    b = nonzeros(g.weights)
    N = length(b)
    sb = sort(b)
    return [sb[round(Int, N * p)] for p in prop]
end


function binarize_absolute(g, thresh)
    out = SimpleGraph(nv(g))
    for e in edges(g)
        if weight(e) > thresh
            add_edge!(out, src(e), dst(e))
        end
    end
    return out
end

each_threshold(op, g, thresh) = [op(binarize_absolute(g, t)) for t in thresh]
each_proportion(op, g, prop) = each_threshold(op, g, compute_threshold_from_proportion(g, prop))

