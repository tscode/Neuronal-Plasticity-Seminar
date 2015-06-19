include("types.jl")

type FunctionTask <: AbstractTask
  time::Float64 # current time -- does the task need this one?
  funcs::Array{Function}   # collection of functions
  ifuncs::Array{Function}  # collection of input functions
  expected::Array{Float64} # function values -> these are the expected values
  input::Array{Float64}    # inputs for the network

  fluctuations::Float64	   # amount of random noise added to the data
  deterministic::Bool      # true if the current values of expected and input are deterministic

  rng::AbstractRNG   # randomness source for this task

  function FunctionTask( funcs::Array{Function}, ifuncs::Array{Function}; fluctuations = 0.0, seed=0 )
    new(0, funcs, ifuncs,  zeros(length(funcs)), zeros(length(ifuncs)), fluctuations, false, MersenneTwister(seed))
  end
  function FunctionTask( funcs::Array{Function}, ifuncs::Array{Function}, rng::AbstractRNG; fluctuations = 0.0 )
    new(0, funcs, ifuncs,  zeros(length(funcs)), zeros(length(ifuncs)), fluctuations, false, rng)
  end
end

#function FunctionTask( funcs...; fluctuations = 0.0 )
#    FunctionTask( [funcs...], fluctuations )
#end

function prepare_task!( task::FunctionTask, time::Real, deterministic::Bool) # usually only called by teacher
  # generate expected output
  for i in 1:length(task.funcs)
      if deterministic
        task.expected[i] = task.funcs[i](time)
      else
        task.expected[i] = task.funcs[i](time) + randn(task.rng) * task.fluctuations
      end
  end
  #!TODO would it make sense to leave the input noisy but test for noiseless output. prly yes
  # generate input
  for i in 1:length(task.ifuncs)
      if deterministic
        task.input[i] = task.ifuncs[i](time)
      else
        task.input[i] = task.ifuncs[i](time) + randn(task.rng) * task.fluctuations
      end
  end
  task.time = time
  task.deterministic = deterministic
end

# returns the cached expected value
function get_expected( task::FunctionTask )
  return task.expected
end

# returns the cached input value
function get_input( task::FunctionTask )
  return task.input
end

# generator function
function make_periodic_function(rng::AbstractRNG)
  freq = 2π/(dt * (rand(rng) * 100 + 10))
  amplitud = 1 + randn(rng) / 2
  phaseshift = rand(rng) * 2π
  return t->amplitud*sin(t*freq + phaseshift)
end

function make_periodic_function_task( out::Int, invals::Array{Function}, rng::AbstractRNG )
  tfuncs = [make_periodic_function(rng) for i = 1:out]
  return FunctionTask(tfuncs, invals, rng)
end
