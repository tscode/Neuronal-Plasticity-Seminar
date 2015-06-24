type ErdösRenyiTopology <: AbstractTopology
  params::Vector{AbstractParameter}

  function ErdösRenyiTopology(p=0.1)
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    params = AbstractParameter[ Parameter{Float64}( "percentage", 0.0, 1.0,  p)]
    new(params)
  end
end

#=type FeedForwardTopology <: AbstractTopology=#

function generate(top::ErdösRenyiTopology, size::Integer, rng::AbstractRNG)
  # generates an Erdös Renyi topology
  p = top.params[1].val
  return spones(sprandn(rng, size, size, p)) # TODO use sprandbool
end
