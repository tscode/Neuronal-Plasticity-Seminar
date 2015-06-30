#= This class defines an interface for types that rate the success of a network
(or sth more general, but we apply it only to networks =#

abstract AbstractRating
export AbstractRating
export get_value
export get_uncertainty

# interface of success ratings

function get_value(s::AbstractRating)
  # get value is supposed to convert a success rating into a single floating point value
  error("get_value not implemented for $(s)")
end

function get_uncertainty(s::AbstractRating)
  # get_uncertainty is supposed to get the uncertainty for a sampled success rating
  error("get_uncertainty not implemented for $(s)")
end


##########################################
#  simple implementation: float rating   #
##########################################

type FloatSuccessRating <: AbstractRating
  rating::Float64
end


function get_value(s::FloatSuccessRating)
  return s.rating
end

function get_uncertainty(s::FloatSuccessRating)
  return 0.0
end