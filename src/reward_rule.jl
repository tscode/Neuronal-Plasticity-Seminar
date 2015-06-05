#
# Implementation of the FORCE for our network to learn.
# Learning rules must implement an update_weigths function
# that depends on the rule, the network, and the task to be
# learned.
#

type RewardModulatedRule <: AbstractRule
  # Invariants for the Rule
  α::Float64         # alpha parameter

  # helper quantities
  P::AAF             # P variable
  k::Vector{Float64} # needed to calc update_weights efficiently

  function ForceRule(size::Int, α::Real)
     P = 1/α * eye(size)
     k = zeros(size)
     return new( α, P, k )
  end
end
