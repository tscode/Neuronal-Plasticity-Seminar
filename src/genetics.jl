#
# GENETICS
#

#const MIN_SAMPLES::Int = 50

type GeneticOptimizer
  population::Vector{AbstractGenerator}   # vector of generators, all different genotypes
  success::Vector{AbstractSuccessRating}  # holds the current success ratings

  fitness::Function     # maps AbstractGenerator       → AbstractSuccessRating
  compare::Function     # maps AbstractGenerator², RNG → bool,
                        # returns true if first arg is better than second

  samples::Integer      # number of samples to take when evaluating the generators

  generation::Int       # counts the number of generations that have been simulated
  recorder::Recorder    # records genotype information
  rng::AbstractRNG      # an own rng for deterministic results

  # Constructor
  function GeneticOptimizer( fitness::Function, compare::Function;
                             population::Vector{AbstractGenerator}=AbstractGenerator[],
                             success::Vector{AbstractSuccessRating}=AbstractSuccessRating[],
                             seed::Uint32 = randseed() )
      new( population, success, fitness, compare, 50, 0, Recorder(), MersenneTwister(seed) )
  end
end

# function to calculate the success values as fast as possible in parallel
# ATTENTION: Usage of this function makes it necessary to start julia appropriately
# for several processes
function rate_population_parallel(opt::GeneticOptimizer; seed::Integer=randseed(), samples = opt.samples, pop = opt.population)
  rng = MersenneTwister(seed)
  gene_tuples = [ (gene, randseed(rng)) for gene in pop ]
  return AbstractSuccessRating[ succ for succ in pmap( x -> opt.fitness(x[1],
                                                       rng=MersenneTwister(x[2]), samples=samples),
                                                       gene_tuples ) ]
end

function init_population!( opt::GeneticOptimizer, base_element::AbstractGenerator, N::Integer )
  # provde defaults to be mutated later
  opt.population = AbstractGenerator[ deepcopy(base_element) for i in 1:N ]
  opt.success    = AbstractSuccessRating[ SuccessRating(0,0,0,0) for i in 1:N ]
  # load parameters
  params = export_params( base_element ) # Vector of AbstractParameters
  # randomize the generators in the population (genome-pool)
  for gen in opt.population
    import_params!( gen, AbstractParameter[random_param(p, opt.rng, s = 0.5 ) for p in params] )
  end
  # calculate the initial success rates
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))
end

function step!( opt::GeneticOptimizer ) ## TO BE GENERALIZED
  # provide the impatient programmer with some information
  println("processing generation $(opt.generation)")

  #
  mean_success, variance = record_population(opt.recorder, opt.population, opt.success, opt.generation)

  # collection of all generators that survive
  survivors = AbstractGenerator[]
  success = AbstractSuccessRating[]

  # random order for comparison
  order = shuffle( opt.rng, collect(1:length(opt.population)) )

  # fight: just compare the old fitnesses
  for i = 2:2:length(opt.population)
    if opt.compare( opt.success[order[i-1]], opt.success[order[i]], opt.rng )
      push!(survivors, opt.population[order[i-1]])
      push!(success, opt.success[order[i-1]])
    else
      push!(survivors, opt.population[order[i]])
      push!(success, opt.success[order[i]])
    end
  end

  # estimate number of samples needed
  # error of sampling: es ~ p(1-p)/sqrt(N) => sqrt(N) = p(1-p)/sqrt(variance)
  # we want error < half of variance, thus factor 4
  req = round(4*(mean_success[1] * (1-mean_success[1]) / sqrt(variance[1]))^2)
  println(req)
  opt.samples = int(clamp(req, 50, 2*50))
  println(mean_success)

  # two stage population generation:
  newborns = calculate_next_generation(opt.rng, survivors, 2*length(opt.population) )
  opt.population = infancy_death(opt, newborns, length(opt.population))

  # re evaluate new nets
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))

  opt.generation += 1
end

