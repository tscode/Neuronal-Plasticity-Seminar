#
# TYPES
#
# Collection of all? abstract types used

typealias AAF AbstractArray{Float64, 2}

abstract AbstractNetwork
abstract AbstractNeuron
abstract AbstractRule
abstract AbstractTask
abstract AbstractTeacher
abstract AbstractParametricObject
abstract AbstractGenerator <: AbstractParametricObject
abstract AbstractTopology <: AbstractParametricObject
abstract AbstractEvaluator
abstract AbstractParameter
abstract AbstractSuccessRating
abstract AbstractChallenge
abstract AbstractEnvironment
