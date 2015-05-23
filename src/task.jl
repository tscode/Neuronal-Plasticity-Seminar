include("types.jl")

type FunctionTask <: AbstractTask
  time::Float64 # current time
  funcs::Array{Function}
  expected::Array{Float64}

  function FunctionTask( funcs::Array{Function} )
    new(0, funcs, zeros(length(funcs)))
  end
end

function set_time!( task::FunctionTask, time::Float64 )
  for i in 1:length(task.funcs)
      task.expected[i] = task.funcs[i](time)
  end
  task.time = time
end

# compares out with the output the task desires
function compare_result( task::FunctionTask, out::Array{Float64} )  # returns Array{Float64}
  return out - task.expected
end
