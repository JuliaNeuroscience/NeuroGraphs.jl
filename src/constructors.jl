
x = [0 1 0 0 1;
     0 0 1 0 0;
     0 0 0 1 0;
     0 0 0 0 1;
     0 0 0 0 0]



#=
@inline function _istriu(A::AbstractMatrix, k)
    m, n = size(A)
    for j in 1:min(n, m + k - 1)
        all(iszero, view(A, max(1, j - k + 1):m, j)) || return false
    end
    return true
end




    function AdjacencyMap(n::Integer, cptr::Vector, rval::Vector, m::M, d::StaticBool) where {M}
        T = promote_type(eltype(cptr), eltype(rval))
        _check_type(n, T)
        # String interpolation is a performance bottleneck when it's part of the same function,
        # ensure we only do it once committed to the error.
        throwstart(ckp) = throw(ArgumentError("$ckp == colptr[1] != 1"))
        throwmonotonic(ckp, ck, k) = throw(ArgumentError("$ckp == colptr[$(k-1)] > colptr[$k] == $ck"))
        _check_length("colptr", cptr, n+1, String) # don't check upper bound
        ckp = T(1)
        ckp == cptr[1] || throwstart(ckp)
        @inbounds for k = 2:n+1
            ck = cptr[k]
            ckp <= ck || throwmonotonic(ckp, ck, k)
            ckp = ck
        end
        _check_length("rowval", rval, ckp - 1, T)
        if !(M <: NoMetadata)
            # we allow empty nzval
            _check_length("metadata", m, 0, T)
        end

        # silently shorten rval and nzval to usable index positions.
        maxlen = abs(widemul(m, n))
        isbitstype(T) && (maxlen = min(maxlen, typemax(Ti) - 1))
        length(rval) > maxlen && resize!(rval, maxlen)
        length(nzval) > maxlen && resize!(nzval, maxlen)
        _goodbuffers(n, cptr, rval, m)
        new{T,M,d === static(true)}(DynamicCount(n), cptr, rval, m)
    end
=#

