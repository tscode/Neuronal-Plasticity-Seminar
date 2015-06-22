#
# FORCE RULE
#
# Implementation of the FORCE for our network to learn.
# Learning rules must implement an update_weigths function
# that depends on the rule, the network, and the task to be
# learned.
#

type ForceRule <: AbstractRule
  # Invariants for the Rule
  α::Float64  # alpha parameter
  # helper quantities to be resetted before every learning process
  P::AAF             # P variable
  k::Vector{Float64} # needed to calc update_weights efficiently

  function ForceRule( size::Int; α::Real=1 )
    P = 1/α * eye(size)
    k = zeros(size)
    return new( α, P, k )
  end
  function ForceRule(; α::Real = 1 )
    return new(α, eye(0), zeros(0))
  end
end

function update_weights!( rule::ForceRule, net::AbstractNetwork, task::AbstractTask )
  BLAS.gemv!('N', 1.0, rule.P, net.neuron_out, 0.0, rule.k) # update k
  c  = 1/(1 + net.neuron_out ⋅ rule.k) # helper var c
  update_P!(rule.P, rule.k, c)         # P -= (c*k) * k'
  # Error value to be used to update the weights
  err  = compare_result(task, net.output)
  # Changing the weigths
  @inbounds for j in 1:length(rule.k)
      @simd for i in 1:length(err)
          net.ω_o[i,j] -= (c*err[i])*rule.k[j]
      end
  end
end

function update_weights!( rule::ForceRule, net::LRNetwork, task::AbstractTask )
  d = calc_k_LR!(rule.k, rule.P, net.neuron_out, net.output_neurons) # update k
  c  = 1/(1 + d)   # helper var
  update_P!(rule.P, rule.k, c) # P -= (c*k) * k'
  # Error value to be used to update the weights
  err  = compare_result(task, net.output)
  # Changing the weigths
  @inbounds for j in 1:length(rule.k)
      @simd for i in 1:length(err)
          net.ω_o[i,j] -= (c*err[i])*rule.k[j]
      end
  end
end

# inside an external function for performance reasons
function update_P!(P::Matrix{Float64}, k::Vector{Float64}, c::Float64)
    # summation order column-major friendly --> really saves time!
    @inbounds for j in 1:size(P)[2]
        @simd for i in 1:size(P)[1]
            P[i,j] -= (c*k[i]*k[j])::Float64
        end
    end
end

function calc_k_LR!( k::Vector{Float64}, P::Matrix{Float64}, neuron_out::Vector{Float64}, 
                     output_neurons::Vector{Int} )
  d = 0.
  @inbounds for i in 1:length(output_neurons)
      k[i] = P[i, 1] * neuron_out[output_neurons[1]]
      for j in 2:length(output_neurons)
          k[i] += P[i, j] * neuron_out[output_neurons[j]]
      end
      d += neuron_out[output_neurons[i]] * k[i]
  end
  return d
end

# reset a rule in order to reuse it
function reset(rule::ForceRule; α::Real=rule.α, N::Integer=size(rule.k)[1])
  rule.α = α
  rule.P = 1/α * eye(N)
  rule.k = zeros(N)
end
