
abstract AbstractNetwork
abstract AbstractNeuron

typealias AAF AbstractArray{Float64, 2}

abstract AbstractRule

abstract AbstractTask

# interfaces
function update_weights( rule::AbstractRule, net::AbstractNetwork)
  error("not implemented")
end

# compares out with the output the task desires
function set_time( task::AbstractTask, time::Float64 )
  error("Not implemented")
end

function compare_result( task::AbstractTask, out::Array{Float64} )  # returns Array{Float64}
  error("not implemented")
end

# checks the quality of the generated output
function eval_result( task::AbstractTask, out::Array{Float64} ) # returns Float64
  return norm( compare_result( task, out ) )
end