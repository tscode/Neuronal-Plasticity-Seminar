# This file contains parts of Julia. License is MIT: http://julialang.org/license

#
# RANDOM
#
# Contains basic random number functionality and routines.

# Enhance these functions rather than overwrite them
#
import Base.rand
import Base.shuffle

function rand( rng::AbstractRNG, a::AbstractVector )
  a[convert(Int, ceil(rand(rng)*length(a)))]
end

function shuffle!(rng::AbstractRNG, elem::AbstractVector)
    for i = length(elem):-1:2
        j = convert(Int, ceil(rand(rng)*i))
        elem[i], elem[j] = elem[j], elem[i]
    end
    return elem
end

shuffle(rng::AbstractRNG, elem::AbstractVector) = shuffle!(rng, copy(elem))

# Other random routines
#
randbool(rng::AbstractRNG) = rand(rng, Bool[true, false])
randseed() = convert(Uint32, round(rand() * typemax(Uint32)))
randseed(rng::AbstractRNG) = convert(Uint32, round(rand(rng) * typemax(Uint32)))

function choice( rng::AbstractRNG, elem::AbstractVector, p::Vector{Float64})
  @assert(sum(p) >= 1-1e-5)
  @assert(length(elem) == length(p))
  r = rand(rng)
  cp::Float64 = 0
  @inbounds for i = 1:length(p)
    if r < (cp += p[i])
      return elem[i]
    end
  end
end


# Is used for the Challenges. Uniform and normal distributions
# in the range a to b. Only one parameter as argument will yield the
# deterministic limit case
#
unif(rng::AbstractRNG, a::Real, b::Real) = a + (b - a)*rand(rng)
unif(a::Real, b::Real) = a + (b - a)*rand()
unif(rng::AbstractRNG, a::Real) = a
unif(a::Real) = a 

normal(rng::AbstractRNG, a::Real, b::Real) = 0.5 * (a + b) + 0.5 * (b - a) * randn(rng)
normal(a::Real, b::Real) = 0.5 * (a + b) + 0.5 * (b - a) * randn()
normal(rng::AbstractRNG, a::Real) = a
normal(a::Real) = a
