include("types.jl")

type FunctionTask <: AbstractTask
  time::Float64 # current time -- does the task need this one?
  funcs::Array{Function} # collection of functions
  expected::Array{Float64} # function values -> these are the expected values

  fluctuations::Float64	# amount of random noise added to the data
  deterministic::Bool   # set to true to disable fluctuations temporarily

  function FunctionTask( funcs::Array{Function}; fluctuations = 0.0 )
    new(0, funcs, zeros(length(funcs)), fluctuations, false)
  end
end

#function FunctionTask( funcs...; fluctuations = 0.0 )
#    FunctionTask( [funcs...], fluctuations )
#end

function prepare_task!( task::FunctionTask, time::Real ) # usually only called by teacher
  for i in 1:length(task.funcs)
      if task.deterministic
        task.expected[i] = task.funcs[i](time)
      else
        task.expected[i] = task.funcs[i](time) + randn() * task.fluctuations
      end
  end
  task.time = time
end

# returns the cached expected value
function get_expected( task::FunctionTask )
  return task.expected
end

function set_deterministic!( task::AbstractTask, det::Bool )
  task.deterministic = det
end
