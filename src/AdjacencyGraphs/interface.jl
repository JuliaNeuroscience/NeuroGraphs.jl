
is_directed(::AdjacencyMap{D}) where {D} = D
is_directed(::Type{<:AdjacencyMap{D}}) where {D} = D

###
### has_edge
###
has_edge(g::AdjacencyMap, e::AbstractEdge) = has_edge(g, src(e), dst(e))
function has_edge(g::AdjMap, i::Integer, j::Integer)
    if i < j
        if j <= nvertices(g)
            unsafe_has_edge(getcolptr(g), rowvals(g), i, j)
        else
            return false
        end
    else ## j <= i
        if i <= nvertices(g)
            unsafe_has_edge(getcolptr(g), rowvals(g), j, i)
        else
            return false
        end
    end
end
function has_edge(g::AdjDiMap, i::Integer, j::Integer)
    N = nvertices(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    else
        unsafe_has_edge(getcolptr(g), rowvals(g), i, j)
    end
end
function unsafe_has_edge(cptr, rvals, i, j)
    coljlastk = @inbounds(cptr[j + 1] - 1)
    searchk = searchsortedfirst(rvals, i, @inbounds(cptr[j]), coljlastk, Base.Order.Forward)
    return searchk <= coljlastk && @inbounds(rvals[searchk]) == i
end

###
### add_edge!
###
add_edge!(g::AdjacencyMap, i::Int, j::Int) = add_edge!(g, i, j, no_metadata)
function add_edge!(g::AdjMap, i::Int, j::Int, val) where {T,M}
    N = nvertices(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    elseif i < j
        unsafe_add_edge!(g, i, j, val)
    else
        unsafe_add_edge!(g, j, i, val)
    end
end
function add_edge!(g::AdjDiMap, i::Int, j::Int, val) where {T,M}
    N = nvertices(g)
    if !((1 <= i <= N) & (1 <= j <= N))
        return false
    else
        return unsafe_add_edge!(g, i, j, val)
    end
end
function unsafe_add_edge!(g, i, j, val)
    coljlastk = @inbounds(getcolptr(g)[j + 1] - 1)
    searchk = searchsortedfirst(rowvals(g), i, @inbounds(getcolptr(g)[j]), coljlastk, Base.Order.Forward)
    if searchk <= coljlastk && rowvals(g)[searchk] == i
        _setindex!(metadata(g), val, searchk)
        return true
    else
        N = nvertices(g)
        nz = getcolptr(g)[N + 1]
        # if nnz(A) < length(rowval/nzval): no need to grow rowval and preserve values
        _insert!(rowvals(g), searchk, i, nz)
        _insert!(metadata(g), searchk, val, nz)
        @simd for i in (j + 1):(N + 1)
            @inbounds getcolptr(g)[i] += 1
        end
    end
    return true
end
# insert item at position pos, shifting only from pos+1 to nz
_insert!(m, pos, ::NoMetadata, nz) = error()
_insert!(::NoMetadata, pos, ::NoMetadata, nz) = nothing
function _insert!(m, pos, val, nz)
    if nz > length(m)
        insert!(m, pos, val)
    else # nz < length(v)
        Base.unsafe_copyto!(m, pos + 1, m, pos, nz - pos)
        @inbounds(setindex!(m, val, pos))
        m 
    end
end
_insert!(m::ListOfMeta, pos, val, nz) = _insert!(parent(m), pos, val, nz)

_setindex!(nzvals, val, i) = @inbounds(setindex!(nzvals, val, i))
_setindex!(m::ListOfMeta, val, i) = _setindex!(parent(m), val, i)
_setindex!(::NoMetadata, ::NoMetadata, i) = nothing
_setindex!(::NoMetadata, val, i) = nothing
_setindex!(nzvals, ::NoMetadata, i) = nothing


###
### rem_edge!
###
rem_edge!(g::AdjDiMap, i::Integer, j::Integer) = unsafe_rem_edge!(g, i, j)
function rem_edge!(g::AdjMap, i::Integer, j::Integer)
    if i < j
        return unsafe_rem_edge!(g, i, j)
    else
        return unsafe_rem_edge!(g, j, i)
    end
end
function unsafe_rem_edge!(g::AdjacencyMap, i::Integer, j::Integer)
    N = nvertices(g)
    if !((1 <= i <= N) && (1 <= j <= N))
        return false
    else
        cptr = getcolptr(g)
        rval = rowvals(g)
        coljlastk = @inbounds(cptr[j + 1]) - 1
        searchk = searchsortedfirst(rval, i, @inbounds(cptr[j]), coljlastk, Base.Order.Forward)
        if searchk > coljlastk || @inbounds(rval[searchk]) != i
            return false
        else
            Awritepos = 1
            oldAcolptrAj = 1
            @inbounds for Aj in OneTo(N)
                for Ak in oldAcolptrAj:(cptr[Aj + 1]-1)
                    if Ak != searchk && Awritepos != Ak
                        # If this element should be kept, rewrite in new position
                        _move_value!(rval, Awritepos, Ak)
                        _move_value!(metadata(g), Awritepos, Ak)
                    end
                    Awritepos += 1
                end
                oldAcolptrAj = Acolptr[Aj + 1]
                Acolptr[Aj + 1] = Awritepos
            end

            # Trim A's storage if necessary
            Annz = Acolptr[end] - 1
            resize!(rval, Annz)
            resize!(m, Annz)
            return true
        end
    end
end

_move_value!(m, d, s) = @inbounds(setindex!(m, m[s], d))
_move_value!(::NoMetadata, d, s) = nothing

function SparseArrays.fkeep!(A::AdjacencyMap, f)
    An = size(A, 2)
    Acolptr = getcolptr(A)
    Arowval = rowvals(A)
    Anzval = metadata(A)

    # Sweep through columns, rewriting kept elements in their new positions
    # and updating the column pointers accordingly as we go.
    Awritepos = 1
    oldAcolptrAj = 1
    @inbounds for Aj in 1:An
        for Ak in oldAcolptrAj:(Acolptr[Aj+1]-1)
            Ai = Arowval[Ak]
            Ax = Anzval[Ak]
            # If this element should be kept, rewrite in new position
            if f(Ai, Aj, Ax)
                if Awritepos != Ak
                    _move_value!(rval, Awritepos, Ak)
                    _move_value!(Anzval, Awritepos, Ak)
                end
                Awritepos += 1
            end
        end
        oldAcolptrAj = Acolptr[Aj+1]
        Acolptr[Aj+1] = Awritepos
    end

    # Trim A's storage if necessary
    Annz = Acolptr[end] - 1
    resize!(Arowval, Annz)
    resize!(Anzval, Annz)

    return A
end

###
### add_vertices!
###
function add_vertices!(g::AdjacencyMap, n::Integer)
    if can_change_size(g)
        return _unsafe_add_vertices!(g, max(0, n))
    else
        return false
    end
end

function _unsafe_add_vertices!(g::AdjacencyMap, n)
    cptr = getcolptr(g)
    c = last(cptr)
    for _ in OneTo(n)
        push!(cptr, c)
    end
    return true
end

function add_vertex!(g::AdjacencyMap)
    cptr = getcolptr(g)
    push!(cptr, last(cptr))
    return true
end

###
### add_vertices!
###
# TODO LightGraphs.rem_vertex!(m::AdjMap, n::Integer)
# TODO LightGraphs.rem_vertices!(m::AdjMap, n::AbstractVector)
# TODO check this a bunch
function rem_vertex!(g::AdjacencyMap, n::Integer)
    fkeep!(g, (i, j, x) -> (i != n && j != n))
    deleteat!(getcolptr(g), n)
end

