include("types.jl")

type ForceRule <: AbstractRule
  P::AAF             # P variable
  α::Float64         # alpha parameter

  function ForceRule(size::Int, α::Real)
     P = 1/α * eye(size)
     return new( P, α )
  end
end

function update_weights!( rule::ForceRule, net::AbstractNetwork, task::AbstractTask )
  k = rule.P * net.neuron_out       # helper var
  c  = 1/(1 + net.neuron_out ⋅ k)   # helper var

  update_P!(rule.P, k, c)
  #=P -= (c*k)*k'=#

  err  = compare_result(task, net.readout)

  # Changing the weigths
  @inbounds for j in 1:length(k)
      @simd for i in 1:length(err)
          net.ω_o[i,j] -= (c*err[i])*k[j]
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
