#
# GENERATE - TOPOLOGY
#


abstract AbstractTopology <: AbstractParametricObject


type ErdösRenyiTopology <: AbstractTopology
  params::Vector{AbstractParameter}

  function ErdösRenyiTopology(p=0.1)
    @assert 0 < p <= 1 "p is a connection probability, thus 0 < p <= 1"
    params = AbstractParameter[ RelativeParameter{Float64}( "percentage", 0.0, 1.0,  p)]
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
    params = AbstractParameter[ RelativeParameter{Float64}( "distance", 0.0, typemax(Float64),  k)]
    new(params)
  end
end

function generate(top::RingTopology, size::Integer, rng::AbstractRNG)
  # generates NN topology
  k = top.params[1].val
  p  = k - floor(k)
  m = spzeros(size, size)
  for i = 1:Base.size(m)[1], j = 1:Base.size(m)[1]
    if i != j
      if     ( abs(i-j) < k     || abs(i-j) > size - k )
        m[i,j] = 1
      elseif ( abs(i-j) < k + 1 || abs(i-j) > size - k - 1 )
        m[i,j] = rand(rng) < p ? 1 : 0
      else
        m[i,j] = 0
    end
  end
  return m
end


type FeedForwardTopology <: AbstractTopology
  params::Vector{AbstractParameter} 
  function FeedForwardTopology( ratios::Array{Float64} )
      ratios /= sum(ratios)
      params = AbstractParameter[ NormedSumParameter("ratios", ratios) ]
      new(params)
  end
end

function generate(top::FeedForwardTopology, size::Integer, rng::AbstractRNG)
  ratios = top.params[1].val
  @assert 1-1e-5 <= sum(ratios) <= 1+1e-5 "ratios for feedforward topology do not sum to 1"
  # sizes of the single layers
  cumratios = cumsum(ratios)
  cumsizes = Int[ round(r*size) for r in cumratios ] # e.g. [2, 5, 9]
  # some sanity checks
  @assert cumsizes[end] == size "Error when generating feedforward topology; last cumsize is $(cumsizes[end]) instead of the expected value $(size)"
  # convert the cumsizes to the fitting node indices
  cumsizes += 1               # [3, 6, 10]
  prepend!(cumsizes, Int[1])   # [1, 3, 6, 10], then layer1: 1,2; layer2: 3,4,5; layer3: 6,7,8,9 (*)
  # now create the matrix with its layer structure
  m = zeros(size, size)
  # make the connections
  for i in 2:length(cumsizes)-1  # i = 2,3
      # e.g. for i = 2: j1 = 1:2, j2 = 3:5 <-- exactly as needed, see (*)
      for j1 in cumsizes[i-1]:cumsizes[i]-1, j2 in cumsizes[i]:cumsizes[i+1]-1
          m[j1, j2] = 1
      end
  end
  #=@assert Base.size(m) == (size, size)=#
  return sparse(m)
end


type CommunityTopology <: AbstractTopology
  params::Vector{AbstractParameter} 
  function CommunityTopology( ratios::Array{Float64}, p_inter::Float64, p_intra::Float64 )
      ratios /= sum(ratios)
      params = AbstractParameter[ NormedSumParameter("ratios", ratios),
                                  RelativeParameter{Float64}("prob_inter", 0., 1., p_inter),
                                  RelativeParameter{Float64}("prob_intra", 0., 1., p_intra) ]
      new(params)
  end
end


function generate(top::CommunityTopology, size::Integer, rng::AbstractRNG)
  ratios  = top.params[1].val
  p_inter = top.params[2].val
  p_intra = top.params[3].val
  @assert 1-1e-5 <= sum(ratios) <= 1+1e-5 "ratios for feedforward topology do not sum to 1"
  # sizes of the single layers
  cumratios = cumsum(ratios)
  cumsizes = Int[ round(r*size) for r in cumratios ]
  # some sanity checks
  @assert cumsizes[end] == size "Error when generating feedforward topology; last cumsize is $(cumsizes[end]) instead of the expected value $(size)"
  # convert the cumsizes to the fitting node indices
  cumsizes += 1
  prepend!(cumsizes, Int[1])
  # now create the matrix with its layer structure
  m = zeros(size, size)
  # insert the connections
  for i in 2:length(cumsizes)
      for j1 in cumsizes[i-1]:cumsizes[i]-1, j2 in 1:size
          p = cumsizes[i-1] <= j2 < cumsizes[i] ? p_intra : p_inter
          if rand(rng) < p
              m[j1, j2] = 1
          end
      end
  end
  return sparse(m)
end


# Introduce meta topologies
@MakeMeta(MetaTopology, AbstractTopology)
@MakeMetaGen(MetaTopology, generate)

