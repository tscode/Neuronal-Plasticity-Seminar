# interface
export AnnealingOptimizer
export anneal

# alternate optimizer, might actually be better suited....
type AnnealingOptimizer{T <: AbstractParametricObject} <: AbstractOptimizer{T}
  current::T
  cscore::AbstractRating
  best::T
  bscore::AbstractRating

  fitness::Function     # maps IndividualType       → AbstractSuccessRating
  callback::Function    # this function gets called every step. takes two parameters, opt and step

  stepcount::Int        # counts the number of generations that have been simulated
  recorder::Recorder    # records genotype information
  rng::AbstractRNG      # an own rng for deterministic results

  # configuration variables
  steps_per_temp::Integer
  initial_temperature::Real
  final_temperature::Real

  # Constructor
  function AnnealingOptimizer( init::T, fitness::Function;
                             seed::Integer = 0#=randseed() module problem! =# )
      ifit = fitness(init)
      new( init, ifit, init, ifit, fitness, default_callback, 0, Recorder(), MersenneTwister(seed), 25, 1.0, 0.01 )
  end
end

function anneal_at_temp(opt::AnnealingOptimizer, temperature::Real)
  found_count = 0

  for i = 1:opt.steps_per_temp
    neighbour = mutate(opt.rng, opt.current)
    nscore = opt.fitness( neighbour, samples = 20 )
    dif = get_value(opt.cscore) - get_value(nscore) # cscore - nscore, so positive if current is better
    p = rand(opt.rng)
    # is new state better?
    println(dif)
    if dif < 0
      found_count += 1
      current = neighbour
      cscore = nscore
      if get_value(opt.bscore) - get_value( nscore ) < 0
        opt.best = deepcopy(neighbour)
        opt.bscore = deepcopy(nscore)
      end
    elseif p < exp(-dif / temperature)
      opt.current = neighbour
      opt.cscore = nscore
      found_count += 1
    end
    record(opt.recorder, 1, opt.bscore) # best score
    record(opt.recorder, 2, opt.cscore) # current score
    record(opt.recorder, 3, opt.current.value) # current value
  end
  return found_count
end

# anneal function that tells the optimizer to do the annealing loop
function anneal(opt::AnnealingOptimizer, steps::Integer; itemp::Real = opt.initial_temperature, ftemp::Real = opt.final_temperature)
  λ = log(ftemp/itemp) / steps
  for i = 1:steps
    temp = itemp * exp(λ*i)
    count = anneal_at_temp(opt, temp)
    # record results
    #record(opt.recorder, 0, count)

    # TODO need a good way to record the current state
    # TODO allow for early exit
    opt. callback(opt, i)
  end
end
