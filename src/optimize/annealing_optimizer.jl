# interface
export AnnealingOptimizer
export anneal

# alternate optimizer, might actually be better suited....
type AnnealingOptimizer{T <: AbstractParametricObject} <: AbstractOptimizer{T}
  current::T
  cscore::AbstractSuccessRating
  best::T
  bscore::AbstractSuccessRating

  fitness::Function     # maps IndividualType       → AbstractSuccessRating

  stepcount::Int       # counts the number of generations that have been simulated
  recorder::Recorder    # records genotype information
  rng::AbstractRNG      # an own rng for deterministic results

  # configuration variables
  steps_per_temp::Integer
  initial_temperature::Real
  final_temperature::Real

  # Constructor
  function AnnealingOptimizer( init::T, fitness::Function;
                             seed::Integer = randseed() )
      ifit = fitness(init)
      new( init, ifit, init, ifit, fitness, 0, Recorder(), MersenneTwister(seed), 10, 1.0, 0.01 )
  end
end

function anneal_at_temp(opt::AnnealingOptimizer, temperature::Real)
  found_count = 0

  for i = 1 : opt.steps_per_temp
    neighbour = mutate(current)
    nscore = fitness( neighbour, samples = 20 )
    dif = get_value(cscore) - get_value(nscore) # cscore - nscore, so positive if current is better
    p = rand(opt.rng)
    # is new state better?
    if dif < 0
      found_count += 1
      current = neighbour
      cscore = nscore
      if get_value(bscore) get_value( nscore ) < 0
        best = deepcopy(neighbour)
        bscore = deepcopy(nscore)
      end
    elseif p < exp(-dif / temperature)
      current = neighbour
      cscore = nscore
      found_count += 1
    end
  end
  return found_any
end

# anneal function that tells the optimizer to do the annealing loop
function anneal(opt::AnnealingOptimizer, steps::Integer; itemp::Real = opt.initial_temperatur, ftemp::Real = opt.final_temperature)
  λ = log(ftemp/itemp) / steps
  for i = 1:steps
    temp = itemp * exp(λ*i)
    count = anneal_at_temp(opt, temp)
    # record results
    record(opt.recorder, 0, count)
    record(opt.recorder, 1, opt.bscore) # best score
    record(opt.recorder, 2, opt.cscore) # current score
    # TODO need a good way to record the current state
    # TODO allow for early exit
  end
end
