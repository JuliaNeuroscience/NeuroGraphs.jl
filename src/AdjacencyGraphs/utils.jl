
function is_undirected(n::Int, cptr::Vector, rval::Vector)
    for col = OneTo(n)
        l1 = cptr[col+1]-1
        for i = 0 : (l1 - cptr[col])
            if rval[l1-i] <= col
                break
            end
            return false
        end
    end
    return true
end

@noinline function _check_type(n::Integer, T::Type)
    if 0 ≤ n && (!isbitstype(Ti) || n ≤ typemax(Ti))
        throw(ArgumentError("number of vertices (nv = $n) does not fit in eltype = $(T)"))
    end
    return nothing
end

# stronger check for debugging purposes
# && all(issorted(@view rowval[colptr[i]:colptr[i+1]-1]) for i=1:n)
_goodbuffers(g::AdjacencyMap) = _goodbuffers(nvertices(g), getcolptr(g), rowvals(g), metadata(g))
function _goodbuffers(n, cptr, rval, ::NoMetadata)
    if !(length(cptr) == n + 1 && cptr[end] - 1 == length(rval))
        throw(ArgumentError("Illegal buffers for AdjacencyMap construction $n $colptr $rowval $nzval"))
    end
    return nothing
end
function _goodbuffers(n, cptr, rval, m)
    if !(length(cptr) == n + 1 && cptr[end] - 1 == length(rval) == length(m))
        throw(ArgumentError("Illegal buffers for AdjacencyMap construction $n $colptr $rowval $nzval"))
    end
    return nothing
end

function _check_length(rowstr, rowval, minlen, Ti)
    throwmin(len, minlen, rowstr) = throw(ArgumentError("$len == length($rowstr) < $minlen"))
    throwmax(len, max, rowstr) = throw(ArgumentError("$len == length($rowstr) >= $max"))

    len = length(rowval)
    len >= minlen || throwmin(len, minlen, rowstr)
    !isbitstype(Ti) || len < typemax(Ti) || throwmax(len, typemax(Ti), rowstr)
    return nothing
end

_check_meta_length(ne, ::NoMetadata) = nothing
function _check_meta_length(ne, m)
    if ne != length(m)
        throw(ArgumentError("""
        cannot assign AdjacencyMap list of metadata with length different than number of edges:
        number of edges = $(Int(ne))
        length metadata list = $(length(m))
        """))
    end
    return nothing
end
# This is a bad but it's also the only thing the stops me from writing the print code for
# MetaAdjView here.
SparseArrays._checkbuffers(m::MetaAdjView) = _goodbuffers(parent(m))
