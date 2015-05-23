include("types.jl")

type FunctionTask <: AbstractTask
  time::Float64 # current time
  func::Array{Function}
  expected::Array{Float64}

  function FunctionTask( func::Array{Function} )
    new(0, func, zeros(length(func)))
  end
end

function set_time( task::AbstractTask, time::Float64 )
  task.expected = task.func(time)
  task.time = time
end

# compares out with the output the task desires
function compare_result( task::FunctionTask, out::Array{Float64} )  # returns Array{Float64}
  return out - task.expected
end
