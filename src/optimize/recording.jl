#= This file overloads the record function for types used in optimize =#
include("../recorder.jl")
import EvoNet.record

# the canonical form of recording an AbstractRating is to record its value without additional info
function record(rec::Recorder, id, rating::AbstractRating)
   record(rec, id, get_value(rating))
end

