type ErdösRenyiTopology <: AbstractTopology
  params::Vector{AbstractParameter}

  function ErdösRenyiTopology(p=0.1)
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    params = AbstractParameter[ Parameter{Float64}( "percentage", 0.0, 1.0,  p)]
    new(params)
  end
end

function generate(top::ErdösRenyiTopology, size::Integer, rng::AbstractRNG)
  # generates an Erdös Renyi topology
  p = top.params[1].val
  m = spones(sprandn(rng, size, size, p)) # TODO use sprandbool
  i = 1
  for i = 1:Base.size(m)[1]
     m[i, i] = 0
  end
  return m
end


type RingTopology <: AbstractTopology
  params::Vector{AbstractParameter}

  function RingTopology(k = 2)
    @assert 0 <= k "distance is nonnegativ"
    params = AbstractParameter[ Parameter{Float64}( "distance", 0.0, typemax(Float64),  k)]
    new(params)
  end
end

function generate(top::RingTopology, size::Integer, rng::AbstractRNG)
  # generates NN topology
  k = top.params[1].val
  m = spzeros(size, size)
  for i = 1:Base.size(m)[1], j = 1:Base.size(m)[1]
    if i != j
      m[i, j] = abs(i-j) < k ? 1 : 0
    end
  end
  return m
end
