
# introduce parameter type that is used for genetic modifications
# each parameter corresponds loosely to one gene that can be modified
# by reproduction and mutation
type Parameter{T} <: AbstractParameter
    name::ASCIIString
    min::T
    max::T
    val::T
end

# assume that

function export_params( pob::AbstractParametricObject )
  # parameter export is simple deepcopy per default
  return deepcopy(pob.params)
end

function import_params!( pob::AbstractParametricObject, params::Vector{AbstractParameter})
  # parameter import checks parameter constistency and then performs deepcopy
  # check if the format of the parameters to be imported is suitable
  @assert length(params) == length(pob.params) "wrong length of vector of parameters $(params), $(pop.params)"
  for i in 1:length(params)
      @assert pob.params[i].name == params[i].name "parameters to be imported do not fit $(params), $(pop.params)"
  end
  # if it is then hand over a copy to the generator
  pob.params = deepcopy(params)
end


# functions operating on arrays of parameters useable to implement parameter import/export of higher level objects
function export_params( pobs::Vector{AbstractParametricObject} )
  # parameter export is simple deepcopy per default
  return vcat([deepcopy(p.params) for p in pobs]...)
end

function import_params!( pobs::Vector{AbstractParametricObject}, params::Vector{AbstractParameter})
  # parameter import checks parameter constistency and then performs deepcopy
  # check if the format of the parameters to be imported is suitable
  @assert length(params) == sum([length(pob.params) for pob in pobs]) "wrong length of vector of parameters"
  linearized = vcat([p.params for p in pobs]...)
  for i in 1:length(params)
      @assert linearized[i].name == params[i].name "parameters to be imported do not fit"
  end

  # if it is then hand over a copy to the generator
  lp = 0
  for i in 1:length(pobs)
    len = length(pobs[i].params)
    pobs[i].params = deepcopy( params[(lp+1):(lp+=len)] )
  end
  @assert lp == length(params)
end

