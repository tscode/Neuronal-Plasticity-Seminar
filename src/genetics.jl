#
# GENETICS
#

type GeneticOptimizer
  population::Vector{AbstractGenerator}   # vector of generators, all different genotypes
  success::Vector{AbstractSuccessRating}  # holds the current success ratings

  fitness::Function     # maps AbstractGenerator → AbstractSuccessRating
  compare::Function     # maps AbstractGenerator² → bool,
                        # returns true if first arg is better than second

  generation::Int       # counts the number of generations that have been simulated
  recorder::Recorder    # records genotype information
  rng::AbstractRNG      # an own rng for deterministic results

  # Constructor
  function GeneticOptimizer( fitness::Function, compare::Function;
                             population::Vector{AbstractGenerator}=AbstractGenerator[],
                             success::Vector{AbstractSuccessRating}=AbstractSuccessRating[],
                             seed::Uint32 = randseed() )
      new( population, success, fitness, compare, 0, Recorder(), MersenneTwister(seed) )
  end
end

# function to calculate the success values as fast as possible in parallel
# ATTENTION: Usage of this function makes it necessary to start julia appropriately
# for several processes
function rate_population_parallel(opt::GeneticOptimizer; seed::Integer=randseed())
  rng = MersenneTwister(seed)
  gene_tuples = [ (gene, randseed(rng)) for gene in opt.population ]
  return AbstractSuccessRating[ succ for succ in pmap( x -> opt.fitness(x[1],
                                                       rng=MersenneTwister(x[2])),
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
    import_params!( gen, AbstractParameter[random_param(p, opt.rng, s = 5 ) for p in params] )
  end
  # calculate the initial success rates
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))
end

function step!( opt::GeneticOptimizer ) ## TO BE GENERALIZED
  # provide the impatient programmer with some information
  println("processing generation $(opt.generation)")
  # collection of all generators that survive
  survivors = AbstractGenerator[]
  success = AbstractSuccessRating[]

  # random order for comparison
  order = shuffle( opt.rng, collect(1:length(opt.population)) )

  # fight: just compare the old fitnesses
  for i = 2:2:length(opt.population)
    if opt.compare( opt.success[order[i-1]], opt.success[order[i]] )
      push!(survivors, opt.population[order[i-1]])
      push!(success, opt.success[order[i-1]])
    else
      push!(survivors, opt.population[order[i]])
      push!(success, opt.success[order[i]])
    end
  end

  # record survivor performance. it is not so nice that we have to do that here.
  mean_success = Float64[0.0, 0.0, 0.0]
  for i = 1:length(survivors)
    succ = Float64[success[i].quota, success[i].quality, success[i].timeshift]
    pars = Float64[p.val for p in export_params(survivors[i])]
    record(opt.recorder, 1, vcat([opt.generation], succ, pars))

    mean_success += succ
  end
  mean_success /= length(survivors)
  println(mean_success)

  opt.population = calculate_next_generation(opt.rng, survivors, length(opt.population) )
  opt.success = rate_population_parallel(opt, seed=randseed(opt.rng))

  opt.generation += 1
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

function mutate( rng::AbstractRNG, source::AbstractGenerator ) ## TO BE GENERALIZED
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
function random_param( param::Parameter{Int}, rng::AbstractRNG; s::Real = 1. )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = convert(Int, round( param.val * (rand(rng)*0.2*s + 1 - 0.2*s*0.5) ))
  # Check if the new value is within the boundaries
  return Parameter{Int}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end


function random_param( param::Parameter{Float64}, rng::AbstractRNG; s::Real = 1. )
  # Obtain new parameter values by relative changes of +-0.1*s
  new_val = param.val * (rand(rng)*0.2*s + 1 - 0.2*s*0.5) #  0.9 ... 1.1 is default
  # Check if the new value is within the boundaries and return new param
  return Parameter{Float64}(param.name, param.min, param.max, clamp(new_val, param.min, param.max))
end

function save_evolution(file, opt::GeneticOptimizer)
  writedlm(file, hcat(opt.recorder[1]...)')
#  writedlm(join(("mean_",file)), hcat(opt.recorder[2]...)')
end