# writes info about a population
function record_population(rec::Recorder, pop::Vector{AbstractGenerator}, suc::Vector{AbstractSuccessRating}, generation::Integer)
   # collect info about all gens
  mean_success = Float64[0.0, 0.0, 0.0]
  squared_success = Float64[0.0, 0.0, 0.0]
  for i = 1:length(pop)
    succ = Float64[suc[i].quota, suc[i].quality, suc[i].timeshift]
    pars = Float64[]
    # UGLY UGLY UGLY
    for p in export_params(pop[i])
      if isa(p.val, Real)
        pars = vcat(pars, p.val)
      elseif isa(p.val, Vector{Float64})
        pars = vcat(pars, p.val...)
      else
        @assert false "$(typeof(p.val))"
      end
    end
    record(rec, 1, vcat([generation], succ, pars))

    mean_success += succ
    squared_success += succ .* succ
  end
  mean_success /= length(pop)
  squared_success /= length(pop)
  variance = squared_success - mean_success.*mean_success

  return mean_success, variance
end

function calculate_next_generation( rng::AbstractRNG, parents::Vector{AbstractGenerator}, N::Integer)
  offspring = AbstractGenerator[]
  lidx = 1
  for t in 1:N
    if randbool(rng)
      push!(offspring, mutate(rng, parents[lidx]))
    else
      push!(offspring, recombine(rng, parents[lidx], parents[lidx % length(parents) + 1]))
    end

    # make lidx round-trip, so this works even if we require no relation between parents and targets sizes
    lidx = lidx % length(parents) + 1
  end

  return offspring
end

function infancy_death(opt::GeneticOptimizer, infants::Vector{AbstractGenerator}, N::Integer)
  survivors = infants
  survivor_rating = AbstractSuccessRating[]
  NUM_SAMPLES = 0

  while true
    # do another sample and mix with previous results
    nb_rating = rate_population_parallel(opt, seed=randseed(opt.rng), samples = 1, pop=survivors) # only do a few samples
    if length(survivor_rating) != 0
      nb_rating .+= survivor_rating
    end
    NUM_SAMPLES += 1

    # reset survivors and their ratings, initialise linearized score
    infants = deepcopy(survivors)
    survivors = AbstractGenerator[]
    survivor_rating = AbstractSuccessRating[]
    linear_scores = [s.quota * NUM_SAMPLES + s.quality for s in nb_rating]

    # take the N best networks
    while length(survivors) < N
      best = indmax(linear_scores)
      linear_scores[best] = -1 # this one is used
      push!(survivors, infants[best])
      push!(survivor_rating, nb_rating[best])
    end

    # take a look at the last survivors rating. if it includes failed trials, we are finished
    if survivor_rating[end].quota < 1
      return survivors # would be cool if we could reuse the samples we did here
    end
  end
end

function recombine( rng::AbstractRNG, A::AbstractGenerator, B::AbstractGenerator )
  # combine A and B as parents for a new Generator target
  # load parameters
  ap = export_params( A )
  bp = export_params( B )
  # randomize networks
  for i = 1:length(ap)
    if( randbool(rng) )
      @assert ap[i].name == bp[i].name "parameters do not match $(ap[i]) != $(bp[i])"
      ap[i] = bp[i] #should be safe, because export_params creates deep copies
    end
  end

  new_gen = deepcopy(A) # this assumes that A and B are equivalent!
  import_params!( new_gen, ap )
  return new_gen
end

function mutate( rng::AbstractRNG, source::AbstractGenerator )
  # load parameters
  params = export_params( source )
  # choose parameter-index to mutate
  id = rand( rng, 1:length(params) )
  # make the mutation
  params[id] = random_param( params[id], rng )
  # and reimport them
  target = deepcopy(source) # this assumes that A and B are equivalent!
  import_params!( target, params )
  return target
end

# create a new "mutated" parameter based on a given one
function random_param( param::Parameter{Int}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = convert(Int, round( param.val * (1.0 + randn(rng) * s) ))
  # Check if the new value is within the boundaries
  return Parameter{Int}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end


function random_param( param::Parameter{Float64}, rng::AbstractRNG; s::Real = 0.1 )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val * (1.0 + randn(rng) * s) #  0.9 ... 1.1 is default
  # Check if the new value is within the boundaries and return new param
  return Parameter{Float64}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end

function save_evolution(file, opt::GeneticOptimizer)
  writedlm(file, hcat(opt.recorder[1]...)')
#  writedlm(join(("mean_",file)), hcat(opt.recorder[2]...)')
end
