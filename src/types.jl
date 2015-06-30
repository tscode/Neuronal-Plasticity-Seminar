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
abstract AbstractGenerator <: optimize.AbstractParametricObject
abstract AbstractTopology <: optimize.AbstractParametricObject
abstract AbstractEvaluator
abstract AbstractChallenge
abstract AbstractEnvironment
