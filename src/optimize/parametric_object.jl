# interface defintion
abstract AbstractParametricObject

export AbstractParametricObject
export ParameterContainer
export export_params
export import_params!

type ParameterContainer <: AbstractParametricObject
  params::Vector{AbstractParameter}
  # TODO add convenience interface
  function ParameterContainer(params::Vector{AbstractParameter})
    new(params)
  end
end

# assume that

function export_params( pob::AbstractParametricObject )
  # parameter export is simple deepcopy per default
  return deepcopy(pob.params)
end

function import_params!( pob::AbstractParametricObject, params::Vector{AbstractParameter})
  # parameter import checks parameter constistency and then performs deepcopy
  # check if the format of the parameters to be imported is suitable
  @assert length(params) == length(pob.params) "wrong length of vector of parameters: $(params), \n$(export_params(pob))"
  for i in 1:length(params)
      @assert pob.params[i].name == params[i].name "parameters to be imported do not fit: $(params), $(pop.params)"
  end
  # if it is then hand over a copy to the generator
  pob.params = deepcopy(params)
end

# export all parameter values into a Float64 Array if possible
function get_values(pob::AbstractParametricObject)

end

# mutation function
# TODO add more parameters, e.g. mutation probability and strength
function mutate{T<:AbstractParametricObject}( rng::AbstractRNG, source::T )
  # load parameters
  params = export_params( source )
  # choose parameter-index to mutate
  id = rand( rng, 1:length(params) )
  # make the mutation
  params[id] = random_param( params[id], rng )
  # and reimport them
  target = deepcopy(source) # this assumes that source and target are equivalent!
  import_params!( target, params )
  return target
end

# helpers

# functions operating on arrays of parameters useable to implement parameter import/export of higher level objects
function export_params( pobs::Vector{AbstractParametricObject} )
  # parameter export is simple deepcopy per default
  return vcat([export_params(p) for p in pobs]...)
end

function import_params!( pobs::Vector{AbstractParametricObject}, params::Vector{AbstractParameter})
  # if it is then hand over a copy to the generator
  lp = 0
  for i in 1:length(pobs)
    len = length(export_params(pobs[i])) # it is unfortunate that we need to use export here,
                                         # but unless we want to add another function hierarchy
                                         # just to get a parameter count, it cannot be helped
    import_params!(pobs[i], params[(lp+1):(lp+len)])
    lp += len
  end
  @assert lp == length(params)
end
