#
# OPTIMIZE - META PARAMETRIC OBJECT
#


# combination parameter
type MetaCombinationParam <: AbstractParameter
  name::UTF8String
  val::Vector{Float64}
end


# Meta Generator relative generator contribution
function random_param( param::MetaCombinationParam, rng::AbstractRNG; s::Real = 0.1 )
  # choose two paramerters
  p1 = rand(rng, 1:length(param.val))
  p2 = rand(rng, 1:length(param.val))

  v1 = param.val[p1]
  v2 = param.val[p2]
  sum = v1 + v2
  # rescale to 1
  v1 /= sum
  v2 /= sum

  # select a change rate
  change = min(v1, 1-v2, abs(randn(rng) * s))

  v1 += change
  v2 -= change

  # scale back
  v1 *= sum
  v2 *= sum

  param.val[p1] = v1
  param.val[p2] = v2
end

#####################################################################################

macro MakeMeta(N, T)
  return esc(quote
    import EvoNet.Param: import_params!
    import EvoNet.Param: export_params
    import EvoNet.Param: MetaCombinationParam
    type $N <: $T
      objects::Vector{$T}
      metaparam::MetaCombinationParam
      common_params::Vector{UTF8String}
      function $N( obs::Vector{$T}; p::Vector{Float64} = [1/length(obs) for i=1:length(obs)] , common_params = UTF8String["size"] )
        @assert sum(p) == 1
        new(obs, MetaCombinationParam("meta_strengths", p), common_params)
      end
    end

    # allow the parameters to be exported
    function export_params( gen::$N )
      all_params = AbstractParameter[]
      # add prefixes and combine parameters
      for g in gen.objects
        pars = export_params(g)
        for p in pars
          if !(p.name in gen.common_params)
            p.name = string(typeof(g)) * ":" * p.name
          end
          unique = true
          for s in all_params
            if s.name == p.name
              @assert s.val == p.val
              unique = false
            end
          end
          if unique
            push!(all_params, p)
          end
        end

      end
      push!(all_params, gen.metaparam)
      return all_params

    end

    # import parameters in a network
    function import_params!(gen::$N, params::Vector{AbstractParameter})
      params = deepcopy(params) # just to be safe
      for g in gen.objects
        #remove prefix
        pog = AbstractParameter[]
        for p in params
          if p.name in gen.common_params
            push!(pog, p)
          elseif startswith(p.name, utf8(string(typeof(g))))
            p.name = replace(p.name, utf8(string(typeof(g)) * ":"), "")
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
  end
             )
end

############################################################################################################

# generate function for all PObjects that define such an operation
# TODO maybe make this a macro that can use an arbitrary function name
macro MakeMetaGen(N, F)
  # TODO check that N is META
  return esc(quote
    import EvoNet.Generate: generate
    function generate (gen::$N, size::Integer, rng::AbstractRNG )
      # TODO allow generic parameter forwarding
      candidates = [$F(g, size, rng) for g in gen.objects]

      return combine(candidates, gen.metaparam.val, rng)
    end
  end
  )
end

##############################################################################################################
# a few typical combination function

# for matrices
function combine{T}(mats::Vector{AbstractMatrix{T}}, p::Vector{Float64}, rng::AbstractRNG)
  # check sizes for consistency
  for i = 1:length(candidates)
    @assert size(mats[1]) == size(mats[i]) "matrix sizes incompatible $(size(mats[1]))", "$(size(mats[i]))"
  end

  result = zeros(size(mats[1]))
  # iterate over whole matrix and randomly assign
  @inbounds for x = 1:size(mats[1])[1], y = 1:size(mats[1])[2]
    result[x, y] = choice(rng, [mats[i][x, y] for i in 1:length(mats)], p)
  end

  return result
end

function combine{T}(nums::Vector{T}, p::Vector{Float64}, rng::AbstractRNG)
  return choice(rng, nums, p)
end

################################################################################################################

# default METAs we need
#@MakeMeta(MetaTopology, AbstractTopology)
#@MakeMetaGen(MetaTopology, generate)

#println(macroexpand(:(@MakeMetaGen(MetaTopology, generate))))
