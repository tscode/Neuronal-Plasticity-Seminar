
type ForceRule <: AbstractRule
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

function update_weights!( rule::ForceRule, net::AbstractNetwork, task::AbstractTask )
  BLAS.gemv!('N', 1.0, rule.P, net.neuron_out, 0.0, rule.k) # update the helper var k
  c  = 1/(1 + net.neuron_out ⋅ rule.k)   # helper var

  update_P!(rule.P, rule.k, c)
  #=P -= (c*k)*k'=#

  err  = compare_result(task, net.output)

  # Changing the weigths
  @inbounds for j in 1:length(rule.k)
      @simd for i in 1:length(err)
          net.ω_o[i,j] -= (c*err[i])*rule.k[j]
      end
  end
end

#inside an external function for performance reasons
function update_P!(P::Matrix{Float64}, k::Vector{Float64}, c::Float64)
    # summation order column-major friendly --> really saves time!
    @inbounds for j in 1:size(P)[2]
        @simd for i in 1:size(P)[1]
            P[i,j] -= (c*k[i]*k[j])::Float64
        end
    end
end
