type MetaCombinationParam <: AbstractParameter
  name::ASCIIString
  val::Vector{Float64}
end

type MetaGenerator <: AbstractGenerator
  generators::Vector{AbstractGenerator}
  metaparam::MetaCombinationParam
  common_params::Vector{ASCIIString}

  function MetaGenerator( gens::Vector{AbstractGenerator}; p::Vector{Float64} = [1/length(gens) for i=1:length(gens)] , commmon_params = ASCIIString[] )
    @assert sum(p) == 1
    new(gens, MetaCombinationParam("meta_strengths", p), common_params)
  end
end

# Meta Generator relative generator contribution
function random_param( param::MetaCombinationParam, rng::AbstractRNG; s::Real = 0.1 )
  new_random_val = Float64[rand(rng) for i in param.val]
  new_random_val /= sum(new_random_val)

  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val + s*new_random_val
  new_val /= sum(new_val)

  # Check if the new value is within the boundaries and return new param
  return Parameter{Float64}(param.name, new_val)
end


# Generate a concrete, random network (phenotype) using the generator (genotype)
function generate( gen::MetaGenerator; seed::Integer = randseed(),
                   num_input::Integer=0, num_output::Integer=1 )   ## TO BE GENERALIZED
  # initialize an rng by the given seed
  rng = MersenneTwister(seed)

  # generate one network with each generator
  nets = [generate(g, seed=randseed(rng), num_input=num_input, num_output=num_output) for g in gen.generators]

  # now for the hard part! combine them
  # to do that, we make the following assumptions:
  # each net defines ω_r, which is the matrix we combine here
  # the first generator in the list is used as master generator for now
  # which will supply the other data for the network
  for i = 1:length(nets)
    @assert size(nets[1].ω_r) == size(nets[i].ω_r) "recurrent matrix sizes incompatible"
  end

  # iterate over whole matrix
  @inbounds for x = 1:size(nets[1].ω_r)[1], y = 1:size(nets[1].ω_r)[2]
    nets[1].ω_r[x, y] = choice(rng, [nets[i].ω_r[x, y] for i in 1:length(nets)], metaparam.val)
  end

  return nets[1]
end


# allow the parameters to be exported
function export_params( gen::MetaGenerator )
  all_params = AbstractParameter[]
  # add prefixes and combine parameters
  for g in gen.generators
    pars = export_params(g)
    for p in pars
      if !(p.name in gen.common_params)
        p.name = string(typeof(g)) * p.name
      end

      unique = true
      for s in all_params
        if s.name == p.name
          @assert s.val = p.val
          unique = false
        end
      end
      if unique
        push!(all_params, p)
      end
    end
  end
  push!(all_params, metaparam)
  return all_params
end

# import parameters in a network
function import_params!(gen::MetaGenerator, params::Vector{AbstractParameter})
  params = deepcopy(params) # just to be safe
  for g in gen.generators
    #remove prefix
    pog = AbstractParameter[]
    for p in params
      if p.name in gen.common_params
        push!(pog, p)
      elseif startswith(p.name, string(typeof(g)))
        p.name = replace(p.name, string(typeof(g)), "")
        push!(pog, p)
      end
    end
    import_params!(g, pog)
  end

  for p in params
      if p.name == "meta_strengths"
        gen.metaparam = deepcopy(p)
      end
  end
end
