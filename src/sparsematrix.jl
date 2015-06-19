# This file contains parts of Julia. License is MIT: http://julialang.org/license

function shuffle!(r::AbstractRNG, a::AbstractVector)
    for i = length(a):-1:2
        j = convert(Int, ceil(rand(r)*i))
        a[i], a[j] = a[j], a[i]
    end
    return a
end

shuffle(r::AbstractRNG, a::AbstractVector) = shuffle!(r, copy(a))


function ev_randsubseq!(r::AbstractRNG, S::AbstractArray, A::AbstractArray, p::Real)
    0 <= p <= 1 || throw(ArgumentError("probability $p not in [0,1]"))
    n = length(A)
    p == 1 && return copy!(resize!(S, n), A)
    empty!(S)
    p == 0 && return S
    nexpected = p * length(A)
    sizehint(S, convert(Int, round(nexpected + 5*sqrt(nexpected))))
    if p > 0.15 # empirical threshold for trivial O(n) algorithm to be better
        for i = 1:n
            rand(r) <= p && push!(S, A[i])
        end
    else
        # Skip through A, in order, from each element i to the next element i+s
        # included in S. The probability that the next included element is
        # s==k (k > 0) is (1-p)^(k-1) * p, and hence the probability (CDF) that
        # s is in {1,...,k} is 1-(1-p)^k = F(k).   Thus, we can draw the skip s
        # from this probability distribution via the discrete inverse-transform
        # method: s = ceil(F^{-1}(u)) where u = rand(), which is simply
        # s = ceil(log(rand()) / log1p(-p)).
        # -log(rand()) is an exponential variate, so can use randexp().
        L = 1 / log1p(-p) # L > 0
        i = 0
        while true
            s = log(rand(r)) * L
            s >= n - i && return S # compare before ceil to avoid overflow
            push!(S, A[i += convert(Int, ceil(s))])
        end
        # [This algorithm is similar in spirit to, but much simpler than,
        #  the one by Vitter for a related problem in "Faster methods for
        #  random sampling," Comm. ACM Magazine 7, 703-718 (1984).]
    end
    return S
end
ev_randsubseq!(S::AbstractArray, A::AbstractArray, p::Real) = ev_randsubseq!(GLOBAL_RNG, S, A, p)

ev_randsubseq{T}(r::AbstractRNG, A::AbstractArray{T}, p::Real) = ev_randsubseq!(r, T[], A, p)
ev_randsubseq(A::AbstractArray, p::Real) = ev_randsubseq(GLOBAL_RNG, A, p)


sparse_IJ_sorted!(I,J,V,m,n) = sparse_IJ_sorted!(I,J,V,m,n,+)

sparse_IJ_sorted!(I,J,V::AbstractVector{Bool},m,n) = sparse_IJ_sorted!(I,J,V,m,n,|)

function sparse_IJ_sorted!{Ti<:Integer}(I::AbstractVector{Ti}, J::AbstractVector{Ti},
                                        V::AbstractVector,
                                        m::Integer, n::Integer, combine::Function)

    m = m < 0 ? 0 : m
    n = n < 0 ? 0 : n
    if length(V) == 0; return spzeros(eltype(V),Ti,m,n); end

    cols = zeros(Ti, n+1)
    cols[1] = 1  # For cumsum purposes
    cols[J[1] + 1] = 1

    lastdup = 1
    ndups = 0
    I_lastdup = I[1]
    J_lastdup = J[1]
    L = length(I)

    @inbounds for k=2:L
        if I[k] == I_lastdup && J[k] == J_lastdup
            V[lastdup] = combine(V[lastdup], V[k])
            ndups += 1
        else
            cols[J[k] + 1] += 1
            lastdup = k-ndups
            I_lastdup = I[k]
            J_lastdup = J[k]
            if ndups != 0
                I[lastdup] = I_lastdup
                V[lastdup] = V[k]
            end
        end
    end

    colptr = cumsum(cols)

    # Allow up to 20% slack
    if ndups > 0.2*L
        numnz = L-ndups
        deleteat!(I, (numnz+1):L)
        deleteat!(V, (numnz+1):length(V))
    end

    return SparseMatrixCSC(m, n, colptr, I, V)
end

function sprand{T}(r::AbstractRNG, m::Integer, n::Integer, density::FloatingPoint,
                   rfn::Function,::Type{T}=eltype(rfn(r,1)))
    ((m < 0) || (n < 0)) && throw(ArgumentError("invalid Array dimensions"))
    0 <= density <= 1 || throw(ArgumentError("$density not in [0,1]"))
    N = n*m
    N == 0 && return spzeros(T,m,n)
    N == 1 && return rand(r) <= density ? sparse(rfn(r,1)) : spzeros(T,1,1)

    I, J = Array(Int, 0), Array(Int, 0) # indices of nonzero elements
    sizehint(I, int(N*density))
    sizehint(J, int(N*density))

    # density of nonzero columns:
    L = log1p(-density)
    coldensity = -expm1(m*L) # = 1 - (1-density)^m
    colsparsity = exp(m*L) # = 1 - coldensity
    L = 1/L

    rows = Array(Int, 0)
    for j in ev_randsubseq(r, 1:n, coldensity)
        # To get the right statistics, we *must* have a nonempty column j
        # even if p*m << 1.   To do this, we use an approach similar to
        # the one in randsubseq to compute the expected first nonzero row k,
        # except given that at least one is nonzero (via Bayes' rule);
        # carefully rearranged to avoid excessive roundoff errors.
        k = ceil(log(colsparsity + rand(r)*coldensity) * L)
        ik = k < 1 ? 1 : k > m ? m : int(k) # roundoff-error/underflow paranoia
        ev_randsubseq!(r, rows, 1:m-ik, density)
        push!(rows, m-ik+1)
        append!(I, rows)
        nrows = length(rows)
        Jlen = length(J)
        resize!(J, Jlen+nrows)
        @inbounds for i = Jlen+1:length(J)
            J[i] = j
        end
    end
    return sparse_IJ_sorted!(I, J, rfn(r,length(I)), m, n, +)  # it will never need to combine
end

sprand(r::AbstractRNG, m::Integer, n::Integer, density::FloatingPoint) = sprand(r,m,n,density,rand,Float64)
sprandn(r::AbstractRNG, m::Integer, n::Integer, density::FloatingPoint) = sprand(r,m,n,density,randn,Float64)


