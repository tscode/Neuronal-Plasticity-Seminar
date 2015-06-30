export AbstractParameter
export Parameter

abstract AbstractParameter

# only classes that don't have those members need to reimplement these funtions
function get_value(p::AbstractParameter)
  return p.val
end

function get_name(p::AbstractParameter)
  return p.name::UTF8String
end

# relative Parameter: changesproportional to current value

# introduce parameter type that is used for genetic modifications
# each parameter corresponds loosely to one gene that can be modified
# by reproduction and mutation
type Parameter{T} <: AbstractParameter
    name::UTF8String
    min::T
    max::T
    val::T
end

function Parameter{T}(name::UTF8String, value::T; min::T=typemin(T), max::T=typemax(T))
  return Parameter{T}(name, min, ax, value)
end


# randomize parameters
function random_param( param::Parameter{Int}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = convert(Int, round( param.val * (1.0 + randn(rng) * s) ))
  # Check if the new value is within the boundaries
  return Parameter{Int}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end


function random_param( param::Parameter{Float64}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val * (1.0 + randn(rng) * s) #  0.9 ... 1.1 is default
  # Check if the new value is within the boundaries and return new param
  return Parameter{Float64}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end
