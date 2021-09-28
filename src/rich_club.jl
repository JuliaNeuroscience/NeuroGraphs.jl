

"""

The weighted rich club coefficient, Rw, at level k is the fraction of
edge weights that connect nodes of degree k or higher out of the
maximum edge weights that such nodes might share.


ndependent of each other, i.e. each hub has a specialised function, or they perform
some collaborative function. A graph measure to characterise the relation between the
hubs of a net- work is the rich-club phenomenon. The k-density φ(k), is defined 
as the internal density of links between the nodes with degree larger than k′:


```math
\\psi(k) = \\frac{E_{>k}}{N_{>k}(N_{>k} - 1)}
```
where ``k`` is a threshold, ``E_{k}`` is the number of edges between nodes with
a degree greater than ``k`` and ``N_{k}`` is the number of nodes with a degree
greater than ``k``.

The weighted corrollary is:

```math
\\psi^{w}(k) = \\frac{W_{>k}}{\\sum_{i=1}^{E_{>k}} w_{i}} w_{i}^{ranked}}
```
Where  ``w_{i}^{ranked}`` is the ith index of the ranked graph weights and
``W_{>k}`` is the sum of weights from those nodes with a degree greater than
``k``.
CIJ = [0 1 1 0 0 0
        1 0 1 1 1 0
        1 1 0 0 0 0
        0 1 0 0 0 0
        0 1 0 0 0 1
        0 0 0 0 1 0]
d = [2
 4
 2
 1
 2
 1]
# Examples
```jldoctest
g = Graph([0 1 1 0 0 0
           1 0 1 1 1 0
           1 1 0 0 0 0
           0 1 0 0 0 0
           0 1 0 0 0 1
           0 0 0 0 1 0])
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 3)
add_edge!(g, 2, 4)
add_edge!(g, 2, 5)
add_edge!(g, 5, 6)

```

# Citations

@cite(vandenheuvelRichClubOrganizationHuman2011)

Zamora-López G, Zhou C, Kurths J. Cortical hubs form a module for multisensory
integration on top of the hierarchy of cortical networks. Front Neuroinform. 2010
Mar 19;4:1. doi: 10.3389/neuro.11.001.2010. eCollection 2010. PubMed [citation]
PMID: 20428515, PMCID: PMC2859882

"""

# rich club coefficient curve
function rich_club_coefficient(
    g::AbstractGraph,
    krange::AbstractRange{Int},
    dstmx::AbstractMatrix
   )

    E_r = sort(dstmx[:])
    dgs = degree(g)
    [__weighted_rich_club_coefficient(k, dstmx, E_r, dgs) for k in krange]
end

# rich club coefficient at single threshold
function rich_club_coefficient(g::AbstractGraph, k::Int, dstmx::AbstractMatrix)
    __weighted_rich_club_coefficient(k, dstmx, sort(dstmx[:]), degree(g))
end

function __weighted_rich_club_coefficient(
    k::Int,
    dstmx::AbstractMatrix{T},
    E_r::AbstractVector{T},  # ranked edges
    dgs::AbstractVector{<:Integer}  # degrees
   )
    __weighted_rich_club_coefficient(dstmx, dgs .>= k, E_r)
end

function __weighted_rich_club_coefficient(
    dstmx::AbstractMatrix{T},
    E_k::AbstractVector{Bool},
    E_r::AbstractVector{T}) where T
    E_n = 0
    W_k = zero(T)
    for (x,ek_x) in enumerate(E_k)
        for (y,ek_y) in enumerate(E_k)
            if ek_x && ek_y
                W_k = dstmx[x,y]
                E_n += 1
            end
        end
    end
    return W_k / sum(E_r[1:E_n])
end

function rich_club_coefficient(g::AbstractGraph, krange::AbstractRange{T}) where {T<:Integer}
    dstmx = weights(g)
    dgs = degree(g)
    [__rich_club_coefficient(k, dstmx, dgs) for k in krange]
end

function rich_club_coefficient(g::AbstractGraph, k::Int)
    d = outdegree(g)
    d = d[d .> k]
    Nk = sum(d)
    return 2* length(d) / (Nk * (Nk - 1)) 
end

#    __rich_club_coefficient(k, weights(g), degree(g))
end

function rich_club_coefficient(k::Int, dstmx::AbstractMatrix{<:Integer}, dgs::AbstractVector{<:Integer})
    __rich_club_coefficient(dstmx, dgs .>= k)
end


# unweighted version
"""
"""
function rich_club_coefficient(g::AbstractGraph, kmax::Int)
    if is_directed(g)
        dgs = sort(indegree(g) .+ outdegree(g))
        rcc = zeros(Float64, kmax)
        for k in 1:min(kmax) - 1
            dgs = dgs[dgs .>= k]
            N_k = length(dgs)
            if N_k < 2
                rcc[k:end] .= Inf
                break
            end
            rcc[k] = sum(dgs) / (N_k * (N_k - 1))
        end
        return rcc
    else
        dgs = sort(outdegree(g))
        rcc = zeros(Float64, kmax)
        for k in 1:min(kmax) - 1
            dgs = dgs[dgs .>= k]
            N_k = length(dgs)
            if N_k < 2
                rcc[k:end] .= Inf
                break
            end
            rcc[k] = 2 * sum(dgs) / (N_k * (N_k - 1))
        end
        return rcc
    end
end

# weighted
function rich_club_coefficient(g::AbstractGraph, kmax::Int, w::AbstractMatrix)
    dstmx = copy(w)
    dgs = indegree(g) .+ outdegree(g)
    rcc = zeros(Float64, kmax)
    wrank = sort(dstmx)
    for k in 1:min(maximum(dgs), kmax)
        E_k = dgs .>= k
        dgs = dgs[E_k]
        dstmx = [E_k, E_k]
        N_k = length(dgs)
        if N_k < 2
            rcc[k:end] .= Inf
            break
        end
        wrank = wrank[1:length(dstmx .!= 0)]
        rcc[k] = sum(dstmx) / sum(wrank)
    end
    return rcc
end


function strength(
    g::AbstractGraph,
    v::Integer,
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true
   )
    if is_directed(g)
        return outstrength(g, v, dstmx, normalize=normalize)
    else
        return outstrength(g, v, dstmx, normalize=normalize) +
                instrength(g, v, dstmx, normalize=normalize)
    end
end

function strength(
    g::AbstractGraph,
    vs::AbstractVector=vertices(g),
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true
   )
    map(v->strength(g, v, dstmx, normalize=normalize), vs)
end

function instrength(
    g::AbstractGraph,
    vs::AbstractVector=vertices(g),
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true,
   )
    map(i -> instrength(g, i, dstmx, normalize=normalize), vs)
end

function instrength(
    g::AbstractGraph,
    v::Integer,
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true
   )
    maybe_strength(dstmx[inneighbors(g, v), v], normalize)
end

function outstrength(
    g::AbstractGraph,
    vs::AbstractVector=vertices(g),
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true
   )
    map(i -> outstrength(g, i, dstmx, normalize=normalize), vs)
end

function outstrength(
    g::AbstractGraph,
    v::Integer,
    dstmx::AbstractMatrix=weights(g);
    normalize::Bool=true
   )
    maybe_maybe(dstmx[v, outneighbors(g, v)], normalize)
end

function _maybe_normalize(x::AbstractVector, normalize::Bool)
    if normalize
        sum(x) / (length(x) - 1)
    else
        sum(x)
    end
end

