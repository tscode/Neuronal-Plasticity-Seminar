include("types.jl")

type FunctionTask <: AbstractTask
  time::Float64 # current time -- does the task need this one?
  funcs::Array{Function} # collection of functions
  expected::Array{Float64} # function values -> these are the expected values

  function FunctionTask( funcs::Array{Function} )
    new(0, funcs, zeros(length(funcs)))
  end
end

function FunctionTask( funcs... )
    FunctionTask( [funcs...] )
end

function prepare_task!( task::FunctionTask, time::Real ) # usually only called by teacher
  for i in 1:length(task.funcs)
      task.expected[i] = task.funcs[i](time)
  end
  task.time = time
end

# compares out with the output the task desires
function compare_result( task::FunctionTask, out::Array{Float64} )  # returns Array{Float64}
  return out - task.expected
end
