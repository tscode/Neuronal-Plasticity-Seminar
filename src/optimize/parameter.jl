# export types
export AbstractParameter
export RelativeParameter
export AbsoluteParameter

# export functions
export get_value
export get_name
export random_param

abstract AbstractParameter

# only classes that don't have those members need to reimplement these funtions
function get_value(p::AbstractParameter)
  return p.val
end

function get_name(p::AbstractParameter)
  return p.name::UTF8String
end

# relative Parameter: changes proportional to current value

# introduce parameter type that is used for genetic modifications
# each parameter corresponds loosely to one gene that can be modified
# by reproduction and mutation
#=immutable=# type RelativeParameter{T} <: AbstractParameter
    name::UTF8String
    min::T
    max::T
    val::T

    function RelativeParameter(name, min, max, value)
      @assert min <= value <= max
      new(name, min, max, value)
    end
end

function RelativeParameter{T}(name::UTF8String, value::T; min::T=typemin(T), max::T=typemax(T))
  return RelativeParameter{T}(name, min, ax, value)
end


# randomize parameters
function random_param{T<:Real}( param::RelativeParameter{T}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val * (1.0 + randn(rng) * s) #  0.9 ... 1.1 is default
  # Check if the new value is within the boundaries and return new param
  return RelativeParameter{T}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end

# special behaviour for integer
function random_param{T<:Integer}( param::RelativeParameter{T}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = convert(T, round( param.val * (1.0 + randn(rng) * s) ))
  # Check if the new value is within the boundaries
  return RelativeParameter{T}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end



# absolute Parameter: changes proportional to a predefined delta
immutable type AbsoluteParameter{T} <: AbstractParameter
    name::UTF8String
    min::T
    max::T
    val::T
    Δ::T

    function AbsoluteParameter(name, min, max, value, Δ)
      @assert min <= value <= max
      new(name, min, max, value, Δ)
    end
end

function AbsoluteParameter{T}(name::UTF8String, value::T, Δ::T; min::T=typemin(T), max::T=typemax(T))
  return AbsoluteParameter{T}(name, min, max, value, Δ)
end


# randomize parameters
function random_param{T}( param::AbsoluteParameter{T}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val + (rand(rng)-0.5) * param.Δ * s
  # Check if the new value is within the boundaries and return new param
  return AbsoluteParameter{T}(param.name, param.min, param.max, clamp(new_val, param.min, param.max), param.Δ)
end
